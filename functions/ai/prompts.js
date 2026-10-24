"use strict";

/**
 * GupAI — system-prompt composition, kept pure (no Firestore, no network) so it
 * unit-tests like `./ai/quota`. `index.js` owns the I/O (reading `config/ai`,
 * auth, quota) and passes the resolved config + request mode in here.
 *
 * One endpoint (`askGupShupAi`) serves several task "modes". Each turn composes
 * an effective system prompt from three parts:
 *
 *   1. the base brand voice (`config/ai.systemPrompt`) — unchanged, always on;
 *   2. a KB grounding block — ONLY for open-ended `chat`, where a user might ask
 *      about the app. Translate/summarize/rewrite/smart-reply operate on supplied
 *      text and never need app facts, so the KB is omitted for them (cheaper, and
 *      it can't bleed into a translation);
 *   3. a task instruction for the non-chat modes.
 *
 * "Grounded, still broad": the grounding block tells the model to answer app
 * questions ONLY from the KB, but to keep answering everything else normally —
 * so GupAI is accurate about GupShupGo without becoming a narrow support bot.
 */

/** The task modes the endpoint accepts. Anything else is a 400 in the handler. */
const AI_MODES = ["chat", "translate", "summarize", "rewrite", "smart_reply"];

/** The mode assumed when the client sends none (the dedicated you↔AI chat). */
const DEFAULT_MODE = "chat";

/** Hard caps so a huge KB or a crafted param can't blow up the prompt. */
const MAX_KB_CHARS = 8000;
const MAX_PARAM_CHARS = 40;

/**
 * A short free-text parameter (a language name, a tone), clamped and restricted
 * to letters/spaces/hyphens so it can be dropped into the prompt as a literal.
 * Falls back when missing or malformed.
 *
 * @param {*} value
 * @param {string} fallback
 * @returns {string}
 */
function sanitizeParam(value, fallback) {
  if (typeof value !== "string") return fallback;
  const s = value.trim().slice(0, MAX_PARAM_CHARS);
  return /^[\p{L} .\-]{1,40}$/u.test(s) ? s : fallback;
}

/**
 * The knowledge-base grounding block, or "" when no KB is configured (in which
 * case chat behaves exactly as it did before the KB existed — broad, ungrounded).
 *
 * @param {object} cfg resolved `config/ai`
 * @returns {string}
 */
function groundingBlock(cfg) {
  const kb =
    cfg && typeof cfg.knowledgeBase === "string"
      ? cfg.knowledgeBase.trim().slice(0, MAX_KB_CHARS)
      : "";
  if (kb.length === 0) return "";
  return (
    "\n\n--- GupShupGo knowledge base (facts about the app) ---\n" +
    kb +
    "\n--- end knowledge base ---\n" +
    "When the user asks about GupShupGo — the app, its features, Pro, limits, " +
    "pricing, or how to do something — answer using ONLY the facts above. If the " +
    "answer is not there, say you are not sure and suggest they open Settings → " +
    "Help. For anything that is NOT about the app, answer normally and helpfully."
  );
}

/**
 * The task instruction appended for a non-chat mode (empty for chat).
 *
 * @param {string} mode one of {@link AI_MODES}
 * @param {?object} params e.g. `{ targetLang, tone }`
 * @returns {string}
 */
function modeInstruction(mode, params) {
  const p = params && typeof params === "object" ? params : {};
  switch (mode) {
    case "translate": {
      const lang = sanitizeParam(p.targetLang, "English");
      return (
        "\n\nTASK: Translate the user's message into " + lang + ". Output ONLY " +
        "the translation — no preamble, quotes, or notes. Preserve tone, emoji, " +
        "and line breaks. If it is already in " + lang + ", return it unchanged."
      );
    }
    case "summarize":
      return (
        "\n\nTASK: Summarize the user's message in 1–3 short sentences that " +
        "capture the key points. Output only the summary, in the message's own " +
        "language."
      );
    case "rewrite": {
      const tone = sanitizeParam(p.tone, "clearer and more polished");
      return (
        "\n\nTASK: Rewrite the user's message to be " + tone + ". Keep the " +
        "original meaning and the original language. Output ONLY the rewritten " +
        "message — no options, quotes, or commentary."
      );
    }
    case "smart_reply":
      return (
        "\n\nTASK: The user is showing a message they RECEIVED. Suggest 2–3 " +
        "short, natural, distinct replies they could send back, in the same " +
        "language as the message. Put each reply on its own line. No numbering, " +
        "bullets, quotes, or commentary."
      );
    case "chat":
    default:
      return "";
  }
}

/**
 * Builds the effective system prompt for one turn: base voice + (chat-only) KB
 * grounding + task instruction. Never throws; an unknown mode is treated as the
 * default (the handler rejects unknown modes before this, so that is just a
 * belt-and-braces).
 *
 * @param {object} cfg resolved `config/ai` (systemPrompt, knowledgeBase, …)
 * @param {string} mode
 * @param {?object} params
 * @returns {string}
 */
function composeSystemPrompt(cfg, mode, params) {
  const base = cfg && typeof cfg.systemPrompt === "string" ? cfg.systemPrompt : "";
  const m = AI_MODES.includes(mode) ? mode : DEFAULT_MODE;
  const grounding = m === "chat" ? groundingBlock(cfg) : "";
  return base + grounding + modeInstruction(m, params);
}

module.exports = {
  AI_MODES,
  DEFAULT_MODE,
  sanitizeParam,
  composeSystemPrompt,
};
