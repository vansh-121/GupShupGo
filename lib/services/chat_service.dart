import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/services/crypto/device_identity_service.dart';
import 'package:video_chat_app/services/crypto/plaintext_store.dart';
import 'package:video_chat_app/services/crypto/signal_service.dart';
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

  /// Resolves a Firestore MessageModel into its rendered form.
  ///
  /// • v1 (legacy plaintext) messages pass through unchanged.
  /// • v2 (E2EE) messages are answered from the local PlaintextStore. We
  ///   only call into libsignal on a cache miss, then persist the result
  ///   so the next render is a pure SQLite hit.
  /// • If we can't produce plaintext (the envelope isn't addressed to this
  ///   device, the ratchet has moved past this message, the session is
  ///   missing, etc.) we return null and the stream filters the message
  ///   out — WhatsApp's behaviour for unrecoverable history.
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
    if (envelopes == null || envelopes.isEmpty) return null;
    final deviceId = await _deviceIdentity.getDeviceId();
    if (deviceId == null) return null;
    final env = envelopes['$selfUid:$deviceId'];
    if (env == null) return null;

    try {
      final pt = await SignalService.instance.decrypt(
        msg.senderId,
        msg.senderDeviceId ?? 1,
        EncryptedEnvelope.fromMap(env),
      );
      final payload = jsonDecode(utf8.decode(pt)) as Map<String, dynamic>;
      _payloadMemo[msg.id] = payload;
      await store.save(msg.id, payload);
      // Update the chat-list preview from the receiver's side so the most
      // recent decrypted message shows up immediately on the home screen.
      final chatRoomId = getChatRoomId(msg.senderId, msg.receiverId);
      await store.saveRoomPreview(
        chatRoomId: chatRoomId,
        messageId: msg.id,
        text: (payload['text'] as String?) ?? '',
      );
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
    final optimistic = MessageModel(
      id: messageRef.id,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      type: type,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
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
    // ── E2EE: build the inner plaintext payload, encrypt for every device
    //         of receiver + sender's other devices (multi-device fan-out).
    final senderDeviceId = await _deviceIdentity.getDeviceId();
    final canEncrypt =
        senderDeviceId != null && await _peerHasKeyBundle(receiverId);

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
        envelopes = encs.map((k, v) => MapEntry(k, v.toMap()));
        storedText = '';
        schemaVersion = 2;
        // Persist our own outgoing plaintext to the local sqflite store so
        // this device can render the message when the Firestore write loops
        // back through the chat stream. No envelope is produced for the
        // sending device in the fan-out, so this is the only way to recover
        // the body. Survives app restart, unlike a process-local cache.
        final ps = await PlaintextStore.instance();
        await ps.saveRoomPreview(
          chatRoomId: chatRoomId,
          messageId: messageRef.id,
          text: statusReplyOwnerId != null
              ? 'Replied to status: $text'
              : text,
        );
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
        // Populate the in-memory memo BEFORE the Firestore write so the
        // stream's snapshot for our own message hits the synchronous path
        // and renders without a SQLite round-trip.
        _payloadMemo[messageRef.id] = outgoingPayload;
        await ps.save(messageRef.id, outgoingPayload);
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

    await PerformanceService.traceAsync(
      'chat_send_message',
      (trace) async {
        PerformanceService.setAttribute(
            trace, 'msg_type', type.name);
        await batch.commit();
      },
    );
    print('Message sent: ${message.id}');
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
  Stream<List<MessageModel>> getMessages(
      String currentUserId, String otherUserId) {
    String chatRoomId = getChatRoomId(currentUserId, otherUserId);

    // Combine the chatRoom doc stream (for clearedAt) with the messages stream
    return _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .snapshots()
        .asyncExpand((chatRoomSnap) {
      DateTime? clearedAt;
      if (chatRoomSnap.exists) {
        final data = chatRoomSnap.data();
        final clearedAtMap = data?['clearedAt'] as Map<String, dynamic>?;
        final ts = clearedAtMap?[currentUserId];
        if (ts is Timestamp) {
          clearedAt = ts.toDate();
        }
      }

      // The base Firestore stream of committed messages.
      final firestoreStream = _firestore
          .collection(_chatRoomsCollection)
          .doc(chatRoomId)
          .collection(_messagesCollection)
          .orderBy('timestamp', descending: false)
          .snapshots()
          .asyncMap((snapshot) async {
        final raw = snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .where((msg) =>
                clearedAt == null || msg.timestamp.isAfter(clearedAt))
            .toList();
        // Decrypt E2EE messages in parallel. v1 messages pass through.
        // Null returns (messages we can't render) are filtered out — the
        // chat list silently omits them, like WhatsApp omits messages it
        // couldn't restore from backup.
        final resolved = await Future.wait(
          raw.map((m) => decryptForRendering(m, currentUserId)),
        );
        return resolved.whereType<MessageModel>().toList();
      });

      // Merge the Firestore stream with outbox change notifications. Every
      // time either source ticks we re-emit the union of (latest Firestore
      // list) ∪ (current outbox), with outbox entries filtered out if the
      // canonical Firestore message with the same id has already landed.
      // This is what makes the bubble appear instantly on tap and then
      // seamlessly hand off to the Firestore-backed render once the commit
      // completes — without ever showing the same bubble twice.
      return _mergeWithOutbox(chatRoomId, firestoreStream);
    });
  }

  /// Combines the committed-message stream with the local outbox so a
  /// freshly-tapped send shows up as a bubble in the same frame.
  Stream<List<MessageModel>> _mergeWithOutbox(
    String chatRoomId,
    Stream<List<MessageModel>> firestoreStream,
  ) {
    List<MessageModel> latestCommitted = const [];
    bool gotFirstFirestoreEmission = false;
    final controller = StreamController<List<MessageModel>>();

    List<MessageModel> combine() {
      final outboxList = _outbox[chatRoomId] ?? const <MessageModel>[];
      if (outboxList.isEmpty) return latestCommitted;
      // Dedup: once Firestore has delivered a message, the outbox copy
      // (which may still be in the middle of being removed by the post-
      // commit cleanup) must not appear alongside the canonical version.
      final committedIds = {for (final m in latestCommitted) m.id};
      final merged = <MessageModel>[
        ...latestCommitted,
        ...outboxList.where((m) => !committedIds.contains(m.id)),
      ];
      merged.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return merged;
    }

    StreamSubscription<List<MessageModel>>? firestoreSub;
    StreamSubscription<void>? outboxSub;

    void start() {
      firestoreSub = firestoreStream.listen(
        (msgs) {
          latestCommitted = msgs;
          gotFirstFirestoreEmission = true;
          // The moment Firestore confirms a previously-pending message has
          // arrived, drop its optimistic twin from the outbox. We defer
          // this until the canonical version is actually in the snapshot
          // list — clearing on commit-ack alone would leave a 1-frame gap
          // where the bubble vanishes and re-appears.
          final outboxList = _outbox[chatRoomId];
          if (outboxList != null && outboxList.isNotEmpty) {
            final committedIds = {for (final m in msgs) m.id};
            final stillPending = outboxList
                .where((m) => !committedIds.contains(m.id))
                .toList();
            if (stillPending.length != outboxList.length) {
              if (stillPending.isEmpty) {
                _outbox.remove(chatRoomId);
              } else {
                _outbox[chatRoomId] = stillPending;
              }
              // Don't emit on _outboxNotifier here — we're about to emit
              // a combined frame ourselves and a duplicate tick would
              // just trigger an identical rebuild.
            }
          }
          if (!controller.isClosed) controller.add(combine());
        },
        onError: (e, st) {
          if (!controller.isClosed) controller.addError(e, st);
        },
        onDone: () {
          if (!controller.isClosed) controller.close();
        },
      );
      // Outbox ticks emit on top of whatever the last Firestore snapshot
      // was. If Firestore hasn't emitted yet we still emit so the bubble
      // appears immediately on a cold open.
      outboxSub = _outboxNotifier.stream.listen((_) {
        if (controller.isClosed) return;
        if (gotFirstFirestoreEmission) {
          controller.add(combine());
        } else {
          controller.add(_outbox[chatRoomId] ?? const <MessageModel>[]);
        }
      });
      // Emit an initial frame if the outbox already has entries for this
      // room (e.g. user opens the chat right after firing a send).
      final initialOutbox = _outbox[chatRoomId];
      if (initialOutbox != null && initialOutbox.isNotEmpty) {
        controller.add(List<MessageModel>.from(initialOutbox));
      }
    }

    controller.onListen = start;
    controller.onCancel = () async {
      await firestoreSub?.cancel();
      await outboxSub?.cancel();
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
      raw.map((m) => decryptForRendering(m, currentUserId)),
    );
    return resolved.whereType<MessageModel>().toList();
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

  // Mark ALL messages as delivered across ALL chats when app opens
  // This simulates WhatsApp behavior - messages are delivered when app syncs
  Future<void> markAllMessagesAsDeliveredOnAppOpen(String currentUserId) async {
    try {
      // Get all chat rooms where user is a participant
      QuerySnapshot chatRoomsSnapshot = await _firestore
          .collection(_chatRoomsCollection)
          .where('participants', arrayContains: currentUserId)
          .get();

      if (chatRoomsSnapshot.docs.isEmpty) return;

      int totalMarked = 0;

      for (var chatRoomDoc in chatRoomsSnapshot.docs) {
        // Get all 'sent' messages in this chat room where current user is receiver
        QuerySnapshot sentMessages = await _firestore
            .collection(_chatRoomsCollection)
            .doc(chatRoomDoc.id)
            .collection(_messagesCollection)
            .where('receiverId', isEqualTo: currentUserId)
            .where('status', isEqualTo: 'sent')
            .get();

        if (sentMessages.docs.isEmpty) continue;

        WriteBatch batch = _firestore.batch();

        for (var doc in sentMessages.docs) {
          batch.update(doc.reference, {'status': 'delivered'});
        }

        // Also update the chatRoom's lastMessageStatus
        batch.update(chatRoomDoc.reference,
            {'lastMessageStatus': MessageStatus.delivered.name});

        await batch.commit();
        totalMarked += sentMessages.docs.length;
      }

      if (totalMarked > 0) {
        print('Marked $totalMarked messages as delivered on app open');
      }
    } catch (e) {
      print('Error marking messages as delivered on app open: $e');
    }
  }

  // Get chat rooms for a user.
  // Hides chats the user has cleared (via "Clear all chats") unless a new
  // message arrived after the clear timestamp — in that case the chat
  // reappears automatically (WhatsApp behaviour).
  Stream<List<ChatRoom>> getChatRooms(String userId) {
    return _firestore
        .collection(_chatRoomsCollection)
        .where('participants', arrayContains: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      final ps = await PlaintextStore.instance();
      final previews = await ps.getAllRoomPreviews();

      // First pass: build the room list with cached previews applied, and
      // collect any rooms that show the encrypted placeholder so we can
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
        if (localPreview != null) {
          chatRoom = ChatRoom(
            id: chatRoom.id,
            participants: chatRoom.participants,
            lastMessage: localPreview,
            lastMessageTime: chatRoom.lastMessageTime,
            lastMessageSenderId: chatRoom.lastMessageSenderId,
            lastMessageStatus: chatRoom.lastMessageStatus,
            unreadCount: chatRoom.unreadCount,
          );
        } else if (chatRoom.lastMessage == _encryptedPreviewPlaceholder) {
          // No local preview and the server-side text is the encrypted
          // placeholder — schedule an eager decrypt below.
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
            if (decrypted == null) return;
            final text = decrypted.text.isNotEmpty
                ? decrypted.text
                : (decrypted.mediaUrl != null ? 'Media' : '');
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
    });
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

