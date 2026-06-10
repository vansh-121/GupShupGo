// AppDatabase — Drift-based local SQLite database for GupShupGo.
//
// Replaces the hand-written sqflite schema from PlaintextStore. Three tables:
//
//   • MessagePlaintexts — decrypted E2EE payloads keyed by message ID
//   • ChatRoomPreviews — last-message text per chat room (chat list preview)
//   • LocalMessages     — full MessageModel JSON for local-first rendering
//
// The DB file is intentionally named `gsg_plaintext.db` (same as the old
// sqflite file) so Drift opens the existing file transparently — no data
// migration needed.

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
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

  /// Lazy singleton — mirrors the old `PlaintextStore.instance()` pattern.
  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase._();

  /// Reset the singleton (used on sign-out to ensure a fresh DB on re-login).
  static void resetInstance() {
    _instance?.close();
    _instance = null;
  }

  /// Schema version MUST match the old sqflite version (3) so that Drift
  /// recognises the existing file and doesn't try to re-create tables.
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(chatRoomPreviews);
          }
          if (from < 3) {
            await m.createTable(localMessages);
          }
        },
      );
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
