# Call backend compatibility

The backend can be deployed before the next APK. Installed 1.2.2 (build 60)
clients and clients using the earlier `call_<Firestore id>` signaling format
continue to use the same endpoints. Compatibility follows each install's
reported capabilities, not its app version number.

## Contract kept for released clients

- `sendCallNotification` keeps its URL, authenticated POST request, and HTTP 200
  success response. Required body fields remain `callerId`, `calleeId`, and
  `channelId`; `isAudioOnly` remains optional and accepts a boolean or the legacy
  string form. No app version or native capability field is required in a call
  request.
- Call IDs are passed through unchanged. Both `call_<Firestore id>` and UUID
  channels work with the existing Firestore and Agora paths.
- The caller creates a `ringing` call document before requesting notification
  delivery, as build 60 and the preceding released signaling clients already
  do. Missing, ended, expired, or mismatched calls are not recreated by a push
  request.
- Incoming pushes keep `type: "incoming_call"`, `channelId`, `callerId`,
  `calleeId`, `callerName`, `callerPhotoUrl`, and the string `isAudioOnly` flag.
  `expiresAt` is additive; old receivers can ignore it.
- Both `users/{uid}.fcmToken` and `users/{uid}/devices/{deviceId}.fcmToken` remain
  readable by the notification sender. Old registrations do not need migration
  or a foreground launch to become targets. Tokens are deduplicated across both
  locations. If old and new device IDs contain the same token, the record with
  native capabilities wins, independent of Firestore query order.
- Silent call cancellation is sent only to Android registrations explicitly
  advertising an integer `nativeCallsVersion >= 1`. Missing or malformed
  capabilities use legacy behavior. Regular incoming calls still go to them.
- A callee can answer without `acceptedDeviceId`, including an explicit null
  value. A non-null device claim must identify a registered device owned by that
  callee and cannot be changed after acceptance.
- Old `dispose` handlers may write `ended` after `declined` or `missed`, changing
  only `status` and `endedAt`. Participant deletion remains supported, and a
  legacy deletion still triggers cancellation for native receivers.

Authentication, participant ownership, server deadlines, and the prohibition
on restarting terminal call documents remain in force. This contract does not
restore pre-signaling clients that never create a call document or change
navigation code in an already-installed APK. The notification Accept-screen
fix must ship in an app update.

## Verification and rollout

The compatibility tests cover old-to-old, old-to-native, native-to-old, and
native-to-native delivery; legacy account tokens; duplicate registrations;
legacy Firestore accept/end/delete operations; and the corresponding ownership
and expiry restrictions.

From `functions`, run the unit and Firestore emulator suites:

```sh
npm test
```

After those checks pass, deploy from the repository root:

```sh
firebase deploy --only "firestore:rules,functions"
```

Then verify a call in both directions between an installed build 60 client and
the updated APK. Existing clients continue using the published contract while
new clients pick up the native handoff fix.

## Android acceptance and foreground UI

The updated APK uses one shared install-ID lookup for simultaneous auth, Home
and resume registration. Native Accept captures that device ID in the call's
durable inbox. Rebinding a different device ID for the same account preserves
the inbox; signing out or switching accounts still clears it.

An `answered` cancellation push stops devices that are still ringing. If this
device has already accepted, the Firestore transaction decides whether it won
the call. A delayed or legacy push cannot erase acceptance before that decision
returns. Caller hangup, decline, timeout and account mismatch still stop it.

The open Android app mirrors native ringing through the native state bridge,
using `IncomingCallScreen` alongside the notification. Both Accept buttons open
the existing `CallScreen`, which displays Connecting while confirming the answer.
Media starts only after this device's claim is confirmed. Closing during that
confirmation cannot start media later or hang up a call won by another device.

Acceptance confirms the device document before claiming it. This preserves
strict device ownership rules without depending on WorkManager's token job
finishing first. Existing tokens and encryption keys are merged, not replaced.

For a failed call, use **Settings → Incoming call readiness → Copy call
diagnostics** in the updated APK. Expected events include `accept_tapped`,
`accept_device_confirmed`, `answer_accepted`, `flutter_handoff`,
`accept_ready_for_media`, `rtc_local_joined`, and `rtc_peer_joined`. Errors carry
their stage, such as `answer_transaction_permission-denied`. A successful token
HTTP response proves token issuance, not that either peer joined the RTC channel.

Run the focused Flutter regressions:

```sh
flutter test test/services/call_acceptance_test.dart test/services/call_device_identity_test.dart test/services/native_call_service_test.dart test/services/call_signaling_service_test.dart
```

Before release, verify voice and video in both directions on two physical
phones: app open, backgrounded, locked, and process terminated. Check Accept
from both the notification and the in-app screen, cancellation during Connect,
and simultaneous Accept on two devices signed into the callee account. Repeat
with build 60 on one side. Unit and navigation tests do not replace these media
and OS-delivery checks.
