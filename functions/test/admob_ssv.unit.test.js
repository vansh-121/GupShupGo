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
  signedContentCandidatesFrom,
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

// ─── Real captured callbacks ──────────────────────────────────────────────────
// The tests above sign their own URLs, which means they agree with whatever
// assumption the implementation makes about *which bytes* Google signs. They
// therefore passed while production refused every real reward.
//
// These vectors close that hole: real signatures, made by Google's live key, over
// real callbacks captured from the Cloud Run request log. Nothing here is a
// secret — the key is published and the uid is a Firebase Auth id.

/** Google's published verifier key, id 3335741209. */
const GOOGLE_PEM =
  "-----BEGIN PUBLIC KEY-----\n" +
  "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE+nzvoGqvDeB9+SzE6igTl7TyK4JB\n" +
  "bglwir9oTcQta8NuG26ZpZFxt+F2NDk7asTE6/2Yc8i1ATcGIqtuS5hv0Q==\n" +
  "-----END PUBLIC KEY-----";

/** A real `points` reward. `custom_data` is percent-encoded JSON. */
const REAL_WITH_CUSTOM_DATA =
  "/admobSsv?ad_network=5450213213286189855&ad_unit=3145500055" +
  "&custom_data=%7B%22uid%22%3A%22D268P40MbCgAqEI1q4GPhJt4cmJ3%22%2C%22type%22%3A%22points%22%7D" +
  "&reward_amount=1&reward_item=Reward&timestamp=1788460324887" +
  "&transaction_id=00065a985cc423f002ac87ddcf20aacf" +
  "&user_id=D268P40MbCgAqEI1q4GPhJt4cmJ3" +
  "&signature=MEQCIHvWnxD-voBY1xk3yLEyw33JFlUicoe-f-DsROKVfexHAiAioXRsmLiinDxI6fEi-j1zEFKhJbQ972Z3KqYVgqvYHw" +
  "&key_id=3335741209";

/** The AdMob console's "send test SSV" callback — no `custom_data`. */
const REAL_WITHOUT_CUSTOM_DATA =
  "/admobSsv?ad_network=5450213213286189855&ad_unit=1234567890" +
  "&reward_amount=1&reward_item=Reward&timestamp=1788456881623" +
  "&transaction_id=123456789" +
  "&signature=MEQCIFAn0V2DiSRrlS2rxFo4vX7xm_koj-U78CWXN26DrHfKAiAoMR02rHEFLAsWsMFcdA3tYrhtDDE9aSQh9WKYFiUIVw" +
  "&key_id=3335741209";

/** Pulls the `signature` value back out of a callback URL. */
function signatureOf(url) {
  return /[?&]signature=([^&]+)/.exec(url)[1];
}

describe("signedContentCandidatesFrom", () => {
  it("offers the decoded form first, then the raw one", () => {
    const candidates = signedContentCandidatesFrom(REAL_WITH_CUSTOM_DATA);
    assert.strictEqual(candidates.length, 2);
    assert.ok(candidates[0].includes('custom_data={"uid":"D268P40MbCgAqEI1q4GPhJt4cmJ3"'));
    assert.ok(candidates[1].includes("custom_data=%7B%22uid%22"));
  });

  it("collapses to one candidate when there is nothing to decode", () => {
    assert.deepStrictEqual(
      signedContentCandidatesFrom(REAL_WITHOUT_CUSTOM_DATA).length,
      1
    );
  });

  it("survives an undecodable escape instead of throwing", () => {
    const candidates = signedContentCandidatesFrom(
      "/admobSsv?custom_data=%zz&signature=AAAA&key_id=1"
    );
    assert.deepStrictEqual(candidates, ["custom_data=%zz"]);
  });

  it("still reports a non-callback URL as null", () => {
    assert.strictEqual(signedContentCandidatesFrom("/admobSsv"), null);
  });
});

describe("verification against real AdMob callbacks", () => {
  it("accepts a real reward whose custom_data is percent-encoded", async () => {
    const cache = new VerifierKeyCache({
      fetchImpl: async () => ({
        ok: true,
        json: async () => ({ keys: [{ keyId: 3335741209, pem: GOOGLE_PEM }] }),
      }),
    });
    assert.strictEqual(
      await cache.verify(
        signedContentCandidatesFrom(REAL_WITH_CUSTOM_DATA),
        signatureOf(REAL_WITH_CUSTOM_DATA),
        "3335741209"
      ),
      true
    );
  });

  it("still accepts a callback with no custom_data", async () => {
    const cache = new VerifierKeyCache({
      fetchImpl: async () => ({
        ok: true,
        json: async () => ({ keys: [{ keyId: 3335741209, pem: GOOGLE_PEM }] }),
      }),
    });
    assert.strictEqual(
      await cache.verify(
        signedContentCandidatesFrom(REAL_WITHOUT_CUSTOM_DATA),
        signatureOf(REAL_WITHOUT_CUSTOM_DATA),
        "3335741209"
      ),
      true
    );
  });

  it("signs the DECODED query string, not the encoded one", () => {
    // The regression, stated as a fact about Google rather than about our code:
    // the encoded span on the wire is NOT what the signature covers.
    const [decoded, raw] = signedContentCandidatesFrom(REAL_WITH_CUSTOM_DATA);
    const signature = signatureOf(REAL_WITH_CUSTOM_DATA);
    assert.strictEqual(verifyWithPem(decoded, signature, GOOGLE_PEM), true);
    assert.strictEqual(verifyWithPem(raw, signature, GOOGLE_PEM), false);
  });

  it("rejects a real callback with the uid swapped in custom_data", () => {
    const forged = REAL_WITH_CUSTOM_DATA.replace(
      "D268P40MbCgAqEI1q4GPhJt4cmJ3%22%2C%22type",
      "attackersUidHere00000000000x%22%2C%22type"
    );
    for (const content of signedContentCandidatesFrom(forged)) {
      assert.strictEqual(
        verifyWithPem(content, signatureOf(forged), GOOGLE_PEM),
        false
      );
    }
  });

  it("rejects a real callback with the reward inflated", () => {
    const forged = REAL_WITH_CUSTOM_DATA.replace(
      "reward_amount=1",
      "reward_amount=9999"
    );
    for (const content of signedContentCandidatesFrom(forged)) {
      assert.strictEqual(
        verifyWithPem(content, signatureOf(forged), GOOGLE_PEM),
        false
      );
    }
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
