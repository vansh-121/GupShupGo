// Force redeploy to apply minInstances
const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentUpdated, onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onValueWritten } = require("firebase-functions/v2/database");
const { beforeUserSignedIn } = require("firebase-functions/v2/identity");
const admin = require("firebase-admin");
const crypto = require("crypto");
const { google } = require("googleapis");
const { defineSecret } = require("firebase-functions/params");

// ─── Google Play Service Account (for subscription verification) ─────────────
// Set via: firebase functions:secrets:set PLAY_SERVICE_ACCOUNT_KEY
// Value: the full JSON content of the service account key file.
const playServiceAccountKey = defineSecret("PLAY_SERVICE_ACCOUNT_KEY");

// ─── Email System ──────────────────────────────────────────────────────────────
const emailService = require("./email-service");
const emailTemplates = require("./email-templates");
const { escHtml } = emailTemplates;

// ─── Streak Engine (server-authoritative) ─────────────────────────────────────
// Pure engine + transactional state adapter. Both resolve their Firestore handle
// lazily, so requiring them above `admin.initializeApp()` is safe.
const streakState = require("./streak/state");
const streakDay = require("./streak/day");
const streakEngine = require("./streak/engine");
const streakAwards = require("./streak/awards");
const streakNotify = require("./streak/notify");
const streakRepair = require("./streak/repair");

// ─── Rewarded-ad SSV ──────────────────────────────────────────────────────────
// Signature verification only — no Firestore, no Express — so it can be unit
// tested against a locally generated keypair. See `exports.admobSsv` below.
const adsSsv = require("./ads/ssv");

// ─── Repair admin token ────────────────────────────────────────────────────────
// Set via: firebase functions:secrets:set STREAK_ADMIN_TOKEN
// The only credential that can drive `streakRepairRoom`. Not a user id token: the
// endpoint is an operator tool, so no end user — Pro or otherwise — can reach it.
const streakAdminToken = defineSecret("STREAK_ADMIN_TOKEN");

// ─── Agora RTC token generation ──────────────────────────────────────────────
// The App Certificate is the secret that authorises token minting; it must
// NEVER ship in the client. Set both via:
//   firebase functions:secrets:set AGORA_APP_ID
//   firebase functions:secrets:set AGORA_APP_CERTIFICATE
const agoraAppId = defineSecret("AGORA_APP_ID");
const agoraAppCertificate = defineSecret("AGORA_APP_CERTIFICATE");

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

// ─── Streak notification wiring ────────────────────────────────────────────
// `functions/streak/notify.js` reuses the helpers above rather than
// re-implementing them; injection here avoids a circular require.
streakNotify.configure({
  sendToUserDevices,
  getUserNames,
  sendMulticastBatch,
});

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
      const { receiverId, senderId, senderName, message, chatRoomId, screen } = req.body;

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
          // Optional tap-routing hint (e.g. "requests" for friend-request
          // notifications). Omitted entirely for real chat messages, which
          // keeps existing client behavior (route via chatRoomId) unchanged.
          ...(screen ? { screen } : {}),
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
// IN-APP PURCHASE — Server-Side Subscription Verification (Robust)
// ═══════════════════════════════════════════════════════════════════════════════

const PACKAGE_NAME = "com.gupshupgo.app";
const SUBSCRIPTION_PRODUCT_IDS = new Set([
  "gupshupgo_pro_monthly",
  "gupshupgo_pro_yearly",
]);

// Duration map (fallback if Google API doesn't return expiry)
const PRODUCT_DURATION_DAYS = {
  gupshupgo_pro_monthly: 30,
  gupshupgo_pro_yearly: 365,
};

// Subscription states from Subscriptions v2 API that grant Pro access
const ACTIVE_SUBSCRIPTION_STATES = new Set([
  "SUBSCRIPTION_STATE_ACTIVE",
  "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
]);

// States where the user should lose access
const INACTIVE_SUBSCRIPTION_STATES = new Set([
  "SUBSCRIPTION_STATE_CANCELED",   // still active until expiry, handled by expiry check
  "SUBSCRIPTION_STATE_EXPIRED",
  "SUBSCRIPTION_STATE_REVOKED",
  "SUBSCRIPTION_STATE_ON_HOLD",    // payment failed, account hold (no access)
  "SUBSCRIPTION_STATE_PAUSED",
]);

/**
 * Returns an authorized Google Play AndroidPublisher client.
 * Uses the service account key stored in Firebase Secrets.
 */
function getPlayClient() {
  const keyJson = JSON.parse(playServiceAccountKey.value());
  const authClient = new google.auth.GoogleAuth({
    credentials: keyJson,
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
  return google.androidpublisher({ version: "v3", auth: authClient });
}

/**
 * Helper: Clear subscription fields from a user's Firestore document.
 */
async function clearSubscriptionFirestore(uid) {
  await db.collection("users").doc(uid).update({
    subscriptionPlan: "free",
    subscriptionExpiresAt: admin.firestore.FieldValue.delete(),
    subscriptionProductId: admin.firestore.FieldValue.delete(),
    subscriptionVerifiedAt: admin.firestore.FieldValue.delete(),
    subscriptionPurchaseToken: admin.firestore.FieldValue.delete(),
    subscriptionGracePeriod: admin.firestore.FieldValue.delete(),
  });
}

/**
 * Helper: Extract expiry and state from Subscriptions v2 response.
 * The v2 API returns a richer structure with lineItems[].
 * Returns { expiryMillis, subscriptionState, linkedPurchaseToken, acknowledged }
 */
function parseV2SubscriptionData(v2Data) {
  // v2 returns lineItems array — for single-product subscriptions, take the first
  const lineItem = v2Data.lineItems && v2Data.lineItems[0];
  const expiryTime = lineItem?.expiryTime || v2Data.lineItems?.[0]?.expiryTime;
  const expiryMillis = expiryTime ? new Date(expiryTime).getTime() : null;

  return {
    expiryMillis,
    subscriptionState: v2Data.subscriptionState || null,
    linkedPurchaseToken: v2Data.linkedPurchaseToken || null,
    acknowledged: v2Data.acknowledgementState === "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED",
    autoRenewing: lineItem?.autoRenewingPlan != null,
  };
}

/**
 * Helper: Extract expiry and state from Subscriptions v1 response (fallback).
 * Returns { expiryMillis, subscriptionState, linkedPurchaseToken, acknowledged }
 */
function parseV1SubscriptionData(v1Data) {
  const expiryMillis = v1Data.expiryTimeMillis
    ? parseInt(v1Data.expiryTimeMillis, 10)
    : null;
  const paymentState = parseInt(v1Data.paymentState, 10);

  // Map v1 paymentState + cancelReason to a pseudo v2 state
  let subscriptionState = "SUBSCRIPTION_STATE_ACTIVE";
  if (v1Data.cancelReason != null) {
    subscriptionState = "SUBSCRIPTION_STATE_CANCELED";
  }
  if (expiryMillis && expiryMillis < Date.now()) {
    subscriptionState = "SUBSCRIPTION_STATE_EXPIRED";
  }
  // paymentState 0 = pending (could be grace period or account hold)
  if (paymentState === 0) {
    subscriptionState = "SUBSCRIPTION_STATE_IN_GRACE_PERIOD";
  }

  return {
    expiryMillis,
    subscriptionState,
    linkedPurchaseToken: v1Data.linkedPurchaseToken || null,
    acknowledged: v1Data.acknowledgementState === 1,
    paymentState,
    autoRenewing: v1Data.autoRenewing === true,
  };
}

/**
 * Fetch subscription data from Google Play, trying v2 first with v1 fallback.
 * Returns a normalised object with { expiryMillis, subscriptionState, linkedPurchaseToken, acknowledged, source }
 */
async function getSubscriptionFromPlay(play, productId, purchaseToken) {
  // Try Subscriptions v2 API first
  try {
    const v2Result = await play.purchases.subscriptionsv2.get({
      packageName: PACKAGE_NAME,
      token: purchaseToken,
    });
    const parsed = parseV2SubscriptionData(v2Result.data);
    return { ...parsed, source: "v2", raw: v2Result.data };
  } catch (v2Error) {
    console.warn("Subscriptions v2 API failed, falling back to v1:", v2Error.message);
  }

  // Fallback to v1
  const v1Result = await play.purchases.subscriptions.get({
    packageName: PACKAGE_NAME,
    subscriptionId: productId,
    token: purchaseToken,
  });
  const parsed = parseV1SubscriptionData(v1Result.data);
  return { ...parsed, source: "v1", raw: v1Result.data };
}

// ─── Verify Purchase ─────────────────────────────────────────────────────────
// Called by the Flutter client after a successful in-app purchase. Validates
// the purchase token with Google Play, then writes verified subscription
// status to Firestore. The client NEVER writes subscription fields directly.
//
// Robustness features:
// - Idempotent: re-verifying the same token returns cached data
// - Grace period support: users in billing retry keep Pro access
// - Upgrade/downgrade: handles linkedPurchaseToken
// - Detailed error responses for client-side debugging
exports.verifyPurchase = onRequest(
  { cors: true, invoker: "public", minInstances: 0, secrets: [playServiceAccountKey] },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    // ── Auth ──────────────────────────────────────────────────────────────
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      res.status(401).json({ error: "Unauthorized", detail: "Missing Bearer token" });
      return;
    }

    let uid;
    try {
      const decoded = await auth.verifyIdToken(authHeader.split("Bearer ")[1]);
      uid = decoded.uid;
    } catch (_) {
      res.status(401).json({ error: "Invalid or expired token", detail: "Firebase ID token verification failed" });
      return;
    }

    // ── Validate input ───────────────────────────────────────────────────
    const { purchaseToken, productId } = req.body || {};

    if (!purchaseToken || typeof purchaseToken !== "string") {
      res.status(400).json({ error: "Missing or invalid purchaseToken", detail: "purchaseToken must be a non-empty string" });
      return;
    }
    if (!productId || !SUBSCRIPTION_PRODUCT_IDS.has(productId)) {
      res.status(400).json({ error: `Invalid productId: ${productId}`, detail: `Must be one of: ${[...SUBSCRIPTION_PRODUCT_IDS].join(", ")}` });
      return;
    }

    try {
      // ── Idempotency check ──────────────────────────────────────────────
      // If this exact token was already verified for this user, return cached data
      const userDoc = await db.collection("users").doc(uid).get();
      if (userDoc.exists) {
        const userData = userDoc.data();
        if (
          userData.subscriptionPurchaseToken === purchaseToken &&
          userData.subscriptionPlan === "pro" &&
          userData.subscriptionExpiresAt &&
          userData.subscriptionExpiresAt > Date.now()
        ) {
          console.log(`verifyPurchase: idempotent hit for ${uid} — already verified this token`);
          res.status(200).json({
            success: true,
            plan: "pro",
            productId: userData.subscriptionProductId,
            expiresAt: userData.subscriptionExpiresAt,
            cached: true,
          });
          return;
        }
      }

      // ── Call Google Play Developer API ──────────────────────────────────
      const play = getPlayClient();
      const purchase = await getSubscriptionFromPlay(play, productId, purchaseToken);

      console.log(`verifyPurchase: Play API response for ${uid} (${purchase.source}):`, JSON.stringify({
        state: purchase.subscriptionState,
        expiryMillis: purchase.expiryMillis,
        acknowledged: purchase.acknowledged,
        linkedPurchaseToken: purchase.linkedPurchaseToken ? "present" : "none",
      }));

      // ── Validate the purchase state ────────────────────────────────────
      const state = purchase.subscriptionState;

      // Expired subscriptions
      if (state === "SUBSCRIPTION_STATE_EXPIRED" || state === "SUBSCRIPTION_STATE_REVOKED") {
        res.status(410).json({
          error: "Subscription expired or revoked",
          detail: `State: ${state}`,
          expiresAt: purchase.expiryMillis,
        });
        return;
      }

      // Account on hold — payment failed, no access
      if (state === "SUBSCRIPTION_STATE_ON_HOLD" || state === "SUBSCRIPTION_STATE_PAUSED") {
        res.status(402).json({
          error: "Subscription on hold — payment issue",
          detail: `State: ${state}. Please update your payment method in Google Play.`,
        });
        return;
      }

      // For v1 fallback: check paymentState directly
      if (purchase.source === "v1" && purchase.paymentState !== undefined) {
        const ps = purchase.paymentState;
        // 0 = pending (grace period — allow), 1 = received, 2 = free trial, 3 = deferred
        if (ps === 3) {
          res.status(402).json({
            error: "Payment deferred",
            detail: "Payment method requires action. Please check Google Play.",
          });
          return;
        }
      }

      // Check expiry
      if (purchase.expiryMillis && purchase.expiryMillis < Date.now()) {
        res.status(410).json({
          error: "Subscription expired",
          detail: `Expired at ${new Date(purchase.expiryMillis).toISOString()}`,
          expiresAt: purchase.expiryMillis,
        });
        return;
      }

      // ── Acknowledge the purchase if needed ─────────────────────────────
      if (!purchase.acknowledged) {
        try {
          await play.purchases.subscriptions.acknowledge({
            packageName: PACKAGE_NAME,
            subscriptionId: productId,
            token: purchaseToken,
          });
          console.log(`Acknowledged purchase for user ${uid}, product ${productId}`);
        } catch (ackError) {
          // Non-fatal — the purchase is still valid
          console.error("Acknowledgement failed (non-fatal):", ackError.message);
        }
      }

      // ── Handle upgrade/downgrade (linkedPurchaseToken) ─────────────────
      if (purchase.linkedPurchaseToken) {
        try {
          // Find and clean up any user whose subscription is linked to the old token
          const oldTokenQuery = await db.collection("users")
            .where("subscriptionPurchaseToken", "==", purchase.linkedPurchaseToken)
            .limit(1)
            .get();

          if (!oldTokenQuery.empty) {
            const oldDoc = oldTokenQuery.docs[0];
            if (oldDoc.id === uid) {
              // Same user upgrading/downgrading — just overwrite below
              console.log(`verifyPurchase: upgrade/downgrade for ${uid}, replacing old token`);
            } else {
              // Different user had this token — unusual, log it
              console.warn(`verifyPurchase: linkedPurchaseToken belonged to different user ${oldDoc.id}`);
            }
          }
        } catch (linkError) {
          // Non-fatal — proceed with activation
          console.error("linkedPurchaseToken cleanup failed (non-fatal):", linkError.message);
        }
      }

      // ── Calculate expiry ───────────────────────────────────────────────
      const isGracePeriod = state === "SUBSCRIPTION_STATE_IN_GRACE_PERIOD";
      const expiresAt = purchase.expiryMillis
        ? purchase.expiryMillis
        : Date.now() + (PRODUCT_DURATION_DAYS[productId] || 30) * 86400000;

      // ── Write verified subscription to Firestore ───────────────────────
      const subscriptionData = {
        subscriptionPlan: "pro",
        subscriptionExpiresAt: expiresAt,
        subscriptionProductId: productId,
        subscriptionVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        subscriptionPurchaseToken: purchaseToken,
        subscriptionGracePeriod: isGracePeriod || false,
      };

      await db.collection("users").doc(uid).set(subscriptionData, { merge: true });

      console.log(`verifyPurchase: activated Pro for ${uid} (${productId}), expires ${new Date(expiresAt).toISOString()}${isGracePeriod ? " [GRACE PERIOD]" : ""}`);

      res.status(200).json({
        success: true,
        plan: "pro",
        productId,
        expiresAt,
        gracePeriod: isGracePeriod,
      });
    } catch (error) {
      console.error("verifyPurchase error:", error.message, error.stack);

      // Distinguish between Google API errors and server errors
      const status = error.response?.status || error.code;
      if (status === 404) {
        res.status(404).json({
          error: "Purchase not found",
          detail: "The purchase token may be invalid, expired, or already consumed. Try restoring purchases.",
        });
      } else if (status === 400) {
        res.status(400).json({
          error: "Invalid purchase token format",
          detail: "The token sent by the app is malformed. Please try purchasing again.",
        });
      } else if (status === 401 || status === 403) {
        res.status(500).json({
          error: "Server configuration error",
          detail: "The server's Google Play credentials are invalid. Please contact support.",
        });
      } else {
        res.status(500).json({
          error: "Server error verifying purchase",
          detail: `An unexpected error occurred: ${error.message}. Please try again.`,
        });
      }
    }
  }
);

// ─── Verify Subscription Status ──────────────────────────────────────────────
// Called by the client on app launch / cross-device sync to re-verify the
// current subscription status from the server. Returns the Firestore-stored
// subscription data, and optionally re-validates with Google Play if a
// purchase token exists.
//
// Robustness features:
// - Re-validates with Google Play v2 API (v1 fallback)
// - Handles renewal (updates expiry from Google)
// - Handles expiry / revocation
// - Falls back to cached Firestore data on transient Play API errors
exports.verifySubscriptionStatus = onRequest(
  { cors: true, invoker: "public", minInstances: 0, secrets: [playServiceAccountKey] },
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

    let uid;
    try {
      const decoded = await auth.verifyIdToken(authHeader.split("Bearer ")[1]);
      uid = decoded.uid;
    } catch (_) {
      res.status(401).json({ error: "Invalid or expired token" });
      return;
    }

    try {
      const userDoc = await db.collection("users").doc(uid).get();
      if (!userDoc.exists) {
        res.status(404).json({ error: "User not found" });
        return;
      }

      const userData = userDoc.data();
      const plan = userData.subscriptionPlan;
      const expiresAt = userData.subscriptionExpiresAt;
      const productId = userData.subscriptionProductId;
      const storedToken = userData.subscriptionPurchaseToken;

      // ── No subscription ────────────────────────────────────────────────
      if (plan !== "pro" || !expiresAt) {
        res.status(200).json({ plan: "free", expiresAt: null, productId: null });
        return;
      }

      // ── Already expired (server time) ──────────────────────────────────
      if (expiresAt < Date.now()) {
        // But before cleaning up, re-check with Google Play — maybe it renewed
        if (storedToken && productId && SUBSCRIPTION_PRODUCT_IDS.has(productId)) {
          try {
            const play = getPlayClient();
            const purchase = await getSubscriptionFromPlay(play, productId, storedToken);

            if (purchase.expiryMillis && purchase.expiryMillis > Date.now()) {
              // Renewed! Update Firestore with new expiry
              const isGrace = purchase.subscriptionState === "SUBSCRIPTION_STATE_IN_GRACE_PERIOD";
              await db.collection("users").doc(uid).update({
                subscriptionExpiresAt: purchase.expiryMillis,
                subscriptionVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
                subscriptionGracePeriod: isGrace || false,
              });
              console.log(`verifySubscriptionStatus: renewed subscription for ${uid}, new expiry ${new Date(purchase.expiryMillis).toISOString()}`);
              res.status(200).json({
                plan: "pro",
                expiresAt: purchase.expiryMillis,
                productId,
                gracePeriod: isGrace,
              });
              return;
            }
          } catch (playError) {
            console.warn(`verifySubscriptionStatus: Play API renewal check failed for ${uid}:`, playError.message);
            // Fall through to clean up
          }
        }

        // Truly expired — clean up
        await clearSubscriptionFirestore(uid);
        res.status(200).json({ plan: "free", expiresAt: null, productId: null });
        return;
      }

      // ── Re-verify with Google Play if we have a token ──────────────────
      if (storedToken && productId && SUBSCRIPTION_PRODUCT_IDS.has(productId)) {
        try {
          const play = getPlayClient();
          const purchase = await getSubscriptionFromPlay(play, productId, storedToken);

          const state = purchase.subscriptionState;
          const liveExpiryMillis = purchase.expiryMillis;

          // Revoked or expired according to Google
          if (state === "SUBSCRIPTION_STATE_REVOKED" ||
            state === "SUBSCRIPTION_STATE_EXPIRED" ||
            (liveExpiryMillis && liveExpiryMillis < Date.now())) {
            await clearSubscriptionFirestore(uid);
            console.log(`verifySubscriptionStatus: revoked/expired for ${uid} (state: ${state})`);
            res.status(200).json({ plan: "free", expiresAt: null, productId: null });
            return;
          }

          // On hold — no access but don't delete data (user may fix payment)
          if (state === "SUBSCRIPTION_STATE_ON_HOLD" || state === "SUBSCRIPTION_STATE_PAUSED") {
            console.log(`verifySubscriptionStatus: account on hold for ${uid} (state: ${state})`);
            res.status(200).json({
              plan: "free",
              expiresAt: null,
              productId: null,
              onHold: true,
              detail: "Your subscription is on hold. Please update your payment method in Google Play.",
            });
            return;
          }

          // Update expiry if Google returned a newer one (e.g. renewal)
          const isGrace = state === "SUBSCRIPTION_STATE_IN_GRACE_PERIOD";
          if (liveExpiryMillis && liveExpiryMillis !== expiresAt) {
            await db.collection("users").doc(uid).update({
              subscriptionExpiresAt: liveExpiryMillis,
              subscriptionVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
              subscriptionGracePeriod: isGrace || false,
            });
            res.status(200).json({
              plan: "pro",
              expiresAt: liveExpiryMillis,
              productId,
              gracePeriod: isGrace,
            });
            return;
          }
        } catch (playError) {
          // If Google Play check fails, fall through to return cached data
          // (don't revoke access just because of a transient API error)
          console.warn(`verifySubscriptionStatus: Play API check failed for ${uid}:`, playError.message);
        }
      }

      // ── Return cached subscription data ────────────────────────────────
      res.status(200).json({
        plan: "pro",
        expiresAt,
        productId,
      });
    } catch (error) {
      console.error("verifySubscriptionStatus error:", error.message);
      res.status(500).json({ error: "Server error checking subscription", detail: error.message });
    }
  }
);

// ═══════════════════════════════════════════════════════════════════════════════
// STREAK ENGINE — server-authoritative write path
// ═══════════════════════════════════════════════════════════════════════════════
// The legacy streak functions below (streakBrokenTrigger, streakMilestoneTrigger,
// hourlyStreakWarningBatch, streakExpiryJob) stay in place for the dual-write
// window and are retired in tasks 10.2 / 10.4. This section is the NEW path.

/** How long the message timestamp may lag server time and still count (2.11). */
const STREAK_BACKDATE_WINDOW_MS = 48 * 60 * 60 * 1000;

/** Kill-switch cache TTL — one config read per minute per instance, not per message. */
const STREAK_FLAG_TTL_MS = 60 * 1000;

// Module-scope cache for `_config/streak`. Warm instances therefore cost zero
// extra reads on the hot send path.
let _streakFlagValue = null;
let _streakFlagFetchedAt = 0;

/**
 * Whether the streak engine is enabled.
 *
 * DEFAULT IS **ENABLED**, deliberately: `_config/streak` is only created in task
 * 10.1, and a missing config document must not silently disable the feature.
 * Only an explicit `engineEnabled: false` turns the engine off. A failed read
 * also defaults to enabled — we'd rather evaluate a streak than lose a day of
 * participation because a config read blipped.
 *
 * @returns {Promise<boolean>}
 */
async function isStreakEngineEnabled() {
  const now = Date.now();
  if (_streakFlagValue !== null && now - _streakFlagFetchedAt < STREAK_FLAG_TTL_MS) {
    return _streakFlagValue;
  }
  let enabled = true; // explicit default
  try {
    const snap = await db.collection("_config").doc("streak").get();
    if (snap.exists && snap.data().engineEnabled === false) enabled = false;
  } catch (error) {
    console.warn("streak: config read failed, defaulting to ENABLED:", error.message);
  }
  _streakFlagValue = enabled;
  _streakFlagFetchedAt = now;
  return enabled;
}

/**
 * Whether an error is worth a platform retry. Transient Firestore/gRPC failures
 * (contention, unavailable, deadline exceeded) are RETHROWN so the trigger is
 * re-delivered — safe, because `applyParticipation` is idempotent. Anything that
 * looks permanent (a malformed document, a rejected invariant) is swallowed, so a
 * single bad message cannot spin in an infinite retry loop.
 *
 * @param {*} error
 * @returns {boolean}
 */
function isTransientFirestoreError(error) {
  if (!error) return false;
  const code = error.code;
  // gRPC numeric codes: 4 DEADLINE_EXCEEDED, 8 RESOURCE_EXHAUSTED, 10 ABORTED,
  // 13 INTERNAL, 14 UNAVAILABLE.
  if (typeof code === "number") return [4, 8, 10, 13, 14].includes(code);
  if (typeof code === "string") {
    return [
      "deadline-exceeded",
      "resource-exhausted",
      "aborted",
      "internal",
      "unavailable",
    ].includes(code);
  }
  return false;
}

/**
 * The side effects of one evaluation: milestone awards + the three pushes.
 *
 * Shared by `streakOnMessageCreate` and `streakSweepJob` so the two paths cannot
 * drift. Everything in here is idempotent or guarded elsewhere:
 *   * awards are guarded by the `streakAwards/{roomId}_{threshold}` create,
 *   * every push is guarded by `notifiedAt` on the state document inside
 *     `notify.js` — this function deliberately re-implements none of that.
 *
 * NEVER THROWS. A payout or a push must not fail (and therefore retry) the write
 * that produced it. The underlying helpers already swallow their own failures;
 * the outer try/catch is belt-and-braces.
 *
 * @param {string} roomId
 * @param {object} result envelope from `state.applyParticipation` / `state.reevaluate`
 * @param {*} serverNow the instant the evaluation was made against
 * @param {object} [opts]
 * @param {boolean} [opts.allowWarnings=false] send `atRisk`/`critical` warnings.
 *   Only the sweeper does: a warning belongs to the passage of time, not to a send.
 * @returns {Promise<{broken: boolean, warned: ?string, milestones: Array<number>}>}
 */
async function applyStreakSideEffects(roomId, result, serverNow, opts = {}) {
  const outcome = { broken: false, warned: null, milestones: [] };
  try {
    const next = (result && result.evaluation && result.evaluation.next) || null;
    if (next === null) return outcome;

    const transitions = Array.isArray(result.transitions) ? result.transitions : [];
    // Already empty unless `result.sideEffectsAllowed` — state.js applies the
    // (uid, day) dedupe before handing the envelope back.
    const milestones = Array.isArray(result.milestonesCrossed)
      ? result.milestonesCrossed
      : [];

    // ── milestones: pay first, announce second ────────────────────────────
    if (milestones.length > 0) {
      const awarded = await streakAwards.applyAwardsSafely(result, { serverNow });
      if (awarded && awarded.wrote) {
        console.log(
          `streak: awarded room=${roomId} thresholds=[${awarded.thresholdsAwarded.join(",")}]`
        );
      }
      // Announced per CROSSING, not per payout: a threshold with no configured
      // point value (today: 365) is still a real milestone for the user. The
      // milestone guard in notify.js is once-per-room-per-threshold forever, so a
      // re-emitted crossing cannot produce a second push.
      for (const threshold of milestones) {
        await streakNotify.notifyStreakMilestone(roomId, next, threshold, { serverNow });
        outcome.milestones.push(threshold);
      }
    }

    // ── broken beats at-risk: never tell someone to hurry after it lapsed ──
    if (transitions.includes(streakEngine.Transition.broken)) {
      await streakNotify.notifyStreakBroken(roomId, next, { serverNow });
      outcome.broken = true;
    } else if (
      opts.allowWarnings === true &&
      (next.riskLevel === streakEngine.RiskLevel.atRisk ||
        next.riskLevel === streakEngine.RiskLevel.critical)
    ) {
      await streakNotify.notifyStreakWarning(roomId, next, next.riskLevel, { serverNow });
      outcome.warned = next.riskLevel;
    }
  } catch (error) {
    console.error(
      `streak: side effects failed for room ${roomId} (swallowed):`,
      error && error.stack ? error.stack : error
    );
  }
  return outcome;
}

// ─── Trigger: participation from a persisted message ──────────────────────────
// The ONLY entry point that folds a send into a room's streak. Because it fires
// from the persisted document, a delivered message is always eventually counted
// even if the app dies right after `batch.commit()` (2.8), and the client send
// path performs no streak write at all.
//
// Reads only the cleartext fields `senderId`, `type` and `timestamp` — present
// even at `schemaVersion: 2` (MessageModel.toMap) — so E2EE is untouched.
// ─── E2EE Resend Wakeup ────────────────────────────────────────────────────
// Wakes a message's *sender* so their app can answer a resend request.
//
// When a recipient can't decrypt a message, the only party who can repair it is
// the sender: they hold the plaintext and can re-encrypt it over a fresh Signal
// session. We hold nothing but ciphertext, so there is no server-side fix — the
// entire job here is delivery of a silent nudge.
//
// The recipient writes a `resendWakeups` doc alongside the request it puts on the
// message document (see ChatService._publishResendWakeup). A trigger on the
// message document would have worked without any client change, but those are
// updated on every read receipt and delivery tick — a few needless invocations
// per message forever. This fires only on a real request.
//
// Data-only push, no `notification` block: a notification would land in the tray
// and pull the sender's attention to something they never need to see. The point
// is to start their process, not to tell them anything.
exports.notifyResendRequest = onDocumentCreated(
  { document: "resendWakeups/{wakeupId}", region: "us-central1" },
  async (event) => {
    const snap = event.data;
    if (!snap || !snap.exists) return null;
    const d = snap.data() || {};

    try {
      const { senderId, requesterId, roomId, messageId } = d;
      if (
        typeof senderId !== "string" || senderId.length === 0 ||
        typeof roomId !== "string" || roomId.length === 0 ||
        typeof messageId !== "string" || messageId.length === 0 ||
        senderId === requesterId
      ) {
        console.warn(`notifyResendRequest: malformed doc ${event.params.wakeupId}, dropping`);
        return null;
      }

      // Drop a backlog or a replay. The requester gives up on a round after a
      // couple of minutes, so waking a phone for a request nobody is waiting on
      // any more costs battery for nothing.
      const atMs = d.at && typeof d.at.toMillis === "function" ? d.at.toMillis() : 0;
      if (atMs > 0 && Date.now() - atMs > 5 * 60 * 1000) {
        console.log(`notifyResendRequest: ${messageId} is stale, dropping`);
        return null;
      }

      const result = await sendToUserDevices(senderId, (token) => ({
        token,
        data: {
          type: "resend_request",
          roomId,
          messageId,
          // Keyed `receiverId` so the client can reuse
          // FCMService._isMessageForCurrentUser unchanged. The sender of the
          // message is the receiver of this push.
          receiverId: senderId,
        },
        android: {
          // Required for delivery to a Doze-mode or idle device. Without it the
          // push waits for the next maintenance window, which can be hours —
          // long past the point the recipient stopped waiting.
          priority: "high",
        },
        apns: {
          headers: {
            // Apple rejects priority 10 on a background push.
            "apns-priority": "5",
            "apns-push-type": "background",
          },
          payload: { aps: { "content-available": 1 } },
        },
      }));

      if (!result.ok) {
        // Expected whenever the sender has no live token. Not an error worth
        // retrying: the request is already on the message document, so their app
        // repairs the bubble the next time it opens.
        console.log(`notifyResendRequest: ${messageId} not delivered — ${JSON.stringify(result.body)}`);
      }
      return null;
    } catch (error) {
      console.error(`notifyResendRequest failed for ${event.params.wakeupId}:`, error);
      return null;
    }
    // Deliberately no delete, on any path — including the malformed and stale
    // ones. The document id is what rate-limits this Function: it is derived from
    // (room, message, requester device, attempt), and `firestore.rules` denies
    // updates, so a spent id is a permanently spent push. Deleting the document
    // would hand that id back and let a modified client re-trigger the same
    // wakeup as fast as it could write.
    //
    // Growth is bounded operationally instead, by a Firestore TTL policy on the
    // `at` field. Any retention over a few hours is safe: a legitimate client
    // never reissues an attempt number (it is lifetime-monotonic per message), so
    // recycling an id after expiry caps a modified client at one push per attempt
    // per retention window, and a create still has to satisfy the live
    // `retryRequests` check. Forgetting to configure the policy fails safe — a
    // stricter bound, at the cost of some very small documents.
  }
);

exports.streakOnMessageCreate = onDocumentCreated(
  { document: "chatRooms/{roomId}/messages/{messageId}", region: "us-central1" },
  async (event) => {
    const roomId = event.params.roomId;
    const messageId = event.params.messageId;

    try {
      // ── 0. kill switch ────────────────────────────────────────────────────
      if (!(await isStreakEngineEnabled())) return null;

      const snap = event.data;
      if (!snap || !snap.exists) return null;
      const message = snap.data() || {};

      // ── 1. reactions never qualify (2.10) — single enforcement point ──────
      if (message.type === "reaction") return null;

      const senderId = message.senderId;
      if (typeof senderId !== "string" || senderId.length === 0) {
        console.warn(`streakOnMessageCreate: ${roomId}/${messageId} has no senderId, skipping`);
        return null; // permanently bad document — do not retry
      }

      // ── 2. two distinct participants only (2.9) ───────────────────────────
      // Read the parent room once here and hand `participants` to the state
      // adapter so it does not read the same document again.
      const roomSnap = await db.collection("chatRooms").doc(roomId).get();
      if (!roomSnap.exists) return null;
      const rawParticipants = roomSnap.data().participants;
      if (!Array.isArray(rawParticipants)) return null;
      const participants = Array.from(
        new Set(rawParticipants.filter((id) => typeof id === "string" && id.length > 0))
      );
      if (participants.length !== 2) return null; // self-chat or group-shaped room
      if (!participants.includes(senderId)) {
        console.warn(
          `streakOnMessageCreate: sender ${senderId} is not a participant of ${roomId}, skipping`
        );
        return null;
      }

      // ── 3. clamp the client timestamp into a trustworthy window (2.11/2.13)
      // Upper bound: server time — a skewed client clock cannot push a send into
      // the future. Lower bound: server time − 48h — a legitimately late mesh or
      // retried message still lands on its real day, but arbitrary backdating is
      // impossible. Missing/unparseable timestamp falls back to server time.
      const serverNow = streakDay.instantFrom(event.time) || new Date();
      const serverNowMs = serverNow.getTime();
      const claimedMs = streakDay.instantMillis(message.timestamp);
      const qualifyingMs =
        claimedMs === null
          ? serverNowMs
          : Math.min(Math.max(claimedMs, serverNowMs - STREAK_BACKDATE_WINDOW_MS), serverNowMs);
      const qualifyingInstant = new Date(qualifyingMs);

      // ── 4. fold the participation in, transactionally ─────────────────────
      const result = await streakState.applyParticipation(
        roomId,
        { uid: senderId, instant: qualifyingInstant },
        { serverNow, reason: streakState.EvaluationReason.send, participants }
      );

      // ── 5. side effects: awards, then notifications ───────────────────────
      // `result.milestonesCrossed` is already empty unless
      // `result.sideEffectsAllowed`, so the dedupe verdict needs no re-check
      // here. Both helpers are the *Safely / never-throw variants, and the whole
      // block is additionally wrapped: a push or a payout must never fail (and so
      // never retry) a message write that has already been folded in.
      await applyStreakSideEffects(roomId, result, serverNow);

      if (result.wrote) {
        console.log(
          `streakOnMessageCreate: ${roomId} rev=${result.rev} ` +
          `count=${result.evaluation.next.count} transitions=[${result.transitions.join(",")}]`
        );
      }
      return null;
    } catch (error) {
      if (isTransientFirestoreError(error)) {
        // Let the platform retry: applyParticipation is idempotent.
        console.warn(
          `streakOnMessageCreate: transient failure for ${roomId}/${messageId}, retrying:`,
          error.message
        );
        throw error;
      }
      console.error(
        `streakOnMessageCreate: permanent failure for ${roomId}/${messageId}:`,
        error && error.stack ? error.stack : error
      );
      return null; // swallow — never spin on a permanently bad document
    }
  }
);

// ─── Scheduled: the streak sweeper ────────────────────────────────────────────
// Replaces BOTH `hourlyStreakWarningBatch` and `streakExpiryJob` (design §6).
// Every 15 minutes it re-derives the streaks that are near or past their deadline
// and lets the engine decide: stamp the break at the real `deadlineAt` (not the
// sweep instant, defect 1.14), or move the room into `atRisk`/`critical`. It is
// the reason a streak breaks, and a warning arrives, with no app open anywhere.

/** Rooms per query page. Small enough to keep one page's work well inside the timeout. */
const SWEEP_PAGE_SIZE = 200;

/**
 * Hard ceiling on rooms per invocation. A scheduled function has a wall-clock
 * timeout; without a cap a large backlog would be killed mid-page and silently
 * lose the tail. With it, the overflow is LOGGED and picked up 15 minutes later —
 * the query is ordered by `deadlineAt`, so the oldest lapses are always swept
 * first and no room can starve.
 */
const SWEEP_MAX_ROOMS = 3000;

/** How far ahead of now to look: the whole grace day plus 2h of slack. */
const SWEEP_HORIZON_MS = 26 * 60 * 60 * 1000;

let _sweepFlagValue = null;
let _sweepFlagFetchedAt = 0;

/**
 * Whether the sweeper is enabled.
 *
 * DEFAULT IS **DISABLED** — deliberately the OPPOSITE of `isStreakEngineEnabled`,
 * and that asymmetry is not a mistake. The engine defaults on because a missing
 * config document must not lose participation. The sweeper defaults off because
 * the legacy `streakExpiryJob` / `hourlyStreakWarningBatch` are still live: a
 * sweeper that self-enabled before the rollout's step 3 (task 10.2) would
 * double-process the same rooms and double-notify. It runs only on an explicit
 * `sweepEnabled: true`, and a failed config read also means "stay dark".
 *
 * @returns {Promise<boolean>}
 */
async function isStreakSweepEnabled() {
  const now = Date.now();
  if (_sweepFlagValue !== null && now - _sweepFlagFetchedAt < STREAK_FLAG_TTL_MS) {
    return _sweepFlagValue;
  }
  let enabled = false; // explicit default
  try {
    const snap = await db.collection("_config").doc("streak").get();
    if (snap.exists && snap.data().sweepEnabled === true) enabled = true;
  } catch (error) {
    console.warn("streakSweepJob: config read failed, staying DISABLED:", error.message);
  }
  _sweepFlagValue = enabled;
  _sweepFlagFetchedAt = now;
  return enabled;
}

exports.streakSweepJob = onSchedule(
  { schedule: "every 15 minutes", region: "us-central1" },
  async () => {
    if (!(await isStreakSweepEnabled())) {
      console.log("streakSweepJob: disabled (_config/streak.sweepEnabled is not true)");
      return;
    }

    const serverNow = new Date();
    const horizon = admin.firestore.Timestamp.fromDate(
      new Date(serverNow.getTime() + SWEEP_HORIZON_MS)
    );

    // Precise by construction: `deadlineAt <= now + 26h` is exactly the set of
    // rooms in the grace day, critical, or already lapsed. No scan of every room
    // with `streakCount > 0`. Backed by the collection-group index on
    // `streak.deadlineAt` in firestore.indexes.json.
    const baseQuery = db
      .collectionGroup("streak")
      .where("deadlineAt", "<=", horizon)
      .orderBy("deadlineAt")
      .limit(SWEEP_PAGE_SIZE);

    let cursor = null;
    let scanned = 0;
    let rewritten = 0;
    let broken = 0;
    let warned = 0;
    let milestoned = 0;
    let failed = 0;
    let capped = false;

    while (true) {
      const page = await (cursor === null ? baseQuery : baseQuery.startAfter(cursor)).get();
      if (page.empty) break;
      cursor = page.docs[page.docs.length - 1];

      for (const doc of page.docs) {
        if (scanned >= SWEEP_MAX_ROOMS) {
          capped = true;
          break;
        }
        // chatRooms/{roomId}/streak/state → the room is the grandparent.
        const roomId = doc.ref.parent.parent ? doc.ref.parent.parent.id : null;
        if (roomId === null) continue;
        scanned++;

        // One room's failure must never abort the sweep: log it and move on. The
        // next invocation retries it, since its deadline still matches the query.
        try {
          const result = await streakState.reevaluate(
            roomId,
            streakState.EvaluationReason.sweep,
            { serverNow }
          );
          if (result.wrote) rewritten++;

          const outcome = await applyStreakSideEffects(roomId, result, serverNow, {
            allowWarnings: true,
          });
          if (outcome.broken) broken++;
          if (outcome.warned !== null) warned++;
          if (outcome.milestones.length > 0) milestoned++;
        } catch (error) {
          failed++;
          console.error(
            `streakSweepJob: room ${roomId} failed:`,
            error && error.stack ? error.stack : error
          );
        }
      }

      if (capped || page.size < SWEEP_PAGE_SIZE) break;
    }

    if (capped) {
      console.warn(
        `streakSweepJob: hit the ${SWEEP_MAX_ROOMS}-room cap; the remainder is ` +
        "deferred to the next run (oldest deadlines are swept first)"
      );
    }
    console.log(
      `streakSweepJob done: scanned=${scanned} rewritten=${rewritten} ` +
      `broken=${broken} warned=${warned} milestoned=${milestoned} failed=${failed} capped=${capped}`
    );
  }
);

// ═══════════════════════════════════════════════════════════════════════════════
// STREAK REPAIR / MIGRATION (design §10, task 9.2)
// ═══════════════════════════════════════════════════════════════════════════════
// Two drivers over `functions/streak/repair.js`:
//
//   streakRepairJob   onSchedule("every 5 minutes") — 200 rooms per invocation,
//                     resumable from the `_migrations/streakV2` cursor,
//   streakRepairRoom  onRequest + admin token — dry runs and spot fixes on one
//                     room, and a `?status=1` read of the cursor.
//
// THREE independent brakes, all of which must be released for a live run:
//   1. `_config/streak.repairEnabled === true`  — default DISABLED,
//   2. `_config/streak.engineEnabled !== false` — a repair into a dark engine
//      would be rewritten by nobody and read by nobody,
//   3. `_config/streak.repairDryRun === false`  — default DRY RUN. Anything
//      ambiguous (missing document, missing field, non-boolean) stays dry.
// The job can therefore never self-start, and cannot mutate a streak on its own.

/** Rooms per scheduled invocation (design §10). */
const REPAIR_PAGE_SIZE = 200;

let _repairFlagValue = null;
let _repairFlagFetchedAt = 0;

/**
 * The repair flags, cached for `STREAK_FLAG_TTL_MS`.
 *
 * DEFAULTS ARE THE SAFE ONES in every direction: disabled, and dry-run if it were
 * somehow enabled. A failed config read returns the same defaults — a blipped
 * read must not be able to start a migration.
 *
 * @returns {Promise<{enabled: boolean, dryRun: boolean, engineOff: boolean}>}
 */
async function readStreakRepairFlags() {
  const now = Date.now();
  if (_repairFlagValue !== null && now - _repairFlagFetchedAt < STREAK_FLAG_TTL_MS) {
    return _repairFlagValue;
  }
  let flags = { enabled: false, dryRun: true, engineOff: false };
  try {
    const snap = await db.collection("_config").doc("streak").get();
    const data = snap.exists ? snap.data() || {} : {};
    flags = {
      enabled: data.repairEnabled === true,
      // `resolveDryRun` is the single definition of "live": the boolean false.
      dryRun: streakRepair.resolveDryRun(data.repairDryRun),
      engineOff: data.engineEnabled === false,
    };
  } catch (error) {
    console.warn(
      "streakRepair: config read failed, staying DISABLED and DRY:",
      error.message
    );
  }
  _repairFlagValue = flags;
  _repairFlagFetchedAt = now;
  return flags;
}

/**
 * Constant-time secret comparison. Byte lengths are compared first (which
 * `timingSafeEqual` requires anyway, and which leaks nothing useful about a
 * random token), and an unset/empty secret never matches.
 *
 * @param {string} presented
 * @param {*} expected
 * @returns {boolean}
 */
function _secretEquals(presented, expected) {
  if (typeof expected !== "string" || expected.length === 0) return false;
  const a = Buffer.from(String(presented || ""), "utf8");
  const b = Buffer.from(expected, "utf8");
  if (a.length !== b.length) return false;
  return crypto.timingSafeEqual(a, b);
}

/** One-line summary of a page aggregate, for the job log. */
function _repairAggregateLine(aggregate) {
  const histogram = Object.entries(aggregate.mismatchHistogram || {})
    .map(([bucket, hits]) => `${bucket}=${hits}`)
    .join(" ");
  return (
    `dryRun=${aggregate.dryRun} processed=${aggregate.processed} ` +
    `repaired=${aggregate.repaired} fallback=${aggregate.fallback} ` +
    `skipped=${aggregate.skipped} failed=${aggregate.failed} ` +
    `lastRoomId=${aggregate.lastRoomId} finished=${aggregate.finished}` +
    (histogram ? ` | ${histogram}` : "")
  );
}

exports.streakRepairJob = onSchedule(
  { schedule: "every 5 minutes", region: "us-central1" },
  async () => {
    const flags = await readStreakRepairFlags();
    if (!flags.enabled) {
      // Deliberately quiet-ish: this is the steady state until task 9.4/9.5.
      console.log("streakRepairJob: disabled (_config/streak.repairEnabled is not true)");
      return;
    }
    if (flags.engineOff) {
      console.warn(
        "streakRepairJob: refusing to run while _config/streak.engineEnabled is false"
      );
      return;
    }

    const serverNow = new Date();
    const { aggregate, cursorBefore } = await streakRepair.runNextPage({
      dryRun: flags.dryRun,
      limit: REPAIR_PAGE_SIZE,
      serverNow,
    });

    if (aggregate.processed === 0 && aggregate.skipped === 0 && aggregate.finished) {
      console.log(
        `streakRepairJob: nothing left after ${cursorBefore.lastRoomId || "<start>"} ` +
        `(dryRun=${aggregate.dryRun})`
      );
      return;
    }
    console.log(`streakRepairJob done: ${_repairAggregateLine(aggregate)}`);
  }
);

// ─── Admin: dry runs, spot fixes and cursor inspection ────────────────────────
// `POST /streakRepairRoom  {roomId, dryRun?, force?}` → the per-room report
// `GET  /streakRepairRoom?status=1`                   → the cursor document
//
// `dryRun` defaults to TRUE here too, and a request may only go live by sending
// `dryRun: false` explicitly AND having `_config/streak.repairEnabled === true`.
// A spot fix does not consult `repairDryRun`: it is one room, chosen by an
// operator, and the report comes straight back in the response.
exports.streakRepairRoom = onRequest(
  { cors: false, invoker: "public", secrets: [streakAdminToken] },
  async (req, res) => {
    // ── admin token, compared in constant time ────────────────────────────────
    const expected = streakAdminToken.value();
    const authHeader = req.headers.authorization || "";
    const presented = authHeader.startsWith("Bearer ")
      ? authHeader.slice("Bearer ".length)
      : String(req.headers["x-streak-admin-token"] || "");
    if (!_secretEquals(presented, expected)) {
      res.status(401).json({ error: "Unauthorized" });
      return;
    }

    try {
      if (req.method === "GET" && (req.query.status || req.query.cursor)) {
        const cursor = await streakRepair.readCursor();
        res.status(200).json({
          cursor: Object.assign({}, cursor, {
            startedAt: cursor.startedAt ? cursor.startedAt.getTime() : null,
            finishedAt: cursor.finishedAt ? cursor.finishedAt.getTime() : null,
          }),
        });
        return;
      }

      if (req.method !== "POST") {
        res.status(405).json({ error: "Method not allowed" });
        return;
      }

      const body = req.body || {};
      const roomId = body.roomId;
      if (typeof roomId !== "string" || roomId.length === 0) {
        res.status(400).json({ error: "roomId is required" });
        return;
      }

      const dryRun = streakRepair.resolveDryRun(body.dryRun);
      if (!dryRun) {
        const flags = await readStreakRepairFlags();
        if (!flags.enabled || flags.engineOff) {
          res.status(409).json({
            error: "Live repair is not enabled",
            detail:
              "_config/streak.repairEnabled must be true and engineEnabled must not be false",
          });
          return;
        }
      }

      const report = await streakRepair.repairRoom(roomId, {
        dryRun,
        force: body.force === true,
        serverNow: new Date(),
      });
      res.status(200).json({ ok: true, dryRun, report });
    } catch (error) {
      console.error(
        "streakRepairRoom error:",
        error && error.stack ? error.stack : error
      );
      res.status(500).json({ error: "Server error repairing room", detail: error.message });
    }
  }
);

// ═══════════════════════════════════════════════════════════════════════════════
// STREAK HTTP ENDPOINTS (design §8, task 5.8)
// ═══════════════════════════════════════════════════════════════════════════════
// Four `onRequest` functions consumed by `lib/services/streak/streak_api.dart`:
//
//   GET  /serverTime                     → { now: <epochMillis> }   (public)
//   POST /streakEvaluate       {roomId}  → { ok, ... }              (participant)
//   GET  /streakRestoreQuote?roomId=…    → quote                    (participant)
//   POST /streakRestore  {roomId, useFreePerk} → restore outcome    (participant)
//
// Auth, CORS and error shapes are copied verbatim from `verifySubscriptionStatus`:
// `{ cors: true, invoker: "public" }`, `Authorization: Bearer <idToken>` verified
// with `auth.verifyIdToken`, 401 `{error}` on a missing/bad token, 405 on the
// wrong method, 500 `{error, detail}` on an unexpected failure.
//
// Instants are emitted as EPOCH MILLIS — `streakInstantFrom` on the client
// accepts millis, and a number cannot be mangled by a timezone-naive parse.

/** One nudge per room per five minutes (task 5.8). */
const STREAK_NUDGE_COOLDOWN_MS = 5 * 60 * 1000;

/** Rejects a request that carries no usable `Authorization: Bearer` header. */
async function _streakAuthUid(req, res) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    res.status(401).json({ error: "Unauthorized", reason: "unauthenticated" });
    return null;
  }
  try {
    const decoded = await auth.verifyIdToken(authHeader.split("Bearer ")[1]);
    return decoded.uid;
  } catch (_) {
    res.status(401).json({ error: "Invalid or expired token", reason: "unauthenticated" });
    return null;
  }
}

function _epochOrNull(value) {
  return streakDay.instantMillis(value);
}

/**
 * The ISO-8601 week key (`'GGGG-Www'`) that [instant] falls in, computed in the
 * CANONICAL streak zone — so the Pro allowance resets on the same boundary the
 * streak calendar uses, in every deployment region.
 *
 * Implementation: shift the instant into canonical wall-clock time, then apply
 * the standard Thursday rule on UTC getters only (never local ones): move to the
 * Thursday of the current ISO week (Monday = day 1), and the week number is
 * `1 + floor(dayOfYear(thursday) / 7)` with that Thursday's year as the ISO
 * week-year. This is exactly ISO 8601, including the year-boundary cases where
 * 1 January belongs to week 52/53 of the previous year.
 *
 * @param {*} instant
 * @returns {string} e.g. `'2026-W07'`
 */
function isoWeekKeyInCanonicalZone(instant) {
  const ms = streakDay.instantMillis(instant);
  if (ms === null) throw new TypeError("instant is required");
  const shifted = new Date(
    ms + streakDay.CANONICAL_DAY_OFFSET_MINUTES * streakDay.MS_PER_MINUTE
  );
  // Midnight of that canonical day, as a UTC instant we can do integer days on.
  const dayStart = Date.UTC(
    shifted.getUTCFullYear(),
    shifted.getUTCMonth(),
    shifted.getUTCDate()
  );
  const isoDow = shifted.getUTCDay() === 0 ? 7 : shifted.getUTCDay(); // Mon=1..Sun=7
  const thursday = new Date(dayStart + (4 - isoDow) * streakDay.MS_PER_DAY);
  const weekYear = thursday.getUTCFullYear();
  const jan1 = Date.UTC(weekYear, 0, 1);
  const dayOfYear = Math.round((thursday.getTime() - jan1) / streakDay.MS_PER_DAY);
  const week = 1 + Math.floor(dayOfYear / 7);
  return `${weekYear}-W${String(week).padStart(2, "0")}`;
}

/**
 * Whether [userData] is Pro right now, per the SERVER-side mirror only
 * (`subscriptionPlan === 'pro'` and `subscriptionExpiresAt` in the future).
 * `SubscriptionService` on the device is never consulted (defect 1.20).
 *
 * @param {?object} userData
 * @param {number} nowMs
 * @returns {boolean}
 */
function isProUser(userData, nowMs) {
  if (!userData || userData.subscriptionPlan !== "pro") return false;
  const expiresAt = _epochOrNull(userData.subscriptionExpiresAt);
  return expiresAt !== null && expiresAt > nowMs;
}

/**
 * Whether the weekly free-restore allowance is still unused for the ISO week
 * [weekKey]. A stored key from any other week is stale and means "unused" — that
 * is the real weekly reset the SharedPreferences version could never do.
 *
 * @param {?object} userData
 * @param {string} weekKey
 * @returns {boolean}
 */
function hasFreeRestoreAllowance(userData, weekKey) {
  const allowance = userData && userData.streakRestoreAllowance;
  if (!allowance || typeof allowance !== "object") return true;
  if (allowance.weekKey !== weekKey) return true; // different week → reset
  const used = Number(allowance.used);
  return !Number.isFinite(used) || used < 1;
}

// ─── Rewarded-ad reward limits ────────────────────────────────────────────────
// These two numbers are the AUTHORITATIVE ones — `admobSsv` is what actually
// credits an account, so nothing a client claims can change them.
//
// The Remote Config keys `ads_reward_points` and `ads_rewarded_daily_cap` are
// display-only: they tell the UI what to promise. KEEP THEM IN SYNC WITH THESE.
// If they diverge, the app advertises one figure and the server pays another,
// which reads to the user as the reward being broken.
const ADS_REWARD_POINTS = 50;
const ADS_REWARD_DAILY_CAP = 10;

// One ad-granted Bond Restore per ISO week, deliberately: a free restore is the
// Pro tier's headline weekly perk, and an uncapped ad route would undercut the
// thing people are paying for.
const ADS_RESTORE_WEEKLY_CAP = 1;

/**
 * How many paid rewarded views [userData] already has on the canonical day
 * [dayKey]. A counter from any other day is stale and counts as zero — the same
 * "the key IS the reset" trick as `hasFreeRestoreAllowance`, which is why no
 * sweeper job is needed to roll the day over.
 *
 * @param {?object} userData
 * @param {string} dayKey
 * @returns {number}
 */
function adRewardDailyCount(userData, dayKey) {
  return _staleKeyedCount(userData && userData.adRewardDaily, "dayKey", dayKey);
}

/**
 * How many ad-granted Bond Restores [userData] earned in the ISO week [weekKey].
 *
 * @param {?object} userData
 * @param {string} weekKey
 * @returns {number}
 */
function adRestoreWeeklyCount(userData, weekKey) {
  return _staleKeyedCount(userData && userData.adRestoreWeekly, "weekKey", weekKey);
}

/**
 * Whether an ad-granted Bond Restore can still be earned in the ISO week
 * [weekKey].
 *
 * @param {?object} userData
 * @param {string} weekKey
 * @returns {boolean}
 */
function _adRestoreEarnableThisWeek(userData, weekKey) {
  return adRestoreWeeklyCount(userData, weekKey) < ADS_RESTORE_WEEKLY_CAP;
}

function _staleKeyedCount(bucket, keyField, expectedKey) {
  if (!bucket || typeof bucket !== "object") return 0;
  if (bucket[keyField] !== expectedKey) return 0; // different period → reset
  const count = Number(bucket.count);
  return Number.isFinite(count) && count > 0 ? count : 0;
}

/**
 * The participants of a room, preferring the state document and falling back to
 * the parent room (a bond with no state document yet).
 *
 * @param {string} roomId
 * @returns {Promise<{participants: Array<string>, state: ?object, exists: boolean}>}
 */
async function _readStreakParticipants(roomId) {
  const snap = await streakState.stateRef(roomId).get();
  if (snap.exists) {
    const state = streakEngine.normalizeState(snap.data());
    if (state.participants.length === 2) {
      return { participants: state.participants, state, exists: true };
    }
    const roomSnap = await db.collection("chatRooms").doc(roomId).get();
    const raw = roomSnap.exists ? roomSnap.data().participants : null;
    return { participants: Array.isArray(raw) ? raw : [], state, exists: true };
  }
  const roomSnap = await db.collection("chatRooms").doc(roomId).get();
  const raw = roomSnap.exists ? roomSnap.data().participants : null;
  return { participants: Array.isArray(raw) ? raw : [], state: null, exists: false };
}

// ─── 1. GET /serverTime ───────────────────────────────────────────────────────
// The clock source for `ServerClock` (task 7.1). Deliberately trivial: no auth,
// no Firestore read, no body parsing — the whole point is that it is the cheapest
// and fastest endpoint in the project, because every client polls it.
exports.serverTime = onRequest(
  { cors: true, invoker: "public", minInstances: 0 },
  (req, res) => {
    res.set("Cache-Control", "no-store");
    res.status(200).json({ now: Date.now() });
  }
);

// ─── 2. POST /streakEvaluate ───────────────────────────────────────────────────
// A client nudge: "my derived state says this bond is broken but the stored
// document has not caught up". Purely an optimisation over the sweeper, so it is
// idempotent (`state.reevaluate` writes only when the derivation differs) and
// rate-limited.
//
// RATE LIMIT MECHANISM: a `lastNudgedAt` field on the state document, claimed in
// its own tiny transaction before the evaluation runs. Chosen over a `_rateLimits`
// collection because the document is already the contention point for this room,
// it needs no new collection, no new security rule and no TTL sweeper, and
// `normalizeState` round-trips unknown fields through `extraFields` so the field
// survives every subsequent engine write untouched.
exports.streakEvaluate = onRequest(
  { cors: true, invoker: "public", minInstances: 0 },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const uid = await _streakAuthUid(req, res);
    if (uid === null) return;

    const roomId = req.body && req.body.roomId;
    if (typeof roomId !== "string" || roomId.length === 0) {
      res.status(400).json({ error: "roomId is required", reason: "bad-request" });
      return;
    }

    try {
      const { participants, exists } = await _readStreakParticipants(roomId);
      if (!participants.includes(uid)) {
        res.status(403).json({ error: "Not a participant", reason: "not-participant" });
        return;
      }
      if (!exists) {
        // Nothing has ever been evaluated for this room; there is no stored
        // state to correct, and a nudge must not bootstrap one.
        res.status(200).json({ ok: true, skipped: "no-state" });
        return;
      }

      // ── rate-limit claim ──────────────────────────────────────────────────
      const ref = streakState.stateRef(roomId);
      const nowMs = Date.now();
      const claimed = await db.runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        if (!snap.exists) return false;
        const lastMs = _epochOrNull(snap.data().lastNudgedAt);
        if (lastMs !== null && nowMs - lastMs < STREAK_NUDGE_COOLDOWN_MS) return false;
        tx.update(ref, { lastNudgedAt: new Date(nowMs) });
        return true;
      });
      if (!claimed) {
        res.status(200).json({ ok: true, skipped: "rate-limited" });
        return;
      }

      const result = await streakState.reevaluate(
        roomId,
        streakState.EvaluationReason.nudge,
        { serverNow: new Date(nowMs), participants }
      );
      const next = (result.evaluation && result.evaluation.next) || null;

      res.status(200).json({
        ok: true,
        changed: result.changed === true,
        rev: result.rev,
        count: next === null ? null : next.count,
        riskLevel: next === null ? null : next.riskLevel,
        transitions: result.transitions || [],
        serverNow: nowMs,
      });
    } catch (error) {
      console.error("streakEvaluate error:", error && error.message);
      res.status(500).json({ error: "Server error evaluating streak", detail: error.message });
    }
  }
);

// ─── 3. GET /streakRestoreQuote?roomId=… ──────────────────────────────────────
// Everything `StreakRestoreDialog` needs to render, decided server-side: the cost
// tier, whether the Pro weekly perk is actually available, the window end, and
// server time so the countdown does not tick off the device clock.
exports.streakRestoreQuote = onRequest(
  { cors: true, invoker: "public", minInstances: 0 },
  async (req, res) => {
    if (req.method !== "GET") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const uid = await _streakAuthUid(req, res);
    if (uid === null) return;

    const roomId = req.query && req.query.roomId;
    if (typeof roomId !== "string" || roomId.length === 0) {
      res.status(400).json({ error: "roomId is required", reason: "bad-request" });
      return;
    }

    try {
      const { participants, state } = await _readStreakParticipants(roomId);
      if (!participants.includes(uid)) {
        res.status(403).json({ error: "Not a participant", reason: "not-participant" });
        return;
      }

      const nowMs = Date.now();
      const brokenAtMs = state === null ? null : _epochOrNull(state.brokenAt);
      const previousCount = state === null ? 0 : state.previousCount;
      if (brokenAtMs === null || previousCount <= 0) {
        res.status(404).json({ error: "Nothing to restore", reason: "nothing-to-restore" });
        return;
      }

      const deadlineMs = _epochOrNull(state.restoreDeadlineAt);
      if (deadlineMs !== null && nowMs > deadlineMs) {
        res.status(410).json({ error: "Restore window expired", reason: "window-expired" });
        return;
      }

      const otherUid = participants.find((id) => id !== uid) || null;
      const [userSnap, nameMap] = await Promise.all([
        db.collection("users").doc(uid).get(),
        getUserNames(otherUid === null ? [] : [otherUid]),
      ]);
      const userData = userSnap.exists ? userSnap.data() : null;
      const weekKey = isoWeekKeyInCanonicalZone(nowMs);
      const canUseFreePerk =
        isProUser(userData, nowMs) && hasFreeRestoreAllowance(userData, weekKey);

      // Rewarded-ad state, so the dialog can tell the three cases apart: spend a
      // banked credit now, watch an ad to earn one, or neither (already earned
      // this week — the cap is per ISO week, see `admobSsv`).
      const adRestoreCredits = Math.max(0, Number(userData && userData.adRestoreCredits) || 0);
      const canEarnAdRestore = _adRestoreEarnableThisWeek(userData, weekKey);

      res.status(200).json({
        previousCount,
        cost: streakEngine.restoreCost(previousCount),
        canUseFreePerk,
        adRestoreCredits,
        canEarnAdRestore,
        restoreDeadlineAt: deadlineMs,
        serverNow: nowMs,
        contactName: otherUid === null ? null : nameMap[otherUid] || null,
        weekKey,
      });
    } catch (error) {
      console.error("streakRestoreQuote error:", error && error.message);
      res.status(500).json({ error: "Server error building quote", detail: error.message });
    }
  }
);

// ─── 4. POST /streakRestore ───────────────────────────────────────────────────
// The whole restore decision, in ONE transaction over `users/{uid}` and the state
// document. Three defects die here:
//
//   1.18 — no mutual day is invented. `lastMutualDay` is left EXACTLY as it was;
//          continuity comes from `bridgedThroughDay`, so the next increment still
//          requires both participants to send on one canonical day.
//   1.19 — the client writes nothing, so no later message can clobber the count.
//   1.20 — the free perk lives in `users/{uid}.streakRestoreAllowance`, keyed by a
//          real ISO week in the canonical zone, so it survives a reinstall and
//          resets on a real weekly boundary.
//
// The window is checked against SERVER time (2.20). Awards and the notification
// run AFTER the commit: the count JUMPS here (5 → 12), and `engine.evaluate` can
// only ever report a single crossing, so `awardCrossedUpToSafely` is the only
// thing that pays the thresholds the jump flew past.
exports.streakRestore = onRequest(
  { cors: true, invoker: "public", minInstances: 0 },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const uid = await _streakAuthUid(req, res);
    if (uid === null) return;

    const roomId = req.body && req.body.roomId;
    if (typeof roomId !== "string" || roomId.length === 0) {
      res.status(400).json({ error: "roomId is required", reason: "bad-request" });
      return;
    }
    const wantsFreePerk =
      req.body.useFreePerk === true || req.body.useFreePerk === "true";

    const stateDocRef = streakState.stateRef(roomId);
    const userDocRef = db.collection("users").doc(uid);

    try {
      const outcome = await db.runTransaction(async (tx) => {
        // ── reads ────────────────────────────────────────────────────────────
        const stateSnap = await tx.get(stateDocRef);
        if (!stateSnap.exists) {
          return { refusal: { status: 404, reason: "nothing-to-restore" } };
        }
        const stored = streakEngine.normalizeState(stateSnap.data());
        const userSnap = await tx.get(userDocRef);

        // (a) the caller must be in the bond
        if (!stored.participants.includes(uid)) {
          return { refusal: { status: 403, reason: "not-participant" } };
        }

        // (b) a restorable break, judged by SERVER time
        const nowMs = Date.now();
        const brokenAtMs = _epochOrNull(stored.brokenAt);
        const previousCount = stored.previousCount;
        if (brokenAtMs === null || previousCount <= 0) {
          return { refusal: { status: 404, reason: "nothing-to-restore" } };
        }
        const deadlineMs = _epochOrNull(stored.restoreDeadlineAt);
        if (deadlineMs !== null && nowMs > deadlineMs) {
          return { refusal: { status: 410, reason: "window-expired" } };
        }

        // (c) the tiered cost
        const cost = streakEngine.restoreCost(previousCount);

        // (d) the Pro weekly perk — server-verified, never the client's word
        const userData = userSnap.exists ? userSnap.data() : null;
        if (userData === null) {
          return { refusal: { status: 404, reason: "user-not-found" } };
        }
        const weekKey = isoWeekKeyInCanonicalZone(nowMs);
        const perkAvailable =
          isProUser(userData, nowMs) && hasFreeRestoreAllowance(userData, weekKey);
        const usedFreePerk = wantsFreePerk && perkAvailable;

        // (d2) a rewarded-ad credit, granted only by `admobSsv` after Google's
        // signed callback verified. The Pro perk is spent FIRST when both are
        // available: the perk expires at the end of the ISO week regardless,
        // while a credit keeps — so spending the credit first would quietly burn
        // the thing the user sat through an ad for.
        const adCredits = Number(userData.adRestoreCredits) || 0;
        const usedAdCredit = wantsFreePerk && !perkAvailable && adCredits > 0;
        const isFree = usedFreePerk || usedAdCredit;

        // (e) otherwise the points must actually be there
        const points = Number(userData.gupPoints) || 0;
        if (!isFree && points < cost) {
          return {
            refusal: {
              status: 402,
              reason: "insufficient-points",
              detail: { required: cost, available: points },
            },
          };
        }

        // ── writes ───────────────────────────────────────────────────────────
        const serverNow = new Date(nowMs);
        const today = streakDay.dayKeyFromInstant(serverNow, stored.dayZoneOffsetMinutes);
        const deadlineAt = streakDay.dayStartUtc(
          streakDay.plusDays(today, 2),
          stored.dayZoneOffsetMinutes
        );

        const next = Object.assign({}, stored, {
          count: previousCount,
          previousCount: 0,
          brokenAt: null,
          restoreDeadlineAt: null,
          // `lastMutualDay` is DELIBERATELY untouched (defect 1.18).
          bridgedThroughDay: today,
          deadlineAt,
          riskLevel: streakEngine.riskLevelFor({
            deadlineAt,
            serverNow,
            hasBrokenStamp: false,
          }),
          longestForRoom: Math.max(stored.longestForRoom || 0, previousCount),
          restoredAt: serverNow,
          restoredBy: uid,
          restoreCostPaid: isFree ? 0 : cost,
        });

        tx.set(
          stateDocRef,
          streakState.toWire(next, {
            rev: stored.rev + 1,
            serverNow,
            reason: streakState.EvaluationReason.restore,
            recentApplied: streakState.pruneRecentApplied(stored.recentApplied, serverNow),
          })
        );

        const userUpdates = {};
        if (usedFreePerk) {
          const sameWeek =
            userData.streakRestoreAllowance &&
            userData.streakRestoreAllowance.weekKey === weekKey;
          const usedBefore = sameWeek
            ? Number(userData.streakRestoreAllowance.used) || 0
            : 0;
          userUpdates.streakRestoreAllowance = {
            weekKey,
            used: usedBefore + 1,
            lastUsedAt: serverNow,
          };
        } else if (usedAdCredit) {
          // Decremented inside the same transaction that consumed it, so two
          // concurrent restores can never spend one credit twice.
          userUpdates.adRestoreCredits = admin.firestore.FieldValue.increment(-1);
        } else {
          userUpdates.gupPoints = admin.firestore.FieldValue.increment(-cost);
        }
        tx.update(userDocRef, userUpdates);

        return {
          ok: true,
          restoredCount: previousCount,
          costPaid: isFree ? 0 : cost,
          usedFreePerk,
          usedAdCredit,
          weekKey,
          serverNow: nowMs,
          state: next,
        };
      });

      if (outcome.refusal) {
        const { status, reason, detail } = outcome.refusal;
        res
          .status(status)
          .json(Object.assign({ ok: false, error: reason, reason }, detail || {}));
        return;
      }

      // ── post-commit side effects — never fail the restore over them ───────
      try {
        await streakAwards.awardCrossedUpToSafely(
          roomId,
          outcome.state,
          outcome.restoredCount,
          { serverNow: new Date(outcome.serverNow) }
        );
      } catch (awardError) {
        console.error(
          `streakRestore: award pass failed for ${roomId}:`,
          awardError && awardError.message
        );
      }
      try {
        await streakNotify.notifyStreakRestored(roomId, outcome.state, uid, {
          serverNow: new Date(outcome.serverNow),
        });
      } catch (notifyError) {
        console.error(
          `streakRestore: notification failed for ${roomId}:`,
          notifyError && notifyError.message
        );
      }

      console.log(
        `streakRestore: ${roomId} restored to ${outcome.restoredCount} by ${uid} ` +
        `cost=${outcome.costPaid} freePerk=${outcome.usedFreePerk} ` +
        `adCredit=${outcome.usedAdCredit}`
      );

      res.status(200).json({
        ok: true,
        restoredCount: outcome.restoredCount,
        count: outcome.restoredCount,
        costPaid: outcome.costPaid,
        cost: outcome.costPaid,
        usedFreePerk: outcome.usedFreePerk,
        usedAdCredit: outcome.usedAdCredit,
        serverNow: outcome.serverNow,
      });
    } catch (error) {
      console.error("streakRestore error:", error && error.stack ? error.stack : error);
      res.status(500).json({
        ok: false,
        error: "Server error restoring streak",
        detail: error.message,
      });
    }
  }
);

// ═══════════════════════════════════════════════════════════════════════════════
// REWARDED-AD SERVER-SIDE VERIFICATION (SSV)
// ═══════════════════════════════════════════════════════════════════════════════
//
// This function is the ONLY thing in the system that pays out a rewarded ad. The
// client (`lib/services/ads/rewarded_ad_service.dart`) does not credit anything,
// cannot credit anything, and is not trusted even when it swears the ad was
// watched — Google calls us directly, over a signed URL, and this is the only
// party that writes `gupPoints` or `adRestoreCredits` for an ad.
//
// Three properties make that stick:
//
//   1. AUTHENTICITY — every callback is signed by Google with ECDSA-SHA256 over
//      the raw query string. An unsigned or altered URL is refused before any
//      read happens, so a hand-crafted request buys nothing.
//   2. IDEMPOTENCE — Google retries callbacks it can't confirm we received, and
//      an attacker who captures a real URL will simply replay it. `transaction_id`
//      is recorded in the same transaction that credits, so the second delivery
//      of the same reward is a no-op instead of a double payout.
//   3. CAPS — the daily/weekly limits are enforced HERE. `ads_reward_points` and
//      `ads_rewarded_daily_cap` in Remote Config only tell the UI what to
//      *promise*; a rooted device rewriting them changes the copy, not the payout.
//
// Configure this in AdMob → the rewarded ad unit → Server-side verification, as
//   https://<region>-<project>.cloudfunctions.net/admobSsv
// The unit is shared by both reward types, so the type travels in `custom_data`.
//
// Two deliberate non-features:
//
//   * No `timestamp` freshness check. Google's docs have described that field in
//     both milliseconds and microseconds, and a unit mistake here fails CLOSED —
//     it would silently refuse every legitimate reward. The `transaction_id`
//     ledger already makes a captured URL worthless after its first delivery,
//     which is the property a freshness window was going to buy.
//   * No TTL on the `adRewards` ledger. It grows, but each row is tiny and a row
//     is the only thing standing between a saved callback URL and a second
//     payout. If it ever needs pruning, the TTL has to be long enough that no
//     replay could outlive it — months, not days.

// ─── Verifier keys ────────────────────────────────────────────────────────────
// Google publishes its public keys and rotates them. Fetching per callback would
// add a round-trip to every reward, so they're cached per instance.
//
// The signature work lives in `ads/ssv.js` and is unit-tested against a locally
// generated keypair (`test/admob_ssv.unit.test.js`), because it is the piece of
// this feature that can be wrong without anyone noticing: get the byte slicing
// off by one and every legitimate reward is refused, which looks identical to
// "nobody watched an ad".
const admobKeys = new adsSsv.VerifierKeyCache();

// ─── GET /admobSsv ────────────────────────────────────────────────────────────
// Status codes are deliberate, because they decide whether Google retries:
//   400 — the callback isn't genuine (bad/absent signature). Never credits.
//   500 — WE failed (key fetch, Firestore). Google retries; the reward survives.
//   200 — handled. Includes the cases that can never succeed on a retry (already
//         processed, cap reached, unknown reward type), because retrying those
//         forever would just fill the logs.
exports.admobSsv = onRequest(
  { invoker: "public", minInstances: 0 },
  async (req, res) => {
    res.set("Cache-Control", "no-store");

    if (req.method !== "GET") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const q = req.query || {};
    const signature = typeof q.signature === "string" ? q.signature : null;
    const keyId = q.key_id == null ? null : String(q.key_id);
    const transactionId =
      typeof q.transaction_id === "string" && q.transaction_id.length > 0
        ? q.transaction_id
        : null;

    const signedContent = adsSsv.signedContentFrom(req.originalUrl);
    if (!signature || !keyId || !transactionId || signedContent === null) {
      console.warn("admobSsv: malformed callback");
      res.status(400).json({ ok: false, error: "malformed-callback" });
      return;
    }

    // ── 1. authenticity, before anything is read or written ───────────────────
    let verified = false;
    try {
      verified = await admobKeys.verify(signedContent, signature, keyId);
    } catch (error) {
      console.error("admobSsv: verifier unavailable:", error && error.message);
      res.status(500).json({ ok: false, error: "verification-unavailable" });
      return;
    }
    if (!verified) {
      console.warn(
        `admobSsv: REJECTED unverified callback txn=${transactionId} key_id=${keyId}`
      );
      res.status(400).json({ ok: false, error: "bad-signature" });
      return;
    }

    // Everything below is inside the signed blob, so it is Google's word — but
    // the *contents* were composed by our client, so shape is still checked.
    let custom = null;
    if (typeof q.custom_data === "string" && q.custom_data.length > 0) {
      try {
        custom = JSON.parse(q.custom_data);
      } catch (_) {
        custom = null;
      }
    }
    const customUid =
      custom && typeof custom.uid === "string" && custom.uid.length > 0
        ? custom.uid
        : null;
    const userIdParam =
      typeof q.user_id === "string" && q.user_id.length > 0 ? q.user_id : null;
    const type = custom && typeof custom.type === "string" ? custom.type : null;
    const roomId =
      custom && typeof custom.roomId === "string" ? custom.roomId : null;

    // The uid is sent twice — as `user_id` and inside `custom_data` — precisely
    // so a mismatch is detectable. Both are signed, so disagreement means our own
    // client built the request wrong, which is a bug worth shouting about.
    if (customUid && userIdParam && customUid !== userIdParam) {
      console.error(
        `admobSsv: uid mismatch custom=${customUid} user_id=${userIdParam} ` +
        `txn=${transactionId}`
      );
      res.status(200).json({ ok: true, credited: false, reason: "uid-mismatch" });
      return;
    }

    const uid = customUid || userIdParam;
    if (!uid || (type !== "points" && type !== "restore")) {
      console.error(
        `admobSsv: verified callback we can't route uid=${uid} type=${type} ` +
        `txn=${transactionId}`
      );
      res.status(200).json({ ok: true, credited: false, reason: "unroutable" });
      return;
    }

    // The transaction id becomes a document id. Google sends hex, but a `/` or a
    // lone `.` would make `doc()` throw — and a throw means 500, which means
    // Google retries a request that can never succeed. Same for the uid, which
    // our own client supplied. Checked here rather than with the early guards so
    // an unsigned probe isn't answered any differently.
    if (!/^[A-Za-z0-9_-]{1,200}$/.test(transactionId) ||
        !/^[A-Za-z0-9_-]{1,128}$/.test(uid)) {
      console.error(
        `admobSsv: unusable ids txn=${transactionId} uid=${uid}`
      );
      res.status(200).json({ ok: true, credited: false, reason: "bad-ids" });
      return;
    }

    const rewardRef = db.collection("adRewards").doc(transactionId);
    const userRef = db.collection("users").doc(uid);

    try {
      const outcome = await db.runTransaction(async (tx) => {
        // ── 2. replay guard, in the same transaction as the credit ────────────
        // Reading and writing the id atomically with the payout is the whole
        // point: a check-then-write outside the transaction would let two
        // concurrent retries both pass the check.
        const existing = await tx.get(rewardRef);
        if (existing.exists) {
          return { replay: true };
        }

        const userSnap = await tx.get(userRef);
        if (!userSnap.exists) {
          return { skipped: "user-not-found" };
        }
        const userData = userSnap.data();

        const serverNow = new Date();
        const nowMs = serverNow.getTime();

        // The audit trail. Written on every outcome, including refusals — a
        // reward that didn't pay is exactly the thing someone will dispute.
        const record = {
          uid,
          type,
          roomId: roomId || null,
          transactionId,
          keyId,
          adUnit: typeof q.ad_unit === "string" ? q.ad_unit : null,
          rewardItem: typeof q.reward_item === "string" ? q.reward_item : null,
          rewardAmount: Number(q.reward_amount) || 0,
          createdAt: serverNow,
        };

        // ── 3. credit, with the caps enforced here and nowhere else ───────────
        if (type === "points") {
          const dayKey = streakDay.dayKeyFromInstant(serverNow);
          const already = adRewardDailyCount(userData, dayKey);
          if (already >= ADS_REWARD_DAILY_CAP) {
            tx.set(rewardRef, { ...record, credited: false, reason: "daily-cap", dayKey });
            return { skipped: "daily-cap", dayKey };
          }

          tx.update(userRef, {
            gupPoints: admin.firestore.FieldValue.increment(ADS_REWARD_POINTS),
            adRewardDaily: { dayKey, count: already + 1, lastAt: serverNow },
          });
          tx.set(rewardRef, {
            ...record,
            credited: true,
            points: ADS_REWARD_POINTS,
            dayKey,
          });
          return {
            credited: true,
            points: ADS_REWARD_POINTS,
            remaining: ADS_REWARD_DAILY_CAP - already - 1,
          };
        }

        // type === "restore" — a credit, not a restore. The user still has to
        // spend it through `streakRestore`, which is where participation and the
        // restore window are checked; granting one here says nothing about
        // whether there is a broken streak to spend it on.
        const weekKey = isoWeekKeyInCanonicalZone(nowMs);
        const earned = adRestoreWeeklyCount(userData, weekKey);
        if (earned >= ADS_RESTORE_WEEKLY_CAP) {
          tx.set(rewardRef, { ...record, credited: false, reason: "weekly-cap", weekKey });
          return { skipped: "weekly-cap", weekKey };
        }

        tx.update(userRef, {
          adRestoreCredits: admin.firestore.FieldValue.increment(1),
          adRestoreWeekly: { weekKey, count: earned + 1, lastAt: serverNow },
        });
        tx.set(rewardRef, { ...record, credited: true, weekKey });
        return { credited: true, weekKey };
      });

      if (outcome.replay) {
        console.log(`admobSsv: duplicate txn=${transactionId} — no credit`);
        res.status(200).json({ ok: true, credited: false, reason: "duplicate" });
        return;
      }
      if (outcome.skipped) {
        console.log(
          `admobSsv: ${uid} ${type} not credited (${outcome.skipped}) txn=${transactionId}`
        );
        res.status(200).json({ ok: true, credited: false, reason: outcome.skipped });
        return;
      }

      console.log(
        `admobSsv: credited ${uid} ${type} txn=${transactionId}` +
        (type === "points"
          ? ` points=${outcome.points} remainingToday=${outcome.remaining}`
          : ` week=${outcome.weekKey} room=${roomId || "-"}`)
      );
      res.status(200).json({ ok: true, credited: true });
    } catch (error) {
      // Ours to fix, so ask Google to try again rather than eating the reward.
      console.error(
        "admobSsv error:",
        error && error.stack ? error.stack : error
      );
      res.status(500).json({ ok: false, error: "credit-failed" });
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
      // Write to pendingEmails collection — the processPendingEmails Firestore
      // trigger handles the actual SMTP send asynchronously, so auth isn't delayed.
      await db.collection("pendingEmails").add({
        type: "login_alert",
        email,
        name,
        device,
        loginTime,
        unsub,
        uid: user.uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

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

// ─── Firestore Trigger: Process Pending Emails ────────────────────────────────
// Picks up documents written to the pendingEmails collection and sends them
// via SMTP. This keeps auth-blocking functions (like loginAlertEmail) fast.
exports.processPendingEmails = onDocumentCreated(
  {
    document: "pendingEmails/{emailId}",
    region: "us-central1",
    secrets: emailService.secrets,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    if (!data || !data.email) return;

    try {
      let subject, html;

      switch (data.type) {
        case "login_alert": {
          const tpl = emailTemplates.loginAlertEmail(
            data.name,
            data.device,
            data.loginTime,
            data.unsub,
          );
          subject = tpl.subject;
          html = tpl.html;
          break;
        }
        default:
          console.warn(`processPendingEmails: unknown type "${data.type}", skipping`);
          return;
      }

      const sent = await emailService.sendEmail(data.email, subject, html);
      if (sent) {
        console.log(`processPendingEmails: ${data.type} email sent to ${data.email}`);
      }
    } catch (error) {
      console.error(`processPendingEmails error for ${data.email}:`, error.message);
    }
  },
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

    // Process users in sequential batches to avoid OOM / rate-limiting
    const BATCH_SIZE = 20;
    for (let i = 0; i < usersSnap.docs.length; i += BATCH_SIZE) {
      const batch = usersSnap.docs.slice(i, i + BATCH_SIZE);
      const results = await Promise.allSettled(
        batch.map(async (userDoc) => {
          const userData = userDoc.data();
          const email = userData.email;
          const name = userData.name || "there";

          if (!email) return false;
          if (userData.emailNotifications === false) return false;

          // Cooldown: once per 6 days
          const lastDigestEmail = userData.notifiedAt?.weekly_digest_email;
          if (lastDigestEmail) {
            const daysSince = (now - lastDigestEmail.toDate()) / 86400000;
            if (daysSince < 6) return false;
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

              // Count messages sent by this user in the last 7 days
              try {
                const msgCountSnap = await db
                  .collection("chatRooms")
                  .doc(roomDoc.id)
                  .collection("messages")
                  .where("senderId", "==", userId)
                  .where("timestamp", ">=", admin.firestore.Timestamp.fromDate(sevenDaysAgo))
                  .count()
                  .get();
                messagesSent += msgCountSnap.data().count || 0;
              } catch (_) { }
            }
          } catch (_) { }

          const gupPointsEarned = Math.max(0, (userData.gupPoints || 0) - (userData.lastWeekPoints || 0));

          const stats = {
            messagesSent,
            activeBonds,
            longestStreak,
            gupPointsEarned,
          };

          const unsub = emailService.buildUnsubscribeUrl(userId);
          const { subject, html } = emailTemplates.weeklyDigestEmail(name, stats, unsub);
          const sent = await emailService.sendEmail(email, subject, html);

          if (sent) {
            await userDoc.ref.update({
              "notifiedAt.weekly_digest_email": admin.firestore.FieldValue.serverTimestamp(),
              "lastWeekPoints": userData.gupPoints || 0,
            }).catch(() => { });
            return true;
          }
          return false;
        }),
      );
      sentCount += results.filter((r) => r.status === "fulfilled" && r.value).length;
    }

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

    // Process users in sequential batches to avoid OOM / rate-limiting
    const BATCH_SIZE = 20;
    for (let i = 0; i < usersSnap.docs.length; i += BATCH_SIZE) {
      const batch = usersSnap.docs.slice(i, i + BATCH_SIZE);
      const results = await Promise.allSettled(
        batch.map(async (userDoc) => {
          const userData = userDoc.data();
          const email = userData.email;
          const name = userData.name || "there";

          if (!email) return false;
          if (userData.emailNotifications === false) return false;

          // Cooldown: once per 7 days
          const lastInactivityEmail = userData.notifiedAt?.inactivity_email;
          if (lastInactivityEmail) {
            const daysSince = (now - lastInactivityEmail.toDate()) / 86400000;
            if (daysSince < 7) return false;
          }

          const lastSeen = userData.lastSeen?.toDate ? userData.lastSeen.toDate() : null;
          const daysSinceLastSeen = lastSeen
            ? Math.floor((now - lastSeen) / 86400000)
            : 3;

          const unsub = emailService.buildUnsubscribeUrl(userDoc.id);
          const { subject, html } = emailTemplates.inactivityReminderEmail(name, daysSinceLastSeen, unsub);
          const sent = await emailService.sendEmail(email, subject, html);

          if (sent) {
            await userDoc.ref.update({
              "notifiedAt.inactivity_email": admin.firestore.FieldValue.serverTimestamp(),
            }).catch(() => { });
            return true;
          }
          return false;
        }),
      );
      sentCount += results.filter((r) => r.status === "fulfilled" && r.value).length;
    }

    console.log(`inactivityReminderEmailJob: sent ${sentCount} inactivity emails.`);
  }
);

// ─── HTTP: Unsubscribe from Emails ────────────────────────────────────────────
// One-click unsubscribe endpoint. Sets emailNotifications = false on the user doc.
// Uses HMAC-signed tokens to prevent unauthorised unsubscribes.
exports.unsubscribeEmail = onRequest(
  { cors: true, invoker: "public", region: "us-central1", secrets: emailService.secrets },
  async (req, res) => {
    const uid = req.query.uid || (req.body && req.body.uid);
    const token = req.query.token || (req.body && req.body.token);

    if (!uid || typeof uid !== "string") {
      res.status(400).send(unsubscribePage("Invalid request", false));
      return;
    }

    // Verify HMAC token to prevent unauthorised unsubscribes
    if (!emailService.verifyUnsubscribeToken(uid, token)) {
      res.status(403).send(unsubscribePage("Invalid or expired link", false));
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

      const safeName = escHtml(userDoc.data().name || "there");
      res.status(200).send(unsubscribePage(safeName, true));
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

// ═══════════════════════════════════════════════════════════════════════════
// Agora RTC token generation
// ═══════════════════════════════════════════════════════════════════════════
// Mints a short-lived RTC token so the client never holds the App Certificate.
// The caller must present a valid Firebase ID token. The uid embedded in the
// Agora token is 0 (the client joins with uid: 0), matching the app's
// joinChannel call — Agora then assigns a real uid on join.
const { RtcTokenBuilder, RtcRole } = require("agora-token");

// Tokens are valid for 1 hour. Long enough for any single call; the client
// requests a fresh one per call so expiry is never hit mid-call.
const AGORA_TOKEN_TTL_SECONDS = 3600;

exports.generateAgoraToken = onRequest(
  { cors: true, invoker: "public", secrets: [agoraAppId, agoraAppCertificate] },
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

    const channelName = req.body && req.body.channelName;
    if (!channelName || typeof channelName !== "string") {
      res.status(400).json({ error: "Missing channelName" });
      return;
    }

    // ── Authorization: requester must be a participant of THIS call ──────────
    // Authentication alone is not enough — the channel name is caller-supplied,
    // so without this check any signed-in user who learns a channel id could
    // mint a publisher token and join a private call. The calls/{channelId}
    // document records the two legitimate participants (written by both the
    // call flow and the screen-share flow); require the caller to be one of them.
    const callSnap = await db.collection("calls").doc(channelName).get();
    if (!callSnap.exists) {
      res.status(404).json({ error: "Call not found" });
      return;
    }
    const call = callSnap.data();
    if (decoded.uid !== call.callerId && decoded.uid !== call.calleeId) {
      res.status(403).json({ error: "Not a participant of this call" });
      return;
    }
    // uid is optional; default 0 to match the client's joinChannel(uid: 0).
    const uid = Number.isInteger(req.body && req.body.uid) ? req.body.uid : 0;

    try {
      const appId = agoraAppId.value();
      const appCertificate = agoraAppCertificate.value();
      const now = Math.floor(Date.now() / 1000);
      const privilegeExpireTs = now + AGORA_TOKEN_TTL_SECONDS;

      const token = RtcTokenBuilder.buildTokenWithUid(
        appId,
        appCertificate,
        channelName,
        uid,
        RtcRole.PUBLISHER,
        privilegeExpireTs,
        privilegeExpireTs
      );

      res.status(200).json({
        token,
        appId,
        uid,
        expiresAt: privilegeExpireTs,
      });
    } catch (error) {
      console.error("generateAgoraToken error:", error);
      res.status(500).json({ error: error.message });
    }
  }
);

// ─── Firestore Trigger: Problem Report → Email to Support ─────────────────────
// When a user submits a problem report from the app settings, this trigger
// picks up the new document and sends a formatted email to the support inbox.
exports.processProblemReportEmail = onDocumentCreated(
  {
    document: "problem_reports/{reportId}",
    region: "us-central1",
    secrets: emailService.secrets,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    if (!data) return;

    const supportEmail = "vansh.sethi98760@gmail.com";

    // ── Per-user rate limit ──────────────────────────────────────────────
    // Every created report triggers a support email, so cap how many a single
    // user can dispatch per rolling window. This prevents a malicious client
    // from looping writes to flood (and run up the bill on) the support inbox.
    // The check fails OPEN on limiter errors, so a transient Firestore fault
    // never silently drops a legitimate bug report.
    const RATE_LIMIT_WINDOW_MS = 60 * 60 * 1000; // 1 hour
    const MAX_REPORTS_PER_WINDOW = 5;
    const userId = data.userId;

    if (userId) {
      const limitRef = admin
        .firestore()
        .collection("problem_report_limits")
        .doc(userId);
      let withinLimit = true;
      try {
        withinLimit = await admin.firestore().runTransaction(async (tx) => {
          const limitSnap = await tx.get(limitRef);
          const now = Date.now();
          const prev = limitSnap.exists ? limitSnap.data() : null;
          const windowStart = (prev && prev.windowStart) || 0;
          const count = (prev && prev.count) || 0;

          // Window elapsed (or first ever report) → start a fresh window.
          if (now - windowStart >= RATE_LIMIT_WINDOW_MS) {
            tx.set(limitRef, { windowStart: now, count: 1 });
            return true;
          }
          // Still inside the window and already at the cap → reject.
          if (count >= MAX_REPORTS_PER_WINDOW) {
            return false;
          }
          tx.set(limitRef, { count: count + 1 }, { merge: true });
          return true;
        });
      } catch (error) {
        console.error(
          `processProblemReportEmail: rate-limit check failed for ${userId} (failing open):`,
          error.message,
        );
        withinLimit = true;
      }

      if (!withinLimit) {
        console.warn(
          `processProblemReportEmail: rate limit exceeded for user ${userId}; skipping email for report ${snap.id}`,
        );
        await snap.ref.update({ emailSent: false, rateLimited: true });
        return;
      }
    }

    try {
      const createdAt = data.createdAt
        ? data.createdAt.toDate().toISOString()
        : null;

      const tpl = emailTemplates.problemReportEmail({
        userName: data.userName,
        userId: data.userId,
        userEmail: data.userEmail,
        subject: data.subject,
        body: data.body,
        platform: data.platform,
        createdAt,
      });

      const sent = await emailService.sendEmail(supportEmail, tpl.subject, tpl.html);

      // Mark the document so we know the email was dispatched
      await snap.ref.update({ emailSent: sent, emailSentAt: admin.firestore.FieldValue.serverTimestamp() });

      if (sent) {
        console.log(`processProblemReportEmail: report ${snap.id} emailed to ${supportEmail}`);
      } else {
        console.warn(`processProblemReportEmail: email dispatch failed for report ${snap.id}`);
      }
    } catch (error) {
      console.error(`processProblemReportEmail error for report ${snap.id}:`, error.message);
    }
  },
);

// ─── Presence: RTDB → Firestore mirror ───────────────────────────────────────
// The client owns RTDB `/presence/{uid}` and arms an onDisconnect() handler, so
// the RTDB node self-heals when a process dies. Firestore — which every screen
// actually reads — has no such mechanism: without this trigger a force-killed
// app leaves `users/{uid}.isOnline` stuck at `true` forever.
//
// The trigger watches ONLY the `online` child, not the whole node. The client
// heartbeats `lastSeen` (a sibling path) every 25s; watching the parent would
// invoke this function on every heartbeat instead of ~twice per session.
const PRESENCE_STALE_MS = 60000; // must match PresenceService.staleThreshold

exports.presenceMirror = onValueWritten(
  {
    ref: "/presence/{uid}/online",
    instance: "videocallapp-81166-default-rtdb",
    region: "us-central1",
    // Retries are off by default, which would make the `throw` below a no-op.
    // They matter for the exact case this whole fix targets: the app is
    // backgrounded, so `online` flips false while `lastSeen` is still fresh
    // from a heartbeat seconds earlier. If that one mirror write is dropped,
    // Firestore keeps `isOnline: true` with a *fresh* lastSeen — the reader's
    // freshness guard can't catch that, and the user shows online for a full
    // minute. A retry is what closes it.
    //
    // Retrying can't report a lie: `online` comes from the (possibly stale)
    // event, but `lastSeen` is re-read live on every attempt. So a late retry
    // that re-asserts `true` for a session that has since died carries that
    // session's real, stale lastSeen, and the reader suppresses it anyway.
    retry: true,
  },
  async (event) => {
    const { uid } = event.params;
    const before = event.data.before.val();
    const after = event.data.after.val();

    // Heartbeats never touch `online`, but a no-op write still reaches here.
    if (before === after) return;

    const isOnline = after === true;

    // Take lastSeen from the RTDB sibling rather than stamping serverTimestamp():
    // an onDisconnect fires up to a minute after the user's real last activity,
    // so stamping "now" would report "last seen just now" for someone who
    // vanished a minute ago.
    let lastSeen;
    try {
      const snap = await event.data.after.ref.parent.child("lastSeen").once("value");
      const ms = snap.val();
      if (typeof ms === "number" && Number.isFinite(ms) && ms > 0) {
        lastSeen = admin.firestore.Timestamp.fromMillis(ms);
      }
    } catch (error) {
      console.warn(`presenceMirror: could not read lastSeen for ${uid}:`, error.message);
    }
    if (!lastSeen) lastSeen = admin.firestore.FieldValue.serverTimestamp();

    try {
      // update() rather than set({merge:true}) on purpose: a lingering RTDB node
      // for a deleted account must not resurrect a stub users/{uid} document,
      // which would then surface in discovery queries.
      await db.collection("users").doc(uid).update({ isOnline, lastSeen });
    } catch (error) {
      if (error.code === 5 || error.code === "not-found") {
        console.log(`presenceMirror: no user doc for ${uid}, skipping.`);
        return;
      }
      console.error(`presenceMirror error for ${uid}:`, error.message);
      throw error; // let the platform retry — a dropped mirror is a stuck "online"
    }

    console.log(`presenceMirror: ${uid} → ${isOnline ? "online" : "offline"}`);
  },
);

// ─── Scheduled: Presence sweeper (every 5 minutes) ───────────────────────────
// onDisconnect() is not a hard guarantee — observed in production at roughly a
// 4% miss rate, with individual records stuck `online: true` for weeks. This job
// is the janitor that makes presence self-healing regardless.
//
// Two independent passes, because the two stores fail in different ways:
//   1. Firestore — catches docs the mirror never corrected (the historical bug,
//      including any that predate presenceMirror being deployed).
//   2. RTDB — catches nodes whose onDisconnect never fired, cleaning the source
//      of truth. Flipping `online` there also re-triggers presenceMirror.
//
// The cutoff is deliberately looser than PRESENCE_STALE_MS: readers already
// enforce 60s freshness client-side, so this only needs to catch long-lived
// ghosts, and a wider window can't race a live user's delayed heartbeat.
const PRESENCE_SWEEP_STALE_MS = 3 * PRESENCE_STALE_MS;

exports.presenceSweeper = onSchedule(
  { schedule: "every 5 minutes", region: "us-central1" },
  async () => {
    const cutoffMs = Date.now() - PRESENCE_SWEEP_STALE_MS;
    let firestoreFixed = 0;
    let rtdbFixed = 0;

    // ── Pass 1: Firestore ────────────────────────────────────────────────
    // Single-field query (auto-indexed) with the staleness filter applied in
    // memory — avoids adding a composite index for isOnline + lastSeen.
    try {
      const onlineSnap = await db
        .collection("users")
        .where("isOnline", "==", true)
        .get();

      const stale = [];
      for (const doc of onlineSnap.docs) {
        const lastSeen = doc.data().lastSeen;
        const lastSeenMs = lastSeen?.toMillis ? lastSeen.toMillis() : null;
        // A missing lastSeen can never be evidence of a live connection.
        if (lastSeenMs !== null && lastSeenMs >= cutoffMs) continue;
        stale.push(doc.ref);
      }

      // Chunked at Firestore's hard 500-writes-per-batch limit. Not a
      // theoretical concern: this job's whole purpose is to be the layer that
      // still works, and a single oversized commit would throw and repair
      // nothing — silently, right as the userbase grew past the limit.
      const BATCH_LIMIT = 500;
      for (let i = 0; i < stale.length; i += BATCH_LIMIT) {
        const batch = db.batch();
        for (const ref of stale.slice(i, i + BATCH_LIMIT)) {
          // Preserve lastSeen — the user really was last seen then, and the UI
          // renders it as "last seen X ago".
          batch.update(ref, { isOnline: false });
        }
        await batch.commit();
        firestoreFixed += Math.min(BATCH_LIMIT, stale.length - i);
      }
    } catch (error) {
      console.error("presenceSweeper: Firestore pass failed:", error.message);
    }

    // ── Pass 2: RTDB ─────────────────────────────────────────────────────
    try {
      const ghostSnap = await admin
        .database()
        .ref("presence")
        .orderByChild("online")
        .equalTo(true)
        .once("value");

      const writes = [];
      ghostSnap.forEach((child) => {
        const lastSeenMs = child.val()?.lastSeen;
        const isStale =
          typeof lastSeenMs !== "number" || lastSeenMs < cutoffMs;
        if (!isStale) return;
        // update() not set(): keeps the original lastSeen intact.
        writes.push(child.ref.update({ online: false }));
        rtdbFixed++;
      });
      await Promise.all(writes);
    } catch (error) {
      console.error("presenceSweeper: RTDB pass failed:", error.message);
    }

    console.log(
      `presenceSweeper: cleared ${firestoreFixed} Firestore + ${rtdbFixed} RTDB ghost records.`
    );
  },
);


