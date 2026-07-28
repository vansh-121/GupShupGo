import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/services/fcm_service.dart';

enum ConnectionStateStatus { none, pendingSent, pendingReceived, friends }

class FriendRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FCMService _fcmService = FCMService();

  final String _requestsCollection = 'friend_requests';
  final String _usersCollection = 'users';

  /// Send a new connection/friend request
  Future<bool> sendFriendRequest({
    required String fromUserId,
    required String toUserId,
    required String fromName,
    String? fromUsername,
  }) async {
    try {
      if (fromUserId == toUserId) return false;

      // Check if already friends or request pending
      final existingReq = await _firestore
          .collection(_requestsCollection)
          .where('fromUserId', isEqualTo: fromUserId)
          .where('toUserId', isEqualTo: toUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingReq.docs.isNotEmpty) {
        return false; // Request already pending
      }

      DocumentReference ref = await _firestore.collection(_requestsCollection).add({
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'fromName': fromName,
        'fromUsername': fromUsername ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Notify target user via FCM
      await _fcmService.sendMessageNotification(
        receiverId: toUserId,
        senderId: fromUserId,
        senderName: fromName,
        message: '$fromName (@${fromUsername ?? fromName}) wants to connect with you on GupShupGo.',
        chatRoomId: 'friend_req_${ref.id}',
      );

      return true;
    } catch (e) {
      print('Error sending friend request: $e');
      return false;
    }
  }

  /// Accept incoming friend request
  Future<bool> acceptFriendRequest({
    required String requestId,
    required String currentUserId,
    required String friendId,
  }) async {
    try {
      final batch = _firestore.batch();

      // Update request doc
      DocumentReference reqRef = _firestore.collection(_requestsCollection).doc(requestId);
      batch.update(reqRef, {
        'status': 'accepted',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      // Add to current user's friends collection
      DocumentReference myFriendRef = _firestore
          .collection(_usersCollection)
          .doc(currentUserId)
          .collection('friends')
          .doc(friendId);
      batch.set(myFriendRef, {
        'friendId': friendId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add to friend's friends collection
      DocumentReference targetFriendRef = _firestore
          .collection(_usersCollection)
          .doc(friendId)
          .collection('friends')
          .doc(currentUserId);
      batch.set(targetFriendRef, {
        'friendId': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Send confirmation FCM notification
      await _fcmService.sendMessageNotification(
        receiverId: friendId,
        senderId: currentUserId,
        senderName: 'GupShupGo',
        message: 'Your connection request has been accepted. You can now chat and call!',
        chatRoomId: 'friend_acc_$currentUserId',
      );

      return true;
    } catch (e) {
      print('Error accepting friend request: $e');
      return false;
    }
  }

  /// Decline friend request
  Future<void> declineFriendRequest(String requestId) async {
    try {
      await _firestore.collection(_requestsCollection).doc(requestId).update({
        'status': 'declined',
        'respondedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error declining friend request: $e');
    }
  }

  /// Stream incoming pending friend requests
  Stream<QuerySnapshot> streamIncomingRequests(String currentUserId) {
    return _firestore
        .collection(_requestsCollection)
        .where('toUserId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  /// Stream accepted friends list for current user
  Stream<List<UserModel>> streamFriends(String currentUserId) {
    return _firestore
        .collection(_usersCollection)
        .doc(currentUserId)
        .collection('friends')
        .snapshots()
        .asyncMap((snapshot) async {
      List<String> friendIds = snapshot.docs.map((doc) => doc.id).toList();

      if (friendIds.isEmpty) return [];

      List<UserModel> friends = [];
      for (String fid in friendIds) {
        DocumentSnapshot uDoc = await _firestore.collection(_usersCollection).doc(fid).get();
        if (uDoc.exists) {
          friends.add(UserModel.fromFirestore(uDoc));
        }
      }
      return friends;
    });
  }

  /// Get current connection status between current user and target user
  Future<ConnectionStateStatus> getConnectionStatus(String currentUserId, String targetUserId) async {
    if (currentUserId == targetUserId) return ConnectionStateStatus.none;

    try {
      // Check if already friends
      DocumentSnapshot friendDoc = await _firestore
          .collection(_usersCollection)
          .doc(currentUserId)
          .collection('friends')
          .doc(targetUserId)
          .get();

      if (friendDoc.exists) {
        return ConnectionStateStatus.friends;
      }

      // Check pending outgoing request
      QuerySnapshot outgoing = await _firestore
          .collection(_requestsCollection)
          .where('fromUserId', isEqualTo: fromUserIdQuery(currentUserId))
          .where('toUserId', isEqualTo: targetUserId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (outgoing.docs.isNotEmpty) {
        return ConnectionStateStatus.pendingSent;
      }

      // Check pending incoming request
      QuerySnapshot incoming = await _firestore
          .collection(_requestsCollection)
          .where('fromUserId', isEqualTo: targetUserId)
          .where('toUserId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (incoming.docs.isNotEmpty) {
        return ConnectionStateStatus.pendingReceived;
      }

      return ConnectionStateStatus.none;
    } catch (e) {
      print('Error checking connection status: $e');
      return ConnectionStateStatus.none;
    }
  }

  String fromUserIdQuery(String id) => id;
}
