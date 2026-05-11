// PlaintextStore — local sqflite-backed cache of decrypted message bodies.
//
// Why this exists:
//
// A Signal ciphertext can be decrypted exactly ONCE. The chain ratchet
// advances on every successful decrypt and refuses to re-process the same
// counter (DuplicateMessageException). The Firestore message stream, by
// contrast, re-emits the entire chat list every time *anything* in the chat
// room doc changes (read receipts, typing indicators, delivery status), so
// the same MessageModel flows through `decryptForRendering` over and over.
//
// WhatsApp solves this by persisting decrypted plaintext to a local SQLite
// database. The ciphertext on the server is only ever consulted for
// transport — the UI reads from local storage. We do the same here:
//
//   • On send → store our own plaintext keyed by message id.
//   • On first successful receive-side decrypt → store the plaintext.
//   • On every render → consult the store before touching libsignal.
//
// Lifecycle: wiped on signOut (same as the Signal stores). Otherwise the
// DB lives for the lifetime of the install — that's how WhatsApp history
// survives ratchet advances.

import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class PlaintextStore {
  PlaintextStore._(this._db);
  final Database _db;

  static const _dbName = 'gsg_plaintext.db';
  static const _table = 'message_plaintext';

  static PlaintextStore? _instance;
  static Completer<PlaintextStore>? _opening;

  /// Lazily opens the DB on first call. Concurrent callers share the same
  /// Future so we don't open twice from different code paths.
  static Future<PlaintextStore> instance() async {
    if (_instance != null) return _instance!;
    if (_opening != null) return _opening!.future;
    _opening = Completer<PlaintextStore>();
    try {
      final dbDir = await getDatabasesPath();
      final db = await openDatabase(
        p.join(dbDir, _dbName),
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE $_table (
              id TEXT PRIMARY KEY,
              payload TEXT NOT NULL,
              saved_at INTEGER NOT NULL
            )
          ''');
        },
      );
      _instance = PlaintextStore._(db);
      _opening!.complete(_instance!);
      return _instance!;
    } catch (e) {
      _opening!.completeError(e);
      _opening = null;
      rethrow;
    }
  }

  /// Persists the plaintext payload for `messageId`. Idempotent — re-saving
  /// the same id is a no-op (we keep the earliest entry).
  Future<void> save(String messageId, Map<String, dynamic> payload) async {
    await _db.insert(
      _table,
      {
        'id': messageId,
        'payload': jsonEncode(payload),
        'saved_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Fetches the saved plaintext for `messageId`, or null if we never
  /// decrypted/sent it on this device.
  Future<Map<String, dynamic>?> get(String messageId) async {
    final rows = await _db.query(
      _table,
      columns: const ['payload'],
      where: 'id = ?',
      whereArgs: [messageId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['payload'] as String)
        as Map<String, dynamic>;
  }

  /// Drops all rows. Called from AuthService.signOut.
  Future<void> wipe() async {
    await _db.delete(_table);
  }
}
