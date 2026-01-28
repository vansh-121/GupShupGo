import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, audio, video }

enum MessageStatus {
  sent, // Message sent but not delivered
  delivered, // Message delivered to device but not read
  read // Message read by receiver
}

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final String? mediaUrl;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.type = MessageType.text,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.mediaUrl,
  });

  // Convenience getters for status
  bool get isDelivered =>
      status == MessageStatus.delivered || status == MessageStatus.read;
  bool get isRead => status == MessageStatus.read;

  // Convert MessageModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.name,
      'mediaUrl': mediaUrl,
    };
  }

  // Create MessageModel from Firestore document
  factory MessageModel.fromMap(Map<String, dynamic> map, String documentId) {
    return MessageModel(
      id: documentId,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      type: _parseMessageType(map['type']),
      timestamp: _parseTimestamp(map['timestamp']),
      status: _parseMessageStatus(map['status']),
      mediaUrl: map['mediaUrl'],
    );
  }

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MessageModel.fromMap(data, doc.id);
  }

  static MessageType _parseMessageType(String? type) {
    switch (type) {
      case 'image':
        return MessageType.image;
      case 'audio':
        return MessageType.audio;
      case 'video':
        return MessageType.video;
      default:
        return MessageType.text;
    }
  }

  static MessageStatus _parseMessageStatus(dynamic status) {
    if (status == null) return MessageStatus.sent;
    // Handle legacy isRead boolean
    if (status is bool) {
      return status ? MessageStatus.read : MessageStatus.delivered;
    }
    switch (status.toString()) {
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      default:
        return MessageStatus.sent;
    }
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? text,
    MessageType? type,
    DateTime? timestamp,
    MessageStatus? status,
    String? mediaUrl,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      mediaUrl: mediaUrl ?? this.mediaUrl,
    );
  }
}

// Chat room model to track conversations
class ChatRoom {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final MessageStatus? lastMessageStatus;
  final Map<String, int> unreadCount;

  ChatRoom({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.lastMessageStatus,
    this.unreadCount = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime':
          lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageStatus': lastMessageStatus?.name,
      'unreadCount': unreadCount,
    };
  }

  factory ChatRoom.fromMap(Map<String, dynamic> map, String documentId) {
    return ChatRoom(
      id: documentId,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : null,
      lastMessageSenderId: map['lastMessageSenderId'],
      lastMessageStatus: _parseMessageStatus(map['lastMessageStatus']),
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
    );
  }

  static MessageStatus? _parseMessageStatus(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return MessageStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => MessageStatus.sent,
      );
    }
    return MessageStatus.sent;
  }

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatRoom.fromMap(data, doc.id);
  }
}
