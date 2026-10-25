"use strict";

const crypto = require("crypto");
const http2 = require("http2");

const PRODUCTION_HOST = "api.push.apple.com";
const SANDBOX_HOST = "api.sandbox.push.apple.com";
const RETRYABLE_ENVIRONMENT_REASONS = new Set([
  "BadDeviceToken",
  "DeviceTokenNotForTopic",
]);

function base64Url(value) {
  return Buffer.from(value)
    .toString("base64")
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
}

function normalizePrivateKey(privateKey) {
  return String(privateKey || "").replace(/\\n/g, "\n").trim();
}

function createProviderToken({ teamId, keyId, privateKey, nowSeconds }) {
  const issuedAt = nowSeconds || Math.floor(Date.now() / 1000);
  const header = base64Url(JSON.stringify({ alg: "ES256", kid: keyId }));
  const claims = base64Url(JSON.stringify({ iss: teamId, iat: issuedAt }));
  const unsignedToken = `${header}.${claims}`;
  const signature = crypto.sign("sha256", Buffer.from(unsignedToken), {
    key: normalizePrivateKey(privateKey),
    dsaEncoding: "ieee-p1363",
  });
  return `${unsignedToken}.${base64Url(signature)}`;
}

function parseResponseBody(body) {
  if (!body) return {};
  try {
    return JSON.parse(body);
  } catch (_) {
    return { reason: body };
  }
}

function requestVoipPush({
  host,
  token,
  topic,
  providerToken,
  payload,
  collapseId,
  expiration,
  timeoutMs = 8000,
}) {
  return new Promise((resolve) => {
    const client = http2.connect(`https://${host}`);
    let settled = false;

    const finish = (result) => {
      if (settled) return;
      settled = true;
      try {
        client.close();
      } catch (_) {}
      resolve(result);
    };

    client.on("error", (error) => {
      finish({ status: 0, reason: error.message, host });
    });

    const request = client.request({
      ":method": "POST",
      ":path": `/3/device/${token}`,
      authorization: `bearer ${providerToken}`,
      "apns-topic": `${topic}.voip`,
      "apns-push-type": "voip",
      "apns-priority": "10",
      "apns-expiration": String(expiration),
      ...(collapseId ? { "apns-collapse-id": collapseId } : {}),
      "content-type": "application/json",
    });

    let status = 0;
    let responseBody = "";
    request.setEncoding("utf8");
    request.setTimeout(timeoutMs, () => {
      request.close(http2.constants.NGHTTP2_CANCEL);
      finish({ status: 0, reason: "APNs request timed out", host });
    });
    request.on("response", (headers) => {
      status = Number(headers[":status"] || 0);
    });
    request.on("data", (chunk) => {
      responseBody += chunk;
    });
    request.on("end", () => {
      const parsed = parseResponseBody(responseBody);
      finish({ status, reason: parsed.reason || null, host });
    });
    request.on("error", (error) => {
      finish({ status: 0, reason: error.message, host });
    });
    request.end(JSON.stringify(payload));
  });
}

function preferredHosts(environment) {
  return environment === "sandbox"
    ? [SANDBOX_HOST, PRODUCTION_HOST]
    : [PRODUCTION_HOST, SANDBOX_HOST];
}

async function sendOneVoipPush({
  target,
  topic,
  providerToken,
  payload,
  collapseId,
  expiration,
  requestPush = requestVoipPush,
}) {
  const hosts = preferredHosts(target.voipEnvironment);
  let result = await requestPush({
    host: hosts[0],
    token: target.voipToken,
    topic,
    providerToken,
    payload,
    collapseId,
    expiration,
  });

  // Debug/development builds receive sandbox tokens while TestFlight/App Store
  // builds receive production tokens. If a stored environment hint is stale,
  // retry the other APNs gateway only for the two environment-mismatch errors.
  if (RETRYABLE_ENVIRONMENT_REASONS.has(result.reason)) {
    result = await requestPush({
      host: hosts[1],
      token: target.voipToken,
      topic,
      providerToken,
      payload,
      collapseId,
      expiration,
    });
  }

  return { target, ...result };
}

async function sendVoipPushes({
  targets,
  payload,
  topic,
  teamId,
  keyId,
  privateKey,
  collapseId,
  ttlSeconds = 60,
  requestPush,
}) {
  if (!targets || targets.length === 0) {
    return { successes: [], failures: [] };
  }
  if (!topic || !teamId || !keyId || !privateKey) {
    throw new Error("APNs VoIP credentials are not configured");
  }

  const providerToken = createProviderToken({ teamId, keyId, privateKey });
  const expiration = Math.floor(Date.now() / 1000) + ttlSeconds;
  const results = await Promise.all(
    targets.map((target) =>
      sendOneVoipPush({
        target,
        topic,
        providerToken,
        payload,
        collapseId,
        expiration,
        requestPush,
      })
    )
  );

  return {
    successes: results.filter((result) => result.status === 200),
    failures: results.filter((result) => result.status !== 200),
  };
}

function isInvalidVoipTokenResult(result) {
  return result.status === 410 ||
    result.reason === "Unregistered" ||
    result.reason === "BadDeviceToken";
}

module.exports = {
  PRODUCTION_HOST,
  SANDBOX_HOST,
  createProviderToken,
  isInvalidVoipTokenResult,
  requestVoipPush,
  sendVoipPushes,
};
