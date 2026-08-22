// Security rules for `chatRooms/{room}/messages/{id}` updates.
//
// Both "edit" and "delete for everyone" are document *updates*, not deletes, and
// the update rule has to stay open to the other participant — read receipts,
// "delete for me" and resend requests are all writes by someone who did not send
// the message. So "sender-only" cannot come from the rule that decides *who* may
// update; it has to come from a rule about *which fields*.
//
// That split is what these tests pin down, in both directions:
//
//   • The peer's legitimate writes still work — status, deletedFor,
//     retryRequests. Break these and read receipts or the E2EE resend protocol
//     stop working, which is a data-loss bug, not a security one.
//   • The peer cannot touch content — no tombstoning someone else's message, no
//     rewriting the plaintext `text` a legacy v1 document carries in the clear,
//     no publishing envelopes under someone else's name.
//
// The `senderId` case is the load-bearing one and the easiest to leave out. If a
// participant can reassign senderId, every ownership check here is a two-step
// away from being satisfied: claim the message, then edit it as its "sender".
//
// Run:  cd functions && npm run test:rules

const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");
const fs = require("fs");
const path = require("path");

const firebaseCompat = require("firebase/compat/app");
require("firebase/compat/firestore");
const fb = firebaseCompat.default || firebaseCompat;
const arrayUnion = (...v) => fb.firestore.FieldValue.arrayUnion(...v);
const arrayRemove = (...v) => fb.firestore.FieldValue.arrayRemove(...v);
const deleteField = () => fb.firestore.FieldValue.delete();
const serverTimestamp = () => fb.firestore.FieldValue.serverTimestamp();

// Bob sends, Alice receives. Carol is in neither room.
const ALICE = "uid-alice";
const BOB = "uid-bob";
const CAROL = "uid-carol";
const ROOM = "uid-alice_uid-bob";
const MSG = "msg-1";

let testEnv;

before(async function () {
  this.timeout(30000);
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

// A v2 (encrypted) message from Bob to Alice, as the send path writes it.
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
        text: "",
        type: "text",
        schemaVersion: 2,
        status: "sent",
        senderDeviceId: 1,
        envelopes: { "uid-alice:1": { body: "ciphertext" } },
        timestamp: new Date("2026-08-20T10:00:00Z"),
        ...overrides,
      });
  });

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx
      .firestore()
      .collection("chatRooms")
      .doc(ROOM)
      .set({ participants: [ALICE, BOB] });
  });
  await seedMessage();
});

const msgRef = (uid) =>
  testEnv
    .authenticatedContext(uid)
    .firestore()
    .collection("chatRooms")
    .doc(ROOM)
    .collection("messages")
    .doc(MSG);

const update = (uid, data) => msgRef(uid).update(data);

describe("message updates: the peer's legitimate writes", () => {
  it("lets the recipient mark it delivered and read", async () => {
    // markMessagesAsDelivered / markMessagesAsRead. The whole reason the update
    // rule cannot simply be sender-only.
    await assertSucceeds(update(ALICE, { status: "delivered" }));
    await assertSucceeds(update(ALICE, { status: "read" }));
  });

  it("lets either participant hide it from themselves", async () => {
    // "Delete for me" — ChatService.deleteMessageForMe, on a message the writer
    // did not send.
    await assertSucceeds(update(ALICE, { deletedFor: arrayUnion(ALICE) }));
    await assertSucceeds(update(BOB, { deletedFor: arrayUnion(BOB) }));
  });

  it("lets the recipient publish a resend request", async () => {
    // The E2EE repair path: an undecryptable message is fixed by the recipient
    // adding a tag here and the sender answering it.
    await assertSucceeds(
      update(ALICE, { retryRequests: arrayUnion(`${ALICE}:1#1`) })
    );
  });

  it("lets the sender answer one, publishing a fresh envelope", async () => {
    await assertSucceeds(
      update(BOB, {
        "envelopes.uid-alice:1": { body: "repaired" },
        retryRequests: arrayRemove(`${ALICE}:1#1`),
      })
    );
  });

  it("still refuses an outsider anything at all", async () => {
    await assertFails(update(CAROL, { status: "read" }));
  });
});

describe("message updates: content is the sender's", () => {
  it("lets the sender tombstone and edit its own message", async () => {
    // deleteMessageForEveryone, then editMessage. Both must keep working — the
    // gate is about ownership, not about forbidding the operation.
    await assertSucceeds(
      update(BOB, {
        deletedForEveryone: true,
        text: "",
        mediaUrl: null,
        envelopes: deleteField(),
      })
    );
    await seedMessage();
    await assertSucceeds(
      update(BOB, {
        envelopes: { "uid-alice:1": { body: "edited" } },
        senderDeviceId: 1,
        text: "",
        editedAt: serverTimestamp(),
      })
    );
  });

  it("refuses to let the recipient tombstone it", async () => {
    // The plain-boolean vandalism case: no crypto needed, and it renders as
    // "This message was deleted" on both sides.
    await assertFails(update(ALICE, { deletedForEveryone: true }));
  });

  it("refuses to let the recipient rewrite the text", async () => {
    // On a v1 document `text` is the message, in the clear, so this would be a
    // straight content substitution.
    await seedMessage({ schemaVersion: 1, text: "the original", envelopes: {} });
    await assertFails(update(ALICE, { text: "something Bob never said" }));
  });

  it("refuses to let the recipient replace the envelopes", async () => {
    await assertFails(
      update(ALICE, { envelopes: { "uid-alice:1": { body: "forged" } } })
    );
  });

  it("refuses to let the recipient forge an edit marker", async () => {
    await assertFails(update(ALICE, { editedAt: serverTimestamp() }));
  });

  it("refuses to let the recipient strip a v1 link preview", async () => {
    await seedMessage({ schemaVersion: 1, linkPreviewTitle: "A title" });
    await assertFails(update(ALICE, { linkPreviewTitle: deleteField() }));
  });

  it("refuses to let the recipient forge reply attribution", async () => {
    await seedMessage({
      schemaVersion: 1,
      replyToMessageId: "original-msg",
      replyToSenderName: "Alice",
      replyToSenderId: ALICE,
      replyToType: "text",
    });
    await assertFails(update(ALICE, { replyToSenderName: "Mallory" }));
    await assertFails(update(ALICE, { replyToMessageId: "fake-msg" }));
    await assertFails(update(ALICE, { replyToSenderId: CAROL }));
  });

  it("refuses to let the recipient forge status-reply fields", async () => {
    await seedMessage({
      schemaVersion: 1,
      statusReplyOwnerId: BOB,
      statusReplyOwnerName: "Bob",
      statusReplyText: "My status text",
    });
    await assertFails(update(ALICE, { statusReplyText: "Forged status" }));
    await assertFails(update(ALICE, { statusReplyOwnerName: "Alice" }));
  });

  it("refuses to let the recipient claim the message", async () => {
    // The escalation the field list exists to close. Without senderId in it,
    // Alice takes ownership here and every assertFails above becomes a
    // two-write sequence that succeeds.
    await assertFails(update(ALICE, { senderId: ALICE }));
  });

  it("refuses to let the recipient move it in time", async () => {
    await assertFails(
      update(ALICE, { timestamp: new Date("2020-01-01T00:00:00Z") })
    );
  });

  it("refuses a legitimate write smuggling a content field alongside", async () => {
    // The rule is on the affected-key set, not on the operation, so a receipt
    // update carrying a tombstone with it fails as a whole.
    await assertFails(
      update(ALICE, { status: "read", deletedForEveryone: true })
    );
  });
});

describe('message updates: "delete for me" only hides from you', () => {
  it("refuses to let a participant hide it from the other side", async () => {
    // Would make a message vanish from the peer's chat with no trace.
    await assertFails(update(ALICE, { deletedFor: arrayUnion(BOB) }));
    await assertFails(update(ALICE, { deletedFor: [ALICE, BOB] }));
  });

  it("refuses to let a participant un-hide it for the other side", async () => {
    await seedMessage({ deletedFor: [BOB] });
    await assertFails(update(ALICE, { deletedFor: arrayRemove(BOB) }));
    // Adding yourself is fine, but not while dropping their entry.
    await assertFails(update(ALICE, { deletedFor: [ALICE] }));
    await assertSucceeds(update(ALICE, { deletedFor: [BOB, ALICE] }));
  });

  it("lets you drop your own entry", async () => {
    // Nothing in the app does this today; it is the writer's own visibility, so
    // the rule has no reason to care. Worth asserting because emptying the array
    // is the input that broke the first version of this rule.
    await seedMessage({ deletedFor: [ALICE] });
    await assertSucceeds(update(ALICE, { deletedFor: arrayRemove(ALICE) }));
    await seedMessage({ deletedFor: [ALICE, BOB] });
    await assertSucceeds(update(ALICE, { deletedFor: arrayRemove(ALICE) }));
  });
});
