// ════════════════════════════════════════════════════════════════════════════
//  PRESERVATION — chat-streak-system-fix, task 2
// ════════════════════════════════════════════════════════════════════════════
//
// Property 2: Non-buggy evaluations are unchanged.
//
// These tests run against the UNFIXED logic (`legacyEvaluate`, frozen in
// `test/support/legacy_streak_reference.dart`) and are restricted to the
// `¬isBugCondition` residue. They are OBSERVATION-FIRST: every number below was
// recorded from the unfixed reference before it was asserted, and nothing is
// asserted that the unfixed code does not actually do.
//
// Task 3.7 re-runs this same file with `StreakEngine` added as the second side
// of the equality — `legacyEvaluate(X) == StreakEngine.evaluate(X)` on count,
// anchor day and broken state for every input here.
//
// ────────────────────────────────────────────────────────────────────────────
//  THE RESIDUE
// ────────────────────────────────────────────────────────────────────────────
// `isBugCondition` (design, Bug Condition) is the disjunction:
//   usesStaleDeviceCache | anchorAdvancedWithoutMutualDay | CLIENT_CLOCK
//   | DEVICE_LOCAL zone | evaluationTrigger != SEND | sender == receiver
// so the residue asserted here is the conjunction of its negations:
//   * two DISTINCT uids,
//   * both effectively in the canonical zone (UTC+05:30, which has no DST, so
//     no day boundary in these tests crosses a transition),
//   * a non-reaction send,
//   * the cache freshly filled from the stored state — in the legacy code that
//     is the COLD path (`cache: null`): the cache is only refilled when empty,
//     and a refill overwrites the anchor from the stored document, so a
//     freshly-filled cache and a cold read are the same input. Threading a
//     warm cache forward is the stale-cache defect, not this residue,
//   * a trustworthy clock — `now` is the true instant of the send, and the
//     post-commit `lastSentAt` write is not dropped,
//   * evaluation triggered by a send.
//
// ────────────────────────────────────────────────────────────────────────────
//  OBSERVED BASELINE  (recorded from the UNFIXED reference)
// ────────────────────────────────────────────────────────────────────────────
//
// [3.1] CONSECUTIVE MUTUAL DAYS — one increment per day
//   2024-05-01..04 IST, A sends 09:00, B replies 09:05, cold cache each time.
//     D1 A 09:00  waitingForOtherUser  daysDiff=null  count 0 → 0, no anchor
//     D1 B 09:05  firstMutualDay       daysDiff=null  count 0 → 1, anchor 05-01
//     D2 A 09:00  waitingForOtherUser  daysDiff=null  count 1 → 1, no anchor
//     D2 B 09:05  incremented          daysDiff=1     count 1 → 2, anchor 05-02
//     D3 B 09:05  incremented          daysDiff=1     count 2 → 3, anchor 05-03
//     D4 B 09:05  incremented          daysDiff=1     count 3 → 4, anchor 05-04
//   i.e. exactly +1 per mutual day, and the sender's own lone first send of the
//   day writes the unchanged count and NO anchor to the room document.
//
// [3.2] EXTRA MESSAGES ON AN ALREADY-COUNTED DAY — count unchanged
//   after the 05-01 mutual day was counted at 1:
//     A 10:00  sameDay  daysDiff=0  count 1 → 1, anchor rewritten 05-01T10:00
//     B 11:00  sameDay  daysDiff=0  count 1 → 1, anchor rewritten 05-01T11:00
//     A 23:30  sameDay  daysDiff=0  count 1 → 1, anchor rewritten 05-01T23:30
//   The COUNT and the anchor DAY never move. The anchor TIMESTAMP is rewritten
//   on every same-day send (which is what makes the badge's 48h countdown
//   restart mid-day). Only the count and the anchor day are preservation
//   requirements; the intra-day timestamp refresh is recorded here as a legacy
//   quirk the engine is expected to drop (design: "and now the anchor").
//
// [3.3] FIRST SAME-DAY EXCHANGE — starts at 1
//   empty room, A 09:00 then B 09:05 on 2024-05-01:
//     A 09:00  waitingForOtherUser  count 0 → 0, anchor still null
//     B 09:05  firstMutualDay (lastInteraction == null)  count 0 → 1,
//              anchor 2024-05-01T09:05 IST
//
// [3.4] MUTUAL DAY AFTER A 2+ DAY GAP — restart at 1, previous count preserved
//   stored: count 5, anchor 2024-05-01T09:05 IST, both lastSentAt on 05-01.
//   05-02 and 05-03 silent. On 05-04:
//     A 09:00  waitingForOtherUser  count 5 → 5 (written), no anchor
//     B 09:05  brokenAndRestarted   daysDiff=3
//              → streakCount 1, previousStreakCount 5,
//                streakBrokenAt = 2024-05-04T09:05 IST, anchor 05-04
//   `previousStreakCount` and `streakBrokenAt` are both written, so the restore
//   window opens — but `streakBrokenAt` is the DISCOVERY instant (the evaluating
//   client's clock), ~33h after the real deadline dayStart(05-03) =
//   2024-05-02T18:30Z. Preserved here: restart at 1 + previous count 5 + broken
//   state set. The stamp itself is defect 1.14 and moves under the fix.
//   Follow-on, recorded for completeness: the "expired restore window" cleanup
//   is `now.difference(brokenAt).inHours > 24`, strictly, so
//     05-05 09:00 (23h55) no cleanup, 05-05 09:05 (exactly 24h) no cleanup,
//     05-06 09:00 (47h55) → previousStreakCount 0, streakBrokenAt null.
//
// [3.8 / 3.9] RESTORE COST TIERS — frozen from GamificationService.getRestoreCost
//     0 → 10    9 → 10   10 → 25   29 → 25   30 → 50   99 → 50   100 → 100
//
// [PROPERTY] For a generated history of consecutive mutual days on top of a
//   stored state that is itself a consecutive prior run, folded through
//   `legacyEvaluate` with a cold cache per send: the final count equals
//   priorRun + generatedDays, the anchor day equals the last generated day, no
//   broken state is ever written, and the count agrees with the independent
//   `referenceStreak` oracle. Extra same-day messages and the order of the two
//   participants within a day change nothing.
//
// ────────────────────────────────────────────────────────────────────────────

import 'package:glados/glados.dart';
import 'package:video_chat_app/services/gamification_service.dart';

import '../../support/legacy_streak_reference.dart';
import '../../support/reference_streak.dart';

/// The absolute instant of an Asia/Kolkata (UTC+05:30) wall-clock reading.
DateTime atIst(int y, int m, int d, [int h = 0, int min = 0]) =>
    DateTime.utc(y, m, d, h, min).subtract(const Duration(minutes: 330));

final _ist = LegacyDeviceZone.ist;

/// `YYYY-MM-DD` of an instant in the legacy device zone used by these tests,
/// which is the canonical zone.
String dayKeyOf(DateTime instant) =>
    _ist.dayKey(_ist.wall(instant)).toIso8601String().substring(0, 10);

// ── The residue filter, made explicit ─────────────────────────────────────

/// The negation of `isBugCondition`, as a checkable record of the side
/// conditions every input in this file satisfies.
class NonBugResidue {
  const NonBugResidue({
    required this.senderId,
    required this.receiverId,
    required this.zone,
    required this.messageType,
    required this.coldOrFreshlyFilledCache,
    required this.clockIsTrue,
    required this.triggeredBySend,
  });

  final String senderId;
  final String receiverId;
  final LegacyDeviceZone zone;
  final String messageType;
  final bool coldOrFreshlyFilledCache;
  final bool clockIsTrue;
  final bool triggeredBySend;

  bool get holds =>
      senderId != receiverId && // ¬(sender == receiver)              1.9
      zone.dstOffsetMinutes == null && // ¬DST-crossing boundary       1.6
      zone.baseOffsetMinutes == canonicalOffsetMinutes && // canonical 1.5
      messageType != 'reaction' && // ¬reaction                        1.10
      coldOrFreshlyFilledCache && // ¬usesStaleDeviceCache        1.1/1.3
      clockIsTrue && // ¬CLIENT_CLOCK skew                       1.7/1.11
      triggeredBySend; // ¬(evaluationTrigger != SEND)         1.13/1.17
}

/// Every send in this file goes through here: two distinct uids, canonical
/// zone, non-reaction, cold (== freshly filled) cache, honest clock.
NonBugResidue residueFor(String sender, String receiver) => NonBugResidue(
      senderId: sender,
      receiverId: receiver,
      zone: _ist,
      messageType: 'text',
      coldOrFreshlyFilledCache: true,
      clockIsTrue: true,
      triggeredBySend: true,
    );

/// One send on the residue path: evaluated against the authoritative stored
/// state with a cold (freshly filled) cache, then merged back exactly as the
/// legacy batch + post-commit `lastSentAt` update would.
({LegacyRoomDoc room, LegacyEvaluation eval}) sendOnResidue(
  LegacyRoomDoc room,
  String sender,
  String receiver,
  DateTime now,
) {
  expect(residueFor(sender, receiver).holds, isTrue,
      reason: 'this input must sit outside isBugCondition');

  final eval = legacyEvaluate(
    stored: room,
    senderId: sender,
    receiverId: receiver,
    cache: null, // cold == freshly filled from `stored`
    now: now,
    zone: _ist,
    messageType: 'text',
  );
  final next = legacyMergeRoomDoc(
    room,
    eval.roomUpdates,
    postCommitLastSentAtUpdate: eval.postCommitLastSentAtUpdate,
  );
  return (room: next, eval: eval);
}

void main() {
  group('3.1 — consecutive mutual days increment by exactly one per day', () {
    test('four consecutive days, completing reply is the sender\'s first send '
        'of the day', () {
      var room = LegacyRoomDoc(streakCount: 0);
      final counts = <int>[];
      final anchorDays = <String>[];
      final branches = <LegacyBranch>[];

      for (var day = 1; day <= 4; day++) {
        // A's own first send of the day: not yet a mutual day.
        final lone = sendOnResidue(room, 'A', 'B', atIst(2024, 5, day, 9));
        room = lone.room;
        expect(lone.eval.branch, LegacyBranch.waitingForOtherUser);
        expect(lone.eval.wroteLastInteractionDate, isFalse,
            reason: 'a lone send writes no anchor to the room document');
        expect(lone.eval.streakCountWritten, day == 1 ? 0 : day - 1,
            reason: 'the count is rewritten unchanged');

        // B's first send of the day completes the mutual day.
        final completing =
            sendOnResidue(room, 'B', 'A', atIst(2024, 5, day, 9, 5));
        room = completing.room;
        branches.add(completing.eval.branch);
        counts.add(room.streakCount);
        anchorDays.add(dayKeyOf(room.lastInteractionDate!));
      }

      expect(counts, [1, 2, 3, 4], reason: 'exactly +1 per mutual day');
      expect(branches, [
        LegacyBranch.firstMutualDay,
        LegacyBranch.incremented,
        LegacyBranch.incremented,
        LegacyBranch.incremented,
      ]);
      expect(anchorDays,
          ['2024-05-01', '2024-05-02', '2024-05-03', '2024-05-04']);
      expect(room.previousStreakCount, 0);
      expect(room.streakBrokenAt, isNull);
    });

    test('the increment branch is reached with daysDiff == 1', () {
      final room = LegacyRoomDoc(
        streakCount: 3,
        lastInteractionDate: atIst(2024, 5, 3, 9, 5),
        lastSentAt: {
          'A': atIst(2024, 5, 4, 9), // A already sent today
          'B': atIst(2024, 5, 3, 9, 5),
        },
      );

      final completing = sendOnResidue(room, 'B', 'A', atIst(2024, 5, 4, 9, 5));

      expect(completing.eval.otherSentToday, isTrue);
      expect(completing.eval.daysDiff, 1);
      expect(completing.eval.branch, LegacyBranch.incremented);
      expect(completing.eval.streakCountWritten, 4);
      expect(dayKeyOf(completing.room.lastInteractionDate!), '2024-05-04');
    });
  });

  group('3.2 — extra messages on an already-counted day change nothing', () {
    test('three further sends after the day was counted leave the count and '
        'the anchor day alone', () {
      var room = LegacyRoomDoc(streakCount: 0);
      room = sendOnResidue(room, 'A', 'B', atIst(2024, 5, 1, 9)).room;
      room = sendOnResidue(room, 'B', 'A', atIst(2024, 5, 1, 9, 5)).room;
      expect(room.streakCount, 1);

      final extras = <(String, DateTime)>[
        ('A', atIst(2024, 5, 1, 10)),
        ('B', atIst(2024, 5, 1, 11)),
        ('A', atIst(2024, 5, 1, 23, 30)),
      ];

      for (final (sender, instant) in extras) {
        final result = sendOnResidue(
            room, sender, sender == 'A' ? 'B' : 'A', instant);
        room = result.room;

        expect(result.eval.branch, LegacyBranch.sameDay);
        expect(result.eval.daysDiff, 0);
        expect(result.eval.streakCountWritten, 1, reason: 'count unchanged');
        expect(room.streakCount, 1);
        expect(dayKeyOf(room.lastInteractionDate!), '2024-05-01',
            reason: 'the anchor DAY never moves within a counted day');
        // Recorded legacy quirk (not a preservation requirement): the anchor
        // timestamp is rewritten to `now` on every same-day send.
        expect(result.eval.lastInteractionDateWritten, instant);
      }

      expect(room.streakCount, 1);
      expect(room.previousStreakCount, 0);
      expect(room.streakBrokenAt, isNull);
    });

    test('the next day still increments by exactly one after all those extras',
        () {
      var room = LegacyRoomDoc(streakCount: 0);
      room = sendOnResidue(room, 'A', 'B', atIst(2024, 5, 1, 9)).room;
      room = sendOnResidue(room, 'B', 'A', atIst(2024, 5, 1, 9, 5)).room;
      room = sendOnResidue(room, 'A', 'B', atIst(2024, 5, 1, 23, 30)).room;

      room = sendOnResidue(room, 'A', 'B', atIst(2024, 5, 2, 9)).room;
      final completing = sendOnResidue(room, 'B', 'A', atIst(2024, 5, 2, 9, 5));

      expect(completing.eval.daysDiff, 1);
      expect(completing.room.streakCount, 2);
    });
  });

  group('3.3 — a first same-day exchange starts the count at 1', () {
    test('empty room, A then B on the same canonical day', () {
      var room = LegacyRoomDoc(streakCount: 0);

      final first = sendOnResidue(room, 'A', 'B', atIst(2024, 5, 1, 9));
      room = first.room;
      expect(first.eval.branch, LegacyBranch.waitingForOtherUser);
      expect(first.eval.streakCountWritten, 0);
      expect(room.lastInteractionDate, isNull,
          reason: 'no anchor until the day is mutual');

      final completing = sendOnResidue(room, 'B', 'A', atIst(2024, 5, 1, 9, 5));
      room = completing.room;

      expect(completing.eval.otherSentToday, isTrue);
      expect(completing.eval.branch, LegacyBranch.firstMutualDay);
      expect(completing.eval.daysDiff, isNull,
          reason: 'lastInteraction was null, so no difference was computed');
      expect(completing.eval.streakCountWritten, 1);
      expect(room.streakCount, 1);
      expect(room.lastInteractionDate, atIst(2024, 5, 1, 9, 5));
      expect(dayKeyOf(room.lastInteractionDate!), '2024-05-01');
      expect(room.previousStreakCount, 0);
      expect(room.streakBrokenAt, isNull);
    });

    test('the same first exchange in the other order also starts at 1', () {
      var room = LegacyRoomDoc(streakCount: 0);
      room = sendOnResidue(room, 'B', 'A', atIst(2024, 5, 1, 20)).room;
      final completing = sendOnResidue(room, 'A', 'B', atIst(2024, 5, 1, 20, 5));

      expect(completing.eval.branch, LegacyBranch.firstMutualDay);
      expect(completing.room.streakCount, 1);
    });
  });

  group('3.4 — a mutual day after a 2+ day gap restarts at 1 and preserves '
      'the broken count', () {
    LegacyRoomDoc storedFiveDayStreak() => LegacyRoomDoc(
          streakCount: 5,
          lastInteractionDate: atIst(2024, 5, 1, 9, 5),
          lastSentAt: {
            'A': atIst(2024, 5, 1, 9),
            'B': atIst(2024, 5, 1, 9, 5),
          },
        );

    test('restart at 1 with previousStreakCount preserved and the broken state '
        'set', () {
      var room = storedFiveDayStreak();

      final lone = sendOnResidue(room, 'A', 'B', atIst(2024, 5, 4, 9));
      room = lone.room;
      expect(lone.eval.branch, LegacyBranch.waitingForOtherUser);
      expect(lone.eval.streakCountWritten, 5,
          reason: 'the lapsed count is still rewritten unchanged');
      expect(room.previousStreakCount, 0);
      expect(room.streakBrokenAt, isNull,
          reason: 'nothing breaks until a mutual day is evaluated');

      final completing = sendOnResidue(room, 'B', 'A', atIst(2024, 5, 4, 9, 5));
      room = completing.room;

      expect(completing.eval.daysDiff, 3);
      expect(completing.eval.branch, LegacyBranch.brokenAndRestarted);
      expect(completing.eval.streakCountWritten, 1, reason: 'restart at 1');
      expect(room.streakCount, 1);
      expect(room.previousStreakCount, 5, reason: 'preserved for restore');
      expect(room.streakBrokenAt, isNotNull, reason: 'broken state set');
      expect(dayKeyOf(room.lastInteractionDate!), '2024-05-04');

      // Recorded: the break is stamped at the DISCOVERY instant, not at the
      // real deadline dayStart(2024-05-03) == 2024-05-02T18:30Z (defect 1.14).
      expect(room.streakBrokenAt, atIst(2024, 5, 4, 9, 5));
      final realDeadline =
          canonicalDayStartUtc(canonicalDayPlus('2024-05-01', 2));
      expect(realDeadline, DateTime.utc(2024, 5, 2, 18, 30));
      expect(room.streakBrokenAt!.difference(realDeadline).inHours, 33);
    });

    test('a two-day gap is the smallest gap that breaks; a one-day gap '
        'increments', () {
      final broken = sendOnResidue(
        storedFiveDayStreak().copyWith(
          lastSentAt: {
            'A': atIst(2024, 5, 3, 9), // gap day 05-02, mutual day 05-03
            'B': atIst(2024, 5, 1, 9, 5),
          },
        ),
        'B',
        'A',
        atIst(2024, 5, 3, 9, 5),
      );
      expect(broken.eval.daysDiff, 2);
      expect(broken.eval.branch, LegacyBranch.brokenAndRestarted);
      expect(broken.room.streakCount, 1);
      expect(broken.room.previousStreakCount, 5);

      final continued = sendOnResidue(
        storedFiveDayStreak().copyWith(
          lastSentAt: {
            'A': atIst(2024, 5, 2, 9),
            'B': atIst(2024, 5, 1, 9, 5),
          },
        ),
        'B',
        'A',
        atIst(2024, 5, 2, 9, 5),
      );
      expect(continued.eval.daysDiff, 1);
      expect(continued.room.streakCount, 6);
      expect(continued.room.previousStreakCount, 0);
      expect(continued.room.streakBrokenAt, isNull);
    });

    test('the restarted streak then increments normally, and the restore '
        'window is cleaned up strictly past 24h', () {
      var room = storedFiveDayStreak();
      room = sendOnResidue(room, 'A', 'B', atIst(2024, 5, 4, 9)).room;
      room = sendOnResidue(room, 'B', 'A', atIst(2024, 5, 4, 9, 5)).room;
      expect(room.streakCount, 1);
      expect(room.streakBrokenAt, atIst(2024, 5, 4, 9, 5));

      // 23h55 and then exactly 24h after the break: `inHours > 24` is false,
      // so the window survives both evaluations.
      room = sendOnResidue(room, 'A', 'B', atIst(2024, 5, 5, 9)).room;
      expect(room.previousStreakCount, 5);
      final day5 = sendOnResidue(room, 'B', 'A', atIst(2024, 5, 5, 9, 5));
      room = day5.room;
      expect(day5.eval.daysDiff, 1);
      expect(room.streakCount, 2);
      expect(room.previousStreakCount, 5);
      expect(room.streakBrokenAt, atIst(2024, 5, 4, 9, 5));

      // 47h55 after the break: the window is cleared.
      final day6 = sendOnResidue(room, 'A', 'B', atIst(2024, 5, 6, 9));
      room = day6.room;
      expect(day6.eval.branch, LegacyBranch.waitingForOtherUser);
      expect(room.previousStreakCount, 0);
      expect(room.streakBrokenAt, isNull);

      room = sendOnResidue(room, 'B', 'A', atIst(2024, 5, 6, 9, 5)).room;
      expect(room.streakCount, 3);
    });
  });

  group('3.8 / 3.9 — the restore cost tier table is frozen', () {
    // Frozen from GamificationService.getRestoreCost as it stands today.
    const frozenTiers = <int, int>{
      0: 10,
      9: 10,
      10: 25,
      29: 25,
      30: 50,
      99: 50,
      100: 100,
    };

    test('GamificationService.getRestoreCost matches the frozen table', () {
      for (final entry in frozenTiers.entries) {
        expect(GamificationService.getRestoreCost(entry.key), entry.value,
            reason: 'tier boundary at ${entry.key}');
      }
    });

    test('the tiers are 10/25/50/100 with boundaries at 10, 30 and 100', () {
      expect(GamificationService.getRestoreCost(1), 10);
      expect(GamificationService.getRestoreCost(11), 25);
      expect(GamificationService.getRestoreCost(31), 50);
      expect(GamificationService.getRestoreCost(1000), 100);

      // The cost is monotonic non-decreasing across the whole display range.
      var previous = 0;
      for (var count = 0; count <= 150; count++) {
        final cost = GamificationService.getRestoreCost(count);
        expect(cost, greaterThanOrEqualTo(previous));
        previous = cost;
      }
      expect(previous, 100);
    });

    test('the frozen transcription agrees with production', () {
      for (final count in [0, 9, 10, 29, 30, 99, 100]) {
        expect(legacyRestoreCost(count),
            GamificationService.getRestoreCost(count));
      }
    });
  });

  // ── Property ────────────────────────────────────────────────────────────
  group('PROPERTY — on the ¬isBugCondition residue the legacy fold keeps the '
      'core day-counting semantics', () {
    Glados<_PreservationCase>(
      _anyPreservationCase,
      ExploreConfig(numRuns: 120),
    ).test('count, anchor day and broken state', (input) {
      expect(input.residueHolds, isTrue,
          reason: 'the generator must only produce ¬isBugCondition inputs');

      // Stored state, itself the product of a consecutive prior run.
      var room = input.storedState;
      for (final send in input.sends) {
        room = sendOnResidue(room, send.uid, input.partnerOf(send.uid),
                send.instant)
            .room;
      }

      final expectedCount = input.priorRun + input.days.length;

      // Count — per-day increment, first day starts at 1 (3.1, 3.3), extra
      // same-day messages change nothing (3.2).
      expect(room.streakCount, expectedCount);

      // Anchor day — the newest mutual day.
      expect(dayKeyOf(room.lastInteractionDate!), input.lastMutualDayKey);

      // Broken state — nothing breaks while the days are consecutive.
      expect(room.previousStreakCount, 0);
      expect(room.streakBrokenAt, isNull);

      // And the independent oracle agrees on the count.
      final reference = referenceStreak(
        input.priorSends + input.sends,
        input.serverNow,
        participants: input.participants,
      );
      expect(reference.count, expectedCount);
      expect(reference.lastMutualDay, input.lastMutualDayKey);
      expect(reference.isBroken, isFalse);
      expect(room.streakCount, reference.count);
    });
  });
}

// ── Generators ────────────────────────────────────────────────────────────

/// One generated mutual day: when in the canonical day the pair exchanges,
/// who opens it, and how many further same-day messages follow.
class _DayPlan {
  const _DayPlan(this.minuteOfDay, this.firstSenderIsFirstUid, this.extras);

  /// 0..1379 — bounded so the completing reply and every extra stay inside the
  /// same canonical day.
  final int minuteOfDay;
  final bool firstSenderIsFirstUid;
  final int extras;

  @override
  String toString() =>
      'Day(min: $minuteOfDay, opener: ${firstSenderIsFirstUid ? 0 : 1}, '
      'extras: $extras)';
}

/// A full residue input: participants, the send list, `serverNow` and the
/// stored state.
class _PreservationCase {
  _PreservationCase({
    required this.participants,
    required this.priorRun,
    required this.days,
    required this.serverNowOffsetMinutes,
  });

  final List<String> participants;

  /// Length of the consecutive prior run the stored state represents.
  final int priorRun;
  final List<_DayPlan> days;
  final int serverNowOffsetMinutes;

  static const int _firstGeneratedDay = 20; // 2024-06-20, room for 12 prior days

  String get a => participants[0];
  String get b => participants[1];
  String partnerOf(String uid) => uid == a ? b : a;

  bool get residueHolds =>
      a != b &&
      days.isNotEmpty &&
      days.every((d) => d.minuteOfDay >= 0 && d.minuteOfDay < 1380) &&
      days.every((d) => d.extras >= 0 && d.extras <= 3);

  /// The prior consecutive mutual days the stored state stands for.
  List<ReferenceSend> get priorSends => [
        for (var i = 0; i < priorRun; i++)
          ...[
            ReferenceSend(a, atIst(2024, 6, _firstGeneratedDay - priorRun + i, 12)),
            ReferenceSend(
                b, atIst(2024, 6, _firstGeneratedDay - priorRun + i, 12, 5)),
          ],
      ];

  LegacyRoomDoc get storedState {
    if (priorRun == 0) return LegacyRoomDoc(streakCount: 0);
    final lastPriorDay = _firstGeneratedDay - 1;
    return LegacyRoomDoc(
      streakCount: priorRun,
      lastInteractionDate: atIst(2024, 6, lastPriorDay, 12, 5),
      lastSentAt: {
        a: atIst(2024, 6, lastPriorDay, 12),
        b: atIst(2024, 6, lastPriorDay, 12, 5),
      },
    );
  }

  List<ReferenceSend> get sends {
    final result = <ReferenceSend>[];
    for (var i = 0; i < days.length; i++) {
      final plan = days[i];
      final base = atIst(2024, 6, _firstGeneratedDay + i);
      final opener = plan.firstSenderIsFirstUid ? a : b;
      final closer = partnerOf(opener);
      result
        ..add(ReferenceSend(
            opener, base.add(Duration(minutes: plan.minuteOfDay))))
        ..add(ReferenceSend(
            closer, base.add(Duration(minutes: plan.minuteOfDay + 5))));
      for (var e = 0; e < plan.extras; e++) {
        result.add(ReferenceSend(e.isEven ? opener : closer,
            base.add(Duration(minutes: plan.minuteOfDay + 10 + e * 10))));
      }
    }
    return result;
  }

  String get lastMutualDayKey => canonicalDayKey(sends.last.instant);

  /// Well inside the deadline `dayStart(lastMutualDay + 2)`, so the oracle
  /// reports the streak as live.
  DateTime get serverNow =>
      sends.last.instant.add(Duration(minutes: serverNowOffsetMinutes));

  @override
  String toString() => '_PreservationCase(participants: $participants, '
      'priorRun: $priorRun, days: $days, '
      'serverNowOffsetMinutes: $serverNowOffsetMinutes)';
}

final Generator<_DayPlan> _anyDayPlan = any.combine3(
  any.intInRange(0, 1380),
  any.bool,
  any.intInRange(0, 4),
  (int minute, bool openerIsFirst, int extras) =>
      _DayPlan(minute, openerIsFirst, extras),
);

/// Only ¬isBugCondition inputs are constructible: the uid pairs are always two
/// distinct ids, the zone is always canonical, every send is a text message,
/// every evaluation is cold-cache and clock-honest.
final Generator<_PreservationCase> _anyPreservationCase = any.combine4(
  any.choose(<List<String>>[
    ['A', 'B'],
    ['alice', 'bob'],
    ['uid_0001', 'uid_0002'],
  ]),
  any.intInRange(0, 13),
  any.listWithLengthInRange(1, 6, _anyDayPlan),
  any.intInRange(0, 600),
  (
    List<String> participants,
    int priorRun,
    List<_DayPlan> days,
    int serverNowOffset,
  ) =>
      _PreservationCase(
    participants: participants,
    priorRun: priorRun,
    days: days,
    serverNowOffsetMinutes: serverNowOffset,
  ),
);
