import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/services/crypto/device_identity_service.dart';
import 'package:video_chat_app/services/crypto/plaintext_store.dart';
import 'package:video_chat_app/services/crypto/signal_service.dart';
import 'package:video_chat_app/services/crypto/vault_cipher.dart';
import 'package:video_chat_app/services/fcm_service.dart';
import 'package:video_chat_app/services/performance_service.dart';

class ChatService {
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
      '🔒 This message can\'t be decrypted on this device. Ask sender to resend.';

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
  //
  // Static because ChatService is constructed per-screen but the outbox
  // must outlive any single screen — a send from the chat list preview
  // bar (hypothetical) should appear instantly when the user opens the
  // chat screen a moment later. Keyed by chatRoomId.
  static final Map<String, List<MessageModel>> _outbox = {};

  // Broadcasts whenever _outbox changes so the merged stream in
  // getMessages can re-emit. We use a void signal rather than passing the
  // full outbox map to avoid forcing a copy on every notification — every
  // listener reads _outbox directly during the merge step.
  static final StreamController<void> _outboxNotifier =
      StreamController<void>.broadcast();

  static void _addToOutbox(String chatRoomId, MessageModel message) {
    final list = _outbox.putIfAbsent(chatRoomId, () => <MessageModel>[]);
    list.add(message);
    _outboxNotifier.add(null);
  }

  static void _updateOutbox(
      String chatRoomId, String messageId, MessageModel Function(MessageModel) update) {
    final list = _outbox[chatRoomId];
    if (list == null) return;
    final idx = list.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    list[idx] = update(list[idx]);
    _outboxNotifier.add(null);
  }


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
    return _fetchPeerBundle(peerUid);
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
  static final Map<String, Map<String, dynamic>> _payloadMemo = {};

  Future<MessageModel?> decryptForRendering(
      MessageModel msg, String selfUid) async {
    if (msg.schemaVersion < 2) return msg;

    // In-memory hot path — no awaits, synchronous return.
    final memo = _payloadMemo[msg.id];
    if (memo != null) return _applyPayload(msg, memo);

    final store = await PlaintextStore.instance();

    final cachedPayload = await store.get(msg.id);
    if (cachedPayload != null) {
      _payloadMemo[msg.id] = cachedPayload;
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
        _payloadMemo[msg.id] = vaultPayload;
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
      _payloadMemo[msg.id] = payload;
      // Fire-and-forget all persistence — the in-memory memo is already
      // set so rendering is instant. SQLite and vault writes are only for
      // crash recovery and cross-install history. Previously these two
      // sequential awaits (save + saveRoomPreview) added 50-200ms to the
      // render path for EVERY received message.
      final chatRoomId = getChatRoomId(msg.senderId, msg.receiverId);
      unawaited(Future.wait([
        store.save(msg.id, payload),
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
      // If the session is missing, drop it so the next PreKey message from
      // this peer can rebuild from scratch. This is invisible to the user.
      if (errStr.contains('NoSession') ||
          errStr.contains('No session') ||
          errStr.contains('InvalidMessage')) {
        try {
          await SignalService.instance.stores.sessionStore.deleteSession(
            SignalProtocolAddress(msg.senderId, msg.senderDeviceId ?? 1),
          );
          SignalService.instance.stores.markDirty();
        } catch (_) {}
      }
      // Libsignal couldn't decrypt — try the vault before giving up.
      final vaultPayload = await _loadFromVault(selfUid, msg.id);
      if (vaultPayload != null) {
        _payloadMemo[msg.id] = vaultPayload;
        unawaited(store.save(msg.id, vaultPayload));
        return _applyPayload(msg, vaultPayload);
      }
      // ignore: avoid_print
      print('decrypt skipped for ${msg.id} (${e.runtimeType}): $e');
      return null;
    }
  }

  MessageModel _applyPayload(
      MessageModel msg, Map<String, dynamic> payload) {
    return msg.copyWith(
      text: (payload['text'] as String?) ?? '',
      mediaUrl: payload['mediaUrl'] as String?,
      audioDuration: payload['audioDuration'] as int?,
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
    // Drop a `status: sending` MessageModel into the outbox immediately so
    // the chat stream emits it in the same frame as the tap. Once the
    // Firestore commit lands, the canonical message arrives via the
    // snapshot stream and we remove the outbox entry. On failure we flip
    // it to status=failed so the bubble stays on screen with an error
    // indicator the user can retry from.
    // WhatsApp-parity perceived speed: show the single tick (sent) in the
    // same frame as the tap. Firestore's offline persistence queues the
    // batch commit locally and rarely fails when online, so the lie is
    // tiny and self-correcting — on failure we flip to `failed` in the
    // catch below, same as before.
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
    );
    _addToOutbox(chatRoomId, optimistic);

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
      );
    } catch (e) {
      // Keep the bubble visible with a failed indicator so the user can
      // see what didn't go through and (in a future revision) tap to
      // retry. The bubble is removed only on a successful commit, when
      // Firestore re-delivers the canonical message.
      _updateOutbox(chatRoomId, messageRef.id,
          (m) => m.copyWith(status: MessageStatus.failed));
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
  }) async {
    final sw = Stopwatch()..start();
    // ── E2EE: build the inner plaintext payload, encrypt for every device
    //         of receiver + sender's other devices (multi-device fan-out).
    final senderDeviceId = await _deviceIdentity.getDeviceId();
    final canEncrypt =
        senderDeviceId != null && await _peerHasKeyBundle(receiverId);
    print('[SEND] setup: ${sw.elapsedMilliseconds}ms (canEncrypt=$canEncrypt)');

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
        print('[SEND] encrypt: ${sw.elapsedMilliseconds}ms');
        envelopes = encs.map((k, v) => MapEntry(k, v.toMap()));
        storedText = '';
        schemaVersion = 2;

        final outgoingPayload = <String, dynamic>{
          'text': text,
          'mediaUrl': mediaUrl,
          'audioDuration': audioDuration,
          'statusReplyOwnerId': statusReplyOwnerId,
          'statusReplyItemId': statusReplyItemId,
          'statusReplyOwnerName': statusReplyOwnerName,
          'statusReplyOwnerPhotoUrl': statusReplyOwnerPhotoUrl,
          'statusReplyType': statusReplyType,
          'statusReplyText': statusReplyText,
          'statusReplyMediaUrl': statusReplyMediaUrl,
          'statusReplyCaption': statusReplyCaption,
          'statusReplyBackgroundColor': statusReplyBackgroundColor,
        };
        // Populate the in-memory memo SYNCHRONOUSLY so the stream's
        // snapshot for our own message never needs any async lookup.
        _payloadMemo[messageRef.id] = outgoingPayload;

        // Fire SQLite persistence in the background — the in-memory memo
        // is already set, so rendering is instant. SQLite is only needed
        // for crash recovery / cold restart. Previously these two
        // sequential awaits (saveRoomPreview + save) added 50-200ms to
        // every send BEFORE the Firestore batch.commit() could even start.
        final ps = await PlaintextStore.instance();
        unawaited(Future.wait([
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
        // ignore: avoid_print
        print('E2EE encrypt failed, falling back to plaintext: $e');
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
    );
    final lastMessagePreview = schemaVersion == 2
        ? _encryptedPreviewPlaceholder
        : (statusReplyOwnerId != null ? 'Replied to status: $text' : text);

    // Use batch write for consistency
    WriteBatch batch = _firestore.batch();

    // Add message
    batch.set(messageRef, message.toMap());

    // Update chat room with last message info
    batch.set(
      chatRoomRef,
      {
        'id': chatRoomId,
        'participants': [senderId, receiverId]..sort(),
        'lastMessage': lastMessagePreview,
        'lastMessageTime': Timestamp.fromDate(message.timestamp),
        'lastMessageSenderId': senderId,
        'lastMessageStatus': MessageStatus.sent.name,
        'unreadCount.$senderId': FieldValue.increment(0),
        'unreadCount.$receiverId': FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );

    print('[SEND] pre-commit: ${sw.elapsedMilliseconds}ms');
    await batch.commit();
    print('[SEND] committed: ${sw.elapsedMilliseconds}ms — ${message.id}');
    // Outbox cleanup happens in the merge layer the moment the Firestore
    // snapshot stream actually delivers the canonical message. Removing
    // here, between commit-ack and Firestore-observe, would cause a brief
    // 1-frame flicker where the bubble disappears and then reappears.

    // Fire-and-forget the FCM push. Awaiting it added 200ms–1s to every
    // send while the HTTP call to the notifications endpoint ran. The
    // message is already committed to Firestore by this point, so the
    // receiver will get it via the chat stream regardless — the FCM ping
    // is only there to wake a backgrounded app.
    //
    // E2EE: NEVER include the plaintext in the FCM payload. The FCM
    // backend can read whatever we put in here; the receiver's device
    // renders the real text after decryption.
    unawaited(() async {
      try {
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
        print('Error sending message notification: $e');
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
    String chatRoomId = getChatRoomId(currentUserId, otherUserId);

    DateTime? clearedAt;
    List<MessageModel> latestRaw = const [];
    List<MessageModel> latestDecrypted = const [];
    List<MessageModel> latestCommitted = const [];
    bool gotFirstFirestoreEmission = false;
    final controller = StreamController<List<MessageModel>>();

    void recomputeCommittedFromLatest() {
      // Re-apply the clearedAt filter against the latest decrypted list
      // without re-decrypting anything. clearedAt changes are rare (only
      // when the user taps "Clear all chats"), but we still want a fresh
      // filter pass to be cheap when it does happen.
      if (clearedAt == null) {
        latestCommitted = latestDecrypted;
      } else {
        latestCommitted = latestDecrypted
            .where((m) => m.timestamp.isAfter(clearedAt!))
            .toList();
      }
    }

    List<MessageModel> combine() {
      final outboxList = _outbox[chatRoomId] ?? const <MessageModel>[];
      if (outboxList.isEmpty) return latestCommitted;
      final committedIds = {for (final m in latestCommitted) m.id};
      final merged = <MessageModel>[
        ...latestCommitted,
        ...outboxList.where((m) => !committedIds.contains(m.id)),
      ];
      merged.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return merged;
    }

    // Re-runs the decrypt pass over the last raw Firestore snapshot.
    // Called on vault-ready ticks so the moment the user unlocks
    // (typically right after reinstall) every currently-displayed
    // "🔒 can't decrypt" bubble retries against the now-readable vault
    // and recovers its plaintext — without waiting for an unrelated
    // Firestore change to force a fresh snapshot.
    Future<void> redecryptLatest() async {
      if (latestRaw.isEmpty) return;
      final resolved = await Future.wait(
        latestRaw.map((m) async {
          final r = await decryptForRendering(m, currentUserId);
          return r ?? _lockedPlaceholder(m);
        }),
      );
      latestDecrypted = resolved;
      recomputeCommittedFromLatest();
      if (!controller.isClosed) controller.add(combine());
    }

    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
        chatRoomSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? messagesSub;
    StreamSubscription<void>? outboxSub;
    StreamSubscription<void>? vaultReadySub;

    // ignore: discarded_futures
    Future<void> start() async {
      // PERF CRITICAL: Await the SQLite bulk-load (~10-50ms) BEFORE attaching
      // the Firestore snapshot listener. Otherwise, the snapshot arrives instantly
      // and triggers 500 parallel individual SQLite `store.get()` queries (one
      // per message), which blocks the platform channel and stalls rendering
      // for 15-20 seconds!
      await _preWarmSqlite(currentUserId);

      // Kick off the Firestore-vault bulk prewarm in the BACKGROUND.
      // The vault read scales with the user's total message count and requires
      // a network round-trip. We let it run fire-and-forget; when it completes,
      // we re-decrypt the latest snapshot so any bubbles that fell back to
      // "locked" auto-recover.
      unawaited(_preWarmVault(currentUserId).then((_) {
        // ignore: discarded_futures
        redecryptLatest();
      }));

      // (1) Track clearedAt independently of the messages subscription.
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
        if (newClearedAt == clearedAt) return; // no-op for unrelated changes
        clearedAt = newClearedAt;
        recomputeCommittedFromLatest();
        if (!controller.isClosed && gotFirstFirestoreEmission) {
          controller.add(combine());
        }
      });

      // (2) Messages subscription — started once, never torn down.
      messagesSub = _firestore
          .collection(_chatRoomsCollection)
          .doc(chatRoomId)
          .collection(_messagesCollection)
          .orderBy('timestamp', descending: false)
          .snapshots()
          .listen((snapshot) async {
        final raw = snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList();
        latestRaw = raw;
        // Decrypt E2EE messages in parallel. v1 messages pass through.
        // Messages we can't decrypt (post-reinstall, lost session, etc.)
        // are surfaced as a "locked" placeholder bubble instead of being
        // dropped — so the user sees that something arrived and can ask
        // the sender to resend, rather than wondering why the sender's
        // blue ticks went up with no visible message.
        //
        // PERF: skip already-memoized messages entirely — they hit the
        // synchronous `_payloadMemo[msg.id]` path inside
        // decryptForRendering, but previously the Future.wait still
        // created N microtask-hops for every message in the snapshot.
        // On a 500-message chat this added measurable latency on every
        // Firestore emission (typing indicator, read receipt, etc.).
        // Now only truly-new messages enter the decrypt pipeline.
        final resolved = await Future.wait(
          raw.map((m) async {
            if (m.schemaVersion < 2) return m;
            if (_payloadMemo.containsKey(m.id)) {
              return _applyPayload(m, _payloadMemo[m.id]!);
            }
            final r = await decryptForRendering(m, currentUserId);
            return r ?? _lockedPlaceholder(m);
          }),
        );
        latestDecrypted = resolved;
        recomputeCommittedFromLatest();
        gotFirstFirestoreEmission = true;

        // Cleanup outbox entries whose canonical Firestore copy has now
        // landed. Done here (not in sendMessage's commit-ack) so there's
        // no frame where the bubble disappears before the canonical
        // version is in the list.
        final outboxList = _outbox[chatRoomId];
        if (outboxList != null && outboxList.isNotEmpty) {
          final committedIds = {for (final m in latestCommitted) m.id};
          final stillPending = outboxList
              .where((m) => !committedIds.contains(m.id))
              .toList();
          if (stillPending.length != outboxList.length) {
            if (stillPending.isEmpty) {
              _outbox.remove(chatRoomId);
            } else {
              _outbox[chatRoomId] = stillPending;
            }
          }
        }

        if (!controller.isClosed) controller.add(combine());
      }, onError: (e, st) {
        if (!controller.isClosed) controller.addError(e, st);
      });

      // (3) Outbox ticks: emit the combined view on every change. Until
      // Firestore has emitted at least once, latestCommitted is empty
      // and combine() falls back to outbox-only — which is the right
      // behaviour on cold open with a pending send.
      outboxSub = _outboxNotifier.stream.listen((_) {
        if (!controller.isClosed) controller.add(combine());
      });

      // (4) Vault-ready ticks: re-decrypt the cached raw snapshot the
      // moment the vault becomes usable. Fixes the post-reinstall case
      // where the home screen and chat both rendered with the "🔒 can't
      // decrypt" placeholder because the vault was still locked when the
      // first message snapshot arrived — once the user enters their PIN,
      // the bubbles auto-recover their plaintext from the vault.
      // ignore: discarded_futures
      vaultReadySub = _vaultReadyNotifier.stream.listen((_) async {
        try {
          await _preWarmSqlite(currentUserId);
          await _preWarmVault(currentUserId);
          await redecryptLatest();
        } catch (_) {}
      });
    }

    controller.onListen = start;
    controller.onCancel = () async {
      await chatRoomSub?.cancel();
      await messagesSub?.cancel();
      await outboxSub?.cancel();
      await vaultReadySub?.cancel();
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

      // First pass: build the room list with cached previews applied, and
      // collect any rooms whose cached preview is missing or stale so we can
      // decrypt their last message in parallel below.
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
        // The cached preview is fresh only when it's at least as new as the
        // room's lastMessageTime. Otherwise a new message landed (typically
        // an incoming reply after we sent something) and the cache still
        // points at our own outgoing text — drop it and eager-decrypt.
        final roomMs = chatRoom.lastMessageTime?.millisecondsSinceEpoch ?? 0;
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
          );
        } else if (chatRoom.lastMessage == _encryptedPreviewPlaceholder ||
            localPreview != null) {
          // Either the server text is the encrypted placeholder, or we have
          // a stale local preview — eager-decrypt the latest message.
          needsPreview.add(chatRooms.length);
        }

        chatRooms.add(chatRoom);
      }

      // Eager preview decrypt: fetch the latest message of each room that
      // still shows the placeholder and decrypt it locally. This is how
      // WhatsApp's chat list shows the real text without ever opening the
      // chat. Runs in parallel; per-room cost is one Firestore read + one
      // libsignal decrypt, and the result is persisted so subsequent
      // snapshots short-circuit to the SQLite cache.
      if (needsPreview.isNotEmpty) {
        await Future.wait(needsPreview.map((i) async {
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
            // Post-reinstall recovery: when the latest message can't be
            // decrypted, replace the generic "🔒 Encrypted message"
            // placeholder with the explicit "can't decrypt — ask sender
            // to resend" indicator so the user understands why their
            // chat looks empty inside.
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
            );
          } catch (_) {
            // Leave the placeholder in place; next snapshot will retry.
          }
        }));
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
}

