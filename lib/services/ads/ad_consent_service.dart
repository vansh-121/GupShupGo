/// GupShupGo — AdMob consent (Google User Messaging Platform).
///
/// Under GDPR and the EU DMA, a certified CMP has to collect consent *before*
/// any personal data reaches Google for advertising. `google_mobile_ads` bundles
/// Google's own CMP (UMP), which is what this wraps. This is not optional
/// polish: serving personalised ads in the EEA without it is both a legal
/// exposure and an AdMob policy breach.
///
/// Two-step by design:
///
/// 1. [refresh] — no UI. Asks UMP what this device's consent state is for its
///    geography, and answers [canRequestAds]. Safe to call at startup.
/// 2. [gather] — may show the consent form. Only ever called from a surface
///    that actually shows ads (the home tabs, or a rewarded-ad tap), never over
///    the auth or PIN flow, so a brand-new user is not greeted by a consent
///    dialog before they have even signed in.
///
/// Outside a regulated region UMP requires no form at all and [gather] is a
/// no-op that leaves [canRequestAds] true.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_service.dart' show kAdTestDeviceIds;

/// Pretend this device is in the given region, for debug builds only.
///
/// Set to [DebugGeography.debugGeographyEea] to exercise the consent form from
/// India without a VPN — it only takes effect for devices listed in
/// [kAdTestDeviceIds], so it cannot leak into a real user's session even if a
/// debug build escapes.
const DebugGeography _kDebugGeography = DebugGeography.debugGeographyDisabled;

/// UMP calls can hang if the consent endpoint is unreachable. Ads are never
/// worth stalling a screen for, so every await here is bounded.
const Duration _kConsentTimeout = Duration(seconds: 12);

class AdConsentService {
  AdConsentService._();
  static final AdConsentService instance = AdConsentService._();

  bool _canRequestAds = false;

  /// Whether ad requests are permitted for this user right now.
  ///
  /// Starts `false` and only becomes true once UMP has been consulted, so the
  /// failure mode is "no ads", never "ads without consent".
  bool get canRequestAds => _canRequestAds;

  bool _privacyOptionsRequired = false;

  /// Whether this user must be offered a way to change their choice later.
  /// Drives the visibility of Settings → Privacy → Ad preferences; UMP requires
  /// that entry point to exist wherever this is true.
  bool get privacyOptionsRequired => _privacyOptionsRequired;

  Future<void>? _refreshFuture;

  /// Reads the current consent state. Idempotent — concurrent callers share one
  /// in-flight request, and later calls reuse the result.
  Future<void> refresh() => _refreshFuture ??= _refresh();

  Future<void> _refresh() async {
    try {
      final params = ConsentRequestParameters(
        consentDebugSettings: kDebugMode
            ? ConsentDebugSettings(
                debugGeography: _kDebugGeography,
                testIdentifiers: kAdTestDeviceIds,
              )
            : null,
      );

      final updated = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () {
          if (!updated.isCompleted) updated.complete();
        },
        (FormError error) {
          // Deliberately not an error path. UMP persists the last known consent
          // on the device, so a returning user who already consented should keep
          // seeing ads through a network blip — reading the cached status below
          // is more accurate than assuming the worst.
          debugPrint('[AdConsent] ⚠️ info update failed '
              '(${error.errorCode}): ${error.message}');
          if (!updated.isCompleted) updated.complete();
        },
      );
      await updated.future.timeout(_kConsentTimeout);
    } on TimeoutException {
      debugPrint('[AdConsent] ⚠️ info update timed out');
    } catch (e) {
      debugPrint('[AdConsent] ⚠️ info update threw: $e');
    }

    await _readStatus();
  }

  /// Shows the consent form if — and only if — UMP says one is required.
  ///
  /// Call this from a screen that may show ads. Cheap to call repeatedly: once
  /// consent exists, the SDK short-circuits and no form appears.
  Future<void> gather() async {
    await refresh();
    try {
      await ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
        if (error != null) {
          debugPrint('[AdConsent] ⚠️ form dismissed with error '
              '(${error.errorCode}): ${error.message}');
        }
      }).timeout(_kConsentTimeout);
    } on TimeoutException {
      debugPrint('[AdConsent] ⚠️ consent form timed out');
    } catch (e) {
      debugPrint('[AdConsent] ⚠️ consent form threw: $e');
    }

    // The user may have just granted or refused consent, so re-read rather than
    // trusting the value from before the form.
    await _readStatus();
  }

  /// Reopens the privacy options form so a user can change or withdraw consent.
  /// Wired to Settings → Privacy → Ad preferences.
  ///
  /// Returns `false` if the form could not be shown, so the caller can tell the
  /// user something went wrong instead of appearing to do nothing.
  Future<bool> showPrivacyOptionsForm() async {
    FormError? failure;
    try {
      await ConsentForm.showPrivacyOptionsForm((FormError? error) {
        failure = error;
      }).timeout(_kConsentTimeout);
    } on TimeoutException {
      debugPrint('[AdConsent] ⚠️ privacy options form timed out');
      return false;
    } catch (e) {
      debugPrint('[AdConsent] ⚠️ privacy options form threw: $e');
      return false;
    }

    await _readStatus();

    if (failure != null) {
      debugPrint('[AdConsent] ⚠️ privacy options form failed '
          '(${failure!.errorCode}): ${failure!.message}');
      return false;
    }
    return true;
  }

  /// Wipes the stored consent so the form appears again on the next [gather].
  /// Debug-only — resetting a real user's consent would silently drop them back
  /// to non-personalised ads and re-prompt them for no reason.
  Future<void> resetConsent() async {
    if (!kDebugMode) return;
    try {
      await ConsentInformation.instance.reset();
      _refreshFuture = null;
      _canRequestAds = false;
      _privacyOptionsRequired = false;
      debugPrint('[AdConsent] 🔄 consent reset');
    } catch (e) {
      debugPrint('[AdConsent] ⚠️ reset failed: $e');
    }
  }

  Future<void> _readStatus() async {
    try {
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
      final status =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      _privacyOptionsRequired =
          status == PrivacyOptionsRequirementStatus.required;
      debugPrint('[AdConsent] canRequestAds=$_canRequestAds, '
          'privacyOptionsRequired=$_privacyOptionsRequired');
    } catch (e) {
      // Leave the previous values alone — a failed read is not a withdrawal.
      debugPrint('[AdConsent] ⚠️ status read failed: $e');
    }
  }
}
