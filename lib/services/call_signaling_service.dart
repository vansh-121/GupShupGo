import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_chat_app/services/call_acceptance.dart';
import 'package:video_chat_app/services/crashlytics_service.dart';

/// Possible statuses for a call signaling document.
///
/// State machine:
///   ringing → answered → ended     (normal call flow)
///   ringing → declined              (callee presses decline)
///   ringing → missed                (timeout — no answer)
///   ringing → ended                 (caller cancels before callee answers)
enum CallSignalStatus {
  ringing,
  answered,
  declined,
  ended,
  missed,
}

/// Manages the Firestore `calls/{channelId}` document that acts as the
/// shared signaling state between caller and callee.
///
/// Both [CallScreen] and [IncomingCallScreen] listen to the document via
/// [listenToCallStatus] so that when one party changes the status (decline,
/// end, timeout), the other party's screen reacts immediately.
class CallSignalingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'calls';

  static String generateChannelId() {
    // CallKit requires the incoming call id to be a real UUID. The previous
    // `call_<Firestore auto id>` value worked as an Agora channel on Android,
    // but iOS force-parses it with UUID(uuidString:) and cannot present the
    // call. A UUID is valid for Agora and Firestore as well, so use one id for
    // signaling, RTC, and the native call UI on every platform.
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // UUID v4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant
    final hex =
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  // ─── Create ────────────────────────────────────────────────────────────────

  /// Creates (or overwrites) the call document. Called by the **caller** right
  /// before sending the FCM push and navigating to CallScreen.
  static Future<void> createCallDocument({
    required String channelId,
    required String callerId,
    required String calleeId,
  }) async {
    await _firestore.collection(_collection).doc(channelId).set({
      'callerId': callerId,
      'calleeId': calleeId,
      'status': CallSignalStatus.ringing.name,
      'createdAt': FieldValue.serverTimestamp(),
      'answeredAt': null,
      'endedAt': null,
    });
  }

  // ─── Status transitions ────────────────────────────────────────────────────

  /// Callee accepted the call. Returns true when the `answered` transition was
  /// written, false when it failed (the error is logged). Callers that must not
  /// proceed until the peer is actually notified — e.g. the screen-share
  /// viewer, which otherwise opens on a black screen while the sharer, never
  /// told we accepted, never starts capture — should gate on the result;
  /// call-style callers may ignore it.
  static Future<bool> answerCall(String channelId, {String? deviceId}) async {
    try {
      return await _answerCall(channelId, deviceId: deviceId) ==
          CallAnswerOutcome.accepted;
    } catch (e, stack) {
      print('CallSignaling: error answering call: $e');
      CrashlyticsService.logError(e, stack,
          reason: 'CallSignaling.answerCall failed');
      if (deviceId != null) rethrow;
      return false;
    }
  }

  /// Native registration runs in WorkManager and may still be pending when an
  /// older account-level FCM token delivers a call. Publish the device identity
  /// before claiming it; never retry a rejected claim without its device ID.
  /// This merge preserves FCM tokens and any existing encryption keys.
  static Future<CallAnswerOutcome> answerCallOnDevice(
    String channelId, {
    required String userId,
    required String deviceId,
    required void Function(String) onEvent,
  }) async {
    if (FirebaseAuth.instance.currentUser?.uid != userId) {
      return CallAnswerOutcome.signedOut;
    }
    if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(deviceId)) {
      throw const CallAcceptanceException('device_identity_missing');
    }
    var stage = 'device_registration';
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(deviceId)
          .set({
        'deviceId': deviceId,
        'platform': 'android',
        'lastSeenAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 10));
      onEvent('accept_device_confirmed');
      if (FirebaseAuth.instance.currentUser?.uid != userId) {
        return CallAnswerOutcome.signedOut;
      }
      stage = 'transaction';
      return await _answerCall(channelId,
          deviceId: deviceId, expectedUserId: userId);
    } on FirebaseException catch (error, stack) {
      unawaited(CrashlyticsService.logError(error, stack,
              reason: 'Call Accept $stage: ${error.code}')
          .catchError((_) {}));
      throw CallAcceptanceException('${stage}_${error.code}',
          retryable: const {'unavailable', 'deadline-exceeded', 'aborted'}
              .contains(error.code));
    } on TimeoutException {
      throw CallAcceptanceException('${stage}_timeout', retryable: true);
    }
  }

  static Future<CallAnswerOutcome> _answerCall(String channelId,
      {String? deviceId, String? expectedUserId}) async {
    final uid = expectedUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return CallAnswerOutcome.signedOut;
    return _firestore.runTransaction((tx) async {
      final ref = _firestore.collection(_collection).doc(channelId);
      final snapshot = await tx.get(ref);
      final call = snapshot.data();
      if (FirebaseAuth.instance.currentUser?.uid != uid) {
        return CallAnswerOutcome.signedOut;
      }
      if (call == null) return CallAnswerOutcome.missing;
      if (call['calleeId'] != uid) return CallAnswerOutcome.wrongAccount;
      if (call['status'] == 'answered') {
        return deviceId != null && call['acceptedDeviceId'] == deviceId
            ? CallAnswerOutcome.accepted
            : CallAnswerOutcome.answeredElsewhere;
      }
      if (call['status'] != 'ringing') return CallAnswerOutcome.ended;
      final expires = call['expiresAt'] as Timestamp?;
      if (expires != null && !expires.toDate().isAfter(DateTime.now())) {
        return CallAnswerOutcome.expired;
      }
      tx.update(ref, {
        'status': CallSignalStatus.answered.name,
        'answeredAt': FieldValue.serverTimestamp(),
        if (deviceId != null) 'acceptedDeviceId': deviceId,
      });
      return CallAnswerOutcome.accepted;
    }, timeout: const Duration(seconds: 15), maxAttempts: 3);
  }

  /// A dismissed Accept must not hang up a call won by another device (including
  /// a legacy client with no device claim). Re-read ownership in the transaction
  /// instead of trusting whether this route once saw `answered`.
  static Future<void> finishCallOnDevice(String channelId,
      {required String userId, required String deviceId}) async {
    if (FirebaseAuth.instance.currentUser?.uid != userId) return;
    final ref = _firestore.collection(_collection).doc(channelId);
    await _firestore.runTransaction((tx) async {
      final call = (await tx.get(ref)).data();
      if (FirebaseAuth.instance.currentUser?.uid != userId ||
          call == null ||
          call['calleeId'] != userId) return;
      final status = call['status'];
      if (status != 'ringing' &&
          !(status == 'answered' && call['acceptedDeviceId'] == deviceId)) {
        return;
      }
      tx.update(ref, {
        'status': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
      });
    }, timeout: const Duration(seconds: 15), maxAttempts: 3);
  }

  /// Callee declined the call.
  static Future<void> declineCall(String channelId) async {
    try {
      await _finishIfActive(channelId, CallSignalStatus.declined);
    } catch (e, stack) {
      print('CallSignaling: error declining call: $e');
      CrashlyticsService.logError(e, stack,
          reason: 'CallSignaling.declineCall failed');
    }
  }

  /// Either party ended the call (mid-conversation or caller cancelled while
  /// ringing).
  static Future<void> endCall(String channelId) async {
    try {
      await _finishIfActive(channelId, CallSignalStatus.ended);
    } catch (e, stack) {
      print('CallSignaling: error ending call: $e');
      CrashlyticsService.logError(e, stack,
          reason: 'CallSignaling.endCall failed');
    }
  }

  /// No one answered before the timeout.
  static Future<void> missCall(String channelId) async {
    try {
      await _finishIfActive(channelId, CallSignalStatus.missed);
    } catch (e, stack) {
      print('CallSignaling: error marking call as missed: $e');
      CrashlyticsService.logError(e, stack,
          reason: 'CallSignaling.missCall failed');
    }
  }

  // ─── Real-time listener ────────────────────────────────────────────────────

  /// Returns a stream of [CallSignalStatus] changes for the given channel.
  /// Both caller and callee screens subscribe to this stream and react when
  /// the status changes (e.g. auto-close on `declined`, `ended`, `missed`).
  static Stream<CallSignalStatus?> listenToCallStatus(String channelId) {
    return _firestore
        .collection(_collection)
        .doc(channelId)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      final statusStr = data['status'] as String?;
      if (statusStr == null) return null;
      return CallSignalStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => CallSignalStatus.ringing,
      );
    });
  }

  static Future<void> _finishIfActive(
      String id, CallSignalStatus status) async {
    final ref = _firestore.collection(_collection).doc(id);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = snap.data()?['status'];
      if (current != 'ringing' &&
          !(current == 'answered' && status == CallSignalStatus.ended)) return;
      tx.update(ref,
          {'status': status.name, 'endedAt': FieldValue.serverTimestamp()});
    });
  }

  // ─── E2EE negotiation ──────────────────────────────────────────────────

  /// Write the negotiated E2EE status to the call document.
  ///
  /// The **caller** writes `e2ee: true` after successfully publishing the
  /// key envelope, or `e2ee: false` if encryption setup failed. The callee
  /// reads this field before polling for the key envelope — if `false`, it
  /// skips the poll entirely and joins unencrypted.
  ///
  /// Either peer can also flip it to `false` mid-call to trigger the
  /// black-screen recovery path (see `_handleEncryptionMismatchRecovery`
  /// in CallScreen).
  static Future<void> setE2eeStatus(String channelId, bool enabled) async {
    try {
      await _firestore.collection(_collection).doc(channelId).update({
        'e2ee': enabled,
      });
    } catch (e, stack) {
      print('CallSignaling: error setting e2ee status: $e');
      CrashlyticsService.logError(e, stack,
          reason: 'CallSignaling.setE2eeStatus failed');
    }
  }

  /// One-shot read of the `e2ee` field on the call document.
  ///
  /// Returns `null` if the document doesn't exist yet or the field hasn't
  /// been written (caller hasn't finished key exchange yet).
  static Future<bool?> getE2eeStatus(String channelId) async {
    try {
      final snap =
          await _firestore.collection(_collection).doc(channelId).get();
      if (!snap.exists) return null;
      return snap.data()?['e2ee'] as bool?;
    } catch (e) {
      print('CallSignaling: error reading e2ee status: $e');
      return null;
    }
  }

  // ─── Cleanup ───────────────────────────────────────────────────────────────

  /// Deletes a call document. Called after both parties have left the call
  /// and the call log has been created. Fire-and-forget.
  static Future<void> deleteCallDocument(String channelId) async {
    // Retain terminal state so delayed Accept/push delivery cannot revive a call.
    // The backend retention job removes these documents after seven days.
    await endCall(channelId);
  }
}
