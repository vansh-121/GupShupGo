// Unit tests for the canonical streak calendar day.
//
// Validates: Requirements 2.5 (one canonical zone, both participants always
// agree on "today") and 2.6 (a DST transition in any other zone can never
// swallow or duplicate a streak day, because all arithmetic is on absolute
// instants).
//
// Canonical zone: Asia/Kolkata, fixed UTC+05:30, no DST. Canonical midnight is
// therefore 18:30 UTC of the previous calendar date.

import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/services/streak/streak_day.dart';

import '../../support/reference_streak.dart';

void main() {
  group('StreakDay.fromInstant — canonical midnight is 18:30 UTC', () {
    test('one microsecond before the boundary is still the previous day', () {
      final instant = DateTime.utc(2024, 3, 3, 18, 29, 59, 999, 999);
      expect(StreakDay.fromInstant(instant).key, '2024-03-03');
    });

    test('exactly the boundary is the new day', () {
      final instant = DateTime.utc(2024, 3, 3, 18, 30);
      expect(StreakDay.fromInstant(instant).key, '2024-03-04');
    });

    test('one microsecond after the boundary is the new day', () {
      final instant = DateTime.utc(2024, 3, 3, 18, 30, 0, 0, 1);
      expect(StreakDay.fromInstant(instant).key, '2024-03-04');
    });

    test('UTC noon and the following UTC midnight are different streak days',
        () {
      // 2024-03-03 12:00 UTC == 17:30 IST on Mar 3.
      expect(StreakDay.fromInstant(DateTime.utc(2024, 3, 3, 12)).key,
          '2024-03-03');
      // 2024-03-04 00:00 UTC == 05:30 IST on Mar 4.
      expect(StreakDay.fromInstant(DateTime.utc(2024, 3, 4)).key, '2024-03-04');
    });

    test('the two participants in the design example agree on the day', () {
      // A sends Mar 4 01:00 IST == Mar 3 19:30 UTC.
      final a = DateTime.utc(2024, 3, 3, 19, 30);
      // B sends Mar 3 20:00 PT (UTC-07:00) == Mar 4 03:00 UTC == Mar 4 08:30 IST.
      final b = DateTime.utc(2024, 3, 4, 3);
      expect(StreakDay.fromInstant(a).key, '2024-03-04');
      expect(StreakDay.fromInstant(b).key, '2024-03-04');
      expect(StreakDay.fromInstant(a), StreakDay.fromInstant(b));
    });

    test('a non-UTC input instant is normalised, not reinterpreted', () {
      final utc = DateTime.utc(2024, 3, 3, 18, 30);
      final asLocal = utc.toLocal(); // same instant, whatever the host zone is
      expect(StreakDay.fromInstant(asLocal), StreakDay.fromInstant(utc));
    });

    test('an explicit non-canonical offset moves the boundary', () {
      final instant = DateTime.utc(2024, 3, 3, 18, 30);
      // Evaluated at UTC+00:00 the same instant is still Mar 3.
      expect(StreakDay.fromInstant(instant, offsetMinutes: 0).key,
          '2024-03-03');
    });
  });

  group('startUtc round-trips', () {
    test('startUtc is canonical midnight, i.e. 18:30 UTC the day before', () {
      expect(const StreakDay(2024, 3, 4).startUtc(),
          DateTime.utc(2024, 3, 3, 18, 30));
    });

    test('fromInstant(startUtc(d)) == d', () {
      final days = <StreakDay>[
        const StreakDay(2024, 1, 1),
        const StreakDay(2024, 2, 29),
        const StreakDay(2024, 3, 10),
        const StreakDay(2024, 12, 31),
        const StreakDay(2025, 1, 1),
        const StreakDay(2023, 11, 5),
      ];
      for (final day in days) {
        expect(StreakDay.fromInstant(day.startUtc()), day, reason: day.key);
      }
    });

    test('the last microsecond of a day still maps back to that day', () {
      const day = StreakDay(2024, 3, 4);
      final lastMicro =
          day.endUtc().subtract(const Duration(microseconds: 1));
      expect(StreakDay.fromInstant(lastMicro), day);
      expect(StreakDay.fromInstant(day.endUtc()), const StreakDay(2024, 3, 5));
    });

    test('parse(key) round-trips through key', () {
      for (final key in ['2024-02-29', '2024-12-31', '2025-01-01', '0999-01-02']) {
        expect(StreakDay.parse(key).key, key);
      }
    });

    test('parse rejects malformed and impossible keys', () {
      for (final bad in [
        '2024-2-29',
        '24-02-29',
        '2024/02/29',
        '2023-02-29', // not a leap year
        '2024-13-01',
        '',
        'not-a-day',
      ]) {
        expect(() => StreakDay.parse(bad), throwsFormatException, reason: bad);
      }
      expect(StreakDay.tryParse('2023-02-29'), isNull);
      expect(StreakDay.tryParse(null), isNull);
      expect(StreakDay.tryParse('2024-02-29'), const StreakDay(2024, 2, 29));
    });
  });

  group('differenceInDays is exact under foreign DST transitions', () {
    test('every consecutive pair of days is exactly 24 hours apart', () {
      // Walk a full year, including both hemispheres' DST transitions.
      var day = const StreakDay(2024, 1, 1);
      for (var i = 0; i < 366; i++) {
        final next = day.plusDays(1);
        expect(next.startUtc().difference(day.startUtc()),
            const Duration(hours: 24),
            reason: '${day.key} → ${next.key}');
        expect(next.differenceInDays(day), 1, reason: day.key);
        day = next;
      }
    });

    test('US spring-forward: the 23-hour local day is still one streak day',
        () {
      // 2024-03-10 02:00 America/Los_Angeles springs forward to 03:00, making
      // the local day 23 hours long. Legacy code did
      // `today.difference(lastMutualDay).inDays` on wall-clock values and got 0.
      final before = StreakDay.fromInstant(DateTime.utc(2024, 3, 9, 20)); // Mar 10 IST
      final after = StreakDay.fromInstant(DateTime.utc(2024, 3, 10, 20)); // Mar 11 IST
      expect(before.key, '2024-03-10');
      expect(after.key, '2024-03-11');
      expect(after.differenceInDays(before), 1);
    });

    test('US fall-back: the 25-hour local day is still one streak day', () {
      // 2024-11-03 02:00 America/Los_Angeles falls back to 01:00.
      final before = StreakDay.fromInstant(DateTime.utc(2024, 11, 2, 20));
      final after = StreakDay.fromInstant(DateTime.utc(2024, 11, 3, 20));
      expect(after.differenceInDays(before), 1);
    });

    test('EU transitions in both directions still measure one day', () {
      // 2024-03-31 (spring forward) and 2024-10-27 (fall back) in Europe/Berlin.
      for (final pair in [
        (DateTime.utc(2024, 3, 30, 12), DateTime.utc(2024, 3, 31, 12)),
        (DateTime.utc(2024, 10, 26, 12), DateTime.utc(2024, 10, 27, 12)),
      ]) {
        final a = StreakDay.fromInstant(pair.$1);
        final b = StreakDay.fromInstant(pair.$2);
        expect(b.differenceInDays(a), 1, reason: '${a.key} → ${b.key}');
      }
    });

    test('difference is signed, antisymmetric and additive', () {
      const a = StreakDay(2024, 3, 4);
      final b = a.plusDays(37);
      expect(b.differenceInDays(a), 37);
      expect(a.differenceInDays(b), -37);
      expect(a.differenceInDays(a), 0);
      expect(b.plusDays(-37), a);
    });
  });

  group('leap days', () {
    test('2024-02-28 → 2024-02-29 → 2024-03-01', () {
      const feb28 = StreakDay(2024, 2, 28);
      expect(feb28.plusDays(1).key, '2024-02-29');
      expect(feb28.plusDays(2).key, '2024-03-01');
      expect(const StreakDay(2024, 3, 1).differenceInDays(feb28), 2);
    });

    test('2023 has no Feb 29', () {
      expect(const StreakDay(2023, 2, 28).plusDays(1).key, '2023-03-01');
    });

    test('the leap day boundary sits at 2024-02-28 18:30 UTC', () {
      expect(
          StreakDay.fromInstant(DateTime.utc(2024, 2, 28, 18, 29, 59)).key,
          '2024-02-28');
      expect(StreakDay.fromInstant(DateTime.utc(2024, 2, 28, 18, 30)).key,
          '2024-02-29');
      expect(const StreakDay(2024, 2, 29).startUtc(),
          DateTime.utc(2024, 2, 28, 18, 30));
    });

    test('a February spanning the leap day counts 29 days', () {
      expect(
          const StreakDay(2024, 3, 1)
              .differenceInDays(const StreakDay(2024, 2, 1)),
          29);
      expect(
          const StreakDay(2023, 3, 1)
              .differenceInDays(const StreakDay(2023, 2, 1)),
          28);
    });

    test('2100 is not a leap year (century rule)', () {
      expect(const StreakDay(2100, 2, 28).plusDays(1).key, '2100-03-01');
      expect(const StreakDay(2000, 2, 28).plusDays(1).key, '2000-02-29');
    });
  });

  group('year boundaries', () {
    test('New Year rolls over at 2024-12-31 18:30 UTC', () {
      expect(StreakDay.fromInstant(DateTime.utc(2024, 12, 31, 18, 29)).key,
          '2024-12-31');
      expect(StreakDay.fromInstant(DateTime.utc(2024, 12, 31, 18, 30)).key,
          '2025-01-01');
    });

    test('UTC New Year is already the canonical new year', () {
      // 2025-01-01 00:00 UTC == 05:30 IST on Jan 1.
      expect(StreakDay.fromInstant(DateTime.utc(2025)).key, '2025-01-01');
    });

    test('plusDays and differenceInDays cross the year end', () {
      const dec31 = StreakDay(2024, 12, 31);
      expect(dec31.plusDays(1).key, '2025-01-01');
      expect(dec31.plusDays(2).key, '2025-01-02');
      expect(const StreakDay(2025, 1, 1).differenceInDays(dec31), 1);
      expect(
          const StreakDay(2025, 1, 1)
              .differenceInDays(const StreakDay(2024, 1, 1)),
          366); // 2024 is a leap year
      expect(
          const StreakDay(2024, 1, 1)
              .differenceInDays(const StreakDay(2023, 1, 1)),
          365);
    });
  });

  group('ordering, equality and helpers', () {
    test('compareTo orders chronologically across all components', () {
      final days = <StreakDay>[
        const StreakDay(2025, 1, 1),
        const StreakDay(2024, 2, 29),
        const StreakDay(2024, 12, 31),
        const StreakDay(2024, 3, 4),
        const StreakDay(2024, 3, 3),
      ]..sort();
      expect(days.map((d) => d.key).toList(), [
        '2024-02-29',
        '2024-03-03',
        '2024-03-04',
        '2024-12-31',
        '2025-01-01',
      ]);
    });

    test('compareTo agrees with the sign of differenceInDays', () {
      const a = StreakDay(2024, 3, 3);
      const b = StreakDay(2024, 12, 31);
      expect(a.compareTo(b).sign, a.differenceInDays(b).sign);
      expect(b.compareTo(a).sign, b.differenceInDays(a).sign);
      expect(a.compareTo(a), 0);
      expect(a < b, isTrue);
      expect(a <= a, isTrue);
      expect(b > a, isTrue);
      expect(b >= b, isTrue);
    });

    test('value equality and hashCode', () {
      const a = StreakDay(2024, 2, 29);
      final b = StreakDay.parse('2024-02-29');
      final c = StreakDay.fromInstant(DateTime.utc(2024, 2, 29, 12));
      expect(a, b);
      expect(a, c);
      expect(a.hashCode, b.hashCode);
      expect({a, b, c}.length, 1);
      expect(a == const StreakDay(2024, 3, 1), isFalse);
    });

    test('isDayAfter, max and min', () {
      const a = StreakDay(2024, 3, 3);
      const b = StreakDay(2024, 3, 4);
      expect(b.isDayAfter(a), isTrue);
      expect(a.isDayAfter(b), isFalse);
      expect(b.plusDays(1).isDayAfter(a), isFalse);
      expect(StreakDay.max(a, b), b);
      expect(StreakDay.max(a, null), a);
      expect(StreakDay.max(null, null), isNull);
      expect(StreakDay.min(a, b), a);
      expect(StreakDay.min(null, b), b);
    });

    test('plusDays(0) is identity', () {
      const a = StreakDay(2024, 3, 3);
      expect(a.plusDays(0), a);
    });
  });

  group('agreement with the independent reference oracle', () {
    test('the canonical offset matches the oracle', () {
      expect(kCanonicalDayOffsetMinutes, canonicalOffsetMinutes);
    });

    test('key, startUtc and plusDays agree with the oracle over a year', () {
      // Sample every 7 hours for a year so the sample walks through every
      // time-of-day relative to the 18:30 UTC boundary.
      var instant = DateTime.utc(2024, 1, 1, 0, 17);
      final end = DateTime.utc(2025, 1, 2);
      var samples = 0;
      while (instant.isBefore(end)) {
        final day = StreakDay.fromInstant(instant);
        expect(day.key, canonicalDayKey(instant),
            reason: instant.toIso8601String());
        expect(day.startUtc(), canonicalDayStartUtc(day.key), reason: day.key);
        for (final n in [-2, -1, 1, 2, 30]) {
          expect(day.plusDays(n).key, canonicalDayPlus(day.key, n),
              reason: '${day.key} + $n');
        }
        instant = instant.add(const Duration(hours: 7));
        samples++;
      }
      expect(samples, greaterThan(1200));
    });

    test('the deadline rule agrees with the oracle', () {
      // The oracle's deadline is dayStart(lastMutualDay + 2); the engine will
      // read the same value off StreakDay.
      for (final key in ['2024-02-28', '2024-12-31', '2024-03-09']) {
        final day = StreakDay.parse(key);
        expect(day.plusDays(2).startUtc(),
            canonicalDayStartUtc(canonicalDayPlus(key, 2)),
            reason: key);
      }
    });
  });
}
