import 'dart:async';
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
  final bool isAudioOnly;

  CallScreen({
    required this.channelId,
    required this.isCaller,
    this.calleeId,
    this.calleeName,
    this.isAudioOnly = false,
  });

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  RtcEngine? _engine;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isOnHold = false;
  bool _isFrontCamera = true;
  bool _isInitialized = false;
  int? _remoteUid;
  bool _localVideoEnabled = true;

  // Call timer
  Timer? _callTimer;
  int _callDurationSeconds = 0;

  // Call logging fields
  final CallLogService _callLogService = CallLogService();
  DateTime? _callStartTime;
  bool _remoteUserJoined = false;
  bool _callLogCreated = false;
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
      // Set initial call start time to avoid null errors
      _callStartTime = DateTime.now();

      // Initialize Agora engine
      _engine = await AgoraService.initAgora(isAudioOnly: widget.isAudioOnly);

      // Request permissions
      await AgoraService.requestPermissions(isAudioOnly: widget.isAudioOnly);

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
              _remoteUserJoined = true;
            });
            _startCallTimer();
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

      // Small delay to ensure engine is fully initialized
      await Future.delayed(Duration(milliseconds: 200));

      // Join channel with null token for testing
      await _engine!.joinChannel(
        token: '', // Use empty string for testing without token server
        channelId: widget.channelId,
        uid: 0,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishCameraTrack: !widget.isAudioOnly,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: !widget.isAudioOnly,
        ),
      );
    } catch (e) {
      print("Error initializing Agora: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to initialize ${widget.isAudioOnly ? "audio" : "video"} call: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    // Create call log (fire and forget for cases like back button press)
    _createCallLog();

    // Use proper release method with cleanup tracking
    AgoraService.releaseEngine(_engine);
    super.dispose();
  }

  void _startCallTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDurationSeconds++;
        });
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _createCallLog() async {
    // Prevent duplicate call logs
    if (_callLogCreated) return;
    _callLogCreated = true;

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
        widget.calleeName == null) {
      print('⚠️ Cannot create call log - missing required fields');
      return;
    }

    // Use _callDurationSeconds for accurate talk time (excludes ringing/waiting time)
    // _callDurationSeconds starts only when the remote user joins the channel
    final durationInSeconds = _callDurationSeconds;

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

    print(
        'Creating log: callType=$callType, status=$status, duration=$durationInSeconds');

    try {
      await _callLogService.createCallLog(
        callerId: widget.isCaller ? _currentUserId! : widget.calleeId!,
        callerName: widget.isCaller ? _currentUserName! : widget.calleeName!,
        callerPhotoUrl:
            widget.isCaller ? _currentUserPhotoUrl : _calleePhotoUrl,
        calleeId: widget.isCaller ? widget.calleeId! : _currentUserId!,
        calleeName: widget.isCaller ? widget.calleeName! : _currentUserName!,
        calleePhotoUrl:
            widget.isCaller ? _calleePhotoUrl : _currentUserPhotoUrl,
        channelId: widget.channelId,
        status: status,
        mediaType:
            widget.isAudioOnly ? CallMediaType.audio : CallMediaType.video,
        durationInSeconds:
            status == CallStatus.answered ? durationInSeconds : 0,
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

  Widget _buildAudioCallUI() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF00A884),
            Color(0xFF005C4B),
            Color(0xFF111B21),
            Color(0xFF111B21),
          ],
          stops: [0.0, 0.3, 0.6, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Encrypted label
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, color: Colors.white60, size: 12),
                const SizedBox(width: 4),
                Text(
                  'End-to-end encrypted',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            // User name
            Text(
              widget.calleeName ?? 'Unknown',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            // Call status / timer
            Text(
              _getCallStatusText(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const Spacer(flex: 1),
            // User avatar
            CircleAvatar(
              radius: 75,
              backgroundColor: Colors.white24,
              backgroundImage: _calleePhotoUrl != null
                  ? NetworkImage(_calleePhotoUrl!)
                  : null,
              child: _calleePhotoUrl == null
                  ? Icon(Icons.person, size: 75, color: Colors.white70)
                  : null,
            ),
            const Spacer(flex: 2),
            // Control buttons grid (WhatsApp style - 2 rows)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  // Top row: Speaker, Mute, Hold (not available in video)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: _isSpeakerOn
                            ? Icons.volume_up
                            : Icons.volume_up_outlined,
                        label: 'Speaker',
                        isActive: _isSpeakerOn,
                        onTap: () {
                          setState(() => _isSpeakerOn = !_isSpeakerOn);
                          _engine?.setEnableSpeakerphone(_isSpeakerOn);
                        },
                      ),
                      _buildControlButton(
                        icon: _isMuted ? Icons.mic_off : Icons.mic_none,
                        label: 'Mute',
                        isActive: _isMuted,
                        onTap: () {
                          setState(() => _isMuted = !_isMuted);
                          _engine?.muteLocalAudioStream(_isMuted);
                        },
                      ),
                      _buildControlButton(
                        icon: _isOnHold ? Icons.play_arrow : Icons.pause,
                        label: _isOnHold ? 'Resume' : 'Hold',
                        isActive: _isOnHold,
                        onTap: () {
                          setState(() => _isOnHold = !_isOnHold);
                          _engine?.muteLocalAudioStream(_isOnHold || _isMuted);
                          _engine?.muteAllRemoteAudioStreams(_isOnHold);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
            // End call button
            GestureDetector(
              onTap: () async {
                await _createCallLog();
                Provider.of<CallStateNotifier>(context, listen: false)
                    .updateState(CallState.Ended);
                Navigator.pop(context);
              },
              child: Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Color(0xFFEA0038),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call_end,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  String _getCallStatusText() {
    if (_isOnHold) return 'On hold';
    if (_remoteUserJoined && _callDurationSeconds > 0) {
      return _formatDuration(_callDurationSeconds);
    }
    if (_isInitialized && _remoteUid == null) {
      return widget.isCaller ? 'Ringing...' : 'Connecting...';
    }
    if (!_isInitialized) {
      return widget.isCaller ? 'Calling...' : 'Connecting...';
    }
    return 'Connected';
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Color(0xFF005C4B) : Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // For audio calls, use the dedicated WhatsApp-style audio UI
    if (widget.isAudioOnly) {
      return Scaffold(
        backgroundColor: Color(0xFF111B21),
        body: _buildAudioCallUI(),
      );
    }

    // Video call UI
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

          // Call timer for video calls
          if (_remoteUserJoined && _callDurationSeconds > 0)
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _formatDuration(_callDurationSeconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
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
                // Speaker button
                Container(
                  decoration: BoxDecoration(
                    color: _isSpeakerOn
                        ? Colors.white
                        : Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isSpeakerOn ? Icons.volume_up : Icons.volume_up_outlined,
                      color: _isSpeakerOn ? Colors.black : Colors.white,
                      size: 26,
                    ),
                    onPressed: () {
                      setState(() => _isSpeakerOn = !_isSpeakerOn);
                      _engine?.setEnableSpeakerphone(_isSpeakerOn);
                    },
                  ),
                ),

                // Mute/Unmute button
                Container(
                  decoration: BoxDecoration(
                    color:
                        _isMuted ? Colors.white : Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isMuted ? Icons.mic_off : Icons.mic,
                      color: _isMuted ? Colors.black : Colors.white,
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
                    color: Color(0xFFEA0038),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () async {
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
                    color: !_localVideoEnabled
                        ? Colors.white
                        : Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _localVideoEnabled ? Icons.videocam : Icons.videocam_off,
                      color: !_localVideoEnabled ? Colors.black : Colors.white,
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
                  widget.calleeName ??
                      (widget.isCaller ? 'Calling...' : 'Incoming Call'),
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
