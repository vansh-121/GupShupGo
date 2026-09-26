// AppDatabase — Drift-based local SQLite database for GupShupGo.
//
// Replaces the hand-written sqflite schema from PlaintextStore. Three tables:
//
//   • MessagePlaintexts — decrypted E2EE payloads keyed by message ID
//   • ChatRoomPreviews — last-message text per chat room (chat list preview)
//   • LocalMessages     — full MessageModel JSON for local-first rendering
//
// Plus one virtual table Drift can't model, `message_fts` — the FTS5 index
// behind in-chat search. See [AppDatabase.createFtsTable].
//
// The DB file is intentionally named `gsg_plaintext.db` (same as the old
// sqflite file) so Drift opens the existing file transparently — no data
// migration needed.

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'app_database.g.dart';

// ─── Table definitions ──────────────────────────────────────────────────────

/// Decrypted E2EE message payloads. Primary cache — a Signal ciphertext can
/// only be decrypted once, so we persist the result here for future renders.
/// Also stores status content (`status_content:*`) and status keys
/// (`status_key:*`) using the same table with prefixed IDs.
class MessagePlaintexts extends Table {
  @override
  String get tableName => 'message_plaintext';

  TextColumn get id => text()();
  TextColumn get payload => text()();
  IntColumn get savedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Last-message preview per chat room. Populated on both send and receive so
/// the chat list can render decrypted text instead of "🔒 Encrypted message".
class ChatRoomPreviews extends Table {
  @override
  String get tableName => 'chat_room_preview';

  TextColumn get chatRoomId => text()();
  TextColumn get lastMessageText => text()();
  TextColumn get lastMessageId => text()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {chatRoomId};
}

/// Full MessageModel JSON stored locally for offline-first rendering.
/// The SyncService populates this from Firestore snapshots; the UI reads from
/// here via `watchMessages()`.
class LocalMessages extends Table {
  @override
  String get tableName => 'local_messages';

  TextColumn get id => text()();
  TextColumn get chatRoomId => text()();
  TextColumn get messageJson => text()();
  IntColumn get timestamp => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Database class ─────────────────────────────────────────────────────────

@DriftDatabase(tables: [MessagePlaintexts, ChatRoomPreviews, LocalMessages])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  /// Opens an isolated database on [executor] instead of the app's on-disk
  /// file, bypassing the singleton entirely.
  ///
  /// For tests: the FTS5 index and the v4→v5 migration are the two pieces of
  /// this file that can't be verified by reading them, because both depend on
  /// what the bundled SQLite build actually supports at runtime.
  @visibleForTesting
  AppDatabase.forTesting(super.executor);

  /// Lazy singleton — mirrors the old `PlaintextStore.instance()` pattern.
  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase._();

  /// Reset the singleton (used on sign-out to ensure a fresh DB on re-login).
  static void resetInstance() {
    _instance?.close();
    _instance = null;
  }

  /// Schema version.
  ///
  ///  * 4 — performance indexes on local_messages(chatRoomId, timestamp) and
  ///    message_plaintext(savedAt).
  ///  * 5 — the `message_fts` FTS5 index behind in-chat search.
  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          // New installs get indexes from the start.
          await _createIndexes();
          await createFtsTable();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(chatRoomPreviews);
          }
          if (from < 3) {
            await m.createTable(localMessages);
          }
          if (from < 4) {
            await _createIndexes();
          }
          if (from < 5) {
            await createFtsTable();
            await backfillFts();
          }
        },
      );

  /// Creates performance-critical indexes that prevent full table scans
  /// on the core chat queries (filter by chatRoomId, order by timestamp).
  /// Uses raw SQL via customStatement since Drift's Migrator doesn't
  /// expose CREATE INDEX natively.
  ///
  /// NOTE: Column names must use Drift's SQL convention (snake_case):
  ///   chatRoomId → chat_room_id, savedAt → saved_at
  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_local_messages_room_time '
      'ON local_messages(chat_room_id, "timestamp")');
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_message_plaintext_saved '
      'ON message_plaintext(saved_at)');
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_chat_room_preview_updated '
      'ON chat_room_preview(updated_at)');
  }

  /// Creates the full-text index behind in-chat search.
  ///
  /// Same `customStatement` escape hatch as [_createIndexes], for the same
  /// reason: Drift's `Migrator` has no vocabulary for a virtual table, and a
  /// generated table class would be wrong here anyway — an FTS5 table has no
  /// real columns to model. Keeping it out of `@DriftDatabase` also means the
  /// codegen'd `.g.dart` doesn't try to `createAll()` it twice.
  ///
  /// It is a plain (non-external-content) FTS5 table, deliberately: a
  /// `content=` table would have to be kept in sync with `local_messages` by
  /// triggers over `message_json`, and the searchable text is a *field inside*
  /// that JSON, not a column. [PlaintextStore] owns the four write paths
  /// instead, which is both explicit and the only way to index a decrypted
  /// body that never exists as a column.
  ///
  /// `remove_diacritics 2` folds accents correctly for multi-byte characters
  /// (level 1 is the legacy, Latin-1-only behaviour) so "café" matches "cafe".
  ///
  /// **This index holds decrypted message text.** It lives in the same local
  /// DB file as `local_messages`, which already holds the same plaintext, so it
  /// widens nothing — but it must be wiped on sign-out with everything else.
  static const String ftsTableName = 'message_fts';

  Future<void> createFtsTable() async {
    await customStatement(
      'CREATE VIRTUAL TABLE IF NOT EXISTS $ftsTableName USING fts5('
      'body, '
      'message_id UNINDEXED, '
      'chat_room_id UNINDEXED, '
      "tokenize='unicode61 remove_diacritics 2')",
    );
  }

  /// One-time population of [ftsTableName] from the rows that already exist.
  ///
  /// Without this, search on an upgraded install would only ever find messages
  /// received *after* the upgrade — the failure mode is silent and looks
  /// exactly like "search is broken", so it runs as part of the v5 migration
  /// rather than lazily.
  ///
  /// Reads `message_json` directly rather than going through `MessageModel`:
  /// this runs inside the migration, before `PlaintextStore` exists, and a row
  /// that fails to parse should cost its own indexing and nothing else.
  Future<void> backfillFts() async {
    await customStatement('DELETE FROM $ftsTableName');
    final rows = await customSelect(
      'SELECT id, chat_room_id, message_json FROM local_messages',
    ).get();

    for (final row in rows) {
      try {
        final json = row.read<String>('message_json');
        final decoded = jsonDecode(json);
        if (decoded is! Map) continue;
        final body = decoded['text'];
        if (body is! String || body.trim().isEmpty) continue;
        await customInsert(
          'INSERT INTO $ftsTableName(body, message_id, chat_room_id) '
          'VALUES (?, ?, ?)',
          variables: [
            Variable<String>(body),
            Variable<String>(row.read<String>('id')),
            Variable<String>(row.read<String>('chat_room_id')),
          ],
        );
      } catch (_) {
        // A single unparseable row must not abort the migration and strand the
        // database between versions.
      }
    }
  }
}

// ─── Connection factory ─────────────────────────────────────────────────────

/// Helper to get the default SQLite databases path on Android and iOS
/// without relying on the sqflite package.
Future<String> getDatabasesPath() async {
  if (Platform.isAndroid) {
    final docDir = await getApplicationDocumentsDirectory();
    final parentDir = Directory(docDir.path).parent.path;
    return p.join(parentDir, 'databases');
  } else if (Platform.isIOS) {
    final docDir = await getApplicationDocumentsDirectory();
    return docDir.path;
  } else {
    final docDir = await getApplicationSupportDirectory();
    return docDir.path;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // Ensure sqlite3 native library is available on Android
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();

    // Use the same databases directory sqflite used, so the existing
    // `gsg_plaintext.db` file is opened transparently.
    final dbDir = await getDatabasesPath();
    final dbFile = File(p.join(dbDir, 'gsg_plaintext.db'));

    return NativeDatabase.createInBackground(dbFile);
  });
}
