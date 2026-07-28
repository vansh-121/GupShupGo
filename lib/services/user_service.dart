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

  // Get all users except current user
  Stream<List<UserModel>> getAllUsers(String currentUserId) {
    return _firestore
        .collection(_usersCollection)
        .where(FieldPath.documentId, isNotEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    });
  }

  // Search users by name or phone — paginated to prevent unbounded reads.
  // Uses no server-side search (Firestore doesn't natively support
  // full-text search), but limits to 50 results per page to cap cost
  // and client-side work. For production scale, consider Algolia/Typesense.
  Future<List<UserModel>> searchUsers(
    String query,
    String currentUserId, {
    DocumentSnapshot? startAfterDoc,
    int limit = 30,
  }) async {
    try {
      String lowerQuery = query.toLowerCase();

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
          .where((user) =>
              user.name.toLowerCase().contains(lowerQuery) ||
              (user.phoneNumber?.contains(query) ?? false))
          .toList();

      return users;
    } catch (e) {
      print('Error searching users: $e');
      return [];
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

  // Check if a username is available (unique) across all users.
  Future<bool> isUsernameAvailable(String username, {String? currentUserId}) async {
    try {
      String cleanUsername = username.trim().toLowerCase();
      if (cleanUsername.length < 3 || cleanUsername.length > 20) return false;
      
      QuerySnapshot snapshot = await _firestore
          .collection(_usersCollection)
          .where('username_lowercase', isEqualTo: cleanUsername)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return true;
      }
      
      // If the only doc found belongs to the current user, it is available for them
      if (currentUserId != null && snapshot.docs.first.id == currentUserId) {
        return true;
      }

      return false;
    } catch (e) {
      print('Error checking username availability: $e');
      return false;
    }
  }

  // Update user's username
  Future<void> updateUsername(String userId, String username) async {
    try {
      String cleanUsername = username.trim().toLowerCase();
      await _firestore.collection(_usersCollection).doc(userId).update({
        'username': username.trim(),
        'username_lowercase': cleanUsername,
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

  // Universal Multi-field Search (Name, @username, Phone Number, Email)
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
