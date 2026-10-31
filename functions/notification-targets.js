"use strict";

function supportsNativeCalls(target) {
  return target.platform === "android" &&
    Number.isInteger(target.nativeCallsVersion) && target.nativeCallsVersion >= 1;
}

function nativeCallTargets(targets) {
  return targets.filter((target) => target.token && supportsNativeCalls(target));
}

function tokenOrNull(value) {
  return typeof value === "string" && value ? value : null;
}

/** Read both published token formats; missing capabilities always mean legacy. */
function collectNotificationTargets(userRef, userData, devices) {
  const targets = [];
  const byToken = new Map();

  for (const doc of devices) {
    const data = doc.data() || {};
    const target = {
      token: tokenOrNull(data.fcmToken),
      voipToken: tokenOrNull(data.voipToken),
      voipEnvironment: data.voipEnvironment || null,
      platform: data.platform || null,
      nativeCallsVersion: data.nativeCallsVersion || 0,
      ref: doc.ref,
      source: "device",
    };

    if (target.token) {
      const previous = byToken.get(target.token);
      if (!previous) {
        byToken.set(target.token, target);
      } else if (supportsNativeCalls(target) && !supportsNativeCalls(previous)) {
        // An upgraded install can have both old and new device records for the
        // same FCM token. Keep its current capabilities regardless of query order.
        previous.token = null;
        byToken.set(target.token, target);
      } else {
        target.token = null;
      }
    }
    if (target.token || target.voipToken) targets.push(target);
  }

  const legacyToken = tokenOrNull(userData.fcmToken);
  if (legacyToken && !byToken.has(legacyToken)) {
    targets.push({
      token: legacyToken,
      voipToken: null,
      voipEnvironment: null,
      platform: null,
      nativeCallsVersion: 0,
      ref: userRef,
      source: "legacy",
    });
  }

  return targets.filter((target) => target.token || target.voipToken);
}

module.exports = { collectNotificationTargets, nativeCallTargets };
