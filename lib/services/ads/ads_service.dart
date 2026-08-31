/// GupShupGo — AdMob lifecycle and the single decision point for showing ads.
///
/// Everything about *whether* an ad may appear is decided here, in one place,
/// so a new placement cannot accidentally ship without the gating. See
/// [canShowBanner].
///
/// Ordering matters and is not arbitrary:
///
/// 1. Remote Config, so `ads_enabled=false` costs nothing — no SDK, no consent
///    form, no network. A release can ship with ads dark and be switched on
///    later without an update.
/// 2. UMP consent state (non-UI). The form itself is deferred to the first
///    ad-bearing screen — see [AdConsentService].
/// 3. `MobileAds.instance.initialize()`, only once consent permits requests.
///
/// The service is a [ChangeNotifier] and forwards Remote Config changes, so a
/// widget listening to it rebuilds when ads are switched on or off mid-session.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:video_chat_app/provider/call_state_provider.dart';
import 'package:video_chat_app/services/feature_flag_service.dart';

import 'ad_consent_service.dart';

/// Devices that should be served test ads even from a release build.
///
/// Add your own device here before testing a release build, otherwise you are
/// clicking live ads — which AdMob treats as invalid traffic and which is the
/// usual reason accounts get suspended. The ID is printed by the SDK on the
/// first ad request; look for a line like:
///
///     I/Ads: Use RequestConfiguration.Builder.setTestDeviceIds(
///              Arrays.asList("33BE2250B43518CCDA7DE426D04EE231"))
///
/// Debug builds don't need this — they already use test unit IDs (see [AdIds]).
/// The same list doubles as UMP's `testIdentifiers` so the debug geography in
/// [AdConsentService] applies to exactly these devices.
const List<String> kAdTestDeviceIds = <String>[];

class AdsService extends ChangeNotifier {
  AdsService._();
  static final AdsService instance = AdsService._();

  bool _sdkReady = false;
  bool _starting = false;
  bool _wired = false;

  /// Whether the Mobile Ads SDK has been initialised and may be asked for ads.
  bool get isReady => _sdkReady;

  FeatureFlagService get _flags => FeatureFlagService.instance;
  AdConsentService get _consent => AdConsentService.instance;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  /// Call once from `main()`, fire-and-forget. Never awaited on the startup
  /// path: no ad is worth delaying the first frame for.
  Future<void> init() async {
    if (!_wired) {
      _wired = true;
      // Remote Config can flip `ads_enabled` on mid-session, and this listener
      // is what turns that into a real start — without it the first `false`
      // read would be permanent for the life of the process.
      _flags.addListener(_onFlagsChanged);
    }
    await _start();
  }

  void _onFlagsChanged() {
    notifyListeners();
    unawaited(_start());
  }

  /// Brings the SDK up if the flags and consent state allow it. Idempotent and
  /// safe to call from anywhere, including repeatedly.
  Future<void> _start() async {
    if (_sdkReady || _starting) return;
    _starting = true;
    try {
      // Idempotent — resolves against whichever call started first, so this
      // works whether or not main() has already kicked off the flag fetch.
      await _flags.init();
      if (!_flags.adsEnabled) {
        debugPrint('[Ads] ⏸️ ads_enabled=false — SDK not started');
        return;
      }

      await _consent.refresh();
      if (!_consent.canRequestAds) {
        // Not a failure: a user in the EEA who hasn't seen the form yet lands
        // here. The form is shown by [ensureConsent] from the first ad-bearing
        // screen, which then starts the SDK.
        debugPrint('[Ads] ⏸️ consent does not permit ad requests yet');
        return;
      }

      await _initialiseSdk();
    } catch (e) {
      debugPrint('[Ads] ⚠️ start failed (ads stay off): $e');
    } finally {
      _starting = false;
      notifyListeners();
    }
  }

  Future<void> _initialiseSdk() async {
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: kAdTestDeviceIds,
        // A messenger is general-audience, so cap the inventory rather than let
        // an MA-rated ad land next to someone's chat list.
        maxAdContentRating: MaxAdContentRating.t,
      ),
    );
    await MobileAds.instance.initialize();
    _sdkReady = true;
    debugPrint('[Ads] ✅ SDK initialised');
  }

  /// Shows the UMP consent form if one is required, then starts the SDK.
  ///
  /// Call this from a surface that shows ads — never from auth, PIN or vault
  /// flows. Cheap and idempotent: outside a regulated region, and for a user who
  /// has already answered, no form appears.
  Future<void> ensureConsent() async {
    if (!_flags.adsEnabled) return;
    if (_sdkReady) return;

    await _consent.gather();
    if (_consent.canRequestAds && !_sdkReady && !_starting) {
      _starting = true;
      try {
        await _initialiseSdk();
      } catch (e) {
        debugPrint('[Ads] ⚠️ SDK init after consent failed: $e');
      } finally {
        _starting = false;
      }
    }
    notifyListeners();
  }

  // ── The gate ─────────────────────────────────────────────────────────────

  /// Whether a banner may be built right now.
  ///
  /// [hasProEntitlement] must come from
  /// `SubscriptionProvider.hasActiveProEntitlement`, **not** `isPro`: `isPro` is
  /// masked by the `pro_enabled` flag and reads `false` for a real subscriber
  /// whenever that flag is off, which would show banners to the people who paid
  /// to remove them.
  ///
  /// [callState] suppresses banners for the whole duration of a call. A CallKit
  /// call can arrive over any screen, so this is the belt to the placement
  /// rules' braces: it guarantees no banner is ever live under call UI, which
  /// would be both an obscured-ad policy problem and an accidental-click risk.
  bool canShowBanner({
    required bool hasProEntitlement,
    required CallState callState,
  }) {
    return _flags.adsEnabled &&
        _flags.adsBannerEnabled &&
        !hasProEntitlement &&
        callState == CallState.Idle &&
        _consent.canRequestAds &&
        _sdkReady;
  }

  /// Whether a rewarded ad may be offered.
  ///
  /// Note there is no Pro check. Pro removes *banners*; a Pro user who wants to
  /// trade thirty seconds for Gup Points or a Bond Restore is still welcome to,
  /// and the Pro benefit copy is worded so this doesn't contradict it.
  bool get canShowRewarded =>
      _flags.adsEnabled &&
      _flags.adsRewardedEnabled &&
      _consent.canRequestAds &&
      _sdkReady;

  @override
  void dispose() {
    if (_wired) _flags.removeListener(_onFlagsChanged);
    super.dispose();
  }
}
