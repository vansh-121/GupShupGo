#!/usr/bin/env node
// @ts-check
/**
 * translate_arb.mjs — fill GupShupGo's localization ARB files from English.
 *
 * DEV-ONLY build tool. NOT shipped in the app and NOT the production
 * `askGupShupAi` endpoint — it talks to Gemini directly with your own key so a
 * developer can bulk-translate the UI strings, which are then human-reviewed.
 *
 * Source of truth:  lib/l10n/app_en.arb   (the English template)
 * Targets:          lib/l10n/app_<code>.arb  (one per TARGET_LOCALES entry)
 * Review tracking:  lib/l10n/.translation_status.json  (per-locale, per-key:
 *                   { srcHash, reviewed }). Machine output starts reviewed:false;
 *                   flip to true by hand (or a reviewer UI) once checked.
 *
 * Behaviour:
 *   - Only (re)translates keys that are MISSING in the target, or whose English
 *     source changed since the last run (srcHash mismatch). Existing good/reviewed
 *     translations are left untouched. Pass --force to redo everything.
 *   - Preserves ICU placeholders/plurals exactly ({name}, {count, plural, ...}).
 *     If a translation drops a placeholder, it's rejected and the English kept,
 *     and the key is reported so a human can fix it.
 *   - Never translates @-metadata or @@locale; target ARBs carry only @@locale
 *     plus the message keys (metadata lives in the template).
 *
 * Usage:
 *   GEMINI_API_KEY=... node tool/translate_arb.mjs            # all target locales
 *   GEMINI_API_KEY=... node tool/translate_arb.mjs --locale hi,ar
 *   GEMINI_API_KEY=... node tool/translate_arb.mjs --force
 *   GEMINI_MODEL=gemini-3.5-flash  (override the model; default below)
 *
 * Requires Node 18+ (global fetch).
 */

import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { createHash } from "node:crypto";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const L10N_DIR = join(__dirname, "..", "lib", "l10n");
const TEMPLATE = join(L10N_DIR, "app_en.arb");
const STATUS_FILE = join(L10N_DIR, ".translation_status.json");

// Keep in sync with lib/l10n/app_locales.dart (minus 'en').
const TARGET_LOCALES = [
  "hi", "es", "ar", "fr", "pt", "bn", "ru",
  "id", "de", "ja", "zh", "ur", "tr", "ta", "te",
];

// Human-readable names for the prompt (the model translates best when told the
// language by name, not just a code).
const LOCALE_NAMES = {
  hi: "Hindi", es: "Spanish", ar: "Arabic", fr: "French", pt: "Portuguese",
  bn: "Bengali", ru: "Russian", id: "Indonesian", de: "German", ja: "Japanese",
  zh: "Simplified Chinese", ur: "Urdu", tr: "Turkish", ta: "Tamil", te: "Telugu",
};

const MODEL = process.env.GEMINI_MODEL || "gemini-3.5-flash";
const API_KEY = process.env.GEMINI_API_KEY;
const BATCH_SIZE = 40;

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function parseArgs() {
  const args = process.argv.slice(2);
  const force = args.includes("--force");
  const li = args.indexOf("--locale");
  const locales =
    li >= 0 && args[li + 1]
      ? args[li + 1].split(",").map((s) => s.trim()).filter(Boolean)
      : TARGET_LOCALES;
  return { force, locales };
}

/** The translatable keys of an ARB (skips @-metadata and @@-globals). */
function messageKeys(arb) {
  return Object.keys(arb).filter((k) => !k.startsWith("@"));
}

/** Every ICU placeholder token in a string, e.g. "{count}" / "{count, plural,". */
function placeholders(value) {
  return (value.match(/\{[^}]*\}/g) || []).sort();
}

/** True if `translated` keeps every placeholder present in `source`. */
function placeholdersIntact(source, translated) {
  const a = placeholders(source);
  const b = placeholders(translated);
  return a.length === b.length && a.every((p, i) => p === b[i]);
}

function srcHash(value) {
  return createHash("sha1").update(value).digest("hex").slice(0, 12);
}

function loadJson(path, fallback) {
  return existsSync(path) ? JSON.parse(readFileSync(path, "utf8")) : fallback;
}

async function translateBatch(entries, localeCode, attempt = 0) {
  const langName = LOCALE_NAMES[localeCode] || localeCode;
  const payload = Object.fromEntries(entries.map(([k, v]) => [k, v]));
  const prompt =
    `You are a professional app-UI localizer. Translate the VALUES of this JSON ` +
    `from English into ${langName}. Rules:\n` +
    `- Return ONLY a JSON object with the SAME keys and translated values.\n` +
    `- Keep every ICU placeholder EXACTLY as-is, including braces and names: ` +
    `{name}, {count}, and plural/select blocks like {count, plural, one{...} other{...}}. ` +
    `Never translate text inside the braces' control words (plural, select, one, other, =0).\n` +
    `- These are short mobile UI strings (buttons, titles, hints). Keep them concise ` +
    `and natural for ${langName}. Preserve leading/trailing spaces and emoji.\n` +
    `- Do not add notes, markdown, or extra keys.\n\n` +
    `JSON to translate:\n${JSON.stringify(payload, null, 2)}`;

  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/` +
    `${encodeURIComponent(MODEL)}:generateContent`;
  const res = await fetch(url, {
    method: "POST",
    headers: { "content-type": "application/json", "x-goog-api-key": API_KEY },
    body: JSON.stringify({
      contents: [{ role: "user", parts: [{ text: prompt }] }],
      generationConfig: { temperature: 0.2, responseMimeType: "application/json" },
    }),
  });
  // Auto-retry per-minute rate limits with linear backoff (30s, 60s, 90s). A
  // sustained 429 (e.g. a daily cap) exhausts retries and throws, letting main()
  // stop cleanly — the run is resumable from the saved status.
  if (res.status === 429) {
    if (attempt < 3) {
      const waitMs = 30000 * (attempt + 1);
      console.warn(
        `[${localeCode}] 429 rate limit — waiting ${waitMs / 1000}s, retry ${attempt + 1}/3…`
      );
      await sleep(waitMs);
      return translateBatch(entries, localeCode, attempt + 1);
    }
    throw new Error(`Gemini 429: quota/rate limit still hit after ${attempt} retries`);
  }
  if (!res.ok) {
    throw new Error(`Gemini ${res.status}: ${(await res.text()).slice(0, 300)}`);
  }
  const data = await res.json();
  const text =
    data?.candidates?.[0]?.content?.parts?.map((p) => p.text || "").join("") || "";
  let obj;
  try {
    obj = JSON.parse(text);
  } catch {
    throw new Error(`Model did not return JSON for ${localeCode}: ${text.slice(0, 200)}`);
  }
  return obj;
}

async function main() {
  if (!API_KEY) {
    console.error("Set GEMINI_API_KEY in the environment.");
    process.exit(1);
  }
  const { force, locales } = parseArgs();
  const template = loadJson(TEMPLATE, null);
  if (!template) {
    console.error(`Missing template: ${TEMPLATE}`);
    process.exit(1);
  }
  const keys = messageKeys(template);
  const status = loadJson(STATUS_FILE, {});
  let hitQuota = false;

  for (const code of locales) {
    const targetPath = join(L10N_DIR, `app_${code}.arb`);
    const existing = loadJson(targetPath, { "@@locale": code });
    status[code] = status[code] || {};

    // Which keys need (re)translation.
    const todo = keys.filter((k) => {
      if (force) return true;
      const hasValue = typeof existing[k] === "string";
      const changed = status[code][k]?.srcHash !== srcHash(template[k]);
      return !hasValue || changed;
    });

    if (todo.length === 0) {
      console.log(`[${code}] up to date (${keys.length} keys).`);
      continue;
    }
    console.log(`[${code}] translating ${todo.length}/${keys.length} key(s)…`);

    const result = { "@@locale": code };
    // Preserve template key order; carry over untouched existing values.
    for (const k of keys) result[k] = existing[k];

    const dropped = [];
    try {
      for (let i = 0; i < todo.length; i += BATCH_SIZE) {
        const batch = todo.slice(i, i + BATCH_SIZE).map((k) => [k, template[k]]);
        const translated = await translateBatch(batch, code);
        for (const [k, srcVal] of batch) {
          const tv = translated[k];
          if (typeof tv === "string" && placeholdersIntact(srcVal, tv)) {
            result[k] = tv;
            status[code][k] = { srcHash: srcHash(srcVal), reviewed: false };
          } else {
            // Rejected: keep English, flag for a human.
            result[k] = srcVal;
            status[code][k] = { srcHash: srcHash(srcVal), reviewed: false, needsFix: true };
            dropped.push(k);
          }
        }
      }
    } catch (e) {
      // Persist progress so a re-run resumes instead of redoing everything.
      writeFileSync(STATUS_FILE, JSON.stringify(status, null, 2) + "\n", "utf8");
      const msg = (e && e.message) || String(e);
      console.error(`[${code}] failed: ${msg}`);
      if (msg.includes("429")) {
        hitQuota = true;
        const remaining = locales.slice(locales.indexOf(code));
        console.error(
          "\nGemini quota/rate limit hit (429) — stopping. When it resets, " +
            "re-run just the unfinished ones:\n  --locale " + remaining.join(",")
        );
        break;
      }
      // Non-quota error: skip this locale, keep going with the rest.
      continue;
    }

    writeFileSync(targetPath, JSON.stringify(result, null, 2) + "\n", "utf8");
    // Save status after each language so a mid-run failure stays resumable.
    writeFileSync(STATUS_FILE, JSON.stringify(status, null, 2) + "\n", "utf8");
    if (dropped.length) {
      console.warn(
        `[${code}] ${dropped.length} key(s) kept English (placeholder/format issue): ` +
          dropped.join(", ")
      );
    }
    console.log(`[${code}] wrote ${targetPath}`);
  }

  writeFileSync(STATUS_FILE, JSON.stringify(status, null, 2) + "\n", "utf8");
  if (!hitQuota) {
    console.log(
      "Done. All machine translations are reviewed:false in .translation_status.json — " +
        "review, then flip to true."
    );
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
