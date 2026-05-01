import 'dart:math';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_chat_app/provider/call_state_provider.dart';
import 'package:video_chat_app/provider/connectivity_provider.dart';
import 'package:video_chat_app/provider/status_provider.dart';
import 'package:video_chat_app/provider/theme_provider.dart';
import 'package:video_chat_app/screens/call_screen.dart';
import 'package:video_chat_app/services/auth_service.dart';
import 'package:video_chat_app/services/chat_cache_service.dart';
import 'package:video_chat_app/services/mesh_network_service.dart';
import 'package:video_chat_app/screens/auth/login_screen.dart';
import 'package:video_chat_app/theme/app_theme.dart';

import 'screens/home_screen.dart';

/// Globally cached SharedPreferences instance — initialised once in main().
late final SharedPreferences sharedPrefs;

/// Global navigator key — used by CallKit to navigate from outside the
/// widget tree (e.g., when accepting a call from the lock screen).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Disable runtime font fetching — we bundle Poppins locally ──
  GoogleFonts.config.allowRuntimeFetching = false;

  // ── Run Firebase init and SharedPreferences init in parallel ──
  await Future.wait([
    Firebase.initializeApp(),
    SharedPreferences.getInstance().then((prefs) => sharedPrefs = prefs),
  ]);

  // ── App Check: fire-and-forget (don't block startup) ──
  _initAppCheck();

  // ── Register CallKit event listener BEFORE runApp() ──────────────────
  // This catches accept/decline/timeout events even when the app is cold-
  // started from a notification tap (the user tapped "Accept" on the lock
  // screen, which launched the app).
  _setupCallKitListener();

  final connectivityProvider = ConnectivityProvider();

  // ── Stable per-install ID + display name for mesh, used both pre-auth
  //    (guest mesh chat from the login screen) and as the default before
  //    the real userId is wired in via updateUserId() on home screen entry.
  final meshIdentity = _ensureMeshGuestIdentity();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CallStateNotifier()),
        ChangeNotifierProvider(create: (_) => StatusProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: connectivityProvider),
        ChangeNotifierProvider(
          create: (_) => MeshNetworkService(
            currentUserId: meshIdentity.guestId,
            displayName: meshIdentity.displayName,
            cacheService: ChatCacheService(),
            connectivityProvider: connectivityProvider,
          ),
        ),
      ],
      child: MyApp(),
    ),
  );

  // ── Cold-start: check for calls accepted while the app was dead ────────
  // When the user taps "Accept" on the native CallKit notification and the
  // app was killed, the actionCallAccept event fires BEFORE our listener is
  // registered. We catch that case here by querying active calls after the
  // navigator is mounted.
  _checkPendingAcceptedCalls();
}

// ═══════════════════════════════════════════════════════════════════════════════
// CallKit event listener — handles Accept / Decline / Timeout / End
// ═══════════════════════════════════════════════════════════════════════════════

void _setupCallKitListener() {
  FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
    if (event == null) return;

    print('CallKit event: ${event.event} | body: ${event.body}');

    switch (event.event) {
      case Event.actionCallAccept:
        _handleCallAccepted(event.body);
        break;
      case Event.actionCallDecline:
        print('Call declined by user');
        // CallKit auto-dismisses; nothing else needed.
        break;
      case Event.actionCallTimeout:
        print('Call timed out (not answered)');
        // CallKit auto-shows "Missed call" notification.
        break;
      case Event.actionCallEnded:
        print('Call ended');
        break;
      default:
        break;
    }
  });
}

/// Navigates to CallScreen when the user taps "Accept" on the CallKit UI.
///
/// Works in all scenarios:
/// - App in foreground → navigates immediately
/// - App in background → brings app to foreground, then navigates
/// - App killed → app launches, then navigates once the navigator is ready
void _handleCallAccepted(dynamic body) {
  if (body == null) return;

  // flutter_callkit_incoming returns body as Map<String, dynamic>.
  // The CallKitParams.extra map is nested inside body['extra'].
  final Map<String, dynamic> data =
      body is Map ? Map<String, dynamic>.from(body) : {};

  final rawExtra = data['extra'];
  final Map<String, dynamic> extra = rawExtra is Map
      ? Map<String, dynamic>.from(rawExtra)
      : <String, dynamic>{};

  final channelId =
      extra['channelId'] as String? ?? data['id'] as String? ?? '';
  final callerId = extra['callerId'] as String? ?? '';
  final isAudioOnly = extra['isAudioOnly'] == 'true';
  final callerName = data['nameCaller'] as String? ?? 'Unknown';

  if (channelId.isEmpty) {
    print('Cannot navigate to call: channelId is empty');
    return;
  }

  print('Accepting call → channelId: $channelId, caller: $callerName');

  // Use a post-frame callback to ensure the navigator is mounted.
  // This handles the cold-start case where the widget tree isn't built yet.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final nav = navigatorKey.currentState;
    if (nav != null) {
      nav.push(
        MaterialPageRoute(
          builder: (_) => CallScreen(
            channelId: channelId,
            isCaller: false,
            calleeId: callerId,
            calleeName: callerName,
            isAudioOnly: isAudioOnly,
          ),
        ),
      );
    } else {
      print('Navigator not ready — cannot navigate to call screen');
    }
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// Cold-start handler — checks if the app was launched by accepting a call
// ═══════════════════════════════════════════════════════════════════════════════

/// On cold-start (app was killed), the CallKit "Accept" event fires BEFORE
/// our Dart listener is registered. This function runs after the first frame
/// and checks [FlutterCallkitIncoming.activeCalls()] for any call that was
/// accepted. If found, it navigates to CallScreen.
void _checkPendingAcceptedCalls() {
  // Wait for the navigator to be mounted (first frame)
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      final dynamic calls = await FlutterCallkitIncoming.activeCalls();
      print('Active calls on startup: $calls');

      if (calls == null || calls is! List || calls.isEmpty) return;

      // Take the most recent active call
      final Map<String, dynamic> call = Map<String, dynamic>.from(calls.last);

      final rawExtra = call['extra'];
      final Map<String, dynamic> extra = rawExtra is Map
          ? Map<String, dynamic>.from(rawExtra)
          : <String, dynamic>{};

      final channelId =
          extra['channelId'] as String? ?? call['id'] as String? ?? '';
      final callerId = extra['callerId'] as String? ?? '';
      final isAudioOnly = extra['isAudioOnly'] == 'true';
      final callerName = call['nameCaller'] as String? ?? 'Unknown';

      if (channelId.isEmpty) return;

      print('Cold-start: found pending call → $channelId from $callerName');

      // End the CallKit notification (stop ringtone if still playing)
      await FlutterCallkitIncoming.endCall(channelId);

      // Navigate to CallScreen
      final nav = navigatorKey.currentState;
      if (nav != null) {
        nav.push(
          MaterialPageRoute(
            builder: (_) => CallScreen(
              channelId: channelId,
              isCaller: false,
              calleeId: callerId,
              calleeName: callerName,
              isAudioOnly: isAudioOnly,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error checking pending calls: $e');
    }
  });
}
/// Stable identity for the mesh service, kept in SharedPreferences so it
/// persists across launches even before (or without) signing in.
class _MeshGuestIdentity {
  final String guestId;
  final String displayName;
  const _MeshGuestIdentity(this.guestId, this.displayName);
}

_MeshGuestIdentity _ensureMeshGuestIdentity() {
  const idKey = 'mesh_guest_id';
  const nameKey = 'mesh_guest_name';

  String? id = sharedPrefs.getString(idKey);
  if (id == null || id.isEmpty) {
    final rng = Random.secure();
    final bytes = List<int>.generate(8, (_) => rng.nextInt(256));
    final hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    id = 'g_$hex';
    sharedPrefs.setString(idKey, id);
  }

  String name = sharedPrefs.getString(nameKey) ?? '';
  if (name.isEmpty) name = 'Guest ${id.substring(2, 6)}';

  return _MeshGuestIdentity(id, name);
}

/// Runs App Check activation in the background — never blocks the UI.
void _initAppCheck() async {
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.deviceCheck,
    );

    if (kDebugMode) {
      final token = await FirebaseAppCheck.instance.getToken();
      print('═══════════════════════════════════════════════════════');
      print('🔑 APP CHECK DEBUG TOKEN: $token');
      print('═══════════════════════════════════════════════════════');
      print('👆 Copy this token and add it in Firebase Console:');
      print('   App Check → Apps → Manage debug tokens → Add');
      print('═══════════════════════════════════════════════════════');
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ App Check initialization failed: $e');
      print('   Phone auth may fall back to reCAPTCHA flow.');
    }
  }
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = _authService.isUserLoggedIn();
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      navigatorKey: navigatorKey, // Enables navigation from CallKit handler
      title: 'GupShupGo',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      home: isLoggedIn ? HomeScreen() : LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
