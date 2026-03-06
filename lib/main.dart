import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/provider/call_state_provider.dart';
import 'package:video_chat_app/provider/status_provider.dart';
import 'package:video_chat_app/services/auth_service.dart';
import 'package:video_chat_app/screens/auth/login_screen.dart';
import 'package:video_chat_app/theme/app_theme.dart';

import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize Firebase App Check
  // Uses Debug provider in debug mode, Play Integrity in release
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.deviceCheck,
    );

    if (kDebugMode) {
      // Get and print the debug token so you can register it in Firebase Console
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

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GupShupGo',
      theme: AppTheme.light,
      home: FutureBuilder<bool>(
        future: _authService.isUserLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _SplashScreen();
          }

          if (snapshot.data == true) {
            return HomeScreen();
          } else {
            return LoginScreen();
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6C5CE7), Color(0xFF9B8FF0)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'GupShupGo',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Stay connected with everyone',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
              const SizedBox(height: 52),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: Colors.white.withOpacity(0.85),
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
