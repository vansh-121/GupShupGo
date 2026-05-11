import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/services/crypto/device_identity_service.dart';
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

  /// Returns true iff the peer has at least one device with a published
  /// key bundle (i.e. they've upgraded to an E2EE-capable build).
  Future<bool> _peerHasKeyBundle(String peerUid) async {
    final snap = await _firestore
        .collection('users')
        .doc(peerUid)
        .collection('devices')
        .where('keyBundle', isNull: false)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Decrypts a v2 (E2EE) message in-memory for rendering. Returns the
  /// same model with `text` (and reply/media fields) populated from the
  /// envelope addressed to (selfUid, selfDeviceId). If no envelope is
  /// addressed to us, returns the message with `text = '⚠ This message
  /// can't be decrypted on this device.'`
  ///
  /// v1 messages are passed through unchanged.
  Future<MessageModel> decryptForRendering(
      MessageModel msg, String selfUid) async {
    if (msg.schemaVersion < 2) return msg;
    final envelopes = msg.envelopes;
    if (envelopes == null || envelopes.isEmpty) {
      return msg.copyWith(text: '⚠ Encrypted message (no envelope)');
    }
    final deviceId = await _deviceIdentity.getDeviceId();
    if (deviceId == null) {
      return msg.copyWith(text: '⚠ Encryption keys missing on this device');
    }
    final addr = '$selfUid:$deviceId';
    final env = envelopes[addr];
    if (env == null) {
      return msg.copyWith(
          text: '⚠ Message was sent from another device of yours');
    }
    try {
      final pt = await SignalService.instance.decrypt(
        msg.senderId,
        msg.senderDeviceId ?? 1,
        EncryptedEnvelope.fromMap(env),
      );
      final payload = jsonDecode(utf8.decode(pt)) as Map<String, dynamic>;
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
    } catch (e) {
      // ignore: avoid_print
      print('decrypt failed for ${msg.id}: $e');
      return msg.copyWith(text: '⚠ Decryption failed');
    }
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

    // Create message document reference
    DocumentReference messageRef = chatRoomRef
        .collection(_messagesCollection)
        .doc();

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

    // Send push notification for message delivery.
    // This helps mark message as delivered even if receiver app is in background.
    //
    // E2EE: NEVER include the plaintext in the FCM payload. The FCM service
    // is operated by the cloud provider and any preview text is visible to
    // them. We pass a generic preview when E2EE is active; the receiver's
    // device renders the real text after decryption.
    try {
      String displayName = senderName ?? 'Someone';
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
      // Don't fail the message send if notification fails
    }

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

      return _firestore
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
        return Future.wait(
          raw.map((m) => decryptForRendering(m, currentUserId)),
        );
      });
    });
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
    return Future.wait(
      raw.map((m) => decryptForRendering(m, currentUserId)),
    );
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
        .map((snapshot) {
      List<ChatRoom> chatRooms = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final chatRoom = ChatRoom.fromMap(data, doc.id);

        // Check per-user clearedAt timestamp
        final clearedAtMap = data['clearedAt'] as Map<String, dynamic>?;
        if (clearedAtMap != null && clearedAtMap[userId] != null) {
          final clearedAt = (clearedAtMap[userId] as Timestamp).toDate();
          // Hide if no messages exist after clear time
          if (chatRoom.lastMessageTime == null ||
              !chatRoom.lastMessageTime!.isAfter(clearedAt)) {
            continue; // skip this chat room
          }
        }

        chatRooms.add(chatRoom);
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
