/// Canonical streak calendar day.
///
/// Streak days are defined in ONE canonical zone for every room:
/// `Asia/Kolkata`, a **fixed** UTC+05:30 offset with no DST. Because the zone
/// has no DST transitions, every canonical day is exactly 86,400 seconds long,
/// so day differences taken between absolute instants are exact.
///
/// Hard rules for this file (enforced by the purity guard test):
///
///  * no `DateTime.now()` — the caller always supplies the instant,
///  * no `toLocal()` — the device zone is irrelevant to a streak day,
///  * no wall-clock `.inDays` — all arithmetic goes through [startUtc], which
///    is an absolute instant, so a 23-hour local day cannot swallow a day.
library;

/// The canonical zone's fixed offset from UTC, in minutes (UTC+05:30).
const int kCanonicalDayOffsetMinutes = 330;

/// The canonical zone's IANA name. Stored on the state document alongside the
/// offset so a future per-room zone is a data change, not a re-interpretation.
const String kCanonicalDayZone = 'Asia/Kolkata';

/// A `YYYY-MM-DD` calendar day in the canonical zone.
///
/// Value type: two `StreakDay`s with the same date are equal and hash alike.
class StreakDay implements Comparable<StreakDay> {
  const StreakDay(this.year, this.month, this.day);

  /// The canonical day that [instant] falls in.
  ///
  /// [instant] may be in any zone; it is normalised to UTC first, so the
  /// device's zone never affects the result.
  factory StreakDay.fromInstant(
    DateTime instant, {
    int offsetMinutes = kCanonicalDayOffsetMinutes,
  }) {
    final wall = instant.toUtc().add(Duration(minutes: offsetMinutes));
    return StreakDay(wall.year, wall.month, wall.day);
  }

  /// Parses a `YYYY-MM-DD` key.
  ///
  /// Throws [FormatException] when [key] is not a well-formed key or does not
  /// denote a real calendar date (e.g. `2023-02-29`).
  factory StreakDay.parse(String key) {
    final parts = key.split('-');
    if (parts.length != 3 ||
        parts[0].length != 4 ||
        parts[1].length != 2 ||
        parts[2].length != 2) {
      throw FormatException('Not a YYYY-MM-DD streak day key', key);
    }
    final int year;
    final int month;
    final int day;
    try {
      year = int.parse(parts[0]);
      month = int.parse(parts[1]);
      day = int.parse(parts[2]);
    } on FormatException {
      throw FormatException('Not a YYYY-MM-DD streak day key', key);
    }
    // Reject dates that Dart would silently roll over (2023-02-29 → Mar 1).
    final probe = DateTime.utc(year, month, day);
    if (probe.year != year || probe.month != month || probe.day != day) {
      throw FormatException('Not a valid calendar date', key);
    }
    return StreakDay(year, month, day);
  }

  /// Parses [key], returning `null` instead of throwing when it is unusable.
  static StreakDay? tryParse(String? key) {
    if (key == null || key.isEmpty) return null;
    try {
      return StreakDay.parse(key);
    } on FormatException {
      return null;
    }
  }

  final int year;
  final int month;
  final int day;

  /// The `YYYY-MM-DD` key, which is also the persisted representation.
  String get key => '${_pad(year, 4)}-${_pad(month, 2)}-${_pad(day, 2)}';

  /// The absolute UTC instant at which this canonical day begins:
  /// `DateTime.utc(y, m, d) - offsetMinutes`.
  DateTime startUtc({int offsetMinutes = kCanonicalDayOffsetMinutes}) =>
      DateTime.utc(year, month, day)
          .subtract(Duration(minutes: offsetMinutes));

  /// The absolute UTC instant at which this canonical day ends (exclusive),
  /// i.e. the start of the next day.
  DateTime endUtc({int offsetMinutes = kCanonicalDayOffsetMinutes}) =>
      plusDays(1).startUtc(offsetMinutes: offsetMinutes);

  /// This day shifted by [n] canonical days ([n] may be negative).
  ///
  /// Computed by adding whole days to the day's absolute start instant, so
  /// month, year and leap-day rollovers all fall out of instant arithmetic.
  StreakDay plusDays(int n) {
    if (n == 0) return this;
    final shifted = DateTime.utc(year, month, day).add(Duration(days: n));
    return StreakDay(shifted.year, shifted.month, shifted.day);
  }

  /// `this - other`, in whole canonical days.
  ///
  /// Exact: taken between absolute instants, never between wall-clock values,
  /// so a DST transition in any other zone cannot perturb it.
  int differenceInDays(StreakDay other) =>
      startUtc().difference(other.startUtc()).inDays;

  /// Whether this day is the one immediately after [other].
  bool isDayAfter(StreakDay other) => differenceInDays(other) == 1;

  @override
  int compareTo(StreakDay other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  bool operator <(StreakDay other) => compareTo(other) < 0;
  bool operator <=(StreakDay other) => compareTo(other) <= 0;
  bool operator >(StreakDay other) => compareTo(other) > 0;
  bool operator >=(StreakDay other) => compareTo(other) >= 0;

  /// The later of [a] and [b], treating `null` as "no day".
  static StreakDay? max(StreakDay? a, StreakDay? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a >= b ? a : b;
  }

  /// The earlier of [a] and [b], treating `null` as "no day".
  static StreakDay? min(StreakDay? a, StreakDay? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a <= b ? a : b;
  }

  @override
  bool operator ==(Object other) =>
      other is StreakDay &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => 'StreakDay($key)';

  static String _pad(int value, int width) =>
      value.toString().padLeft(width, '0');
}
