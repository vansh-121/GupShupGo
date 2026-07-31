import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/services/presence_service.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';

  // Create or update user
  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      await _firestore.collection(_usersCollection).doc(user.id).set(
            user.toWritableMap(),
            SetOptions(merge: true),
          );
      print('User created/updated: ${user.id}');
    } catch (e) {
      print('Error creating/updating user: $e');
      rethrow;
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_usersCollection).doc(userId).get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Get all users except current user.
  // Capped with a defensive limit — this stream backs both the recent-
  // contacts row on Home and the "Suggested Users" list on Discover,
  // neither of which need (or display) more than a couple hundred users.
  // Without this, the read cost and client-side work scale linearly with
  // total registered users.
  // Opt-out filtering is applied client-side rather than as a Firestore
  // `where` clause on purpose: profiles created before the discoverability
  // feature shipped have no `isDiscoverable` field at all, and a server-side
  // equality/inequality filter would silently exclude every one of them.
  // UserModel defaults the field to `true`, so filtering after decode keeps
  // legacy users visible. The trade-off is that hidden users still occupy
  // slots in [limit]; that is acceptable here because callers display at most
  // a handful of entries out of the 200 fetched.
  //
  // NOTE: this hides opted-out users from *this app's* UI. It is not a read
  // restriction — /users is readable by any authenticated client per
  // firestore.rules. Treat it as "don't surface me", not as access control.
  Stream<List<UserModel>> getAllUsers(String currentUserId, {int limit = 200}) {
    return _firestore
        .collection(_usersCollection)
        .where(FieldPath.documentId, isNotEqualTo: currentUserId)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) => user.isDiscoverable)
          .toList();
    });
  }

  /// Update profile discoverability status in Firestore.
  ///
  /// Deliberately rethrows: this is a privacy control, so a failed write must
  /// surface to the caller (which reverts its optimistic UI) rather than
  /// leaving the user believing they are hidden when they are not.
  Future<void> updateDiscoverableStatus(String userId, bool isDiscoverable) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({'isDiscoverable': isDiscoverable});
    } catch (e) {
      print('Error updating discoverable status: $e');
      rethrow;
    }
  }

  // Update user online status
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      // Always write lastSeen so that stale-detection works for all users.
      // Privacy (whether to *display* the timestamp to others) is enforced
      // at the UI layer, not here.
      await _firestore.collection(_usersCollection).doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
      print('Online status updated for $userId: $isOnline');
    } catch (e) {
      print('Error updating online status: $e');
    }
  }

  // Update FCM token
  Future<void> updateFCMToken(String userId, String fcmToken) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'fcmToken': fcmToken,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print('FCM token updated for $userId');
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  // Get online users
  Stream<List<UserModel>> getOnlineUsers(String currentUserId) {
    return _firestore
        .collection(_usersCollection)
        .where(FieldPath.documentId, isNotEqualTo: currentUserId)
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Returns a real-time stream of a single user's profile (including
  /// online status). Use this to keep UI in sync without manual refreshes.
  ///
  /// Includes stale-detection: if `isOnline` is true but `lastSeen` is
  /// older than [PresenceService.staleThreshold], the user is treated as
  /// offline. This guards against edge cases where the RTDB onDisconnect
  /// handler is delayed.
  Stream<UserModel?> getUserStream(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        final user = UserModel.fromFirestore(doc);
        // Stale-detection: override isOnline if lastSeen is too old.
        if (user.isOnline &&
            !PresenceService.isRecentlyActive(user.lastSeen)) {
          return user.copyWith(isOnline: false);
        }
        return user;
      }
      return null;
    });
  }

  // Check if user exists by phone number
  Future<UserModel?> getUserByPhone(String phoneNumber) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_usersCollection)
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return UserModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting user by phone: $e');
      return null;
    }
  }

  final String _usernamesCollection = 'usernames';

  // Check if a username is available (unique) across all users.
  //
  // Backed by the /usernames/{handle} reservation collection rather than
  // a query over /users — the reservation doc ID *is* the handle, so
  // existence is a point-lookup and (combined with the security rule that
  // forbids overwriting someone else's reservation) gives us a real
  // uniqueness guarantee instead of a racy check-then-write over a query.
  Future<bool> isUsernameAvailable(String username, {String? currentUserId}) async {
    try {
      String cleanUsername = username.trim().toLowerCase();
      if (cleanUsername.length < 3 || cleanUsername.length > 20) return false;

      final doc = await _firestore
          .collection(_usernamesCollection)
          .doc(cleanUsername)
          .get();

      if (!doc.exists) return true;

      // Already reserved by the current user (e.g. re-checking their own
      // existing handle) — treat as available for them.
      final owner = doc.data()?['uid'] as String?;
      return currentUserId != null && owner == currentUserId;
    } catch (e) {
      print('Error checking username availability: $e');
      return false;
    }
  }

  // Update user's username. Atomically claims the new handle in
  // /usernames/{handle} and releases the previous handle (if any) so two
  // users can never simultaneously "win" the same handle — Firestore
  // transactions abort and retry on conflicting concurrent writes, and the
  // create() on the handle doc is itself guarded by a security rule that
  // rejects overwriting an existing reservation.
  Future<void> updateUsername(String userId, String username) async {
    final cleanUsername = username.trim().toLowerCase();
    if (cleanUsername.length < 3 || cleanUsername.length > 20) {
      throw Exception('Username must be between 3 and 20 characters.');
    }

    final userRef = _firestore.collection(_usersCollection).doc(userId);
    final newHandleRef =
        _firestore.collection(_usernamesCollection).doc(cleanUsername);

    try {
      await _firestore.runTransaction((tx) async {
        final userSnap = await tx.get(userRef);
        final existingHandle =
            (userSnap.data()?['username_lowercase'] as String?)?.trim();

        if (existingHandle == cleanUsername) {
          // No-op: re-saving the same handle. Still touch the display-case
          // username field in case only capitalization changed.
          tx.update(userRef, {'username': username.trim()});
          return;
        }

        final newHandleSnap = await tx.get(newHandleRef);
        if (newHandleSnap.exists) {
          final owner = newHandleSnap.data()?['uid'] as String?;
          if (owner != userId) {
            throw Exception('@$cleanUsername is already taken.');
          }
        }

        if (existingHandle != null && existingHandle.isNotEmpty) {
          final oldHandleRef =
              _firestore.collection(_usernamesCollection).doc(existingHandle);
          tx.delete(oldHandleRef);
        }

        tx.set(newHandleRef, {
          'uid': userId,
          'claimedAt': FieldValue.serverTimestamp(),
        });

        tx.update(userRef, {
          'username': username.trim(),
          'username_lowercase': cleanUsername,
        });
      });
      print('Username updated for $userId to @$cleanUsername');
    } catch (e) {
      print('Error updating username: $e');
      rethrow;
    }
  }

  // Get user by unique @username
  Future<UserModel?> getUserByUsername(String username) async {
    try {
      String cleanUsername = username.trim().toLowerCase();
      QuerySnapshot snapshot = await _firestore
          .collection(_usersCollection)
          .where('username_lowercase', isEqualTo: cleanUsername)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return UserModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting user by username: $e');
      return null;
    }
  }

  // Universal Multi-field Search (Name, @username, Phone Number, Email).
  //
  // Firestore has no native full-text search, so matching happens client-side
  // over a capped page of documents — [limit] bounds both read cost and the
  // work done here. For production scale, move this to Algolia/Typesense and
  // mirror `isDiscoverable` into the index so opt-outs are honoured
  // server-side.
  Future<List<UserModel>> searchUsersMultiField(
    String query,
    String currentUserId, {
    DocumentSnapshot? startAfterDoc,
    int limit = 30,
  }) async {
    try {
      String cleanQuery = query.trim().toLowerCase();
      if (cleanQuery.isEmpty) return [];

      // If query starts with '@', strip it for username search
      String handleQuery = cleanQuery.startsWith('@') ? cleanQuery.substring(1) : cleanQuery;

      Query q = _firestore
          .collection(_usersCollection)
          .where(FieldPath.documentId, isNotEqualTo: currentUserId)
          .limit(limit);

      if (startAfterDoc != null) {
        q = q.startAfterDocument(startAfterDoc);
      }

      QuerySnapshot snapshot = await q.get();

      List<UserModel> users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) {
            // Respect the user's discoverability opt-out before matching.
            if (!user.isDiscoverable) return false;

            bool matchName = user.name.toLowerCase().contains(cleanQuery);
            bool matchUsername = user.username != null &&
                user.username!.toLowerCase().contains(handleQuery);
            bool matchPhone = user.phoneNumber != null &&
                user.phoneNumber!.contains(cleanQuery);
            bool matchEmail = user.email != null &&
                user.email!.toLowerCase().contains(cleanQuery);

            return matchName || matchUsername || matchPhone || matchEmail;
          })
          .toList();

      return users;
    } catch (e) {
      print('Error performing multi-field search: $e');
      return [];
    }
  }

  // Match device phone contacts and emails against Firestore registered accounts
  Future<List<UserModel>> matchDeviceContacts({
    required List<String> rawPhoneNumbers,
    required List<String> rawEmails,
    required String currentUserId,
  }) async {
    try {
      Set<String> cleanPhones = rawPhoneNumbers
          .map((p) => p.replaceAll(RegExp(r'[^\d+]'), ''))
          .where((p) => p.isNotEmpty)
          .toSet();

      Set<String> cleanEmails = rawEmails
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toSet();

      if (cleanPhones.isEmpty && cleanEmails.isEmpty) return [];

      QuerySnapshot snapshot = await _firestore
          .collection(_usersCollection)
          .where(FieldPath.documentId, isNotEqualTo: currentUserId)
          .get();

      List<UserModel> matchedUsers = [];

      for (var doc in snapshot.docs) {
        UserModel user = UserModel.fromFirestore(doc);

        // Enforced here (rather than at each call site) so contact sync and
        // the suggestion engine can't drift apart on this policy.
        if (!user.isDiscoverable) continue;

        bool phoneMatch = user.phoneNumber != null &&
            cleanPhones.any((p) =>
                user.phoneNumber!.replaceAll(RegExp(r'[^\d+]'), '').contains(p) ||
                p.contains(user.phoneNumber!.replaceAll(RegExp(r'[^\d+]'), '')));
                
        bool emailMatch = user.email != null &&
            cleanEmails.contains(user.email!.toLowerCase());

        if (phoneMatch || emailMatch) {
          matchedUsers.add(user);
        }
      }

      return matchedUsers;
    } catch (e) {
      print('Error matching device contacts: $e');
      return [];
    }
  }

  // Setup presence system (call when app opens).
  // Delegates to PresenceService which uses RTDB onDisconnect for reliable
  // server-side offline detection.
  Future<void> setupPresence(String userId) async {
    try {
      await PresenceService.instance.setupPresence(userId);
    } catch (e) {
      print('Error setting up presence: $e');
    }
  }
}
