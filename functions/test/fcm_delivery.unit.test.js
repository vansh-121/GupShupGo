const assert = require("node:assert/strict");
const { createFcmSender, shouldRetryDelivery } = require("../fcm-delivery");

const success = { success: true, messageId: "test-message" };
const invalid = { success: false, error: { code: "messaging/registration-token-not-registered" } };
const temporary = { success: false, error: { code: "messaging/server-unavailable" } };
const buildMessage = (token) => ({ token, data: { type: "call_cancelled", channelId: "call-1" } });

function senderWith(responses) {
  const cleaned = [];
  const batches = [];
  let offset = 0;
  const targets = responses.map((_, index) => ({
    token: `test-token-${index}`, source: "device", ref: { id: `device-${index}` },
  }));
  const send = createFcmSender({
    messaging: { sendEach: async (messages) => {
      batches.push(messages);
      const batch = responses.slice(offset, offset + messages.length);
      offset += messages.length;
      return { responses: batch, failureCount: batch.filter((response) => !response.success).length };
    } },
    removeNotificationTarget: async (target) => { cleaned.push(target); },
    logger: { log() {} },
  });
  return { run: () => send(targets, buildMessage), targets, cleaned, batches };
}

describe("FCM cancellation delivery retries", () => {
  it("retries a temporary failure even when every other token is invalid", async () => {
    const sender = senderWith([invalid, temporary]);
    const result = await sender.run();
    assert.equal(result.status, 500);
    assert.equal(result.body.transientFailureCount, 1);
    assert.equal(result.body.failureCount, 2);
    assert.equal(shouldRetryDelivery(result), true);
    assert.deepEqual(sender.cleaned, [sender.targets[0]]);
  });

  it("retries temporary failures after another device received cancellation", async () => {
    const result = await senderWith([success, invalid, temporary]).run();
    assert.equal(result.status, 200);
    assert.equal(result.body.successCount, 1);
    assert.equal(result.body.transientFailureCount, 1);
    assert.equal(shouldRetryDelivery(result), true);
  });

  it("does not retry when only permanently invalid tokens failed", async () => {
    for (const responses of [[invalid], [success, invalid], [success]]) {
      const result = await senderWith(responses).run();
      assert.equal(result.body.transientFailureCount, 0);
      assert.equal(shouldRetryDelivery(result), false);
    }
    assert.equal((await senderWith([invalid]).run()).status, 410);
  });

  it("classifies legacy invalid-token errors before removing their messages", async () => {
    const sender = senderWith([success, { success: false, error: {
      code: "messaging/unknown-error", message: "Requested entity was not found: private detail",
    } }]);
    const result = await sender.run();
    assert.equal(shouldRetryDelivery(result), false);
    assert.equal(sender.cleaned.length, 1);
    assert.ok(!JSON.stringify(result).includes("private detail"));
  });

  it("preserves retry and cleanup decisions across FCM's 500-message batch limit", async () => {
    const sender = senderWith([...Array(500).fill(success), invalid, temporary]);
    const result = await sender.run();
    assert.deepEqual(sender.batches.map((batch) => batch.length), [500, 2]);
    assert.equal(result.body.successCount, 500);
    assert.equal(shouldRetryDelivery(result), true);
    assert.deepEqual(sender.cleaned, [sender.targets[500]]);
  });

  it("propagates a transport failure so the Firestore trigger can retry", async () => {
    const failure = new Error("temporary transport failure");
    const send = createFcmSender({
      messaging: { sendEach: async () => { throw failure; } },
      removeNotificationTarget: async () => { assert.fail("must not delete tokens"); },
    });
    await assert.rejects(send([{ token: "test-token" }], buildMessage), (error) => error === failure);
  });
});
