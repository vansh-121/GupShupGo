import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_chat_app/main.dart';
import 'package:video_chat_app/services/fcm_service.dart';

// ─── Notification Preference Keys ─────────────────────────────────────────────
class NotifPrefs {
  static const streakWarnings = 'notif_streak_warnings';
  static const streakMilestones = 'notif_streak_milestones';
  static const gupPoints = 'notif_gup_points';
  static const dailyDigest = 'notif_daily_digest';
  static const unreadReminder = 'notif_unread_reminder';
}

// ─── Android Notification Channels ────────────────────────────────────────────
const _streakChannel = AndroidNotificationChannel(
  'streak_notifications',
  'Bond Notifications',
  description: 'Alerts about your streaks — warnings, breaks, and milestones',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
  ledColor: Colors.orange,
);

const _pointsChannel = AndroidNotificationChannel(
  'points_notifications',
  'Gup Points',
  description: 'Notifications when you earn Gup Points rewards',
  importance: Importance.defaultImportance,
  playSound: true,
);

const _chatMessageChannel = AndroidNotificationChannel(
  'chat_message_notifications',
  'Chat Messages',
  description: 'Notifications for incoming chat messages',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
);

const _reminderChannel = AndroidNotificationChannel(
  'reminder_notifications',
  'Reminders',
  description: 'Unread message reminders and engagement nudges',
  importance: Importance.low,
  playSound: false,
);

const _digestChannel = AndroidNotificationChannel(
  'digest_notifications',
  'Daily Digest',
  description: 'Your daily GupShupGo morning summary',
  importance: Importance.low,
  playSound: false,
);

// ─── NotificationService ───────────────────────────────────────────────────────
/// Central service for:
///  1. Initialising flutter_local_notifications (channels, tap handler)
///  2. Showing local notifications for foreground FCM messages
///  3. Routing notification taps → correct screen via navigatorKey
///  4. Reading / writing user notification preferences
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// The chatRoomId of the currently-open chat screen.
  /// When set, foreground chat notifications for this room are suppressed
  /// to avoid duplicate alerts while the user is already viewing the chat.
  static String? activeChatRoomId;

  // ─── Initialise ─────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Android: use the app launcher icon for notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // already handled by firebase_messaging
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    // Register Android channels
    if (Platform.isAndroid) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_streakChannel);
      await androidPlugin?.createNotificationChannel(_pointsChannel);
      await androidPlugin?.createNotificationChannel(_chatMessageChannel);
      await androidPlugin?.createNotificationChannel(_reminderChannel);
      await androidPlugin?.createNotificationChannel(_digestChannel);
    }

    // Handle tap when app was TERMINATED (notification opened cold start)
    final NotificationAppLaunchDetails? launchDetails =
        await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final payload = launchDetails?.notificationResponse?.payload;
      if (payload != null) {
        // Slight delay so the app finishes building before we navigate
        Future.delayed(const Duration(milliseconds: 800), () {
          _navigateFromPayload(payload);
        });
      }
    }

    // Handle tap on FCM notification when app was in BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _navigateFromData(message.data);
    });

    // Handle FCM that opened app from TERMINATED state
    final initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(milliseconds: 800), () {
        _navigateFromData(initialMessage.data);
      });
    }
  }

  // ─── Foreground FCM Handler ──────────────────────────────────────────────────
  /// Call this from FCMService.onMessage for all non-call notification types.
  Future<void> handleForegroundMessage(RemoteMessage message) async {
    final type = message.data['type'] ?? '';
    final prefs = await SharedPreferences.getInstance();

    // Check user preferences before showing
    if (!_shouldShow(type, prefs)) return;

    final notification = message.notification;
    final title = notification?.title ?? _defaultTitle(type);
    final body = notification?.body ?? '';
    final payload = jsonEncode(message.data);

    await showLocalNotification(
      id: _idForType(type),
      title: title,
      body: body,
      channelId: _channelForType(type),
      payload: payload,
    );
  }

  /// Shows a local notification for an incoming chat message.
  /// Suppressed if the user is currently viewing the same chat.
  Future<void> handleChatMessage(RemoteMessage message) async {
    final chatRoomId = message.data['chatRoomId'] ?? '';

    // Don't notify if the user is already viewing this chat
    if (chatRoomId.isNotEmpty && chatRoomId == activeChatRoomId) return;

    final senderName = message.data['senderName'] ?? 'Someone';
    final body = message.notification?.body ??
        message.data['message'] ?? 'Sent a message';
    final payload = jsonEncode(message.data);

    // Use a unique ID per sender so subsequent messages update the same notification
    final senderId = message.data['senderId'] ?? '';
    final notifId = senderId.hashCode.abs() % 100000 + 2000;

    await showLocalNotification(
      id: notifId,
      title: senderName,
      body: body,
      channelId: 'chat_message_notifications',
      payload: payload,
    );
  }

  // ─── Show a Local Notification ───────────────────────────────────────────────
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      _channelNameFor(channelId),
      importance: channelId == 'streak_notifications'
          ? Importance.high
          : Importance.defaultImportance,
      priority: channelId == 'streak_notifications'
          ? Priority.high
          : Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
      playSound: channelId != 'digest_notifications',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  // ─── Notification Preferences ────────────────────────────────────────────────
  Future<Map<String, bool>> getPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      NotifPrefs.streakWarnings: prefs.getBool(NotifPrefs.streakWarnings) ?? true,
      NotifPrefs.streakMilestones: prefs.getBool(NotifPrefs.streakMilestones) ?? true,
      NotifPrefs.gupPoints: prefs.getBool(NotifPrefs.gupPoints) ?? true,
      NotifPrefs.dailyDigest: prefs.getBool(NotifPrefs.dailyDigest) ?? true,
      NotifPrefs.unreadReminder: prefs.getBool(NotifPrefs.unreadReminder) ?? true,
    };
  }

  Future<void> setPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // ─── Private Helpers ─────────────────────────────────────────────────────────

  bool _shouldShow(String type, SharedPreferences prefs) {
    return switch (type) {
      'streak_warning' || 'streak_broken' =>
        prefs.getBool(NotifPrefs.streakWarnings) ?? true,
      'streak_milestone' => prefs.getBool(NotifPrefs.streakMilestones) ?? true,
      'gup_points_earned' => prefs.getBool(NotifPrefs.gupPoints) ?? true,
      'daily_digest' => prefs.getBool(NotifPrefs.dailyDigest) ?? true,
      'unread_reminder' => prefs.getBool(NotifPrefs.unreadReminder) ?? true,
      _ => true,
    };
  }

  String _channelForType(String type) {
    return switch (type) {
      'streak_warning' || 'streak_broken' || 'streak_milestone' =>
        'streak_notifications',
      'gup_points_earned' => 'points_notifications',
      'chat_message' => 'chat_message_notifications',
      'unread_reminder' => 'reminder_notifications',
      'daily_digest' => 'digest_notifications',
      _ => 'streak_notifications',
    };
  }

  String _channelNameFor(String channelId) {
    return switch (channelId) {
      'streak_notifications' => 'Bond Notifications',
      'points_notifications' => 'Gup Points',
      'chat_message_notifications' => 'Chat Messages',
      'reminder_notifications' => 'Reminders',
      'digest_notifications' => 'Daily Digest',
      _ => 'GupShupGo',
    };
  }

  int _idForType(String type) {
    return switch (type) {
      'streak_warning' => 1001,
      'streak_broken' => 1002,
      'streak_milestone' => 1003,
      'gup_points_earned' => 1004,
      'chat_message' => 1007,
      'unread_reminder' => 1005,
      'daily_digest' => 1006,
      _ => 1000,
    };
  }

  String _defaultTitle(String type) {
    return switch (type) {
      'streak_warning' => '⚠️ Bond at Risk!',
      'streak_broken' => '💔 Bond Broken',
      'streak_milestone' => '🏆 Bond Milestone!',
      'gup_points_earned' => '⚡ Gup Points Earned!',
      'chat_message' => '💬 New Message',
      'unread_reminder' => '💬 Unread Messages',
      'daily_digest' => '🌅 Good Morning!',
      _ => 'GupShupGo',
    };
  }

  // ─── Navigation ──────────────────────────────────────────────────────────────

  void _onLocalNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        _navigateFromData(data);
      } catch (_) {}
    }
  }

  void _navigateFromPayload(String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _navigateFromData(data);
    } catch (_) {}
  }

  static void _navigateFromData(Map<String, dynamic> data) {
    final screen = data['screen'] as String? ?? '';
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    switch (screen) {
      case 'chat':
        final chatRoomId = data['chatRoomId'] as String? ?? '';
        final contactId = data['contactId'] as String? ?? '';
        if (chatRoomId.isNotEmpty) {
          // Navigate to home first, then open the specific chat
          // The home screen will handle deep-linking into the chat
          nav.pushNamedAndRemoveUntil('/', (route) => false);
          // Store pending navigation so HomeScreen can open the chat on mount
          _pendingChatDeepLink = contactId;
        }
        break;

      case 'arcade':
        nav.pushNamedAndRemoveUntil('/', (route) => false);
        _pendingTabDeepLink = 1; // index of Arcade tab
        break;

      case 'screen_share':
        final channelId = data['channelId'] as String? ?? '';
        final sharerName = data['sharerName'] as String? ?? 'Someone';
        FCMService.openScreenShareViewer(
          channelId: channelId,
          sharerName: sharerName,
        );
        break;

      case 'home':
      default:
        nav.pushNamedAndRemoveUntil('/', (route) => false);
        break;
    }
  }

  // Pending deep link — HomeScreen reads these after mount
  static String? _pendingChatDeepLink;
  static int? _pendingTabDeepLink;

  static String? consumePendingChatDeepLink() {
    final v = _pendingChatDeepLink;
    _pendingChatDeepLink = null;
    return v;
  }

  static int? consumePendingTabDeepLink() {
    final v = _pendingTabDeepLink;
    _pendingTabDeepLink = null;
    return v;
  }
}
