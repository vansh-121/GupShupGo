// ═══════════════════════════════════════════════════════════════════════════════
// GupShupGo — Streak repair / migration (design §10, tasks 9.1–9.2)
// ═══════════════════════════════════════════════════════════════════════════════
// Reconstructs `chatRooms/{roomId}/streak/state` from MESSAGE HISTORY, because the
// legacy `chatRooms/{roomId}.streakCount` was written by a client that could
// refresh its own deadline, skip days, and survive a lapse (defect 1.23). A
// migration that trusted that number would carry the defect forward, so the
// history is the only source consulted — with one narrowly-scoped exception for a
// truncated scan (see `_countForTruncatedScan`).
//
// It contains NO streak arithmetic of its own:
//   * every day key, day shift and day difference comes from `./day.js`,
//   * the count/deadline/break/risk decision comes from ONE `engine.evaluate`
//     call with `event: null`, exactly as the sweeper does,
//   * the document is serialised by `state.toWire`, so a repaired document is
//     byte-identical in shape to one the trigger would have written,
//   * milestones the reconstruction flew past are paid by
//     `awards.awardCrossedUpToSafely`, whose ledger `create` makes the payout
//     idempotent.
//
// SAFETY: dry run is the DEFAULT and the ambiguous case. `repairRoom` mutates
// streak state only when it is handed `dryRun: false` explicitly; anything else —
// `undefined`, a missing flag document, a non-boolean — is treated as a dry run,
// which writes a per-room report to `_migrations/streakV2/reports/{roomId}` and
// touches no state and pays no awards.
// ═══════════════════════════════════════════════════════════════════════════════

const admin = require("firebase-admin");

const engine = require("./engine");
const state = require("./state");
const awards = require("./awards");
const {
  MS_PER_DAY,
  instantFrom,
  instantMillis,
  dayKeyFromInstant,
  tryParseDay,
  dayStartUtc,
  plusDays,
  differenceInDays,
  compareDays,
} = require("./day");

/** Newest-first messages read per room. The boundary that makes a scan truncated. */
const MESSAGE_SCAN_LIMIT = 500;

/** How far a message timestamp may sit before its `createTime` and still count (2.11). */
const BACKDATE_WINDOW_MS = 48 * 60 * 60 * 1000;

/** Rooms per `repairPage` call — one scheduled invocation's worth (design §10). */
const ROOM_PAGE_SIZE = 200;

/** The `repairSource` values this module writes. Persisted strings, so pinned. */
const RepairSource = {
  history: "history",
  historyTruncated: "history:truncated",
  fallbackNoHistory: "fallback:no-history",
};

/** The cursor / accounting document, `_migrations/streakV2`. */
const MIGRATION_COLLECTION = "_migrations";
const MIGRATION_DOC = "streakV2";
const REPORTS_COLLECTION = "reports";

// ─── lazy Firestore handle ────────────────────────────────────────────────────

let _db = null;

/**
 * @returns {import("firebase-admin").firestore.Firestore}
 */
function db() {
  if (_db === null) _db = admin.firestore();
  return _db;
}

/**
 * Test seam. Forwarded to `./state.js` and `./awards.js` so one call configures
 * every module in the repair path and they cannot end up on different handles.
 * @param {*} handle
 */
function setFirestore(handle) {
  _db = handle;
  awards.setFirestore(handle); // also forwards to state.js
}

/** `_migrations/streakV2`. */
function migrationRef() {
  return db().collection(MIGRATION_COLLECTION).doc(MIGRATION_DOC);
}

/** `_migrations/streakV2/reports/{roomId}` — the dry-run per-room report. */
function reportRef(roomId) {
  if (typeof roomId !== "string" || roomId.length === 0) {
    throw new TypeError("roomId is required");
  }
  return migrationRef().collection(REPORTS_COLLECTION).doc(roomId);
}

// ─── dry-run resolution ───────────────────────────────────────────────────────

/**
 * Whether [value] authorises a LIVE run. Only the boolean `false` does — the
 * literal "dryRun is off". `undefined`, `null`, `0`, `'false'` and anything else
 * ambiguous resolve to a dry run, so a missing or half-written flag document can
 * never mutate production streaks.
 *
 * @param {*} value the `dryRun` flag as read from config
 * @returns {boolean} the effective `dryRun`
 */
function resolveDryRun(value) {
  return value === false ? false : true;
}

// ─── helpers ──────────────────────────────────────────────────────────────────

function _asInt(value, fallback) {
  if (typeof value === "number" && Number.isFinite(value)) return Math.trunc(value);
  if (typeof value === "string") {
    const parsed = Number.parseInt(value, 10);
    if (!Number.isNaN(parsed)) return parsed;
  }
  return fallback;
}

function _pairOf(participants) {
  if (!Array.isArray(participants)) return [];
  const set = new Set();
  for (const uid of participants) {
    if (typeof uid === "string" && uid.length > 0) set.add(uid);
  }
  return Array.from(set).sort();
}

function _serverNowOf(opts) {
  const supplied = opts && opts.serverNow;
  const instant = instantFrom(
    supplied === undefined || supplied === null
      ? admin.firestore.Timestamp.now()
      : supplied
  );
  if (instant === null) throw new TypeError("serverNow is required");
  return instant;
}

/**
 * The histogram bucket for a `repairedCount - legacyCount` delta. Bucketed rather
 * than exact so `mismatchHistogram` stays a readable handful of fields instead of
 * an unbounded map, while still answering the question task 9.4 asks: how many
 * rooms LOST a material amount of streak.
 *
 * Field names only — no dots, no leading digits, safe in a Firestore field path.
 *
 * @param {number} delta
 * @returns {string}
 */
function mismatchBucket(delta) {
  const d = _asInt(delta, 0);
  if (d === 0) return "same";
  const magnitude = Math.abs(d);
  const sign = d < 0 ? "lost" : "gained";
  if (magnitude <= 2) return `${sign}_1_2`;
  if (magnitude <= 6) return `${sign}_3_6`;
  if (magnitude <= 29) return `${sign}_7_29`;
  if (magnitude <= 99) return `${sign}_30_99`;
  return `${sign}_100_plus`;
}

// ─── step 2: project messages to (senderId, dayKey) ───────────────────────────

/**
 * Clamps a client-supplied message timestamp into the window the server can
 * vouch for, using the document's own `createTime` as the reference instant.
 *
 * `createTime` is assigned by Firestore, so it is the one trustworthy instant on
 * a historical message. A `timestamp` after it is impossible (the client cannot
 * have sent a message after the server stored it) and a `timestamp` more than 48h
 * before it is treated as clock skew, not as a real backdate — the same window
 * `streakOnMessageCreate` applies on the live path (2.11 / 2.13).
 *
 * @param {*} timestamp the message's claimed `timestamp`
 * @param {*} createTime the document's `createTime`
 * @returns {?number} epoch millis, or `null` when the timestamp is unusable
 */
function clampMessageInstant(timestamp, createTime) {
  const claimed = instantMillis(timestamp);
  if (claimed === null) return null;
  const created = instantMillis(createTime);
  if (created === null) return claimed; // no server reference: take it as given
  return Math.min(Math.max(claimed, created - BACKDATE_WINDOW_MS), created);
}

/**
 * Whether a message document qualifies as participation. Mirrors the single
 * enforcement point in the trigger: reactions never qualify (2.10).
 *
 * @param {?object} data
 * @returns {boolean}
 */
function isQualifyingMessage(data) {
  return !!data && data.type !== "reaction";
}

/**
 * Projects raw message snapshots to `{uid, dayKey}` participation facts.
 *
 * Accepts anything with `.data()` and (optionally) `.createTime` — real
 * `QueryDocumentSnapshot`s, or plain `{data: () => …, createTime}` objects in a
 * test.
 *
 * @param {Array<object>} docs newest-first message snapshots
 * @param {Array<string>} pair the two participant uids
 * @param {number} offsetMinutes canonical day offset
 * @returns {{days: Array<{uid: string, day: string}>, scanned: number,
 *   qualifying: number, unusable: number}}
 */
function projectMessages(docs, pair, offsetMinutes) {
  const days = [];
  let qualifying = 0;
  let unusable = 0;
  for (const doc of docs || []) {
    const data = typeof doc.data === "function" ? doc.data() : doc;
    if (!isQualifyingMessage(data)) continue;
    qualifying++;
    const senderId = data.senderId;
    if (typeof senderId !== "string" || senderId.length === 0) {
      unusable++;
      continue;
    }
    const ms = clampMessageInstant(data.timestamp, doc.createTime);
    if (ms === null) {
      unusable++;
      continue;
    }
    if (!pair.includes(senderId)) continue; // a uid outside the pair proves nothing
    days.push({ uid: senderId, day: dayKeyFromInstant(ms, offsetMinutes) });
  }
  return { days, scanned: (docs || []).length, qualifying, unusable };
}

// ─── step 3: mutual days, and the run that ends at the newest one ─────────────

/**
 * Reconstructs the streak from projected participation facts.
 *
 * A day is mutual iff BOTH participants appear on it. The count is the longest
 * run of CONSECUTIVE mutual days ending at the newest mutual day — "ending
 * there", not "anywhere in history", because a streak is a live chain: an older,
 * longer run has already lapsed and must not be resurrected.
 *
 * Pure: no clock, no I/O.
 *
 * @param {Array<{uid: string, day: string}>} projected
 * @param {Array<string>} pair
 * @returns {{count: number, lastMutualDay: ?string, mutualDays: Array<string>,
 *   latestDayByUid: Object<string, string>, usable: boolean}}
 */
function reconstruct(projected, pair) {
  const byDay = new Map(); // day → Set<uid>
  const latestDayByUid = {};
  for (const entry of projected || []) {
    const day = tryParseDay(entry && entry.day);
    if (day === null) continue;
    if (!byDay.has(day)) byDay.set(day, new Set());
    byDay.get(day).add(entry.uid);
    const current = latestDayByUid[entry.uid] || null;
    if (current === null || compareDays(day, current) > 0) {
      latestDayByUid[entry.uid] = day;
    }
  }

  const mutualDays = Array.from(byDay.entries())
    .filter(([, uids]) => pair.every((uid) => uids.has(uid)))
    .map(([day]) => day)
    .sort(compareDays);

  if (mutualDays.length === 0) {
    return {
      count: 0,
      lastMutualDay: null,
      mutualDays,
      latestDayByUid,
      usable: byDay.size > 0,
    };
  }

  let count = 1;
  for (let i = mutualDays.length - 1; i > 0; i--) {
    if (differenceInDays(mutualDays[i], mutualDays[i - 1]) === 1) count++;
    else break;
  }

  return {
    count,
    lastMutualDay: mutualDays[mutualDays.length - 1],
    mutualDays,
    latestDayByUid,
    usable: true,
  };
}

// ─── truncation: the one place a legacy number is consulted ────────────────────

/**
 * The count to use when the scan hit the 500-message boundary.
 *
 * The reconstruction is a LOWER BOUND there: the chain may well continue past the
 * oldest message we read. The legacy `streakCount` is allowed to raise it, but
 * ONLY when the legacy value is self-consistent with the same history — i.e. its
 * `lastInteractionDate` maps to the exact canonical day the reconstruction found
 * as `lastMutualDay`. If the legacy anchor points at a different day, the legacy
 * count is describing a different (and demonstrably wrong) chain and is ignored.
 *
 * A streak is therefore never inflated beyond what history, or a legacy value
 * that agrees with history, supports.
 *
 * @param {object} args
 * @param {number} args.reconstructedRun
 * @param {?string} args.lastMutualDay
 * @param {number} args.legacyCount
 * @param {?string} args.legacyDay canonical day of `lastInteractionDate`
 * @returns {{count: number, legacyHonoured: boolean}}
 */
function _countForTruncatedScan({
  reconstructedRun,
  lastMutualDay,
  legacyCount,
  legacyDay,
}) {
  const consistent =
    lastMutualDay !== null && legacyDay !== null && legacyDay === lastMutualDay;
  if (!consistent || legacyCount <= reconstructedRun) {
    return { count: reconstructedRun, legacyHonoured: false };
  }
  return { count: legacyCount, legacyHonoured: true };
}

// ─── the per-room repair ──────────────────────────────────────────────────────

function _emptyReport(roomId, dryRun, extra) {
  return Object.assign(
    {
      roomId,
      dryRun,
      skipped: false,
      skipReason: null,
      usable: false,
      truncated: false,
      repairSource: null,
      scannedMessages: 0,
      unusableMessages: 0,
      mutualDayCount: 0,
      reconstructedRun: 0,
      legacyHonoured: false,
      legacyStreakCount: 0,
      legacyLastInteractionDay: null,
      repairPreviousLegacyCount: 0,
      count: 0,
      previousCount: 0,
      lastMutualDay: null,
      deadlineAt: null,
      brokenAt: null,
      riskLevel: null,
      transitions: [],
      delta: 0,
      mismatchBucket: "same",
      wrote: false,
      rev: 0,
      awarded: [],
      fallback: false,
      error: null,
    },
    extra || {}
  );
}

function _epoch(value) {
  const ms = instantMillis(value);
  return ms === null ? null : ms;
}

/**
 * Reconstructs and (unless dry-run) rewrites one room's streak state.
 *
 * @param {string} roomId
 * @param {object} [opts]
 * @param {boolean} [opts.dryRun=true] LIVE only on an explicit `false`
 * @param {*} [opts.serverNow] defaults to `Timestamp.now()`
 * @param {?object} [opts.roomData] the parent room document, if already read
 * @param {boolean} [opts.force=false] repair even an already-repaired room
 * @returns {Promise<object>} the per-room report
 */
async function repairRoom(roomId, opts = {}) {
  if (typeof roomId !== "string" || roomId.length === 0) {
    throw new TypeError("roomId is required");
  }
  const dryRun = resolveDryRun(opts.dryRun);
  const serverNow = _serverNowOf(opts);

  // ── the parent room: participants + the legacy numbers we report on ───────
  let roomData = opts.roomData || null;
  if (roomData === null) {
    const roomSnap = await state.roomRef(roomId).get();
    if (!roomSnap.exists) {
      return _emptyReport(roomId, dryRun, {
        skipped: true,
        skipReason: "room-missing",
      });
    }
    roomData = roomSnap.data() || {};
  }

  const pair = _pairOf(roomData.participants);
  const legacyStreakCount = Math.max(0, _asInt(roomData.streakCount, 0));
  let legacyLastInteractionDay = null;

  // ── the stored state: idempotency gate ───────────────────────────────────
  const stateSnap = await state.stateRef(roomId).get();
  const stored = engine.normalizeState(stateSnap.exists ? stateSnap.data() : null);
  const offsetMinutes = stored.dayZoneOffsetMinutes;

  const legacyMs = instantMillis(roomData.lastInteractionDate);
  if (legacyMs !== null) {
    legacyLastInteractionDay = dayKeyFromInstant(legacyMs, offsetMinutes);
  }

  // `repairPreviousLegacyCount` is the PRE-REPAIR count as the user last saw it:
  // the state document's count once one exists, else the legacy room field.
  const previousLegacyCount = stateSnap.exists ? stored.count : legacyStreakCount;

  if (
    opts.force !== true &&
    stateSnap.exists &&
    stored.schemaVersion === engine.SCHEMA_VERSION &&
    stored.repairSource !== null
  ) {
    return _emptyReport(roomId, dryRun, {
      skipped: true,
      skipReason: "already-repaired",
      repairSource: stored.repairSource,
      legacyStreakCount,
      legacyLastInteractionDay,
      repairPreviousLegacyCount: stored.repairPreviousLegacyCount || 0,
      count: stored.count,
      lastMutualDay: stored.lastMutualDay,
      rev: stored.rev,
    });
  }

  if (pair.length !== 2) {
    // Self-chat or group-shaped: the engine refuses these, so does the repair.
    return _emptyReport(roomId, dryRun, {
      skipped: true,
      skipReason: "not-a-two-person-room",
      legacyStreakCount,
      legacyLastInteractionDay,
    });
  }

  // ── step 1–2: newest-first history, projected ────────────────────────────
  const messagesSnap = await state
    .roomRef(roomId)
    .collection("messages")
    .orderBy("timestamp", "desc")
    .limit(MESSAGE_SCAN_LIMIT)
    .get();

  const docs = messagesSnap.docs || [];
  const truncated = docs.length >= MESSAGE_SCAN_LIMIT;
  const projected = projectMessages(docs, pair, offsetMinutes);
  const reconstruction = reconstruct(projected.days, pair);

  const base = {
    dryRun,
    truncated,
    scannedMessages: projected.scanned,
    unusableMessages: projected.unusable,
    mutualDayCount: reconstruction.mutualDays.length,
    reconstructedRun: reconstruction.count,
    legacyStreakCount,
    legacyLastInteractionDay,
    repairPreviousLegacyCount: previousLegacyCount,
  };

  // ── unusable history: zero it, never invent a streak (2.25) ───────────────
  if (!reconstruction.usable) {
    console.warn(
      "[streak-repair] unusable history, falling back to zero",
      JSON.stringify({
        roomId,
        scanned: projected.scanned,
        unusable: projected.unusable,
        legacyStreakCount,
      })
    );
    const report = _emptyReport(
      roomId,
      dryRun,
      Object.assign({}, base, {
        usable: false,
        fallback: true,
        repairSource: RepairSource.fallbackNoHistory,
        count: 0,
        previousCount: 0,
        lastMutualDay: null,
        deadlineAt: null,
        brokenAt: null,
        riskLevel: engine.RiskLevel.normal,
        delta: -previousLegacyCount,
        mismatchBucket: mismatchBucket(-previousLegacyCount),
      })
    );
    return _persist(roomId, {
      report,
      stored,
      serverNow,
      dryRun,
      pair,
      synthetic: {
        count: 0,
        lastMutualDay: null,
        sendDays: {},
        sendInstants: {},
      },
      repairSource: RepairSource.fallbackNoHistory,
      previousLegacyCount,
      awardCount: 0,
    });
  }

  // ── truncation: the only place the legacy count may raise anything ────────
  let repairSource = RepairSource.history;
  let count = reconstruction.count;
  let legacyHonoured = false;
  if (truncated) {
    repairSource = RepairSource.historyTruncated;
    const resolved = _countForTruncatedScan({
      reconstructedRun: reconstruction.count,
      lastMutualDay: reconstruction.lastMutualDay,
      legacyCount: legacyStreakCount,
      legacyDay: legacyLastInteractionDay,
    });
    count = resolved.count;
    legacyHonoured = resolved.legacyHonoured;
  }

  // Latest send day per participant, from history — NOT forced to the mutual day.
  // A solo send after the last mutual day is a real fact, and keeping it means a
  // reply the day after the repair increments instead of restarting.
  const sendDays = {};
  const sendInstants = {};
  for (const uid of pair) {
    const day = reconstruction.latestDayByUid[uid] || null;
    if (day !== null) {
      sendDays[uid] = day;
      // Midday of the recorded day: the exact instant is not used by any rule,
      // and a mid-day value cannot drift across a boundary under any offset.
      sendInstants[uid] = new Date(dayStartUtc(day, offsetMinutes).getTime() + MS_PER_DAY / 2);
    }
  }

  const report = _emptyReport(
    roomId,
    dryRun,
    Object.assign({}, base, {
      usable: true,
      repairSource,
      legacyHonoured,
    })
  );

  return _persist(roomId, {
    report,
    stored,
    serverNow,
    dryRun,
    pair,
    synthetic: {
      count,
      lastMutualDay: reconstruction.lastMutualDay,
      sendDays,
      sendInstants,
    },
    repairSource,
    previousLegacyCount,
    // Milestones are paid against the count the bond GENUINELY REACHED per
    // history, before the engine's read-side break zeroes it. A bond that ran to
    // 12 days and then lapsed still earned the 7-day award; the ledger `create`
    // in awards.js keeps that from paying twice.
    awardCount: count,
  });
}

/**
 * Runs the single `engine.evaluate` and either writes the state document or
 * records a dry-run report. Shared by both exits of `repairRoom` so the two
 * cannot drift.
 *
 * @returns {Promise<object>} the completed report
 */
async function _persist(
  roomId,
  {
    report,
    stored,
    serverNow,
    dryRun,
    pair,
    synthetic,
    repairSource,
    previousLegacyCount,
    awardCount,
  }
) {
  // The reconstruction, expressed as a state document the engine can evaluate.
  // Everything derived — deadlineAt, riskLevel, brokenAt, restoreDeadlineAt — is
  // left for `evaluate` to decide; nothing here is arithmetic.
  const seed = Object.assign({}, stored, {
    schemaVersion: engine.SCHEMA_VERSION,
    participants: pair,
    count: synthetic.count,
    lastMutualDay: synthetic.lastMutualDay,
    bridgedThroughDay: null,
    deadlineAt:
      synthetic.lastMutualDay === null
        ? null
        : dayStartUtc(plusDays(synthetic.lastMutualDay, 2), stored.dayZoneOffsetMinutes),
    sendDays: synthetic.sendDays,
    sendInstants: synthetic.sendInstants,
    previousCount: 0,
    brokenAt: null,
    restoreDeadlineAt: null,
    repairedAt: serverNow,
    repairSource,
    repairPreviousLegacyCount: previousLegacyCount,
  });

  // Step 4: ONE evaluation, `event: null`, current server time. A reconstruction
  // that already lapsed is stamped broken at its real `deadlineAt` (step 8) and,
  // when that is more than 24h old, has its restore window closed (step 9).
  const evaluation = engine.evaluate({
    stored: seed,
    participants: pair,
    event: null,
    serverNow,
  });
  const next = evaluation.next;

  const delta = next.count - previousLegacyCount;
  Object.assign(report, {
    count: next.count,
    previousCount: next.previousCount,
    lastMutualDay: next.lastMutualDay,
    deadlineAt: _epoch(next.deadlineAt),
    brokenAt: _epoch(next.brokenAt),
    restoreDeadlineAt: _epoch(next.restoreDeadlineAt),
    riskLevel: next.riskLevel,
    transitions: evaluation.transitions,
    repairSource,
    repairPreviousLegacyCount: previousLegacyCount,
    delta,
    mismatchBucket: mismatchBucket(delta),
    evaluatedAt: _epoch(serverNow),
  });

  if (dryRun) {
    // Reports are the ONLY write a dry run makes, and they live outside the
    // streak namespace entirely.
    await reportRef(roomId).set(
      Object.assign({}, report, { generatedAt: serverNow }),
      { merge: false }
    );
    report.wrote = false;
    return report;
  }

  const rev = stored.rev + 1;
  await state.stateRef(roomId).set(
    state.toWire(next, {
      rev,
      serverNow,
      reason: state.EvaluationReason.repair,
      recentApplied: state.pruneRecentApplied(stored.recentApplied, serverNow),
    })
  );
  report.wrote = true;
  report.rev = rev;

  // Step 10: the repaired count can JUMP, and `evaluate` only ever reports a
  // single crossing, so the skipped thresholds are paid explicitly here.
  if (awardCount > 0) {
    try {
      const awarded = await awards.awardCrossedUpToSafely(roomId, next, awardCount, {
        serverNow,
        participants: pair,
      });
      report.awarded = (awarded && awarded.thresholdsAwarded) || [];
    } catch (error) {
      // A payout must never fail a repair: the room is already correct, and the
      // crossing stays un-recorded so a later pass can pay it.
      console.error(
        "[streak-repair] award pass failed (swallowed)",
        JSON.stringify({ roomId, message: error && error.message })
      );
    }
  }

  console.log(
    `[streak-repair] ${roomId} ${repairSource} legacy=${previousLegacyCount} ` +
    `count=${report.count} delta=${delta} rev=${rev}`
  );
  return report;
}

// ─── cursor and accounting ────────────────────────────────────────────────────

/**
 * The `_migrations/streakV2` cursor, normalised. A missing document reads as a
 * fresh, DRY run.
 *
 * @returns {Promise<{lastRoomId: ?string, processed: number, repaired: number,
 *   fallback: number, skipped: number, failed: number,
 *   mismatchHistogram: object, startedAt: ?Date, finishedAt: ?Date,
 *   dryRun: boolean, exists: boolean}>}
 */
async function readCursor() {
  const snap = await migrationRef().get();
  const data = snap.exists ? snap.data() || {} : {};
  const histogram =
    data.mismatchHistogram && typeof data.mismatchHistogram === "object"
      ? data.mismatchHistogram
      : {};
  return {
    lastRoomId: typeof data.lastRoomId === "string" ? data.lastRoomId : null,
    processed: _asInt(data.processed, 0),
    repaired: _asInt(data.repaired, 0),
    fallback: _asInt(data.fallback, 0),
    skipped: _asInt(data.skipped, 0),
    failed: _asInt(data.failed, 0),
    mismatchHistogram: histogram,
    startedAt: instantFrom(data.startedAt),
    finishedAt: instantFrom(data.finishedAt),
    dryRun: resolveDryRun(data.dryRun),
    exists: snap.exists,
  };
}

/**
 * Clears the cursor so the next invocation starts from the first room. Counters
 * and the histogram are reset with it; the reports subcollection is left alone.
 *
 * @param {object} [opts]
 * @param {boolean} [opts.dryRun=true]
 * @param {*} [opts.serverNow]
 * @returns {Promise<void>}
 */
async function resetCursor(opts = {}) {
  const serverNow = _serverNowOf(opts);
  await migrationRef().set(
    {
      lastRoomId: null,
      processed: 0,
      repaired: 0,
      fallback: 0,
      skipped: 0,
      failed: 0,
      mismatchHistogram: {},
      startedAt: serverNow,
      finishedAt: null,
      dryRun: resolveDryRun(opts.dryRun),
    },
    { merge: false }
  );
}

/**
 * Folds one page's aggregate into the cursor document.
 *
 * Counters use `increment` and the histogram uses per-bucket `increment`, so two
 * overlapping invocations cannot lose each other's work, and an invocation killed
 * mid-page only loses the rooms it had not finished — those are re-processed next
 * time and the idempotency gate makes that a no-op.
 *
 * @param {object} aggregate output of `repairPage`
 * @param {object} [opts]
 * @param {*} [opts.serverNow]
 * @returns {Promise<void>}
 */
async function commitCursor(aggregate, opts = {}) {
  const serverNow = _serverNowOf(opts);
  const FieldValue = admin.firestore.FieldValue;
  const updates = {
    processed: FieldValue.increment(aggregate.processed || 0),
    repaired: FieldValue.increment(aggregate.repaired || 0),
    fallback: FieldValue.increment(aggregate.fallback || 0),
    skipped: FieldValue.increment(aggregate.skipped || 0),
    failed: FieldValue.increment(aggregate.failed || 0),
    dryRun: aggregate.dryRun,
    lastUpdatedAt: serverNow,
  };
  if (aggregate.lastRoomId) updates.lastRoomId = aggregate.lastRoomId;
  // A finished pass leaves the cursor where it is; `resetCursor` starts over.
  if (aggregate.finished) updates.finishedAt = serverNow;
  if (aggregate.startedAtPresent !== true) updates.startedAt = serverNow;

  // Nested map rather than dotted field paths, so ONE `set(merge: true)` both
  // creates the document on the first invocation and merges bucket increments.
  const histogram = {};
  for (const [bucket, hits] of Object.entries(aggregate.mismatchHistogram || {})) {
    histogram[bucket] = FieldValue.increment(hits);
  }
  if (Object.keys(histogram).length > 0) updates.mismatchHistogram = histogram;

  await migrationRef().set(updates, { merge: true });
}

// ─── one page of rooms ────────────────────────────────────────────────────────

function _emptyAggregate(dryRun) {
  return {
    dryRun,
    processed: 0,
    repaired: 0,
    fallback: 0,
    skipped: 0,
    failed: 0,
    mismatchHistogram: {},
    lastRoomId: null,
    finished: false,
    reports: [],
  };
}

/**
 * Repairs up to [limit] rooms ordered by `__name__`, starting after
 * [startAfterRoomId]. Ordering by document id is what makes the pass resumable:
 * the cursor is a room id, not an offset, so nothing shifts under it as rooms are
 * created or deleted.
 *
 * One room's failure is logged and counted, never fatal — the pass continues and
 * the room is retried on a later invocation.
 *
 * @param {object} [opts]
 * @param {boolean} [opts.dryRun=true]
 * @param {number} [opts.limit=200]
 * @param {?string} [opts.startAfterRoomId]
 * @param {*} [opts.serverNow]
 * @param {boolean} [opts.force=false]
 * @returns {Promise<object>} the aggregate
 */
async function repairPage(opts = {}) {
  const dryRun = resolveDryRun(opts.dryRun);
  const serverNow = _serverNowOf(opts);
  const limit = Math.max(1, _asInt(opts.limit, ROOM_PAGE_SIZE));
  const aggregate = _emptyAggregate(dryRun);

  let query = db()
    .collection("chatRooms")
    .orderBy(admin.firestore.FieldPath.documentId())
    .limit(limit);
  if (typeof opts.startAfterRoomId === "string" && opts.startAfterRoomId.length > 0) {
    query = query.startAfter(opts.startAfterRoomId);
  }

  const page = await query.get();
  const docs = page.docs || [];

  for (const doc of docs) {
    aggregate.lastRoomId = doc.id;
    try {
      const report = await repairRoom(doc.id, {
        dryRun,
        serverNow,
        roomData: doc.data() || {},
        force: opts.force === true,
      });
      aggregate.reports.push(report);
      if (report.skipped) {
        aggregate.skipped++;
        continue;
      }
      aggregate.processed++;
      if (report.fallback) aggregate.fallback++;
      const bucket = report.mismatchBucket;
      aggregate.mismatchHistogram[bucket] =
        (aggregate.mismatchHistogram[bucket] || 0) + 1;
      if (report.wrote) aggregate.repaired++;
    } catch (error) {
      aggregate.failed++;
      console.error(
        "[streak-repair] room failed",
        JSON.stringify({ roomId: doc.id, message: error && error.message })
      );
    }
  }

  aggregate.finished = docs.length < limit;
  return aggregate;
}

/**
 * `repairPage` + cursor bookkeeping: reads the cursor, repairs the next page from
 * it, and folds the result back. This is the whole body of `streakRepairJob`.
 *
 * @param {object} [opts]
 * @param {boolean} [opts.dryRun] overrides the cursor's mode
 * @param {number} [opts.limit=200]
 * @param {*} [opts.serverNow]
 * @returns {Promise<object>} `{aggregate, cursorBefore, dryRun}`
 */
async function runNextPage(opts = {}) {
  const cursor = await readCursor();
  const dryRun =
    opts.dryRun === undefined ? cursor.dryRun : resolveDryRun(opts.dryRun);
  const serverNow = _serverNowOf(opts);

  const aggregate = await repairPage({
    dryRun,
    limit: _asInt(opts.limit, ROOM_PAGE_SIZE),
    startAfterRoomId: cursor.lastRoomId,
    serverNow,
  });
  aggregate.startedAtPresent = cursor.startedAt !== null;

  await commitCursor(aggregate, { serverNow });
  return { aggregate, cursorBefore: cursor, dryRun };
}

module.exports = {
  MESSAGE_SCAN_LIMIT,
  BACKDATE_WINDOW_MS,
  ROOM_PAGE_SIZE,
  RepairSource,
  setFirestore,
  migrationRef,
  reportRef,
  resolveDryRun,
  mismatchBucket,
  clampMessageInstant,
  isQualifyingMessage,
  projectMessages,
  reconstruct,
  repairRoom,
  readCursor,
  resetCursor,
  commitCursor,
  repairPage,
  runNextPage,
};
