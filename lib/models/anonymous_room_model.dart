import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of an anonymous chat room.
enum AnonymousRoomStatus { active, ended }

/// Model representing an anonymous 1-on-1 chat session between two strangers.
class AnonymousRoomModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final String user1Alias;
  final String user2Alias;
  final AnonymousRoomStatus status;
  final DateTime createdAt;
  final DateTime? endedAt;
  final String? endedBy;

  AnonymousRoomModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.user1Alias,
    required this.user2Alias,
    this.status = AnonymousRoomStatus.active,
    required this.createdAt,
    this.endedAt,
    this.endedBy,
  });

  bool get isActive => status == AnonymousRoomStatus.active;

  /// Returns the alias for the given user in this room.
  String getAlias(String userId) {
    if (userId == user1Id) return user1Alias;
    if (userId == user2Id) return user2Alias;
    return 'Unknown';
  }

  /// Returns the partner's userId for the given user.
  String getPartnerId(String myId) {
    return myId == user1Id ? user2Id : user1Id;
  }

  /// Returns the partner's alias for the given user.
  String getPartnerAlias(String myId) {
    return myId == user1Id ? user2Alias : user1Alias;
  }

  Map<String, dynamic> toMap() {
    return {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'user1Alias': user1Alias,
      'user2Alias': user2Alias,
      'status': status == AnonymousRoomStatus.active ? 'active' : 'ended',
      'createdAt': Timestamp.fromDate(createdAt),
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'endedBy': endedBy,
    };
  }

  factory AnonymousRoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnonymousRoomModel(
      id: doc.id,
      user1Id: data['user1Id'] ?? '',
      user2Id: data['user2Id'] ?? '',
      user1Alias: data['user1Alias'] ?? 'Stranger 1',
      user2Alias: data['user2Alias'] ?? 'Stranger 2',
      status: data['status'] == 'ended'
          ? AnonymousRoomStatus.ended
          : AnonymousRoomStatus.active,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endedAt: (data['endedAt'] as Timestamp?)?.toDate(),
      endedBy: data['endedBy'],
    );
  }
}
