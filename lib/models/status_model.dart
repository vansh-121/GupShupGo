import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single status item (text or image).
class StatusItem {
  final String id;
  final String type; // 'text' or 'image'
  final String? text;
  final String? imageUrl;
  final String? caption;
  final String backgroundColor; // Hex color for text statuses
  final DateTime createdAt;
  final List<String> viewedBy; // List of user IDs who viewed this status

  StatusItem({
    required this.id,
    required this.type,
    this.text,
    this.imageUrl,
    this.caption,
    this.backgroundColor = '#075E54',
    required this.createdAt,
    this.viewedBy = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'text': text,
      'imageUrl': imageUrl,
      'caption': caption,
      'backgroundColor': backgroundColor,
      'createdAt': Timestamp.fromDate(createdAt),
      'viewedBy': viewedBy,
    };
  }

  factory StatusItem.fromMap(Map<String, dynamic> map) {
    return StatusItem(
      id: map['id'] ?? '',
      type: map['type'] ?? 'text',
      text: map['text'],
      imageUrl: map['imageUrl'],
      caption: map['caption'],
      backgroundColor: map['backgroundColor'] ?? '#075E54',
      createdAt: _parseDateTime(map['createdAt']),
      viewedBy: List<String>.from(map['viewedBy'] ?? []),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }
}

/// Represents a user's status collection (all their status items in 24h).
class StatusModel {
  final String id; // Same as userId
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String? userPhoneNumber;
  final List<StatusItem> statusItems;
  final DateTime lastUpdated;

  StatusModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    this.userPhoneNumber,
    required this.statusItems,
    required this.lastUpdated,
  });

  /// Check if the status has any unexpired items.
  bool get hasActiveStatus {
    final cutoff = DateTime.now().subtract(Duration(hours: 24));
    return statusItems.any((item) => item.createdAt.isAfter(cutoff));
  }

  /// Get only the active (non-expired) status items.
  List<StatusItem> get activeStatusItems {
    final cutoff = DateTime.now().subtract(Duration(hours: 24));
    return statusItems.where((item) => item.createdAt.isAfter(cutoff)).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'userPhoneNumber': userPhoneNumber,
      'statusItems': statusItems.map((item) => item.toMap()).toList(),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  factory StatusModel.fromMap(Map<String, dynamic> map, String documentId) {
    final items = (map['statusItems'] as List<dynamic>?)
            ?.map((item) => StatusItem.fromMap(item as Map<String, dynamic>))
            .toList() ??
        [];
    return StatusModel(
      id: documentId,
      userId: map['userId'] ?? documentId,
      userName: map['userName'] ?? 'Unknown',
      userPhotoUrl: map['userPhotoUrl'],
      userPhoneNumber: map['userPhoneNumber'],
      statusItems: items,
      lastUpdated: StatusItem._parseDateTime(map['lastUpdated']),
    );
  }

  factory StatusModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return StatusModel.fromMap(data, doc.id);
  }
}
