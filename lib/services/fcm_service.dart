import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:video_chat_app/services/native_call_service.dart';
import 'package:video_chat_app/services/call_device_identity.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_chat_app/main.dart';
import 'package:video_chat_app/screens/incoming_call_screen.dart';
import 'package:video_chat_app/screens/incoming_screen_share_screen.dart';
import 'package:video_chat_app/screens/screen_share_viewer_screen.dart';
import 'package:video_chat_app/services/screen_share_session.dart';
import 'package:video_chat_app/services/crashlytics_service.dart';
import 'package:video_chat_app/services/crypto/resend_wakeup.dart';
import 'package:video_chat_app/services/notification_service.dart';
import 'package:video_chat_app/services/performance_service.dart';

class FCMService {
  // ── Cloud Function endpoints (no service account key needed) ────────────
  static const _callFunctionUrl =
      'https://sendcallnotification-luh3g2lkma-uc.a.run.app';
  static const _screenShareFunctionUrl =
      'https://sendscreensharenotification-luh3g2lkma-uc.a.run.app';
  static const _messageFunctionUrl =
      'https://sendmessagenotification-luh3g2lkma-uc.a.run.app';

  /// Prevents duplicate listener registration when setupFCM is called
  /// multiple times (e.g., hot restart, re-login, screen rebuild).
  static bool _listenersRegistered = false;

  /// Avoids reopening Android's full-screen-intent settings on every Home
  /// resume. The explicit Settings action can still force a retry.
  static bool _fullScreenIntentPermissionRequested = false;

  /// Prevents stacking multiple IncomingCallScreens.
  static bool _isIncomingCallScreenShowing = false;

  /// Prevents stacking multiple ScreenShareViewerScreens — opening a second
  /// viewer would spin up a second Agora engine for the same channel and
  /// cause resource conflicts. Reset when the viewer is popped.
  static bool _isScreenShareViewerShowing = false;

  /// Prevents stacking multiple IncomingScreenShareScreens (the accept/reject
  /// request UI). Reset when the request screen is popped.
  static bool _isScreenShareRequestShowing = false;
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static const _deviceIdKey = 'gsg_fcm_device_id_v1';
  static const _lastRegisteredUserIdKey = 'gsg_fcm_last_user_id_v1';
  static const _lastFcmTokenKey = 'gsg_fcm_last_token_v1';
  static const _nativeCallUserIdKey = 'gsg_native_call_user_id';
  static const _secureStorage = FlutterSecureStorage();
  static final _deviceIdentity = CallDeviceIdentity(
    read: () => _secureStorage.read(key: _deviceIdKey),
    write: (id) => _secureStorage.write(key: _deviceIdKey, value: id),
    create: () =>
        FirebaseFirestore.instance.collection('_localDeviceIds').doc().id,
  );

  /// Public getter so the global CallKit listener in main.dart can check
  /// whether IncomingCallScreen is already handling the accept flow.
  static bool get isIncomingCallScreenShowing =>
      _isIncomingCallScreenShowing || NativeCallService.instance.isShowingCall;

  /// Shows the accept/reject request UI ([IncomingScreenShareScreen]) for an
  /// incoming screen share. Used by both the foreground FCM handler and the
  /// background notification-tap router. No-ops if a request is already
  /// showing, a session is already active, an incoming call is up, the
  /// channelId is missing, or the navigator isn't ready.
  static void showIncomingScreenShareRequest(Map<String, dynamic> data) {
    final channelId = (data['channelId'] ?? '') as String;
    if (channelId.isEmpty) return;
    if (_isScreenShareRequestShowing ||
        isIncomingCallScreenShowing ||
        ScreenShareSession.instance.active) {
      return;
    }
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    _isScreenShareRequestShowing = true;
    nav
        .push(MaterialPageRoute(
          builder: (_) => IncomingScreenShareScreen(
            channelId: channelId,
            sharerId: (data['sharerId'] ?? '') as String,
            sharerName: (data['sharerName'] ?? 'Someone') as String,
            sharerPhotoUrl: data['sharerPhotoUrl'] as String?,
          ),
        ))
        .then((_) => _isScreenShareRequestShowing = false);
  }

  /// Starts the viewer-side screen-share session (owns the Agora engine so it
  /// survives navigation) and opens the full-screen viewer. Used by both the
  /// foreground FCM handler and the notification-tap router. Safe to call
  /// repeatedly — no-ops if a session is already active.
  static Future<void> openScreenShareViewer({
    required String channelId,
    required String sharerName,
  }) async {
    if (channelId.isEmpty) return;
    if (ScreenShareSession.instance.active || _isScreenShareViewerShowing) {
      return;
    }
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    _isScreenShareViewerShowing = true;
    try {
      await ScreenShareSession.instance.startAsViewer(
        channelId: channelId,
        sharerName: sharerName,
      );
      nav
          .push(MaterialPageRoute(
              builder: (_) => const ScreenShareViewerScreen()))
          .then((_) => _isScreenShareViewerShowing = false);
    } catch (e) {
      print('Error opening screen share viewer: $e');
      await ScreenShareSession.instance.end();
      _isScreenShareViewerShowing = false;
    }
  }

  /// Requests the OS notification permissions messaging needs (iOS/FCM and
  /// Android 13+ POST_NOTIFICATIONS). Deferred behind an explicit opt-in — see
  /// [setupFCM]'s `requestPermissions` flag — so the notification dialog never
  /// fires on the cold-start path. Every step is non-fatal.
  Future<void> _requestMessagingPermissions() async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    // iOS / FCM notification permission.
    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print(settings.authorizationStatus == AuthorizationStatus.authorized
          ? 'Notification permission granted'
          : 'Notification permission denied');
    } catch (e) {
      print('Permission request error (non-fatal): $e');
    }

    // Android 13+ (API 33) runtime POST_NOTIFICATIONS — requestPermission()
    // above only handles iOS/FCM state, not the Android OS-level dialog.
    if (Platform.isAndroid) {
      try {
        final notifStatus = await Permission.notification.status;
        if (!notifStatus.isGranted) {
          final result = await Permission.notification.request();
          print(result.isGranted
              ? 'Android POST_NOTIFICATIONS permission granted'
              : 'Android POST_NOTIFICATIONS permission denied');
        }
      } catch (e) {
        print('Android notification permission request error (non-fatal): $e');
      }
    }

    // Full-screen call access is separate from notification permission.
    requestFullScreenIntentPermission();
  }

  /// Requests Android 14+'s separate full-screen-intent access for incoming
  /// calls. This is deliberately independent of notification permission:
  /// users can have POST_NOTIFICATIONS enabled while this access is disabled.
  ///
  /// The plugin checks current access before opening system settings. Version
  /// 2.5.2 calls its API-34 check before its own SDK guard, and its method-channel
  /// call does not complete a result, so guard it here and launch without
  /// blocking FCM setup.
  void requestFullScreenIntentPermission({bool force = false}) {
    if (!Platform.isAndroid ||
        (_fullScreenIntentPermissionRequested && !force)) {
      return;
    }
    _fullScreenIntentPermissionRequested = true;
    unawaited(_launchFullScreenIntentPermissionRequest());
  }

  Future<void> _launchFullScreenIntentPermissionRequest() async {
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt < 34) return;
      await FlutterCallkitIncoming.requestFullIntentPermission();
    } catch (error) {
      _fullScreenIntentPermissionRequested = false;
      debugPrint(
          'Full-screen call permission request error (non-fatal): $error');
    }
  }

  /// Whether the OS currently lets us show notifications. Lets the soft-ask skip
  /// prompting when permission is already granted (e.g. a returning user).
  Future<bool> hasNotificationPermission() async {
    try {
      if (Platform.isAndroid) {
        return (await Permission.notification.status).isGranted;
      }
      final s = await FirebaseMessaging.instance.getNotificationSettings();
      return s.authorizationStatus == AuthorizationStatus.authorized ||
          s.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  /// Registers this device for messaging: push token, topics, and the
  /// foreground/background handlers. Safe to call repeatedly.
  ///
  /// It does NOT prompt for notification permission by default. Pass
  /// [requestPermissions] true only from the contextual soft-ask
  /// (NotificationPermissionPrompt); after the user grants, this is called
  /// again so the token registers (iOS won't mint one until permission exists).
  /// Android full-screen call access is checked independently during normal
  /// FCM setup and from the explicit Settings entry point.
  Future<void> setupFCM({
    required String userId,
    bool requestPermissions = false,
  }) async {
    print('Setting up FCM for user: $userId');
    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    // The Android FCM receiver runs before Dart when the process is dead. Keep
    // a non-sensitive mirror of the active uid in Flutter SharedPreferences so
    // it can reject a stale token belonging to a previously signed-in account.
    await _mirrorActiveUserForNativeCalls(userId);
    if (Platform.isAndroid) {
      if (FirebaseAuth.instance.currentUser?.uid != userId) return;
      await NativeCallService.bind(userId, await _getOrCreateDeviceId());
    }

    // PushKit has its own token, separate from FCM/APNs notification tokens.
    // AppDelegate registers it at launch; persist it with this device record as
    // soon as it is available so iOS calls can wake a terminated app.
    if (Platform.isIOS) {
      unawaited(_syncVoipToken(userId));
    }

    if (requestPermissions) {
      await _requestMessagingPermissions();
    } else if (await hasNotificationPermission()) {
      // A returning user can already have POST_NOTIFICATIONS while Android
      // 14+'s separate full-screen-intent access is still disabled. Check it
      // during every normal setup path; the process guard makes this cheap.
      requestFullScreenIntentPermission();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Step 2: Register background + foreground listeners ONCE
    // ═══════════════════════════════════════════════════════════════════════
    if (!_listenersRegistered) {
      _listenersRegistered = true;

      // Initialise local notification channels & tap routing
      await NotificationService.instance.initialize();

      // Foreground data-only messages — navigate to full-screen incoming call
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print('Foreground message received: ${message.data}');
        final messageType = message.data['type'] ?? '';

        if (messageType == 'incoming_call' || messageType == 'call') {
          if (Platform.isAndroid) return; // Native receiver is the sole owner.
          if (!await _isMessageForCurrentUser(message.data)) {
            print('Ignoring call notification for a different signed-in user');
            return;
          }

          // Android's native FCM receiver normally posts this before Dart is
          // invoked. Check active calls first so this remains a fallback without
          // ringing twice. iOS foreground calls still arrive through FCM.
          await _ensureCallKitNotification(message.data);

          // Navigate to full-screen incoming call screen (once only)
          if (!_isIncomingCallScreenShowing) {
            _isIncomingCallScreenShowing = true;
            final nav = navigatorKey.currentState;
            if (nav != null) {
              final data = message.data;
              nav
                  .push(
                MaterialPageRoute(
                  builder: (_) => IncomingCallScreen(
                    channelId: data['channelId'] ?? '',
                    callerId: data['callerId'] ?? '',
                    callerName: data['callerName'] ?? 'Unknown',
                    callerPhotoUrl: data['callerPhotoUrl'],
                    isAudioOnly: data['isAudioOnly'] == 'true',
                  ),
                ),
              )
                  .then((_) {
                // Reset flag when IncomingCallScreen is popped/replaced
                _isIncomingCallScreenShowing = false;
              });
            } else {
              _isIncomingCallScreenShowing = false;
            }
          }
        } else if (messageType == 'screen_share') {
          if (!await _isMessageForCurrentUser(message.data)) {
            print(
                'Ignoring screen share notification for a different signed-in user');
            return;
          }

          // Show the accept/reject request UI — the viewer only opens once the
          // user accepts. showIncomingScreenShareRequest guards against a call
          // already ringing or a share session already being active.
          showIncomingScreenShareRequest(message.data);
        } else if (messageType == 'streak_broken' ||
            messageType == 'streak_warning' ||
            messageType == 'streak_milestone' ||
            messageType == 'gup_points_earned' ||
            messageType == 'unread_reminder' ||
            messageType == 'daily_digest') {
          // Show as a local notification via NotificationService so the user
          // sees it even when the app is in the foreground.
          await NotificationService.instance.handleForegroundMessage(message);
        } else if (messageType == 'chat_message') {
          if (!await _isMessageForCurrentUser(message.data)) {
            print('Ignoring chat notification for a different signed-in user');
            return;
          }
          // Show a local notification for the chat message. Suppressed if the
          // user is currently viewing the same chat (via activeChatRoomId).
          await NotificationService.instance.handleChatMessage(message);
        } else if (messageType == 'resend_request') {
          // Silent: nothing for the user to see or do. A peer can't decrypt
          // something we sent, and only this device holds the plaintext needed
          // to re-encrypt it. Handled here as well as in the background handler
          // so an app that's already open answers on the push rather than
          // waiting for its room listener's next snapshot.
          if (!await _isMessageForCurrentUser(message.data)) return;
          await handleForegroundResendWakeup(message.data);
        }
      });
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Step 3: CallKit permissions (notification + full-screen intent)
    // Handled upfront on LoginScreen — no need to request again here.
    // ═══════════════════════════════════════════════════════════════════════

    // Attach this before requesting or retrying a token. Older Play Services /
    // MIUI builds can rotate the token while getToken() is recovering; when the
    // listener was attached afterwards, that rotation was lost and the device
    // stayed unreachable until another app launch.
    _tokenRefreshSubscription ??=
        messaging.onTokenRefresh.listen((String newToken) async {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        print('Ignoring FCM token refresh while signed out');
        return;
      }
      print('FCM token refreshed');
      await _storeToken(currentUserId, newToken);
    });

    // ═══════════════════════════════════════════════════════════════════════
    // Step 4: Fetch and store FCM token (isolated — failure is recoverable)
    // SERVICE_NOT_AVAILABLE can happen when Google Play Services is busy
    // or temporarily unavailable. The onTokenRefresh listener above will
    // catch the token when it becomes available later.
    // On Xiaomi/MIUI devices, SERVICE_NOT_AVAILABLE is common because
    // MIUI aggressively kills Google Play Services connections.
    // ═══════════════════════════════════════════════════════════════════════
    String? token;
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        if (attempt > 1) {
          // Never delete a working token as a retry mechanism. On Android 12 /
          // older MIUI, deleteToken() can succeed while the replacement token
          // request fails, leaving this install absent from every server target.
          print('FCM token retry attempt $attempt');
          await Future.delayed(Duration(seconds: attempt * 2));
        }
        token = await messaging.getToken().timeout(const Duration(seconds: 10));
        if (token != null && token.isNotEmpty) {
          print('FCM token obtained (attempt $attempt)');
          await _storeToken(userId, token);
          break;
        }
      } catch (e) {
        print('FCM token attempt $attempt failed: $e');
        if (attempt == 3) {
          print('All FCM token attempts failed — relying on onTokenRefresh');
        }
      }
    }

    // A transient Play Services outage must not erase a previously working
    // registration. Re-publish the last token for this install so the server's
    // per-device registry remains populated while onTokenRefresh recovers.
    if (token == null || token.isEmpty) {
      try {
        final cachedToken = await _secureStorage.read(key: _lastFcmTokenKey);
        if (cachedToken != null && cachedToken.isNotEmpty) {
          print('Using cached FCM token while Play Services recovers');
          await _storeToken(userId, cachedToken);
        }
      } catch (error) {
        debugPrint('Could not read cached FCM token (non-fatal): $error');
      }
    }
  }

  /// Stores the FCM token in Firestore for the given user.
  static Future<void> _storeToken(String userId, String token) async {
    if (FirebaseAuth.instance.currentUser?.uid != userId) return;
    if (Platform.isAndroid) {
      // Native WorkManager owns refresh ordering and retries, even without Dart.
      await NativeCallService.channel.invokeMethod<void>('syncToken');
      return;
    }
    try {
      final deviceId = await _getOrCreateDeviceId();
      await _removePreviousAccountDeviceTokenIfNeeded(userId, deviceId);
      final deviceInfo = await _getDeviceInfo();
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);

      await userRef.collection('devices').doc(deviceId).set(
        {
          'deviceId': deviceId,
          'fcmToken': token,
          'platform': Platform.operatingSystem,
          'deviceModel': deviceInfo,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
          'lastSeenAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Kept only as a migration fallback for already deployed functions.
      // New Cloud Functions read the per-device token registry above.
      await userRef.set(
        {
          'fcmToken': token,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await _secureStorage.write(
        key: _lastRegisteredUserIdKey,
        value: userId,
      );
      try {
        await _secureStorage.write(key: _lastFcmTokenKey, value: token);
      } catch (error) {
        debugPrint('Could not cache FCM token (non-fatal): $error');
      }

      print('FCM token stored for user: $userId on device: $deviceId');
    } catch (e, stack) {
      print('Error storing FCM token: $e');
      CrashlyticsService.logError(e, stack,
          reason: 'FCM._storeToken failed for user $userId');
    }
  }

  static Future<void> _mirrorActiveUserForNativeCalls(String userId) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_nativeCallUserIdKey, userId);
    } catch (error) {
      debugPrint('Could not mirror active call user (non-fatal): $error');
    }
  }

  static Future<void> _syncVoipToken(String userId) async {
    try {
      final dynamic rawToken =
          await FlutterCallkitIncoming.getDevicePushTokenVoIP();
      final token = rawToken?.toString() ?? '';
      if (token.isNotEmpty) {
        await _storeVoipToken(userId, token);
      }
    } catch (error) {
      debugPrint('VoIP token sync failed (non-fatal): $error');
    }
  }

  /// Called from the global CallKit event listener when PushKit rotates the
  /// device token. PushKit tokens are not FCM registration tokens and must be
  /// stored separately for direct APNs VoIP delivery.
  static Future<void> handleVoipTokenUpdate(dynamic body) async {
    if (!Platform.isIOS || body is! Map) return;

    final data = Map<String, dynamic>.from(body);
    final token = data['deviceTokenVoIP']?.toString() ?? '';
    final userId = FirebaseAuth.instance.currentUser?.uid ??
        await _secureStorage.read(key: _lastRegisteredUserIdKey);
    if (userId == null || userId.isEmpty) return;

    if (token.isEmpty) {
      await _removeVoipToken(userId);
    } else {
      await _storeVoipToken(userId, token);
    }
  }

  static Future<void> _storeVoipToken(String userId, String token) async {
    try {
      final deviceId = await _getOrCreateDeviceId();
      await _removePreviousAccountDeviceTokenIfNeeded(userId, deviceId);
      final deviceInfo = await _getDeviceInfo();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(deviceId)
          .set(
        {
          'deviceId': deviceId,
          'voipToken': token,
          'voipEnvironment': kReleaseMode ? 'production' : 'sandbox',
          'platform': 'ios',
          'deviceModel': deviceInfo,
          'voipTokenUpdatedAt': FieldValue.serverTimestamp(),
          'lastSeenAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      debugPrint('VoIP token stored for user: $userId on device: $deviceId');
    } catch (error, stack) {
      debugPrint('Error storing VoIP token: $error');
      CrashlyticsService.logError(error, stack,
          reason: 'FCM._storeVoipToken failed for user $userId');
    }
  }

  static Future<void> _removeVoipToken(String userId) async {
    try {
      final deviceId = await _secureStorage.read(key: _deviceIdKey);
      if (deviceId == null || deviceId.isEmpty) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(deviceId)
          .set(
        {
          'voipToken': FieldValue.delete(),
          'voipTokenUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (error) {
      debugPrint('Error removing VoIP token: $error');
    }
  }

  Future<void> unregisterCurrentDevice({required String userId}) async {
    await NativeCallService.clear();
    // Cancel the token-refresh listener FIRST, before any operation that can
    // throw or provoke a refresh. deleteToken() below triggers onTokenRefresh,
    // and if the listener were still live (or if an earlier step threw and
    // skipped a late cancel) it would re-store a fresh token for the departing
    // user — leaving the device registered after logout. Cancelling up front
    // makes logout deterministic regardless of what fails afterwards.
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_nativeCallUserIdKey);
    } catch (_) {}

    try {
      final deviceId = await _secureStorage.read(key: _deviceIdKey);
      if (deviceId != null && deviceId.isNotEmpty) {
        final userRef =
            FirebaseFirestore.instance.collection('users').doc(userId);
        final currentToken = await FirebaseMessaging.instance.getToken();

        // The device document also holds encryption keys. Remove push fields only.
        await userRef.collection('devices').doc(deviceId).set({
          'fcmToken': FieldValue.delete(),
          'voipToken': FieldValue.delete(),
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (currentToken != null && currentToken.isNotEmpty) {
          final userDoc = await userRef.get();
          if (userDoc.data()?['fcmToken'] == currentToken) {
            await userRef.set(
              {
                'fcmToken': FieldValue.delete(),
                'lastUpdated': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
          }
        }
      }

      await _secureStorage.delete(key: _lastRegisteredUserIdKey);
      await _secureStorage.delete(key: _lastFcmTokenKey);
      await FirebaseMessaging.instance.deleteToken();

      print('FCM token unregistered for user: $userId');
    } catch (e) {
      print('Error unregistering FCM token for user $userId: $e');
    }
  }

  static Future<void> _removePreviousAccountDeviceTokenIfNeeded(
      String userId, String deviceId) async {
    final previousUserId =
        await _secureStorage.read(key: _lastRegisteredUserIdKey);
    if (previousUserId == null ||
        previousUserId.isEmpty ||
        previousUserId == userId) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(previousUserId)
          .collection('devices')
          .doc(deviceId)
          .set({
        'fcmToken': FieldValue.delete(),
        'voipToken': FieldValue.delete()
      }, SetOptions(merge: true));
      print('Removed this device from previous FCM user: $previousUserId');
    } catch (e) {
      print('Could not remove previous FCM user token: $e');
    }
  }

  static Future<String> _getOrCreateDeviceId() => _deviceIdentity.getOrCreate();

  static Future<String> _getDeviceInfo() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        return '${info.manufacturer} ${info.model}'.trim();
      }
      if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        return info.utsname.machine;
      }
    } catch (_) {}
    return Platform.operatingSystem;
  }

  static Future<bool> _isMessageForCurrentUser(
      Map<String, dynamic> data) async {
    final expectedUserId =
        data['calleeId'] ?? data['receiverId'] ?? data['viewerId'];
    if (expectedUserId == null || expectedUserId.toString().isEmpty) {
      return true;
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid ??
        await _secureStorage.read(key: _lastRegisteredUserIdKey);
    return currentUserId != null && currentUserId == expectedUserId.toString();
  }

  /// Returns the current user's Firebase ID token, or null if not signed in.
  Future<String?> _getIdToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {
      return null;
    }
  }

  /// Send call notification via Cloud Function (no service account needed).
  Future<void> sendCallNotification(
      String calleeId, String callerId, String channelId,
      {bool isAudioOnly = false}) async {
    final metric =
        PerformanceService.newHttpMetric(_callFunctionUrl, HttpMethod.Post);
    try {
      print('Sending call notification to $calleeId via Cloud Function');
      await metric.start();
      metric.putAttribute('call_type', isAudioOnly ? 'audio' : 'video');

      final idToken = await _getIdToken();
      final response = await http.post(
        Uri.parse(_callFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          if (idToken != null) 'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'calleeId': calleeId,
          'callerId': callerId,
          'channelId': channelId,
          'isAudioOnly': isAudioOnly,
        }),
      );

      metric.httpResponseCode = response.statusCode;
      metric.responsePayloadSize = response.contentLength;
      await metric.stop();

      print('Call notification response: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('Failed to send call notification: ${response.body}');
      } else {
        print('Call notification delivery: ${response.body}');
      }
    } catch (e, stack) {
      // Best-effort: stop the metric even on error so it doesn't leak.
      try {
        await metric.stop();
      } catch (_) {}
      print('Error sending call notification: $e');
      CrashlyticsService.logError(e, stack,
          reason: 'FCM.sendCallNotification failed for callee $calleeId');
    }
  }

  /// Send screen share notification via Cloud Function. Notifies [viewerId]
  /// that [sharerId] has started sharing their screen on [channelId].
  Future<void> sendScreenShareNotification(
      String viewerId, String sharerId, String channelId) async {
    final metric = PerformanceService.newHttpMetric(
        _screenShareFunctionUrl, HttpMethod.Post);
    try {
      print(
          'Sending screen share notification to $viewerId via Cloud Function');
      await metric.start();

      final idToken = await _getIdToken();
      final response = await http.post(
        Uri.parse(_screenShareFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          if (idToken != null) 'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'viewerId': viewerId,
          'sharerId': sharerId,
          'channelId': channelId,
        }),
      );

      metric.httpResponseCode = response.statusCode;
      metric.responsePayloadSize = response.contentLength;
      await metric.stop();

      print('Screen share notification response: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('Failed to send screen share notification: ${response.body}');
      }
    } catch (e, stack) {
      try {
        await metric.stop();
      } catch (_) {}
      print('Error sending screen share notification: $e');
      CrashlyticsService.logError(e, stack,
          reason:
              'FCM.sendScreenShareNotification failed for viewer $viewerId');
    }
  }

  /// Send chat message notification via Cloud Function.
  ///
  /// [screen] is an optional tap-routing hint forwarded verbatim in the FCM
  /// data payload (e.g. 'requests' for friend-request notifications so
  /// [NotificationService] opens the Requests tab instead of just Home).
  /// Omitted for real chat messages, which route via chatRoomId/contactId.
  Future<void> sendMessageNotification({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String message,
    required String chatRoomId,
    String? screen,
  }) async {
    final metric =
        PerformanceService.newHttpMetric(_messageFunctionUrl, HttpMethod.Post);
    try {
      await metric.start();

      final idToken = await _getIdToken();
      final response = await http.post(
        Uri.parse(_messageFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          if (idToken != null) 'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'receiverId': receiverId,
          'senderId': senderId,
          'senderName': senderName,
          'message': message,
          'chatRoomId': chatRoomId,
          if (screen != null) 'screen': screen,
        }),
      );

      metric.httpResponseCode = response.statusCode;
      metric.responsePayloadSize = response.contentLength;
      await metric.stop();

      print('Message notification sent: ${response.statusCode}');
    } catch (e) {
      try {
        await metric.stop();
      } catch (_) {}
      print('Error sending message notification: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Background handler — top-level function required by Firebase Messaging
  // ═══════════════════════════════════════════════════════════════════════════

  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await Firebase.initializeApp();
    print('Background message received: ${message.data}');

    final messageType = message.data['type'] ?? '';

    if (messageType == 'chat_message') {
      if (!await _isMessageForCurrentUser(message.data)) {
        print('Ignoring chat notification for a different signed-in user');
        return;
      }

      // Handle chat message - mark as delivered
      String chatRoomId = message.data['chatRoomId'] ?? '';
      String senderId = message.data['senderId'] ?? '';

      if (chatRoomId.isNotEmpty && senderId.isNotEmpty) {
        try {
          final firestore = FirebaseFirestore.instance;

          // Get and update sent messages to delivered
          final snapshot = await firestore
              .collection('chatRooms')
              .doc(chatRoomId)
              .collection('messages')
              .where('senderId', isEqualTo: senderId)
              .where('status', isEqualTo: 'sent')
              .get();

          if (snapshot.docs.isNotEmpty) {
            // Use batch to update all messages and chatRoom
            WriteBatch batch = firestore.batch();

            for (var doc in snapshot.docs) {
              batch.update(doc.reference, {'status': 'delivered'});
            }

            // Also update the chatRoom's lastMessageStatus
            batch.update(
              firestore.collection('chatRooms').doc(chatRoomId),
              {'lastMessageStatus': 'delivered'},
            );

            await batch.commit();
            print('Messages and chatRoom marked as delivered for: $chatRoomId');
          }
        } catch (e) {
          print('Error marking messages as delivered: $e');
        }
      }
    } else if (messageType == 'call' || messageType == 'incoming_call') {
      if (Platform.isAndroid) return;
      if (!await _isMessageForCurrentUser(message.data)) {
        print('Ignoring call notification for a different signed-in user');
        return;
      }

      // The Android receiver posts the UI before starting this isolate. This
      // active-call check keeps the Dart path as a fallback without duplicates.
      await _ensureCallKitNotification(message.data);
    } else if (messageType == 'resend_request') {
      // A peer can't decrypt something we sent, and only this device holds the
      // plaintext to re-encrypt it. Awaited: the handler's isolate is torn down
      // as soon as this returns.
      if (!await _isMessageForCurrentUser(message.data)) return;
      await handleBackgroundResendWakeup(message.data);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CallKit notification — shared between foreground and background handlers
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> _ensureCallKitNotification(
      Map<String, dynamic> data) async {
    final channelId = data['channelId']?.toString() ?? '';
    if (channelId.isEmpty) return;

    try {
      final dynamic activeCalls = await FlutterCallkitIncoming.activeCalls()
          .timeout(const Duration(seconds: 2));
      if (activeCalls is List) {
        final alreadyActive = activeCalls.any((dynamic rawCall) {
          if (rawCall is! Map) return false;
          final call = Map<String, dynamic>.from(rawCall);
          if (call['id']?.toString() == channelId ||
              call['uuid']?.toString() == channelId) {
            return true;
          }
          final rawExtra = call['extra'];
          return rawExtra is Map &&
              rawExtra['channelId']?.toString() == channelId;
        });
        if (alreadyActive) return;
      }
    } catch (error) {
      debugPrint('Could not inspect active calls; using Dart fallback: $error');
    }

    await _showCallKitNotification(data);
  }

  /// Shows a native phone-call-style notification with Accept / Decline
  /// buttons, ringtone, and vibration — identical to WhatsApp's behavior.
  ///
  /// When the user taps Accept, the CallKit event listener (registered in
  /// main.dart) navigates to CallScreen.
  static Future<void> _showCallKitNotification(
      Map<String, dynamic> data) async {
    final callerId = data['callerId'] ?? 'Unknown';
    final callerName = data['callerName'] ?? callerId;
    final callerPhotoUrl = data['callerPhotoUrl'] ?? '';
    final channelId = data['channelId'] ?? '';
    final isAudioOnly = data['isAudioOnly'] == 'true';

    if (channelId.isEmpty) {
      print('Cannot show call notification: channelId is empty');
      return;
    }

    try {
      final params = CallKitParams(
        id: channelId,
        nameCaller: callerName,
        appName: 'GupShupGo',
        avatar: callerPhotoUrl.isNotEmpty ? callerPhotoUrl : null,
        handle: isAudioOnly ? 'Audio Call' : 'Video Call',
        type: isAudioOnly ? 0 : 1, // 0 = Audio, 1 = Video
        textAccept: 'Accept',
        textDecline: 'Decline',
        missedCallNotification: const NotificationParams(
          showNotification: true,
          isShowCallback: true,
          subtitle: 'Missed call',
          callbackText: 'Call back',
        ),
        duration: 45000, // Auto-dismiss after 45 seconds (WhatsApp uses ~45s)
        extra: <String, dynamic>{
          'callerId': callerId,
          'channelId': channelId,
          'isAudioOnly': isAudioOnly.toString(),
        },
        android: const AndroidParams(
          // MIUI/HyperOS lock screens often clip custom RemoteViews when
          // notifications are stacked. Let Android render the call layout so
          // the Accept/Decline row gets the correct height.
          isCustomNotification: false,
          isShowLogo: false,
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#00A884',
          actionColor: '#00A884',
          incomingCallNotificationChannelName: 'Incoming Calls',
          isShowCallID: false,
          isShowFullLockedScreen: true,
        ),
        ios: const IOSParams(
          iconName: 'AppIcon',
          supportsVideo: true,
          maximumCallsPerCallGroup: 1,
          audioSessionMode: 'default',
          audioSessionActive: true,
          audioSessionPreferredSampleRate: 44100.0,
          audioSessionPreferredIOBufferDuration: 0.005,
          ringtonePath: 'system_ringtone_default',
        ),
      );

      await FlutterCallkitIncoming.showCallkitIncoming(params);
      print(
          'CallKit notification shown: $callerName (${isAudioOnly ? 'Audio' : 'Video'})');
    } catch (e) {
      print('Error showing CallKit notification: $e');
    }
  }
}

/// Registered in main() before runApp so Android can start the background
/// isolate even when no HomeScreen has been constructed in the current process.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) {
  return FCMService._firebaseMessagingBackgroundHandler(message);
}
