import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/services/screen_share_session.dart';

/// The full-screen viewer view. A thin observer of [ScreenShareSession] — the
/// Agora engine lives in the session, so navigating back MINIMISES (the
/// session keeps running) rather than ending it. Tapping the floating bubble
/// re-opens this view.
class ScreenShareViewerScreen extends StatelessWidget {
  const ScreenShareViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = ScreenShareSession.instance;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        session.minimize();
        Navigator.of(context).pop();
      },
      child: AnimatedBuilder(
        animation: session,
        builder: (context, _) {
          if (!session.active) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            });
          }

          return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(child: _buildRemoteScreen(session)),
                  // Header with minimise + title
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      color: Colors.black.withOpacity(0.4),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                color: Colors.white, size: 28),
                            tooltip: 'Minimise',
                            onPressed: () {
                              session.minimize();
                              Navigator.of(context).pop();
                            },
                          ),
                          const Icon(Icons.screen_share_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${session.peerName.isEmpty ? 'Someone' : session.peerName} is sharing their screen',
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
                        onTap: () => session.end(),
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
        },
      ),
    );
  }

  Widget _buildRemoteScreen(ScreenShareSession session) {
    final engine = session.engine;
    final remoteUid = session.remoteUid;
    final channelId = session.channelId;

    if (engine == null || remoteUid == null || channelId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            Text(
              session.connected
                  ? 'Waiting for ${session.peerName.isEmpty ? 'the other person' : session.peerName} to share...'
                  : 'Connecting...',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: engine,
        canvas: VideoCanvas(
          uid: remoteUid,
          renderMode: RenderModeType.renderModeFit,
        ),
        connection: RtcConnection(channelId: channelId),
      ),
    );
  }
}
