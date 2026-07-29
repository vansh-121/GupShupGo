import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a friend request originating from an anonymous chat.
enum FriendRequestStatus { pending, accepted, declined }

/// Model representing a friend request sent from within an anonymous chat
/// room. Accepting it bootstraps a full E2EE chat (see
/// [AnonymousChatService.acceptFriendRequest]).
class FriendRequestModel {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String anonymousRoomId;
  final String fromAlias;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  FriendRequestModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.anonymousRoomId,
    required this.fromAlias,
    this.status = FriendRequestStatus.pending,
    required this.createdAt,
    this.respondedAt,
  });

  bool get isPending => status == FriendRequestStatus.pending;

  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'anonymousRoomId': anonymousRoomId,
      'fromAlias': fromAlias,
      'status': _statusToString(status),
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt':
          respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  factory FriendRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendRequestModel(
      id: doc.id,
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      anonymousRoomId: data['anonymousRoomId'] ?? '',
      fromAlias: data['fromAlias'] ?? 'Stranger',
      status: _statusFromString(data['status']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
    );
  }

  static String _statusToString(FriendRequestStatus s) {
    switch (s) {
      case FriendRequestStatus.accepted:
        return 'accepted';
      case FriendRequestStatus.declined:
        return 'declined';
      case FriendRequestStatus.pending:
        return 'pending';
    }
  }

  static FriendRequestStatus _statusFromString(dynamic s) {
    switch (s) {
      case 'accepted':
        return FriendRequestStatus.accepted;
      case 'declined':
        return FriendRequestStatus.declined;
      default:
        return FriendRequestStatus.pending;
    }
  }
}
