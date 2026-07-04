// Force redeploy to apply minInstances
const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentUpdated, onDocumentCreated } = require("firebase-functions/v2/firestore");
const { beforeUserSignedIn } = require("firebase-functions/v2/identity");
const admin = require("firebase-admin");
const crypto = require("crypto");

// ─── Email System ──────────────────────────────────────────────────────────────
const emailService = require("./email-service");
const emailTemplates = require("./email-templates");

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();
const auth = admin.auth();

const INVALID_FCM_TOKEN_CODES = new Set([
  "messaging/invalid-registration-token",
  "messaging/registration-token-not-registered",
]);

function isInvalidFcmTokenError(error) {
  if (!error) return false;
  if (INVALID_FCM_TOKEN_CODES.has(error.code)) return true;
  return String(error.message || "").includes("Requested entity was not found");
}

// ─── Core Helpers ──────────────────────────────────────────────────────────

async function getNotificationTargets(userId) {
  const userRef = db.collection("users").doc(userId);
  const userDoc = await userRef.get();
  if (!userDoc.exists) {
    return { exists: false, targets: [] };
  }

  const targets = [];
  const seenTokens = new Set();
  const devicesSnap = await userRef.collection("devices").get();

  devicesSnap.forEach((doc) => {
    const token = doc.data().fcmToken;
    if (typeof token === "string" && token && !seenTokens.has(token)) {
      seenTokens.add(token);
      targets.push({ token, ref: doc.ref, source: "device" });
    }
  });

  return { exists: true, targets };
}

async function removeNotificationTarget(target) {
  try {
    await target.ref.delete();
  } catch (error) {
    console.error("Error removing invalid FCM token:", error);
  }
}

async function sendToUserDevices(userId, buildMessage) {
  const { exists, targets } = await getNotificationTargets(userId);
  if (!exists) {
    return { ok: false, status: 404, body: { error: `User ${userId} not found` } };
  }
  if (targets.length === 0) {
    return { ok: false, status: 404, body: { error: `No FCM tokens for user ${userId}` } };
  }

  const messages = targets.map((target) => buildMessage(target.token));
  const response = await messaging.sendEach(messages);
  const cleanup = [];
  let successCount = 0;
  const failures = [];

  response.responses.forEach((result, index) => {
    if (result.success) {
      successCount += 1;
      return;
    }

    const error = result.error;
    failures.push({
      tokenSource: targets[index].source,
      code: error && error.code,
      message: error && error.message,
    });

    if (isInvalidFcmTokenError(error)) {
      cleanup.push(removeNotificationTarget(targets[index]));
    }
  });

  await Promise.all(cleanup);

  if (successCount > 0) {
    return {
      ok: true,
      status: 200,
      body: {
        success: true,
        successCount,
        failureCount: response.failureCount,
        cleanedTokenCount: cleanup.length,
      },
    };
  }

  return {
    ok: false,
    status: cleanup.length > 0 ? 410 : 500,
    body: {
      error: cleanup.length > 0
        ? "All known FCM tokens were invalid and have been removed"
        : "Failed to send notification to any registered device",
      failureCount: response.failureCount,
      cleanedTokenCount: cleanup.length,
      failures,
    },
  };
}

// ─── Batch Multicast Helper ────────────────────────────────────────────────
// Chunks a flat list of tokens into groups of 500 and fires one
// sendEachForMulticast call per chunk. One call reaches up to 500 devices.

function chunkArray(arr, size) {
  const chunks = [];
  for (let i = 0; i < arr.length; i += size) {
    chunks.push(arr.slice(i, i + size));
  }
  return chunks;
}

async function sendMulticastBatch(tokens, message) {
  if (!tokens || tokens.length === 0) return;
  const chunks = chunkArray([...new Set(tokens)], 500); // deduplicate first
  const results = await Promise.all(
    chunks.map((chunk) =>
      messaging.sendEachForMulticast({ ...message, tokens: chunk }).catch((e) => {
        console.error("Multicast chunk failed:", e.message);
        return null;
      })
    )
  );
  const total = results.reduce((acc, r) => acc + (r ? r.successCount : 0), 0);
  console.log(`Multicast: ${total} successful deliveries across ${chunks.length} chunks`);
  return total;
}

// ─── Batch Token Fetcher ───────────────────────────────────────────────────
// Fetches FCM tokens for multiple users in parallel.

async function getTokensForUsers(userIds) {
  const tokenMap = {};
  await Promise.all(
    userIds.map(async (userId) => {
      try {
        const devicesSnap = await db
          .collection("users")
          .doc(userId)
          .collection("devices")
          .get();
        const tokens = [];
        devicesSnap.forEach((doc) => {
          const token = doc.data().fcmToken;
          if (token) tokens.push(token);
        });
        tokenMap[userId] = tokens;
      } catch (_) {
        tokenMap[userId] = [];
      }
    })
  );
  return tokenMap;
}

// ─── Batch Name Fetcher ────────────────────────────────────────────────────

async function getUserNames(userIds) {
  const nameMap = {};
  await Promise.all(
    userIds.map(async (userId) => {
      try {
        const doc = await db.collection("users").doc(userId).get();
        nameMap[userId] = doc.data()?.name || "Someone";
      } catch (_) {
        nameMap[userId] = "Someone";
      }
    })
  );
  return nameMap;
}

// ─── Send Call Notification ──────────────────────────────────────────────────
exports.sendCallNotification = onRequest(
  { cors: true, invoker: "public", minInstances: 0 },
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

      let callerName = callerId;
      let callerPhotoUrl = "";
      try {
        const callerDoc = await db.collection("users").doc(callerId).get();
        if (callerDoc.exists) {
          const callerData = callerDoc.data();
          if (callerData.name) callerName = callerData.name;
          if (callerData.photoUrl) callerPhotoUrl = callerData.photoUrl;
        }
      } catch (_) { }

      const audioOnly = isAudioOnly === true || isAudioOnly === "true";

      const result = await sendToUserDevices(calleeId, (fcmToken) => ({
        token: fcmToken,
        data: {
          calleeId: calleeId,
          callerId: callerId,
          callerName: callerName,
          callerPhotoUrl: callerPhotoUrl,
          channelId: channelId,
          type: "incoming_call",
          isAudioOnly: String(audioOnly),
        },
        android: {
          priority: "high",
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
      }));

      res.status(result.status).json(result.body);
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

// ─── Send Screen Share Notification ──────────────────────────────────────────
exports.sendScreenShareNotification = onRequest(
  { cors: true, invoker: "public", minInstances: 0 },
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
    try {
      const decodedToken = await admin.auth().verifyIdToken(authHeader.split("Bearer ")[1]);
      const { viewerId, sharerId, channelId } = req.body;

      if (!viewerId || !sharerId || !channelId) {
        res.status(400).json({ error: "Missing required fields" });
        return;
      }

      if (decodedToken.uid !== sharerId) {
        res.status(403).json({ error: "Forbidden: sharer identity mismatch" });
        return;
      }

      let sharerName = sharerId;
      let sharerPhotoUrl = "";
      try {
        const sharerDoc = await db.collection("users").doc(sharerId).get();
        if (sharerDoc.exists) {
          const sharerData = sharerDoc.data();
          if (sharerData.name) sharerName = sharerData.name;
          if (sharerData.photoUrl) sharerPhotoUrl = sharerData.photoUrl;
        }
      } catch (_) { }

      const result = await sendToUserDevices(viewerId, (fcmToken) => ({
        token: fcmToken,
        // A visible notification so that when the app is backgrounded or
        // terminated, Android shows it in the tray; tapping it opens the
        // viewer (handled by NotificationService via the `screen` field).
        // When the app is foregrounded, onMessage fires instead and the
        // viewer auto-opens — Android does not show the tray notification.
        notification: {
          title: `${sharerName} is sharing their screen`,
          body: "Tap to view the shared screen",
        },
        data: {
          viewerId: viewerId,
          sharerId: sharerId,
          sharerName: sharerName,
          sharerPhotoUrl: sharerPhotoUrl,
          channelId: channelId,
          type: "screen_share",
          // Used by NotificationService._navigateFromData for tap routing.
          screen: "screen_share",
        },
        android: {
          priority: "high",
          ttl: 60000,
          notification: {
            channelId: "chat_message_notifications",
          },
        },
        apns: {
          headers: {
            "apns-priority": "10",
            "apns-push-type": "alert",
          },
          payload: {
            aps: {
              "content-available": 1,
            },
          },
        },
      }));

      res.status(result.status).json(result.body);
    } catch (error) {
      if (error.code && error.code.startsWith("auth/")) {
        res.status(401).json({ error: "Invalid or expired token" });
      } else {
        console.error("Error sending screen share notification:", error);
        res.status(500).json({ error: error.message });
      }
    }
  }
);

// ─── Send Message Notification ──────────────────────────────────────────────
exports.sendMessageNotification = onRequest(
  { cors: true, invoker: "public", minInstances: 0 },
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

      const result = await sendToUserDevices(receiverId, (fcmToken) => ({
        token: fcmToken,
        data: {
          type: "chat_message",
          receiverId: receiverId,
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
      }));

      res.status(result.status).json(result.body);
    } catch (error) {
      console.error("Error sending message notification:", error);
      res.status(500).json({ error: error.message });
    }
  }
);

// ─── Device Session Tokens ───────────────────────────────────────────────────

const DEVICE_SESSION_COLLECTION = "deviceSessions";
const TOKEN_BYTES = 32;

function hashToken(rawToken) {
  return crypto.createHash("sha256").update(rawToken, "utf8").digest("hex");
}

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

      res.status(200).json({ token: rawToken });
    } catch (error) {
      console.error("issueDeviceSession error:", error);
      res.status(500).json({ error: error.message });
    }
  }
);

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
        res.status(401).json({ error: "Invalid session" });
        return;
      }

      const { uid } = doc.data();
      if (!uid) {
        res.status(401).json({ error: "Invalid session" });
        return;
      }

      try {
        const userRecord = await auth.getUser(uid);
        if (userRecord.disabled) {
          res.status(401).json({ error: "Account disabled" });
          return;
        }
      } catch (_) {
        await doc.ref.delete().catch(() => { });
        res.status(401).json({ error: "Account no longer exists" });
        return;
      }

      doc.ref
        .update({ lastUsedAt: admin.firestore.FieldValue.serverTimestamp() })
        .catch(() => { });

      const customToken = await auth.createCustomToken(uid);
      res.status(200).json({ customToken, uid });
    } catch (error) {
      console.error("exchangeDeviceSession error:", error);
      res.status(500).json({ error: error.message });
    }
  }
);

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
        res.status(200).json({ success: true });
        return;
      }

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
        } catch (_) { }
      }

      await ref.delete();
      res.status(200).json({ success: true });
    } catch (error) {
      console.error("revokeDeviceSession error:", error);
      res.status(500).json({ error: error.message });
    }
  }
);

// ─── E2EE: consume one-time prekey ───────────────────────────────────────────
exports.consumeOneTimePreKey = onRequest(
  { cors: true, invoker: "public", minInstances: 0 },
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
    try {
      await auth.verifyIdToken(authHeader.split("Bearer ")[1]);
      const { targetUid, deviceId } = req.body || {};
      if (!targetUid || typeof deviceId !== "number") {
        res.status(400).json({ error: "Missing targetUid or deviceId" });
        return;
      }

      const otpkCol = db
        .collection("users")
        .doc(targetUid)
        .collection("devices")
        .doc(String(deviceId))
        .collection("oneTimePreKeys");

      const result = await db.runTransaction(async (tx) => {
        const snap = await tx.get(otpkCol.limit(1));
        if (snap.empty) return null;
        const doc = snap.docs[0];
        tx.delete(doc.ref);
        return doc.data();
      });

      res.status(200).json({ preKey: result || null });
    } catch (error) {
      console.error("consumeOneTimePreKey error:", error);
      res.status(500).json({ error: error.message });
    }
  }
);

// ═══════════════════════════════════════════════════════════════════════════════
// NOTIFICATION SYSTEM — Automated, Batched, Multicast
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Trigger 1: Streak Broken ─────────────────────────────────────────────────
// Fires the instant streakBrokenAt is written (null → timestamp).
// Both participants get an immediate personalised push + email.
exports.streakBrokenTrigger = onDocumentUpdated(
  { document: "chatRooms/{roomId}", region: "us-central1", secrets: emailService.secrets },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    // Only react when streakBrokenAt goes from absent → present
    if (before.streakBrokenAt || !after.streakBrokenAt) return null;

    const participants = after.participants || [];
    const previousStreakCount = after.previousStreakCount || 0;
    const roomId = event.params.roomId;

    if (participants.length < 2 || previousStreakCount === 0) return null;

    const nameMap = await getUserNames(participants);

    await Promise.all(
      participants.map(async (userId) => {
        const otherUserId = participants.find((id) => id !== userId);
        const otherName = nameMap[otherUserId] || "your friend";
        const streakLabel = `${previousStreakCount}-day`;

        // Push notification
        await sendToUserDevices(userId, (token) => ({
          token,
          notification: {
            title: "💔 Streak Broken",
            body: `Your ${streakLabel} streak with ${otherName} just broke! Restore it within 24 hours.`,
          },
          data: {
            type: "streak_broken",
            screen: "chat",
            chatRoomId: roomId,
            contactId: otherUserId,
            previousStreakCount: String(previousStreakCount),
          },
          android: { priority: "high" },
          apns: { headers: { "apns-priority": "10" } },
        }));

        // Email notification
        await sendEmailToUser(userId, (name, email) => {
          const unsub = emailService.buildUnsubscribeUrl(userId);
          return emailTemplates.streakBrokenEmail(name, otherName, previousStreakCount, unsub);
        });
      })
    );

    console.log(`streakBrokenTrigger: notified ${participants.length} users for room ${roomId}`);
    return null;
  }
);

// ─── Trigger 2: Streak Milestone ──────────────────────────────────────────────
// Fires when streakCount crosses 7, 30, 100, or 365 days.
exports.streakMilestoneTrigger = onDocumentUpdated(
  { document: "chatRooms/{roomId}", region: "us-central1", secrets: emailService.secrets },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    const oldStreak = before.streakCount || 0;
    const newStreak = after.streakCount || 0;
    const MILESTONES = [7, 30, 100, 365];

    const milestone = MILESTONES.find((m) => oldStreak < m && newStreak >= m);
    if (!milestone) return null;

    const participants = after.participants || [];
    const roomId = event.params.roomId;
    const nameMap = await getUserNames(participants);

    const emoji = milestone >= 365 ? "👑" : milestone >= 100 ? "🏆" : milestone >= 30 ? "💎" : "🔥";
    const title = milestone >= 365 ? "Year-long Legend!" : milestone >= 100 ? "Century Streak!" : milestone >= 30 ? "Month Milestone!" : "Week Streak!";

    await Promise.all(
      participants.map(async (userId) => {
        const otherUserId = participants.find((id) => id !== userId);
        const otherName = nameMap[otherUserId] || "your friend";

        // Push notification
        await sendToUserDevices(userId, (token) => ({
          token,
          notification: {
            title: `${emoji} ${title}`,
            body: `${milestone} days straight with ${otherName}! You're on fire! 🔥`,
          },
          data: {
            type: "streak_milestone",
            screen: "arcade",
            milestoneCount: String(milestone),
            chatRoomId: roomId,
            contactId: otherUserId,
          },
          android: { priority: "high" },
          apns: { headers: { "apns-priority": "10" } },
        }));

        // Email notification
        await sendEmailToUser(userId, (name, email) => {
          const unsub = emailService.buildUnsubscribeUrl(userId);
          return emailTemplates.streakMilestoneEmail(name, otherName, milestone, unsub);
        });
      })
    );

    console.log(`streakMilestoneTrigger: milestone ${milestone} for room ${roomId}`);
    return null;
  }
);

// ─── Trigger 3: Gup Points Reward ─────────────────────────────────────────────
// Fires when a user's gupPoints increases by ≥ 20 in one write.
// Cooldown: once per hour per user.
// Email: only for gains ≥ 50 to avoid email spam.
exports.gupPointsEarnedTrigger = onDocumentUpdated(
  { document: "users/{userId}", region: "us-central1", secrets: emailService.secrets },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    const oldPoints = before.gupPoints || 0;
    const newPoints = after.gupPoints || 0;
    const gained = newPoints - oldPoints;

    if (gained < 20) return null;

    const userId = event.params.userId;

    // Hourly cooldown — don't spam for every small earn
    const lastNotified = after.notifiedAt?.gup_points;
    if (lastNotified) {
      const hoursSince = (Date.now() - lastNotified.toMillis()) / 3600000;
      if (hoursSince < 1) return null;
    }

    await sendToUserDevices(userId, (token) => ({
      token,
      notification: {
        title: "⚡ Gup Points Earned!",
        body: `+${gained} Gup Points! You now have ${newPoints} points. Keep it up!`,
      },
      data: {
        type: "gup_points_earned",
        screen: "arcade",
        pointsGained: String(gained),
        totalPoints: String(newPoints),
      },
      android: { priority: "normal" },
      apns: { headers: { "apns-priority": "5" } },
    }));

    // Email only for significant gains (≥ 50 points)
    if (gained >= 50) {
      await sendEmailToUser(userId, (name, email) => {
        const unsub = emailService.buildUnsubscribeUrl(userId);
        return emailTemplates.gupPointsEarnedEmail(name, gained, newPoints, unsub);
      });
    }

    // Write cooldown timestamp
    await db.collection("users").doc(userId).update({
      "notifiedAt.gup_points": admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`gupPointsEarnedTrigger: user ${userId} earned ${gained} points`);
    return null;
  }
);

// ─── Scheduled: Hourly At-Risk Streak Warnings ───────────────────────────────
// Runs every 60 minutes. For each active-streak chatRoom, checks if the last
// mutual interaction was 20–47 hours ago. Sends PERSONALISED per-room
// notifications (with the contact's name) instead of generic batched ones.
// Cooldown: 6h per room per risk level to avoid spam.
exports.hourlyStreakWarningBatch = onSchedule(
  { schedule: "every 60 minutes", region: "us-central1" },
  async () => {
    const now = new Date();
    const COOLDOWN_HOURS = 6;

    const chatRoomsSnap = await db
      .collection("chatRooms")
      .where("streakCount", ">", 0)
      .get();

    const roomNotifications = []; // { userId, otherName, streakCount, riskLevel, roomRef }
    const roomUpdates = [];

    for (const roomDoc of chatRoomsSnap.docs) {
      const room = roomDoc.data();
      const lastInteraction = room.lastInteractionDate;
      if (!lastInteraction) continue;

      const hoursSince = (now - lastInteraction.toDate()) / 3600000;
      let riskLevel = null;

      if (hoursSince >= 36 && hoursSince < 48) riskLevel = "critical";
      else if (hoursSince >= 20 && hoursSince < 36) riskLevel = "warning";
      if (!riskLevel) continue;

      // Check per-room cooldown
      const lastNotified = room.notifiedAt?.[`streak_${riskLevel}`];
      if (lastNotified) {
        const hoursSinceNotified = (now - lastNotified.toDate()) / 3600000;
        if (hoursSinceNotified < COOLDOWN_HOURS) continue;
      }

      const participants = room.participants || [];
      if (participants.length < 2) continue;

      // Queue per-user notifications for this room
      participants.forEach((uid) => {
        const otherUid = participants.find((id) => id !== uid);
        roomNotifications.push({
          userId: uid,
          otherUserId: otherUid,
          streakCount: room.streakCount || 0,
          riskLevel,
          roomId: roomDoc.id,
        });
      });

      roomUpdates.push(
        roomDoc.ref.update({
          [`notifiedAt.streak_${riskLevel}`]: admin.firestore.FieldValue.serverTimestamp(),
        })
      );
    }

    if (roomNotifications.length === 0) {
      console.log("hourlyStreakWarningBatch: no at-risk rooms found");
      return;
    }

    // Fetch names and tokens for all involved users
    const allUserIds = [...new Set(roomNotifications.flatMap((n) => [n.userId, n.otherUserId]))];
    const [tokenMap, nameMap] = await Promise.all([
      getTokensForUsers(allUserIds),
      getUserNames(allUserIds),
    ]);

    // Send personalised per-room notifications
    const sends = roomNotifications.map((n) => {
      const tokens = tokenMap[n.userId] || [];
      if (tokens.length === 0) return Promise.resolve();

      const otherName = nameMap[n.otherUserId] || "your friend";
      const isWarning = n.riskLevel === "warning";

      return sendMulticastBatch(tokens, {
        notification: {
          title: isWarning ? "⚠️ Streak at Risk!" : "🔥 Last Chance!",
          body: isWarning
            ? `Your 🔥${n.streakCount} streak with ${otherName} needs a message today!`
            : `Your 🔥${n.streakCount} streak with ${otherName} is about to break! Send a message NOW.`,
        },
        data: {
          type: "streak_warning",
          screen: "chat",
          chatRoomId: n.roomId,
          contactId: n.otherUserId,
          riskLevel: n.riskLevel,
        },
        android: { priority: "high" },
        apns: { headers: { "apns-priority": "10" } },
      });
    });

    await Promise.all([...sends, ...roomUpdates]);

    console.log(
      `hourlyStreakWarningBatch done: ${roomNotifications.length} personalised ` +
      `notifications across ${chatRoomsSnap.size} streak rooms.`
    );
  }
);

// ─── Scheduled: Streak Expiry (Auto-Break) ────────────────────────────────────
// Runs every 30 minutes. Finds chatRooms with active streaks where the last
// mutual interaction date is 2+ calendar days ago, and atomically breaks them.
// This ensures streaks break even if nobody sends a new message — the previous
// code only broke streaks inside the sendMessage() flow on the client.
// The write to streakBrokenAt triggers the existing `streakBrokenTrigger`
// Firestore onUpdate function, which sends push notifications to both users.
exports.streakExpiryJob = onSchedule(
  { schedule: "every 30 minutes", region: "us-central1" },
  async () => {
    const now = new Date();
    // 2 full calendar days ago (48 hours is a safe server-side threshold)
    const expiryThreshold = new Date(now - 48 * 3600000);

    const chatRoomsSnap = await db
      .collection("chatRooms")
      .where("streakCount", ">", 0)
      .where("lastInteractionDate", "<", admin.firestore.Timestamp.fromDate(expiryThreshold))
      .get();

    if (chatRoomsSnap.empty) {
      console.log("streakExpiryJob: no expired streaks found");
      return;
    }

    const batch = db.batch();
    let brokenCount = 0;

    for (const roomDoc of chatRoomsSnap.docs) {
      const room = roomDoc.data();
      const streakCount = room.streakCount || 0;
      if (streakCount <= 0) continue;

      batch.update(roomDoc.ref, {
        previousStreakCount: streakCount,
        streakCount: 0,
        streakBrokenAt: admin.firestore.FieldValue.serverTimestamp(),
        // Clear per-user last-sent timestamps so the next mutual day starts fresh
        lastSentAt: {},
      });
      brokenCount++;
    }

    if (brokenCount > 0) {
      await batch.commit();
    }

    console.log(`streakExpiryJob: broke ${brokenCount} expired streaks out of ${chatRoomsSnap.size} candidates.`);
  }
);

// ─── Scheduled: Daily Digest (8 AM IST = 2:30 AM UTC) ────────────────────────
// Collects all users' device tokens and sends one personalised morning digest.
// Cooldown: once per 20 hours per user (stored in user.notifiedAt.daily_digest).
exports.dailyDigestJob = onSchedule(
  { schedule: "30 2 * * *", timeZone: "UTC", region: "us-central1" },
  async () => {
    const now = new Date();
    const sevenDaysAgo = new Date(now - 7 * 24 * 3600000);

    // Fetch recently-active users
    const usersSnap = await db
      .collection("users")
      .where("lastSeen", ">", admin.firestore.Timestamp.fromDate(sevenDaysAgo))
      .get();

    const allTokens = [];
    const cooldownUpdates = [];

    await Promise.all(
      usersSnap.docs.map(async (userDoc) => {
        const userData = userDoc.data();

        // Skip if already got a digest in the last 20 hours
        const lastDigest = userData.notifiedAt?.daily_digest;
        if (lastDigest) {
          const hoursSince = (now - lastDigest.toDate()) / 3600000;
          if (hoursSince < 20) return;
        }

        const devicesSnap = await db
          .collection("users")
          .doc(userDoc.id)
          .collection("devices")
          .get();

        devicesSnap.forEach((doc) => {
          const token = doc.data().fcmToken;
          if (token) allTokens.push(token);
        });

        cooldownUpdates.push(
          userDoc.ref.update({
            "notifiedAt.daily_digest": admin.firestore.FieldValue.serverTimestamp(),
          })
        );
      })
    );

    if (allTokens.length > 0) {
      await sendMulticastBatch(allTokens, {
        notification: {
          title: "🌅 Good Morning!",
          body: "Check your streaks, earn Gup Points, and keep conversations going today.",
        },
        data: { type: "daily_digest", screen: "home" },
        android: { priority: "normal" },
        apns: { headers: { "apns-priority": "5" } },
      });
    }

    await Promise.all(cooldownUpdates);
    console.log(`dailyDigestJob: sent to ${allTokens.length} devices.`);
  }
);

// ─── Scheduled: Unread Message Reminder (every 2 hours) ──────────────────────
// If a user has unread messages older than 2 hours and hasn't opened the app,
// send a gentle reminder. Uses lastSeen on the user document.
exports.unreadReminderBatch = onSchedule(
  { schedule: "every 120 minutes", region: "us-central1" },
  async () => {
    const now = new Date();
    const twoHoursAgo = new Date(now - 2 * 3600000);
    const COOLDOWN_HOURS = 4;

    // Find chatRooms that have unread messages older than 2 hours
    const chatRoomsSnap = await db
      .collection("chatRooms")
      .where("lastMessageTime", "<", admin.firestore.Timestamp.fromDate(twoHoursAgo))
      .get();

    const userIdsToRemind = new Set();
    const roomUpdates = [];

    for (const roomDoc of chatRoomsSnap.docs) {
      const room = roomDoc.data();
      const unreadMap = room.unreadCount || {};

      // Check cooldown once per room
      const lastNotified = room.notifiedAt?.unread_reminder;
      if (lastNotified) {
        const hoursSince = (now - lastNotified.toDate()) / 3600000;
        if (hoursSince < COOLDOWN_HOURS) continue;
      }

      let roomHasUnread = false;
      for (const [uid, count] of Object.entries(unreadMap)) {
        if (count <= 0) continue;
        userIdsToRemind.add(uid);
        roomHasUnread = true;
      }

      if (roomHasUnread) {
        roomUpdates.push(
          roomDoc.ref.update({
            "notifiedAt.unread_reminder": admin.firestore.FieldValue.serverTimestamp(),
          })
        );
      }
    }

    if (userIdsToRemind.size === 0) {
      console.log("unreadReminderBatch: no users to remind");
      return;
    }

    const tokenMap = await getTokensForUsers([...userIdsToRemind]);
    const allTokens = [...userIdsToRemind].flatMap((uid) => tokenMap[uid] || []);

    if (allTokens.length > 0) {
      await sendMulticastBatch(allTokens, {
        notification: {
          title: "💬 You have unread messages",
          body: "Someone is waiting for your reply. Open GupShupGo now!",
        },
        data: { type: "unread_reminder", screen: "home" },
        android: { priority: "normal" },
        apns: { headers: { "apns-priority": "5" } },
      });
    }

    await Promise.all(roomUpdates);
    console.log(`unreadReminderBatch: reminded ${userIdsToRemind.size} users.`);
  }
);

// ═══════════════════════════════════════════════════════════════════════════════
// EMAIL NOTIFICATION SYSTEM
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Email Helper ──────────────────────────────────────────────────────────────
// Looks up a user's email and emailNotifications preference, then sends an
// email via the email-service module. Skips silently if the user has no email
// or has unsubscribed. templateFn receives (name, email) and must return
// { subject, html }.

async function sendEmailToUser(userId, templateFn) {
  try {
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) return false;

    const userData = userDoc.data();
    const email = userData.email;
    const name = userData.name || "there";

    // Skip if no email or user has unsubscribed
    if (!email) return false;
    if (userData.emailNotifications === false) return false;

    const { subject, html } = templateFn(name, email);
    return await emailService.sendEmail(email, subject, html);
  } catch (error) {
    console.error(`sendEmailToUser(${userId}) failed:`, error.message);
    return false;
  }
}

// ─── Trigger: Welcome Email (new user created) ────────────────────────────────
exports.welcomeEmailTrigger = onDocumentCreated(
  { document: "users/{userId}", region: "us-central1", secrets: emailService.secrets },
  async (event) => {
    const userData = event.data.data();
    const userId = event.params.userId;
    const email = userData.email;
    const name = userData.name || "there";

    if (!email) {
      console.log(`welcomeEmailTrigger: user ${userId} has no email, skipping`);
      return null;
    }

    const unsub = emailService.buildUnsubscribeUrl(userId);
    const { subject, html } = emailTemplates.welcomeEmail(name, unsub);
    await emailService.sendEmail(email, subject, html);

    console.log(`welcomeEmailTrigger: welcome email sent to ${email}`);
    return null;
  }
);

// ─── Trigger: Login Alert Email ───────────────────────────────────────────────
// Uses beforeUserSignedIn blocking function to capture sign-in events.
// Sends a security-style "new sign-in detected" email.
exports.loginAlertEmail = beforeUserSignedIn(
  { region: "us-central1", secrets: emailService.secrets },
  async (event) => {
    try {
      const user = event.data;
      if (!user || !user.uid) return;

      const userDoc = await db.collection("users").doc(user.uid).get();
      if (!userDoc.exists) return; // New user — welcome email handles it

      const userData = userDoc.data();
      const email = userData.email || user.email;
      const name = userData.name || user.displayName || "there";

      if (!email) return;
      if (userData.emailNotifications === false) return;

      // Cooldown: max one login alert per 6 hours
      const lastLoginEmail = userData.notifiedAt?.login_alert;
      if (lastLoginEmail) {
        const hoursSince = (Date.now() - lastLoginEmail.toMillis()) / 3600000;
        if (hoursSince < 6) return;
      }

      const now = new Date();
      const loginTime = now.toLocaleString("en-IN", {
        timeZone: "Asia/Kolkata",
        dateStyle: "medium",
        timeStyle: "short",
      });

      const device = event.ipAddress
        ? `${event.userAgent || "Unknown device"} (${event.ipAddress})`
        : event.userAgent || "Unknown device";

      const unsub = emailService.buildUnsubscribeUrl(user.uid);
      const { subject, html } = emailTemplates.loginAlertEmail(name, device, loginTime, unsub);
      await emailService.sendEmail(email, subject, html);

      // Record cooldown
      await db.collection("users").doc(user.uid).update({
        "notifiedAt.login_alert": admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error) {
      // Never block sign-in due to email failure
      console.error("loginAlertEmail error (non-blocking):", error.message);
    }
  }
);

// ─── Scheduled: Weekly Digest Email (Monday 9 AM IST = 3:30 AM UTC) ──────────
exports.weeklyDigestEmailJob = onSchedule(
  { schedule: "30 3 * * 1", timeZone: "UTC", region: "us-central1", secrets: emailService.secrets },
  async () => {
    const now = new Date();
    const sevenDaysAgo = new Date(now - 7 * 24 * 3600000);

    // Fetch recently-active users who have email and haven't unsubscribed
    const usersSnap = await db
      .collection("users")
      .where("lastSeen", ">", admin.firestore.Timestamp.fromDate(sevenDaysAgo))
      .get();

    let sentCount = 0;

    await Promise.all(
      usersSnap.docs.map(async (userDoc) => {
        const userData = userDoc.data();
        const email = userData.email;
        const name = userData.name || "there";

        if (!email) return;
        if (userData.emailNotifications === false) return;

        // Cooldown: once per 6 days
        const lastDigestEmail = userData.notifiedAt?.weekly_digest_email;
        if (lastDigestEmail) {
          const daysSince = (now - lastDigestEmail.toDate()) / 86400000;
          if (daysSince < 6) return;
        }

        // Gather stats for this user
        const userId = userDoc.id;
        let messagesSent = 0;
        let activeBonds = 0;
        let longestStreak = 0;

        try {
          const chatRoomsSnap = await db
            .collection("chatRooms")
            .where("participants", "array-contains", userId)
            .get();

          for (const roomDoc of chatRoomsSnap.docs) {
            const room = roomDoc.data();
            const streak = room.streakCount || 0;
            if (streak > 0) activeBonds++;
            if (streak > longestStreak) longestStreak = streak;
          }
        } catch (_) { }

        const gupPointsEarned = Math.max(0, (userData.gupPoints || 0) - (userData.lastWeekPoints || 0));

        const stats = {
          messagesSent: messagesSent, // We don't track per-user message count easily; left as 0
          activeBonds,
          longestStreak,
          gupPointsEarned,
        };

        const unsub = emailService.buildUnsubscribeUrl(userId);
        const { subject, html } = emailTemplates.weeklyDigestEmail(name, stats, unsub);
        const sent = await emailService.sendEmail(email, subject, html);

        if (sent) {
          sentCount++;
          await userDoc.ref.update({
            "notifiedAt.weekly_digest_email": admin.firestore.FieldValue.serverTimestamp(),
            "lastWeekPoints": userData.gupPoints || 0,
          }).catch(() => { });
        }
      })
    );

    console.log(`weeklyDigestEmailJob: sent ${sentCount} weekly digest emails.`);
  }
);

// ─── Scheduled: Inactivity Reminder Email (daily at 6 PM IST = 12:30 PM UTC) ─
exports.inactivityReminderEmailJob = onSchedule(
  { schedule: "30 12 * * *", timeZone: "UTC", region: "us-central1", secrets: emailService.secrets },
  async () => {
    const now = new Date();
    const threeDaysAgo = new Date(now - 3 * 24 * 3600000);
    const thirtyDaysAgo = new Date(now - 30 * 24 * 3600000);

    // Users who were active in the last 30 days but NOT in the last 3 days
    const usersSnap = await db
      .collection("users")
      .where("lastSeen", "<", admin.firestore.Timestamp.fromDate(threeDaysAgo))
      .where("lastSeen", ">", admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
      .get();

    let sentCount = 0;

    await Promise.all(
      usersSnap.docs.map(async (userDoc) => {
        const userData = userDoc.data();
        const email = userData.email;
        const name = userData.name || "there";

        if (!email) return;
        if (userData.emailNotifications === false) return;

        // Cooldown: once per 7 days
        const lastInactivityEmail = userData.notifiedAt?.inactivity_email;
        if (lastInactivityEmail) {
          const daysSince = (now - lastInactivityEmail.toDate()) / 86400000;
          if (daysSince < 7) return;
        }

        const lastSeen = userData.lastSeen?.toDate ? userData.lastSeen.toDate() : null;
        const daysSince = lastSeen
          ? Math.floor((now - lastSeen) / 86400000)
          : 3;

        const unsub = emailService.buildUnsubscribeUrl(userDoc.id);
        const { subject, html } = emailTemplates.inactivityReminderEmail(name, daysSince, unsub);
        const sent = await emailService.sendEmail(email, subject, html);

        if (sent) {
          sentCount++;
          await userDoc.ref.update({
            "notifiedAt.inactivity_email": admin.firestore.FieldValue.serverTimestamp(),
          }).catch(() => { });
        }
      })
    );

    console.log(`inactivityReminderEmailJob: sent ${sentCount} inactivity emails.`);
  }
);

// ─── HTTP: Unsubscribe from Emails ────────────────────────────────────────────
// One-click unsubscribe endpoint. Sets emailNotifications = false on the user doc.
// No auth required (link is in emails, must work without sign-in).
exports.unsubscribeEmail = onRequest(
  { cors: true, invoker: "public", region: "us-central1" },
  async (req, res) => {
    const uid = req.query.uid || (req.body && req.body.uid);

    if (!uid || typeof uid !== "string") {
      res.status(400).send(unsubscribePage("Invalid request", false));
      return;
    }

    try {
      const userRef = db.collection("users").doc(uid);
      const userDoc = await userRef.get();

      if (!userDoc.exists) {
        res.status(404).send(unsubscribePage("Account not found", false));
        return;
      }

      await userRef.update({ emailNotifications: false });

      res.status(200).send(unsubscribePage(userDoc.data().name || "there", true));
    } catch (error) {
      console.error("unsubscribeEmail error:", error);
      res.status(500).send(unsubscribePage("Something went wrong", false));
    }
  }
);

// Simple HTML page shown after clicking unsubscribe
function unsubscribePage(nameOrError, success) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${success ? "Unsubscribed" : "Error"} — GupShupGo</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: #F5F3FF;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 24px;
    }
    .card {
      background: #fff;
      border-radius: 16px;
      padding: 48px 40px;
      max-width: 440px;
      width: 100%;
      text-align: center;
      box-shadow: 0 4px 24px rgba(108,92,231,0.08);
    }
    .icon { font-size: 48px; margin-bottom: 16px; }
    h1 { font-size: 22px; color: #1E293B; margin-bottom: 8px; }
    p { font-size: 15px; color: #64748B; line-height: 1.6; }
    .brand { color: #6C5CE7; font-weight: 700; }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">${success ? "✅" : "⚠️"}</div>
    <h1>${success ? `You've been unsubscribed` : nameOrError}</h1>
    <p>${success
      ? `${nameOrError}, you will no longer receive emails from <span class="brand">GupShupGo</span>. You can re-enable email notifications anytime in the app under Settings.`
      : "We couldn't process your request. Please try again or manage your preferences in the app."
    }</p>
  </div>
</body>
</html>`;
}
