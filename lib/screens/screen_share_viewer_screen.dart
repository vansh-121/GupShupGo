import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/provider/call_state_provider.dart';
import 'package:video_chat_app/services/agora_services.dart';
import 'package:video_chat_app/services/call_signaling_service.dart';

/// The viewer side of a one-way screen share.
///
/// Joins the same Agora channel as the sharer and renders the remote screen
/// track full-screen. The viewer publishes nothing.
class ScreenShareViewerScreen extends StatefulWidget {
  final String channelId;
  final String sharerName;

  const ScreenShareViewerScreen({
    super.key,
    required this.channelId,
    required this.sharerName,
  });

  @override
  State<ScreenShareViewerScreen> createState() =>
      _ScreenShareViewerScreenState();
}

class _ScreenShareViewerScreenState extends State<ScreenShareViewerScreen> {
  RtcEngine? _engine;
  int? _remoteUid;
  bool _isInitialized = false;
  bool _isEnding = false;

  StreamSubscription<CallSignalStatus?>? _signalingSubscription;

  @override
  void initState() {
    super.initState();
    _initViewer();
    _listenForEnd();
  }

  Future<void> _initViewer() async {
    try {
      _engine = await AgoraService.initAgoraForScreenShareViewer();

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            if (!mounted) return;
            setState(() => _isInitialized = true);
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            if (!mounted) return;
            setState(() => _remoteUid = remoteUid);
            Provider.of<CallStateNotifier>(context, listen: false)
                .updateState(CallState.Connected);
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            // Sharer stopped — close the viewer.
            if (!_isEnding) {
              _leave(reason: 'Screen sharing ended');
            }
          },
          onError: (ErrorCodeType err, String msg) {
            print('Agora viewer error: $err - $msg');
          },
        ),
      );

      await _engine!.joinChannel(
        token: '',
        channelId: widget.channelId,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishCameraTrack: false,
          publishMicrophoneTrack: false,
          publishScreenCaptureVideo: false,
          publishScreenCaptureAudio: false,
          autoSubscribeVideo: true,
          autoSubscribeAudio: false,
        ),
      );
    } catch (e) {
      print('Error joining screen share: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to view shared screen: $e')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  void _listenForEnd() {
    _signalingSubscription =
        CallSignalingService.listenToCallStatus(widget.channelId).listen(
      (status) {
        if (status == CallSignalStatus.ended ||
            status == CallSignalStatus.declined) {
          _leave(reason: 'Screen sharing ended');
        }
      },
    );
  }

  Future<void> _leave({String? reason}) async {
    if (_isEnding) return;
    _isEnding = true;

    if (mounted) {
      Provider.of<CallStateNotifier>(context, listen: false)
          .updateState(CallState.Ended);
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _signalingSubscription?.cancel();
    AgoraService.releaseEngine(_engine);
    super.dispose();
  }

  Widget _buildRemoteScreen() {
    if (_remoteUid == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            Text(
              _isInitialized
                  ? 'Waiting for ${widget.sharerName} to share...'
                  : 'Connecting...',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine!,
        canvas: VideoCanvas(
          uid: _remoteUid,
          renderMode: RenderModeType.renderModeFit,
        ),
        connection: RtcConnection(channelId: widget.channelId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _buildRemoteScreen()),
            // Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                color: Colors.black.withOpacity(0.4),
                child: Row(
                  children: [
                    const Icon(Icons.screen_share_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${widget.sharerName} is sharing their screen',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Leave button
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _leave(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.close_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Leave',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
