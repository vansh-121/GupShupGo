/**
 * AdMob rewarded server-side verification — the cryptography, on its own.
 *
 * Split out of `index.js` because this is the part of the ad integration most
 * able to be subtly, silently wrong. If the byte slicing is off by one character
 * or the signature encoding is misread, every signature check fails and the only
 * symptom is that nobody is ever paid — an outage that looks exactly like "no one
 * watched an ad". So it lives here, with no Firestore and no Express in sight,
 * and `test/admob_ssv.unit.test.js` proves it against a signature it generates
 * itself.
 *
 * Reference: AdMob → rewarded ads → server-side verification callbacks.
 */

const crypto = require("crypto");

/** Google's published reward verifier keys. */
const VERIFIER_KEYS_URL =
  "https://www.gstatic.com/admob/reward/verifier-keys.json";

/** How long a fetched key set is reused before refetching. */
const KEY_CACHE_MS = 24 * 60 * 60 * 1000;

/**
 * The exact bytes Google signed: the query string from the character after `?`
 * up to (not including) `&signature=`.
 *
 * This MUST come from the raw URL. Rebuilding it from a parsed query object
 * re-encodes values — `custom_data` is a JSON blob full of `{`, `"` and `:` — and
 * one byte of difference makes a valid signature look forged. Google documents
 * `signature` and `key_id` as the last two parameters, in that order, which is
 * what makes the cut well-defined.
 *
 * @param {string} originalUrl Raw request URL, e.g. `/?ad_network=…&signature=…`
 * @returns {?string} null when the URL isn't shaped like a callback.
 */
function signedContentFrom(originalUrl) {
  const url = String(originalUrl || "");
  const queryStart = url.indexOf("?");
  if (queryStart < 0) return null;
  const query = url.slice(queryStart + 1);
  const marker = query.indexOf("&signature=");
  if (marker <= 0) return null;
  return query.slice(0, marker);
}

/**
 * ECDSA-SHA256 verify [signedContent] against [signatureB64Url] using the PEM
 * [pem].
 *
 * Returns false — never throws — for a malformed signature or an unparseable
 * key, because both mean the same thing to the caller: don't pay.
 *
 * @param {string} signedContent
 * @param {string} signatureB64Url Web-safe base64, as Google sends it.
 * @param {string} pem
 * @returns {boolean}
 */
function verifyWithPem(signedContent, signatureB64Url, pem) {
  try {
    const signature = Buffer.from(String(signatureB64Url), "base64url");
    if (signature.length === 0) return false;
    // Google signs DER-encoded ECDSA, which is Node's default dsaEncoding.
    return crypto.verify(
      "sha256",
      Buffer.from(signedContent, "utf8"),
      crypto.createPublicKey(pem),
      signature
    );
  } catch (error) {
    return false;
  }
}

/**
 * Parses the verifier-keys document into a `keyId → pem` map.
 *
 * @param {*} body Decoded JSON from [VERIFIER_KEYS_URL].
 * @returns {Map<string, string>}
 */
function parseVerifierKeys(body) {
  const byId = new Map();
  for (const entry of (body && body.keys) || []) {
    if (entry && entry.keyId != null && typeof entry.pem === "string") {
      byId.set(String(entry.keyId), entry.pem);
    }
  }
  return byId;
}

/**
 * A cache over [VERIFIER_KEYS_URL]. One instance per function process — fetching
 * per callback would add a round-trip to every reward.
 */
class VerifierKeyCache {
  /**
   * @param {object} [options]
   * @param {function(string): Promise<*>} [options.fetchImpl] Injected for tests.
   * @param {function(): number} [options.now]
   */
  constructor(options) {
    const opts = options || {};
    this._fetch = opts.fetchImpl || ((url) => fetch(url));
    this._now = opts.now || (() => Date.now());
    this._fetchedAt = 0;
    this._byId = new Map();
  }

  /**
   * @param {boolean} force Bypass the cache. Used once per callback when a
   *   `key_id` isn't in the cached set — that is what a key rotation looks like
   *   from here, and refusing instead of refetching would drop real payouts for
   *   up to a day every time Google rolls a key.
   * @returns {Promise<Map<string, string>>}
   */
  async keys(force) {
    const now = this._now();
    const fresh = now - this._fetchedAt < KEY_CACHE_MS;
    if (!force && fresh && this._byId.size > 0) return this._byId;

    const response = await this._fetch(VERIFIER_KEYS_URL);
    if (!response || response.ok === false) {
      throw new Error(
        `verifier keys HTTP ${response && response.status}`
      );
    }
    const byId = parseVerifierKeys(await response.json());
    if (byId.size === 0) {
      // Don't poison the cache with an empty set — retry on the next callback.
      throw new Error("verifier key set was empty");
    }
    this._fetchedAt = now;
    this._byId = byId;
    return byId;
  }

  /**
   * Whether [signatureB64Url] is Google's over [signedContent].
   *
   * Throws only when the key set can't be reached. That is our outage, not a
   * forgery, and the caller must answer 500 so Google retries rather than the
   * user losing a reward they earned.
   *
   * @param {string} signedContent
   * @param {string} signatureB64Url
   * @param {string} keyId
   * @returns {Promise<boolean>}
   */
  async verify(signedContent, signatureB64Url, keyId) {
    let byId = await this.keys(false);
    let pem = byId.get(String(keyId));
    if (!pem) {
      byId = await this.keys(true); // suspected rotation
      pem = byId.get(String(keyId));
    }
    if (!pem) return false;
    return verifyWithPem(signedContent, signatureB64Url, pem);
  }
}

module.exports = {
  VERIFIER_KEYS_URL,
  KEY_CACHE_MS,
  VerifierKeyCache,
  parseVerifierKeys,
  signedContentFrom,
  verifyWithPem,
};
