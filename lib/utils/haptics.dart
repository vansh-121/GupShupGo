import 'package:flutter/services.dart';

/// Uniform, subtle haptic feedback for action taps across the app.
///
/// Tapping a button should feel acknowledged the instant it registers — before
/// any spinner or navigation. This centralises that tick so every call site
/// uses the same weights instead of reaching for `HapticFeedback` ad hoc (today
/// only the voice/drag surfaces do, e.g. [voice_record_button.dart]).
///
/// `HapticFeedback` talks to a platform channel and can fail on devices with no
/// vibrator or before the binding is ready. A dropped haptic must never break
/// the action it accompanies, so every call here is strictly best-effort: the
/// returned future is fire-and-forget and its errors are swallowed.
class AppHaptics {
  AppHaptics._();

  /// A light tick for a normal action tap (buttons, icon buttons, list rows).
  static void tap() => _run(HapticFeedback.lightImpact);

  /// A slightly firmer tap for a completed / confirmed action.
  static void success() => _run(HapticFeedback.mediumImpact);

  /// A heavier tap for a warning or a destructive confirmation.
  static void warning() => _run(HapticFeedback.heavyImpact);

  static void _run(Future<void> Function() impact) {
    try {
      // Ignore the returned future and swallow platform errors (no vibrator,
      // channel unavailable) so a missing haptic can never surface as an
      // unhandled exception on the action's path.
      impact().catchError((Object _) {});
    } catch (_) {
      // Some platforms can throw synchronously if the binding isn't ready.
    }
  }
}
