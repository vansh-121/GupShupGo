"use strict";

/**
 * Unit tests for the GupShup AI daily-quota arithmetic.
 *
 * These exercise the pure allowance formula and the "the key IS the reset"
 * rollover without Firestore, the emulator, or an ID token — the same isolation
 * as admob_ssv.unit.test.js.
 *
 * Run: `npm run test:unit`
 */

const assert = require("assert");

const {
  staleKeyedCount,
  aiDailyCount,
  aiRewardDailyCount,
  aiAllowance,
  positiveIntOr,
} = require("../ai/quota");

/** The caps the way `config/ai` carries them. */
const CFG = {
  freeDailyCap: 10,
  proDailyCap: 100,
  rewardCredits: 5,
  rewardDailyCap: 5,
};

const TODAY = "2026-10-03";
const YESTERDAY = "2026-10-02";

describe("staleKeyedCount", () => {
  it("returns the count when the bucket is keyed to the expected period", () => {
    assert.strictEqual(
      staleKeyedCount({ dayKey: TODAY, count: 3 }, "dayKey", TODAY),
      3
    );
  });

  it("returns 0 for a bucket from a different period — that is the reset", () => {
    assert.strictEqual(
      staleKeyedCount({ dayKey: YESTERDAY, count: 9 }, "dayKey", TODAY),
      0
    );
  });

  it("returns 0 for a missing, non-object, or malformed bucket", () => {
    assert.strictEqual(staleKeyedCount(null, "dayKey", TODAY), 0);
    assert.strictEqual(staleKeyedCount(undefined, "dayKey", TODAY), 0);
    assert.strictEqual(staleKeyedCount(42, "dayKey", TODAY), 0);
    assert.strictEqual(staleKeyedCount({ dayKey: TODAY }, "dayKey", TODAY), 0);
    assert.strictEqual(
      staleKeyedCount({ dayKey: TODAY, count: "oops" }, "dayKey", TODAY),
      0
    );
  });

  it("clamps a negative stored count to 0", () => {
    assert.strictEqual(
      staleKeyedCount({ dayKey: TODAY, count: -4 }, "dayKey", TODAY),
      0
    );
  });
});

describe("aiDailyCount / aiRewardDailyCount", () => {
  it("reads today's aiDaily bucket", () => {
    const user = { aiDaily: { dayKey: TODAY, count: 4 } };
    assert.strictEqual(aiDailyCount(user, TODAY), 4);
  });

  it("resets aiDaily when the stored day is not today", () => {
    const user = { aiDaily: { dayKey: YESTERDAY, count: 10 } };
    assert.strictEqual(aiDailyCount(user, TODAY), 0);
  });

  it("reads today's aiRewardDaily bucket and resets stale ones", () => {
    assert.strictEqual(
      aiRewardDailyCount({ aiRewardDaily: { dayKey: TODAY, count: 2 } }, TODAY),
      2
    );
    assert.strictEqual(
      aiRewardDailyCount({ aiRewardDaily: { dayKey: YESTERDAY, count: 2 } }, TODAY),
      0
    );
  });

  it("treats a user with no counters as zero used", () => {
    assert.strictEqual(aiDailyCount({}, TODAY), 0);
    assert.strictEqual(aiDailyCount(null, TODAY), 0);
    assert.strictEqual(aiRewardDailyCount({}, TODAY), 0);
  });
});

describe("aiAllowance", () => {
  it("is the free base for a non-Pro user with no top-ups", () => {
    assert.strictEqual(aiAllowance({}, CFG, TODAY, false), 10);
  });

  it("is the Pro base for a Pro user with no top-ups", () => {
    assert.strictEqual(aiAllowance({}, CFG, TODAY, true), 100);
  });

  it("adds rewardCredits for each top-up earned today", () => {
    const user = { aiRewardDaily: { dayKey: TODAY, count: 3 } };
    // 10 free + 3 top-ups × 5 credits = 25
    assert.strictEqual(aiAllowance(user, CFG, TODAY, false), 25);
  });

  it("caps the top-ups counted at rewardDailyCap", () => {
    const user = { aiRewardDaily: { dayKey: TODAY, count: 99 } };
    // only 5 top-ups count: 10 + 5 × 5 = 35
    assert.strictEqual(aiAllowance(user, CFG, TODAY, false), 35);
  });

  it("ignores top-ups earned on a previous day", () => {
    const user = { aiRewardDaily: { dayKey: YESTERDAY, count: 5 } };
    assert.strictEqual(aiAllowance(user, CFG, TODAY, false), 10);
  });

  it("stacks the Pro base with today's top-ups", () => {
    const user = { aiRewardDaily: { dayKey: TODAY, count: 2 } };
    // 100 + 2 × 5 = 110
    assert.strictEqual(aiAllowance(user, CFG, TODAY, true), 110);
  });
});

describe("positiveIntOr", () => {
  it("accepts a positive integer", () => {
    assert.strictEqual(positiveIntOr(7, 3), 7);
  });

  it("floors a positive float", () => {
    assert.strictEqual(positiveIntOr(7.9, 3), 7);
  });

  it("falls back on zero, negatives, NaN, null, and non-numbers", () => {
    assert.strictEqual(positiveIntOr(0, 3), 3);
    assert.strictEqual(positiveIntOr(-5, 3), 3);
    assert.strictEqual(positiveIntOr(NaN, 3), 3);
    assert.strictEqual(positiveIntOr(null, 3), 3);
    assert.strictEqual(positiveIntOr(undefined, 3), 3);
    assert.strictEqual(positiveIntOr("abc", 3), 3);
  });
});
