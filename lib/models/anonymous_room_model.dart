import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of an anonymous chat room.
enum AnonymousRoomStatus { active, ended }

/// Status of the friend request within an anonymous room.
enum FriendRequestState { none, pending, accepted, declined }

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

  // ── Phase 2: Friend Request → E2EE transition ─────────────────────────
  /// The userId of whoever sent the pending friend request (null if none).
  final String? friendRequestFrom;

  /// State of the friend request flow in this room.
  final FriendRequestState friendRequestStatus;

  /// When a friend request is accepted, the standard E2EE chatRoom id is
  /// written here so both clients can navigate to the same [ChatScreen].
  final String? e2eeChatRoomId;

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
    this.friendRequestFrom,
    this.friendRequestStatus = FriendRequestState.none,
    this.e2eeChatRoomId,
  });

  bool get isActive => status == AnonymousRoomStatus.active;

  /// True when a friend request is awaiting a response.
  bool get hasPendingFriendRequest =>
      friendRequestStatus == FriendRequestState.pending;

  /// True when a friend request has been accepted (both users are now friends).
  bool get isFriendRequestAccepted =>
      friendRequestStatus == FriendRequestState.accepted;

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

  /// True when [userId] is the one who sent the pending friend request.
  bool didSendFriendRequest(String userId) =>
      hasPendingFriendRequest && friendRequestFrom == userId;

  /// True when [userId] is the one who should respond to the pending request.
  bool shouldRespondToFriendRequest(String userId) =>
      hasPendingFriendRequest &&
      friendRequestFrom != null &&
      friendRequestFrom != userId;

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
      'friendRequestFrom': friendRequestFrom,
      'friendRequestStatus': _friendRequestStatusToString(friendRequestStatus),
      'e2eeChatRoomId': e2eeChatRoomId,
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
      friendRequestFrom: data['friendRequestFrom'],
      friendRequestStatus:
          _friendRequestStatusFromString(data['friendRequestStatus']),
      e2eeChatRoomId: data['e2eeChatRoomId'],
    );
  }

  static String _friendRequestStatusToString(FriendRequestState s) {
    switch (s) {
      case FriendRequestState.pending:
        return 'pending';
      case FriendRequestState.accepted:
        return 'accepted';
      case FriendRequestState.declined:
        return 'declined';
      case FriendRequestState.none:
        return 'none';
    }
  }

  static FriendRequestState _friendRequestStatusFromString(dynamic s) {
    switch (s) {
      case 'pending':
        return FriendRequestState.pending;
      case 'accepted':
        return FriendRequestState.accepted;
      case 'declined':
        return FriendRequestState.declined;
      default:
        return FriendRequestState.none;
    }
  }
}
