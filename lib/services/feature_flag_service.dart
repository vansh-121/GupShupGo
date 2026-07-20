/// GupShupGo — Feature Flag Service.
///
/// A lightweight singleton wrapping Firebase Remote Config to control
/// feature availability at runtime without app updates.
///
/// Currently manages one flag:
/// - `pro_enabled` — when `false` (default), all Pro UI, purchase flows,
///   and premium gates are hidden. Flip to `true` in the Firebase Console
///   once the merchant ID is approved.

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class FeatureFlagService extends ChangeNotifier {
  FeatureFlagService._();
  static final FeatureFlagService instance = FeatureFlagService._();

  // ── Flag keys ────────────────────────────────────────────────────────────
  static const _kProEnabled = 'pro_enabled';

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  /// Whether the Pro feature set is enabled (UI visible + purchases active).
  bool get isProEnabled => _remoteConfig.getBool(_kProEnabled);

  /// Initialise Remote Config with defaults and fetch latest values.
  ///
  /// Call once from main.dart after Firebase.initializeApp().
  Future<void> init() async {
    try {
      // Set defaults — Pro is OFF until explicitly enabled in the console
      await _remoteConfig.setDefaults({
        _kProEnabled: false,
      });

      // Configure fetch settings
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        // In debug: fetch every time. In release: cache for 1 hour.
        minimumFetchInterval:
            kDebugMode ? Duration.zero : const Duration(hours: 1),
      ));

      // Fetch and activate in one call
      await _remoteConfig.fetchAndActivate();

      // Listen for real-time config updates from Firebase
      _remoteConfig.onConfigUpdated.listen((event) async {
        debugPrint('[FeatureFlags] 🔔 Real-time update detected: ${event.updatedKeys}');
        await _remoteConfig.activate();
        notifyListeners();
      });

      debugPrint(
          '[FeatureFlags] ✅ Initialised — pro_enabled=$isProEnabled');
    } catch (e) {
      // Non-fatal — defaults (pro_enabled=false) are fine as fallback
      debugPrint('[FeatureFlags] ⚠️ Init failed (using defaults): $e');
    }
  }
}
