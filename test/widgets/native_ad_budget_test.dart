// The native-ad load budget — the thing standing between a scrolling list and a
// request loop.
//
// Worth its own test despite being four lines, because the failure it prevents
// is invisible locally and expensive remotely. A native card in a `reverse: true`
// chat list is torn down and rebuilt whenever a message arrives or the typing
// bubble toggles, since every sliver index shifts under it. A card counting its
// own attempts is therefore reborn with a fresh count, and the result is one ad
// request per message: requests that never become impressions, which AdMob counts
// against the account's match rate while the user pays for them in battery and
// data.
//
// So the invariant is not "at most two attempts per card" — it is "at most two
// attempts per *visit*, however many cards that spans".

import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/widgets/ads/native_ad_card.dart';

void main() {
  group('NativeAdBudget', () {
    test('starts unspent', () {
      expect(NativeAdBudget().exhausted, isFalse);
    });

    test('allows exactly its two attempts by default', () {
      final budget = NativeAdBudget();
      budget.spend();
      expect(budget.exhausted, isFalse, reason: 'one retry is the point');
      budget.spend();
      expect(budget.exhausted, isTrue);
    });

    test('stays exhausted, however many times it is asked', () {
      // The slot going permanently empty is the intended end state: one lost
      // impression, versus a loop. Nothing resets this — not a theme flip, not a
      // rebuild — so a later `spend()` must not wrap it back to available.
      final budget = NativeAdBudget();
      budget.spend();
      budget.spend();
      budget.spend();
      budget.spend();
      expect(budget.exhausted, isTrue);
    });

    test('survives the cards that spend it', () {
      // The whole reason the budget is a separate object owned by the enclosing
      // State: card #1 loads and dies to an index shift, card #2 retries once,
      // and card #3 — and every rebuild after it — gets nothing.
      final shared = NativeAdBudget();
      shared.spend(); // card #1
      shared.spend(); // card #2
      expect(shared.exhausted, isTrue, reason: 'card #3 must not request');
    });

    test('a per-card budget is independent', () {
      // Hosts where a rebuild genuinely means the surface went away pass no
      // budget and get their own, which must not share state with anyone else's.
      final a = NativeAdBudget();
      final b = NativeAdBudget();
      a.spend();
      a.spend();
      expect(a.exhausted, isTrue);
      expect(b.exhausted, isFalse);
    });

    test('a one-attempt budget has no retry', () {
      final budget = NativeAdBudget(maxAttempts: 1);
      expect(budget.exhausted, isFalse);
      budget.spend();
      expect(budget.exhausted, isTrue);
    });

    test('a zero budget never requests at all', () {
      // Not configured anywhere today, but it is the honest reading of zero and
      // the safe direction to fail in: `exhausted` must be true before the first
      // spend, not after it.
      expect(NativeAdBudget(maxAttempts: 0).exhausted, isTrue);
    });
  });
}
