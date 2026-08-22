// Google Play's in-app review sheet, asked for at moments the user is plausibly
// pleased and nowhere else.
//
// Three properties of the platform API shape this file more than any product
// decision did:
//
//   • Play never says what happened. `requestReview()` completes identically
//     whether the sheet appeared, the user dismissed it, the user submitted a
//     review, or Play silently swallowed the call for being over its own
//     undocumented quota. So an ask is recorded as *spent* before the call is
//     made. Recording afterwards, or waiting for an outcome, would mean asking
//     forever — the state we would be waiting on never arrives.
//
//   • Google's guidance forbids a sentiment question in front of the sheet
//     ("Do you like the app?"), so there is no custom dialog here at all. The
//     consequence is that an unhappy user can see the sheet too; the mitigation
//     is *when* we ask, not a filter on who.
//
//   • The same guidance says not to put `requestReview()` behind a button,
//     because the quota makes it unreliable as a call to action. So the menu and
//     Settings entries call [openStoreListing], which carries no quota and
//     always does something visible.
//
// The gate below is a second fence in front of Play's own quota, not a
// replacement for it. There is deliberately no lifetime cap on asks, so Play's
// undocumented quota is the outer ceiling on how often a sheet actually appears
// — and being inside our own forty-day window says nothing about whether Play
// will show anything at all.

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_review/in_app_review.dart';

import '../main.dart' show sharedPrefs;
import '../utils/url_opener.dart';

/// Minimum gap between two automatic asks.
///
/// There is no lifetime limit by design: once this much time has passed, the
/// next good trigger — a good call, or a launch by an established user — makes
/// the user eligible again, indefinitely.
const Duration _kMinGap = Duration(days: 40);

/// How established an account has to be before the first ask. Applies to the
/// call trigger as well, so a brand-new user is never asked after their first
/// good call.
const Duration _kMinAccountAge = Duration(days: 7);

/// Real talk time a call needs before it counts as a good one.
const Duration _kGoodCallDuration = Duration(minutes: 2);

// Keys follow the `starter_v1_` / `coach_v1_` convention: prefixed and
// version-suffixed, so bumping to `review_v2_` would deliberately reset every
// user's eligibility.
const String _kLastAskKey = 'review_v1_last_ask_ms';
const String _kFirstSeenKey = 'review_v1_first_seen_ms';

/// Play Store listing for the Android build. `market://` would be the more
/// idiomatic scheme, but the manifest's `<queries>` block declares the http(s)
/// ACTION_VIEW intent and not `market`, so the https form is the one that
/// survives Android 11+ package visibility on the url_launcher fallback path.
const String _kPlayListingUrl =
    'https://play.google.com/store/apps/details?id=com.gupshupgo.app';

class ReviewPromptService {
  ReviewPromptService._();

  static final ReviewPromptService instance = ReviewPromptService._();

  /// Whether a call that just ended was pleasant enough to ask on the back of.
  ///
  /// [remoteJoined] is the discriminator that rules out declined, missed and
  /// cancelled calls — it is the same flag `CallScreen._createCallLog` uses to
  /// decide `CallStatus.answered`. [durationSeconds] is talk time only; the call
  /// screen's timer starts when the peer joins, so ringing does not count.
  static bool isGoodCall({
    required bool remoteJoined,
    required int durationSeconds,
  }) =>
      remoteJoined && durationSeconds >= _kGoodCallDuration.inSeconds;

  /// The eligibility decision, as arithmetic over three numbers so it can be
  /// tested without SharedPreferences, a Play connection, or a clock.
  ///
  /// [sinceMs] is when this user became countable — account creation date where
  /// we have one, first launch otherwise. [lastAskMs] is 0 when no ask has ever
  /// been made, which must read as "never asked" rather than "asked at the
  /// epoch"; the latter would be caught by the gap check and every first ask
  /// would be deferred by forty days.
  @visibleForTesting
  static bool shouldAsk({
    required int lastAskMs,
    required int sinceMs,
    required int nowMs,
  }) {
    if (nowMs - sinceMs < _kMinAccountAge.inMilliseconds) return false;
    if (lastAskMs != 0 && nowMs - lastAskMs < _kMinGap.inMilliseconds) {
      return false;
    }
    return true;
  }

  /// Asks Play to show the review sheet, if the user is eligible.
  ///
  /// Fire-and-forget: never throws, never reports back, and no-ops silently far
  /// more often than it does anything. [trigger] only labels the debug line.
  ///
  /// [accountCreatedAt] is `UserModel.createdAt`, which is nullable — accounts
  /// predating the field would otherwise be locked out of the age gate forever,
  /// so a locally stamped first-seen date stands in. Such a user simply starts
  /// their seven days at the first launch after this ships.
  Future<void> maybeRequest({
    required String trigger,
    DateTime? accountCreatedAt,
  }) async {
    // iOS has no App Store listing yet; see the note on [openStoreListing].
    if (!Platform.isAndroid) return;

    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      var firstSeenMs = sharedPrefs.getInt(_kFirstSeenKey) ?? 0;
      if (firstSeenMs == 0) {
        firstSeenMs = now;
        await sharedPrefs.setInt(_kFirstSeenKey, firstSeenMs);
      }

      final lastAskMs = sharedPrefs.getInt(_kLastAskKey) ?? 0;

      // Cheap enough to run on every launch: two prefs reads and no platform
      // channel until the window actually opens.
      if (!shouldAsk(
        lastAskMs: lastAskMs,
        sinceMs: accountCreatedAt?.millisecondsSinceEpoch ?? firstSeenMs,
        nowMs: now,
      )) {
        return;
      }

      // False on emulators, sideloaded builds, and devices without Play.
      if (!await InAppReview.instance.isAvailable()) {
        if (kDebugMode) {
          debugPrint('[Review] $trigger: Play review not available');
        }
        return;
      }

      // Stamp the ask first — see the note at the top of this file. If the
      // process dies between this write and the request, the cost is one missed
      // opportunity and the next window opens in forty days, which is the right
      // way to be wrong.
      await sharedPrefs.setInt(_kLastAskKey, now);

      if (kDebugMode) debugPrint('[Review] $trigger: requesting sheet');
      await InAppReview.instance.requestReview();
    } catch (e) {
      if (kDebugMode) debugPrint('[Review] $trigger failed: $e');
    }
  }

  /// Opens the store listing directly. Unlike [maybeRequest] this is not
  /// quota-limited and always does something visible, which is why it — and not
  /// the review sheet — is what the menu entries call.
  ///
  /// Deliberately does not stamp the last-ask date: the user chose to come here,
  /// so closing their next automatic window for forty days would be backwards.
  ///
  /// [context] is only needed for the url_launcher fallback, which is also the
  /// iOS path: `openStoreListing` requires an `appStoreId` there and no App
  /// Store listing exists yet.
  Future<void> openStoreListing({BuildContext? context}) async {
    if (Platform.isAndroid) {
      try {
        // The plugin calls startActivity natively, so the manifest `<queries>`
        // rules that constrain url_launcher do not apply here.
        await InAppReview.instance.openStoreListing();
        return;
      } catch (e) {
        if (kDebugMode) debugPrint('[Review] openStoreListing failed: $e');
        // Fall through to the browser: Play can be absent on a sideloaded
        // device, and a tap that does nothing at all is the worst outcome here.
      }
    }

    // Also the iOS path — `openStoreListing` needs an `appStoreId` there and no
    // App Store listing exists yet. Never throws; reports its own failure with
    // a snackbar, which is why there is no catch around it.
    if (context != null && context.mounted) {
      await openExternalUrl(context, _kPlayListingUrl);
    }
  }
}
