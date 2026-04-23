import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_chat_app/provider/call_state_provider.dart';
import 'package:video_chat_app/provider/status_provider.dart';
import 'package:video_chat_app/services/auth_service.dart';
import 'package:video_chat_app/screens/auth/login_screen.dart';
import 'package:video_chat_app/theme/app_theme.dart';

import 'screens/home_screen.dart';

/// Globally cached SharedPreferences instance — initialised once in main().
late final SharedPreferences sharedPrefs;

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CallStateNotifier()),
        ChangeNotifierProvider(create: (_) => StatusProvider()),
      ],
      child: MyApp(),
    ),
  );
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

    return MaterialApp(
      title: 'GupShupGo',
      theme: AppTheme.light,
      home: isLoggedIn ? HomeScreen() : LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
