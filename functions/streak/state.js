// ═══════════════════════════════════════════════════════════════════════════════
// GupShupGo — Streak state adapter (the ONLY writer of chatRooms/*/streak/state)
// ═══════════════════════════════════════════════════════════════════════════════
// A thin, transactional shell around the pure engine in `./engine.js`. It owns
// exactly the concerns the engine deliberately refuses:
//
//   * I/O — reading the state document (and, on bootstrap, the parent room for
//     `participants`), and writing the result,
//   * `rev`, `lastEvaluatedAt`, `lastEvaluatedBy`,
//   * `recentApplied` — the dedupe ledger that guards the NON-idempotent side
//     effects (milestone payouts, `longestStreak` raises, notifications). The
//     count itself needs no ledger: engine step 2 is forward-only, so a
//     re-delivered trigger is structurally a no-op,
//   * the invariant backstop that refuses a count regression.
//
// It contains NO streak arithmetic. Every day, deadline and count decision comes
// from `engine.evaluate`; every day key and instant conversion comes from
// `./day.js`.
//
// Concurrency: every mutation is a `db.runTransaction` over the single state
// document. Firestore retries the transaction body on contention, so a losing
// writer RE-READS and RE-EVALUATES instead of clobbering — which is the actual
// fix for the last-writer-wins `set(merge: true)` defect, not merely a mitigation.
//
// Time: `serverNow` is always supplied by the caller (the trigger's `event.time`,
// or `admin.firestore.Timestamp.now()` for the sweeper/repair). A client value
// never reaches this module.
//
// Side effects (awards in 5.7, notifications in 5.4) are NOT performed here. This
// module only reports whether they are permitted, via `sideEffectsAllowed`.
// ═══════════════════════════════════════════════════════════════════════════════

const admin = require("firebase-admin");

const engine = require("./engine");
const {
  MS_PER_DAY,
  instantFrom,
  instantMillis,
  dayKeyFromInstant,
} = require("./day");

/** How long a `recentApplied` entry is retained before pruning. */
const RECENT_APPLIED_WINDOW_MS = 3 * MS_PER_DAY;

/** The accepted `lastEvaluatedBy` values. */
const EvaluationReason = {
  send: "send",
  sweep: "sweep",
  restore: "restore",
  repair: "repair",
  nudge: "nudge",
};

/**
 * Thrown when a write would violate the count-monotonicity invariant. Aborts the
 * transaction, so nothing is persisted.
 */
class StreakInvariantViolation extends Error {
  constructor(message, details) {
    super(message);
    this.name = "StreakInvariantViolation";
    this.details = details || {};
  }
}

// ─── lazy Firestore handle ────────────────────────────────────────────────────
//
// Resolved on first USE, never at require time: `functions/index.js` requires its
// modules above `admin.initializeApp()`, and the tests require this file with no
// credentials at all. This module never initialises the app — it is a consumer of
// whatever default app `index.js` set up.

let _db = null;

/**
 * The Firestore handle, resolved on first call.
 * @returns {import("firebase-admin").firestore.Firestore}
 */
function db() {
  if (_db === null) _db = admin.firestore();
  return _db;
}

/**
 * Test seam: injects a Firestore-like handle (an emulator client, or a fake).
 * @param {*} handle
 */
function setFirestore(handle) {
  _db = handle;
}

// ─── document references ──────────────────────────────────────────────────────

/**
 * The authoritative streak document, `chatRooms/{roomId}/streak/state`.
 *
 * @param {string} roomId
 * @returns {import("firebase-admin").firestore.DocumentReference}
 */
function stateRef(roomId) {
  if (typeof roomId !== "string" || roomId.length === 0) {
    throw new TypeError("roomId is required");
  }
  return db().collection("chatRooms").doc(roomId).collection("streak").doc("state");
}

/**
 * The parent room document, read only to bootstrap `participants`.
 *
 * @param {string} roomId
 * @returns {import("firebase-admin").firestore.DocumentReference}
 */
function roomRef(roomId) {
  if (typeof roomId !== "string" || roomId.length === 0) {
    throw new TypeError("roomId is required");
  }
  return db().collection("chatRooms").doc(roomId);
}

// ─── serialisation ────────────────────────────────────────────────────────────

function _requireReason(reason) {
  if (EvaluationReason[reason] !== reason) {
    throw new TypeError(
      "reason must be one of " + Object.keys(EvaluationReason).join("|")
    );
  }
  return reason;
}

function _requireServerNow(serverNow) {
  const instant = instantFrom(serverNow);
  if (instant === null) {
    throw new TypeError("serverNow is required (server time, never a client value)");
  }
  return instant;
}

function _instantMapToWire(map) {
  const out = {};
  for (const [key, value] of Object.entries(map || {})) {
    const instant = instantFrom(value);
    if (instant !== null) out[key] = instant; // admin converts Date → Timestamp
  }
  return out;
}

/**
 * Drops `recentApplied` entries older than the 3-day window, so the ledger stays
 * a handful of keys rather than growing without bound.
 *
 * @param {object} recentApplied
 * @param {Date} serverNow
 * @returns {object}
 */
function pruneRecentApplied(recentApplied, serverNow) {
  const cutoff = serverNow.getTime() - RECENT_APPLIED_WINDOW_MS;
  const out = {};
  for (const [key, value] of Object.entries(recentApplied || {})) {
    const ms = instantMillis(value);
    if (ms !== null && ms >= cutoff) out[key] = new Date(ms);
  }
  return out;
}

/**
 * The dedupe ledger key for one participation: `"{uid}#{YYYY-MM-DD}"`.
 *
 * @param {string} uid
 * @param {string} dayKey
 * @returns {string}
 */
function dedupeKeyFor(uid, dayKey) {
  return `${uid}#${dayKey}`;
}

/**
 * Flattens the engine's normalised `next` into the exact document to persist:
 * `extraFields` is spread back out to top level (never written as a literal key),
 * and `rev` / `lastEvaluatedAt` / `lastEvaluatedBy` / `recentApplied` — which the
 * engine does not touch — are stamped by this module.
 *
 * Written with a FULL `set()` (no merge): `normalizeState` round-trips every
 * known field plus every unknown one, so the document written is complete and a
 * field cleared by the engine (`brokenAt`, `restoreDeadlineAt`, …) actually
 * clears instead of lingering from a merge.
 *
 * @param {object} next normalised engine output
 * @param {{rev: number, serverNow: Date, reason: string, recentApplied: object}} stamp
 * @returns {object} plain Firestore data
 */
function toWire(next, { rev, serverNow, reason, recentApplied }) {
  const { extraFields, ...known } = next;
  const doc = Object.assign({}, extraFields, known, {
    rev,
    dayZone: next.dayZone,
    dayZoneOffsetMinutes: next.dayZoneOffsetMinutes,
    sendDays: Object.assign({}, next.sendDays), // 'YYYY-MM-DD' strings
    sendInstants: _instantMapToWire(next.sendInstants),
    recentApplied: _instantMapToWire(recentApplied),
    notifiedAt: _instantMapToWire(next.notifiedAt),
    lastEvaluatedAt: serverNow,
    lastEvaluatedBy: reason,
  });
  // Defence in depth: a future engine field named `extraFields` must never leak.
  delete doc.extraFields;
  for (const [key, value] of Object.entries(doc)) {
    if (value === undefined) delete doc[key];
  }
  return doc;
}

// ─── the invariant backstop ───────────────────────────────────────────────────

/**
 * `count` may only fall through an explicit `broken` transition. Anything else is
 * the last-writer-wins clobbering defect resurfacing, so it is logged and the
 * transaction is aborted rather than allowed to persist a lower count.
 *
 * @param {{roomId: string, stored: object, next: object, transitions: Array<string>, reason: string}} args
 * @throws {StreakInvariantViolation}
 */
function assertCountMonotonic({ roomId, stored, next, transitions, reason }) {
  const before = stored.count;
  const after = next.count;
  if (after >= before) return;
  if (transitions.includes(engine.Transition.broken)) return;
  const details = {
    roomId,
    reason,
    storedCount: before,
    nextCount: after,
    transitions,
    rev: stored.rev,
  };
  console.error(
    "[streak] INVARIANT VIOLATION: count regression without a broken transition",
    JSON.stringify(details)
  );
  throw new StreakInvariantViolation(
    `streak count regression for room ${roomId}: ${before} → ${after} without 'broken'`,
    details
  );
}

// ─── the transactional core ───────────────────────────────────────────────────

/**
 * Reads the state document, falls back to the parent room for `participants` on
 * bootstrap (a brand-new room has no state document at all), evaluates, and
 * writes only when something actually changed.
 *
 * @param {object} args
 * @param {string} args.roomId
 * @param {?{uid: string, instant: *}} args.event
 * @param {string} args.reason
 * @param {Date} args.serverNow
 * @param {?Array<string>} args.participants caller-supplied override (the trigger
 *   already has the room document in hand and can skip the extra read)
 * @returns {Promise<object>} result envelope; see `applyParticipation`
 */
async function _runEvaluation({ roomId, event, reason, serverNow, participants }) {
  const ref = stateRef(roomId);
  const parentRef = roomRef(roomId);

  return db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const stored = engine.normalizeState(snap.exists ? snap.data() : null);

    // ── participants: state doc → caller override → parent room ────────────
    let pair = stored.participants;
    if (pair.length !== 2) {
      if (Array.isArray(participants) && participants.length > 0) {
        pair = participants;
      } else {
        const roomSnap = await tx.get(parentRef);
        const roomData = roomSnap.exists ? roomSnap.data() : null;
        pair = roomData && Array.isArray(roomData.participants)
          ? roomData.participants
          : [];
      }
    }

    const evaluation = engine.evaluate({
      stored,
      participants: pair,
      event: event || null,
      serverNow,
    });

    // ── dedupe ledger, for the non-idempotent side effects only ─────────────
    let dedupeKey = null;
    let alreadyApplied = false;
    if (event) {
      const dayKey = dayKeyFromInstant(event.instant, stored.dayZoneOffsetMinutes);
      dedupeKey = dedupeKeyFor(event.uid, dayKey);
      alreadyApplied = Object.prototype.hasOwnProperty.call(
        stored.recentApplied,
        dedupeKey
      );
    }

    if (!evaluation.changed) {
      // Nothing to persist: skip the write entirely. This is the common case for
      // a re-delivered trigger, an extra send on an already-counted day, and a
      // sweep of a room that is still inside its deadline.
      return {
        roomId,
        changed: false,
        wrote: false,
        reason,
        rev: stored.rev,
        stored,
        evaluation,
        transitions: evaluation.transitions,
        milestonesCrossed: [],
        dedupeKey,
        alreadyApplied,
        sideEffectsAllowed: false,
      };
    }

    assertCountMonotonic({
      roomId,
      stored,
      next: evaluation.next,
      transitions: evaluation.transitions,
      reason,
    });

    const rev = stored.rev + 1;
    const recentApplied = pruneRecentApplied(stored.recentApplied, serverNow);
    if (dedupeKey !== null) recentApplied[dedupeKey] = serverNow;

    tx.set(
      ref,
      toWire(evaluation.next, { rev, serverNow, reason, recentApplied })
    );

    // Side effects are permitted exactly once per (uid, day) for a participation,
    // and on any changed no-event evaluation (whose own notification guards live
    // in `notifiedAt`).
    const sideEffectsAllowed = event ? !alreadyApplied : true;

    return {
      roomId,
      changed: true,
      wrote: true,
      reason,
      rev,
      stored,
      evaluation,
      transitions: evaluation.transitions,
      milestonesCrossed: sideEffectsAllowed ? evaluation.milestonesCrossed : [],
      dedupeKey,
      alreadyApplied,
      sideEffectsAllowed,
    };
  });
}

/**
 * Folds one QUALIFYING send into the room's streak.
 *
 * The caller (the `streakOnMessageCreate` trigger) has already dropped reactions,
 * clamped the instant to server time, and confirmed the room is a two-person
 * room. This function does not re-litigate any of that.
 *
 * @param {string} roomId
 * @param {{uid: string, instant: *}} participation server-clamped instant
 * @param {object} [opts]
 * @param {*} [opts.serverNow] defaults to `Timestamp.now()`
 * @param {string} [opts.reason='send']
 * @param {?Array<string>} [opts.participants] skips the parent-room read
 * @returns {Promise<{changed: boolean, wrote: boolean, evaluation: object,
 *   transitions: Array<string>, milestonesCrossed: Array<number>,
 *   sideEffectsAllowed: boolean, dedupeKey: ?string, rev: number}>}
 */
async function applyParticipation(roomId, participation, opts = {}) {
  if (!participation || typeof participation.uid !== "string" || !participation.uid) {
    throw new TypeError("participation.uid is required");
  }
  const instant = instantFrom(participation.instant);
  if (instant === null) {
    throw new TypeError("participation.instant is required");
  }
  const serverNow = _requireServerNow(
    opts.serverNow !== undefined && opts.serverNow !== null
      ? opts.serverNow
      : admin.firestore.Timestamp.now()
  );
  return _runEvaluation({
    roomId,
    event: { uid: participation.uid, instant },
    reason: _requireReason(opts.reason || EvaluationReason.send),
    serverNow,
    participants: opts.participants || null,
  });
}

/**
 * Re-derives the room's streak as of now with NO event — the sweeper, the client
 * nudge endpoint and the repair job all enter here. Persists only when the
 * derivation differs from what is stored (typically: stamping a break, or moving
 * `riskLevel` into `atRisk`/`critical`).
 *
 * @param {string} roomId
 * @param {string} [reason='sweep'] one of `EvaluationReason`
 * @param {object} [opts]
 * @param {*} [opts.serverNow] defaults to `Timestamp.now()`
 * @param {?Array<string>} [opts.participants]
 * @returns {Promise<object>} same envelope as `applyParticipation`
 */
async function reevaluate(roomId, reason = EvaluationReason.sweep, opts = {}) {
  const serverNow = _requireServerNow(
    opts.serverNow !== undefined && opts.serverNow !== null
      ? opts.serverNow
      : admin.firestore.Timestamp.now()
  );
  return _runEvaluation({
    roomId,
    event: null,
    reason: _requireReason(reason),
    serverNow,
    participants: opts.participants || null,
  });
}

module.exports = {
  RECENT_APPLIED_WINDOW_MS,
  EvaluationReason,
  StreakInvariantViolation,
  setFirestore,
  stateRef,
  roomRef,
  dedupeKeyFor,
  pruneRecentApplied,
  toWire,
  assertCountMonotonic,
  applyParticipation,
  reevaluate,
};
