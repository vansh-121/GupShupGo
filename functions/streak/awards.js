// ═══════════════════════════════════════════════════════════════════════════════
// GupShupGo — Streak milestone awards and `longestStreak` raising
// ═══════════════════════════════════════════════════════════════════════════════
// The ONLY writer of `users/{uid}/streakAwards/*`, and the only place that pays a
// streak milestone or raises `users/{uid}.longestStreak`. Design §9.
//
// It exists because `./engine.js` deliberately REPORTS `milestonesCrossed` and a
// `longestRaised` transition without paying anything, and `./state.js` owns only
// the state document. This module owns the non-idempotent economy side effects and
// makes them idempotent:
//
//   * the payout ledger is `users/{uid}/streakAwards/{roomId}_{threshold}`, written
//     with `create` — NOT `set`. A create on an existing document fails the whole
//     transaction, so a replay, a duplicate trigger delivery, a second region, or
//     two concurrent evaluations can never double-pay. That failure is the
//     idempotency key, not a nicety on top of one,
//   * `gupPoints` is incremented in the SAME transaction as the create, so points
//     without a ledger row (or a ledger row without points) is not a reachable
//     state,
//   * `longestStreak` is a `max()`, which is idempotent by construction.
//
// BOTH participants are awarded. The legacy path
// (`GamificationService.handleStreakMilestone`) awarded the SENDER only, on an
// EXACT count match, unawaited, with no ledger — defects 1.21 / 1.22. The point
// values here are transcribed from that method so the economy does not shift.
// ═══════════════════════════════════════════════════════════════════════════════

const admin = require("firebase-admin");

const engine = require("./engine");
const state = require("./state");

// ─── the award table ──────────────────────────────────────────────────────────
//
// Transcribed verbatim from `GamificationService.handleStreakMilestone`
// (lib/services/gamification_service.dart): 25 at 7 with the `streak_warrior`
// badge, 50 at 30, 100 at 100.
//
// ┌─ TODO(product): the 365-day milestone point value is a BLOCKED PRODUCT
// │  DECISION. Design §9 leaves it "to be set at implementation time" and task
// │  5.7 says explicitly: do not pick a value. So 365 is deliberately ABSENT
// │  from this table.
// │
// │  Consequences, all intended:
// │    * `engine.MILESTONES` still contains 365 and `evaluate` still emits the
// │      crossing — that is correct, the crossing is a fact about the streak,
// │      not about the economy,
// │    * this module SKIPS a threshold with no configured value: no ledger row,
// │      no points, no crash, and no `milestonesAwarded` entry. The crossing
// │      therefore stays un-awarded and will be re-emitted, so once a value is
// │      agreed a single `awardCrossedUpTo` pass pays every bond that has
// │      already reached 365 — nothing is lost by waiting,
// │    * awarding 0 points would burn the crossing permanently, which is why the
// │      skip is a skip and not a zero.
// └─ Add `365: { points: <agreed value> }` here, and nowhere else, to unblock.
const MILESTONE_AWARDS = Object.freeze({
  7: Object.freeze({ points: 25, badge: "streak_warrior" }),
  30: Object.freeze({ points: 50 }),
  100: Object.freeze({ points: 100 }),
});

/** Thresholds that currently have an agreed point value, ascending. */
const AWARDABLE_MILESTONES = Object.freeze(
  Object.keys(MILESTONE_AWARDS)
    .map((key) => Number.parseInt(key, 10))
    .sort((a, b) => a - b)
);

/**
 * The award configuration for [threshold], or `null` when the value is not
 * configured (today: 365 — see the TODO above). A `null` here means SKIP, never
 * "award nothing and mark it done".
 *
 * @param {number} threshold
 * @returns {?{points: number, badge?: string}}
 */
function awardFor(threshold) {
  const key = Number.parseInt(threshold, 10);
  if (!Number.isFinite(key)) return null;
  return Object.prototype.hasOwnProperty.call(MILESTONE_AWARDS, key)
    ? MILESTONE_AWARDS[key]
    : null;
}

/**
 * The Gup Points paid at [threshold], or 0 when unconfigured. Read-only helper for
 * callers that want to describe an award (notification copy, admin dry runs).
 *
 * @param {number} threshold
 * @returns {number}
 */
function pointsFor(threshold) {
  const award = awardFor(threshold);
  return award === null ? 0 : award.points;
}

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
 * Test seam. Forwarded to `./state.js` as well, so one call configures both
 * modules and they cannot end up talking to different handles.
 * @param {*} handle
 */
function setFirestore(handle) {
  _db = handle;
  state.setFirestore(handle);
}

/**
 * `users/{uid}`.
 * @param {string} uid
 */
function userRef(uid) {
  if (typeof uid !== "string" || uid.length === 0) {
    throw new TypeError("uid is required");
  }
  return db().collection("users").doc(uid);
}

/**
 * `users/{uid}/streakAwards/{roomId}_{threshold}` — the payout ledger row whose
 * mere existence means "already paid".
 *
 * @param {string} uid
 * @param {string} roomId
 * @param {number} threshold
 */
function awardRef(uid, roomId, threshold) {
  if (typeof roomId !== "string" || roomId.length === 0) {
    throw new TypeError("roomId is required");
  }
  return userRef(uid).collection("streakAwards").doc(`${roomId}_${threshold}`);
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

function _isAlreadyExists(error) {
  if (!error) return false;
  // Firestore surfaces ALREADY_EXISTS as gRPC code 6.
  return (
    error.code === 6 ||
    error.code === "already-exists" ||
    /already exists/i.test(String(error.message || ""))
  );
}

function _serverNowOf(opts) {
  const supplied = opts && opts.serverNow;
  if (supplied === undefined || supplied === null) {
    return admin.firestore.Timestamp.now();
  }
  return supplied;
}

function _emptyResult(roomId, note) {
  return {
    roomId,
    awarded: [],
    thresholdsAwarded: [],
    skippedUnconfigured: [],
    alreadyAwarded: [],
    pointsByUid: {},
    longestStreakRaised: {},
    milestonesRecorded: [],
    wrote: false,
    note: note || null,
  };
}

// ─── the transactional core ───────────────────────────────────────────────────

/**
 * Awards [thresholds] to both participants and raises `longestStreak` to
 * `max(current, count)`, in ONE transaction spanning both user documents, their
 * ledger rows and the state document.
 *
 * Why one transaction: the create-guard only prevents a double payout if the
 * points ride along with it. Splitting them would make "crashed after create,
 * before increment" a silent underpay, and "crashed after increment" a silent
 * overpay.
 *
 * Ordering within the transaction: every read happens before any write, as
 * Firestore requires. Existing ledger rows are read and filtered out so the
 * ordinary replay is a cheap no-op rather than an aborted transaction; `create`
 * is still used for the rows we do write, so a racer that slipped in between the
 * read and the commit aborts us instead of paying twice.
 *
 * @param {object} args
 * @param {string} args.roomId
 * @param {Array<string>} args.participants
 * @param {Array<number>} args.thresholds crossed thresholds to consider
 * @param {number} args.count the streak count that produced the crossing
 * @param {boolean} args.raiseLongest
 * @param {*} args.serverNow
 * @returns {Promise<object>}
 */
async function _runAwards({
  roomId,
  participants,
  thresholds,
  count,
  raiseLongest,
  serverNow,
}) {
  const pair = _pairOf(participants);
  if (pair.length !== 2) {
    return _emptyResult(roomId, "not-a-two-person-room");
  }

  const requested = Array.from(
    new Set((thresholds || []).map((t) => _asInt(t, NaN)).filter(Number.isFinite))
  ).sort((a, b) => a - b);

  const payable = requested.filter((t) => awardFor(t) !== null);
  const skippedUnconfigured = requested.filter((t) => awardFor(t) === null);

  if (payable.length === 0 && !raiseLongest) {
    const result = _emptyResult(roomId, "nothing-to-do");
    result.skippedUnconfigured = skippedUnconfigured;
    return result;
  }

  const sRef = state.stateRef(roomId);

  const committed = await db().runTransaction(async (tx) => {
    // ── reads ────────────────────────────────────────────────────────────────
    // The state document is read so this transaction CONTENDS with `state.js`'s
    // evaluation transaction on the same document. Without the read our
    // `milestonesAwarded` append could be clobbered by a concurrent full `set()`.
    const stateSnap = await tx.get(sRef);
    const storedState = engine.normalizeState(
      stateSnap.exists ? stateSnap.data() : null
    );

    const userSnaps = {};
    for (const uid of pair) {
      userSnaps[uid] = await tx.get(userRef(uid));
    }

    const existing = {}; // uid → Set<threshold>
    for (const uid of pair) {
      existing[uid] = new Set();
      for (const threshold of payable) {
        const snap = await tx.get(awardRef(uid, roomId, threshold));
        if (snap.exists) existing[uid].add(threshold);
      }
    }

    // ── writes ───────────────────────────────────────────────────────────────
    const awarded = [];
    const alreadyAwarded = [];
    const pointsByUid = {};
    const longestStreakRaised = {};

    for (const uid of pair) {
      const data = userSnaps[uid].exists ? userSnaps[uid].data() || {} : null;
      if (data === null) {
        // No user document: `update` would fail the whole transaction and block
        // the partner's award too. Skip this uid, keep going; the repair job can
        // pick it up if the document appears later (the crossing is not recorded
        // in `milestonesAwarded` unless at least one uid was paid).
        console.warn(
          "[streak] award skipped, missing user document",
          JSON.stringify({ roomId, uid })
        );
        continue;
      }

      const updates = {};
      let pointsDelta = 0;
      const badges = [];

      for (const threshold of payable) {
        if (existing[uid].has(threshold)) {
          alreadyAwarded.push({ uid, threshold });
          continue;
        }
        const award = awardFor(threshold);
        tx.create(awardRef(uid, roomId, threshold), {
          roomId,
          threshold,
          awardedAt: serverNow,
          points: award.points,
        });
        pointsDelta += award.points;
        if (award.badge) badges.push(award.badge);
        awarded.push({ uid, threshold, points: award.points });
      }

      if (pointsDelta > 0) {
        // `increment` rather than read-modify-write: another writer
        // (`handleMessageSent`, a challenge payout) may be moving `gupPoints`
        // outside this transaction.
        updates.gupPoints = admin.firestore.FieldValue.increment(pointsDelta);
        pointsByUid[uid] = (pointsByUid[uid] || 0) + pointsDelta;
      }
      if (badges.length > 0) {
        updates.badges = admin.firestore.FieldValue.arrayUnion(...badges);
      }

      if (raiseLongest) {
        const current = _asInt(data.longestStreak, 0);
        if (count > current) {
          updates.longestStreak = count;
          longestStreakRaised[uid] = count;
        }
      }

      if (Object.keys(updates).length > 0) {
        tx.update(userRef(uid), updates);
      }
    }

    // ── record the crossing so the engine stops re-emitting it ───────────────
    //
    // The engine filters `milestonesCrossed` against `milestonesAwarded` and
    // never appends to it, so without this the same crossing is reported on
    // every evaluation forever.
    //
    // Only thresholds actually PAID in this transaction are recorded, and only
    // in this same transaction — so a crash between "award" and "record" is not
    // a reachable state at all. Even if it were, the `create` guard above means
    // the re-emitted crossing pays nothing the second time.
    const milestonesRecorded = Array.from(
      new Set(awarded.map((entry) => entry.threshold))
    ).sort((a, b) => a - b);
    if (milestonesRecorded.length > 0) {
      const merged = Array.from(
        new Set(storedState.milestonesAwarded.concat(milestonesRecorded))
      ).sort((a, b) => a - b);
      // `update` on a document the engine has certainly created by now; `set`
      // with merge would resurrect a deleted state document as a fragment.
      tx.update(sRef, { milestonesAwarded: merged });
    }

    return {
      roomId,
      awarded,
      thresholdsAwarded: milestonesRecorded,
      skippedUnconfigured,
      alreadyAwarded,
      pointsByUid,
      longestStreakRaised,
      milestonesRecorded,
      wrote:
        awarded.length > 0 || Object.keys(longestStreakRaised).length > 0,
      note: null,
    };
  });

  return committed;
}

// ─── entry points ─────────────────────────────────────────────────────────────

/**
 * The trigger / sweeper path: applies the side effects a `state.js` result
 * envelope reports.
 *
 * Awards nothing when `sideEffectsAllowed` is false — that flag is the (uid, day)
 * dedupe from `recentApplied`, and `state.js` has already emptied
 * `milestonesCrossed` in that case.
 *
 * NOTE (engine constraint): `evaluate` moves the count by +1 or resets it, so
 * `milestonesCrossed` here can only ever hold ONE threshold. A count that JUMPS
 * (a restore 5 → 12, a repair) does not produce the skipped crossings — use
 * `awardCrossedUpTo` for those.
 *
 * @param {object} result envelope from `state.applyParticipation` / `state.reevaluate`
 * @param {object} [opts]
 * @param {*} [opts.serverNow]
 * @returns {Promise<object>}
 */
async function applyAwards(result, opts = {}) {
  if (!result || typeof result.roomId !== "string") {
    throw new TypeError("result envelope with a roomId is required");
  }
  if (!result.changed || !result.sideEffectsAllowed) {
    return _emptyResult(result.roomId, "side-effects-not-allowed");
  }

  const next = (result.evaluation && result.evaluation.next) || {};
  const count = _asInt(next.count, 0);
  const transitions = Array.isArray(result.transitions) ? result.transitions : [];

  return _runAwards({
    roomId: result.roomId,
    participants: next.participants || [],
    thresholds: result.milestonesCrossed || [],
    count,
    raiseLongest: transitions.includes(engine.Transition.longestRaised),
    serverNow: _serverNowOf(opts),
  });
}

/**
 * The JUMP path: awards every configured, not-yet-awarded threshold `t <= count`.
 *
 * Needed because `evaluate` can only ever report a single crossing (it moves the
 * count by one). A restore that returns a bond to 12, or a repair that
 * reconstructs 5 → 12 from history, must still pay 7. Called by the restore
 * endpoint (5.8) and the repair job (9.1).
 *
 * `longestStreak` is raised to `max(current, count)` unconditionally here: the
 * caller has just moved the count itself, so there is no `longestRaised`
 * transition to consult, and the raise is idempotent regardless.
 *
 * @param {string} roomId
 * @param {?object} storedState state document (raw or normalised) — used for
 *   `participants` and `milestonesAwarded`; the transaction re-reads the
 *   authoritative copy either way
 * @param {number} count the count the bond now stands at
 * @param {object} [opts]
 * @param {*} [opts.serverNow]
 * @param {?Array<string>} [opts.participants] override when [storedState] is null
 * @returns {Promise<object>}
 */
async function awardCrossedUpTo(roomId, storedState, count, opts = {}) {
  if (typeof roomId !== "string" || roomId.length === 0) {
    throw new TypeError("roomId is required");
  }
  const normalized = engine.normalizeState(storedState || null);
  const total = _asInt(count, 0);

  const participants =
    normalized.participants.length === 2
      ? normalized.participants
      : _pairOf(opts.participants || []);

  const thresholds = engine.MILESTONES.filter(
    (threshold) =>
      threshold <= total && !normalized.milestonesAwarded.includes(threshold)
  );

  return _runAwards({
    roomId,
    participants,
    thresholds,
    count: total,
    raiseLongest: total > 0,
    serverNow: _serverNowOf(opts),
  });
}

/**
 * `applyAwards` / `awardCrossedUpTo` with the ALREADY_EXISTS abort swallowed.
 *
 * A lost create race means someone else paid this exact (uid, roomId, threshold)
 * concurrently — the correct outcome, not an error worth failing a trigger over.
 * Anything else propagates.
 *
 * @param {() => Promise<object>} run
 * @param {string} roomId
 * @returns {Promise<object>}
 */
async function _swallowRaces(run, roomId) {
  try {
    return await run();
  } catch (error) {
    if (_isAlreadyExists(error)) {
      console.log(
        "[streak] award race lost, already paid elsewhere",
        JSON.stringify({ roomId })
      );
      return _emptyResult(roomId, "already-awarded-elsewhere");
    }
    throw error;
  }
}

/**
 * `applyAwards`, tolerant of a lost create race. This is what the trigger and the
 * sweeper should call: a milestone payout must never fail a message write.
 *
 * @param {object} result
 * @param {object} [opts]
 * @returns {Promise<object>}
 */
function applyAwardsSafely(result, opts = {}) {
  const roomId = result && result.roomId;
  return _swallowRaces(() => applyAwards(result, opts), roomId);
}

/**
 * `awardCrossedUpTo`, tolerant of a lost create race.
 *
 * @param {string} roomId
 * @param {?object} storedState
 * @param {number} count
 * @param {object} [opts]
 * @returns {Promise<object>}
 */
function awardCrossedUpToSafely(roomId, storedState, count, opts = {}) {
  return _swallowRaces(
    () => awardCrossedUpTo(roomId, storedState, count, opts),
    roomId
  );
}

module.exports = {
  MILESTONE_AWARDS,
  AWARDABLE_MILESTONES,
  awardFor,
  pointsFor,
  setFirestore,
  userRef,
  awardRef,
  applyAwards,
  applyAwardsSafely,
  awardCrossedUpTo,
  awardCrossedUpToSafely,
};
