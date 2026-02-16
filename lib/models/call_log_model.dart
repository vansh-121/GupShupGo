import 'package:cloud_firestore/cloud_firestore.dart';

enum CallType { incoming, outgoing, missed }

enum CallStatus { answered, declined, missed, cancelled }

class CallLogModel {
  final String id;
  final String callerId;
  final String callerName;
  final String? callerPhotoUrl;
  final String calleeId;
  final String calleeName;
  final String? calleePhotoUrl;
  final String channelId;
  final CallType callType; // From perspective of the user viewing this log
  final CallStatus status;
  final DateTime timestamp;
  final int? durationInSeconds;

  CallLogModel({
    required this.id,
    required this.callerId,
    required this.callerName,
    this.callerPhotoUrl,
    required this.calleeId,
    required this.calleeName,
    this.calleePhotoUrl,
    required this.channelId,
    required this.callType,
    required this.status,
    required this.timestamp,
    this.durationInSeconds,
  });

  // Get the other person's name (from perspective of current user)
  String getOtherPersonName(String currentUserId) {
    return currentUserId == callerId ? calleeName : callerName;
  }

  // Get the other person's photo URL
  String? getOtherPersonPhotoUrl(String currentUserId) {
    return currentUserId == callerId ? calleePhotoUrl : callerPhotoUrl;
  }

  // Get the other person's ID
  String getOtherPersonId(String currentUserId) {
    return currentUserId == callerId ? calleeId : callerId;
  }

  // Format duration to human readable string
  String getFormattedDuration() {
    if (durationInSeconds == null || durationInSeconds == 0) {
      return status == CallStatus.missed ? 'Missed' : 
             status == CallStatus.declined ? 'Declined' :
             status == CallStatus.cancelled ? 'Cancelled' : 'No duration';
    }
    
    final minutes = durationInSeconds! ~/ 60;
    final seconds = durationInSeconds! % 60;
    
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'callerId': callerId,
      'callerName': callerName,
      'callerPhotoUrl': callerPhotoUrl,
      'calleeId': calleeId,
      'calleeName': calleeName,
      'calleePhotoUrl': calleePhotoUrl,
      'channelId': channelId,
      'callType': callType.toString().split('.').last,
      'status': status.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'durationInSeconds': durationInSeconds,
    };
  }

  // Create from Firestore document
  factory CallLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CallLogModel(
      id: doc.id,
      callerId: data['callerId'] ?? '',
      callerName: data['callerName'] ?? 'Unknown',
      callerPhotoUrl: data['callerPhotoUrl'],
      calleeId: data['calleeId'] ?? '',
      calleeName: data['calleeName'] ?? 'Unknown',
      calleePhotoUrl: data['calleePhotoUrl'],
      channelId: data['channelId'] ?? '',
      callType: _parseCallType(data['callType']),
      status: _parseCallStatus(data['status']),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      durationInSeconds: data['durationInSeconds'],
    );
  }

  static CallType _parseCallType(String? type) {
    switch (type) {
      case 'incoming':
        return CallType.incoming;
      case 'outgoing':
        return CallType.outgoing;
      case 'missed':
        return CallType.missed;
      default:
        return CallType.outgoing;
    }
  }

  static CallStatus _parseCallStatus(String? status) {
    switch (status) {
      case 'answered':
        return CallStatus.answered;
      case 'declined':
        return CallStatus.declined;
      case 'missed':
        return CallStatus.missed;
      case 'cancelled':
        return CallStatus.cancelled;
      default:
        return CallStatus.missed;
    }
  }
}
