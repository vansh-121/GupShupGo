"use strict";

const RING_MS = 60_000;
const TERMINAL = new Set(["answered", "declined", "ended", "missed"]);
function validCallRequest(body) {
  return body && ["callerId", "calleeId", "channelId"].every((key) =>
    typeof body[key] === "string" && /^[A-Za-z0-9_-]{1,128}$/.test(body[key])) &&
    body.callerId !== body.calleeId;
}
function callExpiry(call, now) {
  const existing = call.expiresAt?.toMillis?.();
  return Number.isFinite(existing) ? existing : now + RING_MS;
}
function cancellationData(id, before, after) {
  if (!before || (after && (before.status === after.status || !TERMINAL.has(after.status)))) return null;
  return {
    type: "call_cancelled", channelId: id, calleeId: before.calleeId,
    status: after?.status || "ended", acceptedDeviceId: after?.acceptedDeviceId || "",
  };
}
function androidCallConfig(expiresAt, now) {
  // Data-only, non-collapsible ringing pushes. Cancel and invite may arrive in either order.
  return { priority: "high", ttl: Math.max(0, Math.min(RING_MS, expiresAt - now)) };
}
module.exports = { RING_MS, validCallRequest, callExpiry, cancellationData, androidCallConfig };
