import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_chat_app/main.dart';
import 'package:video_chat_app/screens/public_profile_screen.dart';
import 'package:video_chat_app/services/profile_link_router.dart';

/// Handles `https://gupshupgo.app/u/<username>` profile links — from a QR
/// scan, a shared link, or Android's autoVerify app-link intent filter.
///
/// If the app is already signed in when the link arrives, navigates
/// straight to [PublicProfileScreen]. If not (cold start before auth
/// resolves, or the user is on the login screen), the username is queued
/// and HomeScreen releases it once authentication and onboarding are ready.
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  late final _router = ProfileLinkRouter(openProfile: _openProfile);

  bool get hasPendingLink => _router.hasPendingLink;

  /// Home calls this after auth, onboarding and startup dialogs have settled.
  void setRoutingReady(bool ready) => _router.setReady(ready);

  /// Starts listening for both the very first link (cold start) and any
  /// subsequent links while the app is running. Safe to call once, after
  /// the first frame so [navigatorKey] is guaranteed to be mounted.
  Future<void> init() async {
    if (_sub != null) return; // already initialised

    // Subscribe before reading the launch intent so a warm intent cannot fall
    // into the asynchronous gap. The router deduplicates the launch delivery.
    _sub = _appLinks.uriLinkStream.listen(
      _router.receive,
      onError: (e) => debugPrint('[DeepLink] stream error: $e'),
    );

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _router.receive(initialUri);
      }
    } catch (e) {
      debugPrint('[DeepLink] failed to read initial link: $e');
    }
  }

  /// Extracts the handle from a `/u/<username>` path. Returns null for any
  /// URL that doesn't match the expected profile-link shape.
  ///
  /// Public and static so the QR scanner validates scanned codes with exactly
  /// the same rule that the deep-link handler uses — otherwise a code that
  /// scans fine could fail when the same link is tapped, or vice versa.
  static String? extractUsername(Uri uri) {
    return ProfileLinkRouter.extractUsername(uri);
  }

  bool _openProfile(String username) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final nav = navigatorKey.currentState;
    if (nav == null || currentUserId == null) return false;
    nav.push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          username: username,
          currentUserId: currentUserId,
        ),
      ),
    );
    return true;
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
