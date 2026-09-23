// FTS5 in-chat search: the index, its four sync points, and the query escaping.
//
// The search box is backed by a SQLite FTS5 virtual table that mirrors
// `local_messages`. Nothing enforces that mirroring except four hand-written
// call sites in `PlaintextStore` — `saveMessage`, `saveMessagesBatch`,
// `deleteMessage` and `wipe`. A missed one doesn't throw: it leaves a stale row
// in the index, so search either can't find a message that exists or offers one
// that was deleted. The second failure is the serious one — a deleted or
// tombstoned message resurfacing in a search result is a privacy bug, not a
// missing feature.
//
// These run against `NativeDatabase.memory()` through the `forTesting`
// constructors, so they exercise the real migration, the real virtual table and
// the real write paths without touching the on-device file.

// `show Variable` rather than a bare import: drift exports its own `isNull`
// (a SQL expression helper) which collides with matcher's.
import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/services/crypto/plaintext_store.dart';
import 'package:video_chat_app/services/database/app_database.dart';

import '../../support/sqlite_test_setup.dart';

const _room = 'alice_bob';
const _otherRoom = 'alice_carol';

MessageModel _msg(
  String id,
  String text, {
  String senderId = 'alice',
  String receiverId = 'bob',
  int? tsMillis,
}) =>
    MessageModel(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      timestamp:
          DateTime.fromMillisecondsSinceEpoch(tsMillis ?? 1700000000000),
      schemaVersion: 2,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useNativeSqliteForTests();

  late AppDatabase db;
  late PlaintextStore store;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = PlaintextStore.forTesting(db);
    // Force the migration to run now, so a failure surfaces here rather than
    // inside whichever test happened to touch the DB first.
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() async => db.close());

  Future<List<String>> search(String q, {String room = _room}) async {
    final results = await store.searchMessages(room, q);
    return results.map((m) => m.id).toList();
  }

  Future<int> ftsRowCount() async {
    final rows = await db
        .customSelect('SELECT COUNT(*) AS c FROM ${AppDatabase.ftsTableName}')
        .get();
    return rows.first.read<int>('c');
  }

  group('FTS5 availability', () {
    test('the bundled SQLite has FTS5 compiled in', () async {
      // sqlite3_flutter_libs is what guarantees this; if the pin ever drifts to
      // a build without FTS5, every other test here fails with an opaque
      // "no such module" and this one names the cause.
      final rows = await db
          .customSelect(
              "SELECT 1 AS ok FROM pragma_compile_options WHERE compile_options LIKE 'ENABLE_FTS5'")
          .get();
      expect(rows, isNotEmpty, reason: 'SQLite was built without FTS5');
    });

    test('the virtual table exists after onCreate', () async {
      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
            variables: [const Variable<String>(AppDatabase.ftsTableName)],
          )
          .get();
      expect(rows, hasLength(1));
    });
  });

  group('round trip', () {
    test('a saved message is findable by a word in its body', () async {
      await store.saveMessage(_msg('m1', 'the quick brown fox'), _room);
      expect(await search('brown'), ['m1']);
    });

    test('prefix matching finds a word the user is still typing', () async {
      await store.saveMessage(_msg('m1', 'appointment at four'), _room);
      expect(await search('appoint'), ['m1']);
    });

    test('multiple tokens are an AND, not an OR', () async {
      await store.saveMessage(_msg('m1', 'quick brown fox'), _room);
      await store.saveMessage(_msg('m2', 'quick red herring'), _room);

      expect(await search('quick brown'), ['m1']);
      expect((await search('quick'))..sort(), ['m1', 'm2']);
    });

    test('search is case-insensitive and diacritic-insensitive', () async {
      // `remove_diacritics 2` in the tokenizer is what makes the second half
      // work — searching "cafe" has to find "café" or the feature is useless
      // for most of the languages this app ships in.
      await store.saveMessage(_msg('m1', 'Meet me at the Café'), _room);

      expect(await search('café'), ['m1']);
      expect(await search('cafe'), ['m1']);
      expect(await search('CAFE'), ['m1']);
    });

    test('a miss returns empty rather than throwing', () async {
      await store.saveMessage(_msg('m1', 'hello there'), _room);
      expect(await search('goodbye'), isEmpty);
    });

    test('results are newest first', () async {
      await store.saveMessage(
          _msg('older', 'shared topic', tsMillis: 1700000000000), _room);
      await store.saveMessage(
          _msg('newer', 'shared topic', tsMillis: 1700000900000), _room);

      expect(await search('topic'), ['newer', 'older']);
    });
  });

  group('index maintenance — the four sync points', () {
    test('saveMessage re-indexes an edit, dropping the old text', () async {
      await store.saveMessage(_msg('m1', 'original wording'), _room);
      expect(await search('original'), ['m1']);

      // saveMessage is insertOrReplace, so an edit arrives as a re-save of the
      // same id. The FTS row has to be replaced too, not appended.
      await store.saveMessage(_msg('m1', 'revised wording'), _room);

      expect(await search('revised'), ['m1']);
      expect(await search('original'), isEmpty,
          reason: 'the pre-edit text is still in the index');
      expect(await ftsRowCount(), 1,
          reason: 'the edit left a duplicate index row behind');
    });

    test('saveMessagesBatch indexes every message in the batch', () async {
      await store.saveMessagesBatch([
        _msg('m1', 'alpha one'),
        _msg('m2', 'beta two'),
        _msg('m3', 'gamma three'),
      ], _room);

      expect(await search('alpha'), ['m1']);
      expect(await search('beta'), ['m2']);
      expect(await search('gamma'), ['m3']);
      expect(await ftsRowCount(), 3);
    });

    test('a batch re-save replaces rather than duplicates', () async {
      await store.saveMessagesBatch([_msg('m1', 'first pass')], _room);
      await store.saveMessagesBatch([_msg('m1', 'second pass')], _room);

      expect(await search('second'), ['m1']);
      expect(await search('first'), isEmpty);
      expect(await ftsRowCount(), 1);
    });

    test('deleteMessage removes the message from the index', () async {
      await store.saveMessage(_msg('m1', 'delete me please'), _room);
      expect(await search('delete'), ['m1']);

      await store.deleteMessage('m1', _room);

      expect(await search('delete'), isEmpty);
      expect(await ftsRowCount(), 0);
    });

    test('a tombstoned message leaves no searchable text behind', () async {
      // "Delete for everyone" goes through saveMessage with a tombstone model,
      // not deleteMessage — the row stays so the bubble can say "deleted", but
      // the original text must not remain findable.
      await store.saveMessage(_msg('m1', 'the incriminating sentence'), _room);
      expect(await search('incriminating'), ['m1']);

      await store.saveMessage(_msg('m1', '').asTombstone(), _room);

      expect(await search('incriminating'), isEmpty,
          reason: 'deleted message text is still searchable');
    });

    test('wipe clears the whole index', () async {
      await store.saveMessagesBatch([
        _msg('m1', 'alpha'),
        _msg('m2', 'beta'),
      ], _room);
      expect(await ftsRowCount(), 2);

      await store.wipe();

      expect(await ftsRowCount(), 0);
      expect(await search('alpha'), isEmpty);
    });
  });

  group('scoping', () {
    test('search does not leak across chat rooms', () async {
      await store.saveMessage(_msg('mine', 'shared secret'), _room);
      await store.saveMessage(
        _msg('theirs', 'shared secret', receiverId: 'carol'),
        _otherRoom,
      );

      expect(await search('secret'), ['mine']);
      expect(await search('secret', room: _otherRoom), ['theirs']);
    });
  });

  group('query escaping', () {
    // Each of these is FTS5 syntax. Unescaped, they throw a SqliteException out
    // of a keystroke handler — i.e. the search box crashes the chat screen
    // while the user is mid-word.
    const hostile = <String>[
      '"',
      '""',
      'unbalanced "quote',
      'OR',
      'AND',
      'NOT',
      'NEAR',
      'NEAR(a b, 2)',
      '*',
      '^caret',
      'col:value',
      '(unclosed',
      ')',
      '-negated',
      'a AND b OR c',
      '""""',
      '\\',
      '%_',
    ];

    setUp(() async {
      await store.saveMessage(_msg('m1', 'ordinary message text'), _room);
    });

    for (final input in hostile) {
      test('does not throw on ${jsonish(input)}', () async {
        await expectLater(store.searchMessages(_room, input), completes);
      });
    }

    test('a bare operator is searched as a literal word', () async {
      await store.saveMessage(_msg('m2', 'we are near the station'), _room);

      // "NEAR" quoted is a literal token, so it matches the word "near" in m2
      // (prefix match, case-folded) and not m1.
      expect(await search('NEAR'), ['m2']);
    });

    test('a quote character searches for the quote, not syntax', () async {
      await store.saveMessage(_msg('m2', 'she said "hello" loudly'), _room);
      await expectLater(store.searchMessages(_room, '"hello"'), completes);
      expect(await search('hello'), ['m2']);
    });

    test('whitespace-only input returns nothing without querying', () async {
      expect(PlaintextStore.buildFtsQuery('   '), isNull);
      expect(PlaintextStore.buildFtsQuery(''), isNull);
      expect(PlaintextStore.buildFtsQuery('\t\n '), isNull);
      expect(await search('   '), isEmpty);
    });
  });

  group('buildFtsQuery', () {
    test('wraps each token in quotes with a trailing prefix star', () {
      expect(PlaintextStore.buildFtsQuery('hello'), '"hello"*');
      expect(PlaintextStore.buildFtsQuery('hello world'), '"hello"* "world"*');
    });

    test('doubles embedded quotes, FTS5-style', () {
      expect(PlaintextStore.buildFtsQuery('say "hi"'), '"say"* """hi"""*');
    });

    test('collapses runs of whitespace', () {
      expect(PlaintextStore.buildFtsQuery('  a   b  '), '"a"* "b"*');
    });

    test('the star is outside the quotes, where it is the prefix operator', () {
      // Inside the quotes it would be a literal asterisk and prefix matching
      // would silently stop working — search would only ever find whole words.
      final q = PlaintextStore.buildFtsQuery('foo')!;
      expect(q.endsWith('"*'), isTrue);
      expect(q.contains('*"'), isFalse);
    });
  });
}

/// Renders a hostile input readably in a test name — a bare `"` or a newline in
/// the name makes the failure output hard to read.
String jsonish(String s) => s.isEmpty
    ? '<empty>'
    : s.replaceAll('\n', r'\n').replaceAll('\t', r'\t');
