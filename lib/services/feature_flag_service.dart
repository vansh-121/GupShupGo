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
/// - `force_update_enabled` + the three `*_version_code` / deadline keys —
///   the supported-version policy. Off by default; see [VersionPolicyService].

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class FeatureFlagService extends ChangeNotifier {
  FeatureFlagService._();
  static final FeatureFlagService instance = FeatureFlagService._();

  // ── Flag keys ────────────────────────────────────────────────────────────
  static const _kProEnabled = 'pro_enabled';

  // Ads. `ads_enabled` is the master switch: the per-format flags are only
  // consulted when it is on, so flipping it off kills every placement at once
  // without having to remember which formats exist.
  static const _kAdsEnabled = 'ads_enabled';
  static const _kAdsBannerEnabled = 'ads_banner_enabled';
  static const _kAdsRewardedEnabled = 'ads_rewarded_enabled';
  static const _kAdsInterstitialEnabled = 'ads_interstitial_enabled';
  static const _kAdsNativeEnabled = 'ads_native_enabled';
  // Chat gets its own switch on top of `ads_native_enabled`. It is the only
  // placement inside a conversation, so it carries the most UX risk of the
  // three, and this is what allows it to be killed without also losing the
  // Moments and Calls cards.
  static const _kAdsNativeChatEnabled = 'ads_native_chat_enabled';
  static const _kAdsRewardPoints = 'ads_reward_points';
  static const _kAdsRewardedDailyCap = 'ads_rewarded_daily_cap';
  static const _kAdsInterstitialMinGapSeconds =
      'ads_interstitial_min_gap_seconds';
  static const _kAdsInterstitialCallMinGapSeconds =
      'ads_interstitial_call_min_gap_seconds';

  // Version support policy. See [VersionPolicyService] for the state machine
  // these four drive; the short version is that `force_update_enabled` is the
  // master switch and **nothing here does anything while it is off**. That is
  // deliberate: a mistyped version code is the one config error in this file
  // that can lock every user out of the app, so the recovery lever is a single
  // boolean rather than having to work out which number was wrong.
  static const _kForceUpdateEnabled = 'force_update_enabled';
  static const _kMinSupportedVersionCode = 'min_supported_version_code';
  static const _kDeprecatedBelowVersionCode = 'deprecated_below_version_code';
  static const _kSupportDeadlineIso = 'support_deadline_iso';

  // Fallbacks used when the console holds a value Remote Config can't parse as
  // a positive int — getInt() returns 0 in that case, and a 0-point reward or a
  // 0 daily cap silently disables the feature rather than failing loudly.
  static const _kDefaultRewardPoints = 50;
  static const _kDefaultRewardedDailyCap = 10;

  // Interstitial pacing. The stranger-skip gap is short because a skip is a
  // deliberate request for new content; the post-call gap is hours because an ad
  // after every call teaches people that calling costs them something.
  static const _kDefaultInterstitialMinGapSeconds = 60;
  static const _kDefaultInterstitialCallMinGapSeconds = 14400; // 4h

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

  /// Whether interstitials may be shown. Meaningless on its own — see
  /// [adsEnabled].
  bool get adsInterstitialEnabled =>
      _remoteConfig.getBool(_kAdsInterstitialEnabled);

  /// Whether native ad cards may render. Meaningless on its own — see
  /// [adsEnabled].
  bool get adsNativeEnabled => _remoteConfig.getBool(_kAdsNativeEnabled);

  /// Whether a native card may appear inside a conversation. Requires
  /// [adsNativeEnabled] as well — this is a narrowing switch, not an
  /// independent one.
  bool get adsNativeChatEnabled =>
      adsNativeEnabled && _remoteConfig.getBool(_kAdsNativeChatEnabled);

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

  /// Minimum seconds between two interstitials from the same trigger.
  ///
  /// Unlike the reward knobs there is no server counterpart: an interstitial
  /// pays on impression, so the client is the only party that can pace it. That
  /// makes this flag the actual ceiling rather than a display value, which is why
  /// the fallback is deliberately conservative.
  Duration get adsInterstitialMinGap {
    final v = _remoteConfig.getInt(_kAdsInterstitialMinGapSeconds);
    return Duration(
      seconds: v > 0 ? v : _kDefaultInterstitialMinGapSeconds,
    );
  }

  /// Minimum seconds between two post-call interstitials. Much longer than
  /// [adsInterstitialMinGap] on purpose — see the constant's note.
  Duration get adsInterstitialCallMinGap {
    final v = _remoteConfig.getInt(_kAdsInterstitialCallMinGapSeconds);
    return Duration(
      seconds: v > 0 ? v : _kDefaultInterstitialCallMinGapSeconds,
    );
  }

  // ── Version support policy ───────────────────────────────────────────────

  /// Master switch for the whole retire-old-builds machinery.
  ///
  /// While this is `false` the other three keys are inert no matter what they
  /// hold, so a release can ship the client code long before any version is
  /// actually retired — and a bad policy is undone by flipping one boolean.
  bool get forceUpdateEnabled => _remoteConfig.getBool(_kForceUpdateEnabled);

  /// Builds below this are blocked **immediately**, with no countdown.
  ///
  /// Clock-independent, which makes it the dependable lever: unlike
  /// [supportDeadline] it cannot be dodged (or triggered early) by a device
  /// whose date is wrong. `0` disables it.
  int get minSupportedVersionCode =>
      _remoteConfig.getInt(_kMinSupportedVersionCode);

  /// Builds below this are on notice: they still work, but they start warning
  /// the user and are blocked once [supportDeadline] passes. `0` disables it.
  int get deprecatedBelowVersionCode =>
      _remoteConfig.getInt(_kDeprecatedBelowVersionCode);

  /// When [deprecatedBelowVersionCode] stops being merely deprecated and
  /// becomes unsupported. ISO-8601; `null` when unset or unparseable.
  ///
  /// An unparseable string reads as "no deadline set" rather than as "now",
  /// so a typo here downgrades to a nagging warning instead of a lockout.
  DateTime? get supportDeadline {
    final raw = _remoteConfig.getString(_kSupportDeadlineIso).trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
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
        _kAdsInterstitialEnabled: false,
        _kAdsNativeEnabled: false,
        _kAdsNativeChatEnabled: false,
        _kAdsRewardPoints: _kDefaultRewardPoints,
        _kAdsRewardedDailyCap: _kDefaultRewardedDailyCap,
        _kAdsInterstitialMinGapSeconds: _kDefaultInterstitialMinGapSeconds,
        _kAdsInterstitialCallMinGapSeconds:
            _kDefaultInterstitialCallMinGapSeconds,
        // Version policy ships inert. Because enforcement is gated on the
        // boolean below, a device that never manages to fetch — offline on
        // first run, or fetch errored — cannot lock itself out on defaults.
        _kForceUpdateEnabled: false,
        _kMinSupportedVersionCode: 0,
        _kDeprecatedBelowVersionCode: 0,
        _kSupportDeadlineIso: '',
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
          'rewarded=$adsRewardedEnabled, '
          'interstitial=$adsInterstitialEnabled, '
          'native=$adsNativeEnabled, chat_native=$adsNativeChatEnabled)');
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
