import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/models/call_log_model.dart';
import 'package:video_chat_app/provider/call_state_provider.dart';
import 'package:video_chat_app/services/agora_services.dart';
import 'package:video_chat_app/services/call_log_service.dart';

class CallScreen extends StatefulWidget {
  final String channelId;
  final bool isCaller;
  final String? calleeId;
  final String? calleeName;

  CallScreen({
    required this.channelId,
    required this.isCaller,
    this.calleeId,
    this.calleeName,
  });

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  RtcEngine? _engine;
  bool _isMuted = false;
  bool _isFrontCamera = true;
  bool _isInitialized = false;
  int? _remoteUid;
  bool _localVideoEnabled = true;

  // Call logging fields
  final CallLogService _callLogService = CallLogService();
  DateTime? _callStartTime;
  bool _remoteUserJoined = false;
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserPhotoUrl;
  String? _calleePhotoUrl;

  @override
  void initState() {
    super.initState();
    _initializeUserInfo();
    _initAgora();
  }

  Future<void> _initializeUserInfo() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _currentUserId = currentUser.uid;
      
      // Fetch current user details from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      if (userDoc.exists) {
        _currentUserName = userDoc.data()?['name'] ?? 'Unknown';
        _currentUserPhotoUrl = userDoc.data()?['photoUrl'];
      }

      // Fetch callee photo URL if calleeId is provided
      if (widget.calleeId != null) {
        final calleeDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.calleeId)
            .get();
        
        if (calleeDoc.exists) {
          _calleePhotoUrl = calleeDoc.data()?['photoUrl'];
        }
      }
    }
  }

  Future<void> _initAgora() async {
    try {
      // Initialize Agora engine
      _engine = await AgoraService.initAgora();

      // Request permissions
      await AgoraService.requestPermissions();

      // Set up event handlers
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            print("Local user joined channel: ${connection.channelId}");
            setState(() {
              _isInitialized = true;
              _callStartTime = DateTime.now(); // Track call start time
            });
            Provider.of<CallStateNotifier>(context, listen: false)
                .updateState(CallState.Connected);
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            print("Remote user joined: $remoteUid");
            setState(() {
              _remoteUid = remoteUid;
              _remoteUserJoined = true; // Track that remote user joined
            });
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            print("Remote user left: $remoteUid");
            setState(() {
              _remoteUid = null;
            });
          },
          onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
            print("Token will expire, should refresh token");
          },
          onError: (ErrorCodeType err, String msg) {
            print("Agora Error: $err - $msg");
            if (err == ErrorCodeType.errInvalidToken) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Token expired or invalid. Please restart the call.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      );

      // Join channel with null token for testing
      await _engine!.joinChannel(
        token: '', // Use empty string for testing without token server
        channelId: widget.channelId,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
    } catch (e) {
      print("Error initializing Agora: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize video call: $e')),
      );
    }
  }

  @override
  void dispose() {
    // Create call log (fire and forget for cases like back button press)
    _createCallLog();
    
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  Future<void> _createCallLog() async {
    print('=== Creating Call Log ===');
    print('_currentUserId: $_currentUserId');
    print('_currentUserName: $_currentUserName');
    print('widget.calleeId: ${widget.calleeId}');
    print('widget.calleeName: ${widget.calleeName}');
    print('_callStartTime: $_callStartTime');
    
    // Only create log if we have necessary information
    if (_currentUserId == null || 
        _currentUserName == null || 
        widget.calleeId == null || 
        widget.calleeName == null ||
        _callStartTime == null) {
      print('⚠️ Cannot create call log - missing required fields');
      return;
    }

    // Calculate call duration
    final durationInSeconds = DateTime.now().difference(_callStartTime!).inSeconds;

    // Determine call status
    CallStatus status;
    if (_remoteUserJoined) {
      status = CallStatus.answered;
    } else {
      // If remote user never joined, it's either missed or cancelled
      status = widget.isCaller ? CallStatus.cancelled : CallStatus.missed;
    }

    // Determine call type based on whether this user is caller or callee
    final callType = widget.isCaller ? CallType.outgoing : CallType.incoming;

    print('Creating log: callType=$callType, status=$status, duration=$durationInSeconds');
    
    try {
      await _callLogService.createCallLog(
        callerId: widget.isCaller ? _currentUserId! : widget.calleeId!,
        callerName: widget.isCaller ? _currentUserName! : widget.calleeName!,
        callerPhotoUrl: widget.isCaller ? _currentUserPhotoUrl : _calleePhotoUrl,
        calleeId: widget.isCaller ? widget.calleeId! : _currentUserId!,
        calleeName: widget.isCaller ? widget.calleeName! : _currentUserName!,
        calleePhotoUrl: widget.isCaller ? _calleePhotoUrl : _currentUserPhotoUrl,
        channelId: widget.channelId,
        status: status,
        durationInSeconds: status == CallStatus.answered ? durationInSeconds : 0,
      );
      print('✅ Call log created successfully');
    } catch (e) {
      print('❌ Error creating call log: $e');
    }
  }

  Widget _buildLocalPreview() {
    if (_engine == null || !_isInitialized) return Container();

    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine!,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }

  Widget _buildRemoteVideo() {
    if (_engine == null || !_isInitialized || _remoteUid == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'Waiting for remote user...',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine!,
        canvas: VideoCanvas(uid: _remoteUid),
        connection: RtcConnection(channelId: widget.channelId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video (full screen)
          _buildRemoteVideo(),

          // Local video (small preview in top-right corner)
          if (_isInitialized)
            Positioned(
              top: 40,
              right: 20,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: _buildLocalPreview(),
                ),
              ),
            ),

          // Loading indicator
          if (!_isInitialized)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    'Connecting...',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),

          // Control buttons at bottom
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mute/Unmute button
                Container(
                  decoration: BoxDecoration(
                    color:
                        _isMuted ? Colors.red : Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isMuted ? Icons.mic_off : Icons.mic,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      setState(() => _isMuted = !_isMuted);
                      _engine?.muteLocalAudioStream(_isMuted);
                    },
                  ),
                ),

                // End call button
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () async {
                      // Create call log before ending call
                      await _createCallLog();
                      
                      Provider.of<CallStateNotifier>(context, listen: false)
                          .updateState(CallState.Ended);
                      Navigator.pop(context);
                    },
                  ),
                ),

                // Switch camera button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.switch_camera,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      setState(() => _isFrontCamera = !_isFrontCamera);
                      _engine?.switchCamera();
                    },
                  ),
                ),

                // Video on/off button
                Container(
                  decoration: BoxDecoration(
                    color: _localVideoEnabled
                        ? Colors.white.withOpacity(0.2)
                        : Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _localVideoEnabled ? Icons.videocam : Icons.videocam_off,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      setState(() => _localVideoEnabled = !_localVideoEnabled);
                      _engine?.muteLocalVideoStream(!_localVideoEnabled);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Call info at top
          Positioned(
            top: 50,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.calleeName ?? (widget.isCaller ? 'Calling...' : 'Incoming Call'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _remoteUid != null ? 'Connected' : 'Waiting...',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
