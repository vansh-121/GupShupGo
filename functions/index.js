const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const crypto = require("crypto");

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();
const auth = admin.auth();

// ─── Send Call Notification ──────────────────────────────────────────────────
// IMPORTANT: This sends a DATA-ONLY message (no "notification" block).
// On Android, data-only messages ALWAYS reach the background handler even when
// the app is killed, allowing us to show the native CallKit full-screen call UI.
// If a "notification" block were present, Android would display a plain text
// notification and NEVER invoke the Dart background handler — which is why
// call notifications were unreliable before this fix.
exports.sendCallNotification = onRequest(
  { cors: true, invoker: "public" },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    // Verify Firebase Auth ID token
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      res.status(401).json({ error: "Unauthorized" });
      return;
    }
    try {
      const decodedToken = await admin.auth().verifyIdToken(authHeader.split("Bearer ")[1]);
      const { calleeId, callerId, channelId, isAudioOnly } = req.body;

      if (!calleeId || !callerId || !channelId) {
        res.status(400).json({ error: "Missing required fields" });
        return;
      }

      if (decodedToken.uid !== callerId) {
        res.status(403).json({ error: "Forbidden: caller identity mismatch" });
        return;
      }

      const userDoc = await db.collection("users").doc(calleeId).get();
      if (!userDoc.exists) {
        res.status(404).json({ error: `User ${calleeId} not found` });
        return;
      }

      const fcmToken = userDoc.data().fcmToken;
      if (!fcmToken) {
        res.status(404).json({ error: `No FCM token for user ${calleeId}` });
        return;
      }

      // Fetch caller details for display in the CallKit UI
      let callerName = callerId;
      let callerPhotoUrl = "";
      try {
        const callerDoc = await db.collection("users").doc(callerId).get();
        if (callerDoc.exists) {
          const callerData = callerDoc.data();
          if (callerData.name) callerName = callerData.name;
          if (callerData.photoUrl) callerPhotoUrl = callerData.photoUrl;
        }
      } catch (_) {}

      const audioOnly = isAudioOnly === true || isAudioOnly === "true";

      // Data-only message — no "notification" block.
      // This guarantees the Dart background handler fires on every platform
      // state (foreground, background, killed) so CallKit can display the
      // native full-screen call UI with Accept / Decline buttons.
      const message = {
        token: fcmToken,
        data: {
          callerId: callerId,
          callerName: callerName,
          callerPhotoUrl: callerPhotoUrl,
          channelId: channelId,
          type: "incoming_call",
          isAudioOnly: String(audioOnly),
        },
        // No "notification" key — intentional.
        android: {
          priority: "high",
          // Time-to-live: auto-dismiss if not delivered within 60 seconds
          // Firebase Admin SDK requires TTL in milliseconds (number)
          ttl: 60000,
        },
        apns: {
          headers: {
            "apns-priority": "10",
            "apns-push-type": "voip",
          },
          payload: {
            aps: {
              "content-available": 1,
            },
          },
        },
      };

      const result = await messaging.send(message);
      res.status(200).json({ success: true, messageId: result });
    } catch (error) {
      if (error.code && error.code.startsWith("auth/")) {
        res.status(401).json({ error: "Invalid or expired token" });
      } else {
        console.error("Error sending call notification:", error);
        res.status(500).json({ error: error.message });
      }
    }
  }
);

// ─── Send Message Notification ──────────────────────────────────────────────
exports.sendMessageNotification = onRequest(
  { cors: true, invoker: "public" },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    // Verify Firebase Auth ID token
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      res.status(401).json({ error: "Unauthorized" });
      return;
    }
    try {
      await admin.auth().verifyIdToken(authHeader.split("Bearer ")[1]);
    } catch (_) {
      res.status(401).json({ error: "Invalid or expired token" });
      return;
    }

    try {
      const { receiverId, senderId, senderName, message, chatRoomId } = req.body;

      if (!receiverId || !senderId || !senderName || !chatRoomId) {
        res.status(400).json({ error: "Missing required fields" });
        return;
      }

      const userDoc = await db.collection("users").doc(receiverId).get();
      if (!userDoc.exists) {
        res.status(404).json({ error: `User ${receiverId} not found` });
        return;
      }

      const fcmToken = userDoc.data().fcmToken;
      if (!fcmToken) {
        res.status(404).json({ error: `No FCM token for user ${receiverId}` });
        return;
      }

      const fcmMessage = {
        token: fcmToken,
        data: {
          type: "chat_message",
          senderId: senderId,
          senderName: senderName,
          message: message || "",
          chatRoomId: chatRoomId,
        },
        notification: {
          title: senderName,
          body: message || "Sent a message",
        },
        android: { priority: "high" },
        apns: {
          headers: { "apns-priority": "10" },
          payload: {
            aps: {
              alert: { title: senderName, body: message || "Sent a message" },
              sound: "default",
              "content-available": 1,
            },
          },
        },
      };

      const result = await messaging.send(fcmMessage);
      res.status(200).json({ success: true, messageId: result });
    } catch (error) {
      console.error("Error sending message notification:", error);
      res.status(500).json({ error: error.message });
    }
  }
);

// ─── Device Session Tokens ───────────────────────────────────────────────────
// Lets the app maintain its own long-lived "remember this device" session,
// independent of Firebase Auth's internal refresh-token store. We hand the
// app an opaque random token at sign-in; on cold starts where Firebase Auth
// has lost its session (e.g. MIUI cleared the store), the app trades that
// token back for a Firebase custom token and re-authenticates silently.
//
// Security model:
//   • Tokens are random 32-byte values (256 bits of entropy).
//   • We persist only a SHA-256 hash of the token in Firestore — leaks of
//     the deviceSessions docs alone are not enough to impersonate a user.
//   • Exchange increments lastUsedAt (audit trail) and is rate-limited by
//     the natural latency of a custom token mint (~100 ms).
//   • Revocation deletes the doc; the app deletes the local token too.
// ─────────────────────────────────────────────────────────────────────────────

const DEVICE_SESSION_COLLECTION = "deviceSessions";
const TOKEN_BYTES = 32;

function hashToken(rawToken) {
  return crypto.createHash("sha256").update(rawToken, "utf8").digest("hex");
}

// Issue a new device session token. Requires a valid Firebase ID token —
// the user has just signed in (phone OTP, Google, email/password, etc.)
// and we trust their current uid.
exports.issueDeviceSession = onRequest(
  { cors: true, invoker: "public" },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      res.status(401).json({ error: "Unauthorized" });
      return;
    }
    let decoded;
    try {
      decoded = await auth.verifyIdToken(authHeader.split("Bearer ")[1]);
    } catch (_) {
      res.status(401).json({ error: "Invalid or expired token" });
      return;
    }

    try {
      const uid = decoded.uid;
      const rawToken = crypto.randomBytes(TOKEN_BYTES).toString("hex");
      const tokenHash = hashToken(rawToken);
      const platform = (req.body && req.body.platform) || "unknown";
      const deviceLabel = (req.body && req.body.deviceLabel) || "unknown";

      const now = admin.firestore.FieldValue.serverTimestamp();
      await db.collection(DEVICE_SESSION_COLLECTION).doc(tokenHash).set({
        uid,
        platform,
        deviceLabel,
        createdAt: now,
        lastUsedAt: now,
      });

      // Return the raw token ONCE — the app must persist it locally; the
      // server only ever stores the hash and cannot recover it later.
      res.status(200).json({ token: rawToken });
    } catch (error) {
      console.error("issueDeviceSession error:", error);
      res.status(500).json({ error: error.message });
    }
  }
);

// Exchange a device session token for a Firebase custom token. No Bearer
// auth required — that's the whole point: this restores a session when
// the client has no live Firebase ID token.
exports.exchangeDeviceSession = onRequest(
  { cors: true, invoker: "public" },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }
    try {
      const rawToken = req.body && req.body.token;
      if (!rawToken || typeof rawToken !== "string") {
        res.status(400).json({ error: "Missing token" });
        return;
      }

      const tokenHash = hashToken(rawToken);
      const doc = await db
        .collection(DEVICE_SESSION_COLLECTION)
        .doc(tokenHash)
        .get();

      if (!doc.exists) {
        // Either never issued, or has been revoked. Treat identically.
        res.status(401).json({ error: "Invalid session" });
        return;
      }

      const { uid } = doc.data();
      if (!uid) {
        res.status(401).json({ error: "Invalid session" });
        return;
      }

      // Confirm the user account still exists and isn't disabled.
      try {
        const userRecord = await auth.getUser(uid);
        if (userRecord.disabled) {
          res.status(401).json({ error: "Account disabled" });
          return;
        }
      } catch (_) {
        // User deleted — clean up the stale session.
        await doc.ref.delete().catch(() => {});
        res.status(401).json({ error: "Account no longer exists" });
        return;
      }

      // Audit trail. Fire-and-forget — never block the exchange on this.
      doc.ref
        .update({ lastUsedAt: admin.firestore.FieldValue.serverTimestamp() })
        .catch(() => {});

      const customToken = await auth.createCustomToken(uid);
      res.status(200).json({ customToken, uid });
    } catch (error) {
      console.error("exchangeDeviceSession error:", error);
      res.status(500).json({ error: error.message });
    }
  }
);

// Revoke a device session token. Called on explicit sign-out. Bearer auth
// optional — we accept either a valid ID token (preferred) OR the raw
// token itself, so a user can always invalidate a token even if they no
// longer have a working Firebase session.
exports.revokeDeviceSession = onRequest(
  { cors: true, invoker: "public" },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }
    try {
      const rawToken = req.body && req.body.token;
      if (!rawToken || typeof rawToken !== "string") {
        res.status(400).json({ error: "Missing token" });
        return;
      }

      const tokenHash = hashToken(rawToken);
      const ref = db.collection(DEVICE_SESSION_COLLECTION).doc(tokenHash);
      const doc = await ref.get();
      if (!doc.exists) {
        // Already gone — succeed silently so retries are safe.
        res.status(200).json({ success: true });
        return;
      }

      // If a Bearer token is supplied, require it to match the session's uid.
      // (Optional but blocks a third party who scraped the raw token from
      // doing nothing useful — they'd need the user's current ID token to
      // pass this check. Without an ID token, holding the raw token is
      // already proof of access on this device, so revoking is allowed.)
      const authHeader = req.headers.authorization;
      if (authHeader && authHeader.startsWith("Bearer ")) {
        try {
          const decoded = await auth.verifyIdToken(
            authHeader.split("Bearer ")[1]
          );
          if (decoded.uid !== doc.data().uid) {
            res.status(403).json({ error: "Forbidden" });
            return;
          }
        } catch (_) {
          // Bad ID token — fall through; raw-token possession is still proof.
        }
      }

      await ref.delete();
      res.status(200).json({ success: true });
    } catch (error) {
      console.error("revokeDeviceSession error:", error);
      res.status(500).json({ error: error.message });
    }
  }
);
