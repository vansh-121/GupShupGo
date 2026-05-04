import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:video_chat_app/main.dart'; // for sharedPrefs global
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/services/user_service.dart';
import 'package:video_chat_app/services/device_session_service.dart';
import 'package:video_chat_app/services/fcm_service.dart';
import 'package:video_chat_app/services/phone_verification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final FCMService _fcmService = FCMService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DeviceSessionService _deviceSession = DeviceSessionService();

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
      await _saveUserLocally(user);
      // Issue a "remember this device" token now that we hold a fresh
      // Firebase ID token. On future cold starts where Firebase Auth's
      // own session has been wiped (Redmi/MIUI force-stop), this token
      // is exchanged for a Firebase custom token in attemptSilentReauth().
      await _deviceSession.issueAndPersist();

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

      // If user is already signed in (email/Google session), link phone to
      // that account so both providers share the same UID.
      final User? currentUser = _auth.currentUser;
      UserCredential userCredential;
      if (currentUser != null && currentUser.phoneNumber == null) {
        try {
          userCredential = await currentUser.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' ||
              e.code == 'account-exists-with-different-credential') {
            // Phone already tied to its own account – sign into that one.
            userCredential = await _auth.signInWithCredential(credential);
          } else {
            rethrow;
          }
        }
      } else {
        userCredential = await _auth.signInWithCredential(credential);
      }
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
      await _saveUserLocally(user);
      // Issue a "remember this device" token now that we hold a fresh
      // Firebase ID token. On future cold starts where Firebase Auth's
      // own session has been wiped (Redmi/MIUI force-stop), this token
      // is exchanged for a Firebase custom token in attemptSilentReauth().
      await _deviceSession.issueAndPersist();
      await _fcmService.setupFCM(userId: userId);
      await _userService.setupPresence(userId);

      return user;
    } catch (e) {
      print('Error verifying OTP: $e');
      return null;
    }
  }

  // Sign in with carrier-verified phone number (Firebase Phone Number Verification)
  // This uses the new carrier-based verification — no SMS OTP needed.
  final PhoneVerificationService _phoneVerificationService =
      PhoneVerificationService();

  /// Step 1: Request phone number from system (carrier-based verification).
  /// Returns the verified phone number string.
  Future<String> requestCarrierVerification() async {
    return await _phoneVerificationService.requestPhoneNumberHint();
  }

  /// Step 2: Sign in using the carrier-verified phone number.
  /// Uses Firebase Auth's phone flow internally, but auto-completes via carrier.
  Future<UserModel?> signInWithVerifiedPhone({
    required String verifiedPhoneNumber,
    required String name,
    String? photoUrl,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function(UserModel user) onAutoVerified,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: verifiedPhoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed (carrier/SMS auto-read)
          try {
            final User? currentUser = _auth.currentUser;
            UserCredential userCredential;
            if (currentUser != null && currentUser.phoneNumber == null) {
              try {
                userCredential =
                    await currentUser.linkWithCredential(credential);
              } on FirebaseAuthException catch (e) {
                if (e.code == 'credential-already-in-use' ||
                    e.code == 'account-exists-with-different-credential') {
                  userCredential = await _auth.signInWithCredential(credential);
                } else {
                  rethrow;
                }
              }
            } else {
              userCredential = await _auth.signInWithCredential(credential);
            }
            String userId = userCredential.user!.uid;

            UserModel? existingUser = await _userService.getUserById(userId);

            UserModel user;
            if (existingUser != null) {
              user = existingUser.copyWith(
                isOnline: true,
                lastSeen: DateTime.now(),
              );
            } else {
              user = UserModel(
                id: userId,
                name: name,
                phoneNumber: verifiedPhoneNumber,
                photoUrl: photoUrl,
                isOnline: true,
                createdAt: DateTime.now(),
              );
            }

            await _userService.createOrUpdateUser(user);
            await _saveUserIdLocally(userId);
            await _saveUserLocally(user);
            // See note in other sign-in paths — issue device session token
            // so this user stays signed in across MIUI force-stops, etc.
            await _deviceSession.issueAndPersist();
            await _fcmService.setupFCM(userId: userId);
            await _userService.setupPresence(userId);

            onAutoVerified(user);
          } catch (e) {
            onError('Auto-verification sign-in failed: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Phone verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          // Fallback: if carrier verification doesn't auto-complete,
          // an SMS OTP is sent. Pass the verificationId to the UI.
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Auto retrieval timeout for carrier verification');
        },
      );
    } catch (e) {
      onError(e.toString());
    }
    return null;
  }

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // If user is already signed in (phone session), link Google to that
      // account so both providers share the same UID.
      final User? currentUser = _auth.currentUser;
      UserCredential userCredential;
      if (currentUser != null &&
          !currentUser.providerData
              .any((p) => p.providerId == GoogleAuthProvider.PROVIDER_ID)) {
        try {
          userCredential = await currentUser.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' ||
              e.code == 'account-exists-with-different-credential') {
            userCredential = await _auth.signInWithCredential(credential);
          } else {
            rethrow;
          }
        }
      } else {
        userCredential = await _auth.signInWithCredential(credential);
      }

      if (userCredential.user == null) return null;

      final String userId = userCredential.user!.uid;
      UserModel? existingUser = await _userService.getUserById(userId);

      UserModel user;
      if (existingUser != null) {
        user = existingUser.copyWith(
          isOnline: true,
          lastSeen: DateTime.now(),
        );
      } else {
        user = UserModel(
          id: userId,
          name: userCredential.user!.displayName ??
              googleUser.displayName ??
              'User',
          email: userCredential.user!.email ?? googleUser.email,
          photoUrl: userCredential.user!.photoURL ?? googleUser.photoUrl,
          isOnline: true,
          createdAt: DateTime.now(),
        );
      }

      await _userService.createOrUpdateUser(user);
      await _saveUserIdLocally(userId);
      await _saveUserLocally(user);
      // Issue a "remember this device" token now that we hold a fresh
      // Firebase ID token. On future cold starts where Firebase Auth's
      // own session has been wiped (Redmi/MIUI force-stop), this token
      // is exchanged for a Firebase custom token in attemptSilentReauth().
      await _deviceSession.issueAndPersist();
      try {
        await _fcmService.setupFCM(userId: userId);
      } catch (e) {
        print('FCM setup failed (non-critical): $e');
      }
      await _userService.setupPresence(userId);

      return user;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Sign up with email and password
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String? photoUrl,
  }) async {
    try {
      print('Starting email sign up...');

      // If user is already signed in (phone session), link email to that
      // account so both providers share the same UID.
      final User? currentUser = _auth.currentUser;
      UserCredential userCredential;
      if (currentUser != null && currentUser.email == null) {
        final emailCredential =
            EmailAuthProvider.credential(email: email, password: password);
        try {
          userCredential =
              await currentUser.linkWithCredential(emailCredential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use' ||
              e.code == 'credential-already-in-use') {
            // Email already has its own account – sign into it.
            userCredential = await _auth.signInWithEmailAndPassword(
                email: email, password: password);
          } else {
            rethrow;
          }
        }
      } else {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      if (userCredential.user == null) {
        print('Error: User credential is null');
        return null;
      }

      String userId = userCredential.user!.uid;
      print('Signed up with user ID: $userId');

      // Create user profile in Firestore
      UserModel user = UserModel(
        id: userId,
        name: name,
        email: email,
        photoUrl: photoUrl,
        isOnline: true,
        createdAt: DateTime.now(),
      );

      print('Creating user in Firestore...');
      await _userService.createOrUpdateUser(user);

      print('Saving user ID locally...');
      await _saveUserIdLocally(userId);
      await _saveUserLocally(user);
      // Issue a "remember this device" token now that we hold a fresh
      // Firebase ID token. On future cold starts where Firebase Auth's
      // own session has been wiped (Redmi/MIUI force-stop), this token
      // is exchanged for a Firebase custom token in attemptSilentReauth().
      await _deviceSession.issueAndPersist();

      print('Setting up FCM...');
      try {
        await _fcmService.setupFCM(userId: userId);
      } catch (e) {
        print('FCM setup failed (non-critical): $e');
      }

      print('Setting up presence...');
      await _userService.setupPresence(userId);

      print('Email sign up complete!');
      return user;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      print('Error signing up with email: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('Starting email sign in...');

      // If user is already signed in (phone session), attempt to link this
      // email credential to that account before falling back to a normal sign-in.
      final User? currentUser = _auth.currentUser;
      UserCredential userCredential;
      if (currentUser != null && currentUser.email == null) {
        final emailCredential =
            EmailAuthProvider.credential(email: email, password: password);
        try {
          userCredential =
              await currentUser.linkWithCredential(emailCredential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use' ||
              e.code == 'credential-already-in-use') {
            userCredential = await _auth.signInWithEmailAndPassword(
                email: email, password: password);
          } else {
            rethrow;
          }
        }
      } else {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      if (userCredential.user == null) {
        print('Error: User credential is null');
        return null;
      }

      String userId = userCredential.user!.uid;
      print('Signed in with user ID: $userId');

      // Check if user exists in Firestore
      UserModel? existingUser = await _userService.getUserById(userId);

      UserModel user;
      if (existingUser != null) {
        // Update existing user status
        user = existingUser.copyWith(
          isOnline: true,
          lastSeen: DateTime.now(),
        );
      } else {
        // Create user profile if it doesn't exist
        user = UserModel(
          id: userId,
          name: userCredential.user!.displayName ?? 'User',
          email: email,
          isOnline: true,
          createdAt: DateTime.now(),
        );
      }

      await _userService.createOrUpdateUser(user);

      print('Saving user ID locally...');
      await _saveUserIdLocally(userId);
      await _saveUserLocally(user);
      // Issue a "remember this device" token now that we hold a fresh
      // Firebase ID token. On future cold starts where Firebase Auth's
      // own session has been wiped (Redmi/MIUI force-stop), this token
      // is exchanged for a Firebase custom token in attemptSilentReauth().
      await _deviceSession.issueAndPersist();

      print('Setting up FCM...');
      try {
        await _fcmService.setupFCM(userId: userId);
      } catch (e) {
        print('FCM setup failed (non-critical): $e');
      }

      print('Setting up presence...');
      await _userService.setupPresence(userId);

      print('Email sign in complete!');
      return user;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      print('Error signing in with email: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ─── Account Linking (called while phone session is already active) ─────────

  // Link a Google account to the currently signed-in user (phone).
  // NEVER falls back to a regular sign-in — throws on conflict.
  Future<UserModel?> linkGoogleProvider() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('No active session to link to.');

    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // user cancelled

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // This will throw FirebaseAuthException (credential-already-in-use)
    // if this Google account already belongs to a separate Firebase Auth user.
    // Let the UI handle that error — we never silently create a second account.
    final UserCredential userCredential =
        await currentUser.linkWithCredential(credential);

    final String userId = userCredential.user!.uid;
    UserModel? existingUser = await _userService.getUserById(userId);
    UserModel user;
    if (existingUser != null) {
      user = existingUser.copyWith(
        email: userCredential.user!.email ?? existingUser.email,
        photoUrl: userCredential.user!.photoURL ?? existingUser.photoUrl,
      );
    } else {
      user = UserModel(
        id: userId,
        name: userCredential.user!.displayName ?? 'User',
        email: userCredential.user!.email,
        photoUrl: userCredential.user!.photoURL,
        isOnline: true,
        createdAt: DateTime.now(),
      );
    }
    await _userService.createOrUpdateUser(user);
    return user;
  }

  // Link an email/password to the currently signed-in user (phone).
  // NEVER falls back to createUserWithEmailAndPassword — throws on conflict.
  Future<UserModel?> linkEmailProvider({
    required String email,
    required String password,
  }) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('No active session to link to.');

    final AuthCredential emailCredential =
        EmailAuthProvider.credential(email: email, password: password);

    final UserCredential userCredential =
        await currentUser.linkWithCredential(emailCredential);

    final String userId = userCredential.user!.uid;
    UserModel? existingUser = await _userService.getUserById(userId);
    UserModel user;
    if (existingUser != null) {
      user = existingUser.copyWith(email: email);
    } else {
      user = UserModel(
        id: userId,
        name: userCredential.user!.displayName ??
            currentUser.displayName ??
            'User',
        email: email,
        isOnline: true,
        createdAt: DateTime.now(),
      );
    }
    await _userService.createOrUpdateUser(user);
    return user;
  }

  // Get list of currently linked provider IDs (e.g. 'phone', 'google.com', 'password')
  List<String> getLinkedProviders() {
    return _auth.currentUser?.providerData.map((p) => p.providerId).toList() ??
        [];
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Password reset email sent to $email');
    } catch (e) {
      print('Error sending password reset email: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      String? userId = await _getSavedUserId();
      if (userId != null) {
        await _userService.updateOnlineStatus(userId, false);
      }
      // Revoke the server-side device session token BEFORE signing out of
      // Firebase Auth — revocation can use the still-valid ID token to prove
      // the request is from the legitimate user. revokeAndClear() always
      // clears local state, even if the network call fails.
      await _deviceSession.revokeAndClear();
      await _googleSignIn.signOut();
      await _auth.signOut();
      await _clearUserIdLocally();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  /// Returns true iff Firebase Auth currently has a hydrated user. Different
  /// from [isUserLoggedIn], which only checks the local cache. Used by UI to
  /// decide whether an empty Firestore stream result is real ("no chats")
  /// vs. a side-effect of a missing Firebase session ("queries denied").
  bool get hasFirebaseSession => _auth.currentUser != null;

  /// Attempts to silently restore a Firebase Auth session without any UI.
  ///
  /// Use case: SharedPreferences says we're logged in but [hasFirebaseSession]
  /// is false (typical on MIUI/HyperOS Redmi devices that wipe Firebase Auth's
  /// internal store on aggressive force-stop). For users who originally signed
  /// in with Google we can re-issue a Firebase credential entirely in the
  /// background. For phone-auth users this is impossible without an OTP and
  /// the call returns false — the caller should then surface a "Tap to verify"
  /// affordance.
  ///
  /// Returns true iff [_auth.currentUser] is non-null after the attempt.
  Future<bool> attemptSilentReauth() async {
    if (_auth.currentUser != null) return true;
    final savedUserId = _getSavedUserId();
    if (savedUserId == null) return false;

    // ── Path A: device session token (works for ALL sign-in methods) ──────
    // If we hold a token issued the last time this device signed in, trade
    // it for a Firebase custom token. This is uid-bound on the server, so
    // there's no way for it to log us in as the wrong user.
    try {
      final restoredUid = await _deviceSession.exchangeAndSignIn();
      if (restoredUid != null) {
        if (restoredUid == savedUserId) return true;
        // Server returned a uid that doesn't match local prefs. Shouldn't
        // happen in practice (we only stored a token for the user whose
        // uid is in prefs), but be defensive — sign out and fall through.
        await _auth.signOut();
      }
    } catch (e) {
      print('Device session exchange failed (will try Google fallback): $e');
    }

    // ── Path B: Google silent sign-in (legacy fallback) ──────────────────
    // For users who installed an older build that didn't issue a device
    // session token, this still recovers Google accounts. Phone-only users
    // who never had a token will simply get false here, which lets the
    // re-verify banner take over.
    try {
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signInSilently();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final restoredUid = userCredential.user?.uid;

      // Same uid-match guard as before: if the device's default Google
      // account is a different identity than the cached user_id, undo.
      if (restoredUid == null || restoredUid != savedUserId) {
        await _googleSignIn.signOut();
        await _auth.signOut();
        return false;
      }

      // Opportunistically upgrade this user to the device-session-token
      // path so subsequent cold starts don't even need Google round-trips.
      await _deviceSession.issueAndPersist();

      return true;
    } catch (e) {
      print('Silent re-auth failed: $e');
      return false;
    }
  }

  // Check if user is logged in (synchronous — uses cached SharedPreferences).
  //
  // IMPORTANT: We trust SharedPreferences as the sole source of truth here.
  // Firebase Auth restores its persisted user from disk *asynchronously* after
  // Firebase.initializeApp() returns; on slower devices (notably MIUI / HyperOS
  // Redmi handsets) that disk read can lose the race against the first build()
  // pass, making `_auth.currentUser` falsely null on cold start and bouncing
  // the user back to the login screen even though they are signed in.
  //
  // A genuinely-revoked session is handled separately by listenForAuthInvalidation()
  // — that fires only after Firebase has had a chance to rehydrate and still
  // reports no user, at which point we explicitly sign out.
  bool isUserLoggedIn() {
    return _getSavedUserId() != null;
  }

  /// Watches Firebase Auth state and signs us out **only** if a previously
  /// observed (non-null) user transitions to null while the app is running —
  /// i.e. a real revocation, deletion, or programmatic signOut().
  ///
  /// Crucially, we do NOT treat the cold-start "no Firebase user" state as a
  /// revocation. On some devices (notably MIUI / HyperOS Redmi handsets) the
  /// SDK's persisted user file can be inaccessible or slow to restore, leaving
  /// `currentUser` null indefinitely even though local prefs (and the server)
  /// still consider the user signed in. WhatsApp's behaviour: trust local
  /// state, let API calls re-auth lazily, never auto-bounce on cold start.
  void listenForAuthInvalidation({
    required VoidCallback onSignedOut,
  }) {
    if (_getSavedUserId() == null) return;

    bool sawUserThisSession = false;
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        sawUserThisSession = true;
        return;
      }
      // user == null. Only act if we previously saw a real user this session.
      if (!sawUserThisSession) return;
      if (_getSavedUserId() == null) return;

      await _clearUserIdLocally();
      onSignedOut();
    });
  }

  // Get saved user — returns CACHED local copy instantly (no Firestore read).
  // Call refreshUserFromFirestore() afterwards for a background sync.
  UserModel? getSavedUser() {
    try {
      String? userId = _getSavedUserId();
      if (userId == null) return null;
      return _getCachedUser();
    } catch (e) {
      print('Error getting saved user: $e');
      return null;
    }
  }

  /// Fetches the latest user profile from Firestore and updates the local cache.
  /// Call this in the background after the UI is already visible.
  Future<UserModel?> refreshUserFromFirestore() async {
    try {
      String? userId = _getSavedUserId();
      if (userId == null) return null;

      final user = await _userService.getUserById(userId);
      if (user != null) {
        await _saveUserLocally(user);
      }
      return user;
    } catch (e) {
      print('Error refreshing user from Firestore: $e');
      return null;
    }
  }

  // Save user ID locally (uses pre-cached sharedPrefs from main.dart)
  Future<void> _saveUserIdLocally(String userId) async {
    await sharedPrefs.setString('user_id', userId);
  }

  // Cache the full UserModel as JSON in SharedPreferences
  Future<void> _saveUserLocally(UserModel user) async {
    await sharedPrefs.setString('cached_user', jsonEncode(user.toMap()));
  }

  /// Cache user profile after any successful sign-in / sign-up.
  /// Call this after _saveUserIdLocally for complete local caching.
  Future<void> cacheUser(UserModel user) => _saveUserLocally(user);

  // Read cached user from SharedPreferences (synchronous, no network)
  UserModel? _getCachedUser() {
    final json = sharedPrefs.getString('cached_user');
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return UserModel.fromMap(map, map['id'] ?? '');
    } catch (e) {
      print('Error parsing cached user: $e');
      return null;
    }
  }

  // Get saved user ID (synchronous — uses pre-cached sharedPrefs)
  String? _getSavedUserId() {
    return sharedPrefs.getString('user_id');
  }

  // Clear user ID locally
  Future<void> _clearUserIdLocally() async {
    await sharedPrefs.remove('user_id');
    await sharedPrefs.remove('cached_user');
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
