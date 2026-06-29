import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/services/screen_share_session.dart';

/// The full-screen sharer view. This is now a thin observer of
/// [ScreenShareSession] — the Agora engine lives in the session, not here, so
/// navigating back simply MINIMISES the session (it keeps running) instead of
/// ending it. Tapping the floating bubble re-opens this view.
class ScreenShareScreen extends StatelessWidget {
  const ScreenShareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = ScreenShareSession.instance;

    return PopScope(
      // Back never ends the session — it minimises to the floating bubble.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        session.minimize();
        Navigator.of(context).pop();
      },
      child: AnimatedBuilder(
        animation: session,
        builder: (context, _) {
          // If the session ended while this view was open, close it.
          if (!session.active) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            });
          }

          final statusText = !session.connected
              ? 'Starting screen share...'
              : !session.peerPresent
                  ? 'Waiting for ${session.peerName.isEmpty ? 'the other person' : session.peerName} to join...'
                  : 'Sharing your screen';

          return Scaffold(
            backgroundColor: const Color(0xFF101418),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Top bar with a minimise button.
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: Colors.white, size: 30),
                        tooltip: 'Minimise',
                        onPressed: () {
                          session.minimize();
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: session.connected
                            ? const Color(0xFF2E7D32)
                            : Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.screen_share_rounded,
                          color: Colors.white, size: 44),
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
                    if (session.peerPresent)
                      Text(
                        session.formattedDuration,
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 14),
                      )
                    else
                      Text(
                        'Your entire screen is visible to the other person.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            color: Colors.white54, fontSize: 13),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'You can go back and keep using the app while sharing.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          color: Colors.white38, fontSize: 12),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => session.end(),
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
        },
      ),
    );
  }
}
