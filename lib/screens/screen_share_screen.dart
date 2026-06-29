import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/provider/call_state_provider.dart';
import 'package:video_chat_app/services/agora_services.dart';
import 'package:video_chat_app/services/call_signaling_service.dart';

/// The sharer side of a one-way screen share.
///
/// Joins the Agora channel as a broadcaster and publishes the device screen
/// track. The remote user (viewer) only watches — this screen renders no
/// remote video, just session status and a "Stop sharing" control.
class ScreenShareScreen extends StatefulWidget {
  final String channelId;
  final String? viewerName;

  const ScreenShareScreen({
    super.key,
    required this.channelId,
    this.viewerName,
  });

  @override
  State<ScreenShareScreen> createState() => _ScreenShareScreenState();
}

class _ScreenShareScreenState extends State<ScreenShareScreen> {
  RtcEngine? _engine;
  bool _isInitialized = false;
  bool _isSharing = false;
  bool _viewerJoined = false;
  bool _isEnding = false;

  Timer? _timer;
  int _elapsedSeconds = 0;

  /// Cached so it can be safely used in dispose() (where looking up an
  /// InheritedWidget via context is unsafe).
  CallStateNotifier? _callState;

  @override
  void initState() {
    super.initState();
    _initShare();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _callState = Provider.of<CallStateNotifier>(context, listen: false);
  }

  Future<void> _initShare() async {
    try {
      _engine = await AgoraService.initAgoraForScreenShare();

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            if (!mounted) return;
            setState(() => _isInitialized = true);
            Provider.of<CallStateNotifier>(context, listen: false)
                .updateState(CallState.Connected);
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            if (!mounted) return;
            setState(() => _viewerJoined = true);
            _startTimer();
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            // Viewer left — end the screen share for this side too.
            if (_viewerJoined && !_isEnding) {
              _endShare();
            }
          },
          onError: (ErrorCodeType err, String msg) {
            print('Agora screen share error: $err - $msg');
          },
        ),
      );

      // Begin capturing the screen (shows the system consent dialog on Android).
      await AgoraService.startScreenShare(_engine!);
      if (mounted) setState(() => _isSharing = true);

      await _engine!.joinChannel(
        token: '',
        channelId: widget.channelId,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishScreenCaptureVideo: true,
          // Publish the captured system audio so the viewer can hear sounds
          // playing on this device's screen.
          publishScreenCaptureAudio: true,
          publishCameraTrack: false,
          publishMicrophoneTrack: false,
          autoSubscribeVideo: false,
          autoSubscribeAudio: false,
        ),
      );
    } catch (e) {
      print('Error starting screen share: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start screen sharing: $e')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _endShare() async {
    if (_isEnding) return;
    _isEnding = true;

    if (_engine != null) {
      await AgoraService.stopScreenShare(_engine!);
    }
    await CallSignalingService.endCall(widget.channelId);

    if (mounted) {
      Provider.of<CallStateNotifier>(context, listen: false)
          .updateState(CallState.Ended);
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (!_isEnding) {
      CallSignalingService.endCall(widget.channelId);
    }
    // Always reset the global call state so exiting via the system back
    // gesture (which bypasses _endShare) can't leave it stuck in
    // Connected/Calling and block future calls.
    _callState?.updateState(CallState.Ended);
    AgoraService.releaseEngine(_engine);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusText = !_isInitialized
        ? 'Starting screen share...'
        : !_viewerJoined
            ? 'Waiting for ${widget.viewerName ?? 'the other person'} to join...'
            : 'Sharing your screen';

    return Scaffold(
      backgroundColor: const Color(0xFF101418),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: _isSharing
                      ? const Color(0xFF2E7D32)
                      : Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.screen_share_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                statusText,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              if (_viewerJoined)
                Text(
                  _formatDuration(_elapsedSeconds),
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                )
              else
                Text(
                  'Your entire screen is visible to the other person.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              const Spacer(),
              GestureDetector(
                onTap: _endShare,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.stop_screen_share_rounded,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Stop sharing',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
