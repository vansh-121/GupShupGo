import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/provider/call_state_provider.dart';
import 'package:video_chat_app/provider/status_provider.dart';
import 'package:video_chat_app/services/auth_service.dart';
import 'package:video_chat_app/screens/auth/login_screen.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        appBarTheme: AppBarTheme(
          elevation: 1,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      home: FutureBuilder<bool>(
        future: _authService.isUserLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
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
