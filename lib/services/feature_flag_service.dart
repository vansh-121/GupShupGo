/// GupShupGo — Feature Flag Service.
///
/// A lightweight singleton wrapping Firebase Remote Config to control
/// feature availability at runtime without app updates.
///
/// Flags managed here:
/// - `pro_enabled` — when `false` (default), all Pro UI, purchase flows,
///   and premium gates are hidden. Flip to `true` in the Firebase Console
///   once the merchant ID is approved.
/// - `ads_*` — the AdMob kill switches and tuning knobs. All default to
///   off/zero so a release ships dark and ads only appear once they are
///   deliberately enabled in the console.

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class FeatureFlagService extends ChangeNotifier {
  FeatureFlagService._();
  static final FeatureFlagService instance = FeatureFlagService._();

  // ── Flag keys ────────────────────────────────────────────────────────────
  static const _kProEnabled = 'pro_enabled';

  // Ads. `ads_enabled` is the master switch: the two per-format flags are only
  // consulted when it is on, so flipping it off kills every placement at once
  // without having to remember which formats exist.
  static const _kAdsEnabled = 'ads_enabled';
  static const _kAdsBannerEnabled = 'ads_banner_enabled';
  static const _kAdsRewardedEnabled = 'ads_rewarded_enabled';
  static const _kAdsRewardPoints = 'ads_reward_points';
  static const _kAdsRewardedDailyCap = 'ads_rewarded_daily_cap';

  // Fallbacks used when the console holds a value Remote Config can't parse as
  // a positive int — getInt() returns 0 in that case, and a 0-point reward or a
  // 0 daily cap silently disables the feature rather than failing loudly.
  static const _kDefaultRewardPoints = 50;
  static const _kDefaultRewardedDailyCap = 5;

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  /// Whether the Pro feature set is enabled (UI visible + purchases active).
  bool get isProEnabled => _remoteConfig.getBool(_kProEnabled);

  // ── Ads ──────────────────────────────────────────────────────────────────

  /// Master ad switch. When `false`, the SDK is never initialised, no consent
  /// form is shown, and no placement renders.
  bool get adsEnabled => _remoteConfig.getBool(_kAdsEnabled);

  /// Whether banner ads may render. Meaningless on its own — see [adsEnabled].
  bool get adsBannerEnabled => _remoteConfig.getBool(_kAdsBannerEnabled);

  /// Whether rewarded ads may be offered. Meaningless on its own — see
  /// [adsEnabled].
  bool get adsRewardedEnabled => _remoteConfig.getBool(_kAdsRewardedEnabled);

  /// Gup Points granted per completed rewarded ad.
  ///
  /// This is the value the *UI advertises*. The authoritative one lives in the
  /// `admobSsv` Cloud Function, which is what actually credits the account — a
  /// tampered client can promise any number it likes and still only be paid
  /// what the server decides.
  int get adsRewardPoints {
    final v = _remoteConfig.getInt(_kAdsRewardPoints);
    return v > 0 ? v : _kDefaultRewardPoints;
  }

  /// How many rewarded ads a user may be paid for per day. Same client/server
  /// split as [adsRewardPoints]: shown here, enforced in `admobSsv`.
  int get adsRewardedDailyCap {
    final v = _remoteConfig.getInt(_kAdsRewardedDailyCap);
    return v > 0 ? v : _kDefaultRewardedDailyCap;
  }

  Future<void>? _initFuture;

  /// Initialise Remote Config with defaults and fetch latest values.
  ///
  /// Call once from main.dart after Firebase.initializeApp(). Idempotent: later
  /// callers (e.g. [AdsService], which must not read a flag before the first
  /// fetch lands) await the same in-flight init rather than starting a second
  /// one or racing ahead on defaults.
  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    try {
      // Set defaults — Pro and every ad placement are OFF until explicitly
      // enabled in the console, so a build can ship before the AdMob account
      // is fully approved and stay quiet until it is.
      await _remoteConfig.setDefaults({
        _kProEnabled: false,
        _kAdsEnabled: false,
        _kAdsBannerEnabled: false,
        _kAdsRewardedEnabled: false,
        _kAdsRewardPoints: _kDefaultRewardPoints,
        _kAdsRewardedDailyCap: _kDefaultRewardedDailyCap,
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
          '[FeatureFlags] ✅ Initialised — pro_enabled=$isProEnabled, '
          'ads_enabled=$adsEnabled (banner=$adsBannerEnabled, '
          'rewarded=$adsRewardedEnabled)');
    } catch (e) {
      // Non-fatal — defaults (everything off) are fine as fallback
      debugPrint('[FeatureFlags] ⚠️ Init failed (using defaults): $e');
    }

    // Notify even on failure. init() runs fire-and-forget before runApp(), so
    // anything already built read the defaults; without this, values that
    // arrived with the first fetch would sit inert until the next real-time
    // update. Cheap, and it means a flag flip is never one rebuild behind.
    notifyListeners();
  }
}
