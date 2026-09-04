/// GupShupGo — rewarded ads.
///
/// The client never grants the reward. It loads the ad, attaches
/// [ServerSideVerificationOptions] describing *who* is watching and *what for*,
/// and shows it; Google then calls the `admobSsv` Cloud Function, which verifies
/// the signature and does the crediting. A tampered client can fake
/// [RewardedAdOutcome.earned] all day and still be paid nothing.
///
/// One rewarded unit serves both reward types, so the type has to travel in
/// `custom_data` — it cannot be inferred from the ad unit ID.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';
import 'ads_service.dart';

/// What a completed rewarded view should buy. The wire values are part of the
/// contract with `admobSsv` — changing one silently breaks crediting, because
/// the function falls through to "unknown type" and refuses to pay.
enum AdRewardType {
  /// Gup Points, credited to `users/{uid}.gupPoints`.
  points('points'),

  /// One free Bond Restore, credited as `users/{uid}.adRestoreCredits`.
  restore('restore');

  const AdRewardType(this.wire);
  final String wire;
}

/// Why a rewarded attempt ended. Only [earned] means the server was told to pay.
enum RewardedAdOutcome {
  /// The user watched enough of the ad to qualify. The credit is now in flight
  /// via SSV — it is *not* yet in Firestore, so the UI must wait for it rather
  /// than assume it.
  earned,

  /// Shown, but closed before qualifying. No reward, and nothing to apologise
  /// for — this is the user's choice.
  dismissedEarly,

  /// Rewarded ads are switched off, unsupported, or consent doesn't permit a
  /// request. Nothing was shown.
  unavailable,

  /// No ad filled, or the ad failed on the way to the screen.
  failed,
}

/// Loading is bounded: a spinner that never resolves is worse than "try again".
const Duration _kLoadTimeout = Duration(seconds: 20);

class RewardedAdService {
  RewardedAdService._();
  static final RewardedAdService instance = RewardedAdService._();

  RewardedAd? _ad;
  bool _loading = false;
  bool _showing = false;

  /// Whether an ad is already in hand, so the UI can offer an instant watch
  /// rather than a spinner.
  bool get isReady => _ad != null;

  /// Warm one ad up. Fire-and-forget — call it when entering a screen that
  /// offers rewards so the tap itself doesn't wait on a network round-trip.
  Future<void> preload() async {
    if (!AdsService.instance.canShowRewarded) return;
    if (_ad != null || _loading || _showing) return;
    await _load();
  }

  Future<void> _load() async {
    _loading = true;
    final loaded = Completer<RewardedAd?>();
    try {
      await RewardedAd.load(
        adUnitId: AdIds.rewarded,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (!loaded.isCompleted) loaded.complete(ad);
          },
          onAdFailedToLoad: (error) {
            debugPrint('[RewardedAd] ⚠️ load failed: $error');
            if (!loaded.isCompleted) loaded.complete(null);
          },
        ),
      );
      _ad = await loaded.future.timeout(_kLoadTimeout);
      if (_ad != null) debugPrint('[RewardedAd] ✅ loaded');
    } on TimeoutException {
      debugPrint('[RewardedAd] ⚠️ load timed out');
      _ad = null;
    } catch (e) {
      debugPrint('[RewardedAd] ⚠️ load threw: $e');
      _ad = null;
    } finally {
      _loading = false;
    }
  }

  /// Shows a rewarded ad for [uid], asking the server to grant [type].
  ///
  /// [roomId] is carried through to the SSV callback for the restore flow. It
  /// isn't needed to credit the reward — the credit lands on the user, not the
  /// room — but it makes a disputed restore traceable in the function logs.
  ///
  /// Returns once the ad is dismissed. [RewardedAdOutcome.earned] means Google
  /// accepted the view and the SSV callback is on its way; the caller must wait
  /// for the Firestore write, never credit locally.
  Future<RewardedAdOutcome> show({
    required String uid,
    required AdRewardType type,
    String? roomId,
  }) async {
    if (!AdsService.instance.canShowRewarded) return RewardedAdOutcome.unavailable;
    if (_showing) return RewardedAdOutcome.failed;

    if (_ad == null) {
      await _load();
      if (_ad == null) return RewardedAdOutcome.failed;
    }

    final ad = _ad!;
    _ad = null; // A rewarded ad is single-use; never hand the same one out twice.
    _showing = true;

    var earned = false;
    final dismissed = Completer<RewardedAdOutcome>();

    void finish(RewardedAdOutcome outcome) {
      if (!dismissed.isCompleted) dismissed.complete(outcome);
    }

    try {
      await ad.setServerSideOptions(ServerSideVerificationOptions(
        userId: uid,
        // Both `uid` and `type` are repeated here rather than relying on
        // `user_id` alone: `custom_data` is the only field that can carry the
        // reward type, and having the uid in the same signed blob lets the
        // function cross-check it instead of trusting one unauthenticated param.
        customData: jsonEncode(<String, dynamic>{
          'uid': uid,
          'type': type.wire,
          if (roomId != null) 'roomId': roomId,
        }),
      ));

      ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('[RewardedAd] ⚠️ failed to show: $error');
          ad.dispose();
          finish(RewardedAdOutcome.failed);
        },
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          finish(earned
              ? RewardedAdOutcome.earned
              : RewardedAdOutcome.dismissedEarly);
        },
      );

      await ad.show(onUserEarnedReward: (ad, reward) {
        // Note what Google's reward *says* is irrelevant here — amount and type
        // come from the server, which is the only party that decides what a view
        // is worth. This flag only records that the view qualified.
        earned = true;
        debugPrint('[RewardedAd] 🎁 qualified for ${type.wire}');
      });

      return await dismissed.future;
    } catch (e) {
      debugPrint('[RewardedAd] ⚠️ show threw: $e');
      try {
        ad.dispose();
      } catch (_) {}
      return RewardedAdOutcome.failed;
    } finally {
      _showing = false;
      // Warm the next one so a second reward doesn't make the user wait.
      unawaited(preload());
    }
  }

  /// Drop the cached ad. Call when leaving a screen that offers rewards so an
  /// unwatched ad isn't held (and doesn't go stale — AdMob expires preloaded
  /// ads after about an hour).
  void disposeAd() {
    _ad?.dispose();
    _ad = null;
  }
}
