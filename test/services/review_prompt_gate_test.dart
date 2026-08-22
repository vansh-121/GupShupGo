// The review-ask eligibility rules, as arithmetic.
//
// `shouldAsk` is the whole policy — everything else in ReviewPromptService is
// plumbing around a platform API that reports nothing back. Since Play silently
// swallows over-quota calls, an ask that leaks past this gate is invisible in
// testing and shows up months later as a user complaining the app nags. There is
// no lifetime cap to fall back on, so this gate is the only thing standing
// between a good trigger and a sheet. The interesting assertions here are the
// ones that say *no*, and the fenceposts: the exact day a window opens, and the
// zero that means "never asked" rather than "asked in 1970".

import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/services/review_prompt_service.dart';

/// Fixed "now" so the tests never depend on the wall clock.
final DateTime now = DateTime.utc(2026, 8, 21, 12);

int msAgo(Duration d) => now.subtract(d).millisecondsSinceEpoch;

/// [shouldAsk] with the established-account case as the default, so each test
/// overrides only the thing it is about.
bool ask({
  Duration? lastAsk,
  Duration accountAge = const Duration(days: 30),
}) =>
    ReviewPromptService.shouldAsk(
      lastAskMs: lastAsk == null ? 0 : msAgo(lastAsk),
      sinceMs: msAgo(accountAge),
      nowMs: now.millisecondsSinceEpoch,
    );

void main() {
  group('the account has to be established', () {
    test('a brand-new account is never asked', () {
      expect(ask(accountAge: Duration.zero), isFalse);
      expect(ask(accountAge: const Duration(days: 1)), isFalse);
      // The trigger being a two-minute call does not buy an exemption; a user
      // who installed this morning is not a reviewer.
      expect(ask(accountAge: const Duration(days: 6, hours: 23)), isFalse);
    });

    test('seven days is the threshold', () {
      expect(ask(accountAge: const Duration(days: 7)), isTrue);
      expect(ask(accountAge: const Duration(days: 8)), isTrue);
    });

    test('an established account with no prior ask is asked', () {
      expect(ask(), isTrue);
    });
  });

  group('asks are forty days apart', () {
    test('a recent ask blocks the next one', () {
      expect(ask(lastAsk: Duration.zero), isFalse);
      expect(ask(lastAsk: const Duration(days: 1)), isFalse);
      expect(ask(lastAsk: const Duration(days: 39)), isFalse);
    });

    test('forty days opens the window', () {
      expect(ask(lastAsk: const Duration(days: 40)), isTrue);
      expect(ask(lastAsk: const Duration(days: 41)), isTrue);
    });

    test('the window keeps reopening, with no lifetime cap', () {
      // The gap is the only limit by design. However long the user has been
      // around and however many sheets they have already been shown, forty days
      // after the last one they are eligible again — so this must not start
      // failing if someone later reintroduces a count.
      expect(ask(lastAsk: const Duration(days: 200)), isTrue);
      expect(
        ask(
          lastAsk: const Duration(days: 40),
          accountAge: const Duration(days: 3650),
        ),
        isTrue,
      );
    });

    test('a zero timestamp means never asked, not asked at the epoch', () {
      // The fencepost worth pinning: read as a real date, 0 is 1970, which is
      // more than forty days ago and so would pass — but were the comparison
      // written the other way round it would fail, and every first ask in the
      // app would silently wait six weeks.
      expect(ask(lastAsk: null), isTrue);
    });
  });

  group('what counts as a good call', () {
    test('two minutes of talk time with the peer present', () {
      expect(
        ReviewPromptService.isGoodCall(
            remoteJoined: true, durationSeconds: 120),
        isTrue,
      );
      expect(
        ReviewPromptService.isGoodCall(
            remoteJoined: true, durationSeconds: 600),
        isTrue,
      );
    });

    test('a short call does not count', () {
      expect(
        ReviewPromptService.isGoodCall(
            remoteJoined: true, durationSeconds: 119),
        isFalse,
      );
      expect(
        ReviewPromptService.isGoodCall(remoteJoined: true, durationSeconds: 0),
        isFalse,
      );
    });

    test('a call the peer never joined never counts', () {
      // Declined, missed and cancelled calls all land here. The duration is 0 in
      // practice, but assert the long form too: a stuck timer must not turn a
      // call nobody answered into a moment of satisfaction.
      expect(
        ReviewPromptService.isGoodCall(
            remoteJoined: false, durationSeconds: 600),
        isFalse,
      );
      expect(
        ReviewPromptService.isGoodCall(remoteJoined: false, durationSeconds: 0),
        isFalse,
      );
    });
  });
}
