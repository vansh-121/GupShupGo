import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Maintains a "remember this device" session token, stored in Android
/// Keystore-backed secure storage, that the app can trade for a Firebase
/// custom token when Firebase Auth's own session is gone.
///
/// This is the same pattern WhatsApp uses to keep users signed in across
/// OS-level data wipes, MIUI/HyperOS force-stop cleanups, and any other
/// path that drops Firebase's internal token store. It works uniformly
/// for phone, Google, and email/password users — the server only cares
/// about the uid behind the token, not how the user originally signed in.
class DeviceSessionService {
  static const _issueUrl =
      'https://us-central1-videocallapp-81166.cloudfunctions.net/issueDeviceSession';
  static const _exchangeUrl =
      'https://us-central1-videocallapp-81166.cloudfunctions.net/exchangeDeviceSession';
  static const _revokeUrl =
      'https://us-central1-videocallapp-81166.cloudfunctions.net/revokeDeviceSession';

  static const _tokenKey = 'gsg_device_session_token_v1';

  // Keystore-backed; uses EncryptedSharedPreferences on Android.
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Returns the locally stored token, or null if there isn't one.
  Future<String?> _readToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> _deleteToken() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {}
  }

  /// True iff we have a persisted device session token on this device.
  Future<bool> hasToken() async => (await _readToken()) != null;

  /// Calls [issueDeviceSession] using the user's current Firebase ID token,
  /// then persists the returned raw token in secure storage. Safe to call
  /// after every successful sign-in — overwrites any prior token.
  Future<bool> issueAndPersist() async {
    try {
      final idToken =
          await FirebaseAuth.instance.currentUser?.getIdToken(true);
      if (idToken == null) return false;

      final response = await http.post(
        Uri.parse(_issueUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'platform': Platform.operatingSystem,
          'deviceLabel': Platform.operatingSystemVersion,
        }),
      );
      if (response.statusCode != 200) {
        print('issueDeviceSession failed: ${response.statusCode} ${response.body}');
        return false;
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final token = body['token'] as String?;
      if (token == null || token.isEmpty) return false;
      await _writeToken(token);
      return true;
    } catch (e) {
      print('issueAndPersist error: $e');
      return false;
    }
  }

  /// Trades the locally stored token for a Firebase custom token and signs
  /// into Firebase Auth with it. Returns the restored uid on success.
  ///
  /// Reasons this can return null:
  ///   • No local token (user never signed in on this install)
  ///   • Token revoked server-side or user account deleted
  ///   • Network failure
  Future<String?> exchangeAndSignIn() async {
    try {
      final token = await _readToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse(_exchangeUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 401) {
        // Token is no longer valid — purge it so we don't keep retrying.
        await _deleteToken();
        return null;
      }
      if (response.statusCode != 200) {
        print('exchangeDeviceSession failed: ${response.statusCode} ${response.body}');
        return null;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final customToken = body['customToken'] as String?;
      if (customToken == null) return null;

      final cred =
          await FirebaseAuth.instance.signInWithCustomToken(customToken);
      return cred.user?.uid;
    } catch (e) {
      print('exchangeAndSignIn error: $e');
      return null;
    }
  }

  /// Revokes the server-side session and clears the local token. Best-effort:
  /// always clears local state even if the network call fails (so the next
  /// startup won't try to reuse a token the user just signed out from).
  Future<void> revokeAndClear() async {
    final token = await _readToken();
    await _deleteToken();
    if (token == null) return;

    try {
      final idToken =
          await FirebaseAuth.instance.currentUser?.getIdToken();
      await http.post(
        Uri.parse(_revokeUrl),
        headers: {
          'Content-Type': 'application/json',
          if (idToken != null) 'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'token': token}),
      );
    } catch (e) {
      print('revokeAndClear network error (ignored): $e');
    }
  }
}
