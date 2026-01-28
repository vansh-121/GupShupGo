import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class FCMService {
  static const _fcmScope = 'https://www.googleapis.com/auth/firebase.messaging';
  static const _fcmEndpoint =
      'https://fcm.googleapis.com/v1/projects/videocallapp-81166/messages:send';

  Future<void> setupFCM({required String userId}) async {
    try {
      print('Setting up FCM for user: $userId');
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
        await FirebaseFirestore.instance.collection('users').doc(userId).set(
          {'fcmToken': token, 'lastUpdated': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
        print('FCM token stored for user: $userId');
      }
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Foreground message received: ${message.data}');
        String messageType = message.data['type'] ?? '';

        // Only show call notification for call type messages
        if (messageType == 'call' ||
            messageType.isEmpty && message.data['channelId'] != null) {
          String callerId = message.data['callerId'] ?? 'Unknown';
          String channelId = message.data['channelId'] ?? '';
          if (channelId.isNotEmpty) {
            _showCallNotification(callerId, channelId);
          }
        }
        // Chat messages are handled by the StreamBuilder in chat_screen.dart
      });
    } catch (e) {
      print('FCM setup error: $e');
    }
  }

  void onCallReceived(void Function(String, String) callback) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message received in onCallReceived: ${message.data}');
      String messageType = message.data['type'] ?? '';
      String channelId = message.data['channelId'] ?? '';

      // Only trigger callback for call messages, not chat messages
      if (messageType == 'call' ||
          (messageType.isEmpty && channelId.isNotEmpty)) {
        String callerId = message.data['callerId'] ?? 'Unknown';
        print('Call notification - callerId: $callerId, channelId: $channelId');
        callback(callerId, channelId);
      } else {
        print('Ignoring non-call message of type: $messageType');
      }
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

  // Send a chat message notification (for delivery receipts)
  Future<void> sendMessageNotification({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String message,
    required String chatRoomId,
  }) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .get();

      if (!doc.exists) {
        print('User $receiverId not found in database');
        return;
      }

      String? fcmToken = doc['fcmToken'];
      if (fcmToken == null) {
        print('No FCM token found for $receiverId');
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
              'type': 'chat_message',
              'senderId': senderId,
              'senderName': senderName,
              'message': message,
              'chatRoomId': chatRoomId,
            },
            'notification': {
              'title': senderName,
              'body': message,
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
                    'title': senderName,
                    'body': message,
                  },
                  'sound': 'default',
                  'content-available': 1,
                },
              },
            },
          },
        }),
      );
      print('Message notification sent: ${response.statusCode}');
    } catch (e) {
      print('Error sending message notification: $e');
    }
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    print('Background message received: ${message.data}');

    String messageType = message.data['type'] ?? '';

    if (messageType == 'chat_message') {
      // Handle chat message - mark as delivered
      String chatRoomId = message.data['chatRoomId'] ?? '';
      String senderId = message.data['senderId'] ?? '';

      if (chatRoomId.isNotEmpty && senderId.isNotEmpty) {
        try {
          await Firebase.initializeApp();
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
    } else {
      // Handle call notification
      String callerId = message.data['callerId'] ?? 'Unknown';
      String channelId = message.data['channelId'] ?? '';
      await _showCallNotification(callerId, channelId);
    }
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
