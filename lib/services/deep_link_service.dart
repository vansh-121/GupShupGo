import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_chat_app/main.dart';
import 'package:video_chat_app/screens/public_profile_screen.dart';

/// Handles `https://gupshupgo.app/u/<username>` profile links — from a QR
/// scan, a shared link, or Android's autoVerify app-link intent filter.
///
/// If the app is already signed in when the link arrives, navigates
/// straight to [PublicProfileScreen]. If not (cold start before auth
/// resolves, or the user is on the login screen), the username is queued
/// and [consumePendingUsername] lets HomeScreen open it once the user is
/// authenticated.
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  static String? _pendingUsername;

  /// Starts listening for both the very first link (cold start) and any
  /// subsequent links while the app is running. Safe to call once, after
  /// the first frame so [navigatorKey] is guaranteed to be mounted.
  Future<void> init() async {
    if (_sub != null) return; // already initialised

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (e) {
      debugPrint('[DeepLink] failed to read initial link: $e');
    }

    _sub = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (e) => debugPrint('[DeepLink] stream error: $e'),
    );
  }

  void _handleUri(Uri uri) {
    final username = _extractUsername(uri);
    if (username == null || username.isEmpty) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      // Not signed in yet — HomeScreen (or the login flow, once signed in)
      // will pick this up via consumePendingUsername().
      _pendingUsername = username;
      return;
    }

    _openProfile(username, currentUserId);
  }

  /// Extracts the handle from a `/u/<username>` path. Returns null for any
  /// URL that doesn't match the expected profile-link shape.
  String? _extractUsername(Uri uri) {
    final segments = uri.pathSegments;
    final uIndex = segments.indexOf('u');
    if (uIndex == -1 || uIndex + 1 >= segments.length) return null;
    return segments[uIndex + 1];
  }

  void _openProfile(String username, String currentUserId) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          username: username,
          currentUserId: currentUserId,
        ),
      ),
    );
  }

  /// Called by HomeScreen after it has an authenticated `_currentUserId` so
  /// a profile link tapped before login still opens once the user signs in.
  static String? consumePendingUsername() {
    final v = _pendingUsername;
    _pendingUsername = null;
    return v;
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
