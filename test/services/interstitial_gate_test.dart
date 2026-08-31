// The interstitial pacing rules, as arithmetic.
//
// An interstitial is the only format in this app that takes the whole screen
// without being asked for, so these two functions are the entire difference
// between "an ad at a natural break" and "an ad break". Everything else in
// InterstitialAdService is plumbing around an SDK that will happily show a
// second fullscreen ad one second after the first.
//
// Both gates are worth pinning for the same reason the review gate is: a leak
// past them is invisible in testing — the ad shows, the SDK is happy, nothing
// logs an error — and surfaces later as users saying the app is full of ads. So
// the interesting assertions here are the ones that say *no*, plus the two
// fenceposts that would each silently break a whole trigger if written the
// other way round: the zero that means "never shown", and the zero that means
// "no skips yet".

import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/services/ads/interstitial_ad_service.dart';

/// Fixed "now" so the tests never depend on the wall clock.
final DateTime now = DateTime.utc(2026, 8, 21, 12);

int msAgo(Duration d) => now.subtract(d).millisecondsSinceEpoch;

/// The stranger-skip gap: short, because a skip is a deliberate request for new
/// content and the user is moving through them quickly.
const Duration kSkipGap = Duration(seconds: 60);

/// The post-call gap. Much longer on purpose — an ad after every call teaches
/// users that calling costs them something.
const Duration kCallGap = Duration(hours: 4);

/// [InterstitialAdService.shouldShow] with the never-shown case as the default,
/// so each test overrides only the thing it is about.
bool show({Duration? lastShown, Duration gap = kSkipGap}) =>
    InterstitialAdService.shouldShow(
      lastShownMs: lastShown == null ? 0 : msAgo(lastShown),
      nowMs: now.millisecondsSinceEpoch,
      minGapMs: gap.inMilliseconds,
    );

void main() {
  group('the time gap', () {
    test('nothing shown yet means show', () {
      expect(show(), isTrue);
    });

    test('a zero stamp means never shown, not shown at the epoch', () {
      // The fencepost worth pinning. Read as a real date, 0 is 1970 — further
      // back than any gap, so it passes on the arithmetic alone. But written
      // the other way round it would fail, and the very first interstitial in
      // the app would wait for a gap that could never elapse, because nothing
      // would ever be shown to start the clock.
      expect(show(lastShown: null), isTrue);
      expect(show(lastShown: null, gap: kCallGap), isTrue);
    });

    test('inside the gap, no ad', () {
      expect(show(lastShown: Duration.zero), isFalse);
      expect(show(lastShown: const Duration(seconds: 1)), isFalse);
      expect(show(lastShown: const Duration(seconds: 59)), isFalse);
    });

    test('the gap boundary opens the window', () {
      expect(show(lastShown: const Duration(seconds: 60)), isTrue);
      expect(show(lastShown: const Duration(seconds: 61)), isTrue);
      expect(show(lastShown: const Duration(hours: 3)), isTrue);
    });

    test('the same arithmetic serves the much longer post-call gap', () {
      // Two triggers, two stamps, one function. If this ever needed its own
      // implementation, the post-call floor would be the one to quietly lose.
      expect(show(lastShown: const Duration(hours: 1), gap: kCallGap), isFalse);
      expect(
        show(lastShown: const Duration(hours: 3, minutes: 59), gap: kCallGap),
        isFalse,
      );
      expect(show(lastShown: const Duration(hours: 4), gap: kCallGap), isTrue);
      expect(show(lastShown: const Duration(days: 2), gap: kCallGap), isTrue);
    });

    test('a stamp in the future reads as just-shown, not as long ago', () {
      // A timezone change, an NTP correction, or a user setting the date
      // forward and back. Subtracting in the naive direction gives a large
      // negative, which compares as "well past the gap" and hands out an ad on
      // every trigger until the clock catches up — potentially for hours.
      final int future = now.add(const Duration(hours: 1)).millisecondsSinceEpoch;
      expect(
        InterstitialAdService.shouldShow(
          lastShownMs: future,
          nowMs: now.millisecondsSinceEpoch,
          minGapMs: kSkipGap.inMilliseconds,
        ),
        isFalse,
      );
      expect(
        InterstitialAdService.shouldShow(
          lastShownMs: now.add(const Duration(days: 365)).millisecondsSinceEpoch,
          nowMs: now.millisecondsSinceEpoch,
          minGapMs: kCallGap.inMilliseconds,
        ),
        isFalse,
      );
    });

    test('a zero gap is still gated by nothing but the gap', () {
      // Not a configuration anyone should ship, but Remote Config can deliver
      // it, and it must degrade to "no pacing" rather than to a crash or to a
      // permanently shut gate.
      expect(show(lastShown: Duration.zero, gap: Duration.zero), isTrue);
    });
  });

  group('which skip earns an ad', () {
    test('no skips yet is not a skip', () {
      // The other fencepost. `isSkipDue` is called with a count that starts at
      // zero, and 0 % 3 == 0 — so without the explicit positive check the
      // counter would read as due before the user had skipped anything at all.
      expect(InterstitialAdService.isSkipDue(0), isFalse);
    });

    test('the first two skips are free', () {
      expect(InterstitialAdService.isSkipDue(1), isFalse);
      expect(InterstitialAdService.isSkipDue(2), isFalse);
    });

    test('every third skip is due', () {
      expect(InterstitialAdService.isSkipDue(3), isTrue);
      expect(InterstitialAdService.isSkipDue(6), isTrue);
      expect(InterstitialAdService.isSkipDue(9), isTrue);
      expect(InterstitialAdService.isSkipDue(300), isTrue);
    });

    test('and no other skip is', () {
      for (final n in [4, 5, 7, 8, 10, 11, 100, 101]) {
        expect(
          InterstitialAdService.isSkipDue(n),
          isFalse,
          reason: 'skip $n should not be due',
        );
      }
    });

    test('never two in a row', () {
      // The property that makes a counter better than a random roll: whatever
      // the count, a due skip is always followed by a skip that is not.
      for (int n = 1; n <= 60; n++) {
        if (InterstitialAdService.isSkipDue(n)) {
          expect(InterstitialAdService.isSkipDue(n + 1), isFalse);
        }
      }
    });

    test('a negative count is not due', () {
      // Corrupt or hand-edited prefs. Dart's `%` returns a non-negative result
      // for a positive divisor, so -3 % 3 is 0 and would otherwise read as due
      // — the positive check is doing real work here, not defending against an
      // impossible input.
      expect(InterstitialAdService.isSkipDue(-1), isFalse);
      expect(InterstitialAdService.isSkipDue(-3), isFalse);
      expect(InterstitialAdService.isSkipDue(-9), isFalse);
    });
  });
}
