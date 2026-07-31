// ════════════════════════════════════════════════════════════════════════════
//  BUG CONDITION EXPLORATION — chat-streak-system-fix, task 1
// ════════════════════════════════════════════════════════════════════════════
//
// These tests run against the UNFIXED logic, transcribed frozen in
// `test/support/legacy_streak_reference.dart`. Every assertion here documents
// the BUGGY outcome. A green run means the bug is reproduced and that row of
// the root-cause table is CONFIRMED.
//
// Task 3.6 re-runs these same scenarios against `StreakEngine` with the
// assertions inverted to the correct outcome, which is recorded next to each
// counterexample below.
//
// ────────────────────────────────────────────────────────────────────────────
//  COUNTEREXAMPLE LOG  (inputs → legacy result vs reference result)
// ────────────────────────────────────────────────────────────────────────────
//
// [1.1 / 1.3] STALE CACHE — increment dropped
//   stored: count 4, anchor 2024-03-03 10:00 IST, lastSentAt{A: 03-04 09:00,
//           B: 03-04 09:05}
//   A's cache (filled 2024-03-03 21:00 IST, 12h stale): count 4,
//           anchor 03-03 10:00, lastSentAt{A: 03-04 09:00, B: 03-03 10:00}
//   event : A sends 2024-03-04 09:10 IST
//   legacy: cacheHit=true, readFirestore=false, otherSentToday=FALSE,
//           branch=waitingForOtherUser, streakCount written = 4
//   same call with a cold cache: otherSentToday=TRUE, daysDiff=1,
//           streakCount written = 5
//   reference: mutual days [03-03, 03-04] → count 2 (i.e. it increments)
//   correct : increment (engine sees the partner's send; 4 → 5)
//   also   : the cache is 12h old and still a hit — `_streakCacheTtl`
//           (30 min) is never compared against anything.
//
// [1.2] ANCHOR ADVANCED WITHOUT A MUTUAL DAY — PARTIALLY CONFIRMED
//   CONFIRMED: the cache rewrite. stored anchor = 2024-03-03, A sends alone on
//     2024-03-04 08:00 IST → branch=waitingForOtherUser, roomUpdates carries
//     NO lastInteractionDate, yet nextCache.lastInteraction = 03-04 08:00.
//     The device's anchor day moved from 03-03 to 03-04 with no mutual day.
//   REFUTED as written: "the later completing reply is classified as same day".
//     The corrupted anchor lives ONLY in the sending device's `_streakCache`,
//     and that same cache can never observe the partner's send (it is refilled
//     from Firestore only when EMPTY, and a refill overwrites the anchor with
//     the stored value). So on the legacy code the completing reply is NOT
//     misclassified: B's cold-cache evaluation on 2024-03-04 09:00 reads the
//     uncorrupted stored anchor 03-03, gets daysDiff = 1 and increments 4 → 5.
//     What actually destroys that increment is A's NEXT send from the stale
//     cache: 2024-03-04 10:00 → waitingForOtherUser → streakCount written = 4,
//     which merges over B's 5 (see 1.4). Net effect on the user is identical
//     ("stuck for weeks"), cause is stale-cache + last-writer-wins, not the
//     anchor rewrite.
//   The daysDiff == 0 misclassification of a genuine completing reply IS
//     reachable — but only through a PERSISTED anchor advance, i.e. restore
//     writing `lastInteractionDate: now` (1.18, see below) or a skewed clock
//     writing a future anchor (1.11). Counterexample under [1.18].
//
// [1.5] CROSS-TIMEZONE DISAGREEMENT
//   stored: count 4, anchor 2024-03-02T18:00Z, lastSentAt{A: 2024-03-03T18:00Z}
//   event : B sends 2024-03-04T04:00Z
//   legacy @ UTC+05:30: today=03-04, A's send=03-03 wall → otherSentToday=false
//           → streakCount written = 4
//   legacy @ UTC-08:00: today=03-03, A's send=03-03 wall → otherSentToday=true,
//           daysDiff=1 → streakCount written = 5
//   correct : one answer for both devices.
//
// [1.6] DST-SHORTENED DAY — increment dropped
//   zone  : America/Los_Angeles, spring-forward 2024-03-10T10:00Z
//   stored: count 5, anchor 2024-03-10T19:00Z (PT 03-10 12:00),
//           lastSentAt{A: 2024-03-11T18:30Z}
//   event : B sends 2024-03-11T19:00Z (PT 03-11 12:00)
//   legacy: today=03-11, anchor day=03-10, and
//           (localMidnight 03-11 = 07:00Z) − (localMidnight 03-10 = 08:00Z)
//           = 23h → inDays = 0 → branch=sameDay → count stays 5
//   same inputs @ fixed UTC-08:00: daysDiff = 1 → count 6
//   reference: mutual canonical days [2024-03-11, 2024-03-12] → 1 → 2
//   correct : 5 → 6.
//
// [1.9] SELF-CHAT FARMING
//   senderId == receiverId == 'A', empty room
//   legacy: otherUserId = 'A', otherSentToday = true from the sender's own
//           in-memory `lastSentAt[senderId] = now` → count 1, then 2 the next
//           day, purely alone.
//   reference (participants ['A']): count 0
//   correct : 0, always.
//
// [1.10] REACTION REFRESHES THE DEADLINE
//   stored: count 6, anchor 2024-05-01 09:00 IST, both participants sent 05-01
//   event : A sends a REACTION 2024-05-01 20:00 IST
//   legacy: messageType is never consulted → branch=sameDay →
//           roomUpdates['lastInteractionDate'] = 05-01 20:00, so the badge's
//           48h countdown restarts off a reaction.
//   correct : reactions do not qualify; the deadline does not move.
//
// [1.11] CLIENT CLOCK
//   (a) self-chat + clock walked +1 day per send, zero partner activity →
//       counts [1, 2, 3, 4, 5].
//   (b) A's device is 24h fast: true instant 2024-03-04 09:00 IST, believed
//       2024-03-05 09:00 IST. The post-commit write stamps
//       lastSentAt[A] = 2024-03-05 09:00 (a future instant). B, with a correct
//       clock, evaluates on 2024-03-04 10:00: A's send reads as 03-05 → today
//       is 03-04 → otherSentToday=false → the genuine mutual day is lost and
//       the count stays 4.
//   correct : server time; the skewed device changes nothing.
//
// [1.13 / 1.17] NO EVALUATION ON READ
//   stored: count 7, anchor 35 days ago, nobody has sent since
//   legacy: display returns 7 verbatim, `legacyEvaluate` is never called
//           (evaluateCallCount unchanged), computeStreakRisk → critical
//           (the enum has no `broken`), and the cache rehydrates the same two
//           fields with no freshness marker.
//   reference: isBroken = true, count 0, restore window long closed
//   correct : derive on read → broken, no badge.
//
// [1.15] BADGE DEADLINE ≠ BREAK DEADLINE
//   anchor at local 23:30 yesterday: badge says ~47h30m remaining, the
//     calendar-day rule breaks at local midnight tonight+1 → ~24h30m.
//     Disagreement > 20h.
//   anchor at local 00:30 yesterday: badge ~24h30m, calendar ~24h00m →
//     disagreement < 1h.
//   correct : one `deadlineAt`, read by both.
//
// [1.4] CONCURRENT WRITES — the later write carries the LOWER count
//   B's cold-cache write: {streakCount: 5, lastInteractionDate: 03-04 09:05}
//   A's stale-cache write, 5 minutes later: {streakCount: 4}
//   merge order B then A → persisted streakCount = 4
//   correct : transactional, monotonic; 5 stands.
//
// [1.7 / 1.8] NON-ATOMIC PARTICIPATION
//   roomUpdates contains no `lastSentAt` key at all; the sender's
//   participation is a separate fire-and-forget `update()` after
//   `batch.commit()`, stamped with a SECOND `DateTime.now()`.
//   Drop that write (timeout / app killed): the message is persisted, the
//   evidence is not, and the partner's evaluation the next day still reports
//   otherSentToday=false → no increment, ever.
//   correct : participation derived from the persisted message itself.
//
// [1.18] RESTORE FABRICATES A MUTUAL DAY (and this is where daysDiff == 0 bites)
//   broken room: previousStreakCount 5, streakBrokenAt 2024-03-06 09:00 IST,
//                anchor 2024-03-04 10:00 IST
//   restore @ client 2024-03-06 20:00 → writes streakCount 5 AND
//                lastInteractionDate = 03-06 20:00 (no mutual message that day)
//   then a genuine mutual pair on 03-06 21:00 → daysDiff = 0 → no increment
//   then a genuine mutual day on 03-07 → daysDiff = 1 → 5 → 6, as if the chain
//        had never broken, on the strength of ONE mutual day
//   reference: single mutual day 03-07 → count 1
//   client-clock window: brokenAt 03-06 09:00, real now 03-08 09:00, device
//        believes 03-06 19:00 → the expired window is accepted.
//   correct : server-validated window, `bridgedThroughDay`, no invented day.
//
// [1.20] PRO FREE-RESTORE PERK — PARTIALLY CONFIRMED
//   CONFIRMED: `recordStreakRestore` writes `_kLastStreakRestore` and then
//     reads it straight back, so lastWeek == currentWeek on every call, the
//     "reset for new week" branch is dead code, and the counter only ever
//     grows: [1, 2, 3, …] across real week boundaries.
//   CONFIRMED: the allowance lives in SharedPreferences — clearing app data
//     restores eligibility immediately.
//   REFUTED: "permanently consumed on one device". `canRestoreStreakFree`
//     compares weeks BEFORE consulting the counter, so a new real week returns
//     true regardless of how large the counter has grown.
//
// [1.21 / 1.22] MILESTONES AND longestStreak
//   the call is `handleStreakMilestone(senderId, newStreak)`: sender only, so
//     the partner is never awarded; exact match, so any count that lands on a
//     non-threshold value (e.g. a restore to 12, then 13) awards nothing and
//     the crossed threshold is lost with no catch-up; no idempotency key, so
//     two evaluations that both produce 7 award 7 twice; and `longestStreak`
//     is written ONLY inside that method, so a room sitting at 13 leaves
//     longestStreak at 0.
//
// [PROPERTY] For every generated history of n ∈ [2, 30] consecutive mutual
//   days at any in-day minute, a device evaluating from a warm cache filled
//   before the history reports 0 while the reference reports n.
//
// ────────────────────────────────────────────────────────────────────────────

import 'package:glados/glados.dart';

// The badge's own 20h/36h/48h rule now lives frozen in the legacy reference:
// `streak_badge.dart` was reworked onto the canonical deadline in task 8.1.
import '../../support/legacy_streak_reference.dart';
import '../../support/reference_streak.dart';

/// The absolute instant of an Asia/Kolkata (UTC+05:30) wall-clock reading.
DateTime atIst(int y, int m, int d, [int h = 0, int min = 0]) =>
    DateTime.utc(y, m, d, h, min).subtract(const Duration(minutes: 330));

void main() {
  group('1.1 / 1.3 — stale device cache short-circuits the partner\'s send', () {
    final storedTruth = LegacyRoomDoc(
      streakCount: 4,
      lastInteractionDate: atIst(2024, 3, 3, 10),
      lastSentAt: {
        'A': atIst(2024, 3, 4, 9),
        'B': atIst(2024, 3, 4, 9, 5), // B completed the mutual day at 09:05
      },
      previousStreakCount: 0,
    );

    // Filled 12 hours before the evaluation, and still treated as valid.
    final staleCache = LegacyStreakCacheEntry(
      streakCount: 4,
      lastInteraction: atIst(2024, 3, 3, 10),
      lastSentAt: {
        'A': atIst(2024, 3, 4, 9),
        'B': atIst(2024, 3, 3, 10), // predates B's 03-04 message
      },
      filledAt: atIst(2024, 3, 3, 21),
    );

    test('the increment is dropped on the cached device (1.1)', () {
      final result = legacyEvaluate(
        stored: storedTruth,
        senderId: 'A',
        receiverId: 'B',
        cache: staleCache,
        now: atIst(2024, 3, 4, 9, 10),
      );

      expect(result.cacheHit, isTrue);
      expect(result.readFirestore, isFalse,
          reason: 'a cache hit skips the Firestore read entirely');
      expect(result.otherSentToday, isFalse,
          reason: "B's 03-04 09:05 message is invisible to A's cached copy");
      expect(result.branch, LegacyBranch.waitingForOtherUser);
      expect(result.streakCountWritten, 4, reason: 'no increment');
      expect(result.wroteLastInteractionDate, isFalse);
    });

    test('the same call with a cold cache does increment — the cache is the '
        'cause (1.1)', () {
      final result = legacyEvaluate(
        stored: storedTruth,
        senderId: 'A',
        receiverId: 'B',
        cache: null,
        now: atIst(2024, 3, 4, 9, 10),
      );

      expect(result.readFirestore, isTrue);
      expect(result.otherSentToday, isTrue);
      expect(result.daysDiff, 1);
      expect(result.streakCountWritten, 5);
    });

    test('the reference oracle increments across the two mutual days', () {
      final sends = <ReferenceSend>[
        ReferenceSend('A', atIst(2024, 3, 3, 9, 30)),
        ReferenceSend('B', atIst(2024, 3, 3, 10)),
        ReferenceSend('A', atIst(2024, 3, 4, 9)),
        ReferenceSend('B', atIst(2024, 3, 4, 9, 5)),
      ];

      final beforeToday = referenceStreak(
          sends.sublist(0, 2), atIst(2024, 3, 3, 23), participants: ['A', 'B']);
      final withToday =
          referenceStreak(sends, atIst(2024, 3, 4, 9, 10), participants: ['A', 'B']);

      expect(beforeToday.count, 1);
      expect(withToday.count, 2, reason: 'the mutual day 03-04 counts');
      expect(withToday.lastMutualDay, '2024-03-04');
    });

    test('a 12-hour-old cache entry is still a hit — the declared 30 minute '
        'TTL is never compared against anything (1.3)', () {
      final now = atIst(2024, 3, 4, 9, 10);
      final age = now.difference(staleCache.filledAt!);

      expect(age, greaterThan(LegacyStreakReference.declaredCacheTtl));
      expect(age.inHours, 12);

      final result = legacyEvaluate(
        stored: storedTruth,
        senderId: 'A',
        receiverId: 'B',
        cache: staleCache,
        now: now,
      );

      expect(result.cacheHit, isTrue,
          reason: 'cacheHit is literally `cached != null`');
      expect(result.readFirestore, isFalse);
    });
  });

  group('1.2 — the cached anchor advances without a mutual day', () {
    final stored = LegacyRoomDoc(
      streakCount: 4,
      lastInteractionDate: atIst(2024, 3, 3, 10),
      lastSentAt: {
        'A': atIst(2024, 3, 3, 9, 30),
        'B': atIst(2024, 3, 3, 10),
      },
    );

    test('CONFIRMED: a lone send rewrites the cached anchor to a day with no '
        'mutual message, while writing no anchor to Firestore', () {
      final loneSend = legacyEvaluate(
        stored: stored,
        senderId: 'A',
        receiverId: 'B',
        cache: null,
        now: atIst(2024, 3, 4, 8),
      );

      expect(loneSend.branch, LegacyBranch.waitingForOtherUser);
      expect(loneSend.wroteLastInteractionDate, isFalse,
          reason: 'the room document keeps the honest 03-03 anchor');
      expect(loneSend.nextCache.lastInteraction, atIst(2024, 3, 4, 8),
          reason: '`lastInteraction: now` is written on EVERY branch');

      final tz = LegacyDeviceZone.ist;
      expect(tz.dayKey(tz.wall(loneSend.nextCache.lastInteraction!)),
          DateTime.utc(2024, 3, 4),
          reason: 'the cached anchor day moved 03-03 → 03-04 with no mutual day');
      expect(tz.dayKey(tz.wall(stored.lastInteractionDate!)),
          DateTime.utc(2024, 3, 3));
    });

    test("REFUTED as written: the partner's completing reply is NOT classified "
        'as same-day — the corrupted anchor never leaves the sending device', () {
      final loneSend = legacyEvaluate(
        stored: stored,
        senderId: 'A',
        receiverId: 'B',
        cache: null,
        now: atIst(2024, 3, 4, 8),
      );
      final afterLoneSend = legacyMergeRoomDoc(
        stored,
        loneSend.roomUpdates,
        postCommitLastSentAtUpdate: loneSend.postCommitLastSentAtUpdate,
      );

      // B completes the mutual day from its own (cold) device.
      final completingReply = legacyEvaluate(
        stored: afterLoneSend,
        senderId: 'B',
        receiverId: 'A',
        cache: null,
        now: atIst(2024, 3, 4, 9),
      );

      expect(completingReply.otherSentToday, isTrue);
      expect(completingReply.daysDiff, 1,
          reason: 'NOT 0 — the stored anchor is still 03-03');
      expect(completingReply.branch, LegacyBranch.incremented);
      expect(completingReply.streakCountWritten, 5);
    });

    test("and the increment is instead destroyed by A's next send from the "
        'stale cache (1.1 + 1.4)', () {
      final loneSend = legacyEvaluate(
        stored: stored,
        senderId: 'A',
        receiverId: 'B',
        cache: null,
        now: atIst(2024, 3, 4, 8),
      );
      var room = legacyMergeRoomDoc(stored, loneSend.roomUpdates,
          postCommitLastSentAtUpdate: loneSend.postCommitLastSentAtUpdate);

      final completingReply = legacyEvaluate(
        stored: room,
        senderId: 'B',
        receiverId: 'A',
        cache: null,
        now: atIst(2024, 3, 4, 9),
      );
      room = legacyMergeRoomDoc(room, completingReply.roomUpdates,
          postCommitLastSentAtUpdate:
              completingReply.postCommitLastSentAtUpdate);
      expect(room.streakCount, 5);

      // A sends again, still on its warm (now doubly stale) cache.
      final secondSend = legacyEvaluate(
        stored: room,
        senderId: 'A',
        receiverId: 'B',
        cache: loneSend.nextCache,
        now: atIst(2024, 3, 4, 10),
      );
      room = legacyMergeRoomDoc(room, secondSend.roomUpdates,
          postCommitLastSentAtUpdate: secondSend.postCommitLastSentAtUpdate);

      expect(secondSend.branch, LegacyBranch.waitingForOtherUser);
      expect(secondSend.streakCountWritten, 4);
      expect(room.streakCount, 4,
          reason: 'the correct 5 is clobbered by the stale device');
    });
  });

  group('1.5 — device-local day boundaries make two devices disagree', () {
    final stored = LegacyRoomDoc(
      streakCount: 4,
      lastInteractionDate: DateTime.utc(2024, 3, 2, 18),
      lastSentAt: {'A': DateTime.utc(2024, 3, 3, 18)},
    );
    final now = DateTime.utc(2024, 3, 4, 4); // B's completing send

    test('identical inputs, two devices, two different answers', () {
      final atIndia = legacyEvaluate(
        stored: stored,
        senderId: 'B',
        receiverId: 'A',
        cache: null,
        now: now,
        zone: LegacyDeviceZone.ist,
      );
      final atPacific = legacyEvaluate(
        stored: stored,
        senderId: 'B',
        receiverId: 'A',
        cache: null,
        now: now,
        zone: LegacyDeviceZone.fixedMinus8,
      );

      expect(atIndia.otherSentToday, isFalse);
      expect(atIndia.branch, LegacyBranch.waitingForOtherUser);
      expect(atIndia.streakCountWritten, 4);

      expect(atPacific.otherSentToday, isTrue);
      expect(atPacific.daysDiff, 1);
      expect(atPacific.streakCountWritten, 5);

      expect(atIndia.streakCountWritten,
          isNot(equals(atPacific.streakCountWritten)),
          reason: 'the outcome depends on who evaluates and where');
    });
  });

  group('1.6 — a DST-shortened local day drops the increment', () {
    final stored = LegacyRoomDoc(
      streakCount: 5,
      lastInteractionDate: DateTime.utc(2024, 3, 10, 19), // PT 03-10 12:00
      lastSentAt: {
        'A': DateTime.utc(2024, 3, 11, 18, 30), // PT 03-11 11:30
        'B': DateTime.utc(2024, 3, 10, 19),
      },
    );
    final now = DateTime.utc(2024, 3, 11, 19); // PT 03-11 12:00

    test('23-hour local day → inDays == 0 → sameDay branch', () {
      final result = legacyEvaluate(
        stored: stored,
        senderId: 'B',
        receiverId: 'A',
        cache: null,
        now: now,
        zone: LegacyDeviceZone.pacific2024,
      );

      expect(result.otherSentToday, isTrue);
      expect(result.todayKey, DateTime.utc(2024, 3, 11));
      expect(result.lastMutualDayKey, DateTime.utc(2024, 3, 10));
      expect(result.daysDiff, 0,
          reason: 'the local day 03-10 was only 23 hours long');
      expect(result.branch, LegacyBranch.sameDay);
      expect(result.streakCountWritten, 5, reason: 'the increment is lost');
    });

    test('the same inputs in a fixed-offset zone do increment', () {
      final result = legacyEvaluate(
        stored: stored,
        senderId: 'B',
        receiverId: 'A',
        cache: null,
        now: now,
        zone: LegacyDeviceZone.fixedMinus8,
      );

      expect(result.daysDiff, 1);
      expect(result.streakCountWritten, 6);
    });

    test('the reference oracle counts both days', () {
      final sends = <ReferenceSend>[
        ReferenceSend('A', DateTime.utc(2024, 3, 10, 18, 30)),
        ReferenceSend('B', DateTime.utc(2024, 3, 10, 19)),
        ReferenceSend('A', DateTime.utc(2024, 3, 11, 18, 30)),
        ReferenceSend('B', DateTime.utc(2024, 3, 11, 19)),
      ];

      final before = referenceStreak(sends.sublist(0, 2),
          DateTime.utc(2024, 3, 11, 10), participants: ['A', 'B']);
      final after =
          referenceStreak(sends, now, participants: ['A', 'B']);

      expect(before.count, 1);
      expect(after.count, 2);
      expect(after.mutualDays, ['2024-03-11', '2024-03-12']);
    });
  });

  group('1.9 — self-chat farms a streak alone', () {
    test('a note-to-self room starts and advances a streak', () {
      final day1 = legacyEvaluate(
        stored: LegacyRoomDoc(),
        senderId: 'A',
        receiverId: 'A',
        cache: null,
        now: atIst(2024, 4, 1, 10),
      );

      expect(day1.otherUserId, 'A', reason: 'the self-alias');
      expect(day1.otherSentToday, isTrue,
          reason: "the sender's own in-memory lastSentAt satisfies 'other'");
      expect(day1.branch, LegacyBranch.firstMutualDay);
      expect(day1.streakCountWritten, 1);

      final day2 = legacyEvaluate(
        stored: LegacyRoomDoc(),
        senderId: 'A',
        receiverId: 'A',
        cache: day1.nextCache,
        now: atIst(2024, 4, 2, 10),
      );

      expect(day2.daysDiff, 1);
      expect(day2.streakCountWritten, 2);
    });

    test('the reference oracle refuses a single-participant room', () {
      final result = referenceStreak(
        [
          ReferenceSend('A', atIst(2024, 4, 1, 10)),
          ReferenceSend('A', atIst(2024, 4, 2, 10)),
        ],
        atIst(2024, 4, 2, 11),
        participants: ['A'],
      );

      expect(result.count, 0);
      expect(result.lastMutualDay, isNull);
    });
  });

  group('1.10 — a reaction refreshes the expiry deadline', () {
    final stored = LegacyRoomDoc(
      streakCount: 6,
      lastInteractionDate: atIst(2024, 5, 1, 9),
      lastSentAt: {
        'A': atIst(2024, 5, 1, 9),
        'B': atIst(2024, 5, 1, 9, 30),
      },
    );

    test('the streak block never looks at the message type', () {
      final reaction = legacyEvaluate(
        stored: stored,
        senderId: 'A',
        receiverId: 'B',
        cache: null,
        now: atIst(2024, 5, 1, 20),
        messageType: 'reaction',
      );
      final text = legacyEvaluate(
        stored: stored,
        senderId: 'A',
        receiverId: 'B',
        cache: null,
        now: atIst(2024, 5, 1, 20),
        messageType: 'text',
      );

      expect(reaction.branch, LegacyBranch.sameDay);
      expect(reaction.wroteLastInteractionDate, isTrue,
          reason: 'a reaction restarts the badge countdown');
      expect(reaction.lastInteractionDateWritten, atIst(2024, 5, 1, 20));
      expect(reaction.streakCountWritten, text.streakCountWritten);
      expect(reaction.lastInteractionDateWritten,
          text.lastInteractionDateWritten,
          reason: 'a reaction is indistinguishable from a real message here');
    });
  });

  group('1.11 — the client clock is the only time source', () {
    test('a clock walked forward one day per send climbs the count with zero '
        'partner activity (with 1.9)', () {
      final counts = <int>[];
      LegacyStreakCacheEntry? cache;

      for (var day = 1; day <= 5; day++) {
        final result = legacyEvaluate(
          stored: LegacyRoomDoc(),
          senderId: 'A',
          receiverId: 'A',
          cache: cache,
          now: atIst(2024, 6, day, 12),
        );
        counts.add(result.streakCountWritten!);
        cache = result.nextCache;
      }

      expect(counts, [1, 2, 3, 4, 5]);
    });

    test('a 24h-fast device stamps a future participation instant and the '
        "partner's genuine mutual day is lost", () {
      final trueInstant = atIst(2024, 3, 4, 9);
      final believedInstant = atIst(2024, 3, 5, 9); // device is 24h fast

      final stored = LegacyRoomDoc(
        streakCount: 4,
        lastInteractionDate: atIst(2024, 3, 3, 10),
        lastSentAt: {
          'A': atIst(2024, 3, 3, 9, 30),
          'B': atIst(2024, 3, 4, 8), // B genuinely sent today
        },
      );

      final skewed = legacyEvaluate(
        stored: stored,
        senderId: 'A',
        receiverId: 'B',
        cache: null,
        now: believedInstant,
      );

      expect(skewed.postCommitLastSentAtUpdate['A'], believedInstant);
      expect(
          skewed.postCommitLastSentAtUpdate['A']!.difference(trueInstant).inHours,
          24,
          reason: 'participation is stamped 24h in the future');
      expect(skewed.otherSentToday, isFalse,
          reason: "B's real send now reads as 'yesterday' to the fast device");

      // The partner, with an accurate clock, evaluates after that write landed.
      final afterSkewedWrite = legacyMergeRoomDoc(
        stored,
        skewed.roomUpdates,
        postCommitLastSentAtUpdate: skewed.postCommitLastSentAtUpdate,
      );
      final partner = legacyEvaluate(
        stored: afterSkewedWrite,
        senderId: 'B',
        receiverId: 'A',
        cache: null,
        now: atIst(2024, 3, 4, 10),
      );

      expect(partner.otherSentToday, isFalse,
          reason: "A's send is stamped 03-05, so it is not 'today'");
      expect(partner.branch, LegacyBranch.waitingForOtherUser);
      expect(partner.streakCountWritten, 4,
          reason: 'a real mutual day produced no increment');

      // The reference, on server time, sees the mutual day.
      final reference = referenceStreak(
        [
          ReferenceSend('A', atIst(2024, 3, 3, 9, 30)),
          ReferenceSend('B', atIst(2024, 3, 3, 10)),
          ReferenceSend('B', atIst(2024, 3, 4, 8)),
          ReferenceSend('A', trueInstant),
        ],
        atIst(2024, 3, 4, 10),
        participants: ['A', 'B'],
      );
      expect(reference.count, 2);
    });
  });

  group('1.13 / 1.17 — nothing evaluates the streak on a read', () {
    test('a five-week-dead bond still displays its stored count', () {
      final anchor = atIst(2024, 3, 11, 12);
      final stored = LegacyRoomDoc(
        streakCount: 7,
        lastInteractionDate: anchor,
        lastSentAt: {'A': atIst(2024, 3, 11, 11), 'B': anchor},
      );
      final serverNow = atIst(2024, 4, 15, 12); // 35 days later

      LegacyStreakReference.resetCallCount();
      final displayed = legacyDisplayStreakCount(stored);
      final rehydrated = legacyCacheRehydrate({
        'streakCount': stored.streakCount,
        'lastInteractionDate': stored.lastInteractionDate,
        'previousStreakCount': 0,
        'streakBrokenAt': null,
      });

      expect(displayed, 7, reason: 'rendered verbatim');
      expect(rehydrated.streakCount, 7,
          reason: 'the local cache rehydrates it verbatim too');
      expect(rehydrated.lastInteractionDate, anchor);
      expect(LegacyStreakReference.evaluateCallCount, 0,
          reason: 'the streak block only ever runs while sending a message');

      final reference =
          referenceStreak(
        [
          ReferenceSend('A', atIst(2024, 3, 11, 11)),
          ReferenceSend('B', anchor),
        ],
        serverNow,
        participants: ['A', 'B'],
      );
      expect(reference.isBroken, isTrue);
      expect(reference.count, 0);
      expect(reference.previousCount, 0,
          reason: 'the restore window closed 34 days ago');
    });

    test('the badge renders `critical` forever — the risk enum has no broken '
        'state', () {
      final fiveWeeksAgo = DateTime.now().subtract(const Duration(days: 35));

      expect(legacyComputeStreakRisk(fiveWeeksAgo),
          LegacyBadgeRiskLevel.critical);
      expect(LegacyBadgeRiskLevel.values.map((e) => e.name),
          ['normal', 'atRisk', 'critical']);
      expect(legacyComputeTimeRemaining(fiveWeeksAgo), Duration.zero);
    });
  });

  group('1.15 — the badge deadline and the break deadline are different rules',
      () {
    /// The legacy break rule: a mutual day D survives through D+1 and breaks at
    /// local midnight of D+2.
    DateTime calendarDeadline(DateTime anchor) {
      final day = DateTime(anchor.year, anchor.month, anchor.day);
      return DateTime(day.year, day.month, day.day + 2);
    }

    test('an anchor late in the day: the badge is ~23h too generous', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final anchor = today
          .subtract(const Duration(days: 1))
          .add(const Duration(hours: 23, minutes: 30));

      final badgeRemaining = legacyComputeTimeRemaining(anchor)!;
      final realRemaining = calendarDeadline(anchor).difference(DateTime.now());
      final disagreement = badgeRemaining - realRemaining;

      expect(disagreement, greaterThan(const Duration(hours: 20)));
      expect(legacyComputeStreakRisk(anchor),
          isNot(LegacyBadgeRiskLevel.critical),
          reason: 'the badge never reaches its own critical state before the '
              'calendar-day rule has already broken the streak');
    });

    test('an anchor early in the day: the two rules nearly agree — the grace '
        'period swings between ~24h and ~48h', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final anchor = today
          .subtract(const Duration(days: 1))
          .add(const Duration(minutes: 30));

      final badgeRemaining = legacyComputeTimeRemaining(anchor)!;
      final realRemaining = calendarDeadline(anchor).difference(DateTime.now());
      final disagreement = badgeRemaining - realRemaining;

      expect(disagreement, lessThan(const Duration(hours: 1)));
      expect(disagreement, greaterThanOrEqualTo(Duration.zero));
    });
  });

  group('1.4 — last-writer-wins: the later write carries the lower count', () {
    test('a stale device overwrites the correct count', () {
      final stored = LegacyRoomDoc(
        streakCount: 4,
        lastInteractionDate: atIst(2024, 3, 3, 10),
        lastSentAt: {
          'A': atIst(2024, 3, 4, 9),
          'B': atIst(2024, 3, 3, 10),
        },
      );

      // B evaluates cold and computes the correct 5.
      final fromB = legacyEvaluate(
        stored: stored,
        senderId: 'B',
        receiverId: 'A',
        cache: null,
        now: atIst(2024, 3, 4, 9, 5),
      );
      expect(fromB.streakCountWritten, 5);

      // A evaluates from its stale cache five minutes later and computes 4.
      final fromA = legacyEvaluate(
        stored: stored,
        senderId: 'A',
        receiverId: 'B',
        cache: LegacyStreakCacheEntry(
          streakCount: 4,
          lastInteraction: atIst(2024, 3, 3, 10),
          lastSentAt: {
            'A': atIst(2024, 3, 4, 9),
            'B': atIst(2024, 3, 3, 10),
          },
          filledAt: atIst(2024, 3, 4, 8, 55),
        ),
        now: atIst(2024, 3, 4, 9, 10),
      );
      expect(fromA.streakCountWritten, 4);

      // Both writes land, B first, with merge semantics and no transaction.
      var room = legacyMergeRoomDoc(stored, fromB.roomUpdates,
          postCommitLastSentAtUpdate: fromB.postCommitLastSentAtUpdate);
      room = legacyMergeRoomDoc(room, fromA.roomUpdates,
          postCommitLastSentAtUpdate: fromA.postCommitLastSentAtUpdate);

      expect(room.streakCount, 4,
          reason: 'the later, lower, stale write wins');
      expect(room.streakCount, lessThan(fromB.streakCountWritten!));
    });
  });

  group('1.7 / 1.8 — participation is not atomic with the message', () {
    final stored = LegacyRoomDoc(
      streakCount: 4,
      lastInteractionDate: atIst(2024, 3, 3, 10),
      lastSentAt: {
        'A': atIst(2024, 3, 3, 9, 30),
        'B': atIst(2024, 3, 3, 10),
      },
    );

    test('the batch payload carries no lastSentAt; a second timestamp does, '
        'fire-and-forget, after the commit (1.7)', () {
      final result = legacyEvaluate(
        stored: stored,
        senderId: 'A',
        receiverId: 'B',
        cache: null,
        now: atIst(2024, 3, 4, 8),
        postCommitNow: atIst(2024, 3, 4, 8, 0, ), // second DateTime.now()
      );

      expect(result.roomUpdates.keys.where((k) => k.contains('lastSentAt')),
          isEmpty,
          reason: 'set(merge:true) cannot write dot-notation nested paths');
      expect(result.postCommitLastSentAtUpdate.keys, ['A']);
    });

    test('the two timestamps are independent reads of the clock (1.7)', () {
      final result = legacyEvaluate(
        stored: stored,
        senderId: 'A',
        receiverId: 'B',
        cache: null,
        now: atIst(2024, 3, 4, 8),
        postCommitNow: atIst(2024, 3, 4, 8, 0).add(const Duration(seconds: 3)),
      );

      expect(result.postCommitLastSentAtUpdate['A'],
          isNot(equals(result.roomUpdates['lastMessageTime'])));
    });

    test('dropping that write loses the send to the streak forever (1.8)', () {
      final sent = legacyEvaluate(
        stored: stored,
        senderId: 'A',
        receiverId: 'B',
        cache: null,
        now: atIst(2024, 3, 4, 8),
      );

      // The batch committed (message delivered) but the follow-up update()
      // never ran: timeout, offline, or the app was killed.
      final roomAfterDroppedWrite =
          legacyMergeRoomDoc(stored, sent.roomUpdates);

      expect(roomAfterDroppedWrite.lastSentAt['A'], atIst(2024, 3, 3, 9, 30),
          reason: "A's 03-04 send left no trace on the room");

      // B replies the same day, cold cache — it cannot see A's send.
      final sameDayReply = legacyEvaluate(
        stored: roomAfterDroppedWrite,
        senderId: 'B',
        receiverId: 'A',
        cache: null,
        now: atIst(2024, 3, 4, 9),
      );
      expect(sameDayReply.otherSentToday, isFalse);
      expect(sameDayReply.streakCountWritten, 4);

      // And a day later the mutual day is unrecoverable.
      final nextDay = legacyEvaluate(
        stored: legacyMergeRoomDoc(roomAfterDroppedWrite,
            sameDayReply.roomUpdates,
            postCommitLastSentAtUpdate:
                sameDayReply.postCommitLastSentAtUpdate),
        senderId: 'B',
        receiverId: 'A',
        cache: null,
        now: atIst(2024, 3, 5, 9),
      );
      expect(nextDay.otherSentToday, isFalse);
      expect(nextDay.streakCountWritten, 4);
    });
  });

  group('1.18 — restore invents a mutual day and trusts the client clock', () {
    final brokenRoom = LegacyRoomDoc(
      streakCount: 0,
      lastInteractionDate: atIst(2024, 3, 4, 10),
      lastSentAt: {
        'A': atIst(2024, 3, 4, 9, 30),
        'B': atIst(2024, 3, 4, 10),
      },
      previousStreakCount: 5,
      streakBrokenAt: atIst(2024, 3, 6, 9),
    );

    test('the restore writes an anchor on a day nobody messaged', () {
      final outcome = legacyRestoreStreak(
        stored: brokenRoom,
        gupPoints: 500,
        cost: legacyRestoreCost(5),
        clientNow: atIst(2024, 3, 6, 20),
      );

      expect(outcome.succeeded, isTrue);
      expect(outcome.roomUpdates['streakCount'], 5);
      expect(outcome.roomUpdates['lastInteractionDate'], atIst(2024, 3, 6, 20));
      expect(outcome.invalidatedCacheOnThisDeviceOnly, isTrue,
          reason: "the partner's static cache is untouched (1.19)");
    });

    test('a genuine mutual day on the restore day is then classified as '
        'same-day — the daysDiff == 0 misclassification (1.2 consequence)', () {
      final outcome = legacyRestoreStreak(
        stored: brokenRoom,
        gupPoints: 500,
        cost: legacyRestoreCost(5),
        clientNow: atIst(2024, 3, 6, 20),
      );
      final restored = legacyMergeRoomDoc(brokenRoom, outcome.roomUpdates);

      final aSends = legacyEvaluate(
        stored: restored,
        senderId: 'A',
        receiverId: 'B',
        cache: null,
        now: atIst(2024, 3, 6, 20, 30),
      );
      final room = legacyMergeRoomDoc(restored, aSends.roomUpdates,
          postCommitLastSentAtUpdate: aSends.postCommitLastSentAtUpdate);
      final bReplies = legacyEvaluate(
        stored: room,
        senderId: 'B',
        receiverId: 'A',
        cache: null,
        now: atIst(2024, 3, 6, 21),
      );

      expect(bReplies.otherSentToday, isTrue);
      expect(bReplies.daysDiff, 0,
          reason: 'the anchor was advanced to 03-06 without a mutual day');
      expect(bReplies.branch, LegacyBranch.sameDay);
      expect(bReplies.streakCountWritten, 5, reason: 'no increment');
    });

    test('one later mutual day then increments as if the chain never broke',
        () {
      final outcome = legacyRestoreStreak(
        stored: brokenRoom,
        gupPoints: 500,
        cost: legacyRestoreCost(5),
        clientNow: atIst(2024, 3, 6, 20),
      );
      var room = legacyMergeRoomDoc(brokenRoom, outcome.roomUpdates);

      final aSends = legacyEvaluate(
        stored: room,
        senderId: 'A',
        receiverId: 'B',
        cache: null,
        now: atIst(2024, 3, 7, 9),
      );
      room = legacyMergeRoomDoc(room, aSends.roomUpdates,
          postCommitLastSentAtUpdate: aSends.postCommitLastSentAtUpdate);
      final bReplies = legacyEvaluate(
        stored: room,
        senderId: 'B',
        receiverId: 'A',
        cache: null,
        now: atIst(2024, 3, 7, 10),
      );
      room = legacyMergeRoomDoc(room, bReplies.roomUpdates,
          postCommitLastSentAtUpdate: bReplies.postCommitLastSentAtUpdate);

      expect(bReplies.daysDiff, 1);
      expect(room.streakCount, 6,
          reason: 'one mutual day since the break, yet the count reads 6');

      final reference = referenceStreak(
        [
          ReferenceSend('A', atIst(2024, 3, 4, 9, 30)),
          ReferenceSend('B', atIst(2024, 3, 4, 10)),
          ReferenceSend('A', atIst(2024, 3, 7, 9)),
          ReferenceSend('B', atIst(2024, 3, 7, 10)),
        ],
        atIst(2024, 3, 7, 10),
        participants: ['A', 'B'],
      );
      expect(reference.count, 1,
          reason: '03-07 is a fresh single mutual day');
    });

    test('the restore window is validated against the client clock', () {
      // Real time is two days past the break; the device believes otherwise.
      final outcome = legacyRestoreStreak(
        stored: brokenRoom,
        gupPoints: 500,
        cost: legacyRestoreCost(5),
        clientNow: atIst(2024, 3, 6, 19), // believed: 10h after the break
      );
      expect(outcome.succeeded, isTrue,
          reason: 'an expired window is accepted on a rolled-back clock');

      final honest = legacyRestoreStreak(
        stored: brokenRoom,
        gupPoints: 500,
        cost: legacyRestoreCost(5),
        clientNow: atIst(2024, 3, 8, 9), // the real instant
      );
      expect(honest.succeeded, isFalse);
    });
  });

  group('1.20 — the Pro free-restore allowance lives in SharedPreferences', () {
    test('recordStreakRestore reads back what it just wrote, so the weekly '
        'reset branch is dead code and the counter only grows', () {
      final prefs = <String, int>{};
      final week1 = DateTime.utc(2024, 3, 4, 12); // Monday
      final week4 = DateTime.utc(2024, 3, 25, 12); // three weeks later

      final first = legacyRecordStreakRestore(prefs: prefs, now: week1);
      expect(first.lastWeek, first.currentWeek);
      expect(first.count, 1);

      final second = legacyRecordStreakRestore(
          prefs: prefs, now: week1.add(const Duration(hours: 2)));
      expect(second.lastWeek, second.currentWeek);
      expect(second.count, 2);

      final later = legacyRecordStreakRestore(prefs: prefs, now: week4);
      expect(later.lastWeek, later.currentWeek,
          reason: 'still equal three weeks later — the comparison is with '
              'the value written one line earlier');
      expect(later.count, 3, reason: 'never reset to 1');
    });

    test('clearing app data hands the perk back immediately', () {
      final prefs = <String, int>{};
      final now = DateTime.utc(2024, 3, 4, 12);

      expect(legacyCanRestoreStreakFree(isPro: true, prefs: prefs, now: now),
          isTrue);
      legacyRecordStreakRestore(prefs: prefs, now: now);
      expect(legacyCanRestoreStreakFree(isPro: true, prefs: prefs, now: now),
          isFalse);

      prefs.clear(); // reinstall / clear storage
      expect(legacyCanRestoreStreakFree(isPro: true, prefs: prefs, now: now),
          isTrue, reason: 'the allowance is device-local, not server state');
    });

    test('REFUTED: the perk is not permanently consumed — the week comparison '
        'precedes the counter check', () {
      final prefs = <String, int>{};
      final week1 = DateTime.utc(2024, 3, 4, 12);

      legacyRecordStreakRestore(prefs: prefs, now: week1);
      legacyRecordStreakRestore(
          prefs: prefs, now: week1.add(const Duration(hours: 1)));
      expect(prefs[kStreakRestoreCount], 2);

      // A real new week: `currentWeek != lastWeek` short-circuits to true
      // before `restoreCount < 1` is ever consulted.
      expect(
        legacyCanRestoreStreakFree(
            isPro: true, prefs: prefs, now: week1.add(const Duration(days: 7))),
        isTrue,
      );
    });
  });

  group('1.21 / 1.22 — milestones and longestStreak', () {
    final stored = LegacyRoomDoc(
      streakCount: 6,
      lastInteractionDate: atIst(2024, 7, 6, 10),
      lastSentAt: {
        'A': atIst(2024, 7, 7, 9),
        'B': atIst(2024, 7, 6, 10),
      },
    );

    test('only the sender is ever awarded', () {
      final result = legacyEvaluate(
        stored: stored,
        senderId: 'B',
        receiverId: 'A',
        cache: null,
        now: atIst(2024, 7, 7, 10),
      );

      expect(result.streakCountWritten, 7);
      expect(result.milestoneCall, isNotNull);
      expect(result.milestoneCall!.userId, 'B');
      expect(result.milestoneCall!.newStreak, 7);
      expect(result.milestoneCall!.userId, isNot('A'),
          reason: 'the partner is never rewarded');
    });

    test('there is no idempotency key — the same threshold can be awarded '
        'twice', () {
      final first = legacyEvaluate(
        stored: stored,
        senderId: 'B',
        receiverId: 'A',
        cache: null,
        now: atIst(2024, 7, 7, 10),
      );
      // A stale device clobbers the count back to 6 (see 1.4), so the very
      // same evaluation runs again and awards the same threshold a second
      // time — there is no award record to consult.
      final second = legacyEvaluate(
        stored: stored,
        senderId: 'B',
        receiverId: 'A',
        cache: null,
        now: atIst(2024, 7, 7, 10, 5),
      );

      expect(first.milestoneCall!.newStreak, 7);
      expect(second.milestoneCall, isNotNull);
      expect(second.milestoneCall!.newStreak, 7);
    });

    test('a threshold that is jumped is lost permanently', () {
      // A restore writes the count directly, with no milestone path at all.
      final broken = LegacyRoomDoc(
        streakCount: 0,
        lastInteractionDate: atIst(2024, 7, 4, 10),
        lastSentAt: {
          'A': atIst(2024, 7, 4, 9),
          'B': atIst(2024, 7, 4, 10),
        },
        previousStreakCount: 12,
        streakBrokenAt: atIst(2024, 7, 6, 9),
      );
      final restore = legacyRestoreStreak(
        stored: broken,
        gupPoints: 500,
        cost: legacyRestoreCost(12),
        clientNow: atIst(2024, 7, 6, 20),
      );
      expect(restore.roomUpdates['streakCount'], 12);

      var room = legacyMergeRoomDoc(broken, restore.roomUpdates);
      final aSends = legacyEvaluate(
        stored: room,
        senderId: 'A',
        receiverId: 'B',
        cache: null,
        now: atIst(2024, 7, 7, 9),
      );
      room = legacyMergeRoomDoc(room, aSends.roomUpdates,
          postCommitLastSentAtUpdate: aSends.postCommitLastSentAtUpdate);
      final bReplies = legacyEvaluate(
        stored: room,
        senderId: 'B',
        receiverId: 'A',
        cache: null,
        now: atIst(2024, 7, 7, 10),
      );

      expect(bReplies.streakCountWritten, 13);
      expect(bReplies.milestoneCall, isNull,
          reason: '13 matches no threshold exactly, and nothing catches up');

      expect(
          legacyMilestoneUpdates(
              newStreak: 8, longestStreak: 0, gupPoints: 0, badges: const []),
          isNot(contains('gupPoints')),
          reason: 'a non-threshold value awards no points');
      expect(
          legacyMilestoneUpdates(
              newStreak: 7, longestStreak: 0, gupPoints: 0, badges: const []),
          contains('gupPoints'));
    });

    test('longestStreak can only ever be 0, 7, 30 or 100 (1.22)', () {
      // The only writer of longestStreak is handleStreakMilestone, and it only
      // runs on an exact threshold. A room sitting at 13 never touches it.
      final atThirteen = legacyEvaluate(
        stored: LegacyRoomDoc(
          streakCount: 12,
          lastInteractionDate: atIst(2024, 7, 6, 10),
          lastSentAt: {
            'A': atIst(2024, 7, 7, 9),
            'B': atIst(2024, 7, 6, 10),
          },
        ),
        senderId: 'B',
        receiverId: 'A',
        cache: null,
        now: atIst(2024, 7, 7, 10),
      );

      expect(atThirteen.streakCountWritten, 13);
      expect(atThirteen.milestoneCall, isNull);

      // Therefore the only values longestStreak can ever hold:
      final reachable = <int>{0};
      for (final streak in List<int>.generate(120, (i) => i + 1)) {
        final updates = legacyMilestoneUpdates(
            newStreak: streak, longestStreak: 0, gupPoints: 0, badges: const []);
        if (updates.containsKey('gupPoints')) {
          reachable.add(updates['longestStreak'] as int);
        }
      }
      expect(reachable, {0, 7, 30, 100});
    });
  });

  group('PROPERTY — legacyEvaluate disagrees with referenceStreak under the '
      'bug condition (stale device cache)', () {
    Glados2<int, int>(
      any.intInRange(2, 31), // number of consecutive mutual days
      any.intInRange(0, 1380), // minute of the canonical day for A's send
    ).test('a device on a warm cache reports 0 while the history holds n '
        'mutual days', (days, minuteOfDay) {
      const startDay = 1; // 2024-05-01 .. 2024-05-30
      final sends = <ReferenceSend>[];
      final aSendInstants = <DateTime>[];

      for (var i = 0; i < days; i++) {
        final aSend = atIst(2024, 5, startDay + i)
            .add(Duration(minutes: minuteOfDay));
        final bSend = aSend.add(const Duration(minutes: 5));
        aSendInstants.add(aSend);
        sends
          ..add(ReferenceSend('A', aSend))
          ..add(ReferenceSend('B', bSend));
      }

      final serverNow = sends.last.instant.add(const Duration(minutes: 1));

      // The room as the server sees it, kept faithfully up to date.
      var room = LegacyRoomDoc(streakCount: 0, lastSentAt: {});

      // A's device: cache filled before the history began, and only ever
      // updated by A's own sends — the bug condition `usesStaleDeviceCache`.
      LegacyStreakCacheEntry? cache = LegacyStreakCacheEntry(
        streakCount: 0,
        lastInteraction: null,
        lastSentAt: const {},
        filledAt: atIst(2024, 4, 30, 23),
      );

      int lastWritten = 0;
      for (final instant in aSendInstants) {
        final result = legacyEvaluate(
          stored: room,
          senderId: 'A',
          receiverId: 'B',
          cache: cache,
          now: instant,
        );
        cache = result.nextCache;
        lastWritten = result.streakCountWritten!;
        room = legacyMergeRoomDoc(room, result.roomUpdates,
            postCommitLastSentAtUpdate: result.postCommitLastSentAtUpdate);
      }

      final reference =
          referenceStreak(sends, serverNow, participants: ['A', 'B']);

      expect(reference.count, days);
      expect(lastWritten, 0);
      expect(lastWritten, isNot(equals(reference.count)));
    });
  });
}
