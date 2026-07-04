import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/main.dart';
import 'package:video_chat_app/screens/screen_share_screen.dart';
import 'package:video_chat_app/screens/screen_share_viewer_screen.dart';
import 'package:video_chat_app/services/screen_share_session.dart';

/// App-global host that paints a draggable floating "mini-bubble" whenever a
/// [ScreenShareSession] is active AND minimised. Tapping the bubble re-opens
/// the full-screen view; the session itself keeps running independently of
/// navigation. Wrap the app's content with this in MaterialApp.builder.
class ScreenShareOverlayHost extends StatefulWidget {
  final Widget child;
  const ScreenShareOverlayHost({super.key, required this.child});

  @override
  State<ScreenShareOverlayHost> createState() => _ScreenShareOverlayHostState();
}

class _ScreenShareOverlayHostState extends State<ScreenShareOverlayHost> {
  static const double _bubbleW = 132;
  static const double _bubbleH = 56;

  /// Absolute pixel position of the bubble's top-left. Null until the first
  /// build computes a sensible default from the screen size.
  Offset? _pos;
  bool _opening = false;

  void _openFullScreen() {
    if (_opening) return;
    final session = ScreenShareSession.instance;
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    _opening = true;
    session.expand();
    nav
        .push(
      MaterialPageRoute(
        builder: (_) => session.role == ScreenShareRole.sharer
            ? const ScreenShareScreen()
            : const ScreenShareViewerScreen(),
      ),
    )
        .then((_) => _opening = false);
  }

  @override
  Widget build(BuildContext context) {
    final session = ScreenShareSession.instance;
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);

    // Draggable bounds in absolute pixels.
    const minX = 8.0;
    final maxX = size.width - _bubbleW - 8;
    final minY = padding.top + 56; // clear status bar + app bar
    final maxY = size.height - _bubbleH - padding.bottom - 16;

    // Default position: lower-right, comfortably clear of the top.
    _pos ??= Offset(maxX, size.height * 0.65);

    // Keep within bounds (e.g. after rotation).
    final clamped = Offset(
      _pos!.dx.clamp(minX, maxX < minX ? minX : maxX),
      _pos!.dy.clamp(minY, maxY < minY ? minY : maxY),
    );

    return Stack(
      children: [
        widget.child,
        AnimatedBuilder(
          animation: session,
          builder: (context, _) {
            if (!session.active || session.expanded) {
              return const SizedBox.shrink();
            }
            return Positioned(
              left: clamped.dx,
              top: clamped.dy,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openFullScreen,
                onPanUpdate: (d) {
                  setState(() {
                    _pos = Offset(
                      (clamped.dx + d.delta.dx).clamp(
                          minX, maxX < minX ? minX : maxX),
                      (clamped.dy + d.delta.dy).clamp(
                          minY, maxY < minY ? minY : maxY),
                    );
                  });
                },
                child: _buildBubble(session),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBubble(ScreenShareSession session) {
    final isSharer = session.role == ScreenShareRole.sharer;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 132,
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1F8A4C),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.screen_share_rounded,
                color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSharer ? 'Sharing' : 'Viewing',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    session.peerPresent ? session.formattedDuration : 'Tap to open',
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
