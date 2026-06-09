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
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:video_chat_app/models/message_model.dart';

class PlaintextStore {
  PlaintextStore._(this._db);
  final Database _db;

  static const _dbName = 'gsg_plaintext.db';
  static const _table = 'message_plaintext';
  static const _roomTable = 'chat_room_preview';
  static const _messagesTable = 'local_messages';

  static PlaintextStore? _instance;
  static Completer<PlaintextStore>? _opening;

  final _messageUpdates = StreamController<String>.broadcast();

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
        version: 3,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE $_table (
              id TEXT PRIMARY KEY,
              payload TEXT NOT NULL,
              saved_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE $_roomTable (
              chat_room_id TEXT PRIMARY KEY,
              last_message_text TEXT NOT NULL,
              last_message_id TEXT NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE $_messagesTable (
              id TEXT PRIMARY KEY,
              chat_room_id TEXT NOT NULL,
              message_json TEXT NOT NULL,
              timestamp INTEGER NOT NULL
            )
          ''');
        },
        onUpgrade: (db, oldV, newV) async {
          if (oldV < 2) {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS $_roomTable (
                chat_room_id TEXT PRIMARY KEY,
                last_message_text TEXT NOT NULL,
                last_message_id TEXT NOT NULL,
                updated_at INTEGER NOT NULL
              )
            ''');
          }
          if (oldV < 3) {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS $_messagesTable (
                id TEXT PRIMARY KEY,
                chat_room_id TEXT NOT NULL,
                message_json TEXT NOT NULL,
                timestamp INTEGER NOT NULL
              )
            ''');
          }
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

  /// Persists the last decrypted text for a chat room. Called on both
  /// sides — sender at sendMessage time, receiver at decrypt time — so the
  /// chat list can render a real preview instead of "🔒 Encrypted message".
  Future<void> saveRoomPreview({
    required String chatRoomId,
    required String messageId,
    required String text,
  }) async {
    await _db.insert(
      _roomTable,
      {
        'chat_room_id': chatRoomId,
        'last_message_text': text,
        'last_message_id': messageId,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetches the local preview text for one chat room, or null if we don't
  /// have one yet.
  Future<String?> getRoomPreview(String chatRoomId) async {
    final rows = await _db.query(
      _roomTable,
      columns: const ['last_message_text'],
      where: 'chat_room_id = ?',
      whereArgs: [chatRoomId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['last_message_text'] as String?;
  }

  /// Bulk preview lookup that also returns each preview's `updated_at`
  /// (milliseconds since epoch) and the message id it was generated from.
  /// Callers use the timestamp to decide whether the cached preview is still
  /// fresh enough — if the chat room's lastMessageTime is newer, the cached
  /// preview is stale (e.g. we sent the last message earlier, then the peer
  /// replied) and must be re-derived.
  Future<Map<String, ({String text, String messageId, int updatedAt})>>
      getAllRoomPreviewsWithMeta() async {
    final rows = await _db.query(_roomTable, columns: const [
      'chat_room_id',
      'last_message_text',
      'last_message_id',
      'updated_at',
    ]);
    return {
      for (final r in rows)
        r['chat_room_id'] as String: (
          text: r['last_message_text'] as String,
          messageId: (r['last_message_id'] as String?) ?? '',
          updatedAt: (r['updated_at'] as int?) ?? 0,
        ),
    };
  }

  /// Persists the decrypted form of a status item so the next app launch
  /// can render it instantly — WhatsApp's "I've already seen this status,
  /// show it offline" guarantee. For text items we save the plaintext JSON
  /// fields directly; for media we point to a file on disk (written
  /// separately by the caller into [mediaCacheDir]).
  Future<void> saveStatusContent({
    required String itemId,
    required String type, // 'text' | 'media'
    String? text,
    String? backgroundColor,
    String? mediaPath,
    bool isVideo = false,
  }) async {
    await _db.insert(
      _table,
      {
        'id': 'status_content:$itemId',
        'payload': jsonEncode({
          't': type,
          if (text != null) 'tx': text,
          if (backgroundColor != null) 'bg': backgroundColor,
          if (mediaPath != null) 'mp': mediaPath,
          'v': isVideo,
        }),
        'saved_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getStatusContent(String itemId) async {
    final rows = await _db.query(
      _table,
      columns: const ['payload'],
      where: 'id = ?',
      whereArgs: ['status_content:$itemId'],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['payload'] as String)
        as Map<String, dynamic>;
  }

  /// Persistent directory for decrypted status media. Lives next to the
  /// SQLite DB so it survives process restarts (unlike systemTemp, which
  /// the OS wipes whenever it feels like it).
  Future<String> mediaCacheDir() async {
    final dbDir = await getDatabasesPath();
    final mediaDir = p.join(dbDir, 'gsg_status_media');
    await Directory(mediaDir).create(recursive: true);
    return mediaDir;
  }

  /// Save the AES content key for a status item this device posted, so the
  /// owner can decrypt their own status without a Signal-to-self envelope
  /// (which would advance the ratchet and break local decrypt). Stored in
  /// the same table with a `status_key:` id prefix to avoid a schema bump.
  Future<void> saveStatusKey(String statusItemId, Uint8List key) async {
    await _db.insert(
      _table,
      {
        'id': 'status_key:$statusItemId',
        'payload': jsonEncode({'k': base64Encode(key)}),
        'saved_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetches the locally-cached content key for an owner's own status item,
  /// or null if this device didn't post it.
  Future<Uint8List?> getStatusKey(String statusItemId) async {
    final rows = await _db.query(
      _table,
      columns: const ['payload'],
      where: 'id = ?',
      whereArgs: ['status_key:$statusItemId'],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final payload =
        jsonDecode(rows.first['payload'] as String) as Map<String, dynamic>;
    return base64Decode(payload['k'] as String);
  }

  /// Bulk-reads the most-recent [limit] regular message payloads (excludes
  /// status_* rows) into a single map. Used by ChatService._preWarmPayloadCache
  /// to populate _payloadMemo in one SQLite query instead of N per-message
  /// queries. Bounded to [limit] rows so the load time stays sub-50ms even on
  /// heavy accounts; messages outside the window fall through to the per-row
  /// SQLite path in decryptForRendering.
  Future<Map<String, Map<String, dynamic>>> getAllMessagePayloads({
    int? limit = 500,
  }) async {
    final rows = await _db.query(
      _table,
      columns: const ['id', 'payload'],
      where: "id NOT LIKE 'status_%'",
      orderBy: 'saved_at DESC',
      limit: limit,
    );
    final result = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      try {
        result[row['id'] as String] =
            jsonDecode(row['payload'] as String) as Map<String, dynamic>;
      } catch (_) {}
    }
    return result;
  }

  /// Drops all rows. Called from AuthService.signOut.
  Future<void> wipe() async {
    await _db.delete(_table);
    await _db.delete(_roomTable);
    await _db.delete(_messagesTable);
  }

  /// Removes the cached plaintext for a single message id. Used by the
  /// retention sweep so previews of pruned messages don't linger in the
  /// chat list. Best-effort: missing rows are a no-op.
  Future<void> delete(String messageId) async {
    await _db.delete(_table, where: 'id = ?', whereArgs: [messageId]);
  }

  /// Bulk-reads all `status_content:*` rows into a map keyed by the bare
  /// status item id (prefix stripped). Used by
  /// StatusService.preWarmFromDisk() to populate the in-memory plaintext
  /// cache in a single SQLite query at app launch.
  Future<Map<String, Map<String, dynamic>>> getAllStatusContents() async {
    final rows = await _db.query(
      _table,
      columns: const ['id', 'payload'],
      where: "id LIKE 'status_content:%'",
    );
    final result = <String, Map<String, dynamic>>{};
    const prefixLen = 'status_content:'.length;
    for (final row in rows) {
      try {
        final rawId = row['id'] as String;
        final itemId = rawId.substring(prefixLen);
        result[itemId] =
            jsonDecode(row['payload'] as String) as Map<String, dynamic>;
      } catch (_) {}
    }
    return result;
  }

  // ─── Local Messages CRUD & Reactive Stream API ────────────────────────────

  Stream<String> get messageUpdates => _messageUpdates.stream;

  void notifyUpdate(String chatRoomId) {
    _messageUpdates.add(chatRoomId);
  }

  /// Save a single MessageModel locally
  Future<void> saveMessage(MessageModel message, String chatRoomId) async {
    await _db.insert(
      _messagesTable,
      {
        'id': message.id,
        'chat_room_id': chatRoomId,
        'message_json': jsonEncode(message.toJson()),
        'timestamp': message.timestamp.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyUpdate(chatRoomId);
  }

  /// Batch save messages locally
  Future<void> saveMessagesBatch(List<MessageModel> messages, String chatRoomId) async {
    if (messages.isEmpty) return;
    final batch = _db.batch();
    for (final msg in messages) {
      batch.insert(
        _messagesTable,
        {
          'id': msg.id,
          'chat_room_id': chatRoomId,
          'message_json': jsonEncode(msg.toJson()),
          'timestamp': msg.timestamp.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    notifyUpdate(chatRoomId);
  }

  /// Fetch all messages for a chat room, sorted by timestamp ascending
  Future<List<MessageModel>> getMessages(String chatRoomId) async {
    final rows = await _db.query(
      _messagesTable,
      where: 'chat_room_id = ?',
      whereArgs: [chatRoomId],
      orderBy: 'timestamp ASC',
    );
    final list = <MessageModel>[];
    for (final r in rows) {
      try {
        final jsonStr = r['message_json'] as String;
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        list.add(MessageModel.fromJson(map));
      } catch (_) {}
    }
    return list;
  }

  /// Get the latest message timestamp stored locally for a chat room
  Future<int?> getLatestMessageTimestamp(String chatRoomId) async {
    final rows = await _db.query(
      _messagesTable,
      columns: const ['timestamp'],
      where: 'chat_room_id = ?',
      whereArgs: [chatRoomId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['timestamp'] as int?;
  }

  /// Fetch specific messages by ID
  Future<List<MessageModel>> getMessagesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await _db.query(
      _messagesTable,
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
    final list = <MessageModel>[];
    for (final r in rows) {
      try {
        final jsonStr = r['message_json'] as String;
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        list.add(MessageModel.fromJson(map));
      } catch (_) {}
    }
    return list;
  }

  /// Delete a message locally
  Future<void> deleteMessage(String messageId, String chatRoomId) async {
    await _db.delete(
      _messagesTable,
      where: 'id = ?',
      whereArgs: [messageId],
    );
    notifyUpdate(chatRoomId);
  }

  /// Returns a reactive stream of messages for [chatRoomId], updating whenever
  /// any message in that room is saved or deleted.
  Stream<List<MessageModel>> watchMessages(String chatRoomId) {
    final controller = StreamController<List<MessageModel>>();
    StreamSubscription? sub;

    Future<void> emit() async {
      try {
        final msgs = await getMessages(chatRoomId);
        if (!controller.isClosed) {
          controller.add(msgs);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    controller.onListen = () {
      emit();
      sub = _messageUpdates.stream
          .where((updatedId) => updatedId == chatRoomId)
          .listen((_) => emit());
    };

    controller.onCancel = () async {
      await sub?.cancel();
    };

    return controller.stream;
  }
}
