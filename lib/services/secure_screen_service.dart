import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dart wrapper over the native Android FLAG_SECURE MethodChannel
/// (see `MainActivity.kt`, channel `com.gupshupgo.app/secure_screen`).
///
/// Backs **view-once media**. While a view-once photo or video is on screen the
/// viewer calls [enable] in its `initState` and [disable] in its `dispose`, so
/// the window carries FLAG_SECURE only for that moment. Android then keeps the
/// activity out of screenshots, screen recordings, and the recent-apps
/// thumbnail, and refuses to mirror it to a non-secure external display.
///
/// **iOS has no FLAG_SECURE equivalent.** There is no supported public API to
/// stop a screenshot of arbitrary UIKit content, so every method here is a
/// no-op on iOS (and web). [isEnforceable] says which world we're in, and the
/// viewer must word its UI from that honestly rather than imply a guarantee the
/// platform cannot make.
class SecureScreenService {
  SecureScreenService._();
  static final SecureScreenService instance = SecureScreenService._();

  static const MethodChannel _channel =
      MethodChannel('com.gupshupgo.app/secure_screen');

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  /// True only on platforms where [enable] actually blocks screen capture
  /// (Android). The viewer uses this to choose between a "Screenshot blocked"
  /// badge and the honest iOS caveat.
  bool get isEnforceable => _isAndroid;

  /// Marks the window secure so the OS blocks capture. No-op off Android.
  Future<void> enable() => _setSecure(true);

  /// Clears the secure flag. No-op off Android. **Must** be called from the
  /// viewer's dispose — the flag is on the whole window, so leaving it set
  /// would silently break screenshots everywhere else in the app.
  Future<void> disable() => _setSecure(false);

  Future<void> _setSecure(bool secure) async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('setSecure', {'secure': secure});
    } catch (_) {
      // Best-effort: a channel failure must never crash or block the viewer.
    }
  }
}
