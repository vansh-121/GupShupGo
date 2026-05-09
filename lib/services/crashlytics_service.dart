import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper around [FirebaseCrashlytics] that exposes a clean,
/// import-friendly API for the rest of the GupShupGo codebase.
///
/// Usage examples:
/// ```dart
/// // After sign-in
/// CrashlyticsService.setUser(uid: user.uid, name: user.displayName);
///
/// // Inside a catch block you want to track but not crash on
/// CrashlyticsService.logError(e, stack, reason: 'Failed to upload avatar');
///
/// // Breadcrumb before a risky operation
/// CrashlyticsService.log('Agora engine initialising for channel $channelId');
/// ```
class CrashlyticsService {
  CrashlyticsService._(); // static-only

  static final _c = FirebaseCrashlytics.instance;

  // ── User identity ────────────────────────────────────────────────────────

  /// Attach the signed-in user's identity to future crash reports.
  /// Call after login and clear on logout.
  static Future<void> setUser({
    required String uid,
    String? name,
    String? phone,
  }) async {
    if (kDebugMode) return; // don't tag debug runs
    await _c.setUserIdentifier(uid);
    if (name != null) await _c.setCustomKey('user_name', name);
    if (phone != null) await _c.setCustomKey('user_phone', phone);
  }

  /// Clear user identity on sign-out.
  static Future<void> clearUser() async {
    await _c.setUserIdentifier('');
  }

  // ── Non-fatal error logging ──────────────────────────────────────────────

  /// Record a caught exception as a **non-fatal** error.
  ///
  /// [reason] is attached as a custom key visible in the Firebase Console
  /// alongside the stack trace.
  static Future<void> logError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    if (reason != null) await _c.setCustomKey('error_reason', reason);
    await _c.recordError(error, stack, fatal: fatal, reason: reason);
    if (kDebugMode) {
      // ignore: avoid_print
      print('📛 Crashlytics [${fatal ? "FATAL" : "non-fatal"}]'
          '${reason != null ? " ($reason)" : ""}: $error');
    }
  }

  // ── Breadcrumb logs ──────────────────────────────────────────────────────

  /// Write a breadcrumb message that appears in the crash log timeline.
  /// Mirrors `FirebaseCrashlytics.instance.log()`.
  static Future<void> log(String message) => _c.log(message);

  // ── Custom key-value pairs ───────────────────────────────────────────────

  /// Attach arbitrary string metadata that helps reproduce crashes.
  /// Example: screen name, feature flag state, network type.
  static Future<void> setKey(String key, dynamic value) =>
      _c.setCustomKey(key, value);
}
