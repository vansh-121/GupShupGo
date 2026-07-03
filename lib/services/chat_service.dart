import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/services/crypto/device_identity_service.dart';
import 'package:video_chat_app/services/crypto/plaintext_store.dart';
import 'package:video_chat_app/services/crypto/signal_service.dart';
import 'package:video_chat_app/services/crypto/vault_cipher.dart';
import 'package:video_chat_app/services/fcm_service.dart';
import 'package:video_chat_app/services/gamification_service.dart';

class ChatService {
  static final ChatService instance = ChatService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FCMService _fcmService = FCMService();
  final DeviceIdentityService _deviceIdentity = DeviceIdentityService();
  final String _chatRoomsCollection = 'chatRooms';
  final String _messagesCollection = 'messages';

  // The placeholder we write to chatRoom.lastMessage — the room doc is
  // visible to the server, so we never put plaintext there.
  static const String _encryptedPreviewPlaceholder = '🔒 Encrypted message';

  // What we render in place of an E2EE message that this install can't
  // decrypt. Happens after reinstall: messages encrypted to the old
  // deviceId can't be decrypted with the new device's Signal keys, and if
  // we hadn't decrypted them before reinstall they aren't in the vault
  // either. Showing a placeholder bubble (rather than silently dropping
  // them) tells the user "something arrived here" — so they can ask the
  // sender to resend rather than wondering why blue ticks went up without
  // them seeing anything.
  static const String _undecryptablePlaceholderText =
      VaultCipher.undecryptablePlaceholderText;

  /// Build a placeholder MessageModel for E2EE messages we can't decrypt.
  /// Marks schemaVersion=1 so downstream code skips re-decrypt attempts.
  MessageModel _lockedPlaceholder(MessageModel raw) => raw.copyWith(
        text: _undecryptablePlaceholderText,
        schemaVersion: 1,
      );

  // ─── Local send outbox (WhatsApp-style optimistic UI) ───────────────────
  //
  // The Firestore stream is the source of truth for delivered messages, but
  // it can't render a bubble until the commit lands — that's 100–800ms on a
  // good network, longer on a flaky one. The outbox plugs that gap: the
  // moment sendMessage() is called we build a MessageModel with
  // status=sending, drop it into _outbox, and emit it through every active
  // getMessages() stream so the bubble appears in the same frame as the
  // tap. The actual encrypt + Firestore commit runs in the background; on
  // success the entry is removed (Firestore re-delivers the canonical
  // message with status=sent), on failure the entry is updated to
  // status=failed so the user sees an error indicator and can retry.



  // All decrypted message bodies (both incoming and outgoing) live in a
  // local sqflite DB via PlaintextStore. The Firestore stream is the
  // transport, the local DB is the source of truth for rendering — the
  // same architecture WhatsApp uses.

  /// Returns true iff the peer has at least one device with a published
  /// key bundle (i.e. they've upgraded to an E2EE-capable build).
  ///
  /// Stale-while-revalidate. Cached entries are returned instantly; if the
  /// cached value is older than 5 minutes we kick off a background refresh
  /// but DO NOT block the send. The previous 60-second hard TTL caused a
  /// periodic latency spike — once a minute the first send to a peer
  /// synchronously queried Firestore before encryption could begin, which
  /// is exactly the "sometimes the send is slow, sometimes it's instant"
  /// symptom users perceive.
  static final Map<String, ({DateTime at, bool has})> _peerBundleCache = {};
  static const _peerBundleFreshWindow = Duration(minutes: 5);
  static final Set<String> _peerBundleRefreshInFlight = <String>{};

  Future<bool> _peerHasKeyBundle(String peerUid) async {
    final hit = _peerBundleCache[peerUid];
    if (hit != null) {
      if (DateTime.now().difference(hit.at) > _peerBundleFreshWindow) {
        _refreshPeerBundle(peerUid);
      }
      return hit.has;
    }
    // Try the SignalService device-id cache before hitting Firestore.
    // encryptForUser() will call _listDeviceIds() on the same collection
    // anyway, so reusing its cache saves a redundant Firestore query
    // (~300-500ms) on the first message after cold start. The prewarm
    // path populates this cache at app open, so on a warm path this
    // resolves synchronously from memory.
    try {
      final devices =
          await SignalService.instance.listDeviceIdsCached(peerUid);
      final has = devices.isNotEmpty;
      _peerBundleCache[peerUid] = (at: DateTime.now(), has: has);
      return has;
    } catch (_) {
      // SignalService not initialized yet — fall back to direct query.
      return _fetchPeerBundle(peerUid);
    }
  }

  Future<bool> _fetchPeerBundle(String peerUid) async {
    final snap = await _firestore
        .collection('users')
        .doc(peerUid)
        .collection('devices')
        .where('keyBundle', isNull: false)
        .limit(1)
        .get();
    final has = snap.docs.isNotEmpty;
    _peerBundleCache[peerUid] = (at: DateTime.now(), has: has);
    return has;
  }

  void _refreshPeerBundle(String peerUid) {
    if (_peerBundleRefreshInFlight.contains(peerUid)) return;
    _peerBundleRefreshInFlight.add(peerUid);
    // ignore: discarded_futures
    _fetchPeerBundle(peerUid).whenComplete(() {
      _peerBundleRefreshInFlight.remove(peerUid);
    }).catchError((_) => false);
  }

  // ─── Payload cache pre-warm ──────────────────────────────────────────────
  // On every chat open we bulk-load both the local SQLite store AND the
  // Firestore message vault into _payloadMemo in ONE pass before the message
  // subscription starts. This means the first Firestore snapshot resolves
  // synchronously via memo (no awaits per-message), which is how WhatsApp
  // renders instantly even on a reinstall.
  //
  // The Future is memoised per uid so concurrent opens or rapid navigation
  // between chats never trigger duplicate network reads.
  static final Map<String, Future<void>> _preWarmSqliteCache = {};
  static final Map<String, Future<void>> _preWarmVaultCache = {};

  Future<void> _preWarmSqlite(String uid) {
    return _preWarmSqliteCache.putIfAbsent(uid, () => _doPreWarmSqlite(uid));
  }

  Future<void> _preWarmVault(String uid) {
    return _preWarmVaultCache.putIfAbsent(uid, () => _doPreWarmVault(uid));
  }

  /// Public entry point to trigger both SQLite and Firestore Vault pre-warming
  /// in parallel. Called by SyncService during initialization.
  Future<void> preWarmCaches(String uid) async {
    await Future.wait([
      _preWarmSqlite(uid),
      _preWarmVault(uid),
    ]);
  }

  /// Drop the per-uid pre-warm cache AND the process-wide decrypted-
  /// payload memo so the next chat open re-derives every preview from
  /// disk/vault. Called after VaultCipher unlocks (so previously-skipped
  /// vault reads can complete) and after VaultCipher.reset (so wiped
  /// history doesn't keep rendering from RAM).
  static void invalidatePreWarm(String uid) {
    _preWarmSqliteCache.remove(uid);
    _preWarmVaultCache.remove(uid);
    _payloadMemo.clear();
    // Notify any active chat / chat-list stream subscribers so they can
    // re-decrypt their currently-displayed snapshot without waiting for
    // the next Firestore change. Without this, the home screen card and
    // open chat would stay on the "🔒 can't decrypt" placeholder until
    // some unrelated Firestore event (a typing indicator, a new message)
    // happened to fire.
    _vaultReadyNotifier.add(null);
  }

  // Broadcast tick the moment the vault becomes usable (post-unlock,
  // post-reinstall). Subscribers re-run their decrypt pass against the
  // most recent raw Firestore snapshot they've cached.
  static final StreamController<void> _vaultReadyNotifier =
      StreamController<void>.broadcast();

  Future<void> _doPreWarmSqlite(String uid) async {
    // 1. SQLite bulk-load (local IO, ~10-50ms) — populates memo from prior
    //    decryption sessions on the same install. Bounded to the 500 most-
    //    recent messages so load time stays sub-50ms even on heavy accounts.
    try {
      final store = await PlaintextStore.instance();
      final all = await store.getAllMessagePayloads();
      for (final e in all.entries) {
        _payloadMemo.putIfAbsent(e.key, () => e.value);
      }
    } catch (_) {}
  }

  Future<void> _doPreWarmVault(String uid) async {
    // 2. Firestore vault bulk-read (one network query, not N) — restores
    //    history on reinstall where SQLite was wiped but vault survived.
    //    Bounded to the 500 most-recent docs; older messages fall through to
    //    the per-message vault fallback in decryptForRendering.
    //    Decrypts run on a background isolate via decryptDocsBatch so the
    //    main thread stays free for rendering during cold start.
    if (!VaultCipher.instance.isReady) return;
    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection(_vaultCollection)
          .orderBy('createdAt', descending: true)
          .limit(500)
          .get();
      final pending = <String, Map<String, dynamic>>{};
      for (final doc in snap.docs) {
        if (!_payloadMemo.containsKey(doc.id)) {
          pending[doc.id] = doc.data();
        }
      }
      if (pending.isNotEmpty) {
        final results =
            await VaultCipher.instance.decryptDocsBatch(pending);
        _payloadMemo.addAll(results);
      }
    } catch (_) {}
  }

  // ─── Firestore message vault (cross-install backup) ─────────────────────
  // Decrypted plaintext payloads are mirrored to
  //   users/{uid}/msgVault/{messageId}
  // so that a fresh install can recover message history even after the local
  // PlaintextStore (SQLite) and Signal session state are both wiped. Vault
  // writes are fire-and-forget: the local SQLite store is the primary cache
  // and vault failures are non-fatal.
  static const _vaultCollection = 'msgVault';

  Future<void> _saveToVault(
      String uid, String messageId, Map<String, dynamic> payload) async {
    // Drop the write rather than leak plaintext if the vault key isn't
    // available yet. PlaintextStore still has the message locally; the
    // post-unlock migration in HomeScreen flushes anything missing.
    final enc = await VaultCipher.instance.encryptPayload(payload);
    if (enc == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection(_vaultCollection)
          .doc(messageId)
          .set({...enc, 'createdAt': FieldValue.serverTimestamp()});
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> _loadFromVault(
      String uid, String messageId) async {
    // Await any in-flight bulk prewarm first. If it's already completed, this returns instantly.
    // This prevents firing 100+ concurrent individual Firestore reads when the bulk load
    // is already fetching them or has completed.
    final prewarm = _preWarmVaultCache[uid];
    if (prewarm != null) {
      await prewarm;
      final memo = _payloadMemo[messageId];
      if (memo != null) return memo;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection(_vaultCollection)
          .doc(messageId)
          .get();
      if (!doc.exists) return null;
      return VaultCipher.instance.decryptDoc(doc.data()!);
    } catch (_) {
      return null;
    }
  }

  /// Resolves a Firestore MessageModel into its rendered form.
  ///
  /// • v1 (legacy plaintext) messages pass through unchanged.
  /// • v2 (E2EE) messages are answered from the local PlaintextStore. We
  ///   only call into libsignal on a cache miss, then persist the result
  ///   so the next render is a pure SQLite hit.
  /// • If the envelope isn't addressed to this device (e.g. after reinstall
  ///   with a new device ID) or the ratchet can't decrypt, we check the
  ///   Firestore message vault — a per-user cross-install plaintext backup —
  ///   before returning null.
  // In-memory cache of decrypted payloads keyed by message id. Firestore
  // re-emits the entire message list on every read receipt / typing change,
  // so without this we'd hit SQLite N times per snapshot. Memory cost is
  // small — a Map<String, dynamic> per message — and it's wiped on signOut
  // along with the rest of the crypto state.
  // In-memory cache of decrypted payloads keyed by message id. Firestore
  // re-emits the entire message list on every read receipt / typing change,
  // so without this we'd hit SQLite N times per snapshot.
  //
  // LRU eviction: LinkedHashMap preserves insertion order, so when the cache
  // exceeds [_memoMaxSize] we drop the oldest entries (FIFO). On a heavy user
  // with 1000+ messages across chats this prevents unbounded memory growth
  // — each entry is a Map<String, dynamic> that can be several KB for media
  // messages.
  static const _memoMaxSize = 500;
  static final Map<String, Map<String, dynamic>> _payloadMemo = {};

  /// Adds an entry to [_payloadMemo] with automatic LRU eviction.
  /// When the cache exceeds [_memoMaxSize], the oldest 100 entries are
  /// removed (FIFO order via LinkedHashMap insertion ordering).
  static void _addToMemo(String key, Map<String, dynamic> value) {
    _payloadMemo[key] = value;
    if (_payloadMemo.length > _memoMaxSize) {
      final keysToRemove = _payloadMemo.keys.take(100).toList();
      for (final k in keysToRemove) {
        _payloadMemo.remove(k);
      }
    }
  }

  // Dedup set for decrypt-skip log messages. Without this, the same
  // message ID would log every time a Firestore emission re-triggers
  // decryptForRendering (typing, read receipts, etc.).
  static final Set<String> _loggedDecryptSkips = {};

  Future<MessageModel?> decryptForRendering(
      MessageModel msg, String selfUid) async {
    if (msg.schemaVersion < 2) return msg;

    // In-memory hot path — no awaits, synchronous return.
    final memo = _payloadMemo[msg.id];
    if (memo != null) return _applyPayload(msg, memo);

    final store = await PlaintextStore.instance();

    final cachedPayload = await store.get(msg.id);
    if (cachedPayload != null) {
      _addToMemo(msg.id, cachedPayload);
      return _applyPayload(msg, cachedPayload);
    }

    // Need to actually decrypt. Find an envelope addressed to this device.
    final envelopes = msg.envelopes;
    final deviceId = await _deviceIdentity.getDeviceId();

    // No envelope for this device — happens after reinstall (new device ID)
    // or if the sender's fan-out didn't include us. Fall back to the
    // Firestore message vault which was populated when we first decrypted
    // this message on a previous install.
    final env = (envelopes == null || envelopes.isEmpty || deviceId == null)
        ? null
        : envelopes['$selfUid:$deviceId'];

    if (env == null) {
      final vaultPayload = await _loadFromVault(selfUid, msg.id);
      if (vaultPayload != null) {
        _addToMemo(msg.id, vaultPayload);
        // Fire-and-forget: memo is the source of truth for rendering;
        // SQLite is only for crash/restart recovery.
        unawaited(store.save(msg.id, vaultPayload));
      }
      return vaultPayload != null ? _applyPayload(msg, vaultPayload) : null;
    }

    try {
      final pt = await SignalService.instance.decrypt(
        msg.senderId,
        msg.senderDeviceId ?? 1,
        EncryptedEnvelope.fromMap(env),
      );
      final payload = jsonDecode(utf8.decode(pt)) as Map<String, dynamic>;
      _addToMemo(msg.id, payload);
      
      final chatRoomId = getChatRoomId(msg.senderId, msg.receiverId);

      // Handle reaction processing E2EE client-side
      if (payload['type'] == 'reaction') {
        final targetId = payload['reactionTargetMessageId'] as String?;
        final emoji = payload['text'] as String?;
        if (targetId != null && emoji != null) {
          unawaited(store.addReaction(
            targetMessageId: targetId,
            chatRoomId: chatRoomId,
            userId: msg.senderId,
            emoji: emoji,
          ));
          // Earn points for the receiver of the reaction (the owner of target message)
          unawaited(() async {
            final list = await store.getMessagesByIds([targetId]);
            if (list.isNotEmpty && list.first.senderId == selfUid) {
              await GamificationService.instance.earnPoints(selfUid, 5);
            }
          }());
        }
      }

      // Fire-and-forget all persistence
      unawaited(Future.wait([
        store.save(msg.id, payload),
        if (payload['type'] != 'reaction')
          store.saveRoomPreview(
            chatRoomId: chatRoomId,
            messageId: msg.id,
            text: (payload['text'] as String?) ?? '',
          ),
      ]));
      unawaited(_saveToVault(selfUid, msg.id, payload));
      return _applyPayload(msg, payload);
    } catch (e) {
      final errStr = e.toString();
      // If the session is broken (missing, stale signed prekey after
      // reinstall, identity mismatch), drop it so the next PreKey message
      // from this peer can rebuild from scratch. This is invisible to the
      // user. InvalidKeyId covers the "No such signedprekeyrecord" error
      // that fires when the sender's cached keyBundle references a signed
      // prekey the receiver lost on reinstall.
      if (errStr.contains('NoSession') ||
          errStr.contains('No session') ||
          errStr.contains('InvalidMessage') ||
          errStr.contains('InvalidKeyId') ||
          errStr.contains('UntrustedIdentity')) {
        try {
          final addr = SignalProtocolAddress(msg.senderId, msg.senderDeviceId ?? 1);
          await SignalService.instance.stores.sessionStore.deleteSession(addr);
          if (errStr.contains('UntrustedIdentity')) {
            SignalService.instance.stores.identityStore.trustedKeys.remove(addr);
          }
          SignalService.instance.stores.markDirty();
        } catch (_) {}
      }
      // Libsignal couldn't decrypt — try the vault before giving up.
      final vaultPayload = await _loadFromVault(selfUid, msg.id);
      if (vaultPayload != null) {
        _addToMemo(msg.id, vaultPayload);
        unawaited(store.save(msg.id, vaultPayload));
        return _applyPayload(msg, vaultPayload);
      }
      // Cache the failure so we don't re-attempt on every Firestore
      // stream emission (typing indicator, read receipt, delivery status,
      // etc.). Without this, the same decrypt error fires and logs every
      // few seconds — visible as Crashlytics spam.
      final lockedPayload = <String, dynamic>{
        'text': _undecryptablePlaceholderText,
      };
      _addToMemo(msg.id, lockedPayload);
      // Log once per message to avoid flooding the console on every
      // Firestore re-emission (typing, read receipt, etc.).
      if (kDebugMode && _loggedDecryptSkips.add(msg.id)) {
        debugPrint('decrypt skipped for ${msg.id} (${e.runtimeType}): $e');
      }
      return _applyPayload(msg, lockedPayload);
    }
  }

  MessageModel _applyPayload(
      MessageModel msg, Map<String, dynamic> payload) {
    return msg.copyWith(
      text: (payload['text'] as String?) ?? '',
      mediaUrl: payload['mediaUrl'] as String?,
      audioDuration: payload['audioDuration'] as int?,
      reactionTargetMessageId: payload['reactionTargetMessageId'] as String?,
      statusReplyOwnerId: payload['statusReplyOwnerId'] as String?,
      statusReplyItemId: payload['statusReplyItemId'] as String?,
      statusReplyOwnerName: payload['statusReplyOwnerName'] as String?,
      statusReplyOwnerPhotoUrl:
          payload['statusReplyOwnerPhotoUrl'] as String?,
      statusReplyType: payload['statusReplyType'] as String?,
      statusReplyText: payload['statusReplyText'] as String?,
      statusReplyMediaUrl: payload['statusReplyMediaUrl'] as String?,
      statusReplyCaption: payload['statusReplyCaption'] as String?,
      statusReplyBackgroundColor:
          payload['statusReplyBackgroundColor'] as String?,
    );
  }

  // Generate a unique chat room ID from two user IDs
  String getChatRoomId(String userId1, String userId2) {
    // Sort IDs to ensure consistency regardless of who initiates the chat
    List<String> ids = [userId1, userId2];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Create or get existing chat room
  Future<ChatRoom> getOrCreateChatRoom(
      String currentUserId, String otherUserId) async {
    String chatRoomId = getChatRoomId(currentUserId, otherUserId);

    DocumentSnapshot doc =
        await _firestore.collection(_chatRoomsCollection).doc(chatRoomId).get();

    if (doc.exists) {
      return ChatRoom.fromFirestore(doc);
    }

    // Create new chat room with initial lastMessageTime so it shows in queries
    ChatRoom newChatRoom = ChatRoom(
      id: chatRoomId,
      participants: [currentUserId, otherUserId],
      lastMessageTime: DateTime.now(),
      unreadCount: {currentUserId: 0, otherUserId: 0},
    );

    await _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .set(newChatRoom.toMap());

    return newChatRoom;
  }

  // Send a message
  Future<MessageModel> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
    String? senderName,
    MessageType type = MessageType.text,
    String? mediaUrl,
    String? statusReplyOwnerId,
    String? statusReplyItemId,
    String? statusReplyOwnerName,
    String? statusReplyOwnerPhotoUrl,
    String? statusReplyType,
    String? statusReplyText,
    String? statusReplyMediaUrl,
    String? statusReplyCaption,
    String? statusReplyBackgroundColor,
    int? audioDuration,
    String? localFilePath,
    String? reactionTargetMessageId,
  }) async {
    String chatRoomId = getChatRoomId(senderId, receiverId);
    final chatRoomRef =
        _firestore.collection(_chatRoomsCollection).doc(chatRoomId);

    // Firestore generates the doc id synchronously client-side, so we have a
    // stable id to publish into the outbox before any async work begins.
    DocumentReference messageRef = chatRoomRef
        .collection(_messagesCollection)
        .doc();

    // ── Optimistic bubble: WhatsApp behaviour ───────────────────────────
    final optimistic = MessageModel(
      id: messageRef.id,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      type: type,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      mediaUrl: mediaUrl,
      audioDuration: audioDuration,
      statusReplyOwnerId: statusReplyOwnerId,
      statusReplyItemId: statusReplyItemId,
      statusReplyOwnerName: statusReplyOwnerName,
      statusReplyOwnerPhotoUrl: statusReplyOwnerPhotoUrl,
      statusReplyType: statusReplyType,
      statusReplyText: statusReplyText,
      statusReplyMediaUrl: statusReplyMediaUrl,
      statusReplyCaption: statusReplyCaption,
      statusReplyBackgroundColor: statusReplyBackgroundColor,
      localFilePath: localFilePath,
      reactionTargetMessageId: reactionTargetMessageId,
    );
    final ps = await PlaintextStore.instance();

    // If this is a reaction type message, do not save it as a new message bubble in outbox.
    // Instead, update the target message's reactions directly in local SQLite!
    if (type == MessageType.reaction && reactionTargetMessageId != null) {
      await ps.addReaction(
        targetMessageId: reactionTargetMessageId,
        chatRoomId: chatRoomId,
        userId: senderId,
        emoji: text,
      );
    } else {
      await ps.saveMessage(optimistic, chatRoomId);
    }

    try {
      return await _commitMessage(
        chatRoomId: chatRoomId,
        chatRoomRef: chatRoomRef,
        messageRef: messageRef,
        senderId: senderId,
        receiverId: receiverId,
        text: text,
        senderName: senderName,
        type: type,
        mediaUrl: mediaUrl,
        audioDuration: audioDuration,
        statusReplyOwnerId: statusReplyOwnerId,
        statusReplyItemId: statusReplyItemId,
        statusReplyOwnerName: statusReplyOwnerName,
        statusReplyOwnerPhotoUrl: statusReplyOwnerPhotoUrl,
        statusReplyType: statusReplyType,
        statusReplyText: statusReplyText,
        statusReplyMediaUrl: statusReplyMediaUrl,
        statusReplyCaption: statusReplyCaption,
        statusReplyBackgroundColor: statusReplyBackgroundColor,
        localFilePath: localFilePath,
        reactionTargetMessageId: reactionTargetMessageId,
      );
    } catch (e) {
      // Keep the bubble visible with a failed indicator so the user can
      // see what didn't go through.
      if (type != MessageType.reaction) {
        await ps.saveMessage(optimistic.copyWith(status: MessageStatus.failed), chatRoomId);
      }
      rethrow;
    }
  }

  Future<MessageModel> _commitMessage({
    required String chatRoomId,
    required DocumentReference chatRoomRef,
    required DocumentReference messageRef,
    required String senderId,
    required String receiverId,
    required String text,
    String? senderName,
    required MessageType type,
    String? mediaUrl,
    int? audioDuration,
    String? statusReplyOwnerId,
    String? statusReplyItemId,
    String? statusReplyOwnerName,
    String? statusReplyOwnerPhotoUrl,
    String? statusReplyType,
    String? statusReplyText,
    String? statusReplyMediaUrl,
    String? statusReplyCaption,
    String? statusReplyBackgroundColor,
    String? localFilePath,
    String? reactionTargetMessageId,
  }) async {
    final sw = Stopwatch()..start();
    // ── E2EE: build the inner plaintext payload, encrypt for every device
    //         of receiver + sender's other devices (multi-device fan-out).
    // Run device-id lookup, peer-bundle check, AND in-flight prewarm join
    // in PARALLEL. The awaitPrewarm is the critical coordination: if
    // prewarmSessions from initState is still running, we piggyback on it
    // instead of firing redundant Firestore queries. When no prewarm is
    // running, awaitPrewarm returns instantly (zero cost).
    final setupResults = await Future.wait<dynamic>([
      _deviceIdentity.getDeviceId(),
      _peerHasKeyBundle(receiverId),
      SignalService.instance.awaitPrewarm(receiverId),
    ]);
    final senderDeviceId = setupResults[0] as int?;
    final canEncrypt =
        senderDeviceId != null && (setupResults[1] as bool);
    if (kDebugMode) debugPrint('[SEND] setup: ${sw.elapsedMilliseconds}ms (canEncrypt=$canEncrypt)');

    Map<String, Map<String, dynamic>>? envelopes;
    String storedText = text;
    int schemaVersion = 1;

    if (canEncrypt) {
      // The payload that flows inside the Signal envelope. We can extend this
      // with media metadata, status reply blocks, etc. — nothing inside is
      // visible to the server.
      final payload = jsonEncode({
        'type': type.name,
        'text': text,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        if (audioDuration != null) 'audioDuration': audioDuration,
        if (reactionTargetMessageId != null) 'reactionTargetMessageId': reactionTargetMessageId,
        if (statusReplyOwnerId != null) ...{
          'statusReplyOwnerId': statusReplyOwnerId,
          'statusReplyItemId': statusReplyItemId,
          'statusReplyOwnerName': statusReplyOwnerName,
          'statusReplyOwnerPhotoUrl': statusReplyOwnerPhotoUrl,
          'statusReplyType': statusReplyType,
          'statusReplyText': statusReplyText,
          'statusReplyMediaUrl': statusReplyMediaUrl,
          'statusReplyCaption': statusReplyCaption,
          'statusReplyBackgroundColor': statusReplyBackgroundColor,
        },
      });

      try {
        final encs = await SignalService.instance.encryptForUser(
          senderUid: senderId,
          senderDeviceId: senderDeviceId,
          recipientUid: receiverId,
          plaintext: Uint8List.fromList(utf8.encode(payload)),
        );
        if (kDebugMode) debugPrint('[SEND] encrypt: ${sw.elapsedMilliseconds}ms');
        envelopes = encs.map((k, v) => MapEntry(k, v.toMap()));
        storedText = '';
        schemaVersion = 2;

        final outgoingPayload = <String, dynamic>{
          'text': text,
          'mediaUrl': mediaUrl,
          'audioDuration': audioDuration,
          if (reactionTargetMessageId != null) 'reactionTargetMessageId': reactionTargetMessageId,
          'statusReplyOwnerId': statusReplyOwnerId,
          'statusReplyItemId': statusReplyItemId,
          'statusReplyOwnerName': statusReplyOwnerName,
          'statusReplyOwnerPhotoUrl': statusReplyOwnerPhotoUrl,
          'statusReplyType': statusReplyType,
          'statusReplyText': statusReplyText,
          'statusReplyMediaUrl': statusReplyMediaUrl,
          'statusReplyCaption': statusReplyCaption,
          'statusReplyBackgroundColor': statusReplyBackgroundColor,
          if (localFilePath != null) 'localFilePath': localFilePath,
        };
        // Populate the in-memory memo SYNCHRONOUSLY so the stream's
        // snapshot for our own message never needs any async lookup.
        _addToMemo(messageRef.id, outgoingPayload);

        // Fire SQLite persistence in the background — the in-memory memo
        // is already set, so rendering is instant. SQLite is only needed
        // for crash recovery / cold restart.
        final ps = await PlaintextStore.instance();
        unawaited(Future.wait([
          if (type != MessageType.reaction)
            ps.saveRoomPreview(
              chatRoomId: chatRoomId,
              messageId: messageRef.id,
              text: statusReplyOwnerId != null
                  ? 'Replied to status: $text'
                  : text,
            ),
          ps.save(messageRef.id, outgoingPayload),
        ]));
        // Mirror to the cross-install vault so the sender's history
        // survives a reinstall (new device ID loses the Firestore envelope
        // but can recover from the vault).
        unawaited(_saveToVault(senderId, messageRef.id, outgoingPayload));
      } catch (e) {
        if (kDebugMode) debugPrint('E2EE encrypt failed, falling back to plaintext: $e');
      }
    }

    MessageModel message = MessageModel(
      id: messageRef.id,
      senderId: senderId,
      receiverId: receiverId,
      text: storedText,
      type: type,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      mediaUrl: schemaVersion == 2 ? null : mediaUrl,
      statusReplyOwnerId: schemaVersion == 2 ? null : statusReplyOwnerId,
      statusReplyItemId: schemaVersion == 2 ? null : statusReplyItemId,
      statusReplyOwnerName: schemaVersion == 2 ? null : statusReplyOwnerName,
      statusReplyOwnerPhotoUrl:
          schemaVersion == 2 ? null : statusReplyOwnerPhotoUrl,
      statusReplyType: schemaVersion == 2 ? null : statusReplyType,
      statusReplyText: schemaVersion == 2 ? null : statusReplyText,
      statusReplyMediaUrl: schemaVersion == 2 ? null : statusReplyMediaUrl,
      statusReplyCaption: schemaVersion == 2 ? null : statusReplyCaption,
      statusReplyBackgroundColor:
          schemaVersion == 2 ? null : statusReplyBackgroundColor,
      audioDuration: schemaVersion == 2 ? null : audioDuration,
      schemaVersion: schemaVersion,
      senderDeviceId: senderDeviceId,
      envelopes: envelopes,
      localFilePath: localFilePath,
      reactionTargetMessageId: reactionTargetMessageId,
    );
    final lastMessagePreview = schemaVersion == 2
        ? _encryptedPreviewPlaceholder
        : (statusReplyOwnerId != null ? 'Replied to status: $text' : text);

    // Use batch write for consistency
    WriteBatch batch = _firestore.batch();

    // Add message
    batch.set(messageRef, message.toMap());

    // Update chat room details (only update preview fields if NOT a reaction)
    final roomUpdates = <String, dynamic>{
      'id': chatRoomId,
      'participants': [senderId, receiverId]..sort(),
    };

    if (type != MessageType.reaction) {
      roomUpdates['lastMessage'] = lastMessagePreview;
      roomUpdates['lastMessageTime'] = Timestamp.fromDate(message.timestamp);
      roomUpdates['lastMessageSenderId'] = senderId;
      roomUpdates['lastMessageStatus'] = MessageStatus.sent.name;
      roomUpdates['unreadCount.$senderId'] = FieldValue.increment(0);
      roomUpdates['unreadCount.$receiverId'] = FieldValue.increment(1);
    }

    // ── Mutual streak logic (Snapchat-style, calendar-day based) ───────
    // Both participants must send at least one message within the SAME
    // local calendar day for it to count as a mutual day.  When the
    // second person replies (completing the pair), we compare today's
    // date with the last mutual date:
    //   • same day    → no change (already counted today)
    //   • yesterday   → streak increments
    //   • 2+ days ago → streak broken (saved for restore)
    //   • first time  → streak starts at 1
    // Uses local time (DateTime.now()) — same as Snapchat.
    try {
      final chatRoomSnap = await chatRoomRef.get();
      int currentStreak = 0;
      DateTime? lastInteraction;
      Map<String, DateTime> lastSentAt = {};
      int previousStreakCount = 0;
      DateTime? streakBrokenAt;

      if (chatRoomSnap.exists) {
        final data = chatRoomSnap.data() as Map<String, dynamic>;
        currentStreak = data['streakCount'] as int? ?? 0;
        final timestamp = data['lastInteractionDate'] as Timestamp?;
        lastInteraction = timestamp?.toDate().toLocal();
        previousStreakCount = data['previousStreakCount'] as int? ?? 0;
        final brokenTs = data['streakBrokenAt'] as Timestamp?;
        streakBrokenAt = brokenTs?.toDate().toLocal();

        final rawSent = data['lastSentAt'] as Map<String, dynamic>? ?? {};
        rawSent.forEach((key, value) {
          if (value is Timestamp) lastSentAt[key] = value.toDate().toLocal();
        });
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      debugPrint('[STREAK] senderId=$senderId receiverId=$receiverId');
      debugPrint('[STREAK] currentStreak=$currentStreak lastInteraction=$lastInteraction');
      debugPrint('[STREAK] lastSentAt=$lastSentAt');

      // Clean up expired restore windows (>24h after break)
      if (streakBrokenAt != null && now.difference(streakBrokenAt).inHours > 24) {
        previousStreakCount = 0;
        streakBrokenAt = null;
        roomUpdates['previousStreakCount'] = 0;
        roomUpdates['streakBrokenAt'] = null;
      }

      // Record this sender's last-send time (in-memory for the logic below)
      lastSentAt[senderId] = now;
      // NOTE: We intentionally do NOT write lastSentAt via roomUpdates here.
      // set(merge:true) treats dot-notation keys like 'lastSentAt.$uid' as
      // literal top-level field names, not nested paths — so the nested
      // lastSentAt map never gets populated.  Instead, we use update()
      // after the batch commit (see below), which reliably supports
      // dot-notation for nested fields.

      // Determine the other participant
      final otherUserId = senderId == receiverId
          ? senderId
          : receiverId;
      final otherLastSent = lastSentAt[otherUserId];

      int newStreak = currentStreak;

      // Check if BOTH participants have sent at least one message TODAY
      // Use .toLocal() explicitly to ensure timezone-consistent comparison.
      final otherLocal = otherLastSent?.toLocal();
      final otherSentToday = otherLocal != null &&
          otherLocal.year == today.year &&
          otherLocal.month == today.month &&
          otherLocal.day == today.day;

      debugPrint('[STREAK] otherUserId=$otherUserId otherLastSent=$otherLastSent otherLocal=$otherLocal otherSentToday=$otherSentToday today=$today');

      // Only evaluate streak when today becomes a mutual day
      if (otherSentToday) {
        if (lastInteraction == null) {
          // First-ever mutual day — start the streak
          newStreak = 1;
          roomUpdates['lastInteractionDate'] = Timestamp.fromDate(now);
          debugPrint('[STREAK] First mutual day → streak=1');
        } else {
          // Compare the last mutual date with today (calendar-day diff)
          final lastMutualDay = DateTime(
            lastInteraction.year,
            lastInteraction.month,
            lastInteraction.day,
          );
          final daysDiff = today.difference(lastMutualDay).inDays;

          debugPrint('[STREAK] lastMutualDay=$lastMutualDay daysDiff=$daysDiff');

          if (daysDiff == 0) {
            // Same day — streak count stays the same, but refresh the
            // interaction timestamp so the streak badge timer resets.
            // Without this, stale timestamps from the old logic keep
            // the badge stuck in at-risk/critical state.
            roomUpdates['lastInteractionDate'] = Timestamp.fromDate(now);
            debugPrint('[STREAK] Same day → refreshing lastInteractionDate, streak=$newStreak');
          } else if (daysDiff == 1) {
            // Yesterday → streak increments!
            newStreak = currentStreak + 1;
            roomUpdates['lastInteractionDate'] = Timestamp.fromDate(now);
            debugPrint('[STREAK] Yesterday → streak incremented to $newStreak');
          } else {
            // 2+ days gap → streak broken
            if (currentStreak > 0) {
              previousStreakCount = currentStreak;
              streakBrokenAt = now;
              roomUpdates['previousStreakCount'] = currentStreak;
              roomUpdates['streakBrokenAt'] = Timestamp.fromDate(now);
            }
            newStreak = 1; // Fresh mutual day starts a new streak
            roomUpdates['lastInteractionDate'] = Timestamp.fromDate(now);
            debugPrint('[STREAK] Gap of $daysDiff days → streak broken, restart at 1');
          }
        }
      } else {
        // Only one person sent today. Still refresh lastInteractionDate
        // if it's stale (>20h old) to prevent the badge timer from being
        // stuck in at-risk/critical state when the user is actively messaging.
        if (lastInteraction != null) {
          final hoursSinceInteraction = now.difference(lastInteraction).inHours;
          if (hoursSinceInteraction >= 20) {
            roomUpdates['lastInteractionDate'] = Timestamp.fromDate(now);
            debugPrint('[STREAK] Not mutual yet, but refreshing stale lastInteractionDate (${hoursSinceInteraction}h old)');
          }
        }
        debugPrint('[STREAK] Waiting for other user to send today — no streak change');
      }

      roomUpdates['streakCount'] = newStreak;

      // Fire streak milestone rewards in the background
      if (newStreak > currentStreak && (newStreak == 7 || newStreak == 30 || newStreak == 100)) {
        unawaited(GamificationService.instance.handleStreakMilestone(senderId, newStreak));
      }
    } catch (e, st) {
      debugPrint('[STREAK] Error computing streak: $e\n$st');
    }

    batch.set(
      chatRoomRef,
      roomUpdates,
      SetOptions(merge: true),
    );

    if (kDebugMode) debugPrint('[SEND] pre-commit: ${sw.elapsedMilliseconds}ms');
    await batch.commit();
    if (kDebugMode) debugPrint('[SEND] committed: ${sw.elapsedMilliseconds}ms — ${message.id}');

    // Write lastSentAt using update(), which reliably interprets dot-notation
    // as nested field paths (e.g. 'lastSentAt.uid' → lastSentAt/{uid}).
    // This MUST happen after batch.commit() so the document already exists.
    unawaited(chatRoomRef.update({
      'lastSentAt.$senderId': Timestamp.fromDate(DateTime.now()),
    }).catchError((e) {
      debugPrint('[STREAK] Failed to update lastSentAt: $e');
    }));

    // Award points, progress challenges, and unlock badges in a single
    // Firestore transaction — avoids the race condition where multiple
    // sequential transactions on the same user doc cause stale reads.
    unawaited(() async {
      try {
        await GamificationService.instance.handleMessageSent(
          userId: senderId,
          messageType: type.name, // 'text', 'audio', 'image', 'video', 'reaction'
        );
      } catch (e) {
        debugPrint('Error awarding gamification on commit: $e');
      }
    }());

    // Fire-and-forget the FCM push.
    unawaited(() async {
      try {
        // Skip notification for reaction message types
        if (type == MessageType.reaction) return;

        final displayName = senderName ?? 'Someone';
        final previewText = schemaVersion == 2 ? 'New message' : text;
        await _fcmService.sendMessageNotification(
          receiverId: receiverId,
          senderId: senderId,
          senderName: displayName,
          message: previewText,
          chatRoomId: chatRoomId,
        );
      } catch (e) {
        if (kDebugMode) debugPrint('Error sending message notification: $e');
      }
    }());

    return message;
  }

  // Get messages stream for a chat room.
  // Respects the per-user `clearedAt` timestamp written by "Clear all chats"
  // so only messages AFTER the clear time are shown to this user.
  //
  // Implementation note: the messages-subcollection subscription is started
  // ONCE and kept alive for the lifetime of the returned stream. The
  // chatRoom doc subscription (only used to track `clearedAt`) runs in
  // parallel — it can fire dozens of times per minute (typing indicators,
  // lastMessage updates, read-receipt status writes, etc.), but we keep
  // the messages stream untouched across those changes. Previously this
  // used `asyncExpand`, which tore down and rebuilt the entire messages
  // subscription on every chatRoom doc tick — that re-decryption pass was
  // the source of the visible "Today combines with previous list" reflow
  // the user reported after the outbox was introduced (sending a message
  // updates chatRoom.lastMessage as part of the same batch, which fired
  // the asyncExpand teardown right after the optimistic bubble appeared).
  Stream<List<MessageModel>> getMessages(
      String currentUserId, String otherUserId) {
    final chatRoomId = getChatRoomId(currentUserId, otherUserId);
    final controller = StreamController<List<MessageModel>>();
    
    StreamSubscription<List<MessageModel>>? dbSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? chatRoomSub;
    
    DateTime? clearedAt;
    List<MessageModel> latestMessages = const [];

    void emit() {
      if (controller.isClosed) return;
      if (clearedAt == null) {
        controller.add(latestMessages);
      } else {
        final filtered = latestMessages
            .where((m) => m.timestamp.isAfter(clearedAt!))
            .toList();
        controller.add(filtered);
      }
    }

    controller.onListen = () async {
      try {
        final ps = await PlaintextStore.instance();
        dbSub = ps.watchMessages(chatRoomId).listen(
          (data) {
            latestMessages = data;
            emit();
          },
          onError: (e, st) {
            if (!controller.isClosed) controller.addError(e, st);
          },
        );

        // Listen to chatRoom document to track clearedAt (cleared chats)
        chatRoomSub = _firestore
            .collection(_chatRoomsCollection)
            .doc(chatRoomId)
            .snapshots()
            .listen((snap) {
          DateTime? newClearedAt;
          if (snap.exists) {
            final data = snap.data();
            final clearedAtMap = data?['clearedAt'] as Map<String, dynamic>?;
            final ts = clearedAtMap?[currentUserId];
            if (ts is Timestamp) newClearedAt = ts.toDate();
          }
          if (newClearedAt != clearedAt) {
            clearedAt = newClearedAt;
            emit();
          }
        });
      } catch (e, st) {
        if (!controller.isClosed) {
          controller.addError(e, st);
          controller.close();
        }
      }
    };

    controller.onCancel = () async {
      await dbSub?.cancel();
      await chatRoomSub?.cancel();
    };

    return controller.stream;
  }


  // Get paginated messages (for loading older messages)
  Future<List<MessageModel>> getMessagesPaginated({
    required String currentUserId,
    required String otherUserId,
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    String chatRoomId = getChatRoomId(currentUserId, otherUserId);

    Query query = _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    QuerySnapshot snapshot = await query.get();

    final raw = snapshot.docs
        .map((doc) => MessageModel.fromFirestore(doc))
        .toList()
        .reversed
        .toList();
    final resolved = await Future.wait(
      raw.map((m) async {
        final r = await decryptForRendering(m, currentUserId);
        return r ?? _lockedPlaceholder(m);
      }),
    );
    return resolved;
  }

  /// Fetches older messages from Firestore, decrypts them, and batch-saves them to SQLite.
  /// Returns the number of new older messages fetched.
  Future<int> fetchOlderMessages({
    required String chatRoomId,
    required DateTime beforeTimestamp,
    required String currentUserId,
    int limit = 50,
  }) async {
    final snap = await _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .where('timestamp', isLessThan: Timestamp.fromDate(beforeTimestamp))
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    if (snap.docs.isEmpty) return 0;

    final store = await PlaintextStore.instance();
    final toSave = <MessageModel>[];

    for (final doc in snap.docs) {
      final msg = MessageModel.fromFirestore(doc);
      final decrypted = await decryptForRendering(msg, currentUserId);
      toSave.add(decrypted ?? _lockedPlaceholder(msg));
    }

    if (toSave.isNotEmpty) {
      await store.saveMessagesBatch(toSave, chatRoomId);
    }

    return snap.docs.length;
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(
      String currentUserId, String otherUserId) async {
    String chatRoomId = getChatRoomId(currentUserId, otherUserId);

    // Get unread messages sent by the other user
    QuerySnapshot unreadMessages = await _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', whereIn: ['sent', 'delivered']).get();

    if (unreadMessages.docs.isEmpty) return;

    WriteBatch batch = _firestore.batch();

    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'status': 'read'});
    }

    // Reset unread count. Only update lastMessageStatus if the last message
    // was sent by the OTHER user — otherwise we'd incorrectly show blue ticks
    // on our own outgoing message.
    final chatRoomDoc =
        await _firestore.collection(_chatRoomsCollection).doc(chatRoomId).get();
    final chatData = chatRoomDoc.data();
    final updateMap = <String, dynamic>{'unreadCount.$currentUserId': 0};
    if (chatData != null &&
        chatData['lastMessageSenderId'] != currentUserId) {
      updateMap['lastMessageStatus'] = MessageStatus.read.name;
    }
    batch.update(
      _firestore.collection(_chatRoomsCollection).doc(chatRoomId),
      updateMap,
    );

    await batch.commit();
    print('Marked ${unreadMessages.docs.length} messages as read');
  }

  // Mark messages as delivered when receiver opens chat or receives them
  Future<void> markMessagesAsDelivered(
      String currentUserId, String otherUserId) async {
    String chatRoomId = getChatRoomId(currentUserId, otherUserId);

    // Get sent messages (not yet delivered) sent by the other user
    QuerySnapshot sentMessages = await _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'sent')
        .get();

    if (sentMessages.docs.isEmpty) return;

    WriteBatch batch = _firestore.batch();

    for (var doc in sentMessages.docs) {
      batch.update(doc.reference, {'status': 'delivered'});
    }

    // Update lastMessageStatus on chatRoom
    batch.update(
      _firestore.collection(_chatRoomsCollection).doc(chatRoomId),
      {'lastMessageStatus': MessageStatus.delivered.name},
    );

    await batch.commit();
    print('Marked ${sentMessages.docs.length} messages as delivered');
  }

  // Mark ALL messages as delivered across ALL chats when app opens.
  // Uses a collectionGroup query (one round-trip) instead of the previous
  // N+1 pattern (one read per chat room) to avoid hammering Firestore on
  // every app resume.
  //
  // Requires a composite collection-group index on the `messages` group:
  //   receiverId ASC, status ASC
  // Add to firestore.indexes.json if Firestore reports a missing index.
  Future<void> markAllMessagesAsDeliveredOnAppOpen(String currentUserId) async {
    try {
      final sentSnap = await _firestore
          .collectionGroup(_messagesCollection)
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'sent')
          .get();

      if (sentSnap.docs.isEmpty) return;

      // Group docs by chatRoomId so we can update lastMessageStatus per room.
      final byRoom = <String,
          List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
      for (final doc in sentSnap.docs) {
        final chatRoomId = doc.reference.parent.parent?.id;
        if (chatRoomId == null) continue;
        byRoom.putIfAbsent(chatRoomId, () => []).add(doc);
      }

      // Commit in chunks ≤ 490 ops (Firestore hard limit is 500 per batch).
      const maxOps = 490;
      var batch = _firestore.batch();
      var opCount = 0;

      Future<void> maybeFlush() async {
        if (opCount >= maxOps) {
          await batch.commit();
          batch = _firestore.batch();
          opCount = 0;
        }
      }

      for (final entry in byRoom.entries) {
        for (final doc in entry.value) {
          batch.update(doc.reference, {'status': 'delivered'});
          opCount++;
          await maybeFlush();
        }
        batch.update(
          _firestore.collection(_chatRoomsCollection).doc(entry.key),
          {'lastMessageStatus': MessageStatus.delivered.name},
        );
        opCount++;
        await maybeFlush();
      }

      if (opCount > 0) await batch.commit();

      final total = sentSnap.docs.length;
      if (total > 0) print('Marked $total messages as delivered on app open');
    } catch (e) {
      print('Error marking messages as delivered on app open: $e');
    }
  }

  // Get chat rooms for a user.
  // Hides chats the user has cleared (via "Clear all chats") unless a new
  // message arrived after the clear timestamp — in that case the chat
  // reappears automatically (WhatsApp behaviour).
  Stream<List<ChatRoom>> getChatRooms(String userId) {
    // Manual controller so the chat list can be re-emitted on
    // vault-ready ticks as well as on every Firestore snapshot. Without
    // this, post-reinstall the home screen would stay on "🔒 Encrypted
    // message" / "🔒 can't decrypt" placeholders until some unrelated
    // chatRoom change happened to retrigger the asyncMap.
    final controller = StreamController<List<ChatRoom>>();
    QuerySnapshot<Map<String, dynamic>>? latestSnap;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? roomsSub;
    StreamSubscription<void>? vaultReadySub;

    Future<List<ChatRoom>> process(
        QuerySnapshot<Map<String, dynamic>> snapshot) async {
      final ps = await PlaintextStore.instance();
      final previews = await ps.getAllRoomPreviewsWithMeta();

      // Build the room list with cached previews applied, and collect
      // rooms whose cached preview is missing or stale.
      final chatRooms = <ChatRoom>[];
      final needsPreview = <int>[]; // indexes into chatRooms

      for (final doc in snapshot.docs) {
        final data = doc.data();
        var chatRoom = ChatRoom.fromMap(data, doc.id);

        final clearedAtMap = data['clearedAt'] as Map<String, dynamic>?;
        if (clearedAtMap != null && clearedAtMap[userId] != null) {
          final clearedAt = (clearedAtMap[userId] as Timestamp).toDate();
          if (chatRoom.lastMessageTime == null ||
              !chatRoom.lastMessageTime!.isAfter(clearedAt)) {
            continue;
          }
        }

        final localPreview = previews[chatRoom.id];
        final roomMs =
            chatRoom.lastMessageTime?.millisecondsSinceEpoch ?? 0;
        final isFresh = localPreview != null &&
            localPreview.updatedAt + 1000 >= roomMs;

        if (isFresh) {
          chatRoom = ChatRoom(
            id: chatRoom.id,
            participants: chatRoom.participants,
            lastMessage: localPreview.text,
            lastMessageTime: chatRoom.lastMessageTime,
            lastMessageSenderId: chatRoom.lastMessageSenderId,
            lastMessageStatus: chatRoom.lastMessageStatus,
            unreadCount: chatRoom.unreadCount,
            streakCount: chatRoom.streakCount,
            lastInteractionDate: chatRoom.lastInteractionDate,
            lastSentAt: chatRoom.lastSentAt,
            previousStreakCount: chatRoom.previousStreakCount,
            streakBrokenAt: chatRoom.streakBrokenAt,
          );
        } else if (chatRoom.lastMessage == _encryptedPreviewPlaceholder ||
            localPreview != null) {
          needsPreview.add(chatRooms.length);
        }

        chatRooms.add(chatRoom);
      }

      // Decrypt stale previews with frame yields between batches.
      // Batch size is high (20) so most users see a single batch — identical
      // to the original parallel behavior. The frame yield only fires for
      // exceptional cases (20+ stale rooms after reinstall), where it
      // prevents the main-thread buildup that triggers ANR.
      if (needsPreview.isNotEmpty) {
        const batchSize = 20;
        for (int start = 0; start < needsPreview.length; start += batchSize) {
          final end = (start + batchSize).clamp(0, needsPreview.length);
          final batch = needsPreview.sublist(start, end);
          await Future.wait(batch.map((i) async {
            final room = chatRooms[i];
            try {
              final latest = await _firestore
                  .collection(_chatRoomsCollection)
                  .doc(room.id)
                  .collection(_messagesCollection)
                  .orderBy('timestamp', descending: true)
                  .limit(1)
                  .get();
              if (latest.docs.isEmpty) return;
              final msg = MessageModel.fromFirestore(latest.docs.first);
              final decrypted = await decryptForRendering(msg, userId);
              final text = decrypted == null
                  ? _undecryptablePlaceholderText
                  : (decrypted.text.isNotEmpty
                      ? decrypted.text
                      : (decrypted.mediaUrl != null ? 'Media' : ''));
              if (text.isEmpty) return;
              await ps.saveRoomPreview(
                chatRoomId: room.id,
                messageId: msg.id,
                text: text,
              );
              chatRooms[i] = ChatRoom(
                id: room.id,
                participants: room.participants,
                lastMessage: text,
                lastMessageTime: room.lastMessageTime,
                lastMessageSenderId: room.lastMessageSenderId,
                lastMessageStatus: room.lastMessageStatus,
                unreadCount: room.unreadCount,
                streakCount: room.streakCount,
                lastInteractionDate: room.lastInteractionDate,
                lastSentAt: room.lastSentAt,
                previousStreakCount: room.previousStreakCount,
                streakBrokenAt: room.streakBrokenAt,
              );
            } catch (_) {}
          }));
          if (start + batchSize < needsPreview.length) {
            await Future.delayed(Duration.zero);
          }
        }
      }

      // Sort locally to handle null lastMessageTime
      chatRooms.sort((a, b) {
        if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });

      return chatRooms;
    }

    Future<void> emitFromCachedSnap() async {
      final snap = latestSnap;
      if (snap == null) return;
      try {
        final rooms = await process(snap);
        if (!controller.isClosed) controller.add(rooms);
      } catch (e, st) {
        if (!controller.isClosed) controller.addError(e, st);
      }
    }

    controller.onListen = () {
      roomsSub = _firestore
          .collection(_chatRoomsCollection)
          .where('participants', arrayContains: userId)
          .snapshots()
          .listen((snap) {
        latestSnap = snap;
        // ignore: discarded_futures
        emitFromCachedSnap();
      }, onError: (e, st) {
        if (!controller.isClosed) controller.addError(e, st);
      });

      // Re-emit on vault-ready ticks so post-reinstall placeholders get
      // replaced with real previews the moment the user enters their PIN
      // — no need to wait for an unrelated chatRoom mutation.
      vaultReadySub = _vaultReadyNotifier.stream.listen((_) {
        // ignore: discarded_futures
        emitFromCachedSnap();
      });
    };
    controller.onCancel = () async {
      await roomsSub?.cancel();
      await vaultReadySub?.cancel();
    };
    return controller.stream;
  }

  // Delete a message
  Future<void> deleteMessage({
    required String currentUserId,
    required String otherUserId,
    required String messageId,
  }) async {
    String chatRoomId = getChatRoomId(currentUserId, otherUserId);

    await _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .doc(messageId)
        .delete();

    print('Message deleted: $messageId');
  }

  // Get unread message count for a user across all chats
  Stream<int> getTotalUnreadCount(String userId) {
    return _firestore
        .collection(_chatRoomsCollection)
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data();
        Map<String, dynamic> unreadCount =
            Map<String, dynamic>.from(data['unreadCount'] ?? {});
        total += (unreadCount[userId] as int?) ?? 0;
      }
      return total;
    });
  }

  // Check if chat room exists
  Future<bool> chatRoomExists(String currentUserId, String otherUserId) async {
    String chatRoomId = getChatRoomId(currentUserId, otherUserId);
    DocumentSnapshot doc =
        await _firestore.collection(_chatRoomsCollection).doc(chatRoomId).get();
    return doc.exists;
  }

  // ─── Typing Indicator ───────────────────────────────────────────────

  /// Set typing status for a user in a chat room.
  /// Writes the current server timestamp when typing, or removes the entry
  /// when the user stops typing.
  Future<void> setTypingStatus({
    required String currentUserId,
    required String otherUserId,
    required bool isTyping,
  }) async {
    String chatRoomId = getChatRoomId(currentUserId, otherUserId);

    await _firestore.collection(_chatRoomsCollection).doc(chatRoomId).set(
      {
        'typing': {
          currentUserId: isTyping ? FieldValue.serverTimestamp() : null,
        },
      },
      SetOptions(merge: true),
    );
  }

  /// Returns a real-time stream that emits `true` when the other user is
  /// currently typing (i.e. their typing timestamp is less than 5 seconds old).
  Stream<bool> getTypingStatus({
    required String currentUserId,
    required String otherUserId,
  }) {
    String chatRoomId = getChatRoomId(currentUserId, otherUserId);

    return _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return false;

      final data = snapshot.data();
      if (data == null) return false;

      final typing = data['typing'] as Map<String, dynamic>?;
      if (typing == null) return false;

      final otherTypingTimestamp = typing[otherUserId];
      if (otherTypingTimestamp == null) return false;

      if (otherTypingTimestamp is Timestamp) {
        final diff =
            DateTime.now().difference(otherTypingTimestamp.toDate()).inSeconds;
        return diff < 5;
      }

      return false;
    });
  }

  /// Downloads a media file from [message.mediaUrl] and stores it locally.
  /// Returns the local file path if successful, or null otherwise.
  Future<String?> downloadAndCacheMedia(MessageModel message) async {
    final urlStr = message.mediaUrl;
    if (urlStr == null || urlStr.isEmpty) return null;

    try {
      final dbDir = (await getApplicationSupportDirectory()).path;
      final cacheDir = Directory(p.join(dbDir, 'gsg_chat_media'));
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      // Determine the extension (simple check)
      String extension = 'bin';
      if (message.type == MessageType.image) {
        extension = 'jpg';
      } else if (message.type == MessageType.audio) {
        extension = 'm4a';
      } else if (message.type == MessageType.video) {
        extension = 'mp4';
      } else {
        // Fallback: parse from URL path if possible
        try {
          final uri = Uri.parse(urlStr);
          final pathSegments = uri.pathSegments;
          if (pathSegments.isNotEmpty) {
            final fileName = pathSegments.last;
            final dotIdx = fileName.lastIndexOf('.');
            if (dotIdx != -1) {
              extension = fileName.substring(dotIdx + 1);
            }
          }
        } catch (_) {}
      }

      final localPath = p.join(cacheDir.path, '${message.id}.$extension');
      final localFile = File(localPath);

      if (await localFile.exists()) {
        return localPath;
      }

      // Fetch from network
      final response = await http.get(Uri.parse(urlStr));
      if (response.statusCode == 200) {
        await localFile.writeAsBytes(response.bodyBytes);
        return localPath;
      } else {
        if (kDebugMode) debugPrint('[ChatService] Failed to download media: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ChatService] Error downloading media: $e');
      return null;
    }
  }
}

