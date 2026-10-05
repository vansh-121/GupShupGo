// The v4 → v5 migration: creating the FTS5 index and backfilling it.
//
// The backfill is the part worth testing. Without it, search on an *upgraded*
// install silently finds only messages that arrived after the update — every
// older conversation looks empty. That failure is indistinguishable from
// "search is broken", reports as such, and can't be fixed after the fact
// without another migration, so the rung has to be right the first time.
//
// Unlike the round-trip suite, these tests need a database that survives being
// closed and reopened, so they run against a temp *file* rather than
// `NativeDatabase.memory()` — an in-memory database is discarded with its
// connection and could never exercise an upgrade at all.

import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/services/crypto/plaintext_store.dart';
import 'package:video_chat_app/services/database/app_database.dart';

import '../../support/sqlite_test_setup.dart';

const _room = 'alice_bob';

MessageModel _msg(String id, String text) => MessageModel(
      id: id,
      senderId: 'alice',
      receiverId: 'bob',
      text: text,
      timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      schemaVersion: 2,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useNativeSqliteForTests();

  late Directory dir;
  late File dbFile;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('gsg_migration_test');
    dbFile = File('${dir.path}/gsg_plaintext.db');
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  AppDatabase openDb() => AppDatabase.forTesting(NativeDatabase(dbFile));

  /// Rewinds a freshly-created v5 database to look like one written by the
  /// previous release: the FTS table gone, `user_version` back at 4. The
  /// `local_messages` rows stay, which is the whole point — they are what the
  /// backfill has to find.
  Future<void> rewindToV4(AppDatabase db) async {
    await db.customStatement('DROP TABLE IF EXISTS ${AppDatabase.ftsTableName}');
    await db.customStatement('PRAGMA user_version = 4');
  }

  Future<bool> ftsTableExists(AppDatabase db) async {
    final rows = await db.customSelect(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      variables: [const Variable<String>(AppDatabase.ftsTableName)],
    ).get();
    return rows.isNotEmpty;
  }

  Future<int> ftsRowCount(AppDatabase db) async {
    final rows = await db
        .customSelect('SELECT COUNT(*) AS c FROM ${AppDatabase.ftsTableName}')
        .get();
    return rows.first.read<int>('c');
  }

  Future<int> userVersion(AppDatabase db) async {
    final rows = await db.customSelect('PRAGMA user_version').get();
    return rows.first.data.values.first as int;
  }

  test('a fresh install creates the index at onCreate', () async {
    final db = openDb();
    await db.customSelect('SELECT 1').get();

    expect(await ftsTableExists(db), isTrue);
    expect(await userVersion(db), 5);

    await db.close();
  });

  test('upgrading from v4 creates the index and backfills existing rows',
      () async {
    // 1. A populated database on the old schema.
    var db = openDb();
    var store = PlaintextStore.forTesting(db);
    await store.saveMessagesBatch([
      _msg('m1', 'dinner reservation at eight'),
      _msg('m2', 'the quarterly numbers look fine'),
      _msg('m3', 'café on the corner'),
    ], _room);
    await rewindToV4(db);
    expect(await ftsTableExists(db), isFalse,
        reason: 'the rewind did not actually remove the index');
    await db.close();

    // 2. Reopen — onUpgrade(from: 4, to: 5) runs.
    db = openDb();
    store = PlaintextStore.forTesting(db);
    await db.customSelect('SELECT 1').get();

    expect(await ftsTableExists(db), isTrue);
    expect(await userVersion(db), 5);
    expect(await ftsRowCount(db), 3,
        reason: 'the backfill missed pre-existing messages');

    // 3. The messages that predate the upgrade are searchable — the thing the
    //    backfill exists to guarantee.
    expect(
      (await store.searchMessages(_room, 'reservation')).map((m) => m.id),
      ['m1'],
    );
    expect(
      (await store.searchMessages(_room, 'quarterly')).map((m) => m.id),
      ['m2'],
    );
    // Diacritic folding comes from the tokenizer, so it has to survive a
    // backfill as much as a live insert.
    expect(
      (await store.searchMessages(_room, 'cafe')).map((m) => m.id),
      ['m3'],
    );

    await db.close();
  });

  test('an upgrade with no local history is a no-op, not a failure', () async {
    var db = openDb();
    await rewindToV4(db);
    await db.close();

    db = openDb();
    await db.customSelect('SELECT 1').get();

    expect(await ftsTableExists(db), isTrue);
    expect(await ftsRowCount(db), 0);

    await db.close();
  });

  test('a row with unparseable JSON is skipped, not fatal', () async {
    // The backfill reads `message_json` directly. One corrupt row from an older
    // build must cost its own indexing and nothing else — throwing here would
    // leave the database stuck below v5 and the app unable to open at all.
    var db = openDb();
    final store = PlaintextStore.forTesting(db);
    await store.saveMessage(_msg('good', 'perfectly fine message'), _room);
    await db.customStatement(
      "INSERT INTO local_messages (id, chat_room_id, \"timestamp\", message_json) "
      "VALUES ('bad', ?, 1700000000000, 'not json at all')",
      [_room],
    );
    await rewindToV4(db);
    await db.close();

    db = openDb();
    await expectLater(db.customSelect('SELECT 1').get(), completes);

    expect(await ftsTableExists(db), isTrue);
    expect(await userVersion(db), 5);
    expect(
      (await PlaintextStore.forTesting(db).searchMessages(_room, 'perfectly'))
          .map((m) => m.id),
      ['good'],
    );

    await db.close();
  });

  test('re-running the backfill does not duplicate rows', () async {
    // `backfillFts` opens with a DELETE for exactly this reason: an interrupted
    // migration that runs again must not double every message in the index.
    final db = openDb();
    final store = PlaintextStore.forTesting(db);
    await store.saveMessagesBatch([
      _msg('m1', 'alpha'),
      _msg('m2', 'beta'),
    ], _room);

    await db.backfillFts();
    await db.backfillFts();

    expect(await ftsRowCount(db), 2);
    expect((await store.searchMessages(_room, 'alpha')).map((m) => m.id),
        ['m1']);

    await db.close();
  });
}
