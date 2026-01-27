import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/services/user_service.dart';
import 'package:video_chat_app/services/fcm_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final FCMService _fcmService = FCMService();

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Sign in anonymously (for testing)
  Future<UserModel?> signInAnonymously(String displayName) async {
    try {
      print('Starting anonymous sign in...');
      
      // Sign in to Firebase Auth
      UserCredential userCredential = await _auth.signInAnonymously();
      
      if (userCredential.user == null) {
        print('Error: User credential is null');
        return null;
      }
      
      String userId = userCredential.user!.uid;
      print('Signed in with user ID: $userId');

      // Create user profile in Firestore
      UserModel user = UserModel(
        id: userId,
        name: displayName,
        isOnline: true,
        createdAt: DateTime.now(),
      );

      print('Creating user in Firestore...');
      await _userService.createOrUpdateUser(user);
      
      print('Saving user ID locally...');
      await _saveUserIdLocally(userId);
      
      print('Setting up FCM...');
      try {
        await _fcmService.setupFCM(userId: userId);
      } catch (e) {
        print('FCM setup failed (non-critical): $e');
      }
      
      print('Setting up presence...');
      await _userService.setupPresence(userId);
      
      print('Anonymous sign in complete!');
      return user;
    } catch (e, stackTrace) {
      print('Error signing in anonymously: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  // Sign in with phone number (Step 1: Send verification code)
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Auto retrieval timeout');
        },
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  // Sign in with phone number (Step 2: Verify OTP)
  Future<UserModel?> signInWithPhoneOTP({
    required String verificationId,
    required String otp,
    required String name,
    String? photoUrl,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      String userId = userCredential.user!.uid;
      String? phoneNumber = userCredential.user!.phoneNumber;

      // Check if user already exists
      UserModel? existingUser = await _userService.getUserById(userId);

      UserModel user;
      if (existingUser != null) {
        // Update existing user
        user = existingUser.copyWith(
          isOnline: true,
          lastSeen: DateTime.now(),
        );
      } else {
        // Create new user
        user = UserModel(
          id: userId,
          name: name,
          phoneNumber: phoneNumber,
          photoUrl: photoUrl,
          isOnline: true,
          createdAt: DateTime.now(),
        );
      }

      await _userService.createOrUpdateUser(user);
      await _saveUserIdLocally(userId);
      await _fcmService.setupFCM(userId: userId);
      await _userService.setupPresence(userId);

      return user;
    } catch (e) {
      print('Error verifying OTP: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      String? userId = await _getSavedUserId();
      if (userId != null) {
        await _userService.updateOnlineStatus(userId, false);
      }
      await _auth.signOut();
      await _clearUserIdLocally();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    User? user = getCurrentUser();
    String? savedUserId = await _getSavedUserId();
    return user != null && savedUserId != null;
  }

  // Get saved user from local storage
  Future<UserModel?> getSavedUser() async {
    try {
      String? userId = await _getSavedUserId();
      if (userId != null) {
        return await _userService.getUserById(userId);
      }
      return null;
    } catch (e) {
      print('Error getting saved user: $e');
      return null;
    }
  }

  // Save user ID locally
  Future<void> _saveUserIdLocally(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  // Get saved user ID
  Future<String?> _getSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  // Clear user ID locally
  Future<void> _clearUserIdLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? photoUrl,
  }) async {
    try {
      UserModel? user = await _userService.getUserById(userId);
      if (user != null) {
        UserModel updatedUser = user.copyWith(
          name: name ?? user.name,
          photoUrl: photoUrl ?? user.photoUrl,
        );
        await _userService.createOrUpdateUser(updatedUser);
      }
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }
}
