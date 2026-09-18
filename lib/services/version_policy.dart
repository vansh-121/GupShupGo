// Retiring old builds, the way WhatsApp does it: a build is fine, then it is
// on notice with a visible countdown, then it stops working.
//
// Two Remote Config knobs drive it, and they are deliberately independent:
//
//   • `deprecated_below_version_code` + `support_deadline_iso` — the soft
//     phase. Builds below the code keep working and start warning; they become
//     unsupported when the deadline passes. This is the normal path, and the
//     client blocks *itself* on the date, so nobody has to be awake to flip a
//     switch at the deadline.
//   • `min_supported_version_code` — the hard floor, effective immediately and
//     with no date involved. This is the lever for "that build is broken, cut
//     it off now", and because no clock is consulted it is the one that cannot
//     be dodged by changing the device date.
//
// Both are inert unless `force_update_enabled` is true. Locking users out is
// the most destructive thing this app can do to itself, so the design gives it
// one obvious undo: a boolean, not an archaeology exercise over three numbers.
//
// **Time comes from [ServerClock]**, not `DateTime.now()`, so rolling the
// device date back does not buy extra days. Rolling it *forward* can bring the
// block on early — that is the honest limitation of a date-based rule, and it
// is why `min_supported_version_code` exists as the clock-free alternative.
// Once a device has actually observed the unsupported state it is latched in
// prefs, so the rollback trick does not work even for the rest of the session.
//
// [evaluateWith] is a pure function over explicit inputs: every rule below is
// covered by test/services/version_policy_test.dart without Firebase, and the
// instance method is only the wiring that reads Remote Config and prefs.

import 'package:flutter/foundation.dart';

import 'package:video_chat_app/main.dart' show sharedPrefs;
import 'package:video_chat_app/services/feature_flag_service.dart';
import 'package:video_chat_app/services/streak/server_clock.dart';

/// This build's Android `versionCode` — the `+NN` half of `pubspec.yaml`'s
/// `version:` line.
///
/// Hand-maintained alongside `kCurrentVersion`, and kept honest by
/// test/app_version_consistency_test.dart, which parses `pubspec.yaml` and
/// fails the build if the two ever disagree. That test is the reason this is a
/// constant rather than a `package_info_plus` lookup: the value is only ever
/// wrong if someone forgets to bump it, and the test makes forgetting loud.
const int kAppVersionCode = 56;

/// Where this build stands against the supported-version policy.
enum VersionSupportState {
  /// Supported. Says nothing about whether a *newer* build exists — that is
  /// Google Play's answer to give, via `UpdateService.checkForUpdate`.
  ok,

  /// Still works, but scheduled to stop. Warn, with a countdown when there is
  /// a date to count down to.
  expiring,

  /// Must not be used any further.
  unsupported,
}

/// The outcome of one policy evaluation.
@immutable
class VersionPolicy {
  const VersionPolicy(this.state, {this.daysLeft, this.deadline});

  /// A supported build with nothing to say.
  static const ok = VersionPolicy(VersionSupportState.ok);

  final VersionSupportState state;

  /// Whole days until [deadline], rounded up so a few remaining hours read as
  /// "1 day" rather than "0". Never zero while [state] is
  /// [VersionSupportState.expiring], and `null` when the build is deprecated
  /// but no deadline has been published yet.
  final int? daysLeft;

  /// The moment this build stops working, when one is set.
  final DateTime? deadline;

  /// Whether the app must refuse to run.
  bool get blocks => state == VersionSupportState.unsupported;

  /// Whether the user should be warned but not stopped.
  bool get warns => state == VersionSupportState.expiring;

  @override
  String toString() => 'VersionPolicy(${state.name}, daysLeft: $daysLeft)';
}

class VersionPolicyService {
  VersionPolicyService._();
  static final VersionPolicyService instance = VersionPolicyService._();

  /// Latches the moment a device first reads as unsupported. See the header —
  /// this is what stops "set the date back" from restoring a blocked build.
  static const _prefSticky = 'pref_version_unsupported_sticky';

  /// Throttle state for the expiring warning.
  static const _prefLastWarnedMs = 'pref_version_warn_last_ms';

  /// Evaluates the live policy: Remote Config for the rules, [ServerClock] for
  /// the time, prefs for the latch.
  VersionPolicy evaluate() {
    final flags = FeatureFlagService.instance;
    return evaluateWith(
      installed: kAppVersionCode,
      enforcementEnabled: flags.forceUpdateEnabled,
      minSupported: flags.minSupportedVersionCode,
      deprecatedBelow: flags.deprecatedBelowVersionCode,
      deadline: flags.supportDeadline,
      now: ServerClock.now(),
      sticky: sharedPrefs.getBool(_prefSticky) ?? false,
    );
  }

  /// Evaluates and persists the latch, so a later evaluation in the same
  /// install cannot be talked out of a block it has already made.
  ///
  /// Also *clears* the latch when the policy no longer condemns this build —
  /// which is what makes rolling back a bad Remote Config value actually
  /// release the users it caught.
  Future<VersionPolicy> evaluateAndLatch() async {
    final policy = evaluate();
    final latched = sharedPrefs.getBool(_prefSticky) ?? false;

    if (policy.blocks && !latched) {
      await sharedPrefs.setBool(_prefSticky, true);
    } else if (!policy.blocks && latched) {
      await sharedPrefs.remove(_prefSticky);
    }
    return policy;
  }

  // ── The rules ─────────────────────────────────────────────────────────────
  /// Pure policy decision. No Firebase, no prefs, no clock of its own.
  ///
  /// Order matters: the hard floor is checked before the deadline so that
  /// raising `min_supported_version_code` takes effect regardless of what the
  /// soft phase says, and the latch is checked before the deadline so a
  /// backwards clock cannot undo a block.
  static VersionPolicy evaluateWith({
    required int installed,
    required bool enforcementEnabled,
    required int minSupported,
    required int deprecatedBelow,
    required DateTime? deadline,
    required DateTime now,
    bool sticky = false,
  }) {
    // Master switch off → the policy does not exist. Checked first so that
    // flipping it back off releases even a device that already latched.
    if (!enforcementEnabled) return VersionPolicy.ok;

    // Hard floor. Clock-free, immediate.
    if (minSupported > 0 && installed < minSupported) {
      return const VersionPolicy(VersionSupportState.unsupported);
    }

    // Not deprecated → nothing to say. Note this also covers the case where
    // only the hard floor is configured and this build clears it.
    if (deprecatedBelow <= 0 || installed >= deprecatedBelow) {
      return VersionPolicy.ok;
    }

    // Deprecated, and this device has already been told it is out of support.
    if (sticky) return const VersionPolicy(VersionSupportState.unsupported);

    // Deprecated with no date published yet: warn without a countdown rather
    // than inventing a deadline.
    if (deadline == null) {
      return const VersionPolicy(VersionSupportState.expiring);
    }

    final remaining = deadline.difference(now);
    if (!remaining.isNegative && remaining.inSeconds > 0) {
      // Round up: a build with six hours left is on its last day, not its
      // zeroth. The floor at 1 covers the final minute, where the division
      // truncates to zero and the dialog would otherwise read "in 0 days".
      final days = (remaining.inMinutes / Duration.minutesPerDay).ceil();
      return VersionPolicy(
        VersionSupportState.expiring,
        daysLeft: days < 1 ? 1 : days,
        deadline: deadline,
      );
    }

    return VersionPolicy(
      VersionSupportState.unsupported,
      deadline: deadline,
    );
  }

  // ── Warning cadence ───────────────────────────────────────────────────────
  /// How long to stay quiet between two expiry warnings.
  ///
  /// Escalates as the deadline closes: a daily reminder three weeks out would
  /// be nagging, and a daily reminder on the last day would be negligent.
  /// [Duration.zero] means "every time the app is opened".
  @visibleForTesting
  static Duration warnInterval(int? daysLeft) {
    if (daysLeft == null) return const Duration(hours: 24);
    if (daysLeft <= 3) return Duration.zero;
    if (daysLeft <= 7) return const Duration(hours: 6);
    return const Duration(hours: 24);
  }

  /// Whether the expiry warning is due. Only meaningful for an expiring
  /// policy — anything else answers `false`, so callers don't have to
  /// pre-filter.
  bool shouldWarn(VersionPolicy policy, {DateTime? now}) {
    if (!policy.warns) return false;

    final interval = warnInterval(policy.daysLeft);
    if (interval == Duration.zero) return true;

    final last = sharedPrefs.getInt(_prefLastWarnedMs);
    if (last == null) return true;

    final elapsed = (now ?? ServerClock.now())
        .difference(DateTime.fromMillisecondsSinceEpoch(last, isUtc: true))
        // A clock that jumped backwards should re-warn, not go silent for
        // however long the jump was.
        .abs();
    return elapsed >= interval;
  }

  /// Records that the warning was just shown.
  Future<void> markWarned({DateTime? now}) => sharedPrefs.setInt(
        _prefLastWarnedMs,
        (now ?? ServerClock.now()).millisecondsSinceEpoch,
      );

  /// Drops the latch and the warning throttle. For tests and a debug reset.
  @visibleForTesting
  Future<void> reset() async {
    await sharedPrefs.remove(_prefSticky);
    await sharedPrefs.remove(_prefLastWarnedMs);
  }
}
