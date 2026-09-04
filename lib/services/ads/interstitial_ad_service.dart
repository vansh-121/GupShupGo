/// GupShupGo — interstitials, and the pacing that keeps them tolerable.
///
/// An interstitial is the only format here that takes the whole screen without
/// being asked for, so almost all of this file is about *not* showing one. Two
/// triggers exist and they are paced independently:
///
///   • [maybeShowOnStrangerSkip] — every Nth "Next Stranger" tap. A skip is a
///     request for new content, which is the one transition in this app where a
///     fullscreen ad is what Google's own placement guidance describes as
///     acceptable.
///   • [armPostCall] / [showArmedPostCall] — after a call that actually
///     connected and lasted. Split in two on purpose: see [armPostCall].
///
/// Eligibility (flags, consent, Pro, call state) is not decided here — that is
/// [AdsService.canShowInterstitial]. This class owns only the parts that need
/// memory: how long since the last one, and how many skips ago.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../main.dart' show sharedPrefs;
import '../../provider/call_state_provider.dart';
import '../feature_flag_service.dart';
import '../review_prompt_service.dart';
import 'ad_ids.dart';
import 'ads_service.dart';

/// Loading is bounded, matching `RewardedAdService`: an interstitial that
/// arrives late is worse than one that never arrives, because by then the user
/// has moved on and the ad lands over whatever they moved on to.
const Duration _kLoadTimeout = Duration(seconds: 10);

/// How many skips between interstitials. Counted rather than sampled randomly:
/// a counter is predictable for the user, testable without a seeded RNG, and
/// cannot accidentally fire twice in a row.
const int _kSkipsPerInterstitial = 3;

/// After a no-fill, wait this long before asking again. Deliberately not
/// persisted — losing it on restart is harmless, and the only job it has is to
/// stop a rapid series of skips turning into a request loop, which AdMob counts
/// against the account even though no impression ever happens.
const Duration _kFailureCooldown = Duration(seconds: 45);

// Prefixed and version-suffixed, following the `review_v1_` convention: bumping
// to `ads_v2_` would deliberately reset everyone's pacing.
const String _kLastShownKey = 'ads_v1_last_interstitial_ms';
const String _kLastCallShownKey = 'ads_v1_last_call_interstitial_ms';
const String _kSkipCountKey = 'ads_v1_stranger_skips';

class InterstitialAdService {
  InterstitialAdService._();
  static final InterstitialAdService instance = InterstitialAdService._();

  InterstitialAd? _ad;
  bool _loading = false;
  bool _showing = false;
  DateTime? _lastFailureAt;

  /// Set when a call ends well, cleared when the ad is shown or the chance
  /// passes. See [armPostCall].
  bool _postCallArmed = false;

  FeatureFlagService get _flags => FeatureFlagService.instance;

  /// Whether a post-call interstitial is waiting to be shown.
  bool get isPostCallArmed => _postCallArmed;

  // ── The pacing decision ──────────────────────────────────────────────────

  /// Whether enough time has passed, as arithmetic over three numbers so the
  /// gate can be tested without SharedPreferences, an SDK, or a clock — the same
  /// shape as `ReviewPromptService.shouldAsk`.
  ///
  /// [lastShownMs] is 0 when nothing has ever been shown, which must read as
  /// "never" rather than "shown at the epoch"; the latter is also allowed by the
  /// arithmetic below, but only by accident, so it is spelled out.
  @visibleForTesting
  static bool shouldShow({
    required int lastShownMs,
    required int nowMs,
    required int minGapMs,
  }) {
    if (lastShownMs == 0) return true;
    // A clock that moved backwards (timezone change, NTP correction, a user
    // setting the date forward and back) would otherwise lock the gate until it
    // caught up. Treat a future stamp as "just shown" rather than trusting it.
    if (nowMs < lastShownMs) return false;
    return nowMs - lastShownMs >= minGapMs;
  }

  /// Whether this is the skip that earns an ad. Separate from [shouldShow] so
  /// the count and the clock can be reasoned about — and tested — apart.
  @visibleForTesting
  static bool isSkipDue(int skipCount) =>
      skipCount > 0 && skipCount % _kSkipsPerInterstitial == 0;

  // ── Triggers ─────────────────────────────────────────────────────────────

  /// Called on every "Next Stranger" tap. Counts the skip and shows an ad on
  /// every [_kSkipsPerInterstitial]th one, subject to the time gap.
  ///
  /// **Await this before starting the next match.** The ad is fullscreen, so a
  /// match completing behind it means the user comes back to a stranger who has
  /// been waiting — and quite possibly already left.
  ///
  /// Returns true if an ad was shown, only so callers can log it. Never throws.
  Future<bool> maybeShowOnStrangerSkip({
    required bool hasProEntitlement,
    required CallState callState,
  }) async {
    try {
      // Count the skip even when ads are off, so switching the flag on doesn't
      // give the first eligible skip an ad immediately.
      final skips = (sharedPrefs.getInt(_kSkipCountKey) ?? 0) + 1;
      await sharedPrefs.setInt(_kSkipCountKey, skips);

      if (!isSkipDue(skips)) return false;

      return await _maybeShow(
        hasProEntitlement: hasProEntitlement,
        callState: callState,
        stampKey: _kLastShownKey,
        minGap: _flags.adsInterstitialMinGap,
        trigger: 'stranger-skip',
      );
    } catch (e) {
      debugPrint('[Interstitial] ⚠️ skip trigger failed: $e');
      return false;
    }
  }

  /// Warms an ad up only if the *next* skip is the one that would show it.
  ///
  /// Without this, the third skip pays the load time before the lobby appears —
  /// the user taps "Next" and watches the chat they just left for up to
  /// [_kLoadTimeout]. Conditioning on the counter is what keeps that fix from
  /// becoming two wasted requests for every useful one.
  Future<void> preloadForNextSkip() async {
    try {
      if (!isSkipDue((sharedPrefs.getInt(_kSkipCountKey) ?? 0) + 1)) return;
      await preload();
    } catch (e) {
      debugPrint('[Interstitial] ⚠️ skip preload failed: $e');
    }
  }

  /// Records that a call ended in a way that earns an interstitial, and warms
  /// one up.
  ///
  /// Arming and showing are deliberately separate calls. `CallScreen`
  /// `_cleanupAndPop` ends with `Navigator.pop`, so the call screen cannot show
  /// this itself without the ad landing over call UI — which is both an
  /// obscured-ad problem and, with a hangup button underneath, an
  /// accidental-click one. So the call arms it and `PostCallInterstitial`, which
  /// lives on the home screen, fires it once the app is back at idle. "No ad over
  /// call UI" is then structural rather than a convention someone has to
  /// remember.
  void armPostCall() {
    if (_postCallArmed) return;
    _postCallArmed = true;
    // Warm one now: the ad has the length of the pop animation to arrive, which
    // is most of why this is worth preloading at all.
    unawaited(preload());
  }

  /// Clears an arming without showing anything — the honest way to drop the
  /// chance when something more valuable took the moment.
  void disarmPostCall() => _postCallArmed = false;

  /// Shows the armed post-call interstitial, if one is armed and paced.
  ///
  /// Safe and cheap to call on every call-state change: it no-ops unless
  /// [armPostCall] ran.
  Future<bool> showArmedPostCall({
    required bool hasProEntitlement,
    required CallState callState,
  }) async {
    if (!_postCallArmed) return false;
    _postCallArmed = false;

    // The review sheet asks for the same moment and is worth more than an
    // impression, so it wins outright. Checked here rather than at arming time
    // because `maybeRequest` is fire-and-forget: at arming its decision hasn't
    // been made yet, and by now it has been written down.
    if (ReviewPromptService.instance.askedRecently()) {
      debugPrint('[Interstitial] ⏸️ post-call yielded to the review sheet');
      return false;
    }

    try {
      return await _maybeShow(
        hasProEntitlement: hasProEntitlement,
        callState: callState,
        stampKey: _kLastCallShownKey,
        minGap: _flags.adsInterstitialCallMinGap,
        trigger: 'post-call',
      );
    } catch (e) {
      debugPrint('[Interstitial] ⚠️ post-call trigger failed: $e');
      return false;
    }
  }

  // ── Show ─────────────────────────────────────────────────────────────────

  Future<bool> _maybeShow({
    required bool hasProEntitlement,
    required CallState callState,
    required String stampKey,
    required Duration minGap,
    required String trigger,
  }) async {
    if (!AdsService.instance.canShowInterstitial(
      hasProEntitlement: hasProEntitlement,
      callState: callState,
    )) {
      return false;
    }
    if (_showing) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (!shouldShow(
      lastShownMs: sharedPrefs.getInt(stampKey) ?? 0,
      nowMs: now,
      minGapMs: minGap.inMilliseconds,
    )) {
      debugPrint('[Interstitial] ⏸️ $trigger inside the ${minGap.inSeconds}s gap');
      return false;
    }

    final failedAt = _lastFailureAt;
    if (failedAt != null &&
        DateTime.now().difference(failedAt) < _kFailureCooldown) {
      return false;
    }

    if (_ad == null) {
      await _load();
      if (_ad == null) {
        // A no-fill must not burn the window — the user got nothing, so nothing
        // was spent. The in-memory cooldown above is what stops this retrying on
        // the very next skip.
        _lastFailureAt = DateTime.now();
        return false;
      }
    }

    final ad = _ad!;
    _ad = null; // Single-use; never hand the same ad out twice.
    _showing = true;

    // Stamp before showing, not after. There is no outcome to wait for that
    // would make the stamp more accurate, and being wrong in this direction
    // costs one impression — being wrong in the other shows two ads in a row.
    await sharedPrefs.setInt(stampKey, now);

    final dismissed = Completer<bool>();
    void finish(bool shown) {
      if (!dismissed.isCompleted) dismissed.complete(shown);
    }

    try {
      ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('[Interstitial] ⚠️ failed to show: $error');
          ad.dispose();
          finish(false);
        },
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          finish(true);
        },
      );

      debugPrint('[Interstitial] 📺 showing ($trigger)');
      await ad.show();
      return await dismissed.future;
    } catch (e) {
      debugPrint('[Interstitial] ⚠️ show threw: $e');
      try {
        ad.dispose();
      } catch (_) {}
      return false;
    } finally {
      _showing = false;
    }
  }

  // ── Load ─────────────────────────────────────────────────────────────────

  /// Warm one ad up. Fire-and-forget, and a no-op when interstitials are off.
  ///
  /// Unlike the rewarded service this is not called on entering a screen, only
  /// when a trigger becomes plausible — a preloaded interstitial that is never
  /// shown is a wasted request, and wasted requests lower the account's match
  /// rate.
  Future<void> preload() async {
    if (!_flags.adsEnabled || !_flags.adsInterstitialEnabled) return;
    if (!AdsService.instance.isReady) return;
    if (_ad != null || _loading || _showing) return;
    await _load();
  }

  Future<void> _load() async {
    _loading = true;
    final loaded = Completer<InterstitialAd?>();
    try {
      await InterstitialAd.load(
        adUnitId: AdIds.interstitial,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            if (!loaded.isCompleted) loaded.complete(ad);
          },
          onAdFailedToLoad: (error) {
            debugPrint('[Interstitial] ⚠️ load failed: $error');
            if (!loaded.isCompleted) loaded.complete(null);
          },
        ),
      );
      _ad = await loaded.future.timeout(_kLoadTimeout);
      if (_ad != null) debugPrint('[Interstitial] ✅ loaded');
    } on TimeoutException {
      debugPrint('[Interstitial] ⚠️ load timed out');
      _ad = null;
    } catch (e) {
      debugPrint('[Interstitial] ⚠️ load threw: $e');
      _ad = null;
    } finally {
      _loading = false;
    }
  }

  /// Drop any cached ad. Call when leaving a surface that could have shown one:
  /// AdMob expires preloaded ads after about an hour, and a stale ad shown later
  /// is an ad shown somewhere it was never gated for.
  void disposeAd() {
    _ad?.dispose();
    _ad = null;
  }
}
