"use strict";

const INVALID_FCM_TOKEN_CODES = new Set([
  "messaging/invalid-registration-token",
  "messaging/registration-token-not-registered",
]);

function isInvalidFcmTokenError(error) {
  if (!error) return false;
  if (INVALID_FCM_TOKEN_CODES.has(error.code)) return true;
  return String(error.message || "").includes("Requested entity was not found");
}

function shouldRetryDelivery(result) {
  return (!result.ok && result.status >= 500) || result.body.transientFailureCount > 0;
}

function createFcmSender({ messaging, removeNotificationTarget, logger = console }) {
  return async function sendFcmTargets(targets, buildMessage) {
    const messages = targets.map((target) => buildMessage(target.token));
    const batches = [];
    for (let offset = 0; offset < messages.length; offset += 500) {
      batches.push(await messaging.sendEach(messages.slice(offset, offset + 500)));
    }
    const responses = batches.flatMap((batch) => batch.responses);
    const cleanup = [];
    let successCount = 0;
    let transientFailureCount = 0;
    const failures = [];

    responses.forEach((result, index) => {
      if (result.success) {
        successCount += 1;
        if (messages[index].data?.type === "incoming_call" || messages[index].data?.type === "call_cancelled") {
          logger.log("Call FCM accepted", { channelId: messages[index].data.channelId,
            type: messages[index].data.type, deviceId: targets[index].ref.id, messageId: result.messageId });
        }
        return;
      }

      const error = result.error;
      failures.push({ tokenSource: targets[index].source, code: error && error.code });
      // Classify the original error before dropping its potentially sensitive message.
      // Invalid tokens must not hide temporary failures on other devices.
      if (isInvalidFcmTokenError(error)) {
        cleanup.push(removeNotificationTarget(targets[index]));
      } else {
        transientFailureCount += 1;
      }
    });

    await Promise.all(cleanup);
    const counts = {
      successCount,
      failureCount: failures.length,
      cleanedTokenCount: cleanup.length,
      transientFailureCount,
    };
    if (successCount > 0) {
      return { ok: true, status: 200, body: { success: true, ...counts } };
    }

    const allInvalid = cleanup.length > 0 && transientFailureCount === 0;
    return {
      ok: false,
      status: allInvalid ? 410 : 500,
      body: {
        error: allInvalid
          ? "All known FCM tokens were invalid and have been removed"
          : "Failed to send notification to any registered device",
        ...counts,
        failures,
      },
    };
  };
}

module.exports = { createFcmSender, shouldRetryDelivery };
