"use strict";

/**
 * Unit tests for AdMob SSV signature verification.
 *
 * These generate their own EC keypair and sign a callback URL the way Google
 * does, so they prove the byte slicing and the signature encoding without
 * touching the network, Firestore, or the emulator.
 *
 * Run: `npm run test:unit`
 */

const assert = require("assert");
const crypto = require("crypto");

const {
  VerifierKeyCache,
  parseVerifierKeys,
  signedContentFrom,
  verifyWithPem,
} = require("../ads/ssv");

/** An EC P-256 keypair, the curve AdMob signs with. */
function keypair() {
  const { publicKey, privateKey } = crypto.generateKeyPairSync("ec", {
    namedCurve: "prime256v1",
  });
  return {
    privateKey,
    pem: publicKey.export({ type: "spki", format: "pem" }).toString(),
  };
}

/**
 * Builds a callback URL the way AdMob does: the signed parameters, then
 * `signature`, then `key_id`, in that order.
 */
function signedCallbackUrl(params, key, keyId) {
  const query = Object.entries(params)
    .map(([k, v]) => `${k}=${encodeURIComponent(v)}`)
    .join("&");
  const signature = crypto
    .sign("sha256", Buffer.from(query, "utf8"), key.privateKey)
    .toString("base64url");
  return {
    url: `/admobSsv?${query}&signature=${signature}&key_id=${keyId}`,
    query,
    signature,
  };
}

/** A realistic reward callback, `custom_data` JSON and all. */
const REWARD_PARAMS = {
  ad_network: "5450213213286189855",
  ad_unit: "3145500055",
  custom_data: JSON.stringify({
    uid: "aBcD1234efGH5678ijKL",
    type: "restore",
    roomId: "room_abc-123",
  }),
  reward_amount: "1",
  reward_item: "restore",
  timestamp: "1720000000000",
  transaction_id: "1a2b3c4d5e6f7788",
  user_id: "aBcD1234efGH5678ijKL",
};

describe("signedContentFrom", () => {
  it("returns the query string up to but excluding &signature=", () => {
    const key = keypair();
    const { url, query } = signedCallbackUrl(REWARD_PARAMS, key, "3335741209");
    assert.strictEqual(signedContentFrom(url), query);
  });

  it("keeps custom_data percent-encoded exactly as it arrived", () => {
    const key = keypair();
    const { url } = signedCallbackUrl(REWARD_PARAMS, key, "3335741209");
    const content = signedContentFrom(url);
    // The whole point of slicing the raw URL: re-encoding would change these.
    assert.ok(content.includes("custom_data=%7B%22uid%22"));
    assert.ok(!content.includes("signature="));
  });

  it("survives an absolute URL, not just a path", () => {
    const key = keypair();
    const { query } = signedCallbackUrl(REWARD_PARAMS, key, "1");
    const absolute = `https://us-central1-x.cloudfunctions.net/admobSsv?${query}&signature=zz&key_id=1`;
    assert.strictEqual(signedContentFrom(absolute), query);
  });

  it("rejects URLs that are not shaped like a callback", () => {
    assert.strictEqual(signedContentFrom(""), null);
    assert.strictEqual(signedContentFrom(null), null);
    assert.strictEqual(signedContentFrom(undefined), null);
    assert.strictEqual(signedContentFrom("/admobSsv"), null);
    // No signed content before the signature.
    assert.strictEqual(signedContentFrom("/admobSsv?&signature=abc"), null);
    // A `signature` that isn't the delimiter parameter.
    assert.strictEqual(signedContentFrom("/admobSsv?a=1&b=2"), null);
  });
});

describe("verifyWithPem", () => {
  it("accepts a genuine signature", () => {
    const key = keypair();
    const { url, signature } = signedCallbackUrl(REWARD_PARAMS, key, "1");
    assert.strictEqual(
      verifyWithPem(signedContentFrom(url), signature, key.pem),
      true
    );
  });

  it("rejects a tampered parameter", () => {
    const key = keypair();
    const { signature } = signedCallbackUrl(REWARD_PARAMS, key, "1");
    const tampered = signedCallbackUrl(
      { ...REWARD_PARAMS, reward_amount: "9999" },
      key,
      "1"
    );
    // Original signature, inflated reward.
    assert.strictEqual(
      verifyWithPem(signedContentFrom(tampered.url), signature, key.pem),
      false
    );
  });

  it("rejects a swapped uid in custom_data", () => {
    const key = keypair();
    const { signature } = signedCallbackUrl(REWARD_PARAMS, key, "1");
    const attacker = signedCallbackUrl(
      {
        ...REWARD_PARAMS,
        custom_data: JSON.stringify({ uid: "someoneElse", type: "restore" }),
      },
      key,
      "1"
    );
    assert.strictEqual(
      verifyWithPem(signedContentFrom(attacker.url), signature, key.pem),
      false
    );
  });

  it("rejects a signature made by a different key", () => {
    const signer = keypair();
    const other = keypair();
    const { url, signature } = signedCallbackUrl(REWARD_PARAMS, signer, "1");
    assert.strictEqual(
      verifyWithPem(signedContentFrom(url), signature, other.pem),
      false
    );
  });

  it("returns false rather than throwing on junk input", () => {
    const key = keypair();
    const content = signedContentFrom(
      signedCallbackUrl(REWARD_PARAMS, key, "1").url
    );
    assert.strictEqual(verifyWithPem(content, "", key.pem), false);
    assert.strictEqual(verifyWithPem(content, "!!!not base64!!!", key.pem), false);
    assert.strictEqual(verifyWithPem(content, "AAAA", "not a pem"), false);
    assert.strictEqual(verifyWithPem(content, null, key.pem), false);
  });

  it("accepts standard base64 as well as web-safe", () => {
    // Node's base64url decoder tolerates `+` and `/`, so a signature containing
    // them still verifies whichever alphabet Google used.
    const key = keypair();
    const { url } = signedCallbackUrl(REWARD_PARAMS, key, "1");
    const content = signedContentFrom(url);
    const std = crypto
      .sign("sha256", Buffer.from(content, "utf8"), key.privateKey)
      .toString("base64");
    assert.strictEqual(verifyWithPem(content, std, key.pem), true);
  });
});

describe("parseVerifierKeys", () => {
  it("indexes keys by string id and skips malformed entries", () => {
    const byId = parseVerifierKeys({
      keys: [
        { keyId: 1234, pem: "PEM_A", base64: "…" },
        { keyId: "5678", pem: "PEM_B" },
        { keyId: 999 }, // no pem
        { pem: "PEM_C" }, // no id
        null,
      ],
    });
    assert.strictEqual(byId.size, 2);
    assert.strictEqual(byId.get("1234"), "PEM_A");
    assert.strictEqual(byId.get("5678"), "PEM_B");
  });

  it("returns an empty map for junk", () => {
    assert.strictEqual(parseVerifierKeys(null).size, 0);
    assert.strictEqual(parseVerifierKeys({}).size, 0);
    assert.strictEqual(parseVerifierKeys({ keys: null }).size, 0);
  });
});

describe("VerifierKeyCache", () => {
  /** A fake `fetch` that serves [sets] in order and counts calls. */
  function fakeFetch(sets) {
    const calls = [];
    const impl = async (url) => {
      calls.push(url);
      const set = sets[Math.min(calls.length - 1, sets.length - 1)];
      if (set instanceof Error) throw set;
      if (set && set.httpError) return { ok: false, status: set.httpError };
      return { ok: true, json: async () => ({ keys: set }) };
    };
    impl.calls = calls;
    return impl;
  }

  it("fetches once and serves the rest from cache", async () => {
    const key = keypair();
    const fetchImpl = fakeFetch([[{ keyId: "7", pem: key.pem }]]);
    const cache = new VerifierKeyCache({ fetchImpl, now: () => 1000 });
    const { url, signature } = signedCallbackUrl(REWARD_PARAMS, key, "7");
    const content = signedContentFrom(url);

    assert.strictEqual(await cache.verify(content, signature, "7"), true);
    assert.strictEqual(await cache.verify(content, signature, "7"), true);
    assert.strictEqual(fetchImpl.calls.length, 1);
  });

  it("refetches once when a key_id is unknown — that is what rotation looks like", async () => {
    const oldKey = keypair();
    const newKey = keypair();
    const fetchImpl = fakeFetch([
      [{ keyId: "old", pem: oldKey.pem }],
      [
        { keyId: "old", pem: oldKey.pem },
        { keyId: "new", pem: newKey.pem },
      ],
    ]);
    const cache = new VerifierKeyCache({ fetchImpl, now: () => 1000 });
    const { url, signature } = signedCallbackUrl(REWARD_PARAMS, newKey, "new");
    const content = signedContentFrom(url);

    assert.strictEqual(await cache.verify(content, signature, "new"), true);
    assert.strictEqual(fetchImpl.calls.length, 2, "should have refetched once");
  });

  it("returns false — not an error — when the id is absent even after a refetch", async () => {
    const key = keypair();
    const fetchImpl = fakeFetch([[{ keyId: "7", pem: key.pem }]]);
    const cache = new VerifierKeyCache({ fetchImpl, now: () => 1000 });
    const { url, signature } = signedCallbackUrl(REWARD_PARAMS, key, "ghost");

    assert.strictEqual(
      await cache.verify(signedContentFrom(url), signature, "ghost"),
      false
    );
  });

  it("throws on a fetch failure so the caller can answer 500 and be retried", async () => {
    const cache = new VerifierKeyCache({
      fetchImpl: fakeFetch([new Error("network down")]),
      now: () => 1000,
    });
    await assert.rejects(() => cache.verify("a=1", "AAAA", "7"));
  });

  it("throws on a non-OK response", async () => {
    const cache = new VerifierKeyCache({
      fetchImpl: fakeFetch([{ httpError: 503 }]),
      now: () => 1000,
    });
    await assert.rejects(() => cache.verify("a=1", "AAAA", "7"), /503/);
  });

  it("does not cache an empty key set", async () => {
    const key = keypair();
    const fetchImpl = fakeFetch([[], [{ keyId: "7", pem: key.pem }]]);
    const cache = new VerifierKeyCache({ fetchImpl, now: () => 1000 });
    const { url, signature } = signedCallbackUrl(REWARD_PARAMS, key, "7");
    const content = signedContentFrom(url);

    await assert.rejects(() => cache.verify(content, signature, "7"), /empty/);
    // The next callback must get a real fetch, not a poisoned empty cache.
    assert.strictEqual(await cache.verify(content, signature, "7"), true);
  });

  it("refetches after the cache window expires", async () => {
    const key = keypair();
    const fetchImpl = fakeFetch([[{ keyId: "7", pem: key.pem }]]);
    let now = 1000;
    const cache = new VerifierKeyCache({ fetchImpl, now: () => now });
    const { url, signature } = signedCallbackUrl(REWARD_PARAMS, key, "7");
    const content = signedContentFrom(url);

    await cache.verify(content, signature, "7");
    now += 25 * 60 * 60 * 1000; // a day and an hour later
    await cache.verify(content, signature, "7");
    assert.strictEqual(fetchImpl.calls.length, 2);
  });
});
