import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/services/fcm_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FCMService _fcmService = FCMService();
  final String _chatRoomsCollection = 'chatRooms';
  final String _messagesCollection = 'messages';

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
  }) async {
    String chatRoomId = getChatRoomId(senderId, receiverId);

    // Create message document reference
    DocumentReference messageRef = _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .doc();

    MessageModel message = MessageModel(
      id: messageRef.id,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      type: type,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      mediaUrl: mediaUrl,
    );

    // Use batch write for consistency
    WriteBatch batch = _firestore.batch();

    // Add message
    batch.set(messageRef, message.toMap());

    // Update chat room with last message info
    batch.update(
      _firestore.collection(_chatRoomsCollection).doc(chatRoomId),
      {
        'lastMessage': text,
        'lastMessageTime': Timestamp.fromDate(message.timestamp),
        'lastMessageSenderId': senderId,
        'lastMessageStatus': MessageStatus.sent.name,
        'unreadCount.$receiverId': FieldValue.increment(1),
      },
    );

    await batch.commit();
    print('Message sent: ${message.id}');

    // Send push notification for message delivery
    // This helps mark message as delivered even if receiver app is in background
    try {
      String displayName = senderName ?? 'Someone';
      await _fcmService.sendMessageNotification(
        receiverId: receiverId,
        senderId: senderId,
        senderName: displayName,
        message: text,
        chatRoomId: chatRoomId,
      );
    } catch (e) {
      print('Error sending message notification: $e');
      // Don't fail the message send if notification fails
    }

    return message;
  }

  // Get messages stream for a chat room
  Stream<List<MessageModel>> getMessages(
      String currentUserId, String otherUserId) {
    String chatRoomId = getChatRoomId(currentUserId, otherUserId);

    return _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
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

    return snapshot.docs
        .map((doc) => MessageModel.fromFirestore(doc))
        .toList()
        .reversed
        .toList();
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

    // Reset unread count for current user and update lastMessageStatus
    batch.update(
      _firestore.collection(_chatRoomsCollection).doc(chatRoomId),
      {
        'unreadCount.$currentUserId': 0,
        'lastMessageStatus': MessageStatus.read.name,
      },
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

  // Get chat rooms for a user
  Stream<List<ChatRoom>> getChatRooms(String userId) {
    return _firestore
        .collection(_chatRoomsCollection)
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      List<ChatRoom> chatRooms =
          snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList();

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
}
