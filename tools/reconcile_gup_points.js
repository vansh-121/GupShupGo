#!/usr/bin/env node
// ═══════════════════════════════════════════════════════════════════════════════
// GupShupGo — Gup Points / profile reconciliation after the sign-in overwrite bug
// ═══════════════════════════════════════════════════════════════════════════════
//
// A reinstall-and-sign-in used to overwrite an existing user document with a
// freshly built one. `SetOptions(merge: true)` protects only keys ABSENT from the
// payload, so every key the fresh model DID carry landed: `username: null` wiped
// the handle, and `gupPoints: 0` / `badges: []` / `challengeProgress: {}` wiped
// the gamification history. The code path is fixed (see `UserModel.toWritableMap`
// and `AuthService.resolveExistingProfile`); this script repairs documents that
// were damaged before the fix shipped.
//
// ── What it can and cannot know ───────────────────────────────────────────────
//
// The wipe hit the user DOCUMENT. It did not touch subcollections, other
// collections, or the handle reservation — so a surprising amount is recoverable
// exactly, and the rest is honestly labelled rather than guessed at silently.
//
//   EXACT — reconstructed from a ledger that records the payout itself:
//     * username          /usernames/{handle}.uid  (the doc id IS the handle)
//     * ad reward points   adRewards where credited == true, type == 'points';
//                          each row stores its own `points`, so this stays right
//                          even if ADS_REWARD_POINTS is ever changed
//     * streak milestones  users/{uid}/streakAwards/*.points — written with
//                          `create` in the SAME transaction as the increment, so
//                          a row exists for every point paid and vice versa
//     * longestStreak      max of chatRooms/{room}/streak/state.longestForRoom
//     * streak_warrior     implied by any streakAwards threshold >= 7
//
//   RECOUNTED — no ledger, but the source collection survived, so the payout can
//   be recomputed from what caused it. Counted only with --estimates:
//     * message points     1 per non-reaction message sent. `type` and `senderId`
//                          are PLAINTEXT envelope fields even on E2EE messages
//                          (only `text` is blanked), so this is countable
//     * call points        10 per call, from callLogs as caller or callee
//     * challenge bonuses  re-derived from the recounted progress vs the target
//                          table below
//
//   RECOUNTED, --deep only (reads message docs rather than just counting them):
//     * nightMessages      messages sent between 00:00 and 05:00. The app used
//                          the DEVICE clock, so this uses --night-offset to
//                          approximate it and will not match exactly
//     * reactionsReceived  +5 each, from the `reactions` map on messages the user
//                          sent. A FLOOR: the map holds one entry per reactor, so
//                          somebody who changed their emoji was paid twice and is
//                          counted once
//
//   UNRECOVERABLE — stated in the report rather than folded into a number:
//     * status post points (3 each) — statuses expire after 24h and are gone
//     * mesh_messages progress — no surviving per-message mesh record
//     * historical restore SPENDS — `gupPoints: increment(-cost)` left no ledger;
//       only the most recent restore per room survives, as `restoreCostPaid` on
//       the streak state doc. So a heavy restorer's true total is LOWER than what
//       this computes, which is why --apply never lowers a total it cannot prove.
//
// ── Double counting ───────────────────────────────────────────────────────────
//
// `lastWeekPoints` is a real snapshot of `gupPoints`, stamped by
// `weeklyDigestEmailJob` and NOT a member of `UserModel.toMap()` — so the
// destructive write never touched it. When present it is the single most valuable
// number here: everything earned before its timestamp is already inside it, so
// the ledgers and recounts are filtered to activity AFTER that timestamp and
// added on top. Without it there is no baseline and everything is counted from
// the beginning of time.
//
// Challenge bonuses are the one thing that cannot be date-filtered — a lifetime
// threshold has no "when" — so they are credited only when there is no baseline,
// and skipped when there is one (they are already inside it).
//
// ── Safety ────────────────────────────────────────────────────────────────────
//
//   * dry run unless --apply. The dry run prints exactly what --apply would write.
//   * --apply NEVER lowers gupPoints. See the unrecoverable-spends note above.
//   * --apply refuses to run twice for the same uid unless --force, checked
//     against the `pointsReconciliation` audit trail it writes.
//   * the write is one transaction, and badges/challengeProgress are merged
//     upward (union / max per key) rather than replaced, so anything earned
//     between the wipe and this repair survives the repair.
//
// ── Usage ─────────────────────────────────────────────────────────────────────
//
//   Credentials — either works:
//     gcloud auth application-default login
//     $env:GOOGLE_APPLICATION_CREDENTIALS = "C:\path\to\service-account.json"
//
//   node tools/reconcile_gup_points.js --handle vansh
//   node tools/reconcile_gup_points.js --uid <uid> --estimates --deep
//   node tools/reconcile_gup_points.js --uid <uid> --estimates --deep --apply
//
//   --uid <id>          the account to inspect
//   --handle <name>     resolve the uid from /usernames/{handle} instead
//   --estimates         include recounted message/call/challenge points
//   --deep              also read message docs for nightMessages + reactions
//   --apply             write the repair (default is a dry run)
//   --force             allow a second --apply for a uid already reconciled
//   --project <id>      override the project (default: .firebaserc "default")
//   --night-offset <m>  minutes from UTC for the night-window recount (default
//                       330, i.e. IST, matching the app's canonical zone)
// ═══════════════════════════════════════════════════════════════════════════════

"use strict";

const fs = require("fs");
const path = require("path");

const REPO_ROOT = path.resolve(__dirname, "..");

// firebase-admin is already installed for the Cloud Functions, so resolve it out
// of there rather than adding a second node_modules tree to the repo.
let admin;
try {
  admin = require(path.join(REPO_ROOT, "functions", "node_modules", "firebase-admin"));
} catch (_) {
  try {
    admin = require("firebase-admin");
  } catch (_) {
    console.error(
      "Cannot find firebase-admin.\n" +
      "It ships with the Cloud Functions, so install those first:\n" +
      "  cd functions && npm install"
    );
    process.exit(1);
  }
}

// ─── Point values, transcribed from the app ────────────────────────────────────
//
// These live in Dart and are duplicated here because a Node script cannot read
// them. If any of them changes, this script starts producing a wrong number
// silently — so each carries its source.
const POINTS = Object.freeze({
  // GamificationService.handleMessageSent, `pointsToAward` default
  message: 1,
  // CallLogService.createCallLog → earnPoints(_, 10), both participants
  call: 10,
  // ChatService, on a reaction to a message you sent
  reactionReceived: 5,
  // StatusService → earnPoints(_, 3). Listed for the report; never counted.
  statusPost: 3,
});

// lib/models/gamification_data.dart → ChallengeDefinition.allChallenges.
// `recountable` marks the ones whose progress can be rebuilt from Firestore.
const CHALLENGES = Object.freeze([
  { key: "messages_sent", target: 100, reward: 50, badge: "chatterbox", recountable: true },
  { key: "voice_notes", target: 10, reward: 50, badge: "vocalist", recountable: true },
  { key: "reactions_given", target: 25, reward: 60, badge: "social_butterfly", recountable: true },
  { key: "night_messages", target: 10, reward: 75, badge: "night_owl", recountable: "deep" },
  { key: "status_posts", target: 5, reward: 50, badge: "status_superstar", recountable: false },
  { key: "mesh_messages", target: 10, reward: 75, badge: "offline_hero", recountable: false },
  // Weekly challenges reset and keep no history — not reconstructable at all.
  { key: "weekly_voice", target: 7, reward: 100, badge: null, recountable: false },
  { key: "weekly_streak_keeper", target: 7, reward: 100, badge: null, recountable: false },
]);

const AUDIT_COLLECTION = "pointsReconciliation";

// ─── CLI ──────────────────────────────────────────────────────────────────────

function parseArgs(argv) {
  const opts = {
    uid: null,
    handle: null,
    estimates: false,
    deep: false,
    apply: false,
    force: false,
    project: null,
    nightOffsetMinutes: 330,
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    const next = () => {
      const v = argv[++i];
      if (v === undefined) {
        throw new Error(`${a} needs a value`);
      }
      return v;
    };
    switch (a) {
      case "--uid": opts.uid = next(); break;
      case "--handle": opts.handle = next().trim().toLowerCase(); break;
      case "--project": opts.project = next(); break;
      case "--night-offset": opts.nightOffsetMinutes = Number(next()); break;
      case "--estimates": opts.estimates = true; break;
      case "--deep": opts.deep = true; break;
      case "--apply": opts.apply = true; break;
      case "--force": opts.force = true; break;
      case "-h":
      case "--help": opts.help = true; break;
      default:
        throw new Error(`unknown argument: ${a}`);
    }
  }
  return opts;
}

function projectIdFromFirebaserc() {
  try {
    const raw = fs.readFileSync(path.join(REPO_ROOT, ".firebaserc"), "utf8");
    const parsed = JSON.parse(raw);
    return (parsed.projects && parsed.projects.default) || null;
  } catch (_) {
    return null;
  }
}

// ─── small helpers ────────────────────────────────────────────────────────────

const asInt = (v, fallback = 0) => (Number.isFinite(Number(v)) ? Math.trunc(Number(v)) : fallback);

/** Firestore Timestamp | Date | epoch-ms → Date | null. */
function toDate(v) {
  if (v == null) return null;
  if (typeof v.toDate === "function") return v.toDate();
  if (v instanceof Date) return v;
  if (typeof v === "number") return new Date(v);
  return null;
}

async function countOf(query) {
  const snap = await query.count().get();
  return asInt(snap.data().count, 0);
}

/**
 * `count()` needs a composite index for equality + range on different fields.
 * A missing index is a setup problem, not a data problem, so it is reported with
 * the console link Firestore hands back rather than crashing the whole run.
 */
async function countOrExplain(query, label, problems) {
  try {
    return await countOf(query);
  } catch (e) {
    const msg = (e && e.message) || String(e);
    problems.push(`${label}: ${msg}`);
    return null;
  }
}

const fmt = (n) => (n === null || n === undefined ? "—" : String(n));
const pad = (s, w) => String(s).padEnd(w);
const padL = (s, w) => String(s).padStart(w);

function line(char = "─", width = 78) {
  return char.repeat(width);
}

// ─── uid resolution ───────────────────────────────────────────────────────────

async function resolveUid(db, opts) {
  if (opts.uid) return opts.uid;
  const snap = await db.collection("usernames").doc(opts.handle).get();
  if (!snap.exists) {
    throw new Error(`no /usernames/${opts.handle} reservation — check the spelling`);
  }
  const uid = snap.data().uid;
  if (!uid) {
    throw new Error(`/usernames/${opts.handle} has no uid field`);
  }
  return uid;
}

/**
 * The handle, recovered from the reservation collection.
 *
 * `updateUsername` is the only thing that releases a reservation, and the
 * overwrite bug never called it — so the row outlived the wipe and still points
 * at this uid. That makes the lost handle exactly recoverable, and also explains
 * why re-entering the same handle worked for the affected user: nobody else could
 * have claimed it.
 */
async function recoverHandle(db, uid) {
  const snap = await db.collection("usernames").where("uid", "==", uid).get();
  if (snap.empty) return null;
  // More than one would mean a release went missing; report the newest and say so.
  const handles = snap.docs.map((d) => d.id).sort();
  return { handle: handles[0], all: handles };
}

// ─── exact ledgers ────────────────────────────────────────────────────────────

async function sumAdRewards(db, uid, since) {
  let q = db
    .collection("adRewards")
    .where("uid", "==", uid)
    .where("credited", "==", true)
    .where("type", "==", "points");
  if (since) q = q.where("createdAt", ">", since);

  const snap = await q.get();
  let total = 0;
  for (const doc of snap.docs) {
    total += asInt(doc.data().points, 0);
  }
  return { total, rows: snap.size };
}

async function sumStreakAwards(db, uid, since) {
  // Not date-filtered in the query: `awardedAt` is present on every row this
  // module writes, but filtering server-side would need an index for a
  // collection that is tiny by construction (one row per room per threshold).
  const snap = await db.collection("users").doc(uid).collection("streakAwards").get();
  let total = 0;
  let rows = 0;
  let maxThreshold = 0;
  for (const doc of snap.docs) {
    const d = doc.data();
    const awardedAt = toDate(d.awardedAt);
    maxThreshold = Math.max(maxThreshold, asInt(d.threshold, 0));
    if (since && awardedAt && awardedAt <= since) continue;
    total += asInt(d.points, 0);
    rows++;
  }
  return { total, rows, allRows: snap.size, maxThreshold };
}

async function roomsFor(db, uid) {
  const snap = await db
    .collection("chatRooms")
    .where("participants", "array-contains", uid)
    .get();
  return snap.docs.map((d) => d.id);
}

async function recoverLongestStreak(db, roomIds) {
  let longest = 0;
  for (const roomId of roomIds) {
    try {
      const snap = await db
        .collection("chatRooms").doc(roomId)
        .collection("streak").doc("state")
        .get();
      if (!snap.exists) continue;
      const d = snap.data();
      longest = Math.max(longest, asInt(d.longestForRoom, 0), asInt(d.count, 0));
    } catch (_) { /* a room we cannot read contributes nothing */ }
  }
  return longest;
}

/** The only surviving trace of points SPENT on restores: the most recent per room. */
async function observedRestoreSpends(db, roomIds, uid) {
  let total = 0;
  let rooms = 0;
  for (const roomId of roomIds) {
    try {
      const snap = await db
        .collection("chatRooms").doc(roomId)
        .collection("streak").doc("state")
        .get();
      if (!snap.exists) continue;
      const d = snap.data();
      const paid = asInt(d.restoreCostPaid, 0);
      if (paid > 0 && d.restoredBy === uid) {
        total += paid;
        rooms++;
      }
    } catch (_) { /* ignore */ }
  }
  return { total, rooms };
}

// ─── recounts ─────────────────────────────────────────────────────────────────

async function recountMessages(db, uid, roomIds, since, problems) {
  let sent = 0;
  let reactionsGiven = 0;
  let voiceNotes = 0;
  let countedRooms = 0;

  for (const roomId of roomIds) {
    const messages = db.collection("chatRooms").doc(roomId).collection("messages");
    const base = () => {
      let q = messages.where("senderId", "==", uid);
      if (since) q = q.where("timestamp", ">", since);
      return q;
    };

    const total = await countOrExplain(base(), `messages in ${roomId}`, problems);
    if (total === null) continue;

    const reactions = await countOrExplain(
      base().where("type", "==", "reaction"),
      `reactions in ${roomId}`,
      problems
    );
    const audio = await countOrExplain(
      base().where("type", "==", "audio"),
      `voice notes in ${roomId}`,
      problems
    );

    sent += total - (reactions || 0);
    reactionsGiven += reactions || 0;
    voiceNotes += audio || 0;
    countedRooms++;
  }

  return { sent, reactionsGiven, voiceNotes, countedRooms };
}

async function recountCalls(db, uid, since, problems) {
  const build = (field) => {
    let q = db.collection("callLogs").where(field, "==", uid);
    if (since) q = q.where("timestamp", ">", since);
    return q;
  };
  const asCaller = await countOrExplain(build("callerId"), "callLogs as caller", problems);
  const asCallee = await countOrExplain(build("calleeId"), "callLogs as callee", problems);
  if (asCaller === null && asCallee === null) return null;
  return { asCaller: asCaller || 0, asCallee: asCallee || 0, total: (asCaller || 0) + (asCallee || 0) };
}

/**
 * Reads message docs (not just counts) for the two figures that need per-document
 * inspection. Only `timestamp`, `type` and `reactions` are selected, so this stays
 * cheap even on a chatty account.
 */
async function deepScan(db, uid, roomIds, since, nightOffsetMinutes, problems) {
  let nightMessages = 0;
  let reactionsReceived = 0;
  let scanned = 0;

  for (const roomId of roomIds) {
    const messages = db.collection("chatRooms").doc(roomId).collection("messages");
    try {
      let q = messages.where("senderId", "==", uid);
      if (since) q = q.where("timestamp", ">", since);
      const snap = await q.select("timestamp", "type", "reactions").get();

      for (const doc of snap.docs) {
        const d = doc.data();
        scanned++;

        if (d.type !== "reaction") {
          const ts = toDate(d.timestamp);
          if (ts) {
            // The app read `DateTime.now().hour`, i.e. the device's local clock.
            // Shifting UTC by a fixed offset is the closest a server-side recount
            // can get; a user who travelled will not match exactly.
            const localHour = new Date(ts.getTime() + nightOffsetMinutes * 60000).getUTCHours();
            if (localHour >= 0 && localHour < 5) nightMessages++;
          }
        }

        // Reactions others left on this user's message. One entry per reactor, so
        // a reactor who switched emoji was paid twice and counted once — a floor.
        const reactions = d.reactions;
        if (reactions && typeof reactions === "object") {
          for (const reactorId of Object.keys(reactions)) {
            if (reactorId !== uid) reactionsReceived++;
          }
        }
      }
    } catch (e) {
      problems.push(`deep scan of ${roomId}: ${(e && e.message) || e}`);
    }
  }

  return { nightMessages, reactionsReceived, scanned };
}

// ─── challenge re-derivation ──────────────────────────────────────────────────

/**
 * Which challenges the recounted progress says are complete, and what they paid.
 *
 * Only credited when there is no `lastWeekPoints` baseline: a lifetime threshold
 * has no timestamp, so with a baseline these bonuses are already inside it and
 * crediting them again would double count.
 */
function deriveChallenges(progress, deep) {
  const completed = [];
  const badges = [];
  let bonus = 0;
  const skipped = [];

  for (const c of CHALLENGES) {
    const usable = c.recountable === true || (c.recountable === "deep" && deep);
    if (!usable) {
      skipped.push(c.key);
      continue;
    }
    const have = asInt(progress[c.key], 0);
    if (have >= c.target) {
      completed.push(c.key);
      bonus += c.reward;
      if (c.badge) badges.push(c.badge);
    }
  }
  return { completed, badges, bonus, skipped };
}

/**
 * Decides what `gupPoints` should become. The one rule here that must not be
 * wrong, so it is a named function with a test rather than an `if` inside main.
 *
 * A computed figure at or below the stored one is treated as this script having
 * missed something, NOT as the user having too many points — because restore
 * spends left no ledger, so undercounting is a known and expected failure mode
 * while overcounting is not. Refusing to lower makes the worst case "the repair
 * did nothing", which is recoverable, instead of "the repair took points away",
 * which is the bug all over again.
 */
function planPointsWrite(currentPoints, computedTarget) {
  const current = asInt(currentPoints, 0);
  const target = asInt(computedTarget, 0);
  if (target > current) {
    return { write: true, value: target };
  }
  return {
    write: false,
    value: current,
    reason:
      `gupPoints left at ${current}: the computed figure (${target}) is not higher, ` +
      "and this script never lowers a total it cannot prove.",
  };
}

// ─── report ───────────────────────────────────────────────────────────────────

function printReport(r) {
  const W = 78;
  console.log("");
  console.log(line("═", W));
  console.log(` Gup Points reconciliation — ${r.uid}`);
  console.log(line("═", W));

  console.log("");
  console.log(" CURRENT DOCUMENT");
  console.log(`   gupPoints            ${fmt(r.current.gupPoints)}`);
  console.log(`   username             ${r.current.username === null ? "(missing)" : r.current.username}`);
  console.log(`   badges               ${r.current.badges.length ? r.current.badges.join(", ") : "(none)"}`);
  console.log(`   longestStreak        ${fmt(r.current.longestStreak)}`);
  console.log(`   reactionsGiven       ${fmt(r.current.reactionsGiven)}`);
  console.log(`   nightMessages        ${fmt(r.current.nightMessages)}`);
  console.log(`   challengeProgress    ${
    Object.keys(r.current.challengeProgress).length
      ? JSON.stringify(r.current.challengeProgress)
      : "(empty)"
  }`);

  console.log("");
  console.log(" BASELINE");
  if (r.baseline.value !== null) {
    console.log(`   lastWeekPoints       ${r.baseline.value}   (survived the wipe)`);
    console.log(`   stamped at           ${r.baseline.at ? r.baseline.at.toISOString() : "unknown"}`);
    console.log("   Ledgers and recounts below are filtered to activity AFTER that");
    console.log("   timestamp, because everything earlier is already in the baseline.");
  } else {
    console.log("   lastWeekPoints       (absent — no weekly digest has been sent)");
    console.log("   Everything below is counted from the beginning of time.");
  }

  console.log("");
  console.log(" EXACT — ledger-backed, safe to trust");
  console.log(`   ${pad("ad rewards", 22)}${padL(r.exact.adRewards.total, 8)}   (${r.exact.adRewards.rows} rows)`);
  console.log(`   ${pad("streak milestones", 22)}${padL(r.exact.streakAwards.total, 8)}   (${r.exact.streakAwards.rows} of ${r.exact.streakAwards.allRows} rows)`);
  console.log(`   ${pad("", 22)}${padL("─".repeat(8), 8)}`);
  console.log(`   ${pad("exact subtotal", 22)}${padL(r.exact.subtotal, 8)}`);

  console.log("");
  console.log(` PROVABLE FLOOR           ${padL(r.floor, 8)}`);
  console.log("   baseline + exact ledgers. Nothing here is an estimate.");

  if (r.estimates) {
    console.log("");
    console.log(" RECOUNTED — rebuilt from surviving source collections");
    const m = r.recount.messages;
    console.log(`   ${pad("messages sent", 22)}${padL(m.sent * POINTS.message, 8)}   (${m.sent} × ${POINTS.message}, ${m.countedRooms} rooms)`);
    if (r.recount.calls) {
      const c = r.recount.calls;
      console.log(`   ${pad("calls", 22)}${padL(c.total * POINTS.call, 8)}   (${c.total} × ${POINTS.call}; ${c.asCaller} out, ${c.asCallee} in)`);
    } else {
      console.log(`   ${pad("calls", 22)}${padL("—", 8)}   (could not be counted)`);
    }
    if (r.recount.deep) {
      const d = r.recount.deep;
      console.log(`   ${pad("reactions received", 22)}${padL(d.reactionsReceived * POINTS.reactionReceived, 8)}   (${d.reactionsReceived} × ${POINTS.reactionReceived}, a floor)`);
    }
    if (r.challenges.credited) {
      console.log(`   ${pad("challenge bonuses", 22)}${padL(r.challenges.bonus, 8)}   (${r.challenges.completed.join(", ") || "none"})`);
    } else {
      console.log(`   ${pad("challenge bonuses", 22)}${padL("skip", 8)}   (already inside the baseline)`);
    }
    console.log(`   ${pad("", 22)}${padL("─".repeat(8), 8)}`);
    console.log(`   ${pad("recount subtotal", 22)}${padL(r.recountSubtotal, 8)}`);

    console.log("");
    console.log(` BEST ESTIMATE            ${padL(r.best, 8)}`);
    console.log("   floor + recounts. Close, not provable.");
  } else {
    console.log("");
    console.log(" RECOUNTED                (skipped — pass --estimates to include)");
  }

  console.log("");
  console.log(" NOT RECOVERABLE — deliberately excluded from every figure above");
  console.log(`   status post points   ${POINTS.statusPost} each; statuses expire after 24h`);
  console.log("   mesh_messages        no surviving per-message mesh record");
  if (r.spends.total > 0) {
    console.log(`   restore spends       at least ${r.spends.total} spent across ${r.spends.rooms} room(s)`);
    console.log("                        — only the most recent per room survives, so the");
    console.log("                        true total is LOWER than the figures above");
  } else {
    console.log("   restore spends       none observed (only the most recent per room survives)");
  }
  if (!r.estimates || !r.recount.deep) {
    console.log("   nightMessages        needs --estimates --deep");
  }

  if (r.recovered.handle) {
    console.log("");
    console.log(" RECOVERED IDENTITY");
    console.log(`   username             ${r.recovered.handle.handle}   (from /usernames, exact)`);
    if (r.recovered.handle.all.length > 1) {
      console.log(`   ⚠ more than one reservation points at this uid: ${r.recovered.handle.all.join(", ")}`);
    }
  }

  if (r.problems.length) {
    console.log("");
    console.log(" PROBLEMS DURING THE SCAN");
    for (const p of r.problems.slice(0, 12)) console.log(`   • ${p}`);
    if (r.problems.length > 12) console.log(`   … and ${r.problems.length - 12} more`);
    console.log("   A missing-index error includes a console link; create it and re-run.");
  }
}

function printPlan(plan, apply) {
  const W = 78;
  console.log("");
  console.log(line("═", W));
  console.log(apply ? " APPLYING" : " WOULD WRITE (dry run — pass --apply to do it)");
  console.log(line("═", W));
  if (!plan.writes.length) {
    console.log("   nothing to change.");
    return;
  }
  for (const w of plan.writes) {
    console.log(`   ${pad(w.field, 22)}${w.from}  →  ${w.to}`);
  }
  if (plan.notes.length) {
    console.log("");
    for (const n of plan.notes) console.log(`   note: ${n}`);
  }
}

// ─── main ─────────────────────────────────────────────────────────────────────

async function main() {
  let opts;
  try {
    opts = parseArgs(process.argv.slice(2));
  } catch (e) {
    console.error(`${e.message}\nRun with --help for usage.`);
    process.exit(2);
  }

  if (opts.help || (!opts.uid && !opts.handle)) {
    console.log(
      "Reconcile a GupShupGo account damaged by the sign-in profile overwrite.\n\n" +
      "  node tools/reconcile_gup_points.js --handle vansh\n" +
      "  node tools/reconcile_gup_points.js --uid <uid> --estimates --deep\n" +
      "  node tools/reconcile_gup_points.js --uid <uid> --estimates --deep --apply\n\n" +
      "  --uid <id> | --handle <name>   the account\n" +
      "  --estimates    include recounted message/call/challenge points\n" +
      "  --deep         read message docs for nightMessages + reactions received\n" +
      "  --apply        write the repair (default: dry run)\n" +
      "  --force        allow a second --apply for an already-reconciled uid\n" +
      "  --project <id> override the project id\n" +
      "  --night-offset <minutes from UTC, default 330>\n\n" +
      "Credentials: gcloud auth application-default login,\n" +
      "or set GOOGLE_APPLICATION_CREDENTIALS to a service-account JSON.\n" +
      "The file header explains what is exact, what is recounted, and what is lost."
    );
    process.exit(opts.help ? 0 : 2);
  }

  const projectId = opts.project || projectIdFromFirebaserc();
  if (!projectId) {
    console.error("No project id: pass --project, or add one to .firebaserc.");
    process.exit(2);
  }

  admin.initializeApp({ projectId });
  const db = admin.firestore();
  const problems = [];

  const uid = await resolveUid(db, opts);

  const userRef = db.collection("users").doc(uid);
  const userSnap = await userRef.get();
  if (!userSnap.exists) {
    console.error(`users/${uid} does not exist. Nothing to reconcile.`);
    process.exit(1);
  }
  const user = userSnap.data();

  // ── baseline ───────────────────────────────────────────────────────────────
  const hasBaseline = user.lastWeekPoints !== undefined && user.lastWeekPoints !== null;
  const baselineValue = hasBaseline ? asInt(user.lastWeekPoints, 0) : null;
  const baselineAt = toDate(user.notifiedAt && user.notifiedAt.weekly_digest_email);
  // Only filter by date when we actually know the date. A baseline whose stamp we
  // cannot read must not silently become "count everything from zero on top".
  const since = hasBaseline ? baselineAt : null;
  if (hasBaseline && !baselineAt) {
    problems.push(
      "lastWeekPoints is present but its digest timestamp is missing, so ledgers " +
      "could not be date-filtered; totals may double count."
    );
  }

  // ── exact ──────────────────────────────────────────────────────────────────
  const [adRewards, streakAwards, handleInfo] = await Promise.all([
    sumAdRewards(db, uid, since),
    sumStreakAwards(db, uid, since),
    recoverHandle(db, uid),
  ]);
  const exactSubtotal = adRewards.total + streakAwards.total;
  const floor = (baselineValue || 0) + exactSubtotal;

  const roomIds = await roomsFor(db, uid);
  const [longestStreak, spends] = await Promise.all([
    recoverLongestStreak(db, roomIds),
    observedRestoreSpends(db, roomIds, uid),
  ]);

  // ── recounts ───────────────────────────────────────────────────────────────
  let messages = { sent: 0, reactionsGiven: 0, voiceNotes: 0, countedRooms: 0 };
  let calls = null;
  let deep = null;
  let recountSubtotal = 0;
  let challenges = { credited: false, completed: [], badges: [], bonus: 0, skipped: [] };

  if (opts.estimates) {
    messages = await recountMessages(db, uid, roomIds, since, problems);
    calls = await recountCalls(db, uid, since, problems);
    if (opts.deep) {
      deep = await deepScan(db, uid, roomIds, since, opts.nightOffsetMinutes, problems);
    }

    // Lifetime progress for the challenge re-derivation must be counted over ALL
    // time, not just since the baseline — a threshold is a lifetime total.
    const lifetime = since
      ? await recountMessages(db, uid, roomIds, null, problems)
      : messages;
    const lifetimeDeep = since && opts.deep
      ? await deepScan(db, uid, roomIds, null, opts.nightOffsetMinutes, problems)
      : deep;

    const progress = {
      messages_sent: lifetime.sent,
      voice_notes: lifetime.voiceNotes,
      reactions_given: lifetime.reactionsGiven,
      night_messages: lifetimeDeep ? lifetimeDeep.nightMessages : 0,
    };
    const derived = deriveChallenges(progress, opts.deep);
    challenges = { ...derived, credited: !hasBaseline, progress };

    recountSubtotal =
      messages.sent * POINTS.message +
      (calls ? calls.total * POINTS.call : 0) +
      (deep ? deep.reactionsReceived * POINTS.reactionReceived : 0) +
      (challenges.credited ? challenges.bonus : 0);
  }

  const best = floor + recountSubtotal;

  const report = {
    uid,
    current: {
      gupPoints: asInt(user.gupPoints, 0),
      username: user.username === undefined ? null : user.username,
      badges: Array.isArray(user.badges) ? user.badges : [],
      longestStreak: asInt(user.longestStreak, 0),
      reactionsGiven: asInt(user.reactionsGiven, 0),
      nightMessages: asInt(user.nightMessages, 0),
      challengeProgress: user.challengeProgress || {},
    },
    baseline: { value: baselineValue, at: baselineAt },
    exact: { adRewards, streakAwards, subtotal: exactSubtotal },
    floor,
    estimates: opts.estimates,
    recount: { messages, calls, deep },
    recountSubtotal,
    best,
    challenges,
    spends,
    recovered: { handle: handleInfo, longestStreak },
    problems,
  };

  printReport(report);

  // ── the plan ───────────────────────────────────────────────────────────────
  const target = opts.estimates ? best : floor;
  const currentPoints = asInt(user.gupPoints, 0);

  const writes = [];
  const notes = [];
  const update = {};

  // Never lower a total. Historical restore spends left no ledger, so a computed
  // figure below the stored one means this script is missing something, not that
  // the user has too many points.
  const pointsPlan = planPointsWrite(currentPoints, target);
  if (pointsPlan.write) {
    update.gupPoints = pointsPlan.value;
    writes.push({ field: "gupPoints", from: currentPoints, to: pointsPlan.value });
  } else {
    notes.push(pointsPlan.reason);
  }

  const currentHandle = user.username;
  if (handleInfo && !currentHandle) {
    update.username = handleInfo.handle;
    update.username_lowercase = handleInfo.handle.toLowerCase();
    writes.push({ field: "username", from: "(missing)", to: handleInfo.handle });
  } else if (handleInfo && currentHandle && currentHandle.toLowerCase() !== handleInfo.handle) {
    notes.push(
      `username is "${currentHandle}" but /usernames says "${handleInfo.handle}" — left alone, ` +
      "resolve by hand."
    );
  }

  if (longestStreak > asInt(user.longestStreak, 0)) {
    update.longestStreak = longestStreak;
    writes.push({ field: "longestStreak", from: asInt(user.longestStreak, 0), to: longestStreak });
  }

  // Badges are unioned, never replaced: anything earned since the wipe stays.
  const badgeSet = new Set(Array.isArray(user.badges) ? user.badges : []);
  const badgesToAdd = [];
  const candidate = [];
  if (streakAwards.maxThreshold >= 7) candidate.push("streak_warrior");
  // handleMessageSent adds this unconditionally to anyone who has ever sent a
  // message, so any surviving message proves it.
  if (opts.estimates && messages.sent > 0) candidate.push("early_adopter");
  if (target >= 500) candidate.push("reputation_master");
  if (opts.estimates) candidate.push(...challenges.badges);
  for (const b of candidate) {
    if (!badgeSet.has(b)) {
      badgeSet.add(b);
      badgesToAdd.push(b);
    }
  }
  if (badgesToAdd.length) {
    update.badges = admin.firestore.FieldValue.arrayUnion(...badgesToAdd);
    writes.push({ field: "badges", from: "(union)", to: `+ ${badgesToAdd.join(", ")}` });
  }

  // Progress counters are raised per key, never lowered — the same reason as
  // gupPoints, and it also stops a future re-completion from paying twice.
  if (opts.estimates) {
    const storedProgress = user.challengeProgress || {};
    const mergedProgress = { ...storedProgress };
    let progressChanged = false;
    for (const [k, v] of Object.entries(challenges.progress || {})) {
      if (!CHALLENGES.some((c) => c.key === k)) continue;
      if (k === "night_messages" && !opts.deep) continue;
      if (asInt(v, 0) > asInt(storedProgress[k], 0)) {
        mergedProgress[k] = asInt(v, 0);
        progressChanged = true;
      }
    }
    if (progressChanged) {
      update.challengeProgress = mergedProgress;
      writes.push({
        field: "challengeProgress",
        from: JSON.stringify(storedProgress),
        to: JSON.stringify(mergedProgress),
      });
      notes.push(
        "restoring challengeProgress also stops a future re-completion from paying " +
        "the same bonus a second time."
      );
    }

    const completedSet = new Set(Array.isArray(user.completedChallenges) ? user.completedChallenges : []);
    const completedToAdd = challenges.completed.filter((k) => !completedSet.has(k));
    if (completedToAdd.length) {
      update.completedChallenges = admin.firestore.FieldValue.arrayUnion(...completedToAdd);
      writes.push({ field: "completedChallenges", from: "(union)", to: `+ ${completedToAdd.join(", ")}` });
    }

    if (messages.reactionsGiven > asInt(user.reactionsGiven, 0)) {
      update.reactionsGiven = messages.reactionsGiven;
      writes.push({ field: "reactionsGiven", from: asInt(user.reactionsGiven, 0), to: messages.reactionsGiven });
    }
    if (deep && deep.nightMessages > asInt(user.nightMessages, 0)) {
      update.nightMessages = deep.nightMessages;
      writes.push({ field: "nightMessages", from: asInt(user.nightMessages, 0), to: deep.nightMessages });
    }
  }

  if (!opts.estimates) {
    notes.push("without --estimates only ledger-backed figures are written.");
  }

  printPlan({ writes, notes }, opts.apply);

  if (!opts.apply) {
    console.log("");
    console.log(" Dry run. Re-run with --apply to write the changes above.");
    await admin.app().delete();
    return;
  }

  // ── apply ──────────────────────────────────────────────────────────────────
  const priorAudit = await db
    .collection(AUDIT_COLLECTION)
    .where("uid", "==", uid)
    .limit(1)
    .get();
  if (!priorAudit.empty && !opts.force) {
    console.error(
      `\n Refusing: ${uid} has already been reconciled (${priorAudit.docs[0].id}).\n` +
      " Re-running would add recounted points on top of a total that already\n" +
      " includes them. Pass --force only if you know that is what you want."
    );
    await admin.app().delete();
    process.exit(1);
  }

  if (!writes.length) {
    console.log("\n Nothing to write.");
    await admin.app().delete();
    return;
  }

  const auditRef = db.collection(AUDIT_COLLECTION).doc(`${uid}_${Date.now()}`);
  await db.runTransaction(async (tx) => {
    const fresh = await tx.get(userRef);
    if (!fresh.exists) throw new Error("user document vanished mid-transaction");

    // Re-check the floor against the value as of THIS transaction, so a payout
    // landing between the report and the write is not overwritten downward.
    const nowPoints = asInt(fresh.data().gupPoints, 0);
    const finalUpdate = { ...update };
    if (finalUpdate.gupPoints !== undefined && finalUpdate.gupPoints <= nowPoints) {
      delete finalUpdate.gupPoints;
    }

    tx.update(userRef, finalUpdate);
    tx.set(auditRef, {
      uid,
      reconciledAt: admin.firestore.FieldValue.serverTimestamp(),
      tool: "tools/reconcile_gup_points.js",
      options: {
        estimates: opts.estimates,
        deep: opts.deep,
        force: opts.force,
        nightOffsetMinutes: opts.nightOffsetMinutes,
      },
      before: {
        gupPoints: nowPoints,
        username: fresh.data().username || null,
        badges: fresh.data().badges || [],
        longestStreak: asInt(fresh.data().longestStreak, 0),
        challengeProgress: fresh.data().challengeProgress || {},
      },
      computed: {
        baseline: baselineValue,
        baselineAt: baselineAt || null,
        exactAdRewards: adRewards.total,
        exactStreakAwards: streakAwards.total,
        floor,
        recountSubtotal,
        best,
        applied: finalUpdate.gupPoints !== undefined ? finalUpdate.gupPoints : nowPoints,
      },
      recount: {
        messagesSent: messages.sent,
        reactionsGiven: messages.reactionsGiven,
        voiceNotes: messages.voiceNotes,
        calls: calls ? calls.total : null,
        nightMessages: deep ? deep.nightMessages : null,
        reactionsReceived: deep ? deep.reactionsReceived : null,
      },
      problems,
    });
  });

  console.log("");
  console.log(` Applied. Audit trail: ${AUDIT_COLLECTION}/${auditRef.id}`);
  console.log(" That row is what makes a second --apply refuse, so leave it in place.");
  await admin.app().delete();
}

// Guarded so the pure helpers below can be imported by the unit test without
// initialising an app or touching the network.
if (require.main === module) {
  main().catch((e) => {
    console.error(`\nFailed: ${(e && e.stack) || e}`);
    process.exit(1);
  });
}

// Exported for `tools/test/reconcile_gup_points.unit.test.js`. These are the
// decisions that can be silently wrong — a bad threshold or a sign error in the
// "never lower" rule produces a plausible number, not a crash.
module.exports = {
  parseArgs,
  deriveChallenges,
  planPointsWrite,
  toDate,
  asInt,
  POINTS,
  CHALLENGES,
};
