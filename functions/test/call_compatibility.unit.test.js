const assert = require("node:assert/strict");
const { collectNotificationTargets, nativeCallTargets } = require("../notification-targets");
const { validCallRequest, incomingCallData, cancellationData } = require("../call-delivery");
const { createFcmSender } = require("../fcm-delivery");

const userRef = { id: "bob", path: "users/bob" };
const device = (id, data) => ({ ref: { id, path: `users/bob/devices/${id}` }, data: () => data });
const nativeDevice = (id, token) => device(id, {
  fcmToken: token, platform: "android", nativeCallsVersion: 1,
});

describe("notification registration compatibility", () => {
  it("reaches an old install with only users/{uid}.fcmToken", () => {
    const targets = collectNotificationTargets(userRef, { fcmToken: "old-token" }, []);
    assert.equal(targets.length, 1);
    assert.equal(targets[0].token, "old-token");
    assert.equal(targets[0].ref, userRef);
    assert.equal(targets[0].source, "legacy");
    assert.deepEqual(nativeCallTargets(targets), []);
  });

  it("reaches old device records without requiring new capability fields", () => {
    const oldPhone = device("old-phone", { fcmToken: "old-token" });
    const targets = collectNotificationTargets(userRef, {}, [oldPhone]);
    assert.equal(targets.length, 1);
    assert.equal(targets[0].ref, oldPhone.ref);
    assert.equal(targets[0].nativeCallsVersion, 0);
    assert.deepEqual(nativeCallTargets(targets), []);
  });

  it("delivers once per token across account and device registrations", () => {
    const targets = collectNotificationTargets(userRef, { fcmToken: "old-token" }, [
      device("old-phone", { fcmToken: "old-token" }),
      nativeDevice("new-phone", "new-token"),
    ]);
    assert.deepEqual(targets.map((target) => target.token).sort(), ["new-token", "old-token"]);
    assert.deepEqual(nativeCallTargets(targets).map((target) => target.token), ["new-token"]);
  });

  it("keeps a distinct account-level token during a gradual device migration", () => {
    const targets = collectNotificationTargets(userRef, { fcmToken: "still-installed" }, [
      nativeDevice("new-phone", "new-token"),
    ]);
    assert.deepEqual(targets.map((target) => target.token).sort(), ["new-token", "still-installed"]);
  });

  for (const reverse of [false, true]) {
    it(`retains native cancellation after an upgrade (${reverse ? "new" : "old"} record first)`, () => {
      const records = [device("old-id", { fcmToken: "same-token" }), nativeDevice("new-id", "same-token")];
      if (reverse) records.reverse();
      const targets = collectNotificationTargets(userRef, { fcmToken: "same-token" }, records);
      assert.equal(targets.length, 1);
      assert.equal(targets[0].ref.id, "new-id");
      assert.deepEqual(nativeCallTargets(targets), targets);
    });
  }

  it("does not send native commands to unknown capabilities or iOS installs", () => {
    const records = [
      device("missing", { fcmToken: "missing" }),
      device("null", { fcmToken: "null", platform: "android", nativeCallsVersion: null }),
      device("string", { fcmToken: "string", platform: "android", nativeCallsVersion: "1" }),
      device("boolean", { fcmToken: "boolean", platform: "android", nativeCallsVersion: true }),
      device("ios", { fcmToken: "ios", platform: "ios", nativeCallsVersion: 1 }),
      nativeDevice("native", "native"),
    ];
    const targets = collectNotificationTargets(userRef, {}, records);
    assert.equal(targets.length, records.length);
    assert.deepEqual(nativeCallTargets(targets).map((target) => target.token), ["native"]);
  });

  it("preserves a separate VoIP registration while deduplicating FCM", () => {
    const targets = collectNotificationTargets(userRef, {}, [
      device("voip", { fcmToken: "same-token", voipToken: "voip-token", platform: "ios" }),
      nativeDevice("native", "same-token"),
    ]);
    assert.equal(targets.filter((target) => target.token).length, 1);
    assert.equal(targets.find((target) => target.voipToken)?.voipToken, "voip-token");
  });

  it("ignores incomplete registrations without throwing", () => {
    assert.deepEqual(collectNotificationTargets(userRef, {}, [
      device("empty", {}), device("invalid", { fcmToken: 123 }), device("missing", undefined),
    ]), []);
  });
});

describe("old and new call protocol interoperability", () => {
  const formats = {
    legacy: "call_AbCdEfGhIjKlMnOpQrSt",
    native: "e0fb66da-8201-4cb3-82d5-613b59b0a492",
  };

  for (const [caller, channelId] of Object.entries(formats)) {
    for (const receiver of ["legacy", "native"]) {
      it(`delivers a ${caller} caller's request to a ${receiver} receiver`, async () => {
        // These are the original four request fields; no version field is needed.
        const request = { callerId: "alice", calleeId: "bob", channelId, isAudioOnly: true };
        assert.equal(validCallRequest(request), true);
        const targets = receiver === "legacy"
          ? collectNotificationTargets(userRef, { fcmToken: "receiver-token" }, [])
          : collectNotificationTargets(userRef, {}, [nativeDevice("phone", "receiver-token")]);
        const delivered = [];
        const send = createFcmSender({
          messaging: { sendEach: async (messages) => {
            delivered.push(...messages);
            return { responses: messages.map(() => ({ success: true, messageId: "test-message" })) };
          } },
          removeNotificationTarget: async () => assert.fail("valid registration must be retained"),
          logger: { log() {} },
        });
        const result = await send(targets, (token) => ({ token,
          data: incomingCallData({ ...request, callerName: "Alice", expiresAt: 61000 }),
        }));
        assert.equal(result.status, 200);
        assert.equal(result.body.success, true);
        assert.equal(delivered.length, 1);
        assert.deepEqual(delivered[0].data, {
          callerId: "alice", calleeId: "bob", channelId, callerName: "Alice", callerPhotoUrl: "",
          type: "incoming_call", isAudioOnly: "true", expiresAt: "61000",
        });
        assert.ok(Object.values(delivered[0].data).every((value) => typeof value === "string"));
      });
    }
  }

  it("preserves video-by-default and the legacy string audio flag", () => {
    for (const [isAudioOnly, expected] of [[undefined, "false"], [false, "false"], ["false", "false"],
      [true, "true"], ["true", "true"]]) {
      const data = incomingCallData({ callerId: "alice", calleeId: "bob", channelId: formats.legacy,
        isAudioOnly, expiresAt: 61000 });
      assert.equal(data.isAudioOnly, expected);
      assert.equal(data.callerName, "alice");
    }
  });

  it("cancels native siblings when a legacy receiver answers without a device claim", () => {
    const targets = collectNotificationTargets(userRef, { fcmToken: "legacy-token" }, [
      nativeDevice("native-phone", "native-token"),
    ]);
    const data = cancellationData(formats.legacy, { calleeId: "bob", status: "ringing" },
      { calleeId: "bob", status: "answered" });
    assert.equal(data.acceptedDeviceId, "");
    assert.deepEqual(nativeCallTargets(targets).map((target) => target.token), ["native-token"]);
  });

  it("still cancels native ringing when an older app deletes the call document", () => {
    const data = cancellationData(formats.legacy, { calleeId: "bob", status: "answered" }, undefined);
    assert.equal(data.status, "ended");
    assert.equal(data.channelId, formats.legacy);
  });
});
