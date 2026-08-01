// ═══════════════════════════════════════════════════════════════════════════════
// GupShupGo — Streak engine (JS port of lib/services/streak/streak_engine.dart)
// ═══════════════════════════════════════════════════════════════════════════════
// `evaluate({stored, participants, event, serverNow})` is a PURE function. It is
// the server-side mirror of `StreakEngine.evaluate`, pinned to the Dart original
// by the shared golden fixture `test/fixtures/streak_vectors.json`. A semantic
// change here without the same change in Dart (and in the fixture) is a bug.
//
// Hard rules, matching the Dart original:
//   * no `Date.now()` — `serverNow` is always supplied by the caller,
//   * no local-zone arithmetic — canonical days come from `day.js` alone,
//   * no I/O, no logging, no Firestore.
//
// Timestamps: instants are ACCEPTED as `Date`, epoch millis, ISO-8601 string, or
// a Firestore-`Timestamp`-like object; they are EMITTED as JS `Date`.
// `firebase-admin` converts `Date` to `Timestamp` on write, so `next` can be
// handed straight to `set()`/`update()`.
//
// What the engine deliberately does not do:
//   * filter message types — every `event` handed in is a QUALIFYING send; the
//     trigger drops reactions,
//   * pay out milestones or append to `milestonesAwarded` — it only REPORTS
//     `milestonesCrossed`,
//   * touch `rev`, `lastEvaluatedAt`/`lastEvaluatedBy` or `recentApplied` — the
//     writer owns those, in the same transaction.
// ═══════════════════════════════════════════════════════════════════════════════

const {
  CANONICAL_DAY_OFFSET_MINUTES,
  CANONICAL_DAY_ZONE,
  instantFrom,
  instantMillis,
  dayKeyFromInstant,
  tryParseDay,
  dayStartUtc,
  plusDays,
  differenceInDays,
  compareDays,
  maxDay,
} = require("./day");

/** Bumped when the semantics below change. Persisted on the state document. */
const ENGINE_VERSION = 1;

/** The schema version this engine writes. */
const SCHEMA_VERSION = 2;

/** Reward thresholds, ascending. Crossed, not exact-matched. */
const MILESTONES = [7, 30, 100, 365];

/** Above this much time remaining a bond is `normal`; at or below it, `atRisk`. */
const AT_RISK_THRESHOLD_MS = 24 * 60 * 60 * 1000;

/** At or below this much time remaining a bond is `critical`. */
const CRITICAL_THRESHOLD_MS = 6 * 60 * 60 * 1000;

/** How long a broken streak stays restorable. */
const RESTORE_WINDOW_MS = 24 * 60 * 60 * 1000;

/** The persisted `riskLevel` strings. Pinned — the wire format, not identifiers. */
const RiskLevel = {
  normal: "normal",
  atRisk: "atRisk",
  critical: "critical",
  broken: "broken",
};

/** The persisted `transitions` strings. Pinned, same reason. */
const Transition = {
  participationRecorded: "participationRecorded",
  started: "started",
  incremented: "incremented",
  sameDay: "sameDay",
  broken: "broken",
  restoreWindowExpired: "restoreWindowExpired",
  milestoneCrossed: "milestoneCrossed",
  longestRaised: "longestRaised",
  noop: "noop",
};

const _KNOWN_FIELDS = new Set([
  "schemaVersion",
  "engineVersion",
  "rev",
  "dayZone",
  "dayZoneOffsetMinutes",
  "participants",
  "count",
  "lastMutualDay",
  "bridgedThroughDay",
  "deadlineAt",
  "riskLevel",
  "sendDays",
  "sendInstants",
  "previousCount",
  "brokenAt",
  "restoreDeadlineAt",
  "restoredAt",
  "restoredBy",
  "restoreCostPaid",
  "milestonesAwarded",
  "longestForRoom",
  "recentApplied",
  "notifiedAt",
  "lastEvaluatedAt",
  "lastEvaluatedBy",
  "repairedAt",
  "repairSource",
  "repairPreviousLegacyCount",
]);

// ─── parsing helpers ───────────────────────────────────────────────────────────

function _asInt(value, fallback) {
  const parsed = _asNullableInt(value);
  return parsed === null ? fallback : parsed;
}

function _asNullableInt(value) {
  if (typeof value === "number" && Number.isFinite(value)) return Math.trunc(value);
  if (typeof value === "string") {
    const parsed = Number.parseInt(value, 10);
    return Number.isNaN(parsed) ? null : parsed;
  }
  return null;
}

function _asString(value) {
  return typeof value === "string" ? value : null;
}

function _sortedUnique(uids) {
  if (!Array.isArray(uids)) return [];
  const set = new Set();
  for (const uid of uids) {
    if (typeof uid === "string" && uid.length > 0) set.add(uid);
  }
  return Array.from(set).sort();
}

function _asIntList(value) {
  if (!Array.isArray(value)) return [];
  const set = new Set();
  for (const entry of value) {
    const parsed = _asNullableInt(entry);
    if (parsed !== null) set.add(parsed);
  }
  return Array.from(set).sort((a, b) => a - b);
}

function _asPlainMap(value) {
  if (value === null || typeof value !== "object" || Array.isArray(value)) return {};
  return value;
}

function _asDayMap(value) {
  const out = {};
  for (const [key, entry] of Object.entries(_asPlainMap(value))) {
    const day = tryParseDay(entry);
    if (day !== null) out[key] = day;
  }
  return out;
}

function _asInstantMap(value) {
  const out = {};
  for (const [key, entry] of Object.entries(_asPlainMap(value))) {
    const instant = instantFrom(entry);
    if (instant !== null) out[key] = instant;
  }
  return out;
}

function _asRiskLevel(value) {
  return typeof value === "string" && RiskLevel[value] === value
    ? value
    : RiskLevel.normal;
}

/**
 * Hydrates a raw `chatRooms/{roomId}/streak/state` document (or `null`) into the
 * shape the engine works with. Every field is optional and every malformed value
 * is dropped rather than thrown on. Unknown fields — written by a newer engine —
 * are preserved so a round trip never loses data.
 *
 * @param {?object} data
 * @returns {object}
 */
function normalizeState(data) {
  const raw = _asPlainMap(data);
  const extraFields = {};
  for (const [key, value] of Object.entries(raw)) {
    if (!_KNOWN_FIELDS.has(key)) extraFields[key] = value;
  }
  return {
    schemaVersion: _asInt(raw.schemaVersion, SCHEMA_VERSION),
    engineVersion: _asInt(raw.engineVersion, 0),
    rev: _asInt(raw.rev, 0),
    dayZone: _asString(raw.dayZone) || CANONICAL_DAY_ZONE,
    dayZoneOffsetMinutes: _asInt(
      raw.dayZoneOffsetMinutes,
      CANONICAL_DAY_OFFSET_MINUTES
    ),
    participants: _sortedUnique(raw.participants),
    count: _asInt(raw.count, 0),
    lastMutualDay: tryParseDay(raw.lastMutualDay),
    bridgedThroughDay: tryParseDay(raw.bridgedThroughDay),
    deadlineAt: instantFrom(raw.deadlineAt),
    riskLevel: _asRiskLevel(raw.riskLevel),
    sendDays: _asDayMap(raw.sendDays),
    sendInstants: _asInstantMap(raw.sendInstants),
    previousCount: _asInt(raw.previousCount, 0),
    brokenAt: instantFrom(raw.brokenAt),
    restoreDeadlineAt: instantFrom(raw.restoreDeadlineAt),
    restoredAt: instantFrom(raw.restoredAt),
    restoredBy: _asString(raw.restoredBy),
    restoreCostPaid: _asNullableInt(raw.restoreCostPaid),
    milestonesAwarded: _asIntList(raw.milestonesAwarded),
    longestForRoom: _asInt(raw.longestForRoom, 0),
    recentApplied: _asInstantMap(raw.recentApplied),
    notifiedAt: _asInstantMap(raw.notifiedAt),
    lastEvaluatedAt: instantFrom(raw.lastEvaluatedAt),
    lastEvaluatedBy: _asString(raw.lastEvaluatedBy),
    repairedAt: instantFrom(raw.repairedAt),
    repairSource: _asString(raw.repairSource),
    repairPreviousLegacyCount: _asNullableInt(raw.repairPreviousLegacyCount),
    extraFields,
  };
}

// ─── equality (the `changed` signal) ──────────────────────────────────────────

function _instantEquals(a, b) {
  const x = a === null || a === undefined ? null : a.getTime();
  const y = b === null || b === undefined ? null : b.getTime();
  return x === y;
}

function _listEquals(a, b) {
  if (a.length !== b.length) return false;
  for (let i = 0; i < a.length; i++) {
    if (a[i] !== b[i]) return false;
  }
  return true;
}

function _mapEquals(a, b, eq) {
  const ak = Object.keys(a);
  const bk = Object.keys(b);
  if (ak.length !== bk.length) return false;
  for (const key of ak) {
    if (!Object.prototype.hasOwnProperty.call(b, key)) return false;
    if (!eq(a[key], b[key])) return false;
  }
  return true;
}

function _jsonEquals(a, b) {
  return JSON.stringify(a) === JSON.stringify(b);
}

/**
 * Field equality over the persisted document. Mirrors
 * `StreakState.sameDocumentAs`, and is what `changed` is derived from.
 *
 * @param {object} a normalised state
 * @param {object} b normalised state
 * @returns {boolean}
 */
function sameDocument(a, b) {
  return (
    a.schemaVersion === b.schemaVersion &&
    a.engineVersion === b.engineVersion &&
    a.rev === b.rev &&
    a.dayZone === b.dayZone &&
    a.dayZoneOffsetMinutes === b.dayZoneOffsetMinutes &&
    _listEquals(a.participants, b.participants) &&
    a.count === b.count &&
    a.lastMutualDay === b.lastMutualDay &&
    a.bridgedThroughDay === b.bridgedThroughDay &&
    _instantEquals(a.deadlineAt, b.deadlineAt) &&
    a.riskLevel === b.riskLevel &&
    _mapEquals(a.sendDays, b.sendDays, (x, y) => x === y) &&
    _mapEquals(a.sendInstants, b.sendInstants, _instantEquals) &&
    a.previousCount === b.previousCount &&
    _instantEquals(a.brokenAt, b.brokenAt) &&
    _instantEquals(a.restoreDeadlineAt, b.restoreDeadlineAt) &&
    _instantEquals(a.restoredAt, b.restoredAt) &&
    a.restoredBy === b.restoredBy &&
    a.restoreCostPaid === b.restoreCostPaid &&
    _listEquals(a.milestonesAwarded, b.milestonesAwarded) &&
    a.longestForRoom === b.longestForRoom &&
    _mapEquals(a.recentApplied, b.recentApplied, _instantEquals) &&
    _mapEquals(a.notifiedAt, b.notifiedAt, _instantEquals) &&
    _instantEquals(a.lastEvaluatedAt, b.lastEvaluatedAt) &&
    a.lastEvaluatedBy === b.lastEvaluatedBy &&
    _instantEquals(a.repairedAt, b.repairedAt) &&
    a.repairSource === b.repairSource &&
    a.repairPreviousLegacyCount === b.repairPreviousLegacyCount &&
    _jsonEquals(a.extraFields, b.extraFields)
  );
}

// ─── the specification ────────────────────────────────────────────────────────

/**
 * The sorted pair of uids, or `null` when [participants] is not exactly two
 * distinct non-empty uids.
 *
 * @param {Array<string>} participants
 * @returns {?Array<string>}
 */
function _pairOf(participants) {
  const pair = _sortedUnique(participants);
  return pair.length === 2 ? pair : null;
}

/**
 * Step 10 in isolation, so a badge can derive the same risk level from a
 * deadline without re-running an evaluation.
 *
 * `remaining > 24h` → normal; `6h < remaining <= 24h` → atRisk;
 * `0 < remaining <= 6h` → critical; `remaining <= 0` → broken.
 *
 * With no deadline there is nothing to count down to: `broken` when a break is
 * stamped (a restorable bond whose deadline was never recorded, e.g. a legacy
 * projection) and `normal` otherwise.
 *
 * @param {{deadlineAt: *, serverNow: *, hasBrokenStamp?: boolean}} args
 * @returns {string} one of RiskLevel
 */
function riskLevelFor({ deadlineAt, serverNow, hasBrokenStamp = false }) {
  const deadline = instantMillis(deadlineAt);
  if (deadline === null) {
    return hasBrokenStamp ? RiskLevel.broken : RiskLevel.normal;
  }
  const now = instantMillis(serverNow);
  if (now === null) throw new TypeError("serverNow is required");
  const remaining = deadline - now;
  if (remaining <= 0) return RiskLevel.broken;
  if (remaining <= CRITICAL_THRESHOLD_MS) return RiskLevel.critical;
  if (remaining <= AT_RISK_THRESHOLD_MS) return RiskLevel.atRisk;
  return RiskLevel.normal;
}

/**
 * The Gup Point cost of restoring a lapsed streak of [count] days. Mirror of
 * `GamificationService.getRestoreCost`; pinned by `restoreCostTiers` in the
 * shared fixture.
 *
 * @param {number} count
 * @returns {number}
 */
function restoreCost(count) {
  const n = _asInt(count, 0);
  if (n < 10) return 10;
  if (n < 30) return 25;
  if (n < 100) return 50;
  return 100;
}

/**
 * Evaluates [stored] as of [serverNow], optionally folding in [event].
 *
 * @param {object} args
 * @param {?object} args.stored raw or normalised state document
 * @param {Array<string>} args.participants passed verbatim; see step 1
 * @param {?{uid: string, instant: *}} [args.event] one qualifying send
 * @param {*} args.serverNow
 * @returns {{count: number, lastMutualDay: ?string, deadlineAt: ?Date,
 *   riskLevel: string, transitions: Array<string>, milestonesCrossed: Array<number>,
 *   next: object, changed: boolean}}
 */
function evaluate({ stored, participants, event = null, serverNow }) {
  const nowMs = instantMillis(serverNow);
  if (nowMs === null) throw new TypeError("serverNow is required");

  const storedState = normalizeState(stored);

  // ── 1. Refuse anything that is not a two-person room ────────────────────
  //
  // Self-chat (uid == uid) collapses to one participant, so it can never
  // produce a mutual day. A group room is refused rather than guessed at.
  // `stored` is returned untouched so a refusal can never corrupt or erase a
  // document, and `changed` is false so no writer acts on it — while the
  // reported count is 0, so nothing renders.
  const pair = _pairOf(participants);
  if (pair === null) {
    return {
      count: 0,
      lastMutualDay: null,
      deadlineAt: null,
      riskLevel: RiskLevel.normal,
      transitions: [],
      milestonesCrossed: [],
      next: storedState,
      changed: false,
    };
  }

  const offsetMinutes = storedState.dayZoneOffsetMinutes;
  const transitions = [];

  // A negative count can only come from a corrupt document; treat it as 0 so
  // the repair is implicit rather than propagated.
  const storedCount = storedState.count < 0 ? 0 : storedState.count;

  let count = storedCount;
  let lastMutualDay = storedState.lastMutualDay;
  let bridgedThroughDay = storedState.bridgedThroughDay;
  let previousCount =
    storedState.previousCount < 0 ? 0 : storedState.previousCount;
  let brokenAt = storedState.brokenAt;
  let restoreDeadlineAt = storedState.restoreDeadlineAt;

  // ── 2. Record participation, forward only ───────────────────────────────
  //
  // `event.day <= sendDays[uid]` is structurally idempotent: a duplicate
  // delivery, a retry, or a late/out-of-order message for a day already
  // recorded for that uid changes nothing. An event from a uid outside the pair
  // is ignored.
  let sendDays = storedState.sendDays;
  let sendInstants = storedState.sendInstants;
  if (event && pair.includes(event.uid)) {
    const day = dayKeyFromInstant(event.instant, offsetMinutes);
    const recorded = sendDays[event.uid] || null;
    if (recorded === null || compareDays(day, recorded) > 0) {
      sendDays = Object.assign({}, sendDays, { [event.uid]: day });
      sendInstants = Object.assign({}, sendInstants, {
        [event.uid]: instantFrom(event.instant),
      });
      transitions.push(Transition.participationRecorded);
    }
  }

  // ── 3. A mutual day exists iff both latest send days are the same day ────
  const dayA = sendDays[pair[0]] || null;
  const dayB = sendDays[pair[1]] || null;
  const mutualDay = dayA !== null && dayB !== null && dayA === dayB ? dayA : null;

  // ── 4. Continuity is measured from the anchor or a restore bridge ────────
  const horizon = maxDay(lastMutualDay, bridgedThroughDay);

  // ── 5. A newer mutual day starts, continues or restarts the chain ────────
  if (
    mutualDay !== null &&
    (lastMutualDay === null || compareDays(mutualDay, lastMutualDay) > 0)
  ) {
    if (horizon === null) {
      // Nothing to continue from: the bond's first mutual day.
      count = 1;
      transitions.push(Transition.started);
    } else if (differenceInDays(mutualDay, horizon) <= 1) {
      // Inside the chain. The restore bridge has served its purpose.
      count = count > 0 ? count + 1 : 1;
      transitions.push(
        count === 1 ? Transition.started : Transition.incremented
      );
      bridgedThroughDay = null;
    } else {
      // The chain lapsed before this day. Stamp the break at the deadline it
      // actually missed — not at "now" — then restart at 1. Step 9 closes the
      // restore window immediately if it has already elapsed.
      //
      // `count > 0` guards the double-break: when a previous evaluation (a
      // sweep, or step 8 of this one) has already zeroed the count and stamped
      // the break, re-stamping would overwrite `previousCount` with 0 and
      // silently withdraw a live restore offer.
      if (count > 0) {
        previousCount = count;
        brokenAt = dayStartUtc(plusDays(horizon, 2), offsetMinutes);
        restoreDeadlineAt = new Date(brokenAt.getTime() + RESTORE_WINDOW_MS);
        transitions.push(Transition.broken);
      }
      count = 1;
      bridgedThroughDay = null;
      transitions.push(Transition.started);
    }
    lastMutualDay = mutualDay;
  } else if (event && mutualDay !== null && mutualDay === lastMutualDay) {
    // ── 6. Extra traffic on an already-counted day ────────────────────────
    //
    // THE FIX: the anchor does not move and the deadline is not refreshed.
    // Reported for observability only; nothing changes.
    transitions.push(Transition.sameDay);
  }

  // ── 7. The deadline always follows from the resulting horizon ────────────
  const nextHorizon = maxDay(lastMutualDay, bridgedThroughDay);
  const deadlineAt =
    nextHorizon === null
      ? null
      : dayStartUtc(plusDays(nextHorizon, 2), offsetMinutes);

  // ── 8. Read-side break ──────────────────────────────────────────────────
  //
  // This is the step that makes a lapsed bond render as broken with no writer
  // involved: the same pure function the sweeper uses to stamp the break
  // derives it for display.
  if (count > 0 && deadlineAt !== null && nowMs >= deadlineAt.getTime()) {
    previousCount = count;
    brokenAt = deadlineAt;
    restoreDeadlineAt = new Date(deadlineAt.getTime() + RESTORE_WINDOW_MS);
    count = 0;
    transitions.push(Transition.broken);
  }

  // ── 9. The restore window closes ────────────────────────────────────────
  //
  // Strictly AFTER `restoreDeadlineAt`: the last instant of the window is still
  // restorable.
  if (
    brokenAt !== null &&
    restoreDeadlineAt !== null &&
    nowMs > restoreDeadlineAt.getTime()
  ) {
    previousCount = 0;
    brokenAt = null;
    restoreDeadlineAt = null;
    transitions.push(Transition.restoreWindowExpired);
  }

  // ── 10. Risk level, from the same deadline the break rule uses ──────────
  const riskLevel = riskLevelFor({
    deadlineAt,
    serverNow: nowMs,
    hasBrokenStamp: brokenAt !== null,
  });

  // ── 11. Milestones by crossing, not by exact match ──────────────────────
  const milestonesCrossed = MILESTONES.filter(
    (threshold) =>
      storedCount < threshold &&
      threshold <= count &&
      !storedState.milestonesAwarded.includes(threshold)
  );
  if (milestonesCrossed.length > 0) {
    transitions.push(Transition.milestoneCrossed);
  }

  // ── 12. Best-ever for this room ─────────────────────────────────────────
  let longestForRoom =
    storedState.longestForRoom < 0 ? 0 : storedState.longestForRoom;
  if (count > longestForRoom) {
    longestForRoom = count;
    transitions.push(Transition.longestRaised);
  }

  const next = Object.assign({}, storedState, {
    schemaVersion: SCHEMA_VERSION,
    engineVersion: ENGINE_VERSION,
    participants: pair,
    count,
    lastMutualDay,
    bridgedThroughDay,
    deadlineAt,
    riskLevel,
    sendDays,
    sendInstants,
    previousCount,
    brokenAt,
    restoreDeadlineAt,
    longestForRoom,
  });

  if (transitions.length === 0) transitions.push(Transition.noop);

  return {
    count,
    lastMutualDay,
    deadlineAt,
    riskLevel,
    transitions,
    milestonesCrossed,
    next,
    changed: !sameDocument(storedState, next),
  };
}

module.exports = {
  ENGINE_VERSION,
  SCHEMA_VERSION,
  MILESTONES,
  AT_RISK_THRESHOLD_MS,
  CRITICAL_THRESHOLD_MS,
  RESTORE_WINDOW_MS,
  RiskLevel,
  Transition,
  normalizeState,
  sameDocument,
  riskLevelFor,
  restoreCost,
  evaluate,
};
