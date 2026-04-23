const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// ─── Send Call Notification ──────────────────────────────────────────────────
exports.sendCallNotification = onRequest(
  { cors: true, invoker: "public" },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
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

      let callerName = callerId;
      try {
        const callerDoc = await db.collection("users").doc(callerId).get();
        if (callerDoc.exists && callerDoc.data().name) {
          callerName = callerDoc.data().name;
        }
      } catch (_) {}

      const audioOnly = isAudioOnly === true || isAudioOnly === "true";

      const message = {
        token: fcmToken,
        data: {
          callerId: callerId,
          channelId: channelId,
          type: "incoming_call",
          isAudioOnly: String(audioOnly),
        },
        notification: {
          title: audioOnly ? "Incoming Audio Call" : "Incoming Video Call",
          body: `Call from ${callerName}`,
        },
        android: { priority: "high" },
        apns: {
          headers: { "apns-priority": "10" },
          payload: {
            aps: {
              alert: {
                title: audioOnly ? "Incoming Audio Call" : "Incoming Video Call",
                body: `Call from ${callerName}`,
              },
              sound: "default",
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
