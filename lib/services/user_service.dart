import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_chat_app/models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';

  // Create or update user
  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      await _firestore.collection(_usersCollection).doc(user.id).set(
            user.toMap(),
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

  // Search users by name or phone
  Future<List<UserModel>> searchUsers(String query, String currentUserId) async {
    try {
      // Convert query to lowercase for case-insensitive search
      String lowerQuery = query.toLowerCase();

      QuerySnapshot snapshot = await _firestore
          .collection(_usersCollection)
          .where(FieldPath.documentId, isNotEqualTo: currentUserId)
          .get();

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
      await _firestore.collection(_usersCollection).doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
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

  // Setup presence system (call when app opens)
  Future<void> setupPresence(String userId) async {
    try {
      // Set user as online
      await updateOnlineStatus(userId, true);

      // Setup onDisconnect to set user offline when app closes
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error setting up presence: $e');
    }
  }
}
