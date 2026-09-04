// Unit tests for the pure decisions in `tools/reconcile_gup_points.js`.
//
// The script's Firestore reads need a live project, but the parts that can be
// silently WRONG are all pure: the "never lower a total" rule, the challenge
// re-derivation against the target table, and argument parsing. A sign error or a
// bad threshold in any of them produces a plausible number rather than a crash,
// which is exactly the failure this file is here to catch.
//
//   cd functions && npx mocha ../tools/test/reconcile_gup_points.unit.test.js

"use strict";

const assert = require("assert");

const {
  parseArgs,
  deriveChallenges,
  planPointsWrite,
  toDate,
  asInt,
  POINTS,
  CHALLENGES,
} = require("../reconcile_gup_points");

describe("planPointsWrite — never lowers a total it cannot prove", () => {
  it("writes when the computed figure is higher", () => {
    const plan = planPointsWrite(0, 4820);
    assert.strictEqual(plan.write, true);
    assert.strictEqual(plan.value, 4820);
  });

  it("refuses to lower a total", () => {
    // The case that matters: restore spends left no ledger, so undercounting is
    // expected. Lowering here would repeat the very bug this script repairs.
    const plan = planPointsWrite(5000, 4820);
    assert.strictEqual(plan.write, false);
    assert.strictEqual(plan.value, 5000);
    assert.match(plan.reason, /never lowers/);
  });

  it("refuses when the figures are equal, so a no-op writes nothing", () => {
    const plan = planPointsWrite(4820, 4820);
    assert.strictEqual(plan.write, false);
  });

  it("treats a missing stored value as zero rather than NaN", () => {
    const plan = planPointsWrite(undefined, 100);
    assert.strictEqual(plan.write, true);
    assert.strictEqual(plan.value, 100);
  });

  it("does not write a NaN target over a real total", () => {
    const plan = planPointsWrite(500, Number.NaN);
    assert.strictEqual(plan.write, false);
    assert.strictEqual(plan.value, 500);
  });
});

describe("deriveChallenges — pays a bonus only at the real threshold", () => {
  it("credits a challenge whose recounted progress reaches the target", () => {
    const out = deriveChallenges({ messages_sent: 100 }, false);
    assert.ok(out.completed.includes("messages_sent"));
    assert.ok(out.badges.includes("chatterbox"));
    assert.strictEqual(out.bonus, 50);
  });

  it("does not credit one short of the target", () => {
    const out = deriveChallenges({ messages_sent: 99 }, false);
    assert.deepStrictEqual(out.completed, []);
    assert.strictEqual(out.bonus, 0);
  });

  it("sums several completed challenges", () => {
    const out = deriveChallenges(
      { messages_sent: 250, voice_notes: 12, reactions_given: 30 },
      false
    );
    // 50 (chatterbox) + 50 (vocalist) + 60 (social butterfly)
    assert.strictEqual(out.bonus, 160);
    assert.strictEqual(out.completed.length, 3);
  });

  it("skips night_messages unless the deep scan ran", () => {
    // Without --deep the night count is always 0, so crediting it would be a
    // guess dressed up as a recount.
    const shallow = deriveChallenges({ night_messages: 50 }, false);
    assert.ok(!shallow.completed.includes("night_messages"));
    assert.ok(shallow.skipped.includes("night_messages"));

    const deep = deriveChallenges({ night_messages: 50 }, true);
    assert.ok(deep.completed.includes("night_messages"));
    assert.strictEqual(deep.bonus, 75);
    assert.ok(deep.badges.includes("night_owl"));
  });

  it("never credits a challenge with no surviving source", () => {
    // status_posts and mesh_messages cannot be recounted at any depth, so no
    // amount of progress should pay them.
    for (const deep of [false, true]) {
      const out = deriveChallenges(
        { status_posts: 99, mesh_messages: 99, weekly_voice: 99 },
        deep
      );
      assert.deepStrictEqual(out.completed, []);
      assert.strictEqual(out.bonus, 0);
    }
  });

  it("treats absent progress as zero", () => {
    const out = deriveChallenges({}, true);
    assert.strictEqual(out.bonus, 0);
  });
});

describe("the transcribed constants match the app", () => {
  // These values live in Dart and are duplicated in the script. A drift here
  // makes every figure it prints quietly wrong, so they are pinned.
  it("keeps the point values from GamificationService and CallLogService", () => {
    assert.strictEqual(POINTS.message, 1);
    assert.strictEqual(POINTS.call, 10);
    assert.strictEqual(POINTS.reactionReceived, 5);
    assert.strictEqual(POINTS.statusPost, 3);
  });

  it("keeps the challenge targets and rewards from gamification_data.dart", () => {
    const byKey = Object.fromEntries(CHALLENGES.map((c) => [c.key, c]));
    assert.strictEqual(byKey.messages_sent.target, 100);
    assert.strictEqual(byKey.messages_sent.reward, 50);
    assert.strictEqual(byKey.voice_notes.target, 10);
    assert.strictEqual(byKey.voice_notes.reward, 50);
    assert.strictEqual(byKey.reactions_given.target, 25);
    assert.strictEqual(byKey.reactions_given.reward, 60);
    assert.strictEqual(byKey.night_messages.target, 10);
    assert.strictEqual(byKey.night_messages.reward, 75);
    assert.strictEqual(byKey.status_posts.target, 5);
    assert.strictEqual(byKey.mesh_messages.target, 10);
  });

  it("every challenge declares its recountability explicitly", () => {
    // An undefined `recountable` would be falsy and silently skip the challenge,
    // which looks identical to a deliberate exclusion.
    for (const c of CHALLENGES) {
      assert.ok(
        c.recountable === true || c.recountable === false || c.recountable === "deep",
        `${c.key} has an unclear recountable value: ${c.recountable}`
      );
    }
  });
});

describe("parseArgs", () => {
  it("defaults to a dry run with no estimates", () => {
    const o = parseArgs(["--uid", "abc"]);
    assert.strictEqual(o.uid, "abc");
    assert.strictEqual(o.apply, false);
    assert.strictEqual(o.estimates, false);
    assert.strictEqual(o.deep, false);
    assert.strictEqual(o.force, false);
  });

  it("lowercases a handle, matching the reservation doc id", () => {
    assert.strictEqual(parseArgs(["--handle", "  VanSh "]).handle, "vansh");
  });

  it("reads the flags", () => {
    const o = parseArgs(["--uid", "u", "--estimates", "--deep", "--apply", "--force"]);
    assert.ok(o.estimates && o.deep && o.apply && o.force);
  });

  it("defaults the night offset to IST", () => {
    assert.strictEqual(parseArgs(["--uid", "u"]).nightOffsetMinutes, 330);
    assert.strictEqual(parseArgs(["--uid", "u", "--night-offset", "0"]).nightOffsetMinutes, 0);
  });

  it("rejects an unknown flag rather than ignoring it", () => {
    // A typo'd --aply must not silently become a dry run the operator thinks wrote.
    assert.throws(() => parseArgs(["--aply"]), /unknown argument/);
  });

  it("rejects a flag missing its value", () => {
    assert.throws(() => parseArgs(["--uid"]), /needs a value/);
  });
});

describe("toDate / asInt", () => {
  it("reads a Firestore Timestamp, a Date and epoch millis", () => {
    const d = new Date("2026-01-02T03:04:05Z");
    assert.strictEqual(toDate({ toDate: () => d }).getTime(), d.getTime());
    assert.strictEqual(toDate(d).getTime(), d.getTime());
    assert.strictEqual(toDate(d.getTime()).getTime(), d.getTime());
  });

  it("returns null for absent or unrecognised values", () => {
    assert.strictEqual(toDate(null), null);
    assert.strictEqual(toDate(undefined), null);
    assert.strictEqual(toDate("nonsense"), null);
  });

  it("asInt falls back rather than propagating NaN into a total", () => {
    assert.strictEqual(asInt("12"), 12);
    assert.strictEqual(asInt(undefined), 0);
    assert.strictEqual(asInt(null), 0);
    assert.strictEqual(asInt("abc"), 0);
    assert.strictEqual(asInt(4.9), 4);
  });
});
