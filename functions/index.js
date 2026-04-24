const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

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
      await admin.auth().verifyIdToken(authHeader.split("Bearer ")[1]);
    } catch (_) {
      res.status(401).json({ error: "Invalid or expired token" });
      return;
    }

    try {
      const { calleeId, callerId, channelId, isAudioOnly } = req.body;

      if (!calleeId || !callerId || !channelId) {
        res.status(400).json({ error: "Missing required fields" });
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
      console.error("Error sending call notification:", error);
      res.status(500).json({ error: error.message });
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
