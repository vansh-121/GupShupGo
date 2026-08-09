import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dart wrapper over the native Android Picture-in-Picture MethodChannel
/// (see `MainActivity.kt`, channel `com.gupshupgo.app/pip`).
///
/// PiP is used for **video calls only**. When a call connects, the call screen
/// calls [enableAutoEnter] so pressing Home / recents shrinks the call into a
/// floating window — auto-enter on Android 12+ (API 31), an `onUserLeaveHint`
/// fallback on 8.0–11 (API 26–30). [disable] is called when the call ends. The
/// native side reports mode changes back through [isInPipMode], which the UI
/// watches to hide its controls while collapsed into the small window.
///
/// Every method is a safe no-op on iOS and on Android versions/devices without
/// PiP support, so callers don't need to platform-check.
class PipService {
  PipService._internal() {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  /// Single shared instance — keeps one method-call handler registered and one
  /// stable [isInPipMode] notifier. Only one call is ever active at a time.
  static final PipService instance = PipService._internal();

  static const MethodChannel _channel = MethodChannel('com.gupshupgo.app/pip');

  /// True while the activity is in the floating PiP window. The call UI listens
  /// to this to collapse to remote-video-only (no controls / previews / text).
  final ValueNotifier<bool> isInPipMode = ValueNotifier<bool>(false);

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onPipModeChanged') {
      final args = call.arguments;
      isInPipMode.value = args is Map && args['isInPipMode'] == true;
    }
    return null;
  }

  /// Whether this device can enter PiP (Android 8.0+ that declares the PiP
  /// hardware feature). False on iOS and Android 7.x and below.
  Future<bool> isSupported() async {
    if (!_isAndroid) return false;
    try {
      final bool? supported =
          await _channel.invokeMethod<bool>('isPipSupported');
      return supported ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Arm PiP for an active video call. [aspectNumerator]/[aspectDenominator]
  /// set the floating window's shape (defaults to a 9:16 portrait preview).
  /// Returns whether PiP is actually supported on this device.
  Future<bool> enableAutoEnter({
    int aspectNumerator = 9,
    int aspectDenominator = 16,
  }) async {
    if (!_isAndroid) return false;
    try {
      final bool? supported = await _channel.invokeMethod<bool>(
        'enableAutoEnterPip',
        {
          'aspectNumerator': aspectNumerator,
          'aspectDenominator': aspectDenominator,
        },
      );
      return supported ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Disarm PiP when the video call ends. Resets [isInPipMode] immediately so a
  /// stale flag can't hide the UI of whatever screen comes next.
  Future<void> disable() async {
    isInPipMode.value = false;
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod('disablePip');
    } catch (_) {
      // Best effort — nothing to recover if this fails.
    }
  }

  /// Enter PiP immediately (e.g. from a "minimize" button). Returns whether the
  /// transition was accepted by the system.
  Future<bool> enterNow() async {
    if (!_isAndroid) return false;
    try {
      final bool? entered = await _channel.invokeMethod<bool>('enterPipNow');
      return entered ?? false;
    } catch (_) {
      return false;
    }
  }
}
