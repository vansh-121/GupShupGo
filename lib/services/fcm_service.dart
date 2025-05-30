import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FCMService {
  static const _fcmScope = 'https://www.googleapis.com/auth/firebase.messaging';
  // Replace 'videocallapp-81166' with your actual project ID from google-services.json
  static const _fcmEndpoint =
      'https://fcm.googleapis.com/v1/projects/videocallapp-81166/messages:send';

  Future<void> setupFCM() async {
    try {
      print('Setting up FCM...');
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('Notification permission granted');
      } else {
        print('Notification permission denied');
      }
      String? token = await messaging.getToken();
      print('FCM Token: $token');
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        String? userId = prefs.getString('user_id') ?? 'unknown_user';
        await FirebaseFirestore.instance.collection('users').doc(userId).set(
            {'fcmToken': token, 'lastUpdated': FieldValue.serverTimestamp()},
            SetOptions(merge: true));
        print('FCM token stored for user: $userId');
      }
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Foreground message received: ${message.data}');
        String callerId = message.data['callerId'] ?? 'Unknown';
        String channelId = message.data['channelId'] ?? '';
        _showCallNotification(callerId, channelId);
      });
    } catch (e) {
      print('FCM setup error: $e');
    }
  }

  void onCallReceived(void Function(String, String) callback) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Call received: ${message.data}');
      String callerId = message.data['callerId'] ?? 'Unknown';
      String channelId = message.data['channelId'] ?? '';
      callback(callerId, channelId);
    });
  }

  Future<String> _getAccessToken() async {
    try {
      final serviceAccountJson =
          await rootBundle.loadString('assets/service-account.json');
      final accountCredentials =
          ServiceAccountCredentials.fromJson(serviceAccountJson);
      final client = http.Client();
      final accessCredentials = await obtainAccessCredentialsViaServiceAccount(
        accountCredentials,
        [_fcmScope],
        client,
      );
      client.close();
      return accessCredentials.accessToken.data;
    } catch (e) {
      print('Error getting access token: $e');
      rethrow;
    }
  }

  Future<void> sendCallNotification(
      String calleeId, String callerId, String channelId) async {
    try {
      print('Sending notification to $calleeId for channel $channelId');
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(calleeId)
          .get();

      if (!doc.exists) {
        print('User $calleeId not found in database');
        return;
      }

      String? fcmToken = doc['fcmToken'];
      if (fcmToken == null) {
        print('No FCM token found for $calleeId');
        return;
      }

      final accessToken = await _getAccessToken();
      final response = await http.post(
        Uri.parse(_fcmEndpoint),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': {
            'token': fcmToken,
            'data': {
              'callerId': callerId,
              'channelId': channelId,
              'type': 'incoming_call',
            },
            'notification': {
              'title': 'Incoming Call',
              'body': 'Call from $callerId',
            },
            'android': {
              'priority': 'high',
            },
            'apns': {
              'headers': {
                'apns-priority': '10',
              },
              'payload': {
                'aps': {
                  'alert': {
                    'title': 'Incoming Call',
                    'body': 'Call from $callerId',
                  },
                  'sound': 'default',
                },
              },
            },
          },
        }),
      );
      print('Notification sent: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('Failed to send notification: ${response.body}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    print('Background message received: ${message.data}');
    String callerId = message.data['callerId'] ?? 'Unknown';
    String channelId = message.data['channelId'] ?? '';
    await _showCallNotification(callerId, channelId);
  }

  static Future<void> _showCallNotification(
      String callerId, String channelId) async {
    try {
      await FlutterCallkitIncoming.showCallkitIncoming(
        CallKitParams(
          id: channelId,
          nameCaller: callerId,
          appName: 'VideoCallApp',
          type: 1, // Video call
          textAccept: 'Accept',
          textDecline: 'Decline',
        ),
      );
      print('Call notification shown for $callerId');
    } catch (e) {
      print('Error showing call notification: $e');
    }
  }
}
