// The rules for retiring a build — the ones that can lock a user out.
//
// This is the highest-stakes policy in the app: a wrong answer here does not
// degrade an experience, it removes it. So the tests are written around the
// failure modes rather than the happy path:
//
//   • The kill switch genuinely kills. `force_update_enabled` is checked before
//     everything, including a device that has already latched itself as
//     unsupported — otherwise a mistyped version code would be unrecoverable
//     for every user who had already opened the app once.
//   • Rolling the config back releases people. A latch that only ever set
//     itself would turn a five-minute mistake into a permanent one.
//   • Rolling the *clock* back does not. The latch is the whole reason that
//     rule holds, and `min_supported_version_code` is the clock-free lever for
//     when even that is not enough.
//   • The countdown never reads "0 days", including in the last minute before
//     the deadline, because that sentence is nonsense to the person reading it.
//
// [VersionPolicyService.evaluateWith] is pure, so the state machine is tested
// with explicit inputs and no Firebase. Only the throttle needs the prefs
// harness, which follows test/services/whats_new_service_test.dart: the global
// is a `late final` assigned once, so isolation comes from clear().

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_chat_app/main.dart' show sharedPrefs;
import 'package:video_chat_app/services/version_policy.dart';

/// A fixed "now". Everything else is expressed relative to it so no test
/// depends on the wall clock.
final _now = DateTime.utc(2026, 6, 1, 12);

/// Evaluates with the whole policy switched on and this build sitting below
/// the deprecation line — the configuration every interesting case lives in.
/// Named arguments override individual knobs.
VersionPolicy _evaluate({
  int installed = 56,
  bool enforcementEnabled = true,
  int minSupported = 0,
  int deprecatedBelow = 60,
  DateTime? deadline,
  DateTime? now,
  bool sticky = false,
}) {
  return VersionPolicyService.evaluateWith(
    installed: installed,
    enforcementEnabled: enforcementEnabled,
    minSupported: minSupported,
    deprecatedBelow: deprecatedBelow,
    deadline: deadline,
    now: now ?? _now,
    sticky: sticky,
  );
}

/// The warning throttle's storage key, duplicated as a literal on purpose: if
/// the production constant is renamed, these tests should fail rather than
/// quietly agree with themselves about a key nobody writes any more.
const _lastWarnedKey = 'pref_version_warn_last_ms';

void main() {
  group('the kill switch', () {
    // The recovery lever. If this test ever fails, a typo in Remote Config is
    // no longer undoable, and the blast radius is the entire install base.
    test('makes every other knob inert', () {
      final policy = _evaluate(
        enforcementEnabled: false,
        installed: 1,
        minSupported: 999,
        deprecatedBelow: 999,
        deadline: _now.subtract(const Duration(days: 30)),
      );

      expect(policy.state, VersionSupportState.ok);
      expect(policy.blocks, isFalse);
      expect(policy.warns, isFalse);
    });

    test('releases a device that already latched as unsupported', () {
      expect(
        _evaluate(enforcementEnabled: false, sticky: true).state,
        VersionSupportState.ok,
      );
    });
  });

  group('the hard floor', () {
    test('blocks immediately below min_supported_version_code', () {
      final policy = _evaluate(installed: 55, minSupported: 56);

      expect(policy.state, VersionSupportState.unsupported);
      expect(policy.blocks, isTrue);
    });

    // The point of the hard floor is that it answers without asking the clock,
    // so a device with a doctored date is cut off exactly the same.
    test('ignores the deadline and the device clock', () {
      final policy = _evaluate(
        installed: 55,
        minSupported: 56,
        deadline: _now.add(const Duration(days: 365)),
        now: DateTime.utc(1999),
      );

      expect(policy.state, VersionSupportState.unsupported);
    });

    test('is off when left at zero', () {
      expect(
        _evaluate(installed: 56, minSupported: 0, deprecatedBelow: 0).state,
        VersionSupportState.ok,
      );
    });

    test('lets a build that clears it through', () {
      expect(
        _evaluate(installed: 56, minSupported: 56, deprecatedBelow: 0).state,
        VersionSupportState.ok,
      );
    });
  });

  group('a supported build', () {
    test('is ok at the deprecation line', () {
      expect(_evaluate(installed: 60, deprecatedBelow: 60).state,
          VersionSupportState.ok);
    });

    test('is ok above the deprecation line', () {
      expect(_evaluate(installed: 61, deprecatedBelow: 60).state,
          VersionSupportState.ok);
    });

    // Nothing configured is the state this ships in, and it must be silent.
    test('is ok when no deprecation line is set', () {
      expect(
        _evaluate(deprecatedBelow: 0, deadline: _now.subtract(_oneDay)).state,
        VersionSupportState.ok,
      );
    });
  });

  group('the countdown', () {
    test('warns without a number when no deadline is published', () {
      final policy = _evaluate(deadline: null);

      expect(policy.state, VersionSupportState.expiring);
      expect(policy.warns, isTrue);
      expect(policy.daysLeft, isNull);
      expect(policy.blocks, isFalse);
    });

    test('counts whole days to the deadline', () {
      for (final days in [15, 7, 3, 1]) {
        final policy = _evaluate(deadline: _now.add(Duration(days: days)));

        expect(policy.state, VersionSupportState.expiring, reason: '$days');
        expect(policy.daysLeft, days, reason: '$days');
        expect(policy.deadline, _now.add(Duration(days: days)));
      }
    });

    // Rounding up, so a user with a few hours left is told "1 day" rather than
    // being quietly undercounted into "0".
    test('rounds a partial day up', () {
      expect(_evaluate(deadline: _now.add(const Duration(hours: 6))).daysLeft,
          1);
      expect(
        _evaluate(deadline: _now.add(const Duration(days: 6, hours: 1)))
            .daysLeft,
        7,
      );
    });

    // The last minute. Integer division truncates here, and the dialog would
    // read "This version stops working in 0 days".
    test('never reads zero, even seconds from the deadline', () {
      final policy = _evaluate(deadline: _now.add(const Duration(seconds: 30)));

      expect(policy.state, VersionSupportState.expiring);
      expect(policy.daysLeft, 1);
    });
  });

  group('past the deadline', () {
    test('is unsupported', () {
      final deadline = _now.subtract(const Duration(minutes: 1));
      final policy = _evaluate(deadline: deadline);

      expect(policy.state, VersionSupportState.unsupported);
      expect(policy.blocks, isTrue);
      expect(policy.deadline, deadline);
    });

    test('is unsupported exactly at the deadline', () {
      expect(_evaluate(deadline: _now).state, VersionSupportState.unsupported);
    });
  });

  group('the latch', () {
    // The rule that makes a date-based policy hold up. Without it, a device
    // that has seen the block only needs its clock moved back to undo it.
    test('keeps a blocked build blocked when the clock moves backwards', () {
      final policy = _evaluate(
        deadline: _now.add(const Duration(days: 30)),
        sticky: true,
      );

      expect(policy.state, VersionSupportState.unsupported);
    });

    test('still applies when no deadline is published', () {
      expect(_evaluate(deadline: null, sticky: true).state,
          VersionSupportState.unsupported);
    });

    // A latch that only ever set itself would make a bad config value
    // permanent for everyone who opened the app while it was live.
    test('does not survive raising the deprecation line back', () {
      expect(
        _evaluate(installed: 56, deprecatedBelow: 50, sticky: true).state,
        VersionSupportState.ok,
      );
    });
  });

  group('the warning cadence', () {
    test('escalates as the deadline closes', () {
      expect(VersionPolicyService.warnInterval(null), const Duration(hours: 24));
      expect(VersionPolicyService.warnInterval(15), const Duration(hours: 24));
      expect(VersionPolicyService.warnInterval(8), const Duration(hours: 24));
      expect(VersionPolicyService.warnInterval(7), const Duration(hours: 6));
      expect(VersionPolicyService.warnInterval(4), const Duration(hours: 6));
      expect(VersionPolicyService.warnInterval(3), Duration.zero);
      expect(VersionPolicyService.warnInterval(1), Duration.zero);
    });
  });

  group('shouldWarn', () {
    final service = VersionPolicyService.instance;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      sharedPrefs = await SharedPreferences.getInstance();
    });

    setUp(() async {
      await sharedPrefs.clear();
    });

    // Callers pass whatever the policy evaluated to, so anything that isn't a
    // warning has to answer "no" rather than be pre-filtered at every site.
    test('says no for a policy that is not expiring', () {
      expect(service.shouldWarn(VersionPolicy.ok, now: _now), isFalse);
      expect(
        service.shouldWarn(
          const VersionPolicy(VersionSupportState.unsupported),
          now: _now,
        ),
        isFalse,
      );
    });

    test('says yes the first time', () {
      expect(service.shouldWarn(_expiring(15), now: _now), isTrue);
    });

    test('goes quiet for a day after a warning, then comes back', () async {
      await service.markWarned(now: _now);

      expect(service.shouldWarn(_expiring(15), now: _now), isFalse);
      expect(
        service.shouldWarn(_expiring(15), now: _now.add(const Duration(hours: 23))),
        isFalse,
      );
      expect(
        service.shouldWarn(_expiring(15), now: _now.add(const Duration(hours: 25))),
        isTrue,
      );
    });

    test('drops to six hours inside the final week', () async {
      await service.markWarned(now: _now);

      expect(service.shouldWarn(_expiring(6), now: _now), isFalse);
      expect(
        service.shouldWarn(_expiring(6), now: _now.add(const Duration(hours: 7))),
        isTrue,
      );
    });

    // Three days out, every open is a reminder. At that point the cost of
    // being mildly annoying is far below the cost of being locked out.
    test('warns on every open in the last three days', () async {
      await service.markWarned(now: _now);

      expect(service.shouldWarn(_expiring(3), now: _now), isTrue);
      expect(service.shouldWarn(_expiring(1), now: _now), isTrue);
    });

    test('re-warns rather than going silent when the clock jumps back',
        () async {
      await service.markWarned(now: _now);

      expect(
        service.shouldWarn(_expiring(15), now: _now.subtract(_oneDay)),
        isTrue,
      );
    });

    test('markWarned records the time it was given', () async {
      await service.markWarned(now: _now);

      expect(sharedPrefs.getInt(_lastWarnedKey), _now.millisecondsSinceEpoch);
    });

    test('reset clears the throttle and the latch', () async {
      await service.markWarned(now: _now);
      await sharedPrefs.setBool('pref_version_unsupported_sticky', true);

      await service.reset();

      expect(sharedPrefs.getInt(_lastWarnedKey), isNull);
      expect(sharedPrefs.getBool('pref_version_unsupported_sticky'), isNull);
    });
  });
}

const _oneDay = Duration(days: 1);

VersionPolicy _expiring(int daysLeft) => VersionPolicy(
      VersionSupportState.expiring,
      daysLeft: daysLeft,
      deadline: _now.add(Duration(days: daysLeft)),
    );
