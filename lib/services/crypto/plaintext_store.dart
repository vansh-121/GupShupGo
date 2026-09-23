// PlaintextStore — Drift-backed cache of decrypted message bodies.
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

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/services/database/app_database.dart';

class PlaintextStore {
  PlaintextStore._(this._db);

  /// Binds a store to a caller-supplied database — an in-memory
  /// `NativeDatabase.memory()` in tests, so the FTS index can be exercised
  /// without touching the on-device file or the [instance] singleton.
  ///
  /// Tests need this because the index is maintained at *four* separate write
  /// sites in this class ([saveMessage], [saveMessagesBatch], [deleteMessage],
  /// [wipe]); asserting on raw SQL instead would test the schema while leaving
  /// the sync points — the part that actually rots — uncovered.
  ///
  /// Not annotated `@visibleForTesting`: `drift.dart` exports its own
  /// `visibleForTesting` symbol, which shadows the `meta` annotation here and
  /// fails to compile. [AppDatabase.forTesting] is declared the same way.
  PlaintextStore.forTesting(AppDatabase db) : _db = db;

  final AppDatabase _db;

  static PlaintextStore? _instance;
  static Completer<PlaintextStore>? _opening;

  /// Lazily opens the DB on first call. Concurrent callers share the same
  /// Future so we don't open twice from different code paths.
  static Future<PlaintextStore> instance() async {
    if (_instance != null) return _instance!;
    if (_opening != null) return _opening!.future;
    _opening = Completer<PlaintextStore>();
    try {
      final db = AppDatabase.instance;
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
    await _db.into(_db.messagePlaintexts).insert(
      MessagePlaintextsCompanion.insert(
        id: messageId,
        payload: jsonEncode(payload),
        savedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// Fetches the saved plaintext for `messageId`, or null if we never
  /// decrypted/sent it on this device.
  Future<Map<String, dynamic>?> get(String messageId) async {
    final query = _db.select(_db.messagePlaintexts)
      ..where((tbl) => tbl.id.equals(messageId));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return jsonDecode(row.payload) as Map<String, dynamic>;
  }

  /// Persists the last decrypted text for a chat room. Called on both
  /// sides — sender at sendMessage time, receiver at decrypt time — so the
  /// chat list can render a real preview instead of "🔒 Encrypted message".
  Future<void> saveRoomPreview({
    required String chatRoomId,
    required String messageId,
    required String text,
  }) async {
    await _db.into(_db.chatRoomPreviews).insert(
      ChatRoomPreviewsCompanion.insert(
        chatRoomId: chatRoomId,
        lastMessageText: text,
        lastMessageId: messageId,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Fetches the local preview text for one chat room, or null if we don't
  /// have one yet.
  Future<String?> getRoomPreview(String chatRoomId) async {
    final query = _db.select(_db.chatRoomPreviews)
      ..where((tbl) => tbl.chatRoomId.equals(chatRoomId));
    final row = await query.getSingleOrNull();
    return row?.lastMessageText;
  }

  /// Bulk preview lookup that also returns each preview's `updated_at`
  /// (milliseconds since epoch) and the message id it was generated from.
  /// Callers use the timestamp to decide whether the cached preview is still
  /// fresh enough — if the chat room's lastMessageTime is newer, the cached
  /// preview is stale (e.g. we sent the last message earlier, then the peer
  /// replied) and must be re-derived.
  Future<Map<String, ({String text, String messageId, int updatedAt})>>
      getAllRoomPreviewsWithMeta() async {
    final rows = await _db.select(_db.chatRoomPreviews).get();
    return {
      for (final r in rows)
        r.chatRoomId: (
          text: r.lastMessageText,
          messageId: r.lastMessageId,
          updatedAt: r.updatedAt,
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
    await _db.into(_db.messagePlaintexts).insert(
      MessagePlaintextsCompanion.insert(
        id: 'status_content:$itemId',
        payload: jsonEncode({
          't': type,
          if (text != null) 'tx': text,
          if (backgroundColor != null) 'bg': backgroundColor,
          if (mediaPath != null) 'mp': mediaPath,
          'v': isVideo,
        }),
        savedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<Map<String, dynamic>?> getStatusContent(String itemId) async {
    final query = _db.select(_db.messagePlaintexts)
      ..where((tbl) => tbl.id.equals('status_content:$itemId'));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return jsonDecode(row.payload) as Map<String, dynamic>;
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
    await _db.into(_db.messagePlaintexts).insert(
      MessagePlaintextsCompanion.insert(
        id: 'status_key:$statusItemId',
        payload: jsonEncode({'k': base64Encode(key)}),
        savedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Fetches the locally-cached content key for an owner's own status item,
  /// or null if this device didn't post it.
  Future<Uint8List?> getStatusKey(String statusItemId) async {
    final query = _db.select(_db.messagePlaintexts)
      ..where((tbl) => tbl.id.equals('status_key:$statusItemId'));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    final payload = jsonDecode(row.payload) as Map<String, dynamic>;
    return base64Decode(payload['k'] as String);
  }

  // ─── Resend-protocol bookkeeping ──────────────────────────────────────
  //
  // Both halves of the resend protocol need a little state that survives a
  // restart, and both live in `messagePlaintexts` behind an id prefix rather
  // than in new tables — the same trick as `status_key:` above. That means no
  // schema migration, and `wipe()` keeps covering them for free.
  //
  // Keep [getAllMessagePayloads]'s exclusion list in sync when adding a
  // prefix here, or the bookkeeping rows will be loaded into ChatService's
  // payload memo and evict real messages from it.

  /// Receiver side: resend bookkeeping for [messageId].
  ///
  /// [attempts] is the **lifetime** count and only ever increases. It numbers
  /// the request tag on the wire, and the sender ignores any number it has
  /// already answered, so restarting the numbering would make a request
  /// invisible — `arrayUnion` would also treat the repeated tag as a no-op, so
  /// the request would never even reach the document.
  ///
  /// The attempt *cap* therefore applies to the current round rather than to
  /// [attempts]: [roundStart] is what [attempts] was when the round opened, and
  /// [sessionId] / [generation] record the conditions it opened under, so a
  /// later app launch or a peer coming back online can start a fresh one. See
  /// `ChatService.evaluateResendRound`.
  Future<void> saveRetryState(
    String messageId, {
    required int attempts,
    required int atMs,
    required int roundStart,
    required int sessionId,
    required int generation,
  }) async {
    await _db.into(_db.messagePlaintexts).insert(
      MessagePlaintextsCompanion.insert(
        id: 'retry:$messageId',
        payload: jsonEncode({
          'n': attempts,
          'at': atMs,
          'rs': roundStart,
          's': sessionId,
          'g': generation,
        }),
        savedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Rows written before rounds existed carry only `n` and `at`. They read back
  /// with `roundStart: 0` — so the round looks exhausted — and `sessionId: -1`,
  /// which can never match a real session id, so the next launch opens a fresh
  /// round. That is exactly the migration a bubble wants if it hardened under
  /// the old lifetime cap.
  Future<
      ({
        int attempts,
        int atMs,
        int roundStart,
        int sessionId,
        int generation
      })?> getRetryState(String messageId) async {
    final query = _db.select(_db.messagePlaintexts)
      ..where((tbl) => tbl.id.equals('retry:$messageId'));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    try {
      final map = jsonDecode(row.payload) as Map<String, dynamic>;
      return (
        attempts: map['n'] as int,
        atMs: map['at'] as int,
        roundStart: (map['rs'] as int?) ?? 0,
        sessionId: (map['s'] as int?) ?? -1,
        generation: (map['g'] as int?) ?? -1,
      );
    } catch (_) {
      return null;
    }
  }

  /// Sender side: the highest request number already answered for
  /// [messageId] from [address] (`"<uid>:<deviceId>"`), or 0 if none.
  ///
  /// Firestore re-emits a document on every change, so without this the
  /// sender would re-encrypt and re-publish an answer to the same request
  /// each time the snapshot is redelivered.
  Future<int> servedRetryAttempt(String messageId, String address) async {
    final query = _db.select(_db.messagePlaintexts)
      ..where((tbl) => tbl.id.equals('served:$messageId|$address'));
    final row = await query.getSingleOrNull();
    if (row == null) return 0;
    try {
      return (jsonDecode(row.payload) as Map<String, dynamic>)['n'] as int;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markRetryServed(
      String messageId, String address, int attempt) async {
    await _db.into(_db.messagePlaintexts).insert(
      MessagePlaintextsCompanion.insert(
        id: 'served:$messageId|$address',
        payload: jsonEncode({'n': attempt}),
        savedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Bulk-reads the most-recent [limit] regular message payloads (excludes
  /// status_* and resend-bookkeeping rows) into a single map. Used by
  /// ChatService._preWarmPayloadCache to populate _payloadMemo in one SQLite
  /// query instead of N per-message queries. Bounded to [limit] rows so the
  /// load time stays sub-50ms even on heavy accounts; messages outside the
  /// window fall through to the per-row SQLite path in decryptForRendering.
  Future<Map<String, Map<String, dynamic>>> getAllMessagePayloads({
    int? limit = 500,
  }) async {
    final query = _db.select(_db.messagePlaintexts)
      ..where((tbl) =>
          tbl.id.like('status_%').not() &
          tbl.id.like('retry:%').not() &
          tbl.id.like('served:%').not())
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.savedAt, mode: OrderingMode.desc)]);
    if (limit != null) {
      query.limit(limit);
    }
    final rows = await query.get();
    final result = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      try {
        result[row.id] = jsonDecode(row.payload) as Map<String, dynamic>;
      } catch (_) {}
    }
    return result;
  }

  /// Drops all rows. Called from AuthService.signOut.
  Future<void> wipe() async {
    await _db.transaction(() async {
      await _db.delete(_db.messagePlaintexts).go();
      await _db.delete(_db.chatRoomPreviews).go();
      await _db.delete(_db.localMessages).go();
      // FTS sync point 1 of 4. The index holds decrypted message bodies, so it
      // has to go out with the rest of the plaintext — and inside the same
      // transaction, or a crash mid-wipe would leave a searchable residue of
      // the signed-out account.
      await _db.customStatement('DELETE FROM ${AppDatabase.ftsTableName}');
    });
  }

  /// Removes the cached plaintext for a single message id. Used by the
  /// retention sweep so previews of pruned messages don't linger in the
  /// chat list. Best-effort: missing rows are a no-op.
  Future<void> delete(String messageId) async {
    await (_db.delete(_db.messagePlaintexts)
          ..where((tbl) => tbl.id.equals(messageId)))
        .go();
  }

  /// Bulk-reads all `status_content:*` rows into a map keyed by the bare
  /// status item id (prefix stripped). Used by
  /// StatusService.preWarmFromDisk() to populate the in-memory plaintext
  /// cache in a single SQLite query at app launch.
  Future<Map<String, Map<String, dynamic>>> getAllStatusContents() async {
    final query = _db.select(_db.messagePlaintexts)
      ..where((tbl) => tbl.id.like('status_content:%'));
    final rows = await query.get();
    final result = <String, Map<String, dynamic>>{};
    const prefixLen = 'status_content:'.length;
    for (final row in rows) {
      try {
        final rawId = row.id;
        final itemId = rawId.substring(prefixLen);
        result[itemId] = jsonDecode(row.payload) as Map<String, dynamic>;
      } catch (_) {}
    }
    return result;
  }

  // ─── Local Messages CRUD & Reactive Stream API ────────────────────────────

  /// Save a single MessageModel locally
  Future<void> saveMessage(MessageModel message, String chatRoomId) async {
    await _db.into(_db.localMessages).insert(
      LocalMessagesCompanion.insert(
        id: message.id,
        chatRoomId: chatRoomId,
        messageJson: jsonEncode(message.toJson()),
        timestamp: message.timestamp.millisecondsSinceEpoch,
      ),
      mode: InsertMode.insertOrReplace,
    );
    // FTS sync point 2 of 4.
    await _reindex(message, chatRoomId);
  }

  /// Batch save messages locally
  Future<void> saveMessagesBatch(List<MessageModel> messages, String chatRoomId) async {
    if (messages.isEmpty) return;
    await _db.batch((batch) {
      for (final msg in messages) {
        batch.insert(
          _db.localMessages,
          LocalMessagesCompanion.insert(
            id: msg.id,
            chatRoomId: chatRoomId,
            messageJson: jsonEncode(msg.toJson()),
            timestamp: msg.timestamp.millisecondsSinceEpoch,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
    // FTS sync point 3 of 4. Outside the batch: `batch` only accepts Drift's
    // own generated statements, and `message_fts` is a virtual table with no
    // generated class. A separate pass is also cheap — FTS5 inserts are append
    // only and this runs off the UI isolate's critical path.
    for (final msg in messages) {
      await _reindex(msg, chatRoomId);
    }
  }

  /// Fetch all messages for a chat room, sorted by timestamp ascending
  Future<List<MessageModel>> getMessages(String chatRoomId) async {
    final query = _db.select(_db.localMessages)
      ..where((tbl) => tbl.chatRoomId.equals(chatRoomId))
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.timestamp, mode: OrderingMode.asc)]);
    final rows = await query.get();
    final list = <MessageModel>[];
    for (final r in rows) {
      try {
        final map = jsonDecode(r.messageJson) as Map<String, dynamic>;
        list.add(MessageModel.fromJson(map));
      } catch (_) {}
    }
    return list;
  }

  /// Get the latest message timestamp stored locally for a chat room
  Future<int?> getLatestMessageTimestamp(String chatRoomId) async {
    final query = _db.select(_db.localMessages)
      ..where((tbl) => tbl.chatRoomId.equals(chatRoomId))
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.timestamp, mode: OrderingMode.desc)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.timestamp;
  }

  /// Fetch specific messages by ID
  Future<List<MessageModel>> getMessagesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final query = _db.select(_db.localMessages)
      ..where((tbl) => tbl.id.isIn(ids));
    final rows = await query.get();
    final list = <MessageModel>[];
    for (final r in rows) {
      try {
        final map = jsonDecode(r.messageJson) as Map<String, dynamic>;
        list.add(MessageModel.fromJson(map));
      } catch (_) {}
    }
    return list;
  }

  /// Add a reaction to a specific message locally
  Future<void> addReaction({
    required String targetMessageId,
    required String chatRoomId,
    required String userId,
    required String emoji,
  }) async {
    final list = await getMessagesByIds([targetMessageId]);
    if (list.isNotEmpty) {
      final msg = list.first;
      final currentReactions = Map<String, String>.from(msg.reactions ?? {});
      currentReactions[userId] = emoji;
      final updatedMsg = msg.copyWith(reactions: currentReactions);
      await saveMessage(updatedMsg, chatRoomId);
    }
  }

  /// Delete a message locally
  Future<void> deleteMessage(String messageId, String chatRoomId) async {
    await (_db.delete(_db.localMessages)
          ..where((tbl) => tbl.id.equals(messageId)))
        .go();
    // FTS sync point 4 of 4.
    await _unindex(messageId);
  }

  // ─── Full-text search ─────────────────────────────────────────────────────
  //
  // Four write paths above keep `message_fts` in step with `local_messages`.
  // Routing every write through them is what makes deletion correct for free:
  // a "delete for everyone" arrives as `asTombstone()` through [saveMessage],
  // whose text is the deleted-message placeholder, so the original body leaves
  // the index without any tombstone-specific code. An **edit** works the same
  // way — [saveMessage] is insertOrReplace and [_reindex] deletes before
  // inserting, so the pre-edit text stops matching the moment the edit lands.

  /// Replaces [message]'s row in the full-text index.
  ///
  /// Delete-then-insert rather than an UPDATE, to mirror the `insertOrReplace`
  /// on the table it shadows: a plain FTS5 table has no unique constraint on
  /// `message_id`, so an insert alone would accumulate a duplicate row per
  /// save and make an edited message match both its old and new text.
  ///
  /// Only `text` is indexed. Media messages carry a human-readable fallback
  /// there (the filename for a document, `📍 Location` for a pin, `🎬 Video`),
  /// so they are findable by name without indexing anything that isn't already
  /// rendered in the bubble. Messages with nothing to index — reactions, a
  /// payload this device can't decrypt — are removed rather than indexed empty.
  Future<void> _reindex(MessageModel message, String chatRoomId) async {
    try {
      await _unindex(message.id);
      final body = message.text.trim();
      if (body.isEmpty) return;
      await _db.customInsert(
        'INSERT INTO ${AppDatabase.ftsTableName}'
        '(body, message_id, chat_room_id) VALUES (?, ?, ?)',
        variables: [
          Variable<String>(body),
          Variable<String>(message.id),
          Variable<String>(chatRoomId),
        ],
      );
    } catch (_) {
      // Search is an enhancement; a failure here must never fail the save that
      // triggered it and lose the message itself.
    }
  }

  Future<void> _unindex(String messageId) async {
    try {
      await _db.customStatement(
        'DELETE FROM ${AppDatabase.ftsTableName} WHERE message_id = ?',
        [messageId],
      );
    } catch (_) {}
  }

  /// Full-text search within one chat room, newest first.
  ///
  /// Unlike the in-memory filter this replaces, it searches the whole local
  /// history rather than the page window currently scrolled into the list — a
  /// word from six months ago is found without paging back to it.
  ///
  /// Returns at most [limit] messages. Ordering is applied after the id lookup
  /// because [getMessagesByIds] is an `IN (…)` query with no inherent order.
  Future<List<MessageModel>> searchMessages(
    String chatRoomId,
    String query, {
    int limit = 200,
  }) async {
    final match = buildFtsQuery(query);
    if (match == null) return [];

    try {
      final rows = await _db.customSelect(
        'SELECT message_id FROM ${AppDatabase.ftsTableName} '
        'WHERE chat_room_id = ? AND ${AppDatabase.ftsTableName} MATCH ? '
        'ORDER BY rank LIMIT ?',
        variables: [
          Variable<String>(chatRoomId),
          Variable<String>(match),
          Variable<int>(limit),
        ],
      ).get();

      final ids = rows.map((r) => r.read<String>('message_id')).toList();
      final found = await getMessagesByIds(ids);
      found.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return found;
    } catch (_) {
      // A malformed MATCH throws inside SQLite rather than returning nothing.
      // [buildFtsQuery] is supposed to make that impossible; this is the
      // belt-and-braces so a search box can never crash a chat.
      return [];
    }
  }

  /// Turns a raw search box string into a safe FTS5 MATCH expression, or null
  /// if there is nothing to search for.
  ///
  /// **This escaping is load-bearing.** FTS5's query language treats `"`, `*`,
  /// `:`, `^`, `(`, `)`, `-`, and the bare words `AND`, `OR`, `NOT` and `NEAR`
  /// as syntax. A user typing `NEAR` or an unbalanced quote would otherwise
  /// throw a SqliteException out of a keystroke handler. Wrapping every token
  /// in double quotes makes it a literal string token, which neutralises all of
  /// it at once — the only character that then matters is `"` itself, escaped
  /// FTS5-style by doubling.
  ///
  /// A trailing `*` on each token gives prefix matching, so results appear
  /// while the user is still typing the word. It goes *outside* the quotes,
  /// where FTS5 reads it as the prefix operator rather than a literal asterisk.
  ///
  /// Exposed (not private) so the escaping can be tested directly — it is the
  /// part most likely to break, and the hardest to notice breaking.
  static String? buildFtsQuery(String raw) {
    final tokens = raw
        .split(RegExp(r'\s+'))
        .map((t) => t.replaceAll('"', '""').trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return null;
    // Implicit AND between tokens: FTS5 treats a space-separated sequence as a
    // conjunction, which is what a multi-word search should mean.
    return tokens.map((t) => '"$t"*').join(' ');
  }

  /// Returns a reactive stream of messages for [chatRoomId], updating whenever
  /// any message in that room is saved or deleted.
  Stream<List<MessageModel>> watchMessages(String chatRoomId) {
    final query = _db.select(_db.localMessages)
      ..where((tbl) => tbl.chatRoomId.equals(chatRoomId))
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.timestamp, mode: OrderingMode.asc)]);
    return query.watch().map((rows) {
      final list = <MessageModel>[];
      for (final r in rows) {
        try {
          final map = jsonDecode(r.messageJson) as Map<String, dynamic>;
          list.add(MessageModel.fromJson(map));
        } catch (_) {}
      }
      return list;
    });
  }
}
