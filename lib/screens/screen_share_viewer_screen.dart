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

          final peerTitle = session.peerName.isEmpty ? 'Someone' : session.peerName;

          return Scaffold(
            backgroundColor: const Color(0xFF0F1318),
            body: SafeArea(
              child: Stack(
                children: [
                  // Remote Screen Video Feed
                  Positioned.fill(child: _buildRemoteScreen(session)),

                  // Top Floating Glass Header Bar
                  Positioned(
                    top: 12,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E232A).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Minimise Action Button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                session.minimize();
                                Navigator.of(context).pop();
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Screen Share Icon + Status
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.screen_share_rounded,
                              color: Color(0xFF818CF8),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$peerTitle is sharing',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF4CAF50),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'LIVE STREAM',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white60,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Duration Counter Pill
                          if (session.peerPresent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                session.formattedDuration,
                                style: GoogleFonts.firaCode(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Floating Action Pill
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E232A).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Minimise Pill
                            GestureDetector(
                              onTap: () {
                                session.minimize();
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.fullscreen_exit_rounded,
                                      color: Colors.white70,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Minimize',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Leave Stream Pill
                            GestureDetector(
                              onTap: () => session.end(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFE53935),
                                      Color(0xFFD32F2F),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFD32F2F)
                                          .withOpacity(0.4),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Leave',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
      return Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.2),
            radius: 1.2,
            colors: [
              const Color(0xFF6366F1).withOpacity(0.12),
              const Color(0xFF0F1318),
            ],
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: Color(0xFF6366F1),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  session.connected
                      ? 'Waiting for ${session.peerName.isEmpty ? 'participant' : session.peerName} to stream screen...'
                      : 'Connecting to encrypted stream...',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
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

