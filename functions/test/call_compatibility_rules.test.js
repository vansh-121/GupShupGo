const { initializeTestEnvironment, assertFails, assertSucceeds } = require("@firebase/rules-unit-testing");
const fs = require("node:fs");
const path = require("node:path");
const firebaseCompat = require("firebase/compat/app");
require("firebase/compat/firestore");
const fb = firebaseCompat.default || firebaseCompat;
const timestamp = () => fb.firestore.FieldValue.serverTimestamp();
const ringingCall = () => ({ callerId: "alice", calleeId: "bob", status: "ringing",
  createdAt: timestamp(), answeredAt: null, endedAt: null });
let env;
const db = (uid) => env.authenticatedContext(uid).firestore();

describe("released call client compatibility", function () {
  this.timeout(30000);
  before(async () => {
    env = await initializeTestEnvironment({ projectId: "gsg-call-compat-test",
      firestore: { rules: fs.readFileSync(path.join(__dirname, "../../firestore.rules"), "utf8") } });
  });
  beforeEach(async () => { await env.clearFirestore(); });
  after(async () => env?.cleanup());

  for (const channelId of ["call_AbCdEfGhIjKlMnOpQrSt", "e0fb66da-8201-4cb3-82d5-613b59b0a492"]) {
    it(`allows a legacy receiver to answer ${channelId.startsWith("call_") ? "old" : "new"} call IDs`, async () => {
      await assertSucceeds(db("alice").doc(`calls/${channelId}`).set(ringingCall()));
      // The new function adds a deadline, but old clients do not have a device registry.
      await env.withSecurityRulesDisabled((context) => context.firestore().doc(`calls/${channelId}`)
        .update({ expiresAt: fb.firestore.Timestamp.fromMillis(Date.now() + 60000) }));
      await assertSucceeds(db("bob").doc(`calls/${channelId}`).update({
        status: "answered", answeredAt: timestamp(),
      }));
      await assertSucceeds(db("alice").doc(`calls/${channelId}`).update({ e2ee: true }));
      await assertSucceeds(db("bob").doc(`calls/${channelId}`).update({ e2ee: false }));
      await assertSucceeds(db("bob").doc(`calls/${channelId}`).update({ status: "ended", endedAt: timestamp() }));
      await assertSucceeds(db("alice").doc(`calls/${channelId}`).delete());
    });
  }

  it("allows a native receiver to claim a call created with the released legacy schema", async () => {
    const bob = db("bob");
    const ref = bob.doc("calls/call_legacy");
    await assertSucceeds(db("alice").doc(ref.path).set(ringingCall()));
    await assertSucceeds(db("bob").doc("users/bob/devices/phone").set({
      fcmToken: "test-token", platform: "android", nativeCallsVersion: 1,
    }));
    await assertSucceeds(bob.runTransaction(async (tx) => {
      const call = await tx.get(ref);
      if (call.data().status === "ringing") tx.update(ref, {
        status: "answered", answeredAt: timestamp(), acceptedDeviceId: "phone",
      });
    }));
    await assertFails(ref.update({ acceptedDeviceId: null }));
    await assertFails(ref.update({ acceptedDeviceId: "another-device" }));
  });

  it("treats a null device claim as legacy without accepting malformed claims", async () => {
    await assertSucceeds(db("alice").doc("calls/test").set(ringingCall()));
    for (const acceptedDeviceId of ["", 123, "not-registered"]) {
      await assertFails(db("bob").doc("calls/test").update({ status: "answered", acceptedDeviceId }));
    }
    await assertSucceeds(db("bob").doc("calls/test").update({
      status: "answered", answeredAt: timestamp(), acceptedDeviceId: null,
    }));
  });

  for (const status of ["declined", "missed"]) {
    for (const actor of ["alice", "bob"]) {
      it(`allows ${actor}'s old dispose cleanup after ${status}`, async () => {
        await assertSucceeds(db("alice").doc("calls/test").set(ringingCall()));
        await assertSucceeds(db("bob").doc("calls/test").update({ status, endedAt: timestamp() }));
        await assertSucceeds(db(actor).doc("calls/test").update({ status: "ended", endedAt: timestamp() }));
        await assertFails(db(actor).doc("calls/test").update({ status: "ringing" }));
        await assertSucceeds(db(actor).doc("calls/test").delete());
      });
    }
  }

  it("limits terminal legacy cleanup to status and endedAt", async () => {
    await assertSucceeds(db("alice").doc("calls/test").set(ringingCall()));
    await assertSucceeds(db("bob").doc("calls/test").update({ status: "declined" }));
    await assertFails(db("bob").doc("calls/test").update({ status: "ended", acceptedDeviceId: "phone" }));
    await assertFails(db("bob").doc("calls/test").update({ status: "ended", e2ee: true }));
  });

  it("keeps legacy accept subject to expiry, identity, and terminal-state checks", async () => {
    await assertSucceeds(db("alice").doc("calls/test").set(ringingCall()));
    await assertFails(db("alice").doc("calls/test").update({ status: "answered" }));
    await assertFails(db("mallory").doc("calls/test").get());
    await assertFails(db("mallory").doc("calls/test").update({ status: "ended" }));
    await assertFails(db("mallory").doc("calls/test").delete());
    await env.withSecurityRulesDisabled((context) => context.firestore().doc("calls/test")
      .update({ expiresAt: fb.firestore.Timestamp.fromMillis(1000) }));
    await assertFails(db("bob").doc("calls/test").update({ status: "answered", answeredAt: timestamp() }));
    await assertFails(db("bob").doc("calls/test").update({ expiresAt: fb.firestore.Timestamp.fromMillis(Date.now() + 60000) }));
    await assertSucceeds(db("alice").doc("calls/test").update({ status: "ended" }));
    await assertFails(db("bob").doc("calls/test").update({ status: "answered" }));
    await assertFails(db("bob").doc("calls/test").update({ status: "missed" }));
  });

  it("preserves both token registration formats without requiring native metadata", async () => {
    await assertSucceeds(db("bob").doc("users/bob").set({ name: "Bob", fcmToken: "legacy-token" }));
    const phone = db("bob").doc("users/bob/devices/phone");
    await assertSucceeds(phone.set({ keyBundle: { identityKey: "existing-public-key" } }));
    await assertSucceeds(phone.set({ fcmToken: "device-token" }, { merge: true }));
    const stored = await phone.get();
    if (stored.data().keyBundle.identityKey !== "existing-public-key") throw new Error("Key bundle was lost");
    await assertFails(db("alice").doc("users/bob").update({ fcmToken: "replacement" }));
    await assertFails(db("alice").doc(phone.path).update({ fcmToken: "replacement" }));
  });
});
