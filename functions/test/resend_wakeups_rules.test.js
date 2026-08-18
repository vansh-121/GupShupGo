// Security rules for `resendWakeups` — the collection that lets a recipient ask
// the server to wake a message's sender.
//
// Worth testing rather than eyeballing, because the collection is a delivery
// primitive: a doc here causes a silent high-priority push to whoever `senderId`
// names. Unconstrained, that is "make any user's phone wake up on demand". Two
// separate bounds hold it in place, and both are asserted here:
//
//   • WHICH messages can be woken — the named message must exist, must have been
//     written by the uid being woken, and must be carrying an outstanding retry
//     request. Both uids must share the room.
//   • HOW MANY TIMES — the document id is derived from (room, message, requester
//     device, attempt), and updates are denied, so an attempt buys exactly one
//     push. An auto id used to make every write succeed, which left the first
//     bound governing the set of legitimate targets but nothing at all governing
//     the rate at which one of them could be hit.
//
// Run:  firebase emulators:exec --only firestore \
//         "npx mocha functions/test/resend_wakeups_rules.test.js"

const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");
const fs = require("fs");
const path = require("path");
const assert = require("assert");

// `ctx.firestore()` hands back a compat instance, so the sentinel has to come
// from the compat namespace to be recognised. The `.default` dance is because
// the CJS build of a package compiled from ESM may or may not wrap it.
const firebaseCompat = require("firebase/compat/app");
require("firebase/compat/firestore");
const fb = firebaseCompat.default || firebaseCompat;
const serverTimestamp = () => fb.firestore.FieldValue.serverTimestamp();

const ALICE = "uid-alice";
const BOB = "uid-bob";
const CAROL = "uid-carol";
const ROOM = "uid-alice_uid-bob";
const MSG = "msg-1";

let testEnv;

// Alice can't decrypt something Bob sent, so she asks for Bob to be woken.
const wakeup = (overrides = {}) => ({
  roomId: ROOM,
  messageId: MSG,
  senderId: BOB,
  requesterId: ALICE,
  deviceId: 1,
  attempt: 1,
  at: serverTimestamp(),
  ...overrides,
});

// The id `_publishResendWakeup` computes, and the one the rules recompute from
// already-validated fields. Keyed on the *authenticated* uid rather than
// `requesterId` so a test that deliberately spoofs `requesterId` fails on that
// check alone and not incidentally on the id.
const idFor = (authUid, d) =>
  `${d.roomId}_${d.messageId}_${authUid}_${d.deviceId}_${d.attempt}`;

before(async function () {
  this.timeout(30000);
  // emulators:exec exports this; the literal is only for a hand-started emulator.
  const [host, port] = (
    process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080"
  ).split(":");
  testEnv = await initializeTestEnvironment({
    projectId: "gsg-rules-test",
    firestore: {
      rules: fs.readFileSync(
        path.join(__dirname, "..", "..", "firestore.rules"),
        "utf8"
      ),
      host,
      port: Number(port),
    },
  });
});

after(async () => {
  if (testEnv) await testEnv.cleanup();
});

// The legitimate precondition for a wakeup: Bob wrote the message, and Alice has
// already published a retry request against it. `_requestResend` awaits that
// update before writing the wakeup, so this is the real on-the-wire state.
const seedMessage = (overrides = {}) =>
  testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx
      .firestore()
      .collection("chatRooms")
      .doc(ROOM)
      .collection("messages")
      .doc(MSG)
      .set({
        senderId: BOB,
        receiverId: ALICE,
        retryRequests: [`${ALICE}:1#1`],
        ...overrides,
      });
  });

beforeEach(async () => {
  await testEnv.clearFirestore();
  // The rules read `participants` off the parent room, so it has to exist.
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx
      .firestore()
      .collection("chatRooms")
      .doc(ROOM)
      .set({ participants: [ALICE, BOB] });
  });
  await seedMessage();
});

const as = (uid) => testEnv.authenticatedContext(uid).firestore();

// Writes a wakeup the way the client does: `set` at a derived id, never `add`.
// Pass `id` to write to a different one on purpose.
const create = (authUid, data = wakeup(), id = null) =>
  as(authUid)
    .collection("resendWakeups")
    .doc(id === null ? idFor(authUid, data) : id)
    .set(data);

// Seeds a wakeup document bypassing rules, for the read/update/delete cases.
const seedWakeup = async () => {
  const data = wakeup();
  const id = idFor(ALICE, data);
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().collection("resendWakeups").doc(id).set(data);
  });
  return id;
};

describe("resendWakeups", () => {
  it("lets a participant ask for the other participant to be woken", async () => {
    await assertSucceeds(create(ALICE));
  });

  it("rejects an outsider entirely", async () => {
    // Carol is in no chat with either of them, so she has no business causing
    // Bob's phone to wake.
    await assertFails(create(CAROL, wakeup({ requesterId: CAROL })));
  });

  it("rejects spoofing requesterId", async () => {
    // Otherwise the requesterId field would be decoration rather than identity.
    await assertFails(create(ALICE, wakeup({ requesterId: BOB })));
  });

  it("rejects waking someone outside the room", async () => {
    // The case that matters most: Alice is a legitimate participant, so without
    // the hasAll check on senderId she could name any uid here and use a real
    // chat as a launchpad for pushing to strangers.
    await assertFails(create(ALICE, wakeup({ senderId: CAROL })));
  });

  it("rejects naming yourself as the sender", async () => {
    // A self-wake loop: the push would come back to the device that asked for
    // it, which serves nothing and repeats.
    await assertFails(
      create(ALICE, wakeup({ senderId: ALICE, requesterId: ALICE }))
    );
  });

  it("rejects a room the caller is not in", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("chatRooms")
        .doc("uid-bob_uid-carol")
        .set({ participants: [BOB, CAROL] });
    });
    await assertFails(
      create(ALICE, wakeup({ roomId: "uid-bob_uid-carol", senderId: CAROL }))
    );
  });

  it("rejects a nonexistent room", async () => {
    // The get() must fail closed. A missing room used to be the easy way to
    // sidestep a participant check written as an equality on a fetched field.
    await assertFails(create(ALICE, wakeup({ roomId: "no-such-room" })));
  });

  it("rejects a wakeup for a message that does not exist", async () => {
    // Room participation alone used to be the whole bound, which let a
    // participant mint a wakeup per invented messageId — an unbounded silent
    // push generator aimed at someone they share a chat with.
    await assertFails(create(ALICE, wakeup({ messageId: "never-sent" })));
  });

  it("rejects naming a sender who did not write the message", async () => {
    // Carol is a participant of nothing here, but the case that matters is the
    // shape: the uid being woken has to be the message's actual author, or a
    // real message becomes a launchpad for waking an arbitrary room member.
    await seedMessage({ senderId: ALICE });
    await assertFails(create(ALICE, wakeup({ senderId: BOB })));
  });

  it("rejects a wakeup with no outstanding retry request", async () => {
    // The first bound: a wakeup is only legitimate while a request is actually
    // pending on the document, so the set of wakeable messages is the set the
    // resend protocol has genuinely given up on decrypting.
    await seedMessage({ retryRequests: [] });
    await assertFails(create(ALICE));
  });

  it("rejects a wakeup whose message has no retryRequests field at all", async () => {
    // Absent, not empty — the map accessor has to default rather than error,
    // because an error and a denial look the same from here but not in the logs.
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("chatRooms")
        .doc(ROOM)
        .collection("messages")
        .doc(MSG)
        .set({ senderId: BOB, receiverId: ALICE });
    });
    await assertFails(create(ALICE));
  });

  it("rejects a client-chosen timestamp", async () => {
    // The Function drops anything older than five minutes. If the client picked
    // the value, that gate would be advisory: backdate it and a replayed wakeup
    // sails through, or omit it and the staleness check is skipped entirely.
    await assertFails(create(ALICE, wakeup({ at: new Date() })));
    await assertFails(
      create(ALICE, wakeup({ at: new Date(Date.now() - 60 * 60 * 1000) }))
    );
  });

  it("rejects an omitted timestamp", async () => {
    const noAt = wakeup();
    delete noAt.at;
    await assertFails(create(ALICE, noAt));
  });

  it("rejects unauthenticated writes", async () => {
    const data = wakeup();
    await assertFails(
      testEnv
        .unauthenticatedContext()
        .firestore()
        .collection("resendWakeups")
        .doc(idFor(ALICE, data))
        .set(data)
    );
  });

  it("rejects malformed docs", async () => {
    for (const bad of [
      { senderId: 42 },
      { roomId: null },
      { messageId: 7 },
    ]) {
      await assertFails(create(ALICE, wakeup(bad)));
    }
  });

  // ── The write-once ceiling ────────────────────────────────────────────────
  //
  // Everything above bounds which messages are wakeable. These bound how often.

  it("rejects an auto id", async () => {
    // The hole this ceiling closes, stated directly. `add()` was the original
    // implementation: every write landed on a fresh id, so a client holding one
    // genuinely-pending request could re-trigger the Function — and another
    // high-priority push — as fast as it could write.
    await assertFails(as(ALICE).collection("resendWakeups").add(wakeup()));
  });

  it("rejects reusing a spent id", async () => {
    // The mechanism itself. A second write to a live id is an update, and
    // updates are denied, so an attempt buys exactly one push. This is also why
    // `notifyResendRequest` no longer deletes these documents — a delete would
    // hand the id back.
    await assertSucceeds(create(ALICE));
    await assertFails(create(ALICE));
  });

  it("still allows the next legitimate attempt", async () => {
    // The ceiling must not cost the protocol its retries. `attempt` is
    // lifetime-monotonic per message, so each real retry lands on an id of its
    // own and is unaffected by the previous one being spent.
    await assertSucceeds(create(ALICE, wakeup({ attempt: 1 })));
    await assertSucceeds(create(ALICE, wakeup({ attempt: 2 })));
    await assertSucceeds(create(ALICE, wakeup({ attempt: 3 })));
  });

  it("gives each of the requester's devices its own id", async () => {
    // Two of Alice's devices can independently fail to decrypt the same message
    // and each needs its own session rebuilt, so they must not contend for one
    // id — the second would be denied and that device would never be repaired
    // by the fast path.
    await assertSucceeds(create(ALICE, wakeup({ deviceId: 1 })));
    await assertSucceeds(create(ALICE, wakeup({ deviceId: 2 })));
  });

  it("rejects an id that does not match its fields", async () => {
    // Without this the id would be a convention rather than a constraint: a
    // client could keep the payload honest and vary only the id, which is the
    // auto-id hole wearing a different shape.
    const d = wakeup();
    for (const forged of [
      "anything",
      idFor(ALICE, { ...d, attempt: 2 }),
      idFor(ALICE, { ...d, deviceId: 9 }),
      idFor(ALICE, { ...d, messageId: "msg-other" }),
      idFor(BOB, d),
      `${ROOM}_${MSG}_${ALICE}_1`,
      `${ROOM}_${MSG}_${ALICE}_1_1_extra`,
    ]) {
      await assertFails(create(ALICE, d, forged));
    }
  });

  it("rejects a non-integer or missing attempt and deviceId", async () => {
    // `string()` on a float renders differently from an int, so a float would
    // fail the id check too — but only by accident. The explicit `is int` keeps
    // the denial deliberate, and covers the absent case, where the id would
    // otherwise interpolate the literal "null" on both sides and match.
    for (const bad of [
      { attempt: "1" },
      { attempt: 1.5 },
      { deviceId: "1" },
      { deviceId: 1.5 },
    ]) {
      await assertFails(create(ALICE, wakeup(bad)));
    }
    for (const field of ["attempt", "deviceId"]) {
      const d = wakeup();
      delete d[field];
      await assertFails(create(ALICE, d));
    }
  });

  it("rejects a non-positive attempt or deviceId", async () => {
    for (const bad of [
      { attempt: 0 },
      { attempt: -1 },
      { deviceId: 0 },
      { deviceId: -3 },
    ]) {
      await assertFails(create(ALICE, wakeup(bad)));
    }
  });

  it("caps attempt at a ceiling above anything the protocol produces", async () => {
    // `_maxResendTotalAttempts` is 15, so a real attempt never approaches 20.
    // The ceiling exists so the id space cannot be walked: without it a client
    // could mint a fresh id per integer forever. Denying an over-cap write costs
    // only the accelerator — the request is already on the message document,
    // which is what actually drives the repair.
    await assertSucceeds(create(ALICE, wakeup({ attempt: 15 })));
    await assertSucceeds(create(ALICE, wakeup({ attempt: 20 })));
    await assertFails(create(ALICE, wakeup({ attempt: 21 })));
    await assertFails(create(ALICE, wakeup({ attempt: 100000 })));
  });

  it("denies reads to everyone, including the author", async () => {
    // Nothing in the app reads these back — the Function consumes them with the
    // Admin SDK. Denying reads keeps the collection from becoming a side channel
    // that leaks which messages failed to decrypt.
    const id = await seedWakeup();
    await assertFails(as(ALICE).collection("resendWakeups").doc(id).get());
    await assertFails(as(BOB).collection("resendWakeups").doc(id).get());
  });

  it("denies update and delete", async () => {
    // Update is what makes the id a one-shot. Delete matters just as much: a
    // client that could delete a spent wakeup could recycle its id, which is the
    // whole ceiling undone.
    const id = await seedWakeup();
    await assertFails(
      as(ALICE).collection("resendWakeups").doc(id).update({ senderId: CAROL })
    );
    await assertFails(as(ALICE).collection("resendWakeups").doc(id).delete());
    await assertFails(as(BOB).collection("resendWakeups").doc(id).delete());
  });

  it("does not disturb the message-doc path the protocol relies on", async () => {
    // retryRequests is the actual request; the wakeup only accelerates it. If
    // adding this collection had broken participant writes to message documents,
    // the whole repair mechanism would stop working.
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("chatRooms")
        .doc(ROOM)
        .collection("messages")
        .doc("msg-1")
        .set({ senderId: BOB, receiverId: ALICE, text: "hi" });
    });
    await assertSucceeds(
      as(ALICE)
        .collection("chatRooms")
        .doc(ROOM)
        .collection("messages")
        .doc("msg-1")
        .update({ retryRequests: [`${ALICE}:1#1`] })
    );
    assert.ok(true);
  });
});
