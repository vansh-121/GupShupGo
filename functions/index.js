// Force redeploy to apply minInstances
const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const crypto = require("crypto");

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
// Both participants get an immediate personalised push.
exports.streakBrokenTrigger = onDocumentUpdated(
  { document: "chatRooms/{roomId}", region: "us-central1" },
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
      participants.map((userId) => {
        const otherUserId = participants.find((id) => id !== userId);
        const otherName = nameMap[otherUserId] || "your friend";
        const streakLabel = `${previousStreakCount}-day`;

        return sendToUserDevices(userId, (token) => ({
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
      })
    );

    console.log(`streakBrokenTrigger: notified ${participants.length} users for room ${roomId}`);
    return null;
  }
);

// ─── Trigger 2: Streak Milestone ──────────────────────────────────────────────
// Fires when streakCount crosses 7, 30, 100, or 365 days.
exports.streakMilestoneTrigger = onDocumentUpdated(
  { document: "chatRooms/{roomId}", region: "us-central1" },
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
      participants.map((userId) => {
        const otherUserId = participants.find((id) => id !== userId);
        const otherName = nameMap[otherUserId] || "your friend";

        return sendToUserDevices(userId, (token) => ({
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
      })
    );

    console.log(`streakMilestoneTrigger: milestone ${milestone} for room ${roomId}`);
    return null;
  }
);

// ─── Trigger 3: Gup Points Reward ─────────────────────────────────────────────
// Fires when a user's gupPoints increases by ≥ 20 in one write.
// Cooldown: once per hour per user.
exports.gupPointsEarnedTrigger = onDocumentUpdated(
  { document: "users/{userId}", region: "us-central1" },
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
