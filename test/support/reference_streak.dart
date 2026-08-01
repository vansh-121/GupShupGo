// ════════════════════════════════════════════════════════════════════════════
//  INDEPENDENT NAIVE STREAK ORACLE
// ════════════════════════════════════════════════════════════════════════════
//
// A deliberately naive, deliberately slow reimplementation of what a mutual
// streak *means*, written from the requirements rather than from any
// implementation:
//
//   * bucket every qualifying send into a canonical UTC+05:30 calendar day,
//   * a day is mutual iff BOTH participants appear in it,
//   * the streak is the length of the trailing run of consecutive mutual days,
//   * the streak's deadline is the start of `lastMutualDay + 2` — i.e. you have
//     the mutual day itself plus one whole grace day,
//   * past that deadline the streak is broken, the lapsed count is preserved
//     for 24 hours as `previousCount`, then that window closes too.
//
// It shares no code with `StreakEngine` (which does not exist yet) and no code
// with `legacy_streak_reference.dart`, so agreement between an implementation
// and this oracle is evidence rather than tautology.

/// The canonical streak zone: Asia/Kolkata, fixed +05:30, no DST.
const int canonicalOffsetMinutes = 330;

/// One qualifying (non-reaction) send.
class ReferenceSend {
  const ReferenceSend(this.uid, this.instant);
  final String uid;
  final DateTime instant;

  @override
  String toString() => '($uid, ${instant.toUtc().toIso8601String()})';
}

/// `YYYY-MM-DD` in the canonical zone.
String canonicalDayKey(DateTime instant) {
  final wall = instant.toUtc().add(const Duration(minutes: canonicalOffsetMinutes));
  final y = wall.year.toString().padLeft(4, '0');
  final m = wall.month.toString().padLeft(2, '0');
  final d = wall.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// The absolute UTC instant at which the canonical day [dayKey] begins.
DateTime canonicalDayStartUtc(String dayKey) {
  final parts = dayKey.split('-').map(int.parse).toList();
  return DateTime.utc(parts[0], parts[1], parts[2])
      .subtract(const Duration(minutes: canonicalOffsetMinutes));
}

/// [dayKey] shifted by [n] canonical days.
String canonicalDayPlus(String dayKey, int n) {
  final start = canonicalDayStartUtc(dayKey).add(Duration(days: n));
  return canonicalDayKey(start);
}

class ReferenceStreakResult {
  const ReferenceStreakResult({
    required this.count,
    required this.lastMutualDay,
    required this.deadlineAt,
    required this.isBroken,
    required this.previousCount,
    required this.brokenAt,
    required this.mutualDays,
  });

  /// The live streak count as of `serverNow` (0 when broken or never started).
  final int count;

  /// The newest mutual day, `null` when there has never been one.
  final String? lastMutualDay;

  /// The instant at which the streak lapses: `dayStart(lastMutualDay + 2)`.
  final DateTime? deadlineAt;

  final bool isBroken;

  /// The lapsed count, preserved for 24h after [brokenAt].
  final int previousCount;
  final DateTime? brokenAt;

  /// Every mutual day found, ascending. Diagnostics only.
  final List<String> mutualDays;

  @override
  String toString() => 'ReferenceStreakResult(count: $count, '
      'lastMutualDay: $lastMutualDay, deadlineAt: $deadlineAt, '
      'isBroken: $isBroken, previousCount: $previousCount, '
      'mutualDays: $mutualDays)';
}

/// The oracle. [participants] defaults to the distinct uids appearing in
/// [sends]; a room that does not have exactly two distinct participants can
/// never have a mutual day (self-chat, group chat).
ReferenceStreakResult referenceStreak(
  List<ReferenceSend> sends,
  DateTime serverNow, {
  List<String>? participants,
}) {
  final uids = (participants ?? sends.map((s) => s.uid).toList()).toSet();

  const empty = ReferenceStreakResult(
    count: 0,
    lastMutualDay: null,
    deadlineAt: null,
    isBroken: false,
    previousCount: 0,
    brokenAt: null,
    mutualDays: [],
  );

  if (uids.length != 2) return empty;

  // Bucket sends into canonical days.
  final byDay = <String, Set<String>>{};
  for (final send in sends) {
    if (!uids.contains(send.uid)) continue;
    byDay.putIfAbsent(canonicalDayKey(send.instant), () => <String>{}).add(send.uid);
  }

  final mutualDays = byDay.entries
      .where((e) => e.value.length == 2)
      .map((e) => e.key)
      .toList()
    ..sort();

  if (mutualDays.isEmpty) return empty;

  // Trailing run of consecutive mutual days.
  final lastMutualDay = mutualDays.last;
  var run = 1;
  for (var i = mutualDays.length - 1; i > 0; i--) {
    if (mutualDays[i - 1] == canonicalDayPlus(mutualDays[i], -1)) {
      run++;
    } else {
      break;
    }
  }

  final deadlineAt = canonicalDayStartUtc(canonicalDayPlus(lastMutualDay, 2));
  final now = serverNow.toUtc();

  if (now.isBefore(deadlineAt)) {
    return ReferenceStreakResult(
      count: run,
      lastMutualDay: lastMutualDay,
      deadlineAt: deadlineAt,
      isBroken: false,
      previousCount: 0,
      brokenAt: null,
      mutualDays: mutualDays,
    );
  }

  // Lapsed. The break is stamped at the deadline itself, and the restore
  // window is the 24 hours that follow it.
  final restoreWindowOpen = now.isBefore(deadlineAt.add(const Duration(hours: 24)));
  return ReferenceStreakResult(
    count: 0,
    lastMutualDay: lastMutualDay,
    deadlineAt: deadlineAt,
    isBroken: true,
    previousCount: restoreWindowOpen ? run : 0,
    brokenAt: deadlineAt,
    mutualDays: mutualDays,
  );
}
