const { initializeTestEnvironment, assertFails, assertSucceeds } = require("@firebase/rules-unit-testing");
const fs = require("node:fs");
const assert = require("node:assert/strict");
const path = require("node:path");
const firebaseCompat = require("firebase/compat/app");
require("firebase/compat/firestore");
const fb = firebaseCompat.default || firebaseCompat;
const timestamp = () => fb.firestore.FieldValue.serverTimestamp();
let env;
const call = () => ({ callerId: "alice", calleeId: "bob", status: "ringing", createdAt: timestamp() });
const db = (uid) => env.authenticatedContext(uid).firestore();

describe("native call state and receipt rules", function () {
  this.timeout(20000);
  before(async () => {
    env = await initializeTestEnvironment({ projectId: "gsg-native-call-test",
      firestore: { rules: fs.readFileSync(path.join(__dirname, "../../firestore.rules"), "utf8") } });
  });
  beforeEach(async () => {
    await env.clearFirestore();
    await env.withSecurityRulesDisabled(async (context) => {
      const store = context.firestore();
      await store.doc("calls/test").set(call());
      await store.doc("users/bob/devices/phone").set({ keyBundle: { identityKey: "preserve" } });
    });
  });
  after(async () => env?.cleanup());

  it("only the caller creates ringing calls", async () => {
    await assertSucceeds(db("alice").doc("calls/new").set(call()));
    await assertFails(db("bob").doc("calls/new2").set(call()));
    await assertFails(db("mallory").doc("calls/new3").set(call()));
  });
  it("only the callee answers and must identify an owned device", async () => {
    const answer = { status: "answered", acceptedDeviceId: "phone", answeredAt: timestamp() };
    await assertFails(db("alice").doc("calls/test").update(answer));
    await assertFails(db("bob").doc("calls/test").update({ ...answer, acceptedDeviceId: "unregistered" }));
    await assertSucceeds(db("bob").doc("calls/test").update(answer));
    await assertFails(db("bob").doc("calls/test").update({ acceptedDeviceId: "another" }));
  });
  it("confirms a pending device registration before claiming the call", async () => {
    const bob = db("bob");
    const answer = { status: "answered", acceptedDeviceId: "new-phone", answeredAt: timestamp() };
    await assertFails(bob.doc("calls/test").update(answer));
    await assertSucceeds(bob.doc("users/bob/devices/new-phone").set({
      deviceId: "new-phone", platform: "android", lastSeenAt: timestamp(),
    }, { merge: true }));
    await assertSucceeds(bob.runTransaction(async (tx) => {
      const ref = bob.doc("calls/test");
      const call = await tx.get(ref);
      if (call.data().status === "ringing") tx.update(ref, answer);
    }));
    assert.equal((await bob.doc("calls/test").get()).data().acceptedDeviceId, "new-phone");
  });
  it("acceptance registration keeps existing tokens and encryption keys", async () => {
    const phone = db("bob").doc("users/bob/devices/phone");
    await assertSucceeds(phone.set({ fcmToken: "existing-token", nativeCallsVersion: 1 }, { merge: true }));
    await assertSucceeds(phone.set({ deviceId: "phone", platform: "android", lastSeenAt: timestamp() }, { merge: true }));
    const data = (await phone.get()).data();
    assert.equal(data.fcmToken, "existing-token");
    assert.equal(data.nativeCallsVersion, 1);
    assert.equal(data.keyBundle.identityKey, "preserve");
  });
  it("terminal calls cannot be revived or changed by a late decline/timeout", async () => {
    await assertSucceeds(db("alice").doc("calls/test").update({ status: "ended" }));
    for (const status of ["ringing", "answered", "declined", "missed"]) {
      await assertFails(db("bob").doc("calls/test").update({ status }));
    }
  });
  it("an answered call cannot be overwritten by a timeout", async () => {
    await assertSucceeds(db("bob").doc("calls/test").update({ status: "answered" }));
    await assertFails(db("alice").doc("calls/test").update({ status: "missed" }));
    await assertSucceeds(db("alice").doc("calls/test").update({ status: "ended" }));
  });
  it("protects participants and server expiry while allowing encryption negotiation", async () => {
    await assertFails(db("alice").doc("calls/test").update({ calleeId: "mallory" }));
    await assertFails(db("bob").doc("calls/test").update({ expiresAt: timestamp() }));
    await assertSucceeds(db("alice").doc("calls/test").update({ e2ee: true }));
  });
  it("rejects Accept after the server deadline", async () => {
    await env.withSecurityRulesDisabled((context) => context.firestore().doc("calls/test")
      .update({ expiresAt: fb.firestore.Timestamp.fromMillis(1000) }));
    await assertFails(db("bob").doc("calls/test").update({ status: "answered" }));
  });
  it("accepts only bounded callee-owned device receipts", async () => {
    const receipt = { deviceId: "phone", event: "notification_posted", recordedAt: timestamp(), occurredAtMs: 1234 };
    await assertSucceeds(db("bob").doc("calls/test/deliveryReceipts/phone_notification_posted").set(receipt));
    await assertFails(db("alice").doc("calls/test/deliveryReceipts/phone_notification_posted").set(receipt));
    await assertFails(db("bob").doc("calls/test/deliveryReceipts/random").set(receipt));
    await assertFails(db("bob").doc("calls/test/deliveryReceipts/phone_notification_posted").set({ ...receipt, rawToken: "private" }));
  });
});
