const assert = require("node:assert/strict");
const { validCallRequest, callExpiry, cancellationData, androidCallConfig } = require("../call-delivery");

describe("native call delivery protocol", () => {
  it("requires unambiguous participant and channel identifiers", () => {
    assert.equal(validCallRequest({ callerId: "a", calleeId: "b", channelId: "call_123" }), true);
    for (const body of [null, {}, { callerId: "a", calleeId: "a", channelId: "c" },
      { callerId: "a", calleeId: "b", channelId: "a/b" },
      { callerId: {}, calleeId: "b", channelId: "c" }]) assert.ok(!validCallRequest(body));
  });
  it("does not extend the ring window on endpoint retries", () => {
    assert.equal(callExpiry({}, 1000), 61000);
    assert.equal(callExpiry({ expiresAt: { toMillis: () => 61000 } }, 45000), 61000);
    assert.equal(androidCallConfig(61000, 45000).ttl, 16000);
    assert.equal(androidCallConfig(61000, 62000).ttl, 0);
  });
  it("cancels sibling devices after answer and preserves the answering device id", () => {
    const data = cancellationData("c", { calleeId: "b", status: "ringing" },
      { status: "answered", acceptedDeviceId: "phone" });
    assert.deepEqual(data, { type: "call_cancelled", channelId: "c", calleeId: "b",
      status: "answered", acceptedDeviceId: "phone" });
  });
  it("cancels on legacy deletion and every terminal transition", () => {
    const before = { calleeId: "b", status: "ringing" };
    assert.equal(cancellationData("c", before, undefined).status, "ended");
    for (const status of ["ended", "missed", "declined"]) {
      assert.equal(cancellationData("c", before, { status }).status, status);
    }
  });
  it("does not send cancellation for creation, expiry metadata, or encryption changes", () => {
    assert.equal(cancellationData("c", undefined, { status: "ringing" }), null);
    assert.equal(cancellationData("c", { status: "ringing" }, { status: "ringing", e2ee: true }), null);
  });
});
