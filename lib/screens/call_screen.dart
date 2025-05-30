import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/provider/call_state_provider.dart';
import 'package:video_chat_app/services/agora_services.dart';

class CallScreen extends StatefulWidget {
  final String channelId;
  final bool isCaller;

  CallScreen({required this.channelId, required this.isCaller});

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

  @override
  void initState() {
    super.initState();
    _initAgora();
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
            });
            Provider.of<CallStateNotifier>(context, listen: false)
                .updateState(CallState.Connected);
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            print("Remote user joined: $remoteUid");
            setState(() {
              _remoteUid = remoteUid;
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
          },
        ),
      );

      // Join channel
      await _engine!.joinChannel(
        token:
            '', // Use empty string for testing, implement token server for production
        channelId: widget.channelId,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
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
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
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
                    onPressed: () {
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
                  widget.isCaller ? 'Calling...' : 'Incoming Call',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Channel: ${widget.channelId}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
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
