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

  /// Metadata for a reply sent from a status update.
  final String? statusReplyOwnerId;
  final String? statusReplyItemId;
  final String? statusReplyOwnerName;
  final String? statusReplyOwnerPhotoUrl;
  final String? statusReplyType;
  final String? statusReplyText;
  final String? statusReplyMediaUrl;
  final String? statusReplyCaption;
  final String? statusReplyBackgroundColor;

  /// Local file path for images received/sent via mesh (not yet uploaded).
  final String? localFilePath;

  /// Duration of audio in seconds (for voice messages).
  final int? audioDuration;

  // ─── Offline Mesh Messaging fields ──────────────────────────────────
  /// Whether this message was sent/received via the mesh network.
  final bool isOfflineMesh;

  /// Number of peer-to-peer hops this message has traveled (0 = direct).
  final int meshHops;

  /// True if the message hasn't been synced to Firestore yet.
  final bool syncPending;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.type = MessageType.text,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.mediaUrl,
    this.statusReplyOwnerId,
    this.statusReplyItemId,
    this.statusReplyOwnerName,
    this.statusReplyOwnerPhotoUrl,
    this.statusReplyType,
    this.statusReplyText,
    this.statusReplyMediaUrl,
    this.statusReplyCaption,
    this.statusReplyBackgroundColor,
    this.localFilePath,
    this.audioDuration,
    this.isOfflineMesh = false,
    this.meshHops = 0,
    this.syncPending = false,
  });

  // Convenience getters for status
  bool get isDelivered =>
      status == MessageStatus.delivered || status == MessageStatus.read;
  bool get isRead => status == MessageStatus.read;
  bool get hasStatusReply =>
      statusReplyOwnerId != null && statusReplyItemId != null;

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
      'statusReplyOwnerId': statusReplyOwnerId,
      'statusReplyItemId': statusReplyItemId,
      'statusReplyOwnerName': statusReplyOwnerName,
      'statusReplyOwnerPhotoUrl': statusReplyOwnerPhotoUrl,
      'statusReplyType': statusReplyType,
      'statusReplyText': statusReplyText,
      'statusReplyMediaUrl': statusReplyMediaUrl,
      'statusReplyCaption': statusReplyCaption,
      'statusReplyBackgroundColor': statusReplyBackgroundColor,
      'audioDuration': audioDuration,
      // localFilePath is intentionally excluded from Firestore — it's local only.
      'isOfflineMesh': isOfflineMesh,
      'meshHops': meshHops,
      'syncPending': syncPending,
    };
  }

  /// Lightweight JSON map (no Firestore types) for mesh/local storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'type': type.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.name,
      'mediaUrl': mediaUrl,
      'statusReplyOwnerId': statusReplyOwnerId,
      'statusReplyItemId': statusReplyItemId,
      'statusReplyOwnerName': statusReplyOwnerName,
      'statusReplyOwnerPhotoUrl': statusReplyOwnerPhotoUrl,
      'statusReplyType': statusReplyType,
      'statusReplyText': statusReplyText,
      'statusReplyMediaUrl': statusReplyMediaUrl,
      'statusReplyCaption': statusReplyCaption,
      'statusReplyBackgroundColor': statusReplyBackgroundColor,
      'localFilePath': localFilePath,
      'audioDuration': audioDuration,
      'isOfflineMesh': isOfflineMesh,
      'meshHops': meshHops,
      'syncPending': syncPending,
    };
  }

  /// Create from a plain JSON map (mesh / SharedPreferences).
  factory MessageModel.fromJson(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      type: _parseMessageType(map['type']),
      timestamp: map['timestamp'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
      status: _parseMessageStatus(map['status']),
      mediaUrl: map['mediaUrl'],
      statusReplyOwnerId: map['statusReplyOwnerId'],
      statusReplyItemId: map['statusReplyItemId'],
      statusReplyOwnerName: map['statusReplyOwnerName'],
      statusReplyOwnerPhotoUrl: map['statusReplyOwnerPhotoUrl'],
      statusReplyType: map['statusReplyType'],
      statusReplyText: map['statusReplyText'],
      statusReplyMediaUrl: map['statusReplyMediaUrl'],
      statusReplyCaption: map['statusReplyCaption'],
      statusReplyBackgroundColor: map['statusReplyBackgroundColor'],
      localFilePath: map['localFilePath'],
      audioDuration: map['audioDuration'],
      isOfflineMesh: map['isOfflineMesh'] ?? false,
      meshHops: map['meshHops'] ?? 0,
      syncPending: map['syncPending'] ?? false,
    );
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
      statusReplyOwnerId: map['statusReplyOwnerId'],
      statusReplyItemId: map['statusReplyItemId'],
      statusReplyOwnerName: map['statusReplyOwnerName'],
      statusReplyOwnerPhotoUrl: map['statusReplyOwnerPhotoUrl'],
      statusReplyType: map['statusReplyType'],
      statusReplyText: map['statusReplyText'],
      statusReplyMediaUrl: map['statusReplyMediaUrl'],
      statusReplyCaption: map['statusReplyCaption'],
      statusReplyBackgroundColor: map['statusReplyBackgroundColor'],
      audioDuration: map['audioDuration'],
      isOfflineMesh: map['isOfflineMesh'] ?? false,
      meshHops: map['meshHops'] ?? 0,
      syncPending: map['syncPending'] ?? false,
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
    int? audioDuration,
    bool? isOfflineMesh,
    int? meshHops,
    bool? syncPending,
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
      statusReplyOwnerId: statusReplyOwnerId ?? this.statusReplyOwnerId,
      statusReplyItemId: statusReplyItemId ?? this.statusReplyItemId,
      statusReplyOwnerName: statusReplyOwnerName ?? this.statusReplyOwnerName,
      statusReplyOwnerPhotoUrl:
          statusReplyOwnerPhotoUrl ?? this.statusReplyOwnerPhotoUrl,
      statusReplyType: statusReplyType ?? this.statusReplyType,
      statusReplyText: statusReplyText ?? this.statusReplyText,
      statusReplyMediaUrl: statusReplyMediaUrl ?? this.statusReplyMediaUrl,
      statusReplyCaption: statusReplyCaption ?? this.statusReplyCaption,
      statusReplyBackgroundColor:
          statusReplyBackgroundColor ?? this.statusReplyBackgroundColor,
      localFilePath: localFilePath ?? this.localFilePath,
      audioDuration: audioDuration ?? this.audioDuration,
      isOfflineMesh: isOfflineMesh ?? this.isOfflineMesh,
      meshHops: meshHops ?? this.meshHops,
      syncPending: syncPending ?? this.syncPending,
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
