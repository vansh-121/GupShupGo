// ═══════════════════════════════════════════════════════════════════════════════
// GupShupGo — Streak notifications (the ONLY sender of the v2 streak pushes)
// ═══════════════════════════════════════════════════════════════════════════════
// Design §6. Four events, both participants, one push each:
//
//   notifyStreakWarning(roomId, state, level)   level: 'atRisk' | 'critical'
//   notifyStreakBroken(roomId, state)
//   notifyStreakMilestone(roomId, state, threshold)
//   notifyStreakRestored(roomId, state, restoredByUid)
//
// Three hard rules:
//
//  1. CLAIM BEFORE SEND. Every event is guarded by the `notifiedAt` map on
//     `chatRooms/{roomId}/streak/state`. The guard is a check-and-stamp
//     transaction (`claimNotification`) that runs BEFORE the push. A crash
//     between the stamp and the send therefore costs AT MOST ONE MISSED
//     notification — it can never produce a duplicate. The inverse ordering
//     (send, then stamp) would spam on every retry, which is the worse failure
//     for a notification the user did not ask for.
//
//  2. PREFERENCES ARE SERVER-VISIBLE. The client mirrors its SharedPreferences
//     switches to `users/{uid}.notifPrefs.{key}` (see
//     `NotificationService.setPreference`). A user whose mirror says `false` is
//     skipped here; a user with no mirror at all (old client) is sent to, and
//     the client-side `_shouldShow` gate suppresses it on the device. Only an
//     explicit `false` opts out.
//
//  3. NEVER THROW. A notification failure must not abort the streak transaction
//     that produced it. Everything is caught and logged; every function
//     resolves to a small result envelope instead of rejecting.
//
// Payload contract: identical `type` / `screen` / data keys to the legacy
// `streakBrokenTrigger`, `streakMilestoneTrigger` and `hourlyStreakWarningBatch`
// pushes, so `FcmService` and `NotificationService` route these unchanged. The
// legacy functions are NOT touched here — they stay live for the dual-write
// window, and their null→value edge is mutually exclusive with this module's
// `notifiedAt` guard.
//
// I/O helpers (`sendToUserDevices`, `getUserNames`) are INJECTED by
// `functions/index.js` via `configure()` rather than re-implemented, and rather
// than required from `index.js` (which would be circular).
// ═══════════════════════════════════════════════════════════════════════════════

const admin = require("firebase-admin");

const { instantMillis } = require("./day");
const { AT_RISK_THRESHOLD_MS, RiskLevel, normalizeState } = require("./engine");
const { stateRef } = require("./state");

/** The `notifiedAt` keys this module owns. */
const NotifyKey = {
  atRisk: "atRisk",
  critical: "critical",
  broken: "broken",
  restored: "restored",
  /** @param {number} threshold */
  milestone: (threshold) => `milestone_${threshold}`,
};

/** The `users/{uid}.notifPrefs` keys, mirrored from the client's `NotifPrefs`. */
const PrefKey = {
  streakWarnings: "notif_streak_warnings",
  streakMilestones: "notif_streak_milestones",
};

// ─── injected helpers ─────────────────────────────────────────────────────────

let _deps = null;

/**
 * Wires in the helpers that live in `functions/index.js`. Called once from
 * `index.js` after those helpers are defined.
 *
 * @param {{sendToUserDevices: Function, getUserNames: Function}} deps
 */
function configure(deps) {
  _deps = deps || null;
}

function _requireDeps() {
  if (
    _deps === null ||
    typeof _deps.sendToUserDevices !== "function" ||
    typeof _deps.getUserNames !== "function"
  ) {
    console.error(
      "[streak/notify] not configured — call configure({sendToUserDevices, getUserNames}) from index.js"
    );
    return null;
  }
  return _deps;
}

// ─── lazy Firestore handle ────────────────────────────────────────────────────
//
// Resolved on first USE, never at require time — `index.js` requires this file
// above `admin.initializeApp()`.

let _db = null;

function db() {
  if (_db === null) _db = admin.firestore();
  return _db;
}

/** Test seam, mirroring `state.setFirestore`. */
function setFirestore(handle) {
  _db = handle;
}

// ─── the notifiedAt guard ─────────────────────────────────────────────────────

/**
 * Check-and-stamp, in one transaction over the state document.
 *
 * Grants the claim when `notifiedAt[key]` is absent, or when it is STALE:
 * older than [staleBefore], which means the stamp belongs to a previous streak
 * cycle. Staleness is what keeps "once per room per risk level" from meaning
 * "once per room, ever" — a bond that survives sixty days still gets its
 * warning on day sixty-one.
 *
 * On grant, `notifiedAt[key]` is set to [serverNow] and the transaction commits
 * BEFORE the caller sends. Contention is handled by Firestore's transaction
 * retry: a losing writer re-reads and sees the winner's stamp, so exactly one
 * caller is granted.
 *
 * @param {string} roomId
 * @param {string} key one of `NotifyKey`
 * @param {object} [opts]
 * @param {*} [opts.serverNow] defaults to `Timestamp.now()`
 * @param {*} [opts.staleBefore] instant; an existing stamp older than this is
 *   treated as belonging to a previous cycle. Omit for a once-ever guard.
 * @returns {Promise<boolean>} true when the caller may send
 */
async function claimNotification(roomId, key, opts = {}) {
  if (typeof key !== "string" || key.length === 0) {
    throw new TypeError("key is required");
  }
  const serverNow =
    opts.serverNow !== undefined && opts.serverNow !== null
      ? opts.serverNow
      : admin.firestore.Timestamp.now();
  const nowMs = instantMillis(serverNow);
  if (nowMs === null) throw new TypeError("serverNow is required");
  const staleBeforeMs = instantMillis(opts.staleBefore);

  const ref = stateRef(roomId);
  return db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return false; // no bond, nothing to announce

    const stamps = normalizeState(snap.data()).notifiedAt;
    const previousMs = instantMillis(stamps[key]);
    if (previousMs !== null) {
      const isStale = staleBeforeMs !== null && previousMs < staleBeforeMs;
      if (!isStale) return false;
    }

    tx.update(ref, { [`notifiedAt.${key}`]: new Date(nowMs) });
    return true;
  });
}

// ─── preference mirror ────────────────────────────────────────────────────────

/**
 * Whether [uid] still wants [prefKey] pushes. Only an explicit `false` in the
 * `users/{uid}.notifPrefs` mirror opts out: a missing mirror (old client, or a
 * user who never touched the switches) means "yes", and the client's own
 * `_shouldShow` gate remains the second line of defence.
 *
 * Never throws — a read failure is treated as "allowed".
 *
 * @param {string} uid
 * @param {string} prefKey
 * @returns {Promise<boolean>}
 */
async function isNotificationAllowed(uid, prefKey) {
  try {
    const snap = await db().collection("users").doc(uid).get();
    if (!snap.exists) return false; // no user, no devices
    const prefs = snap.data().notifPrefs;
    if (prefs === null || typeof prefs !== "object") return true;
    return prefs[prefKey] !== false;
  } catch (error) {
    console.error(
      `[streak/notify] notifPrefs read failed for ${uid}:`,
      error && error.message
    );
    return true;
  }
}

/**
 * The subset of [uids] that has not opted out of [prefKey].
 * @param {Array<string>} uids
 * @param {string} prefKey
 * @returns {Promise<Array<string>>}
 */
async function _allowedRecipients(uids, prefKey) {
  const flags = await Promise.all(
    uids.map((uid) => isNotificationAllowed(uid, prefKey))
  );
  return uids.filter((_, i) => flags[i]);
}

// ─── shared plumbing ──────────────────────────────────────────────────────────

function _pairOf(state) {
  const participants = Array.isArray(state && state.participants)
    ? state.participants.filter((uid) => typeof uid === "string" && uid.length > 0)
    : [];
  return Array.from(new Set(participants));
}

function _otherOf(pair, uid) {
  return pair.find((id) => id !== uid) || null;
}

function _isoOrNull(value) {
  const ms = instantMillis(value);
  return ms === null ? null : new Date(ms).toISOString();
}

/** Drops null/undefined values and stringifies the rest — FCM data must be strings. */
function _dataPayload(map) {
  const out = {};
  for (const [key, value] of Object.entries(map)) {
    if (value === null || value === undefined) continue;
    out[key] = String(value);
  }
  return out;
}

const _HIGH_PRIORITY = {
  android: { priority: "high" },
  apns: { headers: { "apns-priority": "10" } },
};

/**
 * Sends one already-claimed event to every allowed recipient, in parallel.
 * A per-user failure is logged and does not affect the others.
 *
 * @param {string} label for logs
 * @param {Array<string>} recipients
 * @param {object} nameMap uid → display name
 * @param {Array<string>} pair
 * @param {(args: {uid: string, otherUid: ?string, otherName: string}) => object} build
 *   returns `{ notification, data }`
 * @returns {Promise<number>} how many users were reached
 */
async function _fanOut(label, recipients, nameMap, pair, build) {
  const deps = _requireDeps();
  if (deps === null) return 0;

  const results = await Promise.all(
    recipients.map(async (uid) => {
      try {
        const otherUid = _otherOf(pair, uid);
        const otherName =
          (otherUid && nameMap[otherUid]) || "your friend";
        const { notification, data } = build({ uid, otherUid, otherName });
        const result = await deps.sendToUserDevices(uid, (token) =>
          Object.assign(
            {
              token,
              notification,
              data: _dataPayload(data),
            },
            _HIGH_PRIORITY
          )
        );
        return result && result.ok ? 1 : 0;
      } catch (error) {
        console.error(
          `[streak/notify] ${label} push failed for ${uid}:`,
          error && error.message
        );
        return 0;
      }
    })
  );
  return results.reduce((a, b) => a + b, 0);
}

/**
 * The common shape of every exported notifier: resolve participants → filter by
 * preference → CLAIM → send. Never rejects.
 *
 * @param {object} args
 * @param {string} args.roomId
 * @param {object} args.state normalised (or raw) state document
 * @param {string} args.key `notifiedAt` key
 * @param {?*} args.staleBefore see `claimNotification`
 * @param {string} args.prefKey
 * @param {string} args.label
 * @param {*} [args.serverNow]
 * @param {Function} args.build see `_fanOut`
 * @returns {Promise<{sent: number, claimed: boolean, skipped: ?string}>}
 */
async function _notify({
  roomId,
  state,
  key,
  staleBefore,
  prefKey,
  label,
  serverNow,
  build,
}) {
  try {
    if (typeof roomId !== "string" || roomId.length === 0) {
      return { sent: 0, claimed: false, skipped: "no-room" };
    }
    const pair = _pairOf(state);
    if (pair.length !== 2) {
      return { sent: 0, claimed: false, skipped: "not-a-pair" };
    }

    // Preference check first: when nobody can receive it there is nothing to
    // guard, so the claim is not burned and a later re-opt-in still works.
    const recipients = await _allowedRecipients(pair, prefKey);
    if (recipients.length === 0) {
      return { sent: 0, claimed: false, skipped: "opted-out" };
    }

    // ── claim, then send (never the other way round) ─────────────────────
    const claimed = await claimNotification(roomId, key, {
      serverNow,
      staleBefore,
    });
    if (!claimed) {
      return { sent: 0, claimed: false, skipped: "already-notified" };
    }

    const deps = _requireDeps();
    if (deps === null) return { sent: 0, claimed: true, skipped: "unconfigured" };

    const nameMap = await deps.getUserNames(pair);
    const sent = await _fanOut(label, recipients, nameMap, pair, build);
    console.log(
      `[streak/notify] ${label} room=${roomId} key=${key} sent=${sent}/${recipients.length}`
    );
    return { sent, claimed: true, skipped: null };
  } catch (error) {
    // Rule 3: a notification failure never propagates to the streak caller.
    console.error(
      `[streak/notify] ${label} failed for room ${roomId}:`,
      error && error.stack ? error.stack : error
    );
    return { sent: 0, claimed: false, skipped: "error" };
  }
}

// ─── 1. warning (atRisk / critical) ───────────────────────────────────────────

/**
 * "Your streak needs a message today" / "last chance".
 *
 * Guard: one push per room per risk level per streak CYCLE. The stale cutoff is
 * `deadlineAt - 24h` — the instant the current cycle's `atRisk` window opens —
 * so a stamp from any earlier cycle is re-armed and a stamp from this cycle is
 * not.
 *
 * @param {string} roomId
 * @param {object} state the state document (post-evaluation)
 * @param {string} level `'atRisk'` or `'critical'`
 * @param {object} [opts] `{serverNow}`
 * @returns {Promise<{sent: number, claimed: boolean, skipped: ?string}>}
 */
async function notifyStreakWarning(roomId, state, level, opts = {}) {
  if (level !== RiskLevel.atRisk && level !== RiskLevel.critical) {
    console.error(`[streak/notify] bad warning level: ${String(level)}`);
    return { sent: 0, claimed: false, skipped: "bad-level" };
  }

  const count = Number(state && state.count) || 0;
  const deadlineMs = instantMillis(state && state.deadlineAt);
  const isCritical = level === RiskLevel.critical;

  return _notify({
    roomId,
    state,
    key: isCritical ? NotifyKey.critical : NotifyKey.atRisk,
    staleBefore:
      deadlineMs === null ? null : new Date(deadlineMs - AT_RISK_THRESHOLD_MS),
    prefKey: PrefKey.streakWarnings,
    label: `warning:${level}`,
    serverNow: opts.serverNow,
    build: ({ otherUid, otherName }) => ({
      notification: {
        title: isCritical ? "🔥 Last Chance!" : "⚠️ Streak at Risk!",
        body: isCritical
          ? `Your 🔥${count} streak with ${otherName} is about to break! Send a message NOW.`
          : `Your 🔥${count} streak with ${otherName} needs a message today!`,
      },
      data: {
        type: "streak_warning",
        screen: "chat",
        chatRoomId: roomId,
        contactId: otherUid,
        riskLevel: level,
        streakCount: count,
        deadlineAt: _isoOrNull(state && state.deadlineAt),
      },
    }),
  });
}

// ─── 2. broken ────────────────────────────────────────────────────────────────

/**
 * "Your streak broke — restore it within 24 hours."
 *
 * Guard: one push per BREAK. The stale cutoff is this break's `brokenAt`, so a
 * stamp from an earlier break is re-armed.
 *
 * @param {string} roomId
 * @param {object} state the state document AFTER the break was stamped
 * @param {object} [opts] `{serverNow}`
 * @returns {Promise<{sent: number, claimed: boolean, skipped: ?string}>}
 */
async function notifyStreakBroken(roomId, state, opts = {}) {
  const previousCount = Number(state && state.previousCount) || 0;
  if (previousCount <= 0) {
    return { sent: 0, claimed: false, skipped: "nothing-broken" };
  }

  return _notify({
    roomId,
    state,
    key: NotifyKey.broken,
    staleBefore: state && (state.brokenAt || state.deadlineAt),
    prefKey: PrefKey.streakWarnings,
    label: "broken",
    serverNow: opts.serverNow,
    build: ({ otherUid, otherName }) => ({
      notification: {
        title: "💔 Streak Broken",
        body: `Your ${previousCount}-day streak with ${otherName} just broke! Restore it within 24 hours.`,
      },
      data: {
        type: "streak_broken",
        screen: "chat",
        chatRoomId: roomId,
        contactId: otherUid,
        previousStreakCount: previousCount,
        restoreDeadlineAt: _isoOrNull(state && state.restoreDeadlineAt),
      },
    }),
  });
}

// ─── 3. milestone ─────────────────────────────────────────────────────────────

function _milestoneCopy(threshold) {
  if (threshold >= 365) return { emoji: "👑", title: "Year-long Legend!" };
  if (threshold >= 100) return { emoji: "🏆", title: "Century Streak!" };
  if (threshold >= 30) return { emoji: "💎", title: "Month Milestone!" };
  return { emoji: "🔥", title: "Week Streak!" };
}

/**
 * "N days straight!" — one push per room per threshold, EVER (no stale cutoff:
 * a threshold is crossed once per bond, exactly like `milestonesAwarded`).
 *
 * @param {string} roomId
 * @param {object} state
 * @param {number} threshold one of 7 / 30 / 100 / 365
 * @param {object} [opts] `{serverNow}`
 * @returns {Promise<{sent: number, claimed: boolean, skipped: ?string}>}
 */
async function notifyStreakMilestone(roomId, state, threshold, opts = {}) {
  const value = Number(threshold);
  if (!Number.isFinite(value) || value <= 0) {
    console.error(`[streak/notify] bad milestone threshold: ${String(threshold)}`);
    return { sent: 0, claimed: false, skipped: "bad-threshold" };
  }
  const milestone = Math.trunc(value);
  const { emoji, title } = _milestoneCopy(milestone);

  return _notify({
    roomId,
    state,
    key: NotifyKey.milestone(milestone),
    staleBefore: null, // once per room per threshold, forever
    prefKey: PrefKey.streakMilestones,
    label: `milestone:${milestone}`,
    serverNow: opts.serverNow,
    build: ({ otherUid, otherName }) => ({
      notification: {
        title: `${emoji} ${title}`,
        body: `${milestone} days straight with ${otherName}! You're on fire! 🔥`,
      },
      data: {
        type: "streak_milestone",
        screen: "arcade",
        milestoneCount: milestone,
        chatRoomId: roomId,
        contactId: otherUid,
      },
    }),
  });
}

// ─── 4. restored ──────────────────────────────────────────────────────────────

/**
 * "Your streak is back." Both participants are told; the copy differs so the
 * restorer sees a confirmation and the other side sees who paid for it.
 *
 * Guard: one push per RESTORE. The stale cutoff is `restoredAt` (falling back to
 * [opts.serverNow]/now), so each restore re-arms and a retry of the same restore
 * does not.
 *
 * @param {string} roomId
 * @param {object} state the state document AFTER the restore
 * @param {string} restoredByUid who paid
 * @param {object} [opts] `{serverNow}`
 * @returns {Promise<{sent: number, claimed: boolean, skipped: ?string}>}
 */
async function notifyStreakRestored(roomId, state, restoredByUid, opts = {}) {
  const count = Number(state && state.count) || 0;
  const restoredAt =
    (state && (state.restoredAt || null)) ||
    opts.serverNow ||
    admin.firestore.Timestamp.now();

  return _notify({
    roomId,
    state,
    key: NotifyKey.restored,
    staleBefore: restoredAt,
    prefKey: PrefKey.streakWarnings,
    label: "restored",
    serverNow: opts.serverNow,
    build: ({ uid, otherUid, otherName }) => {
      const isRestorer = uid === restoredByUid;
      return {
        notification: {
          title: "❤️‍🔥 Streak Restored",
          body: isRestorer
            ? `Your ${count}-day streak with ${otherName} is back. Keep it alive!`
            : `${otherName} restored your ${count}-day streak. Say thanks with a message!`,
        },
        data: {
          type: "streak_restored",
          screen: "chat",
          chatRoomId: roomId,
          contactId: otherUid,
          streakCount: count,
          restoredBy: restoredByUid,
        },
      };
    },
  });
}

module.exports = {
  NotifyKey,
  PrefKey,
  configure,
  setFirestore,
  claimNotification,
  isNotificationAllowed,
  notifyStreakWarning,
  notifyStreakBroken,
  notifyStreakMilestone,
  notifyStreakRestored,
};
