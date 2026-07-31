// ═══════════════════════════════════════════════════════════════════════════════
// GupShupGo — Canonical streak calendar day (JS mirror of streak_day.dart)
// ═══════════════════════════════════════════════════════════════════════════════
// Streak days are defined in ONE canonical zone for every room: `Asia/Kolkata`,
// a FIXED UTC+05:30 offset with no DST. Every canonical day is therefore exactly
// 86,400,000 ms long, so day differences taken between absolute instants are
// exact.
//
// A day is a plain `'YYYY-MM-DD'` string here — simpler than a class, and
// identical to the persisted form used by `sendDays`, `lastMutualDay` and
// `bridgedThroughDay`.
//
// Hard rules, matching the Dart original:
//   * no `Date.now()` — the caller always supplies the instant,
//   * no local-zone getters (`getFullYear`, …) — only `getUTC*`,
//   * all arithmetic on absolute instants, never on wall-clock components, so a
//     23-hour local day in some other zone cannot swallow a day.
//
// Timestamp convention for this module (and `engine.js`): instants are ACCEPTED
// as a `Date`, epoch millis, an ISO-8601 string, or a Firestore-`Timestamp`-like
// object (`toDate()`, `_seconds`/`seconds`, `toMillis()`), and are EMITTED as
// JS `Date`. `firebase-admin` converts `Date` to `Timestamp` on write, so the
// persisted document is identical to one written with explicit `Timestamp`s.
// ═══════════════════════════════════════════════════════════════════════════════

/** The canonical zone's fixed offset from UTC, in minutes (UTC+05:30). */
const CANONICAL_DAY_OFFSET_MINUTES = 330;

/** The canonical zone's IANA name, stored alongside the offset on the state doc. */
const CANONICAL_DAY_ZONE = "Asia/Kolkata";

const MS_PER_MINUTE = 60 * 1000;
const MS_PER_DAY = 24 * 60 * MS_PER_MINUTE;

const _DAY_KEY_RE = /^(\d{4})-(\d{2})-(\d{2})$/;

/**
 * Normalises any transport representation of an instant to epoch millis.
 * Returns `null` for anything unusable — parsing a streak document must never
 * throw: a malformed field costs one value, not the whole streak.
 *
 * @param {*} value
 * @returns {number|null}
 */
function instantMillis(value) {
  if (value === null || value === undefined) return null;
  if (value instanceof Date) {
    const ms = value.getTime();
    return Number.isFinite(ms) ? ms : null;
  }
  if (typeof value === "number") return Number.isFinite(value) ? value : null;
  if (typeof value === "string") {
    const ms = Date.parse(value);
    return Number.isNaN(ms) ? null : ms;
  }
  if (typeof value === "object") {
    // Firestore Timestamp (admin SDK or JSON-serialised).
    if (typeof value.toMillis === "function") {
      const ms = value.toMillis();
      return Number.isFinite(ms) ? ms : null;
    }
    if (typeof value.toDate === "function") {
      const date = value.toDate();
      if (date instanceof Date && Number.isFinite(date.getTime())) {
        return date.getTime();
      }
      return null;
    }
    const seconds = value._seconds !== undefined ? value._seconds : value.seconds;
    if (typeof seconds === "number") {
      const nanos =
        value._nanoseconds !== undefined ? value._nanoseconds : value.nanoseconds;
      const nanoMillis = typeof nanos === "number" ? Math.trunc(nanos / 1e6) : 0;
      return seconds * 1000 + nanoMillis;
    }
  }
  return null;
}

/**
 * [instantMillis] as a `Date` (the emission form), or `null`.
 * @param {*} value
 * @returns {Date|null}
 */
function instantFrom(value) {
  const ms = instantMillis(value);
  return ms === null ? null : new Date(ms);
}

function _pad(value, width) {
  return String(value).padStart(width, "0");
}

function _keyFromUtcMillis(utcMillis) {
  const d = new Date(utcMillis);
  return `${_pad(d.getUTCFullYear(), 4)}-${_pad(d.getUTCMonth() + 1, 2)}-${_pad(
    d.getUTCDate(),
    2
  )}`;
}

/**
 * The canonical day [instant] falls in, as a `'YYYY-MM-DD'` key.
 *
 * @param {Date|number|string|object} instant
 * @param {number} [offsetMinutes=330]
 * @returns {string}
 */
function dayKeyFromInstant(instant, offsetMinutes = CANONICAL_DAY_OFFSET_MINUTES) {
  const ms = instantMillis(instant);
  if (ms === null) throw new TypeError("Not a usable instant");
  return _keyFromUtcMillis(ms + offsetMinutes * MS_PER_MINUTE);
}

/**
 * Parses a `'YYYY-MM-DD'` key into `{year, month, day}`.
 * Throws when [key] is malformed or is not a real calendar date (2023-02-29).
 *
 * @param {string} key
 * @returns {{year: number, month: number, day: number}}
 */
function parseDay(key) {
  if (typeof key !== "string") {
    throw new TypeError("Not a YYYY-MM-DD streak day key: " + String(key));
  }
  const match = _DAY_KEY_RE.exec(key);
  if (!match) {
    throw new TypeError("Not a YYYY-MM-DD streak day key: " + key);
  }
  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  // Reject dates JS would silently roll over (2023-02-29 → Mar 1).
  const probe = new Date(Date.UTC(year, month - 1, day));
  if (
    probe.getUTCFullYear() !== year ||
    probe.getUTCMonth() + 1 !== month ||
    probe.getUTCDate() !== day
  ) {
    throw new TypeError("Not a valid calendar date: " + key);
  }
  return { year, month, day };
}

/**
 * Parses [key], returning `null` instead of throwing when it is unusable.
 * @param {*} key
 * @returns {string|null}
 */
function tryParseDay(key) {
  if (typeof key !== "string" || key.length === 0) return null;
  try {
    parseDay(key);
    return key;
  } catch (_) {
    return null;
  }
}

/**
 * The absolute UTC instant at which canonical day [key] begins:
 * `Date.UTC(y, m, d) - offsetMinutes`.
 *
 * @param {string} key
 * @param {number} [offsetMinutes=330]
 * @returns {Date}
 */
function dayStartUtc(key, offsetMinutes = CANONICAL_DAY_OFFSET_MINUTES) {
  const { year, month, day } = parseDay(key);
  return new Date(Date.UTC(year, month - 1, day) - offsetMinutes * MS_PER_MINUTE);
}

/**
 * The absolute UTC instant at which canonical day [key] ends (exclusive).
 * @param {string} key
 * @param {number} [offsetMinutes=330]
 * @returns {Date}
 */
function dayEndUtc(key, offsetMinutes = CANONICAL_DAY_OFFSET_MINUTES) {
  return dayStartUtc(plusDays(key, 1), offsetMinutes);
}

/**
 * [key] shifted by [n] canonical days ([n] may be negative). Month, year and
 * leap-day rollovers fall out of instant arithmetic.
 *
 * @param {string} key
 * @param {number} n
 * @returns {string}
 */
function plusDays(key, n) {
  const { year, month, day } = parseDay(key);
  if (n === 0) return key;
  return _keyFromUtcMillis(Date.UTC(year, month - 1, day) + n * MS_PER_DAY);
}

/**
 * `a - b`, in whole canonical days. Exact: taken between absolute instants,
 * never between wall-clock values.
 *
 * @param {string} a
 * @param {string} b
 * @returns {number}
 */
function differenceInDays(a, b) {
  const delta = dayStartUtc(a).getTime() - dayStartUtc(b).getTime();
  return Math.round(delta / MS_PER_DAY);
}

/**
 * Whether [a] is the day immediately after [b].
 * @param {string} a
 * @param {string} b
 * @returns {boolean}
 */
function isDayAfter(a, b) {
  return differenceInDays(a, b) === 1;
}

/**
 * `-1`, `0` or `1`.
 * @param {string} a
 * @param {string} b
 * @returns {number}
 */
function compareDays(a, b) {
  const x = parseDay(a);
  const y = parseDay(b);
  if (x.year !== y.year) return x.year < y.year ? -1 : 1;
  if (x.month !== y.month) return x.month < y.month ? -1 : 1;
  if (x.day !== y.day) return x.day < y.day ? -1 : 1;
  return 0;
}

/**
 * The later of [a] and [b], treating null/undefined as "no day".
 * @param {?string} a
 * @param {?string} b
 * @returns {?string}
 */
function maxDay(a, b) {
  if (a === null || a === undefined) return b === undefined ? null : b;
  if (b === null || b === undefined) return a;
  return compareDays(a, b) >= 0 ? a : b;
}

/**
 * The earlier of [a] and [b], treating null/undefined as "no day".
 * @param {?string} a
 * @param {?string} b
 * @returns {?string}
 */
function minDay(a, b) {
  if (a === null || a === undefined) return b === undefined ? null : b;
  if (b === null || b === undefined) return a;
  return compareDays(a, b) <= 0 ? a : b;
}

module.exports = {
  CANONICAL_DAY_OFFSET_MINUTES,
  CANONICAL_DAY_ZONE,
  MS_PER_MINUTE,
  MS_PER_DAY,
  instantMillis,
  instantFrom,
  dayKeyFromInstant,
  parseDay,
  tryParseDay,
  dayStartUtc,
  dayEndUtc,
  plusDays,
  differenceInDays,
  isDayAfter,
  compareDays,
  maxDay,
  minDay,
};
