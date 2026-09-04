# Account recovery runbook

Everything here is for repairing accounts damaged by the **sign-in profile
overwrite** bug, and for making the next incident of that shape recoverable
instead of forensic.

The bug: a reinstall-and-sign-in overwrote an existing user document with a freshly
built one. `SetOptions(merge: true)` protects only keys *absent* from the payload,
so `username: null` wiped the handle and `gupPoints: 0` / `badges: []` /
`challengeProgress: {}` wiped the gamification history.

The code path is fixed — `UserModel.toWritableMap` now strips gamification fields
and nulls, `AuthService.resolveExistingProfile` throws rather than reporting an
unreadable profile as a new account, and
`test/services/profile_write_guard_test.dart` pins both. **Documents damaged
before that fix are not repaired by it.** That is what this runbook is for.

---

## 1. Repair a damaged account

### Credentials

Either works. The script needs Firestore read access, and write access only with
`--apply`.

```powershell
# Option A — your own Google account
gcloud auth application-default login

# Option B — a service account key
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\path\to\service-account.json"
```

### Look before you write

The script is a dry run unless you pass `--apply`. Start there, always.

```powershell
# Ledger-backed figures only. Fast, and every number is provable.
node tools/reconcile_gup_points.js --handle vansh

# Add the recounts rebuilt from surviving messages and call logs.
node tools/reconcile_gup_points.js --handle vansh --estimates

# Also read message documents, for nightMessages and reactions-received.
node tools/reconcile_gup_points.js --handle vansh --estimates --deep
```

The report separates three things, and the distinction is the whole point:

| | meaning |
|---|---|
| **PROVABLE FLOOR** | `lastWeekPoints` + ledgers that record the payout itself. Trust it. |
| **BEST ESTIMATE** | floor + points recomputed from what caused them. Close, not provable. |
| **NOT RECOVERABLE** | listed explicitly rather than folded into a number. |

`--apply` writes the floor by default, or the best estimate when you also pass
`--estimates`.

```powershell
node tools/reconcile_gup_points.js --handle vansh --estimates --deep --apply
```

Safety rails, so a bad run cannot repeat the original bug:

- **Never lowers `gupPoints`.** Restore spends left no ledger, so undercounting is
  an expected failure mode — a computed figure below the stored one means the
  script missed something, not that the account has too many points.
- **Refuses a second `--apply`** for the same uid, checked against the
  `pointsReconciliation` audit rows it writes. `--force` overrides; you almost
  never want it, because recounted points would land on a total that already
  includes them.
- **Badges and progress merge upward** (union, and max per key), so anything
  earned between the wipe and the repair survives the repair.
- **One transaction**, and it re-reads `gupPoints` inside that transaction so a
  payout landing mid-run is not overwritten downward.

### What is recoverable, and why

The wipe hit the user *document*. It did not touch subcollections, other
collections, or the handle reservation — which is why so much survives.

**Exact:**

- **`username`** — `/usernames/{handle}` still points at the uid. Only
  `updateUsername` releases a reservation and the bug never called it. This is
  also why re-entering the same handle worked for the affected user: nobody else
  could have claimed it.
- **Ad reward points** — `adRewards` rows store their own `points`, so the sum
  stays right even if `ADS_REWARD_POINTS` changes.
- **Streak milestones** — `users/{uid}/streakAwards/*` is written with `create` in
  the same transaction as the increment, so a row exists for every point paid.
- **`longestStreak`** — from `chatRooms/{room}/streak/state.longestForRoom`.

**Recounted** (`--estimates`): message points, call points, and challenge bonuses
re-derived from the target table. `type` and `senderId` are plaintext envelope
fields even on E2EE messages — only `text` is blanked — so messages are countable
by kind.

**Lost:** status-post points (statuses expire after 24h), `mesh_messages`
progress, and historical restore spends. Only the most recent restore per room
survives, as `restoreCostPaid` on the streak state doc.

### `lastWeekPoints` is the most valuable number here

`weeklyDigestEmailJob` stamps it, and it is **not** a member of
`UserModel.toMap()` — so the destructive write never touched it. When present, the
script treats it as a baseline and filters ledgers and recounts to activity after
its timestamp, so nothing is double counted. When absent, everything is counted
from the beginning of time.

### Tests

The Firestore reads need a live project, but every decision that can be *silently
wrong* is pure and tested — the never-lower rule, the challenge thresholds, and
the transcribed point values.

```powershell
cd functions
npx mocha ../tools/test/reconcile_gup_points.unit.test.js
```

---

## 2. Indexes — reconciled and deployed

`firestore.indexes.json` now matches production. Live state was captured with
`firebase firestore:indexes`, merged in verbatim, and deployed. **7 indexes, live
and in the file.**

What the capture proved, and it is worth recording:

- Two `callLogs` indexes existed live and were **absent from the file**. Deploying
  the old 2-index file would have offered to delete them and broken call history.
  The suspicion was right.
- Live `callLogs` uses `timestamp: DESCENDING`. I had written `ASCENDING`, which
  would have created two redundant duplicates — an equality filter on
  `callerId` plus a range on `timestamp` is served by either direction, so those
  additions were dropped rather than deployed. Two fewer indexes taxing every
  call-log write.
- Nothing live served `messages` (senderId, timestamp), which **confirms** the
  digest bug in section 4 rather than merely suspecting it.

The three genuinely new ones — `messages` (senderId+timestamp), `messages`
(senderId+type+timestamp), `adRewards` (uid+credited+type+createdAt) — are what
the recount needs, and the first is what the weekly digest needed all along.

### The rule for next time

Before any `firebase deploy --only firestore:indexes`, re-capture and diff:

```powershell
firebase firestore:indexes --project=videocallapp-81166 > live.json
```

Anything live but missing from `firestore.indexes.json` must be merged **in**
first. The file is only safe to deploy while it is a superset of live.

**Never pass `--force` to an index deploy.** Without it the CLI refuses to delete
and merely warns; with it, every live index missing from the file is dropped.
That single flag is the whole difference between a safe deploy and an outage.

---

## 3. Enable Point-in-Time Recovery

PITR gives a 7-day recovery window, which turns an incident like this one from
forensic reconstruction into a restore. It is **off** on this project.

`gcloud` is not installed on this machine, so this one needs your hands.

**Console:** Firebase → Firestore → the `(default)` database → ⋯ → *Point-in-time
recovery* → enable.

**CLI:**

```powershell
gcloud firestore databases update --database="(default)" --enable-pitr --project=videocallapp-81166

# verify
gcloud firestore databases describe --database="(default)" --project=videocallapp-81166 --format="value(pointInTimeRecoveryEnablement)"
```

It bills for the extra versioned data it keeps, which for a database this size is
small. It is reversible with `--no-enable-pitr`.

PITR is not retroactive — it protects from the moment it is enabled, so it does
nothing for the damage already done. That is what section 1 is for.

---

## 4. The weekly-digest bug — fixed

`weeklyDigestEmailJob` counts messages with `where senderId == …` plus a
`timestamp` range, a shape needing a composite index that **was confirmed absent
from production** by the capture in section 2. The count sat inside `catch (_) { }`,
so every digest email had been reporting **`messagesSent: 0`** with no error
anywhere.

Both halves are fixed:

- **The index is deployed.** This is the part that actually repairs the number,
  and it needs no code release — the next scheduled run (Mondays 03:30 UTC) will
  count correctly.
- **The swallow is gone.** Both catches now increment a counter and keep the first
  error, and the job logs once at the end:

  ```
  weeklyDigestEmailJob: N stats queries failed, so those digests under-reported
  activity. Check for a missing composite index. First error: …
  ```

  Aggregated deliberately — the query runs once per room per user, so logging at
  the throw site would emit thousands of identical lines and get ignored. One line
  per invocation gets read.

The logging change ships with your next `firebase deploy --only functions`. It is
a safety net, not the fix; the index already did the repairing.

