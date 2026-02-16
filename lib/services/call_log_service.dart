import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_chat_app/models/call_log_model.dart';

class CallLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _callLogsCollection = 'callLogs';

  /// Create a call log entry for both caller and callee
  Future<void> createCallLog({
    required String callerId,
    required String callerName,
    String? callerPhotoUrl,
    required String calleeId,
    required String calleeName,
    String? calleePhotoUrl,
    required String channelId,
    required CallStatus status,
    int? durationInSeconds,
  }) async {
    try {
      final timestamp = DateTime.now();
      
      // Create log for both users with appropriate call types
      final logId = _firestore.collection(_callLogsCollection).doc().id;
      
      final logData = {
        'id': logId,
        'callerId': callerId,
        'callerName': callerName,
        'callerPhotoUrl': callerPhotoUrl,
        'calleeId': calleeId,
        'calleeName': calleeName,
        'calleePhotoUrl': calleePhotoUrl,
        'channelId': channelId,
        'status': status.toString().split('.').last,
        'timestamp': Timestamp.fromDate(timestamp),
        'durationInSeconds': durationInSeconds ?? 0,
      };

      await _firestore.collection(_callLogsCollection).doc(logId).set(logData);
      
      print('Call log created: $logId');
    } catch (e) {
      print('Error creating call log: $e');
      rethrow;
    }
  }

  /// Get call logs for a specific user
  Stream<List<CallLogModel>> getCallLogs(String userId) {
    return _firestore
        .collection(_callLogsCollection)
        .where('callerId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .asyncMap((callerSnapshot) async {
      // Get logs where user is caller
      final callerLogs = callerSnapshot.docs.map((doc) {
        final log = CallLogModel.fromFirestore(doc);
        // Create a new instance with outgoing type
        return CallLogModel(
          id: log.id,
          callerId: log.callerId,
          callerName: log.callerName,
          callerPhotoUrl: log.callerPhotoUrl,
          calleeId: log.calleeId,
          calleeName: log.calleeName,
          calleePhotoUrl: log.calleePhotoUrl,
          channelId: log.channelId,
          callType: CallType.outgoing,
          status: log.status,
          timestamp: log.timestamp,
          durationInSeconds: log.durationInSeconds,
        );
      }).toList();

      // Get logs where user is callee
      final calleeSnapshot = await _firestore
          .collection(_callLogsCollection)
          .where('calleeId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      final calleeLogs = calleeSnapshot.docs.map((doc) {
        final log = CallLogModel.fromFirestore(doc);
        // Create a new instance with incoming type
        return CallLogModel(
          id: log.id,
          callerId: log.callerId,
          callerName: log.callerName,
          callerPhotoUrl: log.callerPhotoUrl,
          calleeId: log.calleeId,
          calleeName: log.calleeName,
          calleePhotoUrl: log.calleePhotoUrl,
          channelId: log.channelId,
          callType: CallType.incoming,
          status: log.status,
          timestamp: log.timestamp,
          durationInSeconds: log.durationInSeconds,
        );
      }).toList();

      // Combine and sort by timestamp
      final allLogs = [...callerLogs, ...calleeLogs];
      allLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return allLogs.take(50).toList();
    });
  }

  /// Delete a specific call log
  Future<void> deleteCallLog(String logId) async {
    try {
      await _firestore.collection(_callLogsCollection).doc(logId).delete();
      print('Call log deleted: $logId');
    } catch (e) {
      print('Error deleting call log: $e');
      rethrow;
    }
  }

  /// Delete all call logs for a user
  Future<void> deleteAllCallLogs(String userId) async {
    try {
      // Delete where user is caller
      final callerLogs = await _firestore
          .collection(_callLogsCollection)
          .where('callerId', isEqualTo: userId)
          .get();
      
      for (var doc in callerLogs.docs) {
        await doc.reference.delete();
      }

      // Delete where user is callee
      final calleeLogs = await _firestore
          .collection(_callLogsCollection)
          .where('calleeId', isEqualTo: userId)
          .get();
      
      for (var doc in calleeLogs.docs) {
        await doc.reference.delete();
      }

      print('All call logs deleted for user: $userId');
    } catch (e) {
      print('Error deleting all call logs: $e');
      rethrow;
    }
  }
}
