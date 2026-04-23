import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:http/http.dart' as http;

class FCMService {
  // ── Cloud Function endpoints (no service account key needed) ────────────
  static const _callFunctionUrl =
      'https://sendcallnotification-luh3g2lkma-uc.a.run.app';
  static const _messageFunctionUrl =
      'https://sendmessagenotification-luh3g2lkma-uc.a.run.app';

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
      // NOTE: Foreground call messages are handled by onCallReceived() in
      // HomeScreen. Chat messages are handled by StreamBuilder. No extra
      // onMessage listener is needed here — adding one would cause duplicate
      // navigations for incoming calls.
    } catch (e) {
      print('FCM setup error: $e');
    }
  }

  void onCallReceived(void Function(String, String, bool) callback) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message received in onCallReceived: ${message.data}');
      String messageType = message.data['type'] ?? '';
      String channelId = message.data['channelId'] ?? '';

      // Only trigger callback for call messages, not chat messages
      if (messageType == 'call' ||
          messageType == 'incoming_call' ||
          (messageType.isEmpty && channelId.isNotEmpty)) {
        String callerId = message.data['callerId'] ?? 'Unknown';
        bool isAudioOnly = message.data['isAudioOnly'] == 'true';
        print(
            'Call notification - callerId: $callerId, channelId: $channelId, isAudioOnly: $isAudioOnly');
        callback(callerId, channelId, isAudioOnly);
      } else {
        print('Ignoring non-call message of type: $messageType');
      }
    });
  }

  /// Send call notification via Cloud Function (no service account needed).
  Future<void> sendCallNotification(
      String calleeId, String callerId, String channelId,
      {bool isAudioOnly = false}) async {
    try {
      print('Sending call notification to $calleeId via Cloud Function');
      final response = await http.post(
        Uri.parse(_callFunctionUrl),
        headers: {'Content-Type': 'application/json'},
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
      final response = await http.post(
        Uri.parse(_messageFunctionUrl),
        headers: {'Content-Type': 'application/json'},
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
            print(
                'Messages and chatRoom marked as delivered for: $chatRoomId');
          }
        } catch (e) {
          print('Error marking messages as delivered: $e');
        }
      }
    } else if (messageType == 'call' || messageType == 'incoming_call') {
      // Handle call notification
      String callerId = message.data['callerId'] ?? 'Unknown';
      String channelId = message.data['channelId'] ?? '';
      bool isAudioOnly = message.data['isAudioOnly'] == 'true';
      if (channelId.isNotEmpty) {
        await _showCallNotification(callerId, channelId,
            isAudioOnly: isAudioOnly);
      }
    }
  }

  static Future<void> _showCallNotification(String callerId, String channelId,
      {bool isAudioOnly = false}) async {
    try {
      await FlutterCallkitIncoming.showCallkitIncoming(
        CallKitParams(
          id: channelId,
          nameCaller: callerId,
          appName: 'GupShupGo',
          type: isAudioOnly ? 0 : 1, // 0 = Audio call, 1 = Video call
          textAccept: 'Accept',
          textDecline: 'Decline',
        ),
      );
      print(
          'Call notification shown for $callerId (${isAudioOnly ? 'Audio' : 'Video'})');
    } catch (e) {
      print('Error showing call notification: $e');
    }
  }
}
