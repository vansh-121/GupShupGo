import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
import 'package:video_chat_app/services/call_signaling_service.dart';
import 'package:video_chat_app/services/chat_cache_service.dart';
import 'package:video_chat_app/services/fcm_service.dart';
import 'package:video_chat_app/services/mesh_network_service.dart';
import 'package:video_chat_app/screens/auth/login_screen.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/widgets/mesh_notification_listener.dart';

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

  // ── Firebase Crashlytics — capture all unhandled errors ────────────────
  // Enable collection on non-debug builds; disable in debug so local errors
  // are easier to iterate on (they still appear in the Crashlytics console
  // but are tagged as debug events).
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);

  // 1️⃣  Flutter framework errors (widget build errors, layout overflow, etc.)
  FlutterError.onError = (FlutterErrorDetails details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  // 2️⃣  Platform-level uncaught async errors (Zone boundary escapes)
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true; // mark as handled so the app doesn't also crash the isolate
  };

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

  // 3️⃣  Wrap runApp in a guarded zone — catches synchronous throws that
  //     escape both FlutterError.onError and PlatformDispatcher.onError.
  runZonedGuarded(
    () {
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
    },
    (Object error, StackTrace stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
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
        // If IncomingCallScreen is showing, it handles the decline itself
        // (including the Firestore update). Otherwise (background / killed),
        // we must signal Firestore here so the caller sees "Call Declined".
        if (!FCMService.isIncomingCallScreenShowing) {
          final channelId = _extractChannelId(event.body);
          if (channelId.isNotEmpty) {
            CallSignalingService.declineCall(channelId);
          }
        }
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

/// Extracts the channelId from a CallKit event body.
String _extractChannelId(dynamic body) {
  if (body == null) return '';
  final Map<String, dynamic> data =
      body is Map ? Map<String, dynamic>.from(body) : {};
  final rawExtra = data['extra'];
  final Map<String, dynamic> extra = rawExtra is Map
      ? Map<String, dynamic>.from(rawExtra)
      : <String, dynamic>{};
  return extra['channelId'] as String? ?? data['id'] as String? ?? '';
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

  // When the app is in the foreground, IncomingCallScreen is already showing
  // and will handle the accept itself (pushReplacement → CallScreen).
  // If we ALSO push CallScreen here, we get a duplicate.  Skip this path
  // when IncomingCallScreen is active.
  if (FCMService.isIncomingCallScreenShowing) {
    print('IncomingCallScreen is handling this accept — skipping global handler');
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
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      navigatorKey: navigatorKey, // Enables navigation from CallKit handler
      title: 'GupShupGo',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      builder: (context, child) =>
          MeshNotificationListener(child: child ?? const SizedBox.shrink()),
      home: _AuthGate(authService: _authService),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Decides Home vs. Login on launch and on auth state changes.
///
/// Decision flow:
///   • Firebase Auth has a hydrated user → HomeScreen.
///   • Firebase Auth is empty AND local prefs say we're logged in
///     (e.g. cached user_id, possibly restored from Drive Auto Backup on a
///     fresh install) → try [attemptSilentReauth]. Succeeds for Google
///     users; for phone-only users it returns false, in which case the
///     prefs are stale → clear them and show LoginScreen.
///   • Otherwise → LoginScreen.
class _AuthGate extends StatefulWidget {
  final AuthService authService;
  const _AuthGate({required this.authService});

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  // null = still resolving the initial auth state.
  bool? _resolvedLoggedIn;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  // True iff the gate let the user into Home without a live Firebase session
  // (offline cold start). We need to repair that session as soon as the
  // network is back, otherwise every Firestore query stays permission-denied.
  bool _needsReauthOnReconnect = false;
  bool _reauthInFlight = false;

  @override
  void initState() {
    super.initState();
    _resolveInitialAuth();
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isOnline = results.any((r) => r != ConnectivityResult.none);
    if (!isOnline) return;
    if (!_needsReauthOnReconnect) return;
    if (_reauthInFlight) return;
    if (FirebaseAuth.instance.currentUser != null) {
      _needsReauthOnReconnect = false;
      return;
    }
    _repairSessionAfterReconnect();
  }

  Future<void> _repairSessionAfterReconnect() async {
    _reauthInFlight = true;
    try {
      final ok = await widget.authService.attemptSilentReauth();
      if (ok) {
        // Firebase Auth restored. Firestore SDK auto-resubscribes any open
        // streams once the new ID token is in hand, so existing screens
        // recover on their own. One-shot FutureBuilders (e.g. Contacts)
        // recover on their next "Try again" / pull-to-refresh.
        _needsReauthOnReconnect = false;
      }
      // Silent re-auth failed (phone-only user, or no matching Google account
      // on device). We deliberately do NOT sign the user out or redirect to
      // login here — that destroys context and wipes cached chats they were
      // in the middle of reading. The user stays on Home with whatever cached
      // data we have. Live queries (new chats, contacts list) will keep
      // failing with permission-denied until they sign in again, but they
      // can still browse history and use offline mesh chat in the meantime.
      // Leave _needsReauthOnReconnect true so we'll retry on the next
      // connectivity bounce — no harm in trying again.
    } finally {
      _reauthInFlight = false;
    }
  }

  Future<void> _resolveInitialAuth() async {
    // Auto Backup is disabled (AndroidManifest android:allowBackup="false"),
    // so SharedPreferences cannot be restored from Drive onto a fresh install.
    // That makes "user_id is in prefs" a reliable signal that this user
    // actually signed in on THIS install — and we can trust it as the sole
    // source of truth for routing without any network round-trip.
    final hasLocalSession = sharedPrefs.getString('user_id') != null;
    _setResolved(hasLocalSession);

    if (!hasLocalSession) return;

    // If Firebase Auth has no user (MIUI cleared the store, or app was
    // killed before currentUser hydrated, etc.), try a silent re-auth in
    // the background. Works for Google users; for phone-only users the
    // attempt is a no-op and the re-verify banner on Home invites them
    // to re-verify when convenient.
    if (FirebaseAuth.instance.currentUser == null) {
      _needsReauthOnReconnect = true;
      // Fire-and-forget — never blocks Home from showing.
      // ignore: discarded_futures
      widget.authService.attemptSilentReauth().then((ok) {
        if (ok) _needsReauthOnReconnect = false;
      });
    }
  }

  void _setResolved(bool loggedIn) {
    if (!mounted) return;
    setState(() => _resolvedLoggedIn = loggedIn);
  }

  @override
  Widget build(BuildContext context) {
    if (_resolvedLoggedIn == null) {
      // Tiny splash while we resolve auth — usually a single frame.
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _resolvedLoggedIn! ? HomeScreen() : LoginScreen();
  }
}
