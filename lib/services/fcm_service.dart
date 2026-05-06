import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:video_chat_app/main.dart';
import 'package:video_chat_app/screens/incoming_call_screen.dart';

class FCMService {
  // ── Cloud Function endpoints (no service account key needed) ────────────
  static const _callFunctionUrl =
      'https://sendcallnotification-luh3g2lkma-uc.a.run.app';
  static const _messageFunctionUrl =
      'https://sendmessagenotification-luh3g2lkma-uc.a.run.app';

  /// Prevents duplicate listener registration when setupFCM is called
  /// multiple times (e.g., hot restart, re-login, screen rebuild).
  static bool _listenersRegistered = false;

  /// Prevents stacking multiple IncomingCallScreens.
  static bool _isIncomingCallScreenShowing = false;
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static const _deviceIdKey = 'gsg_fcm_device_id_v1';
  static const _secureStorage = FlutterSecureStorage();

  /// Public getter so the global CallKit listener in main.dart can check
  /// whether IncomingCallScreen is already handling the accept flow.
  static bool get isIncomingCallScreenShowing => _isIncomingCallScreenShowing;

  Future<void> setupFCM({required String userId}) async {
    print('Setting up FCM for user: $userId');
    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    // ═══════════════════════════════════════════════════════════════════════
    // Step 1: Request notification permission (non-fatal if denied)
    // ═══════════════════════════════════════════════════════════════════════
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

    // ═══════════════════════════════════════════════════════════════════════
    // Step 2: Register background + foreground listeners ONCE
    // ═══════════════════════════════════════════════════════════════════════
    if (!_listenersRegistered) {
      _listenersRegistered = true;

      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Foreground data-only messages — navigate to full-screen incoming call
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Foreground message received: ${message.data}');
        final messageType = message.data['type'] ?? '';

        if (messageType == 'incoming_call' || messageType == 'call') {
          // Show CallKit for ringtone + vibration
          _showCallKitNotification(message.data);

          // Navigate to full-screen incoming call screen (once only)
          if (!_isIncomingCallScreenShowing) {
            _isIncomingCallScreenShowing = true;
            final nav = navigatorKey.currentState;
            if (nav != null) {
              final data = message.data;
              nav.push(
                MaterialPageRoute(
                  builder: (_) => IncomingCallScreen(
                    channelId: data['channelId'] ?? '',
                    callerId: data['callerId'] ?? '',
                    callerName: data['callerName'] ?? 'Unknown',
                    callerPhotoUrl: data['callerPhotoUrl'],
                    isAudioOnly: data['isAudioOnly'] == 'true',
                  ),
                ),
              ).then((_) {
                // Reset flag when IncomingCallScreen is popped/replaced
                _isIncomingCallScreenShowing = false;
              });
            } else {
              _isIncomingCallScreenShowing = false;
            }
          }
        }
        // Chat messages are handled by StreamBuilder — no action needed here.
      });
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Step 3: CallKit permissions (notification + full-screen intent)
    // Handled upfront on LoginScreen — no need to request again here.
    // ═══════════════════════════════════════════════════════════════════════

    // ═══════════════════════════════════════════════════════════════════════
    // Step 4: Fetch and store FCM token (isolated — failure is recoverable)
    // SERVICE_NOT_AVAILABLE can happen when Google Play Services is busy
    // or temporarily unavailable. The onTokenRefresh listener below will
    // catch the token when it becomes available later.
    // On Xiaomi/MIUI devices, SERVICE_NOT_AVAILABLE is common because
    // MIUI aggressively kills Google Play Services connections.
    // ═══════════════════════════════════════════════════════════════════════
    String? token;
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        if (attempt > 1) {
          // On retry, delete old token to force Play Services to reconnect
          print('FCM token retry attempt $attempt — deleting old token first');
          await messaging.deleteToken();
          await Future.delayed(Duration(seconds: attempt * 2));
        }
        token = await messaging.getToken();
        if (token != null) {
          print('FCM Token obtained (attempt $attempt): $token');
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

    // ═══════════════════════════════════════════════════════════════════════
    // Step 5: Listen for token refreshes (handles initial failure + rotations)
    // If Step 4 failed, this will catch the token when Play Services recovers.
    // ═══════════════════════════════════════════════════════════════════════
    _tokenRefreshSubscription ??=
        messaging.onTokenRefresh.listen((String newToken) async {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? userId;
      print('FCM token refreshed: $newToken');
      await _storeToken(currentUserId, newToken);
    });
  }

  /// Stores the FCM token in Firestore for the given user.
  static Future<void> _storeToken(String userId, String token) async {
    try {
      final deviceId = await _getOrCreateDeviceId();
      final deviceInfo = await _getDeviceInfo();
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

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

      print('FCM token stored for user: $userId on device: $deviceId');
    } catch (e) {
      print('Error storing FCM token: $e');
    }
  }

  static Future<String> _getOrCreateDeviceId() async {
    final existing = await _secureStorage.read(key: _deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final deviceId =
        FirebaseFirestore.instance.collection('_localDeviceIds').doc().id;
    await _secureStorage.write(key: _deviceIdKey, value: deviceId);
    return deviceId;
  }

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
    try {
      print('Sending call notification to $calleeId via Cloud Function');
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
      print('Call notification response: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('Failed to send call notification: ${response.body}');
      }
    } catch (e) {
      print('Error sending call notification: $e');
    }
  }

  /// Send chat message notification via Cloud Function.
  Future<void> sendMessageNotification({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String message,
    required String chatRoomId,
  }) async {
    try {
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
        }),
      );
      print('Message notification sent: ${response.statusCode}');
    } catch (e) {
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
            print(
                'Messages and chatRoom marked as delivered for: $chatRoomId');
          }
        } catch (e) {
          print('Error marking messages as delivered: $e');
        }
      }
    } else if (messageType == 'call' || messageType == 'incoming_call') {
      // Show native full-screen call UI via CallKit
      await _showCallKitNotification(message.data);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CallKit notification — shared between foreground and background handlers
  // ═══════════════════════════════════════════════════════════════════════════

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
          isCustomNotification: true,
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
