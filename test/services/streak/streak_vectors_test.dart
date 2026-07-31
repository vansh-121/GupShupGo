// The shared golden fixture, executed as a table test against `StreakEngine`.
//
// Validates: Requirements 2.26.
//
// `test/fixtures/streak_vectors.json` is the streak specification in data form.
// This file is one of exactly two consumers; the other is
// `functions/test/engine.test.js`, which runs the identical table against the
// JavaScript port. That is the whole point: the two engines are two
// implementations of one specification, and the only thing keeping them
// honest is that a semantic change has to regenerate the fixture, which then
// fails the other language's suite until the port catches up.
//
// So: do not "fix" a vector to make this suite green. Either the engine
// regressed, or the semantics changed on purpose — in which case the fixture,
// `lib/services/streak/streak_engine.dart` and `functions/streak/engine.js` all
// move in the same commit.
//
// Nothing here touches Firebase, the clock or the device zone. `stored` is
// hydrated through the ordinary `StreakState.fromStateDoc` reader, so the
// fixture also exercises the transport parsing the server document goes
// through.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/services/gamification_service.dart';
import 'package:video_chat_app/services/streak/streak_day.dart';
import 'package:video_chat_app/services/streak/streak_engine.dart';
import 'package:video_chat_app/services/streak/streak_state.dart';

/// Relative to the package root, which is `flutter test`'s working directory.
const String kFixturePath = 'test/fixtures/streak_vectors.json';

Map<String, dynamic> _loadFixture() {
  final file = File(kFixturePath);
  if (!file.existsSync()) {
    throw StateError(
      'Missing $kFixturePath. The golden fixture is the shared specification; '
      'it cannot be regenerated from this suite.',
    );
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

DateTime _instant(Object? value) => DateTime.parse(value as String).toUtc();

DateTime? _nullableInstant(Object? value) =>
    value == null ? null : _instant(value);

Map<String, dynamic> _map(Object? value) =>
    (value as Map).cast<String, dynamic>();

List<String> _strings(Object? value) =>
    (value as List).map((entry) => entry as String).toList();

List<int> _ints(Object? value) =>
    (value as List).map((entry) => entry as int).toList();

/// `{uid: 'YYYY-MM-DD'}` from a `Map<String, StreakDay>`.
Map<String, String> _dayKeys(Map<String, StreakDay> days) =>
    days.map((uid, day) => MapEntry(uid, day.key));

void main() {
  final fixture = _loadFixture();
  final vectors = (fixture['vectors'] as List).map(_map).toList();

  group('the fixture is pinned to this build of the engine', () {
    test('constants agree', () {
      // A bumped `engineVersion` without a regenerated fixture is precisely the
      // drift this file exists to catch.
      expect(fixture['engineVersion'], StreakEngine.engineVersion);
      expect(fixture['schemaVersion'], kStreakSchemaVersion);
      expect(fixture['dayZone'], kCanonicalDayZone);
      expect(fixture['dayZoneOffsetMinutes'], kCanonicalDayOffsetMinutes);
      expect(_ints(fixture['milestones']), StreakEngine.milestones);
      expect(fixture['restoreWindowHours'], kStreakRestoreWindow.inHours);
      expect(fixture['atRiskThresholdHours'], kStreakAtRiskThreshold.inHours);
      expect(
        fixture['criticalThresholdHours'],
        kStreakCriticalThreshold.inHours,
      );
    });

    test('every transition and risk level appears somewhere in the table', () {
      final seen = <String>{
        for (final vector in vectors)
          ..._strings(_map(vector['expected'])['transitions']),
      };
      for (final transition in StreakTransition.values) {
        expect(seen, contains(transition.wire),
            reason: 'no vector covers ${transition.wire}');
      }

      final levels = <String>{
        for (final vector in vectors)
          _map(vector['expected'])['riskLevel'] as String,
      };
      for (final level in StreakRiskLevel.values) {
        expect(levels, contains(level.wire),
            reason: 'no vector covers ${level.wire}');
      }
    });

    test('vector names are unique, so a failure names one row', () {
      final names = vectors.map((vector) => vector['name'] as String).toList();
      expect(names.toSet().length, names.length);
      expect(names, isNotEmpty);
    });
  });

  group('restoreCost tiers', () {
    // The cost function is not part of the engine — it lives in
    // `GamificationService.getRestoreCost` and, mirrored, in the JS engine
    // module. The tier table rides along in the fixture so both mirrors are
    // pinned by the same file.
    test('the fixture table matches getRestoreCost', () {
      final tiers = (fixture['restoreCostTiers'] as List).map(_map).toList();
      expect(tiers, isNotEmpty);
      for (final tier in tiers) {
        final count = tier['count'] as int;
        expect(GamificationService.getRestoreCost(count), tier['cost'],
            reason: 'restore cost tier at count $count');
      }
    });
  });

  group('golden vectors', () {
    for (final vector in vectors) {
      final name = vector['name'] as String;

      test(name, () {
        final stored = StreakState.fromStateDoc(_map(vector['stored']));
        expect(stored, isNotNull,
            reason: '$name: `stored` must be a schemaVersion >= '
                '$kStreakMinStateSchemaVersion document');

        final rawEvent = vector['event'];
        final event = rawEvent == null
            ? null
            : Participation(
                uid: _map(rawEvent)['uid'] as String,
                instant: _instant(_map(rawEvent)['instant']),
              );

        final result = StreakEngine.evaluate(
          stored: stored!,
          participants: _strings(vector['participants']),
          event: event,
          serverNow: _instant(vector['serverNow']),
        );

        final expected = _map(vector['expected']);
        final next = _map(expected['next']);

        expect(result.count, expected['count'], reason: '$name: count');
        expect(result.lastMutualDay?.key, expected['lastMutualDay'],
            reason: '$name: lastMutualDay');
        expect(result.deadlineAt, _nullableInstant(expected['deadlineAt']),
            reason: '$name: deadlineAt');
        expect(result.riskLevel.wire, expected['riskLevel'],
            reason: '$name: riskLevel');
        expect(
          result.transitions.map((t) => t.wire).toList(),
          _strings(expected['transitions']),
          reason: '$name: transitions',
        );
        expect(result.milestonesCrossed, _ints(expected['milestonesCrossed']),
            reason: '$name: milestonesCrossed');
        expect(result.changed, expected['changed'], reason: '$name: changed');

        expect(result.next.previousCount, next['previousCount'],
            reason: '$name: next.previousCount');
        expect(result.next.brokenAt, _nullableInstant(next['brokenAt']),
            reason: '$name: next.brokenAt');
        expect(
          result.next.restoreDeadlineAt,
          _nullableInstant(next['restoreDeadlineAt']),
          reason: '$name: next.restoreDeadlineAt',
        );
        expect(result.next.bridgedThroughDay?.key, next['bridgedThroughDay'],
            reason: '$name: next.bridgedThroughDay');
        expect(
          _dayKeys(result.next.sendDays),
          _map(next['sendDays']).cast<String, String>(),
          reason: '$name: next.sendDays',
        );
        expect(result.next.longestForRoom, next['longestForRoom'],
            reason: '$name: next.longestForRoom');

        expect(result.previousCount, result.next.previousCount,
            reason: '$name: previousCount projection');
        expect(result.brokenAt, result.next.brokenAt,
            reason: '$name: brokenAt projection');

        // The projections agree with the state they project — except on a
        // step-1 refusal, which deliberately reports 0 over an untouched
        // document so nothing renders and nothing is destroyed. An empty
        // transition list is the refusal marker.
        if (result.transitions.isNotEmpty) {
          expect(result.next.count, result.count, reason: '$name: next.count');
          expect(result.next.lastMutualDay, result.lastMutualDay,
              reason: '$name: next.lastMutualDay');
          expect(result.next.deadlineAt, result.deadlineAt,
              reason: '$name: next.deadlineAt');
          expect(result.next.riskLevel, result.riskLevel,
              reason: '$name: next.riskLevel');
        }
      });
    }
  });

  group('every vector is idempotent', () {
    // Re-running the same evaluation on its own output must change nothing.
    // Refused rooms are excluded: they never produce a `next` to re-apply.
    for (final vector in vectors) {
      final name = vector['name'] as String;
      final participants = _strings(vector['participants']);
      if (_strings(_map(vector['expected'])['transitions']).isEmpty) continue;

      test('$name replays clean', () {
        final stored = StreakState.fromStateDoc(_map(vector['stored']))!;
        final rawEvent = vector['event'];
        final event = rawEvent == null
            ? null
            : Participation(
                uid: _map(rawEvent)['uid'] as String,
                instant: _instant(_map(rawEvent)['instant']),
              );
        final serverNow = _instant(vector['serverNow']);

        final first = StreakEngine.evaluate(
          stored: stored,
          participants: participants,
          event: event,
          serverNow: serverNow,
        );
        final second = StreakEngine.evaluate(
          stored: first.next,
          participants: participants,
          event: event,
          serverNow: serverNow,
        );

        expect(second.changed, isFalse, reason: '$name: replay changed state');
        expect(second.next.sameDocumentAs(first.next), isTrue,
            reason: '$name: replay produced a different document');
        // A replay may only ever report "nothing happened" — either literally,
        // or as `sameDay` when the replayed event lands on the already-counted
        // anchor day. Anything else means the replay did work.
        expect(
          second.transitions.map((t) => t.wire).toList(),
          anyOf(<Matcher>[
            equals(<String>[StreakTransition.noop.wire]),
            equals(<String>[StreakTransition.sameDay.wire]),
          ]),
          reason: '$name: replay produced transitions',
        );
        expect(second.milestonesCrossed, isEmpty,
            reason: '$name: replay re-crossed a milestone');
      });
    }
  });
}
