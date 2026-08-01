import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:permission_handler/permission_handler.dart' as ph;
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
        'requestId': requestId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add to friend's friends collection
      DocumentReference targetFriendRef = _firestore
          .collection(_usersCollection)
          .doc(friendId)
          .collection('friends')
          .doc(currentUserId);
      // `requestId` is REQUIRED by firestore.rules for this write: it is the
      // reciprocal insert into the requester's friends list, and the rule
      // uses it to confirm a pending request from them to us actually
      // exists. Dropping this field will make accepting a request fail with
      // permission-denied.
      batch.set(targetFriendRef, {
        'friendId': currentUserId,
        'requestId': requestId,
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

  /// Decline friend request. Returns false if the write was rejected, so the
  /// caller can surface it — previously this returned void and swallowed the
  /// error, leaving the row on screen with no explanation.
  Future<bool> declineFriendRequest(String requestId) async {
    try {
      await _firestore.collection(_requestsCollection).doc(requestId).update({
        'status': 'declined',
        'respondedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error declining friend request: $e');
      return false;
    }
  }

  /// Resolves the pending request id sent by [fromUserId] to [currentUserId].
  ///
  /// Needed by any "Accept" affordance that is rendered from a user profile
  /// rather than from the requests list, where the request id isn't in hand.
  /// Lives here rather than inline in widgets so the query (and its rules
  /// constraints) has exactly one definition.
  Future<String?> findPendingRequestId({
    required String fromUserId,
    required String currentUserId,
  }) async {
    try {
      final snap = await _firestore
          .collection(_requestsCollection)
          .where('fromUserId', isEqualTo: fromUserId)
          .where('toUserId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      return snap.docs.isEmpty ? null : snap.docs.first.id;
    } catch (e) {
      print('Error resolving pending request id: $e');
      return null;
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
  ///
  /// Profile chunks are fetched concurrently rather than in a sequential
  /// `await` loop — with 90 friends that was 3 serial round-trips on every
  /// single change to the friends subcollection.
  Stream<List<UserModel>> streamFriends(String currentUserId) {
    return _firestore
        .collection(_usersCollection)
        .doc(currentUserId)
        .collection('friends')
        .snapshots()
        .asyncMap((snapshot) async {
      final friendIds = snapshot.docs.map((doc) => doc.id).toList();
      if (friendIds.isEmpty) return <UserModel>[];

      // whereIn accepts at most 30 values per query.
      final chunks = <List<String>>[];
      for (int i = 0; i < friendIds.length; i += 30) {
        chunks.add(friendIds.sublist(
          i,
          (i + 30 < friendIds.length) ? i + 30 : friendIds.length,
        ));
      }

      try {
        final snaps = await Future.wait(chunks.map((chunk) => _firestore
            .collection(_usersCollection)
            .where(FieldPath.documentId, whereIn: chunk)
            .get()));

        return snaps
            .expand((s) => s.docs)
            .map((d) => UserModel.fromFirestore(d))
            .toList();
      } catch (e) {
        // A failed profile fetch shouldn't collapse the friends stream into
        // an error state that renders as "No Friends Added Yet".
        print('Error loading friend profiles: $e');
        return <UserModel>[];
      }
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
          .where('fromUserId', isEqualTo: currentUserId)
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

  /// Fetches intelligent Quick Connect suggestions combining:
  /// 1. Mutual friends ("Mutual friend with [Name]" or "X mutual friends")
  /// 2. Matched device contacts ("From your phone contacts")
  /// 3. General suggestions ("Suggested for you" or "@username")
  ///
  /// Excludes current user, existing friends, and users with pending requests.
  /// Every phase below is individually guarded. Previously the whole body
  /// shared one try/catch, and phase 3 (mutual friends) reads
  /// `/users/{someoneElse}/friends` as a *list* query — which firestore.rules
  /// denies, because a collection query cannot bind the `{friendId}` wildcard
  /// that the read rule depends on. That permission-denied exception aborted
  /// phases 4 and 5 as well, so any account with at least one friend got zero
  /// suggestions forever, while brand-new accounts (empty friend list, loop
  /// never entered) worked fine. Isolating each phase is what actually fixes
  /// the "no suggestions" bug.
  Future<List<QuickConnectSuggestion>> getQuickConnectSuggestions(
      String currentUserId) async {
    final Map<String, QuickConnectSuggestion> suggestionsMap = {};
    final Set<String> excludedUserIds = {currentUserId};
    const int maxSuggestions = 5;

    List<String> friendIds = const [];

    // ── Phase 1: who to exclude — existing friends ────────────────────
    try {
      final friendsSnap = await _firestore
          .collection(_usersCollection)
          .doc(currentUserId)
          .collection('friends')
          .get();
      friendIds = friendsSnap.docs.map((d) => d.id).toList();
      excludedUserIds.addAll(friendIds);
    } catch (e) {
      print('QuickConnect: friend list lookup failed: $e');
    }

    // ── Phase 2: who to exclude — pending requests, both directions ───
    // Run both directions concurrently; they're independent.
    try {
      final results = await Future.wait([
        _firestore
            .collection(_requestsCollection)
            .where('fromUserId', isEqualTo: currentUserId)
            .where('status', isEqualTo: 'pending')
            .get(),
        _firestore
            .collection(_requestsCollection)
            .where('toUserId', isEqualTo: currentUserId)
            .where('status', isEqualTo: 'pending')
            .get(),
      ]);

      for (final d in results[0].docs) {
        final toId = d.data()['toUserId'] as String?;
        if (toId != null) excludedUserIds.add(toId);
      }
      for (final d in results[1].docs) {
        final fromId = d.data()['fromUserId'] as String?;
        if (fromId != null) excludedUserIds.add(fromId);
      }
    } catch (e) {
      print('QuickConnect: pending-request lookup failed: $e');
    }

    // ── Phase 3: mutual friends (2nd degree) ──────────────────────────
    // NOTE: this cannot succeed with the current security rules — reading
    // another user's friends subcollection as a list is denied by design,
    // since it would expose that user's social graph. It is kept, isolated
    // and best-effort, so the feature lights up automatically if the graph
    // is ever denormalised (e.g. a `mutualCount` field maintained by a
    // Cloud Function). It no longer takes the other phases down with it.
    if (friendIds.isNotEmpty) {
      try {
        final Map<String, List<String>> mutualFriendNamesMap = {};

        // Bounded fan-out, run concurrently instead of sequentially.
        final probeIds = friendIds.take(10).toList();
        final probes = await Future.wait(probeIds.map((friendId) async {
          final friendDoc = await _firestore
              .collection(_usersCollection)
              .doc(friendId)
              .get();
          if (!friendDoc.exists) return null;
          final subFriendsSnap = await _firestore
              .collection(_usersCollection)
              .doc(friendId)
              .collection('friends')
              .get();
          return (
            name: UserModel.fromFirestore(friendDoc).name,
            candidateIds: subFriendsSnap.docs.map((d) => d.id).toList(),
          );
        }));

        for (final probe in probes) {
          if (probe == null) continue;
          for (final candidateId in probe.candidateIds) {
            if (excludedUserIds.contains(candidateId)) continue;
            mutualFriendNamesMap
                .putIfAbsent(candidateId, () => [])
                .add(probe.name);
          }
        }

        // Resolve candidate profiles concurrently, capped.
        final candidateIds = mutualFriendNamesMap.keys
            .take(maxSuggestions)
            .toList();
        final candidateDocs = await Future.wait(candidateIds.map((id) =>
            _firestore.collection(_usersCollection).doc(id).get()));

        for (final candidateDoc in candidateDocs) {
          if (suggestionsMap.length >= maxSuggestions) break;
          if (!candidateDoc.exists) continue;

          final candidateUser = UserModel.fromFirestore(candidateDoc);
          if (!candidateUser.isDiscoverable) continue;

          final friendNames = mutualFriendNamesMap[candidateDoc.id] ?? const [];
          if (friendNames.isEmpty) continue;

          suggestionsMap[candidateDoc.id] = QuickConnectSuggestion(
            user: candidateUser,
            reasonSubtitle: friendNames.length == 1
                ? 'Mutual friend with ${friendNames.first}'
                : '${friendNames.length} mutual friends',
          );
        }
      } catch (e) {
        // Expected today (permission-denied on the 2nd-degree list read).
        print('QuickConnect: mutual-friends phase skipped: $e');
      }
    }

    // ── Phase 4: device contacts ──────────────────────────────────────
    // Checks the permission status instead of requesting it. The previous
    // code called FlutterContacts.requestPermission() here, which pops the
    // OS contacts dialog — unprompted, just from opening a tab that renders
    // a suggestions list. Contact access is offered explicitly via the
    // "Sync contacts" action; this phase only piggybacks on a grant the
    // user already gave.
    if (suggestionsMap.length < maxSuggestions) {
      try {
        final alreadyGranted = await ph.Permission.contacts.isGranted;
        if (alreadyGranted) {
          final deviceContacts =
              await fc.FlutterContacts.getContacts(withProperties: true);
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

          for (final matchedUser in matches) {
            if (suggestionsMap.length >= maxSuggestions) break;
            // matchDeviceContacts already drops non-discoverable users.
            if (excludedUserIds.contains(matchedUser.id) ||
                suggestionsMap.containsKey(matchedUser.id)) {
              continue;
            }
            suggestionsMap[matchedUser.id] = QuickConnectSuggestion(
              user: matchedUser,
              reasonSubtitle: 'From your phone contacts',
            );
          }
        }
      } catch (e) {
        print('QuickConnect: device-contact phase skipped: $e');
      }
    }

    // ── Phase 5: general fallback ─────────────────────────────────────
    // Over-fetches relative to the number of slots left because the
    // discoverability opt-out and the exclusion set are both applied
    // client-side; a bare limit(10) frequently yielded nothing once a few
    // users were filtered out.
    if (suggestionsMap.length < maxSuggestions) {
      try {
        final generalSnap = await _firestore
            .collection(_usersCollection)
            .where(FieldPath.documentId, isNotEqualTo: currentUserId)
            .limit(60)
            .get();

        for (final doc in generalSnap.docs) {
          if (suggestionsMap.length >= maxSuggestions) break;
          final u = UserModel.fromFirestore(doc);
          if (!u.isDiscoverable) continue;
          if (excludedUserIds.contains(u.id) ||
              suggestionsMap.containsKey(u.id)) {
            continue;
          }
          suggestionsMap[u.id] = QuickConnectSuggestion(
            user: u,
            reasonSubtitle: u.username != null && u.username!.isNotEmpty
                ? '@${u.username}'
                : 'Suggested for you',
          );
        }
      } catch (e) {
        print('QuickConnect: general fallback failed: $e');
      }
    }

    return suggestionsMap.values.toList();
  }
}
