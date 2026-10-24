GupShupGo — GupAI knowledge base (STARTER)
==========================================

HOW TO USE THIS FILE
--------------------
This is NOT loaded from the repo. It is the text to paste into the Firestore
document `config/ai`, field `knowledgeBase` (a string). It is prepended to GupAI's
system prompt ONLY for open-ended chat (not for translate/summarise/rewrite), so
app questions are answered from these facts instead of being guessed. It is
editable live — a change in `config/ai` takes effect within ~60 seconds, no deploy.

Keep it concise (it is sent on every chat turn). Review every line, fill the
<PLACEHOLDERS>, and delete anything not yet true in your build.

Everything from the line of equals signs below is the value to paste.

================================================================================
GupShupGo is a private messaging app: 1-to-1 chats, voice & video calls, status
updates, and a built-in AI assistant called GupAI.

Privacy & encryption
- Personal chats, calls, and status updates are end-to-end encrypted (Signal
  protocol). No one — not even GupShupGo or GupAI — can read them.
- GupAI cannot see your private chats. It only sees what you send it directly:
  a message you type to GupAI, or text you explicitly choose to Translate,
  Summarise, Rewrite, or "Ask GupAI about".

GupAI (the assistant)
- GupAI helps you write and reply to messages, translate, summarise, brainstorm,
  and answer general questions. It was created by GupShupGo.
- Open it from the "GupAI" entry at the top of the Chats list.
- Inside any chat: long-press a message for Translate / Summarise / Ask GupAI,
  and tap the ✨ button by the message box to rewrite your draft or get reply
  ideas.
- Free users get a set number of GupAI messages per day; it resets daily. You can
  watch a short ad to unlock more, or upgrade to Pro for a higher daily limit.

Chats
- Send text, photos, videos, documents, voice notes, and your location.
- Reply, react with emoji, forward, copy, edit (within a short window), and
  delete for everyone or just for yourself.

Status
- Share photo, video, or text status updates that disappear after 24 hours.
- Status updates are end-to-end encrypted and visible only to your contacts.

Bonds (streaks)
- Chatting with someone on consecutive days builds a "bond" streak. Missing a day
  can break it. <Describe any streak-restore option you offer, e.g. watch an ad.>

Gup Points
- Earn Gup Points in the app <describe how, e.g. by watching rewarded ads>.
  <Describe what points are used for.>

Anonymous chat
- "Connect with a Stranger" pairs you with a random person for an anonymous chat.
  Your identity stays hidden.

Vault & PIN
- You can set a vault PIN so your decrypted messages and status updates are backed
  up securely and restored when you reinstall or switch devices.

Pro (subscription)
- Pro unlocks: media (photo/video) status, screen sharing on calls, chat export,
  custom chat wallpapers, higher media quality, longer status videos, and longer
  voice notes, plus a higher daily GupAI limit.
- Price: <FILL IN price / plans>.

Getting help
- For problems not covered here, open Settings → Help (or the in-app problem
  report) to contact support.
================================================================================
