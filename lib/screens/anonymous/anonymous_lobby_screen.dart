import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/services/anonymous_chat_service.dart';
import 'package:video_chat_app/screens/anonymous/anonymous_chat_screen.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// Lobby screen with a radar ripple animation while searching for
/// a random stranger to pair with.
class AnonymousLobbyScreen extends StatefulWidget {
  final String currentUserId;
  final String? currentUserName;

  const AnonymousLobbyScreen({
    super.key,
    required this.currentUserId,
    this.currentUserName,
  });

  @override
  State<AnonymousLobbyScreen> createState() => _AnonymousLobbyScreenState();
}

class _AnonymousLobbyScreenState extends State<AnonymousLobbyScreen>
    with TickerProviderStateMixin {
  final _service = AnonymousChatService.instance;
  StreamSubscription<DocumentSnapshot>? _queueSub;
  late AnimationController _rippleController;
  bool _isSearching = true;
  bool _navigated = false;

  // Retry timer — if no match found immediately, periodically re-attempt
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _startSearching();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _queueSub?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _startSearching() async {
    setState(() => _isSearching = true);

    // Join the matchmaking queue
    await _service.joinQueue(widget.currentUserId);

    // Listen for when we get matched
    _queueSub = _service
        .listenToQueueEntry(widget.currentUserId)
        .listen(_onQueueUpdate);

    // Retry pairing every 3 seconds in case new users join the queue
    _retryTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_isSearching && !_navigated) {
        _service.findAndPair(widget.currentUserId);
      }
    });
  }

  void _onQueueUpdate(DocumentSnapshot snapshot) {
    if (!snapshot.exists || _navigated) return;
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) return;

    final status = data['status'] as String?;
    final matchedRoomId = data['matchedRoomId'] as String?;

    if (status == 'matched' && matchedRoomId != null) {
      _navigated = true;
      _retryTimer?.cancel();
      _queueSub?.cancel();
      _navigateToChatRoom(matchedRoomId);
    }
  }

  void _navigateToChatRoom(String roomId) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AnonymousChatScreen(
          roomId: roomId,
          currentUserId: widget.currentUserId,
          currentUserName: widget.currentUserName,
        ),
      ),
    );
  }

  Future<void> _cancelSearch() async {
    _retryTimer?.cancel();
    _queueSub?.cancel();
    await _service.leaveQueue(widget.currentUserId);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: c.textHigh),
          onPressed: _cancelSearch,
        ),
        title: Text(
          'Anonymous Chat',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: c.textHigh,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Radar Ripple Animation ───────────────────────────
            SizedBox(
              width: 200,
              height: 200,
              child: AnimatedBuilder2(
                animation: _rippleController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _RadarRipplePainter(
                      progress: _rippleController.value,
                      color: c.primary,
                    ),
                    child: Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: c.primary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_search_rounded,
                          size: 36,
                          color: c.primary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 40),

            // ── Status Text ─────────────────────────────────────
            Text(
              'Searching for a stranger…',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: c.textHigh,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ll be paired with someone random.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: c.textMid,
              ),
            ),

            const SizedBox(height: 48),

            // ── Cancel Button ───────────────────────────────────
            OutlinedButton.icon(
              onPressed: _cancelSearch,
              icon: Icon(Icons.close_rounded, color: c.error, size: 18),
              label: Text(
                'Cancel Search',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: c.error,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: c.error.withOpacity(0.4)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Privacy note ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.visibility_off_outlined,
                      size: 16, color: c.textLow),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Your identity is hidden. Chat as a stranger.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: c.textLow,
                      ),
                      textAlign: TextAlign.center,
                    ),
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

/// Custom painter for radar-style expanding ripple circles.
class _RadarRipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RadarRipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final rippleProgress = (progress + i * 0.33) % 1.0;
      final radius = maxRadius * rippleProgress;
      final opacity = (1.0 - rippleProgress).clamp(0.0, 0.4);

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RadarRipplePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Re-export Flutter's AnimatedBuilder as AnimatedBuilder2 — the same
/// helper already used in the home screen's FAB animation.
class AnimatedBuilder2 extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder2({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) => builder(context, child);
}
