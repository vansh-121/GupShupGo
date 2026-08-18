// Security rules for `resendWakeups` — the collection that lets a recipient ask
// the server to wake a message's sender.
//
// Worth testing rather than eyeballing, because the collection is a delivery
// primitive: a doc here causes a silent high-priority push to whoever `senderId`
// names. Unconstrained, that is "make any user's phone wake up on demand". The
// rules bound it to people you already share a chat with — which sending them a
// message already does — and these cases are what hold that bound in place.
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
  at: serverTimestamp(),
  ...overrides,
});

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

describe("resendWakeups", () => {
  it("lets a participant ask for the other participant to be woken", async () => {
    await assertSucceeds(as(ALICE).collection("resendWakeups").add(wakeup()));
  });

  it("rejects an outsider entirely", async () => {
    // Carol is in no chat with either of them, so she has no business causing
    // Bob's phone to wake.
    await assertFails(
      as(CAROL)
        .collection("resendWakeups")
        .add(wakeup({ requesterId: CAROL }))
    );
  });

  it("rejects spoofing requesterId", async () => {
    // Otherwise the requesterId field would be decoration rather than identity.
    await assertFails(
      as(ALICE).collection("resendWakeups").add(wakeup({ requesterId: BOB }))
    );
  });

  it("rejects waking someone outside the room", async () => {
    // The case that matters most: Alice is a legitimate participant, so without
    // the hasAll check on senderId she could name any uid here and use a real
    // chat as a launchpad for pushing to strangers.
    await assertFails(
      as(ALICE).collection("resendWakeups").add(wakeup({ senderId: CAROL }))
    );
  });

  it("rejects naming yourself as the sender", async () => {
    // A self-wake loop: the push would come back to the device that asked for
    // it, which serves nothing and repeats.
    await assertFails(
      as(ALICE)
        .collection("resendWakeups")
        .add(wakeup({ senderId: ALICE, requesterId: ALICE }))
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
      as(ALICE)
        .collection("resendWakeups")
        .add(wakeup({ roomId: "uid-bob_uid-carol", senderId: CAROL }))
    );
  });

  it("rejects a nonexistent room", async () => {
    // The get() must fail closed. A missing room used to be the easy way to
    // sidestep a participant check written as an equality on a fetched field.
    await assertFails(
      as(ALICE).collection("resendWakeups").add(wakeup({ roomId: "no-such-room" }))
    );
  });

  it("rejects a wakeup for a message that does not exist", async () => {
    // Room participation alone used to be the whole bound, which let a
    // participant mint a wakeup per invented messageId — an unbounded silent
    // push generator aimed at someone they share a chat with.
    await assertFails(
      as(ALICE)
        .collection("resendWakeups")
        .add(wakeup({ messageId: "never-sent" }))
    );
  });

  it("rejects naming a sender who did not write the message", async () => {
    // Carol is a participant of nothing here, but the case that matters is the
    // shape: the uid being woken has to be the message's actual author, or a
    // real message becomes a launchpad for waking an arbitrary room member.
    await seedMessage({ senderId: ALICE });
    await assertFails(
      as(ALICE).collection("resendWakeups").add(wakeup({ senderId: BOB }))
    );
  });

  it("rejects a wakeup with no outstanding retry request", async () => {
    // This is the rate limit. A wakeup is only legitimate while a request is
    // actually pending on the document, so the ceiling is the volume the resend
    // protocol itself produces rather than however fast a client can loop.
    await seedMessage({ retryRequests: [] });
    await assertFails(
      as(ALICE).collection("resendWakeups").add(wakeup())
    );
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
    await assertFails(as(ALICE).collection("resendWakeups").add(wakeup()));
  });

  it("rejects a client-chosen timestamp", async () => {
    // The Function drops anything older than five minutes. If the client picked
    // the value, that gate would be advisory: backdate it and a replayed wakeup
    // sails through, or omit it and the staleness check is skipped entirely.
    await assertFails(
      as(ALICE).collection("resendWakeups").add(wakeup({ at: new Date() }))
    );
    await assertFails(
      as(ALICE)
        .collection("resendWakeups")
        .add(wakeup({ at: new Date(Date.now() - 60 * 60 * 1000) }))
    );
  });

  it("rejects an omitted timestamp", async () => {
    const noAt = wakeup();
    delete noAt.at;
    await assertFails(as(ALICE).collection("resendWakeups").add(noAt));
  });

  it("rejects unauthenticated writes", async () => {
    await assertFails(
      testEnv.unauthenticatedContext().firestore()
        .collection("resendWakeups")
        .add(wakeup())
    );
  });

  it("rejects malformed docs", async () => {
    for (const bad of [
      { senderId: 42 },
      { roomId: null },
      { messageId: 7 },
    ]) {
      await assertFails(
        as(ALICE).collection("resendWakeups").add(wakeup(bad))
      );
    }
  });

  it("denies reads to everyone, including the author", async () => {
    // Nothing in the app reads these back — the Function consumes them with the
    // Admin SDK. Denying reads keeps the collection from becoming a side channel
    // that leaks which messages failed to decrypt.
    let id;
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const ref = await ctx.firestore().collection("resendWakeups").add(wakeup());
      id = ref.id;
    });
    await assertFails(as(ALICE).collection("resendWakeups").doc(id).get());
    await assertFails(as(BOB).collection("resendWakeups").doc(id).get());
  });

  it("denies update and delete — only the Function retires a wakeup", async () => {
    let id;
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const ref = await ctx.firestore().collection("resendWakeups").add(wakeup());
      id = ref.id;
    });
    await assertFails(
      as(ALICE).collection("resendWakeups").doc(id).update({ senderId: CAROL })
    );
    await assertFails(as(ALICE).collection("resendWakeups").doc(id).delete());
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
