import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/services/anonymous_chat_service.dart';
import 'package:video_chat_app/screens/anonymous/anonymous_chat_screen.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// Lobby screen with a radar ripple animation while searching for
/// a random stranger to pair with. Shows a live "online now" count so the
/// search never feels like it's spinning into a void.
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
  late AnimationController _pulseController;
  bool _isSearching = true;
  bool _navigated = false;

  /// Retry timer — if no match found immediately, periodically re-attempt.
  Timer? _retryTimer;

  /// Polls the live online count for the pill. Null until the first read lands.
  Timer? _onlineTimer;
  int? _onlineCount;

  static const _onlinePollInterval = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _startSearching();
    _startOnlinePolling();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _pulseController.dispose();
    _queueSub?.cancel();
    _retryTimer?.cancel();
    _onlineTimer?.cancel();
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

  /// Fetches the live online count now, then on a slow poll for the life of the
  /// screen. Fire-and-forget: a failed read just leaves the previous value.
  void _startOnlinePolling() {
    _refreshOnlineCount();
    _onlineTimer = Timer.periodic(_onlinePollInterval, (_) {
      _refreshOnlineCount();
    });
  }

  Future<void> _refreshOnlineCount() async {
    try {
      final n = await _service.onlineUsersCount();
      if (mounted) setState(() => _onlineCount = n);
    } catch (_) {
      // Keep the last known value; the pill falls back to "Connecting…".
    }
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

  /// Leaves the queue and returns to the previous screen.
  ///
  /// The pop happens FIRST and the queue cleanup is fired unawaited. The delete
  /// is a Firestore write, and when the network is offline/flaky its Future does
  /// not resolve — so awaiting it before popping (the old bug) left the user
  /// stuck on a frozen screen with the button doing nothing. Popping first makes
  /// Cancel/back instant; the local write flushes on its own when connectivity
  /// returns, and the queue's own re-verify in `findAndPair` guards against a
  /// stale entry that never flushed.
  void _cancelSearch() {
    if (_navigated) return;
    _isSearching = false;
    _retryTimer?.cancel();
    _queueSub?.cancel();
    _onlineTimer?.cancel();
    // Fire-and-forget — must not block the pop.
    _service.leaveQueue(widget.currentUserId);
    if (mounted && Navigator.canPop(context)) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);

    return PopScope(
      // We own the pop so that OS/gesture back also leaves the queue instead of
      // stranding a `waiting` entry that would match a stranger into a dead room.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _cancelSearch();
      },
      child: Scaffold(
        backgroundColor: c.surface,
        appBar: AppBar(
          backgroundColor: c.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
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
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),

              // ── Radar hero: expanding ripples behind a brand puck ─────
              _RadarHero(
                rippleController: _rippleController,
                color: c.primary,
                isDark: c.isDark,
              ),

              const SizedBox(height: 44),

              // ── Status text ───────────────────────────────────────────
              Text(
                'Finding someone for you…',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: c.textHigh,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Hang tight — you\'ll be paired with a random stranger.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    color: c.textMid,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Live online pill ──────────────────────────────────────
              _LiveOnlinePill(
                count: _onlineCount,
                pulseController: _pulseController,
                colors: c,
              ),

              const Spacer(flex: 3),

              // ── Cancel button ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _cancelSearch,
                    icon: Icon(Icons.close_rounded, color: c.error, size: 18),
                    label: Text(
                      'Cancel Search',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: c.error,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: c.error.withOpacity(0.35)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Privacy note ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.visibility_off_outlined,
                        size: 15, color: c.textLow),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Your identity stays hidden. Chat as a stranger.',
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

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// The centered radar: three expanding ripple rings behind a gradient puck
/// carrying the search glyph. The gradient reuses the home "Connect with a
/// Stranger" banner's brand colors so the two surfaces read as one feature.
class _RadarHero extends StatelessWidget {
  final AnimationController rippleController;
  final Color color;
  final bool isDark;

  const _RadarHero({
    required this.rippleController,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: AnimatedBuilder(
        animation: rippleController,
        builder: (context, child) {
          return CustomPaint(
            painter: _RadarRipplePainter(
              progress: rippleController.value,
              color: color,
            ),
            child: child,
          );
        },
        child: Center(
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF3D2068), Color(0xFF4A1A6B)]
                    : const [Color(0xFF6C5CE7), Color(0xFFD65DB1)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.person_search_rounded,
              size: 44,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// A rounded "live" pill: a pulsing green dot plus a short status line driven by
/// the online count. Falls back gracefully before the first read and when nobody
/// else is around.
class _LiveOnlinePill extends StatelessWidget {
  final int? count;
  final AnimationController pulseController;
  final AppThemeColors colors;

  const _LiveOnlinePill({
    required this.count,
    required this.pulseController,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final n = count;

    final String label;
    final bool live;
    if (n == null) {
      label = 'Connecting…';
      live = false;
    } else if (n <= 0) {
      label = 'Waiting for others to come online…';
      live = false;
    } else {
      label = '$n online now';
      live = true;
    }

    final dotColor = live ? c.online : c.textLow;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: (live ? c.online : c.textLow).withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (live ? c.online : c.textLow).withOpacity(0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing dot (steady when not live).
          AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              final t = live ? pulseController.value : 0.0;
              return Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  boxShadow: live
                      ? [
                          BoxShadow(
                            color: dotColor.withOpacity(0.5 * (1 - t)),
                            blurRadius: 6,
                            spreadRadius: 3 * t,
                          ),
                        ]
                      : null,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: live ? c.textHigh : c.textMid,
            ),
          ),
        ],
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
