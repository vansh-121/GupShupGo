import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    return 'call_${_firestore.collection(_collection).doc().id}';
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

  /// Callee accepted the call.
  static Future<void> answerCall(String channelId) async {
    try {
      await _firestore.collection(_collection).doc(channelId).update({
        'status': CallSignalStatus.answered.name,
        'answeredAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      print('CallSignaling: error answering call: $e');
      CrashlyticsService.logError(e, stack, reason: 'CallSignaling.answerCall failed');
    }
  }

  /// Callee declined the call.
  static Future<void> declineCall(String channelId) async {
    try {
      await _firestore.collection(_collection).doc(channelId).update({
        'status': CallSignalStatus.declined.name,
        'endedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      print('CallSignaling: error declining call: $e');
      CrashlyticsService.logError(e, stack, reason: 'CallSignaling.declineCall failed');
    }
  }

  /// Either party ended the call (mid-conversation or caller cancelled while
  /// ringing).
  static Future<void> endCall(String channelId) async {
    try {
      await _firestore.collection(_collection).doc(channelId).update({
        'status': CallSignalStatus.ended.name,
        'endedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      print('CallSignaling: error ending call: $e');
      CrashlyticsService.logError(e, stack, reason: 'CallSignaling.endCall failed');
    }
  }

  /// No one answered before the timeout.
  static Future<void> missCall(String channelId) async {
    try {
      await _firestore.collection(_collection).doc(channelId).update({
        'status': CallSignalStatus.missed.name,
        'endedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      print('CallSignaling: error marking call as missed: $e');
      CrashlyticsService.logError(e, stack, reason: 'CallSignaling.missCall failed');
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

  // ─── Cleanup ───────────────────────────────────────────────────────────────

  /// Deletes a call document. Called after both parties have left the call
  /// and the call log has been created. Fire-and-forget.
  static Future<void> deleteCallDocument(String channelId) async {
    try {
      await _firestore.collection(_collection).doc(channelId).delete();
    } catch (_) {}
  }
}
