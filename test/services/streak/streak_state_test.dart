// Unit tests for the authoritative streak state document model.
//
// Validates: Requirements 2.26 (one canonical state document with a versioned
// schema that both engines and the cache agree on) and 2.19 (a cached or
// legacy-shaped streak is read through the same model, so nothing renders from
// a shape the engine cannot evaluate).
//
// Canonical zone: Asia/Kolkata, fixed UTC+05:30. Canonical midnight is
// 18:30 UTC of the previous calendar date.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/services/streak/streak_day.dart';
import 'package:video_chat_app/services/streak/streak_state.dart';

/// Stand-in for `cloud_firestore`'s `Timestamp`: the state model duck-types
/// `toDate()`, which is how it stays free of the Firebase import.
class FakeTimestamp {
  const FakeTimestamp(this.millis);

  final int millis;

  DateTime toDate() =>
      DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
}

/// Stand-in for a transport that only exposes epoch millis.
class FakeMillisInstant {
  const FakeMillisInstant(this.millisecondsSinceEpoch);

  final int millisecondsSinceEpoch;
}

const String uidA = 'alice';
const String uidB = 'bob';

/// 2024-03-05 18:30 UTC == the start of canonical day 2024-03-06.
final DateTime marchSixStart = const StreakDay(2024, 3, 6).startUtc();

Map<String, dynamic> fullStateDoc() => <String, dynamic>{
      'schemaVersion': 2,
      'engineVersion': 1,
      'rev': 7,
      'dayZone': 'Asia/Kolkata',
      'dayZoneOffsetMinutes': 330,
      'participants': <String>[uidB, uidA], // deliberately unsorted
      'count': 4,
      'lastMutualDay': '2024-03-05',
      'bridgedThroughDay': '2024-03-02',
      'deadlineAt': FakeTimestamp(marchSixStart.millisecondsSinceEpoch),
      'riskLevel': 'atRisk',
      'sendDays': <String, dynamic>{uidA: '2024-03-05', uidB: '2024-03-05'},
      'sendInstants': <String, dynamic>{
        uidA: FakeTimestamp(
            DateTime.utc(2024, 3, 5, 13).millisecondsSinceEpoch),
        uidB: DateTime.utc(2024, 3, 5, 14),
      },
      'previousCount': 3,
      'brokenAt': null,
      'restoreDeadlineAt': null,
      'restoredAt': DateTime.utc(2024, 3, 2, 9, 30),
      'restoredBy': uidA,
      'restoreCostPaid': 25,
      'milestonesAwarded': <dynamic>[30, 7], // deliberately unsorted
      'longestForRoom': 12,
      'recentApplied': <String, dynamic>{
        '$uidA#2024-03-05': DateTime.utc(2024, 3, 5, 13),
      },
      'notifiedAt': <String, dynamic>{
        'atRisk': DateTime.utc(2024, 3, 6, 2),
        'milestone_7': DateTime.utc(2024, 2, 20),
      },
      'lastEvaluatedAt': DateTime.utc(2024, 3, 6, 3),
      'lastEvaluatedBy': 'sweep',
      'repairedAt': DateTime.utc(2024, 2, 1),
      'repairSource': 'history',
      'repairPreviousLegacyCount': 9,
    };

void main() {
  group('fromStateDoc', () {
    test('hydrates every field of a complete document', () {
      final state = StreakState.fromStateDoc(fullStateDoc())!;

      expect(state.schemaVersion, 2);
      expect(state.engineVersion, 1);
      expect(state.rev, 7);
      expect(state.dayZone, kCanonicalDayZone);
      expect(state.dayZoneOffsetMinutes, kCanonicalDayOffsetMinutes);
      expect(state.participants, <String>[uidA, uidB]); // sorted
      expect(state.count, 4);
      expect(state.lastMutualDay, const StreakDay(2024, 3, 5));
      expect(state.bridgedThroughDay, const StreakDay(2024, 3, 2));
      expect(state.deadlineAt, marchSixStart);
      expect(state.riskLevel, StreakRiskLevel.atRisk);
      expect(state.sendDays[uidA], const StreakDay(2024, 3, 5));
      expect(state.sendDays[uidB], const StreakDay(2024, 3, 5));
      expect(state.sendInstants[uidA], DateTime.utc(2024, 3, 5, 13));
      expect(state.sendInstants[uidB], DateTime.utc(2024, 3, 5, 14));
      expect(state.previousCount, 3);
      expect(state.brokenAt, isNull);
      expect(state.restoreDeadlineAt, isNull);
      expect(state.restoredAt, DateTime.utc(2024, 3, 2, 9, 30));
      expect(state.restoredBy, uidA);
      expect(state.restoreCostPaid, 25);
      expect(state.milestonesAwarded, <int>[7, 30]); // sorted
      expect(state.longestForRoom, 12);
      expect(state.recentApplied['$uidA#2024-03-05'],
          DateTime.utc(2024, 3, 5, 13));
      expect(state.notifiedAt['atRisk'], DateTime.utc(2024, 3, 6, 2));
      expect(state.notifiedAt['milestone_7'], DateTime.utc(2024, 2, 20));
      expect(state.lastEvaluatedAt, DateTime.utc(2024, 3, 6, 3));
      expect(state.lastEvaluatedBy, StreakEvaluationSource.sweep);
      expect(state.repairedAt, DateTime.utc(2024, 2, 1));
      expect(state.repairSource, 'history');
      expect(state.repairPreviousLegacyCount, 9);
      expect(state.isLegacyProjection, isFalse);
    });

    test('continuityHorizon is the later of the anchor and the bridged day',
        () {
      final state = StreakState.fromStateDoc(fullStateDoc())!;
      expect(state.continuityHorizon, const StreakDay(2024, 3, 5));

      final bridgedLater = StreakState.fromStateDoc(<String, dynamic>{
        ...fullStateDoc(),
        'lastMutualDay': '2024-03-01',
        'bridgedThroughDay': '2024-03-04',
      })!;
      expect(bridgedLater.continuityHorizon, const StreakDay(2024, 3, 4));
    });

    test('a minimal document defaults every optional field', () {
      final state = StreakState.fromStateDoc(<String, dynamic>{
        'schemaVersion': 2,
        'participants': <String>[uidA, uidB],
      })!;

      expect(state.engineVersion, 0);
      expect(state.rev, 0);
      expect(state.count, 0);
      expect(state.lastMutualDay, isNull);
      expect(state.bridgedThroughDay, isNull);
      expect(state.deadlineAt, isNull);
      expect(state.riskLevel, StreakRiskLevel.normal);
      expect(state.sendDays, isEmpty);
      expect(state.sendInstants, isEmpty);
      expect(state.previousCount, 0);
      expect(state.brokenAt, isNull);
      expect(state.milestonesAwarded, isEmpty);
      expect(state.longestForRoom, 0);
      expect(state.recentApplied, isEmpty);
      expect(state.notifiedAt, isEmpty);
      expect(state.lastEvaluatedBy, isNull);
      expect(state.dayZoneOffsetMinutes, kCanonicalDayOffsetMinutes);
    });

    test('explicit nulls and malformed values are dropped, not thrown on', () {
      final state = StreakState.fromStateDoc(<String, dynamic>{
        'schemaVersion': 2,
        'participants': <dynamic>[uidA, 42, null, uidB],
        'count': null,
        'lastMutualDay': 'not-a-day',
        'bridgedThroughDay': '2024-02-30', // not a real date
        'deadlineAt': 'garbage',
        'riskLevel': 'wildlyNewLevel',
        'sendDays': <String, dynamic>{uidA: '2024-03-05', uidB: 'nope'},
        'sendInstants': <String, dynamic>{uidA: 'nope'},
        'milestonesAwarded': <dynamic>['7', 'x', 30],
        'recentApplied': 'not a map',
        'notifiedAt': null,
      })!;

      expect(state.participants, <String>[uidA, uidB]);
      expect(state.count, 0);
      expect(state.lastMutualDay, isNull);
      expect(state.bridgedThroughDay, isNull);
      expect(state.deadlineAt, isNull);
      expect(state.riskLevel, StreakRiskLevel.normal);
      expect(state.sendDays.keys, <String>[uidA]);
      expect(state.sendInstants, isEmpty);
      expect(state.milestonesAwarded, <int>[7, 30]);
      expect(state.recentApplied, isEmpty);
      expect(state.notifiedAt, isEmpty);
    });

    test('participantsFallback fills in a document missing the array', () {
      final state = StreakState.fromStateDoc(
        <String, dynamic>{'schemaVersion': 2, 'count': 3},
        participantsFallback: <String>[uidB, uidA],
      )!;
      expect(state.participants, <String>[uidA, uidB]);
    });

    test('receivedAt is carried and normalised to UTC', () {
      final received = DateTime.utc(2024, 3, 6, 4);
      final state = StreakState.fromStateDoc(
        fullStateDoc(),
        receivedAt: received,
      )!;
      expect(state.receivedAt, received);
      expect(state.receivedAt!.isUtc, isTrue);
      expect(state.observedAt, received);
    });

    test('normalises every timestamp transport to the same UTC instant', () {
      final instant = DateTime.utc(2024, 3, 5, 13, 45, 6);
      final millis = instant.millisecondsSinceEpoch;

      expect(streakInstantFrom(instant), instant);
      expect(streakInstantFrom(millis), instant);
      expect(streakInstantFrom(instant.toIso8601String()), instant);
      expect(streakInstantFrom(FakeTimestamp(millis)), instant);
      expect(streakInstantFrom(FakeMillisInstant(millis)), instant);
      expect(
        streakInstantFrom(<String, dynamic>{
          '_seconds': millis ~/ 1000,
          '_nanoseconds': (millis % 1000) * 1000000,
        }),
        instant,
      );
      expect(streakInstantFrom(null), isNull);
      expect(streakInstantFrom(<String, dynamic>{'nope': 1}), isNull);
      expect(streakInstantFrom(const Object()), isNull);
    });
  });

  group('schemaVersion gating', () {
    test('fromStateDoc rejects null, empty and pre-v2 documents', () {
      expect(StreakState.fromStateDoc(null), isNull);
      expect(StreakState.fromStateDoc(<String, dynamic>{}), isNull);
      expect(
        StreakState.fromStateDoc(<String, dynamic>{'count': 5}),
        isNull,
        reason: 'no schemaVersion means "not the v2 document"',
      );
      expect(
        StreakState.fromStateDoc(
            <String, dynamic>{'schemaVersion': 1, 'count': 5}),
        isNull,
        reason: 'v1 must fall through to the legacy projection',
      );
    });

    test('fromStateDoc accepts a future schemaVersion and keeps its fields',
        () {
      final state = StreakState.fromStateDoc(<String, dynamic>{
        ...fullStateDoc(),
        'schemaVersion': 3,
        'someFutureField': 'keep me',
      })!;

      expect(state.schemaVersion, 3);
      expect(state.count, 4);
      expect(state.extraFields['someFutureField'], 'keep me');
    });

    test('fromCacheJson rejects a block with no usable schemaVersion', () {
      expect(StreakState.fromCacheJson(null), isNull);
      expect(StreakState.fromCacheJson(<String, dynamic>{}), isNull);
      expect(
        StreakState.fromCacheJson(<String, dynamic>{'count': 5}),
        isNull,
      );
    });

    test('fromCacheJson accepts a cached legacy projection', () {
      final legacy = StreakState.fromLegacy(
        participants: <String>[uidA, uidB],
        streakCount: 3,
        lastInteractionDate: DateTime.utc(2024, 3, 5, 13),
      );
      final restored = StreakState.fromCacheJson(
        legacy.toCacheJson(cachedAt: DateTime.utc(2024, 3, 5, 14)),
      )!;

      expect(restored.schemaVersion, kStreakLegacySchemaVersion);
      expect(restored.isLegacyProjection, isTrue);
      expect(restored.count, 3);
    });
  });

  group('unknown-field tolerance', () {
    test('unknown fields survive a document round trip through toMap', () {
      final doc = <String, dynamic>{
        ...fullStateDoc(),
        'futureFlag': true,
        'futureBlock': <String, dynamic>{'a': 1},
      };

      final state = StreakState.fromStateDoc(doc)!;
      expect(state.extraFields, <String, dynamic>{
        'futureFlag': true,
        'futureBlock': <String, dynamic>{'a': 1},
      });

      final persisted = state.toMap();
      expect(persisted['futureFlag'], isTrue);
      expect(persisted['futureBlock'], <String, dynamic>{'a': 1});

      final reread = StreakState.fromStateDoc(persisted)!;
      expect(reread.sameDocumentAs(state), isTrue);
    });

    test('a known field always wins over a same-named extra', () {
      final state = StreakState.fromStateDoc(fullStateDoc())!
          .copyWith(extraFields: <String, dynamic>{'count': 999});
      expect(state.toMap()['count'], 4);
    });

    test('toMap round-trips the full document', () {
      final state = StreakState.fromStateDoc(fullStateDoc())!;
      final reread = StreakState.fromStateDoc(state.toMap())!;

      expect(reread.sameDocumentAs(state), isTrue);
      expect(reread.toMap()['lastMutualDay'], '2024-03-05');
      expect(reread.toMap()['riskLevel'], 'atRisk');
      expect(reread.toMap()['deadlineAt'], marchSixStart);
    });
  });

  group('fromLegacy', () {
    test('projects the legacy room fields onto a v1-tagged state', () {
      final interaction = DateTime.utc(2024, 3, 5, 13); // 18:30 IST Mar 5
      final state = StreakState.fromLegacy(
        participants: <String>[uidB, uidA],
        streakCount: 4,
        lastInteractionDate: FakeTimestamp(interaction.millisecondsSinceEpoch),
        lastSentAt: <String, dynamic>{
          uidA: FakeTimestamp(interaction.millisecondsSinceEpoch),
          uidB: DateTime.utc(2024, 3, 5, 12),
        },
        previousStreakCount: 2,
      );

      expect(state.schemaVersion, kStreakLegacySchemaVersion);
      expect(state.isLegacyProjection, isTrue);
      expect(state.participants, <String>[uidA, uidB]);
      expect(state.count, 4);
      expect(state.lastMutualDay, const StreakDay(2024, 3, 5));
      expect(state.deadlineAt, const StreakDay(2024, 3, 7).startUtc());
      expect(state.sendDays[uidA], const StreakDay(2024, 3, 5));
      expect(state.sendDays[uidB], const StreakDay(2024, 3, 5));
      expect(state.sendInstants[uidB], DateTime.utc(2024, 3, 5, 12));
      expect(state.previousCount, 2);
      expect(state.brokenAt, isNull);
      expect(state.restoreDeadlineAt, isNull);
      expect(state.bridgedThroughDay, isNull);
      expect(state.milestonesAwarded, isEmpty);
      expect(state.longestForRoom, 4);
      expect(state.rev, 0);
    });

    test('a broken legacy streak gets a 24-hour restore window', () {
      final broken = DateTime.utc(2024, 3, 6, 18, 30);
      final state = StreakState.fromLegacy(
        participants: <String>[uidA, uidB],
        streakCount: 0,
        previousStreakCount: 9,
        streakBrokenAt: broken,
      );

      expect(state.count, 0);
      expect(state.previousCount, 9);
      expect(state.brokenAt, broken);
      expect(state.restoreDeadlineAt, broken.add(const Duration(hours: 24)));
      expect(state.riskLevel, StreakRiskLevel.broken);
      expect(state.isRestorable(broken.add(const Duration(hours: 23))), isTrue);
      expect(state.isRestorable(broken.add(const Duration(hours: 25))), isFalse);
    });

    test('a zero count claims no anchor and no deadline', () {
      final state = StreakState.fromLegacy(
        participants: <String>[uidA, uidB],
        streakCount: 0,
        lastInteractionDate: DateTime.utc(2024, 3, 5, 13),
      );

      expect(state.lastMutualDay, isNull);
      expect(state.deadlineAt, isNull);
      expect(state.longestForRoom, 0);
    });

    test('a positive count with no interaction date invents no anchor', () {
      final state = StreakState.fromLegacy(
        participants: <String>[uidA, uidB],
        streakCount: 6,
      );

      expect(state.count, 6);
      expect(state.lastMutualDay, isNull);
      expect(state.deadlineAt, isNull);
      expect(state.continuityHorizon, isNull);
    });

    test('the anchor uses the canonical zone, not the raw UTC date', () {
      // 2024-03-05 19:00 UTC == 2024-03-06 00:30 IST → canonical day Mar 6.
      final state = StreakState.fromLegacy(
        participants: <String>[uidA, uidB],
        streakCount: 1,
        lastInteractionDate: DateTime.utc(2024, 3, 5, 19),
      );
      expect(state.lastMutualDay, const StreakDay(2024, 3, 6));
    });

    test('fromLegacyRoomMap reads a ChatRoom-shaped map', () {
      final room = <String, dynamic>{
        'id': 'room1',
        'participants': <String>[uidB, uidA],
        'lastMessage': 'hey',
        'streakCount': 3,
        'lastInteractionDate': DateTime.utc(2024, 3, 5, 13),
        'lastSentAt': <String, dynamic>{
          uidA: DateTime.utc(2024, 3, 5, 13),
          uidB: DateTime.utc(2024, 3, 5, 10),
        },
        'previousStreakCount': 0,
        'streakBrokenAt': null,
      };

      final state = StreakState.fromLegacyRoomMap(room);

      expect(state.participants, <String>[uidA, uidB]);
      expect(state.count, 3);
      expect(state.lastMutualDay, const StreakDay(2024, 3, 5));
      expect(state.sendDays.length, 2);
      expect(state.isLegacyProjection, isTrue);
    });

    test('fromLegacyRoomMap tolerates a completely empty room', () {
      final state = StreakState.fromLegacyRoomMap(null);
      expect(state.count, 0);
      expect(state.participants, isEmpty);
      expect(state.lastMutualDay, isNull);
    });
  });

  group('cache round trip', () {
    test('survives jsonEncode/jsonDecode with every field intact', () {
      final state = StreakState.fromStateDoc(<String, dynamic>{
        ...fullStateDoc(),
        'brokenAt': DateTime.utc(2024, 3, 7, 18, 30),
        'restoreDeadlineAt': DateTime.utc(2024, 3, 8, 18, 30),
        'futureFlag': 'keep',
      })!;

      final cachedAt = DateTime.utc(2024, 3, 6, 5);
      final encoded = jsonEncode(state.toCacheJson(cachedAt: cachedAt));
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final restored = StreakState.fromCacheJson(decoded)!;

      expect(restored.sameDocumentAs(state), isTrue);
      expect(restored.cachedAt, cachedAt);
      expect(restored.extraFields['futureFlag'], 'keep');
    });

    test('cachedAt falls back to the stream receivedAt when not supplied', () {
      final received = DateTime.utc(2024, 3, 6, 4);
      final state = StreakState.fromStateDoc(
        fullStateDoc(),
        receivedAt: received,
      )!;

      final restored =
          StreakState.fromCacheJson(state.toCacheJson())!;
      expect(restored.cachedAt, received);
      expect(restored.observedAt, received);
    });

    test('freshness is measured from receivedAt, then cachedAt', () {
      final received = DateTime.utc(2024, 3, 6, 4);
      final streamed = StreakState.fromStateDoc(
        fullStateDoc(),
        receivedAt: received,
      )!;

      expect(streamed.isStaleAt(received.add(const Duration(minutes: 14))),
          isFalse);
      expect(streamed.isStaleAt(received.add(const Duration(minutes: 16))),
          isTrue);
      expect(
        streamed.isStaleAt(received.add(const Duration(minutes: 16)),
            window: const Duration(hours: 1)),
        isFalse,
      );

      final cached = StreakState.fromCacheJson(
        streamed.toCacheJson(cachedAt: received),
      )!;
      expect(cached.isStaleAt(received.add(const Duration(minutes: 16))),
          isTrue);

      // Never observed: treated as stale, because nothing vouches for it.
      expect(
        StreakState.empty(participants: <String>[uidA, uidB])
            .isStaleAt(received),
        isTrue,
      );
      expect(kStreakFreshnessWindow, const Duration(minutes: 15));
    });

    test('withReceivedAt stamps the stream path without touching the document',
        () {
      final state = StreakState.fromStateDoc(fullStateDoc())!;
      final stamped = state.withReceivedAt(DateTime.utc(2024, 3, 6, 4));

      expect(stamped.receivedAt, DateTime.utc(2024, 3, 6, 4));
      expect(stamped.sameDocumentAs(state), isTrue);
      expect(stamped == state, isFalse);
    });
  });

  group('enum serialization stability', () {
    test('StreakRiskLevel wire values are pinned', () {
      expect(
        StreakRiskLevel.values.map((level) => level.wire).toList(),
        <String>['normal', 'atRisk', 'critical', 'broken'],
      );
      for (final level in StreakRiskLevel.values) {
        expect(StreakRiskLevel.tryParse(level.wire), level);
      }
      expect(StreakRiskLevel.tryParse('nope'), isNull);
      expect(StreakRiskLevel.tryParse(null), isNull);
      expect(StreakRiskLevel.parse('nope'), StreakRiskLevel.normal);
      expect(
        StreakRiskLevel.parse(null, fallback: StreakRiskLevel.broken),
        StreakRiskLevel.broken,
      );
    });

    test('StreakTransition wire values are pinned', () {
      expect(
        StreakTransition.values.map((t) => t.wire).toList(),
        <String>[
          'participationRecorded',
          'started',
          'incremented',
          'sameDay',
          'broken',
          'restoreWindowExpired',
          'milestoneCrossed',
          'longestRaised',
          'noop',
        ],
      );
      for (final transition in StreakTransition.values) {
        expect(StreakTransition.tryParse(transition.wire), transition);
      }
      expect(StreakTransition.tryParse('somethingElse'), isNull);
    });

    test('evaluation sources are pinned', () {
      expect(StreakEvaluationSource.send, 'send');
      expect(StreakEvaluationSource.sweep, 'sweep');
      expect(StreakEvaluationSource.restore, 'restore');
      expect(StreakEvaluationSource.repair, 'repair');
      expect(StreakEvaluationSource.nudge, 'nudge');
    });

    test('schema constants are pinned', () {
      expect(kStreakSchemaVersion, 2);
      expect(kStreakMinStateSchemaVersion, 2);
      expect(kStreakLegacySchemaVersion, 1);
      expect(kStreakRestoreWindow, const Duration(hours: 24));
    });
  });

  group('copyWith', () {
    test('leaves untouched fields alone', () {
      final state = StreakState.fromStateDoc(fullStateDoc())!;
      final next = state.copyWith(count: 5);

      expect(next.count, 5);
      expect(next.lastMutualDay, state.lastMutualDay);
      expect(next.bridgedThroughDay, state.bridgedThroughDay);
      expect(next.deadlineAt, state.deadlineAt);
      expect(next.restoredBy, state.restoredBy);
      expect(next.restoreCostPaid, state.restoreCostPaid);
      expect(next.repairSource, state.repairSource);
    });

    test('can clear a nullable field explicitly', () {
      final state = StreakState.fromStateDoc(fullStateDoc())!;
      final cleared = state.copyWith(
        bridgedThroughDay: null,
        deadlineAt: null,
        restoredBy: null,
        restoreCostPaid: null,
        repairSource: null,
        receivedAt: null,
      );

      expect(cleared.bridgedThroughDay, isNull);
      expect(cleared.deadlineAt, isNull);
      expect(cleared.restoredBy, isNull);
      expect(cleared.restoreCostPaid, isNull);
      expect(cleared.repairSource, isNull);
      expect(cleared.receivedAt, isNull);
      expect(cleared.count, state.count);
    });

    test('an unchanged copy is equal to its source', () {
      final state = StreakState.fromStateDoc(fullStateDoc())!;
      expect(state.copyWith(), state);
      expect(state.copyWith().hashCode, state.hashCode);
      expect(state.copyWith(rev: state.rev + 1) == state, isFalse);
    });
  });
}
