// Unit tests for the pure streak engine — every transition in isolation.
//
// Validates: Requirements 2.1, 2.2, 2.4, 2.5, 2.6, 2.9, 2.10, 2.11, 2.15,
// 2.17, 2.23, 2.24, 2.26.
//
// Canonical zone: Asia/Kolkata, fixed UTC+05:30, so canonical midnight is
// 18:30 UTC of the previous calendar date and every canonical day is exactly
// 86,400 seconds long. Every instant below is derived from
// `StreakDay.startUtc()` rather than written out, so the tests say what they
// mean ("six hours before the deadline") instead of encoding a UTC literal.
//
// All dates are in May 2024. The month is deliberately DST-free in the zones
// the CI machine might be in; `streak_day_test.dart` covers the zone-agnostic
// arithmetic itself.

import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/services/streak/streak_day.dart';
import 'package:video_chat_app/services/streak/streak_engine.dart';
import 'package:video_chat_app/services/streak/streak_state.dart';

import '../../support/reference_streak.dart';

const String uidA = 'alice';
const String uidB = 'bob';
const String uidC = 'carol';
const List<String> pair = <String>[uidA, uidB];

/// Canonical day `2024-05-<day>`.
StreakDay d(int day) => StreakDay(2024, 5, day);

/// [hours] hours into canonical day [day].
DateTime inDay(StreakDay day, {int hours = 12, int minutes = 0}) =>
    day.startUtc().add(Duration(hours: hours, minutes: minutes));

/// The instant canonical day [day] begins.
DateTime startOf(StreakDay day) => day.startUtc();

/// A state that a previous engine run could have written: schema and engine
/// version stamped, deadline and risk level consistent with [anchor], so any
/// `changed == true` in a test is caused by the evaluation under test and not
/// by bookkeeping drift.
StreakState engineState({
  required StreakDay anchor,
  required int count,
  StreakDay? bridged,
  Map<String, StreakDay>? sendDays,
  int? longestForRoom,
  List<int> milestonesAwarded = const <int>[],
  int previousCount = 0,
  DateTime? brokenAt,
  DateTime? restoreDeadlineAt,
  StreakRiskLevel riskLevel = StreakRiskLevel.normal,
  List<String> participants = pair,
}) {
  final horizon = StreakDay.max(anchor, bridged)!;
  final days = sendDays ?? <String, StreakDay>{uidA: anchor, uidB: anchor};
  return StreakState(
    engineVersion: StreakEngine.engineVersion,
    rev: 4,
    participants: participants,
    count: count,
    lastMutualDay: anchor,
    bridgedThroughDay: bridged,
    deadlineAt: horizon.plusDays(2).startUtc(),
    riskLevel: riskLevel,
    sendDays: days,
    sendInstants: days.map((uid, day) => MapEntry(uid, inDay(day))),
    previousCount: previousCount,
    brokenAt: brokenAt,
    restoreDeadlineAt: restoreDeadlineAt,
    milestonesAwarded: milestonesAwarded,
    longestForRoom: longestForRoom ?? count,
  );
}

StreakEvaluation evaluate(
  StreakState stored, {
  Participation? event,
  required DateTime serverNow,
  List<String> participants = pair,
}) =>
    StreakEngine.evaluate(
      stored: stored,
      participants: participants,
      event: event,
      serverNow: serverNow,
    );

/// Folds [sends] through the engine in chronological order, evaluating each one
/// as of its own instant, then derives the state as of [serverNow] with no
/// event — exactly what the trigger plus the sweeper/read path do.
StreakEvaluation foldSends(
  List<ReferenceSend> sends,
  DateTime serverNow, {
  List<String> participants = pair,
}) {
  final ordered = <ReferenceSend>[...sends]
    ..sort((a, b) => a.instant.compareTo(b.instant));
  var state = StreakState.empty(participants: participants);
  for (final send in ordered) {
    state = StreakEngine.evaluate(
      stored: state,
      participants: participants,
      event: Participation(uid: send.uid, instant: send.instant),
      serverNow: send.instant,
    ).next;
  }
  return StreakEngine.evaluate(
    stored: state,
    participants: participants,
    event: null,
    serverNow: serverNow,
  );
}

void main() {
  group('step 1 — participants must be exactly two distinct uids', () {
    test('self-chat creates no streak and mutates nothing', () {
      // 1.9 / 2.9: `otherUserId = senderId` was the farming path.
      final stored = StreakState.empty(participants: const <String>[uidA]);

      final result = evaluate(
        stored,
        participants: const <String>[uidA, uidA],
        event: Participation(uid: uidA, instant: inDay(d(1))),
        serverNow: inDay(d(1), hours: 13),
      );

      expect(result.count, 0);
      expect(result.transitions, isEmpty);
      expect(result.milestonesCrossed, isEmpty);
      expect(result.deadlineAt, isNull);
      expect(result.riskLevel, StreakRiskLevel.normal);
      expect(result.changed, isFalse);
      expect(identical(result.next, stored), isTrue,
          reason: 'a refused room must not be rewritten');
    });

    test('a refusal reports 0 without erasing an existing document', () {
      final stored = engineState(anchor: d(5), count: 5);

      final result = evaluate(
        stored,
        participants: const <String>[uidA, uidA],
        serverNow: inDay(d(5), hours: 13),
      );

      expect(result.count, 0, reason: 'nothing should render');
      expect(result.next.count, 5, reason: 'but nothing should be destroyed');
      expect(result.changed, isFalse);
    });

    test('group and degenerate rooms are refused, not guessed at', () {
      final stored = StreakState.empty(participants: pair);
      final cases = <List<String>>[
        const <String>[],
        const <String>[uidA],
        const <String>[uidA, uidB, uidC],
        const <String>['', ''],
        const <String>[uidA, ''],
      ];

      for (final participants in cases) {
        final result = evaluate(
          stored,
          participants: participants,
          event: Participation(uid: uidA, instant: inDay(d(1))),
          serverNow: inDay(d(1)),
        );
        expect(result.count, 0, reason: 'participants: $participants');
        expect(result.transitions, isEmpty, reason: 'participants: $participants');
        expect(result.changed, isFalse, reason: 'participants: $participants');
      }
    });
  });

  group('step 5 — started', () {
    test('one participant sending alone records participation only', () {
      // 2.2: the anchor, the count and the deadline stay untouched until the
      // day is actually mutual.
      final result = evaluate(
        StreakState.empty(participants: pair),
        event: Participation(uid: uidA, instant: inDay(d(1))),
        serverNow: inDay(d(1), hours: 13),
      );

      expect(result.transitions, <StreakTransition>[
        StreakTransition.participationRecorded,
      ]);
      expect(result.count, 0);
      expect(result.lastMutualDay, isNull);
      expect(result.deadlineAt, isNull);
      expect(result.next.sendDayFor(uidA), d(1));
      expect(result.next.sendDayFor(uidB), isNull);
    });

    test('the partner completing the day starts the streak at 1', () {
      final afterA = evaluate(
        StreakState.empty(participants: pair),
        event: Participation(uid: uidA, instant: inDay(d(1))),
        serverNow: inDay(d(1)),
      ).next;

      final result = evaluate(
        afterA,
        event: Participation(uid: uidB, instant: inDay(d(1), hours: 14)),
        serverNow: inDay(d(1), hours: 14),
      );

      expect(result.transitions, <StreakTransition>[
        StreakTransition.participationRecorded,
        StreakTransition.started,
        StreakTransition.longestRaised,
      ]);
      expect(result.count, 1);
      expect(result.lastMutualDay, d(1));
      expect(result.deadlineAt, startOf(d(3)),
          reason: 'the mutual day itself plus one whole grace day');
      expect(result.riskLevel, StreakRiskLevel.normal);
      expect(result.milestonesCrossed, isEmpty);
      expect(result.next.longestForRoom, 1);
      expect(result.changed, isTrue);
    });

    test('order of the two first sends does not matter', () {
      final aFirst = foldSends(<ReferenceSend>[
        ReferenceSend(uidA, inDay(d(1), hours: 9)),
        ReferenceSend(uidB, inDay(d(1), hours: 21)),
      ], inDay(d(1), hours: 22));

      final bFirst = foldSends(<ReferenceSend>[
        ReferenceSend(uidB, inDay(d(1), hours: 9)),
        ReferenceSend(uidA, inDay(d(1), hours: 21)),
      ], inDay(d(1), hours: 22));

      expect(aFirst.count, 1);
      expect(bFirst.count, 1);
      expect(aFirst.deadlineAt, bFirst.deadlineAt);
    });
  });

  group('step 6 — sameDay', () {
    test('extra traffic on a counted day moves neither anchor nor deadline', () {
      // THE 1.2 FIX. The legacy code refreshed `lastInteractionDate` to `now`
      // on every send, which is what made the next completing reply look like
      // "same day" and silently drop the increment.
      final stored = engineState(anchor: d(5), count: 3);

      final result = evaluate(
        stored,
        event: Participation(uid: uidA, instant: inDay(d(5), hours: 18)),
        serverNow: inDay(d(5), hours: 18),
      );

      expect(result.transitions, <StreakTransition>[StreakTransition.sameDay]);
      expect(result.count, 3);
      expect(result.lastMutualDay, d(5));
      expect(result.deadlineAt, stored.deadlineAt);
      expect(result.next.sendInstants[uidA], stored.sendInstants[uidA],
          reason: 'a same-day send is not evidence of anything new');
      expect(result.changed, isFalse, reason: 'a genuine no-op');
      expect(result.next.sameDocumentAs(stored), isTrue);
    });

    test('read-side derivation of an untouched active bond is a noop', () {
      final stored = engineState(anchor: d(5), count: 3);

      final result = evaluate(stored, serverNow: inDay(d(5), hours: 18));

      expect(result.transitions, <StreakTransition>[StreakTransition.noop]);
      expect(result.changed, isFalse);
      expect(result.count, 3);
    });
  });

  group('step 5 — incremented', () {
    test('a one-sided send on the grace day does not advance the anchor', () {
      final stored = engineState(anchor: d(5), count: 3, longestForRoom: 9);

      final result = evaluate(
        stored,
        event: Participation(uid: uidA, instant: inDay(d(6))),
        serverNow: inDay(d(6)),
      );

      expect(result.transitions, <StreakTransition>[
        StreakTransition.participationRecorded,
      ]);
      expect(result.count, 3);
      expect(result.lastMutualDay, d(5));
      expect(result.deadlineAt, startOf(d(7)));
      expect(result.riskLevel, StreakRiskLevel.atRisk,
          reason: '12h of the grace day left: past 24h, not yet inside 6h');
    });

    test('the completing reply on the next day increments by exactly one', () {
      // 3.1, and the correct outcome of the 1.2 counterexample.
      final afterA = evaluate(
        engineState(anchor: d(5), count: 3, longestForRoom: 9),
        event: Participation(uid: uidA, instant: inDay(d(6))),
        serverNow: inDay(d(6)),
      ).next;

      final result = evaluate(
        afterA,
        event: Participation(uid: uidB, instant: inDay(d(6), hours: 13)),
        serverNow: inDay(d(6), hours: 13),
      );

      expect(result.transitions, <StreakTransition>[
        StreakTransition.participationRecorded,
        StreakTransition.incremented,
      ]);
      expect(result.count, 4);
      expect(result.lastMutualDay, d(6));
      expect(result.deadlineAt, startOf(d(8)));
      expect(result.riskLevel, StreakRiskLevel.normal);
    });

    test('a mutual day after a 2+ day gap restarts at 1 and preserves the '
        'lapsed count', () {
      // 3.4. The break is stamped at the deadline that was missed, not at now,
      // and the restart does not withdraw the still-open restore offer.
      final stored = engineState(anchor: d(5), count: 6, longestForRoom: 9);

      final afterA = evaluate(
        stored,
        event: Participation(uid: uidA, instant: inDay(d(7))),
        serverNow: inDay(d(7)),
      ).next;
      // The break was stamped the moment day 7 was reached, at the missed
      // deadline (start of day 7), not at the instant it was noticed.
      expect(afterA.brokenAt, startOf(d(7)));
      expect(afterA.previousCount, 6);
      expect(afterA.count, 0);

      final result = evaluate(
        afterA,
        event: Participation(uid: uidB, instant: inDay(d(7), hours: 13)),
        serverNow: inDay(d(7), hours: 13),
      );

      expect(result.transitions, <StreakTransition>[
        StreakTransition.participationRecorded,
        StreakTransition.started,
      ]);
      expect(result.count, 1);
      expect(result.lastMutualDay, d(7));
      expect(result.deadlineAt, startOf(d(9)));
      expect(result.previousCount, 6,
          reason: '3.4: the lapsed count stays restorable');
      expect(result.brokenAt, startOf(d(7)));
      expect(result.next.longestForRoom, 9, reason: 'a restart is not a record');
      expect(result.includes(StreakTransition.longestRaised), isFalse);
    });

    test('a single evaluation that sees the gap stamps the break itself', () {
      // The unswept case: both send days already sit past the deadline while
      // the count still says 6.
      final stored = engineState(
        anchor: d(5),
        count: 6,
        longestForRoom: 9,
        // A already sent on the day past the deadline; nothing has swept yet.
        sendDays: <String, StreakDay>{uidA: d(7), uidB: d(5)},
      );

      final result = evaluate(
        stored,
        event: Participation(uid: uidB, instant: inDay(d(7), hours: 13)),
        serverNow: inDay(d(7), hours: 13),
      );

      expect(result.transitions, <StreakTransition>[
        StreakTransition.participationRecorded,
        StreakTransition.broken,
        StreakTransition.started,
      ]);
      expect(result.count, 1);
      expect(result.previousCount, 6);
      expect(result.brokenAt, startOf(d(7)),
          reason: 'the deadline that was missed');
    });
  });

  group('step 8 — broken exactly at the deadline', () {
    final stored = engineState(
      anchor: d(5),
      count: 5,
      longestForRoom: 5,
      riskLevel: StreakRiskLevel.critical,
    );
    final deadline = startOf(d(7));

    test('one millisecond before the deadline the bond is still alive', () {
      final result = evaluate(
        stored,
        serverNow: deadline.subtract(const Duration(milliseconds: 1)),
      );

      expect(result.count, 5);
      expect(result.riskLevel, StreakRiskLevel.critical);
      expect(result.includes(StreakTransition.broken), isFalse);
      expect(result.changed, isFalse);
    });

    test('at the deadline it breaks, with no writer and no event', () {
      // 2.15 / 1.13: this is the whole read-side derivation.
      final result = evaluate(stored, serverNow: deadline);

      expect(result.transitions, <StreakTransition>[StreakTransition.broken]);
      expect(result.count, 0);
      expect(result.riskLevel, StreakRiskLevel.broken);
      expect(result.previousCount, 5);
      expect(result.brokenAt, deadline, reason: '2.16: the deadline, not now');
      expect(result.restoreDeadlineAt, deadline.add(const Duration(hours: 24)));
      expect(result.lastMutualDay, d(5), reason: 'the anchor survives a break');
      expect(result.next.sendDays[uidA], d(5),
          reason: '2.16: send evidence is preserved, not wiped');
      expect(result.next.longestForRoom, 5);
      expect(result.changed, isTrue);
      expect(result.next.isRestorable(deadline), isTrue);
    });

    test('five weeks stale still derives broken, with the window long shut', () {
      // 1.13 / 1.17: the 🔥 badge on a month-dead bond.
      final result = evaluate(stored, serverNow: inDay(d(5)).add(const Duration(days: 35)));

      expect(result.count, 0);
      expect(result.riskLevel, StreakRiskLevel.broken);
      expect(result.previousCount, 0, reason: 'the restore window closed too');
      expect(result.brokenAt, isNull);
      expect(result.transitions, <StreakTransition>[
        StreakTransition.broken,
        StreakTransition.restoreWindowExpired,
      ]);
    });

    test('stamping the break is idempotent', () {
      final first = evaluate(stored, serverNow: deadline);
      final second = evaluate(first.next, serverNow: deadline);

      expect(second.transitions, <StreakTransition>[StreakTransition.noop]);
      expect(second.changed, isFalse);
      expect(second.next.sameDocumentAs(first.next), isTrue);
    });
  });

  group('step 9 — restoreWindowExpired', () {
    final brokenAt = startOf(d(7));
    final restoreDeadline = brokenAt.add(kStreakRestoreWindow);
    final stored = engineState(
      anchor: d(5),
      count: 0,
      longestForRoom: 5,
      previousCount: 5,
      brokenAt: brokenAt,
      restoreDeadlineAt: restoreDeadline,
      riskLevel: StreakRiskLevel.broken,
    );

    test('the last instant of the window is still restorable', () {
      final result = evaluate(stored, serverNow: restoreDeadline);

      expect(result.transitions, <StreakTransition>[StreakTransition.noop]);
      expect(result.previousCount, 5);
      expect(result.brokenAt, brokenAt);
      expect(result.changed, isFalse);
    });

    test('one millisecond later the window closes', () {
      final result = evaluate(
        stored,
        serverNow: restoreDeadline.add(const Duration(milliseconds: 1)),
      );

      expect(result.transitions, <StreakTransition>[
        StreakTransition.restoreWindowExpired,
      ]);
      expect(result.previousCount, 0);
      expect(result.brokenAt, isNull);
      expect(result.restoreDeadlineAt, isNull);
      expect(result.count, 0);
      expect(result.riskLevel, StreakRiskLevel.broken);
      expect(result.lastMutualDay, d(5), reason: 'history is not rewritten');
      expect(result.changed, isTrue);
    });

    test('expiry is idempotent', () {
      final now = restoreDeadline.add(const Duration(hours: 3));
      final first = evaluate(stored, serverNow: now);
      final second = evaluate(first.next, serverNow: now);

      expect(second.transitions, <StreakTransition>[StreakTransition.noop]);
      expect(second.changed, isFalse);
    });
  });

  group('bridgedThroughDay — the chain after a restore', () {
    // The shape `POST /streakRestore` writes: the count comes back, the anchor
    // is NOT moved (no mutual day is invented, 1.18/2.20), and the bridge day
    // is what keeps the chain continuous.
    StreakState restored({StreakDay? bridge}) => engineState(
          anchor: d(5),
          count: 7,
          bridged: bridge ?? d(9),
          longestForRoom: 7,
          sendDays: <String, StreakDay>{uidA: d(5), uidB: d(5)},
        );

    test('a mutual day on the bridge day increments, it does not restart', () {
      final afterA = evaluate(
        restored(),
        event: Participation(uid: uidA, instant: inDay(d(9), hours: 15)),
        serverNow: inDay(d(9), hours: 15),
      ).next;
      final result = evaluate(
        afterA,
        event: Participation(uid: uidB, instant: inDay(d(9), hours: 16)),
        serverNow: inDay(d(9), hours: 16),
      );

      expect(result.includes(StreakTransition.incremented), isTrue);
      expect(result.includes(StreakTransition.broken), isFalse);
      expect(result.count, 8);
      expect(result.lastMutualDay, d(9));
      expect(result.next.bridgedThroughDay, isNull,
          reason: 'the bridge has been superseded by a real mutual day');
      expect(result.deadlineAt, startOf(d(11)));
    });

    test('a mutual day on the day after the bridge still increments', () {
      final afterA = evaluate(
        restored(),
        event: Participation(uid: uidA, instant: inDay(d(10))),
        serverNow: inDay(d(10)),
      ).next;
      final result = evaluate(
        afterA,
        event: Participation(uid: uidB, instant: inDay(d(10), hours: 13)),
        serverNow: inDay(d(10), hours: 13),
      );

      expect(result.count, 8);
      expect(result.lastMutualDay, d(10));
      expect(result.includes(StreakTransition.broken), isFalse);
      expect(result.next.bridgedThroughDay, isNull);
      expect(result.next.longestForRoom, 8);
      expect(result.includes(StreakTransition.longestRaised), isTrue);
    });

    test('a restored bond still breaks if the bridged deadline is missed', () {
      final afterA = evaluate(
        restored(),
        event: Participation(uid: uidA, instant: inDay(d(11))),
        serverNow: inDay(d(11)),
      ).next;
      final result = evaluate(
        afterA,
        event: Participation(uid: uidB, instant: inDay(d(11), hours: 13)),
        serverNow: inDay(d(11), hours: 13),
      );

      expect(result.count, 1);
      expect(result.previousCount, 7);
      expect(result.brokenAt, startOf(d(11)),
          reason: 'the bridged deadline: dayStart(bridge + 2)');
      expect(result.lastMutualDay, d(11));
    });

    test('a restore alone does not make the next single mutual day count '
        'twice', () {
      final result = foldSends(
        <ReferenceSend>[
          ReferenceSend(uidA, inDay(d(9), hours: 15)),
          ReferenceSend(uidB, inDay(d(9), hours: 16)),
        ],
        inDay(d(9), hours: 17),
      );
      // Same two sends against a virgin state produce 1, so the +1 seen above
      // is the restore's count carrying over, not a double count.
      expect(result.count, 1);
    });
  });

  group('step 11 — milestones by crossing', () {
    test('crossing 7 emits it once, and the writer owns the ledger', () {
      final afterA = evaluate(
        engineState(anchor: d(5), count: 6, longestForRoom: 6),
        event: Participation(uid: uidA, instant: inDay(d(6))),
        serverNow: inDay(d(6)),
      ).next;
      final result = evaluate(
        afterA,
        event: Participation(uid: uidB, instant: inDay(d(6), hours: 13)),
        serverNow: inDay(d(6), hours: 13),
      );

      expect(result.count, 7);
      expect(result.milestonesCrossed, <int>[7]);
      expect(result.includes(StreakTransition.milestoneCrossed), isTrue);
      expect(result.next.milestonesAwarded, isEmpty,
          reason: 'the engine reports; the paying transaction records');
    });

    test('an already-awarded threshold is never re-emitted', () {
      // The re-climb after a break is the replay this guards (1.21/2.23).
      final afterA = evaluate(
        engineState(
          anchor: d(5),
          count: 6,
          longestForRoom: 12,
          milestonesAwarded: const <int>[7],
        ),
        event: Participation(uid: uidA, instant: inDay(d(6))),
        serverNow: inDay(d(6)),
      ).next;
      final result = evaluate(
        afterA,
        event: Participation(uid: uidB, instant: inDay(d(6), hours: 13)),
        serverNow: inDay(d(6), hours: 13),
      );

      expect(result.count, 7);
      expect(result.milestonesCrossed, isEmpty);
      expect(result.includes(StreakTransition.milestoneCrossed), isFalse);
    });

    test('every threshold is crossed on the step that reaches it, and only '
        'then', () {
      // Crossing, not exact match: the rule is `previous < t <= count`. Note
      // that `evaluate` only ever moves the count by +1 (or resets it), so a
      // *jump* past a threshold — a restore 5 → 12, or a repair — is not
      // reachable from here and must be awarded by the writer performing the
      // jump. See the report for task 3.3.
      for (final entry in <int, List<int>>{
        5: <int>[],
        6: <int>[7],
        28: <int>[],
        29: <int>[30],
        98: <int>[],
        99: <int>[100],
        364: <int>[365],
      }.entries) {
        final afterA = evaluate(
          engineState(anchor: d(5), count: entry.key, longestForRoom: 400),
          event: Participation(uid: uidA, instant: inDay(d(6))),
          serverNow: inDay(d(6)),
        ).next;
        final result = evaluate(
          afterA,
          event: Participation(uid: uidB, instant: inDay(d(6), hours: 13)),
          serverNow: inDay(d(6), hours: 13),
        );

        expect(result.count, entry.key + 1);
        expect(result.milestonesCrossed, entry.value,
            reason: 'from count ${entry.key}');
      }
    });

    test('a break and restart re-crosses nothing that was already paid', () {
      final result = evaluate(
        engineState(
          anchor: d(5),
          count: 7,
          longestForRoom: 7,
          milestonesAwarded: const <int>[7],
        ),
        serverNow: startOf(d(7)),
      );

      expect(result.count, 0);
      expect(result.milestonesCrossed, isEmpty);
    });
  });

  group('step 12 — longestForRoom', () {
    test('rises with every new maximum, not only at thresholds', () {
      // 2.24 / 1.22: "Best Bond" could only ever read 0, 7, 30 or 100.
      final afterA = evaluate(
        engineState(anchor: d(5), count: 3, longestForRoom: 3),
        event: Participation(uid: uidA, instant: inDay(d(6))),
        serverNow: inDay(d(6)),
      ).next;
      final result = evaluate(
        afterA,
        event: Participation(uid: uidB, instant: inDay(d(6), hours: 13)),
        serverNow: inDay(d(6), hours: 13),
      );

      expect(result.next.longestForRoom, 4);
      expect(result.includes(StreakTransition.longestRaised), isTrue);
    });

    test('a break never lowers it', () {
      final result = evaluate(
        engineState(anchor: d(5), count: 9, longestForRoom: 9),
        serverNow: startOf(d(7)),
      );

      expect(result.count, 0);
      expect(result.next.longestForRoom, 9);
      expect(result.includes(StreakTransition.longestRaised), isFalse);
    });
  });

  group('step 10 — risk level agrees with the break rule', () {
    final stored = engineState(anchor: d(5), count: 3);
    final deadline = startOf(d(7));

    test('the thresholds sit exactly where the design puts them', () {
      final samples = <Duration, StreakRiskLevel>{
        const Duration(hours: 24, milliseconds: 1): StreakRiskLevel.normal,
        const Duration(hours: 24): StreakRiskLevel.atRisk,
        const Duration(hours: 6, milliseconds: 1): StreakRiskLevel.atRisk,
        const Duration(hours: 6): StreakRiskLevel.critical,
        const Duration(milliseconds: 1): StreakRiskLevel.critical,
        Duration.zero: StreakRiskLevel.broken,
        const Duration(hours: -1): StreakRiskLevel.broken,
      };

      samples.forEach((remaining, expected) {
        final now = deadline.subtract(remaining);
        final result = evaluate(stored, serverNow: now);
        expect(result.riskLevel, expected, reason: 'remaining: $remaining');
        expect(result.isBroken, !now.isBefore(deadline),
            reason: 'broken iff serverNow >= deadlineAt ($remaining)');
        expect(result.count == 0, !now.isBefore(deadline),
            reason: 'a live count and a passed deadline cannot coexist');
      });
    });

    test('a bond that never started has no deadline and no risk', () {
      final result = evaluate(
        StreakState.empty(participants: pair),
        serverNow: inDay(d(1)),
      );

      expect(result.count, 0);
      expect(result.deadlineAt, isNull);
      expect(result.riskLevel, StreakRiskLevel.normal,
          reason: 'no badge, not a broken badge');
    });
  });

  group('reaction exclusion is the caller\'s contract', () {
    test('every Participation the engine is given is treated as qualifying',
        () {
      // 2.10: reactions are filtered once, at the trigger
      // (`streakOnMessageCreate` skips `type == "reaction"`). The engine has no
      // message-type parameter *by design* — one rule, one enforcement point —
      // so this test pins the contract: whatever reaches `evaluate` counts.
      final result = foldSends(<ReferenceSend>[
        ReferenceSend(uidA, inDay(d(1), hours: 9)),
        ReferenceSend(uidB, inDay(d(1), hours: 10)),
      ], inDay(d(1), hours: 11));

      expect(result.count, 1);
    });

    test('a day whose only traffic was filtered out never refreshes the '
        'deadline', () {
      // The caller drops the reaction, so the engine simply sees no event: the
      // deadline stands where the last mutual day put it (1.10).
      final stored = engineState(anchor: d(5), count: 3);

      final result = evaluate(stored, serverNow: inDay(d(6), hours: 20));

      expect(result.deadlineAt, startOf(d(7)));
      expect(result.count, 3);
      expect(result.riskLevel, StreakRiskLevel.critical);
      expect(result.changed, isTrue, reason: 'only the risk level moved');
      expect(result.next.deadlineAt, stored.deadlineAt);
    });
  });

  group('step 2 — out-of-order and duplicate participation', () {
    test('the same event applied twice is applied once', () {
      // 2.4 / 2.11: structural idempotency, no dedupe ledger needed.
      final event = Participation(uid: uidA, instant: inDay(d(6)));
      final first = evaluate(
        engineState(anchor: d(5), count: 3, longestForRoom: 9),
        event: event,
        serverNow: inDay(d(6)),
      );
      final second = evaluate(
        first.next,
        event: event,
        serverNow: inDay(d(6)),
      );

      expect(second.transitions, <StreakTransition>[StreakTransition.noop]);
      expect(second.changed, isFalse);
      expect(second.next.sameDocumentAs(first.next), isTrue);
    });

    test('a late message for an earlier day is ignored, not double counted',
        () {
      final stored = engineState(
        anchor: d(6),
        count: 1,
        longestForRoom: 1,
        sendDays: <String, StreakDay>{uidA: d(6), uidB: d(6)},
      );

      final result = evaluate(
        stored,
        event: Participation(uid: uidB, instant: inDay(d(5), hours: 20)),
        serverNow: inDay(d(6), hours: 20),
      );

      // The event is dropped by step 2, so what is left is an ordinary
      // already-counted day: `sameDay`, and nothing moves.
      expect(result.transitions, <StreakTransition>[StreakTransition.sameDay]);
      expect(result.includes(StreakTransition.participationRecorded), isFalse);
      expect(result.count, 1,
          reason: 'forward-only participation: a retroactive day cannot '
              'create a past mutual day');
      expect(result.next.sendDays[uidB], d(6));
      expect(result.changed, isFalse);
    });

    test('an event from outside the pair is ignored', () {
      final stored = engineState(anchor: d(5), count: 3);

      final result = evaluate(
        stored,
        event: Participation(uid: uidC, instant: inDay(d(6))),
        serverNow: inDay(d(6), hours: 1),
      );

      expect(result.next.sendDays.containsKey(uidC), isFalse);
      expect(result.count, 3);
    });

    test('a non-monotonic burst converges on the same state as sorted '
        'delivery', () {
      final sends = <ReferenceSend>[
        ReferenceSend(uidA, inDay(d(1), hours: 9)),
        ReferenceSend(uidB, inDay(d(1), hours: 10)),
        ReferenceSend(uidA, inDay(d(2), hours: 9)),
        ReferenceSend(uidB, inDay(d(2), hours: 23)),
      ];
      final now = inDay(d(2), hours: 23, minutes: 30);

      final sorted = foldSends(sends, now);
      final shuffled = foldSends(<ReferenceSend>[
        sends[1],
        sends[0],
        sends[3],
        sends[2],
      ], now);

      expect(sorted.count, 2);
      expect(shuffled.count, sorted.count);
      expect(shuffled.deadlineAt, sorted.deadlineAt);
    });
  });

  group('idempotency across every transition', () {
    test('re-evaluating the engine\'s own output changes nothing', () {
      final scenarios = <String, List<Object?>>{
        // name: [stored, event, serverNow]
        'started': <Object?>[
          StreakState(
            engineVersion: StreakEngine.engineVersion,
            participants: pair,
            sendDays: <String, StreakDay>{uidA: d(1)},
            sendInstants: <String, DateTime>{uidA: inDay(d(1))},
          ),
          Participation(uid: uidB, instant: inDay(d(1), hours: 14)),
          inDay(d(1), hours: 14),
        ],
        'participationRecorded': <Object?>[
          StreakState.empty(participants: pair),
          Participation(uid: uidA, instant: inDay(d(1))),
          inDay(d(1)),
        ],
        'incremented': <Object?>[
          engineState(
            anchor: d(5),
            count: 3,
            sendDays: <String, StreakDay>{uidA: d(6), uidB: d(5)},
          ),
          Participation(uid: uidB, instant: inDay(d(6), hours: 13)),
          inDay(d(6), hours: 13),
        ],
        'sameDay': <Object?>[
          engineState(anchor: d(5), count: 3),
          Participation(uid: uidA, instant: inDay(d(5), hours: 20)),
          inDay(d(5), hours: 20),
        ],
        'broken': <Object?>[
          engineState(anchor: d(5), count: 4),
          null,
          startOf(d(7)),
        ],
        'brokenThenRestarted': <Object?>[
          engineState(
            anchor: d(5),
            count: 6,
            sendDays: <String, StreakDay>{uidA: d(7), uidB: d(5)},
          ),
          Participation(uid: uidB, instant: inDay(d(7), hours: 13)),
          inDay(d(7), hours: 13),
        ],
        'restoreWindowExpired': <Object?>[
          engineState(
            anchor: d(5),
            count: 0,
            previousCount: 4,
            longestForRoom: 4,
            brokenAt: startOf(d(7)),
            restoreDeadlineAt: startOf(d(8)),
            riskLevel: StreakRiskLevel.broken,
          ),
          null,
          inDay(d(8), hours: 3),
        ],
        'milestoneCrossed': <Object?>[
          engineState(
            anchor: d(5),
            count: 6,
            sendDays: <String, StreakDay>{uidA: d(6), uidB: d(5)},
          ),
          Participation(uid: uidB, instant: inDay(d(6), hours: 13)),
          inDay(d(6), hours: 13),
        ],
        'bridgedThroughDay': <Object?>[
          engineState(
            anchor: d(5),
            count: 7,
            bridged: d(9),
            sendDays: <String, StreakDay>{uidA: d(9), uidB: d(5)},
          ),
          Participation(uid: uidB, instant: inDay(d(9), hours: 16)),
          inDay(d(9), hours: 16),
        ],
      };

      scenarios.forEach((name, input) {
        final stored = input[0]! as StreakState;
        final event = input[1] as Participation?;
        final serverNow = input[2]! as DateTime;

        final first = StreakEngine.evaluate(
          stored: stored,
          participants: pair,
          event: event,
          serverNow: serverNow,
        );

        // Replaying the identical call — the delivery the trigger might repeat.
        final replayedWithEvent = StreakEngine.evaluate(
          stored: first.next,
          participants: pair,
          event: event,
          serverNow: serverNow,
        );
        expect(replayedWithEvent.changed, isFalse,
            reason: '$name: replaying the event is not idempotent');
        expect(replayedWithEvent.next.sameDocumentAs(first.next), isTrue,
            reason: name);
        expect(replayedWithEvent.milestonesCrossed, isEmpty, reason: name);
        expect(replayedWithEvent.count, first.count, reason: name);

        // Deriving the same state for display, with no event.
        final derived = StreakEngine.evaluate(
          stored: first.next,
          participants: pair,
          event: null,
          serverNow: serverNow,
        );
        expect(derived.changed, isFalse,
            reason: '$name: read-side derivation is not a no-op');
        expect(derived.transitions, <StreakTransition>[StreakTransition.noop],
            reason: name);
      });
    });
  });

  group('agreement with the independent oracle', () {
    // `referenceStreak` is a naive reimplementation written from the
    // requirements, sharing no code with the engine, so agreement is evidence.
    // Compared on count, lastMutualDay and broken state, per task 3.3.
    void expectAgreement(
      String name,
      List<ReferenceSend> sends,
      DateTime serverNow, {
      List<String> participants = pair,
    }) {
      final expected = referenceStreak(
        sends,
        serverNow,
        participants: participants,
      );
      final actual = foldSends(sends, serverNow, participants: participants);

      expect(actual.count, expected.count, reason: '$name: count');
      expect(actual.lastMutualDay?.key, expected.lastMutualDay,
          reason: '$name: lastMutualDay');
      expect(actual.isBroken, expected.isBroken, reason: '$name: broken');
    }

    List<ReferenceSend> mutualDays(Iterable<int> days) => <ReferenceSend>[
          for (final day in days) ...<ReferenceSend>[
            ReferenceSend(uidA, inDay(d(day), hours: 9)),
            ReferenceSend(uidB, inDay(d(day), hours: 17)),
          ],
        ];

    test('five consecutive mutual days', () {
      expectAgreement(
        'consecutive',
        mutualDays(<int>[1, 2, 3, 4, 5]),
        inDay(d(5), hours: 20),
      );
    });

    test('a gap that breaks the chain, then a fresh mutual day', () {
      expectAgreement(
        'gap then restart',
        mutualDays(<int>[1, 2, 3]) + mutualDays(<int>[6]),
        inDay(d(6), hours: 20),
      );
    });

    test('one-sided traffic is never a streak', () {
      expectAgreement(
        'one sided',
        <ReferenceSend>[
          for (final day in <int>[1, 2, 3, 4])
            ReferenceSend(uidA, inDay(d(day), hours: 9)),
        ],
        inDay(d(4), hours: 20),
      );
    });

    test('many sends per day collapse to one mutual day each', () {
      expectAgreement(
        'chatty',
        <ReferenceSend>[
          for (final day in <int>[1, 2])
            for (final hour in <int>[1, 6, 9, 14, 23]) ...<ReferenceSend>[
              ReferenceSend(uidA, inDay(d(day), hours: hour)),
              ReferenceSend(uidB, inDay(d(day), hours: hour, minutes: 30)),
            ],
        ],
        inDay(d(2), hours: 23, minutes: 59),
      );
    });

    test('lapsed, inside the restore window', () {
      final sends = mutualDays(<int>[1, 2]);
      final now = startOf(d(4)).add(const Duration(hours: 6));

      expectAgreement('lapsed restorable', sends, now);

      final expected = referenceStreak(sends, now);
      final actual = foldSends(sends, now);
      expect(actual.previousCount, expected.previousCount);
      expect(actual.brokenAt, expected.brokenAt);
      expect(actual.deadlineAt, expected.deadlineAt);
    });

    test('lapsed, window closed', () {
      expectAgreement(
        'lapsed expired',
        mutualDays(<int>[1, 2]),
        inDay(d(5), hours: 12),
      );
    });

    test('a day boundary crossing: sends either side of canonical midnight',
        () {
      // 2.6: 23:45 and 00:15 canonical are different streak days, and no
      // wall-clock arithmetic in any zone can merge them.
      expectAgreement(
        'boundary',
        <ReferenceSend>[
          ReferenceSend(uidA, inDay(d(1), hours: 23, minutes: 45)),
          ReferenceSend(uidB, inDay(d(2), hours: 0, minutes: 15)),
          ReferenceSend(uidA, inDay(d(2), hours: 1)),
        ],
        inDay(d(2), hours: 2),
      );
    });

    test('self-chat: both the engine and the oracle refuse it', () {
      expectAgreement(
        'self chat',
        <ReferenceSend>[
          ReferenceSend(uidA, inDay(d(1), hours: 9)),
          ReferenceSend(uidA, inDay(d(2), hours: 9)),
        ],
        inDay(d(2), hours: 20),
        participants: const <String>[uidA, uidA],
      );
    });

    test('a long unbroken run', () {
      expectAgreement(
        'ten days',
        mutualDays(List<int>.generate(10, (i) => i + 1)),
        inDay(d(10), hours: 22),
      );
    });
  });
}
