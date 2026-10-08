"use strict";

/**
 * GupShup AI — the pure quota arithmetic, kept out of `index.js` so it can be
 * unit-tested without Firestore, the emulator, or an ID token (same split as
 * `ads/ssv.js`). Everything here is a pure function of its arguments; the I/O
 * (reading `config/ai`, reading/writing the user doc, deciding Pro status) stays
 * in `index.js`, which passes the results in.
 *
 * The daily counters use the "the key IS the reset" trick the ad counters use:
 * a bucket keyed to any day other than today reads as zero, so the allowance
 * rolls over at the day boundary with no sweeper job and no stored "resetAt".
 */

/**
 * The count stored in [bucket], but only if the bucket belongs to [expectedKey].
 * A bucket from a different period (or a missing/garbage one) reads as 0 — that
 * is the reset. Mirrors `_staleKeyedCount` in index.js (which serves the ad
 * counters); duplicated here so this module stays dependency-free and testable.
 *
 * @param {?object} bucket e.g. `{ dayKey: '2026-10-03', count: 3 }`
 * @param {string} keyField the field holding the period key (e.g. `'dayKey'`)
 * @param {string} expectedKey the current period key
 * @returns {number}
 */
function staleKeyedCount(bucket, keyField, expectedKey) {
  if (!bucket || typeof bucket !== "object") return 0;
  if (bucket[keyField] !== expectedKey) return 0; // different period → reset
  const count = Number(bucket.count);
  return Number.isFinite(count) && count > 0 ? count : 0;
}

/**
 * How many AI replies [userData] has already been charged for on [dayKey].
 *
 * @param {?object} userData
 * @param {string} dayKey
 * @returns {number}
 */
function aiDailyCount(userData, dayKey) {
  return staleKeyedCount(userData && userData.aiDaily, "dayKey", dayKey);
}

/**
 * How many rewarded AI top-ups [userData] has claimed on [dayKey]. Each one
 * raises today's allowance by `cfg.rewardCredits`.
 *
 * @param {?object} userData
 * @param {string} dayKey
 * @returns {number}
 */
function aiRewardDailyCount(userData, dayKey) {
  return staleKeyedCount(userData && userData.aiRewardDaily, "dayKey", dayKey);
}

/**
 * Today's AI message allowance: the Pro-or-free base plus the rewarded top-ups
 * earned today (each worth `cfg.rewardCredits`, capped at `cfg.rewardDailyCap`
 * top-ups). `isPro` is passed in so this module never touches the subscription
 * mirror — that decision lives in `isProUser` in index.js.
 *
 * @param {?object} userData
 * @param {object} cfg resolved `config/ai` ({ freeDailyCap, proDailyCap, rewardCredits, rewardDailyCap })
 * @param {string} dayKey
 * @param {boolean} isPro
 * @returns {number}
 */
function aiAllowance(userData, cfg, dayKey, isPro) {
  const base = isPro ? cfg.proDailyCap : cfg.freeDailyCap;
  const topUps = Math.min(aiRewardDailyCount(userData, dayKey), cfg.rewardDailyCap);
  return base + topUps * cfg.rewardCredits;
}

/**
 * [value] as a positive integer, or [fallback] when it is missing, non-numeric,
 * zero, or negative. Used to sanitise the caps read from `config/ai`.
 *
 * @param {*} value
 * @param {number} fallback
 * @returns {number}
 */
function positiveIntOr(value, fallback) {
  const n = Number(value);
  return Number.isFinite(n) && n > 0 ? Math.floor(n) : fallback;
}

module.exports = {
  staleKeyedCount,
  aiDailyCount,
  aiRewardDailyCount,
  aiAllowance,
  positiveIntOr,
};
