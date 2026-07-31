import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/services/fcm_service.dart';
import 'package:video_chat_app/services/user_service.dart';

enum ConnectionStateStatus { none, pendingSent, pendingReceived, friends }

class QuickConnectSuggestion {
  final UserModel user;
  final String reasonSubtitle;

  QuickConnectSuggestion({
    required this.user,
    required this.reasonSubtitle,
  });
}

class FriendRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FCMService _fcmService = FCMService();

  final String _requestsCollection = 'friend_requests';
  final String _usersCollection = 'users';

  /// Send a new connection/friend request.
  Future<bool> sendFriendRequest({
    required String fromUserId,
    required String toUserId,
    required String fromName,
    String? fromUsername,
  }) async {
    try {
      if (fromUserId == toUserId) return false;

      final status = await getConnectionStatus(fromUserId, toUserId);
      if (status != ConnectionStateStatus.none) {
        return false;
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
        screen: 'requests',
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
        screen: 'requests',
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

  /// Stream accepted friends list for current user.
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
      for (int i = 0; i < friendIds.length; i += 30) {
        final chunk = friendIds.sublist(
          i,
          (i + 30 < friendIds.length) ? i + 30 : friendIds.length,
        );
        final chunkSnap = await _firestore
            .collection(_usersCollection)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        friends.addAll(chunkSnap.docs.map((d) => UserModel.fromFirestore(d)));
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

  /// Fetches intelligent Quick Connect suggestions combining:
  /// 1. Mutual friends ("Mutual friend with [Name]" or "X mutual friends")
  /// 2. Matched device contacts ("From your phone contacts")
  /// 3. General suggestions ("Suggested for you" or "@username")
  ///
  /// Excludes current user, existing friends, and users with pending requests.
  Future<List<QuickConnectSuggestion>> getQuickConnectSuggestions(String currentUserId) async {
    final Map<String, QuickConnectSuggestion> suggestionsMap = {};
    final Set<String> excludedUserIds = {currentUserId};

    try {
      // 1. Collect current user's friend IDs
      final friendsSnap = await _firestore
          .collection(_usersCollection)
          .doc(currentUserId)
          .collection('friends')
          .get();
      final List<String> friendIds = friendsSnap.docs.map((d) => d.id).toList();
      excludedUserIds.addAll(friendIds);

      // 2. Collect pending request user IDs (both directions)
      final outgoingSnap = await _firestore
          .collection(_requestsCollection)
          .where('fromUserId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();
      for (var d in outgoingSnap.docs) {
        final toId = d.data()['toUserId'] as String?;
        if (toId != null) excludedUserIds.add(toId);
      }

      final incomingSnap = await _firestore
          .collection(_requestsCollection)
          .where('toUserId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();
      for (var d in incomingSnap.docs) {
        final fromId = d.data()['fromUserId'] as String?;
        if (fromId != null) excludedUserIds.add(fromId);
      }

      // 3. Find Mutual Friends (2nd degree connections)
      final Map<String, List<String>> mutualFriendNamesMap = {};

      for (String friendId in friendIds.take(10)) {
        final friendDoc = await _firestore.collection(_usersCollection).doc(friendId).get();
        if (!friendDoc.exists) continue;
        final friendUser = UserModel.fromFirestore(friendDoc);

        final subFriendsSnap = await _firestore
            .collection(_usersCollection)
            .doc(friendId)
            .collection('friends')
            .get();

        for (var doc in subFriendsSnap.docs) {
          final candidateId = doc.id;
          if (excludedUserIds.contains(candidateId)) continue;
          mutualFriendNamesMap.putIfAbsent(candidateId, () => []).add(friendUser.name);
        }
      }

      for (var entry in mutualFriendNamesMap.entries) {
        if (suggestionsMap.length >= 5) break;

        final candidateId = entry.key;
        final friendNames = entry.value;
        final candidateDoc = await _firestore.collection(_usersCollection).doc(candidateId).get();
        if (!candidateDoc.exists) continue;

        final candidateUser = UserModel.fromFirestore(candidateDoc);
        if (!candidateUser.isDiscoverable) continue;

        final String reason = friendNames.length == 1
            ? 'Mutual friend with ${friendNames.first}'
            : '${friendNames.length} mutual friends';

        suggestionsMap[candidateId] = QuickConnectSuggestion(
          user: candidateUser,
          reasonSubtitle: reason,
        );
      }

      // 4. Try matching Device Contacts if room (< 5 suggestions)
      if (suggestionsMap.length < 5) {
        try {
          final hasPermission = await fc.FlutterContacts.requestPermission(readonly: true);
          if (hasPermission) {
            final deviceContacts = await fc.FlutterContacts.getContacts(withProperties: true);
            final rawPhones = <String>[];
            final rawEmails = <String>[];
            for (final contact in deviceContacts) {
              rawPhones.addAll(contact.phones.map((p) => p.number));
              rawEmails.addAll(contact.emails.map((e) => e.address));
            }

            final matches = await UserService().matchDeviceContacts(
              rawPhoneNumbers: rawPhones,
              rawEmails: rawEmails,
              currentUserId: currentUserId,
            );

            for (var matchedUser in matches) {
              if (suggestionsMap.length >= 5) break;
              // matchDeviceContacts already drops non-discoverable users.
              if (excludedUserIds.contains(matchedUser.id) || suggestionsMap.containsKey(matchedUser.id)) {
                continue;
              }
              suggestionsMap[matchedUser.id] = QuickConnectSuggestion(
                user: matchedUser,
                reasonSubtitle: 'From your phone contacts',
              );
            }
          }
        } catch (_) {
          // Contact permission not granted — skip
        }
      }

      // 5. Fallback for new accounts without contacts/mutual friends
      if (suggestionsMap.length < 3) {
        final generalSnap = await _firestore
            .collection(_usersCollection)
            .where(FieldPath.documentId, isNotEqualTo: currentUserId)
            .limit(10)
            .get();

        for (var doc in generalSnap.docs) {
          if (suggestionsMap.length >= 3) break;
          final u = UserModel.fromFirestore(doc);
          if (!u.isDiscoverable) continue;
          if (excludedUserIds.contains(u.id) || suggestionsMap.containsKey(u.id)) {
            continue;
          }
          suggestionsMap[u.id] = QuickConnectSuggestion(
            user: u,
            reasonSubtitle: u.username != null && u.username!.isNotEmpty
                ? '@${u.username}'
                : 'Suggested for you',
          );
        }
      }
    } catch (e) {
      print('Error calculating Quick Connect suggestions: $e');
    }

    return suggestionsMap.values.toList();
  }
}
