"use strict";

const assert = require("assert");
const crypto = require("crypto");
const {
  PRODUCTION_HOST,
  SANDBOX_HOST,
  createProviderToken,
  isInvalidVoipTokenResult,
  sendVoipPushes,
} = require("../voip-push");

function decodeBase64Url(value) {
  return Buffer.from(value.replace(/-/g, "+").replace(/_/g, "/"), "base64");
}

describe("APNs VoIP push helper", () => {
  const { privateKey, publicKey } = crypto.generateKeyPairSync("ec", {
    namedCurve: "P-256",
  });
  const privateKeyPem = privateKey.export({ type: "pkcs8", format: "pem" });

  it("creates a valid ES256 provider token", () => {
    const token = createProviderToken({
      teamId: "TEAM123456",
      keyId: "KEY1234567",
      privateKey: privateKeyPem,
      nowSeconds: 1_700_000_000,
    });
    const [encodedHeader, encodedClaims, encodedSignature] = token.split(".");

    assert.deepStrictEqual(
      JSON.parse(decodeBase64Url(encodedHeader).toString("utf8")),
      { alg: "ES256", kid: "KEY1234567" }
    );
    assert.deepStrictEqual(
      JSON.parse(decodeBase64Url(encodedClaims).toString("utf8")),
      { iss: "TEAM123456", iat: 1_700_000_000 }
    );
    assert.strictEqual(
      crypto.verify(
        "sha256",
        Buffer.from(`${encodedHeader}.${encodedClaims}`),
        { key: publicKey, dsaEncoding: "ieee-p1363" },
        decodeBase64Url(encodedSignature)
      ),
      true
    );
  });

  it("retries the other APNs environment for a mismatched device token", async () => {
    const hosts = [];
    const result = await sendVoipPushes({
      targets: [{ voipToken: "a".repeat(64), voipEnvironment: "sandbox" }],
      payload: { aps: { "content-available": 1 } },
      topic: "com.gupshupgo.app",
      teamId: "TEAM123456",
      keyId: "KEY1234567",
      privateKey: privateKeyPem,
      collapseId: "call-id",
      requestPush: async ({ host }) => {
        hosts.push(host);
        return hosts.length === 1
          ? { status: 400, reason: "BadDeviceToken", host }
          : { status: 200, reason: null, host };
      },
    });

    assert.deepStrictEqual(hosts, [SANDBOX_HOST, PRODUCTION_HOST]);
    assert.strictEqual(result.successes.length, 1);
    assert.strictEqual(result.failures.length, 0);
  });

  it("does not retry an authentication/configuration failure", async () => {
    const hosts = [];
    const result = await sendVoipPushes({
      targets: [{ voipToken: "b".repeat(64), voipEnvironment: "production" }],
      payload: { aps: { "content-available": 1 } },
      topic: "com.gupshupgo.app",
      teamId: "TEAM123456",
      keyId: "KEY1234567",
      privateKey: privateKeyPem,
      requestPush: async ({ host }) => {
        hosts.push(host);
        return { status: 403, reason: "InvalidProviderToken", host };
      },
    });

    assert.deepStrictEqual(hosts, [PRODUCTION_HOST]);
    assert.strictEqual(result.successes.length, 0);
    assert.strictEqual(result.failures.length, 1);
  });

  it("recognizes invalid tokens that should be removed", () => {
    assert.strictEqual(
      isInvalidVoipTokenResult({ status: 410, reason: "Unregistered" }),
      true
    );
    assert.strictEqual(
      isInvalidVoipTokenResult({ status: 500, reason: "InternalServerError" }),
      false
    );
  });
});
