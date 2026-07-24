import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/services/screen_share_session.dart';

/// Redesigned full-screen sharer view with Obsidian Command glassmorphism,
/// glowing animated pulse rings, live status badges, and floating action controls.
class ScreenShareScreen extends StatefulWidget {
  const ScreenShareScreen({super.key});

  @override
  State<ScreenShareScreen> createState() => _ScreenShareScreenState();
}

class _ScreenShareScreenState extends State<ScreenShareScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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

          final isLive = session.connected && session.peerPresent;
          final statusTitle = !session.connected
              ? 'Initializing Broadcast'
              : !session.peerPresent
                  ? 'Waiting for Participant'
                  : 'Screen Sharing Active';

          final statusSubtitle = !session.connected
              ? 'Establishing encrypted stream...'
              : !session.peerPresent
                  ? 'Waiting for ${session.peerName.isEmpty ? 'participant' : session.peerName} to join...'
                  : 'Your entire screen is visible in high definition.';

          return Scaffold(
            backgroundColor: const Color(0xFF0F1318),
            body: Stack(
              children: [
                // Ambient Glow Background
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.2),
                        radius: 1.2,
                        colors: [
                          isLive
                              ? const Color(0xFF2E7D32).withOpacity(0.18)
                              : const Color(0xFF6366F1).withOpacity(0.15),
                          const Color(0xFF0F1318),
                        ],
                      ),
                    ),
                  ),
                ),

                SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      children: [
                        // Top Header Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Minimise Button
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  session.minimize();
                                  Navigator.of(context).pop();
                                },
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.06),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),

                            // Header Title & Signal Pill
                            Row(
                              children: [
                                // Connection Quality Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: isLive
                                              ? const Color(0xFF4CAF50)
                                              : session.connected
                                                  ? const Color(0xFFFFB74D)
                                                  : Colors.white38,
                                          shape: BoxShape.circle,
                                          boxShadow: isLive
                                              ? [
                                                  BoxShadow(
                                                    color: const Color(0xFF4CAF50)
                                                        .withOpacity(0.6),
                                                    blurRadius: 6,
                                                    spreadRadius: 1,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isLive ? 'HD • 60 FPS' : 'CONNECTING',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Duration Counter Badge
                                if (session.peerPresent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366F1)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFF6366F1)
                                            .withOpacity(0.4),
                                      ),
                                    ),
                                    child: Text(
                                      session.formattedDuration,
                                      style: GoogleFonts.firaCode(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Central Hero Glassmorphic Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Pulsing Rings + Center Icon
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  final wave = _pulseController.value;
                                  final activeColor = isLive
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFF6366F1);

                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Outer pulse wave 2
                                      Transform.scale(
                                        scale: 1.0 + (wave * 0.45),
                                        child: Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: activeColor.withOpacity(
                                                  (1.0 - wave) * 0.3),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Outer pulse wave 1
                                      Transform.scale(
                                        scale: 1.0 + (wave * 0.25),
                                        child: Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: activeColor.withOpacity(
                                                (1.0 - wave) * 0.15),
                                          ),
                                        ),
                                      ),
                                      // Core Icon Badge
                                      Container(
                                        width: 88,
                                        height: 88,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: isLive
                                                ? [
                                                    const Color(0xFF388E3C),
                                                    const Color(0xFF1B5E20),
                                                  ]
                                                : [
                                                    const Color(0xFF6366F1),
                                                    const Color(0xFF4338CA),
                                                  ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: activeColor.withOpacity(0.5),
                                              blurRadius: 18,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.screen_share_rounded,
                                          color: Colors.white,
                                          size: 40,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),

                              const SizedBox(height: 28),

                              // Status Title
                              Text(
                                statusTitle,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Status Subtitle
                              Text(
                                statusSubtitle,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.white60,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),

                              if (session.peerName.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                // Participant Info Chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.08),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor:
                                            const Color(0xFF6366F1),
                                        child: Text(
                                          session.peerName
                                              .characters
                                              .first
                                              .toUpperCase(),
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Shared with ',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        session.peerName,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Tip text
                        Text(
                          'You can minimize this screen to keep using GupShupGo.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),

                        const Spacer(),

                        // Floating Glass Control Bar
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E232A).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: GestureDetector(
                            onTap: () => session.end(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFE53935),
                                    Color(0xFFD32F2F),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        const Color(0xFFD32F2F).withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.stop_screen_share_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Stop sharing',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

