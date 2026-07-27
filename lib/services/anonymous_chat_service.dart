import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_chat_app/models/anonymous_room_model.dart';
import 'package:video_chat_app/models/friend_request_model.dart';
import 'package:video_chat_app/services/chat_service.dart';

/// Singleton service handling anonymous chat matchmaking, messaging,
/// session lifecycle, and reporting.
class AnonymousChatService {
  static final AnonymousChatService instance = AnonymousChatService._();
  AnonymousChatService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _random = Random();

  // ── Alias generation ─────────────────────────────────────────────────
  static const _adjectives = [
    'Cosmic',
    'Purple',
    'Neon',
    'Crimson',
    'Golden',
    'Silver',
    'Mystic',
    'Shadow',
    'Crystal',
    'Electric',
    'Frozen',
    'Blazing',
    'Silent',
    'Swift',
    'Lucky',
    'Brave',
    'Gentle',
    'Wild',
    'Clever',
    'Noble',
    'Radiant',
    'Velvet',
    'Iron',
    'Emerald',
    'Sapphire',
    'Ruby',
    'Amber',
    'Ivory',
    'Midnight',
    'Lunar',
    'Solar',
    'Stellar',
    'Phantom',
    'Zen',
    'Turbo',
  ];

  static const _animals = [
    'Fox',
    'Penguin',
    'Owl',
    'Wolf',
    'Panda',
    'Tiger',
    'Eagle',
    'Dolphin',
    'Phoenix',
    'Dragon',
    'Falcon',
    'Panther',
    'Lynx',
    'Raven',
    'Cobra',
    'Hawk',
    'Bear',
    'Lion',
    'Otter',
    'Koala',
    'Jaguar',
    'Coyote',
    'Crane',
    'Viper',
    'Shark',
    'Bison',
    'Gecko',
    'Mantis',
    'Scorpion',
    'Sparrow',
  ];

  static const _emojis = [
    '🦊',
    '🐧',
    '🦉',
    '🐺',
    '🐼',
    '🐯',
    '🦅',
    '🐬',
    '🔥',
    '🐉',
    '🦅',
    '🐆',
    '🐱',
    '🐦‍⬛',
    '🐍',
    '🦜',
    '🐻',
    '🦁',
    '🦦',
    '🐨',
    '🐆',
    '🐺',
    '🕊️',
    '🐍',
    '🦈',
    '🦬',
    '🦎',
    '🦗',
    '🦂',
    '🐦',
  ];

  /// Returns a fun random pseudonym like "Cosmic Fox 🦊".
  String generateAlias() {
    final adj = _adjectives[_random.nextInt(_adjectives.length)];
    final animalIdx = _random.nextInt(_animals.length);
    final animal = _animals[animalIdx];
    final emoji = animalIdx < _emojis.length
        ? _emojis[animalIdx]
        : _emojis[_random.nextInt(_emojis.length)];
    return '$adj $animal $emoji';
  }

  // ── Matchmaking Queue ────────────────────────────────────────────────

  /// Adds the current user to the matchmaking queue.
  Future<void> joinQueue(String userId) async {
    await _firestore.collection('match_queue').doc(userId).set({
      'userId': userId,
      'status': 'waiting',
      'createdAt': FieldValue.serverTimestamp(),
      'matchedRoomId': null,
    });

    // Immediately try to find a partner
    await findAndPair(userId);
  }

  /// Removes the user from the matchmaking queue.
  Future<void> leaveQueue(String userId) async {
    await _firestore.collection('match_queue').doc(userId).delete();
  }

  /// Listens for changes to the user's queue entry — lobby screen uses
  /// this to detect when `matchedRoomId` appears.
  Stream<DocumentSnapshot> listenToQueueEntry(String userId) {
    return _firestore.collection('match_queue').doc(userId).snapshots();
  }

  /// Atomic transaction: finds a waiting user in the queue, pairs them
  /// with `userId`, creates an anonymous room, and updates both entries.
  Future<String?> findAndPair(String userId) async {
    try {
      // Query for waiting users — no orderBy to avoid needing a composite index.
      // Firestore auto-indexes single-field queries.
      final candidates = await _firestore
          .collection('match_queue')
          .where('status', isEqualTo: 'waiting')
          .limit(10)
          .get(const GetOptions(source: Source.server));

      print('[AnonymousChat] findAndPair: found ${candidates.docs.length} '
          'waiting candidates for $userId');

      // Filter out self
      final others = candidates.docs.where((d) => d.id != userId).toList();

      if (others.isEmpty) {
        print('[AnonymousChat] findAndPair: no available partners');
        return null;
      }

      final partner = others.first;
      final partnerId = partner.id;
      final roomId = _firestore.collection('anonymous_rooms').doc().id;
      final alias1 = generateAlias();
      final alias2 = generateAlias();

      print('[AnonymousChat] findAndPair: attempting to pair '
          '$userId with $partnerId → room $roomId');

      await _firestore.runTransaction((txn) async {
        // Re-read the partner's queue doc to verify they're still waiting
        final freshPartner =
            await txn.get(_firestore.collection('match_queue').doc(partnerId));
        if (!freshPartner.exists ||
            freshPartner.data()?['status'] != 'waiting') {
          throw Exception('Partner no longer available');
        }

        // Also verify ourselves — another device's retry might have
        // already matched us while this transaction was in-flight.
        final freshSelf =
            await txn.get(_firestore.collection('match_queue').doc(userId));
        if (!freshSelf.exists || freshSelf.data()?['status'] != 'waiting') {
          throw Exception('Already matched');
        }

        // Create the anonymous room
        txn.set(_firestore.collection('anonymous_rooms').doc(roomId), {
          'user1Id': userId,
          'user2Id': partnerId,
          'user1Alias': alias1,
          'user2Alias': alias2,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'endedAt': null,
          'endedBy': null,
          'friendRequestFrom': null,
          'friendRequestStatus': 'none',
          'e2eeChatRoomId': null,
        });

        // Update both queue entries
        txn.update(_firestore.collection('match_queue').doc(userId), {
          'status': 'matched',
          'matchedRoomId': roomId,
        });
        txn.update(_firestore.collection('match_queue').doc(partnerId), {
          'status': 'matched',
          'matchedRoomId': roomId,
        });
      });

      print('[AnonymousChat] findAndPair: ✅ paired successfully → $roomId');
      return roomId;
    } catch (e) {
      // Transaction failed — partner was taken, or query error.
      print('[AnonymousChat] findAndPair: ❌ failed: $e');
      return null;
    }
  }

  // ── Room Lifecycle ───────────────────────────────────────────────────

  /// Fetches a room document once.
  Future<AnonymousRoomModel?> getRoom(String roomId) async {
    final doc =
        await _firestore.collection('anonymous_rooms').doc(roomId).get();
    if (!doc.exists) return null;
    return AnonymousRoomModel.fromFirestore(doc);
  }

  /// Real-time stream of the room document — used to detect when the
  /// stranger disconnects or status changes.
  Stream<DocumentSnapshot> listenToRoom(String roomId) {
    return _firestore.collection('anonymous_rooms').doc(roomId).snapshots();
  }

  /// Ends the anonymous session. Sets room status to `ended`.
  Future<void> endSession(String roomId, String userId) async {
    await _firestore.collection('anonymous_rooms').doc(roomId).update({
      'status': 'ended',
      'endedBy': userId,
      'endedAt': FieldValue.serverTimestamp(),
    });
    // Clean up both users' queue entries
    // (fire-and-forget — not critical if they fail)
    try {
      final room = await getRoom(roomId);
      if (room != null) {
        await _firestore.collection('match_queue').doc(room.user1Id).delete();
        await _firestore.collection('match_queue').doc(room.user2Id).delete();
      }
    } catch (_) {}
  }

  // ── Messaging ────────────────────────────────────────────────────────

  /// Sends a text message in the anonymous room.
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String text,
  }) async {
    await _firestore
        .collection('anonymous_rooms')
        .doc(roomId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'text': text,
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
    });
  }

  /// Real-time stream of messages in the anonymous room, ordered by time.
  Stream<QuerySnapshot> messagesStream(String roomId) {
    return _firestore
        .collection('anonymous_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Inserts a centred "system" message (e.g. "You are now friends! 🎉").
  /// Uses the caller's real UID as senderId for Firestore rule compliance;
  /// the UI renders based on type:'system', not the senderId value.
  Future<void> _addSystemMessage(
    String roomId,
    String userId,
    String text,
  ) async {
    await _firestore
        .collection('anonymous_rooms')
        .doc(roomId)
        .collection('messages')
        .add({
      'senderId': userId,
      'text': text,
      'type': 'system',
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
    });
  }

  // ── Friend Request → E2EE transition ─────────────────────────────────

  /// Sends a friend request to the stranger. Marks the room's
  /// `friendRequestStatus` as `pending`, records who sent it, creates a
  /// `/friend_requests` doc, and drops a system message into the room so
  /// both users get real-time feedback.
  Future<void> sendFriendRequest({
    required String roomId,
    required String fromUserId,
    required String toUserId,
    required String fromAlias,
  }) async {
    // Create the friend_requests doc.
    await _firestore.collection('friend_requests').add({
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'anonymousRoomId': roomId,
      'fromAlias': fromAlias,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'respondedAt': null,
    });

    // Flag the room so both clients render the request UI.
    await _firestore.collection('anonymous_rooms').doc(roomId).update({
      'friendRequestFrom': fromUserId,
      'friendRequestStatus': 'pending',
    });

    // System message visible to both users.
    await _addSystemMessage(
      roomId,
      fromUserId,
      '🤝 $fromAlias wants to connect!',
    );
  }

  /// Streams the pending friend request addressed to [userId] for [roomId],
  /// if any. Emits null when there is none.
  Stream<FriendRequestModel?> pendingFriendRequestStream({
    required String roomId,
    required String userId,
  }) {
    return _firestore
        .collection('friend_requests')
        .where('anonymousRoomId', isEqualTo: roomId)
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty
            ? null
            : FriendRequestModel.fromFirestore(snap.docs.first));
  }

  /// Finds the pending friend request for a room addressed to [userId].
  ///
  /// The `toUserId` filter is REQUIRED — the `/friend_requests` security
  /// rules only permit queries constrained to docs the caller participates
  /// in. Without it Firestore rejects the read with permission-denied.
  Future<FriendRequestModel?> _findRequestForRoom(
    String roomId,
    String userId,
  ) async {
    final snap = await _firestore
        .collection('friend_requests')
        .where('anonymousRoomId', isEqualTo: roomId)
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return FriendRequestModel.fromFirestore(snap.docs.first);
  }

  /// Accepts a friend request. Called by the recipient (`toUserId`).
  ///
  /// 1. Marks the `/friend_requests` doc `accepted`.
  /// 2. Bootstraps a standard E2EE chat room via [ChatService].
  /// 3. Writes `e2eeChatRoomId` + `friendRequestStatus: accepted` on the
  ///    anonymous room and ends it — both clients navigate to [ChatScreen].
  /// 4. Drops a celebratory system message.
  ///
  /// Returns the newly-created E2EE `chatRoomId`.
  Future<String?> acceptFriendRequest({
    required String roomId,
    required String currentUserId,
    String? requestId,
  }) async {
    // Resolve the request (allow callers that only have the room id).
    FriendRequestModel? request;
    if (requestId != null) {
      final doc =
          await _firestore.collection('friend_requests').doc(requestId).get();
      if (doc.exists) request = FriendRequestModel.fromFirestore(doc);
    }
    // currentUserId is the recipient (toUserId) — required for the
    // security-rules-compliant query in _findRequestForRoom.
    request ??= await _findRequestForRoom(roomId, currentUserId);
    if (request == null) return null;

    final user1Id = request.fromUserId;
    final user2Id = request.toUserId;

    // 1. Mark the request accepted.
    await _firestore.collection('friend_requests').doc(request.id).update({
      'status': 'accepted',
      'respondedAt': FieldValue.serverTimestamp(),
    });

    // 2. Create the E2EE chat room (Signal session bootstraps lazily on the
    //    first message send inside ChatService.sendMessage).
    final chatRoomId = await _createE2EEChatRoom(user1Id, user2Id);

    // 3. Update the anonymous room and end it.
    await _firestore.collection('anonymous_rooms').doc(roomId).update({
      'friendRequestStatus': 'accepted',
      'e2eeChatRoomId': chatRoomId,
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
    });

    // 4. Celebratory system message.
    await _addSystemMessage(roomId, currentUserId, 'You are now friends! 🎉');

    // Clean up queue entries (fire-and-forget).
    try {
      await _firestore.collection('match_queue').doc(user1Id).delete();
      await _firestore.collection('match_queue').doc(user2Id).delete();
    } catch (_) {}

    return chatRoomId;
  }

  /// Declines a friend request. The anonymous chat continues as normal.
  Future<void> declineFriendRequest({
    required String roomId,
    required String currentUserId,
    String? requestId,
  }) async {
    FriendRequestModel? request;
    if (requestId != null) {
      final doc =
          await _firestore.collection('friend_requests').doc(requestId).get();
      if (doc.exists) request = FriendRequestModel.fromFirestore(doc);
    }
    request ??= await _findRequestForRoom(roomId, currentUserId);
    if (request == null) return;

    await _firestore.collection('friend_requests').doc(request.id).update({
      'status': 'declined',
      'respondedAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('anonymous_rooms').doc(roomId).update({
      'friendRequestStatus': 'declined',
      'friendRequestFrom': null,
    });

    await _addSystemMessage(roomId, currentUserId, 'Friend request declined.');
  }

  /// Private helper — creates a standard E2EE chat room in `/chatRooms`
  /// using the existing [ChatService]. Signal Protocol sessions are
  /// established automatically on the first message send.
  Future<String> _createE2EEChatRoom(String user1Id, String user2Id) async {
    final room = await ChatService.instance.getOrCreateChatRoom(
      user1Id,
      user2Id,
    );
    return room.id;
  }

  // ── Reporting ────────────────────────────────────────────────────────

  /// Reports a user for inappropriate behavior, then ends the session.
  Future<void> reportUser({
    required String roomId,
    required String reporterId,
    required String reportedId,
    required String reason,
  }) async {
    await _firestore.collection('anonymous_reports').add({
      'reporterUserId': reporterId,
      'reportedUserId': reportedId,
      'roomId': roomId,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
      'resolved': false,
    });
    await endSession(roomId, reporterId);
  }
}
