import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_chat_app/services/call_signaling_service.dart';
import 'package:video_chat_app/services/fcm_service.dart';
import 'package:video_chat_app/utils/avatar_image.dart';

/// Full-screen "X wants to share their screen" request UI, shown to the viewer
/// before any screen is displayed. Modelled on [IncomingCallScreen]: same
/// gradient and layout, but Accept opens the screen-share viewer (via
/// [FCMService.openScreenShareViewer]) instead of a call.
///
/// Accept/Reject are signalled through the shared `calls/{channelId}` document
/// so the sharer reacts: accepting flips the status to `answered` (the sharer
/// then starts capturing and broadcasting); rejecting flips it to `declined`.
class IncomingScreenShareScreen extends StatefulWidget {
  final String channelId;
  final String sharerId;
  final String sharerName;
  final String? sharerPhotoUrl;

  const IncomingScreenShareScreen({
    super.key,
    required this.channelId,
    required this.sharerId,
    required this.sharerName,
    this.sharerPhotoUrl,
  });

  @override
  State<IncomingScreenShareScreen> createState() =>
      _IncomingScreenShareScreenState();
}

class _IncomingScreenShareScreenState extends State<IncomingScreenShareScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _autoDismissTimer;
  StreamSubscription<CallSignalStatus?>? _signalingSubscription;
  bool _isResponding = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Local fallback: slightly longer than the sharer's 45s request timeout, so
    // the sharer's `missed` signal normally dismisses us first (below). This
    // only fires if that write never lands (e.g. sharer offline).
    _autoDismissTimer = Timer(const Duration(seconds: 50), () {
      if (mounted) _dismiss();
    });

    // Sharer cancelled, declined elsewhere, or timed out → dismiss.
    _signalingSubscription =
        CallSignalingService.listenToCallStatus(widget.channelId)
            .listen((status) {
      if (!mounted || _isResponding) return;
      if (status == CallSignalStatus.ended ||
          status == CallSignalStatus.declined ||
          status == CallSignalStatus.missed) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _autoDismissTimer?.cancel();
    _signalingSubscription?.cancel();
    super.dispose();
  }

  void _cancelListeners() {
    _autoDismissTimer?.cancel();
    _signalingSubscription?.cancel();
  }

  /// Pops this request screen (used by auto-timeout and the signaling listener).
  void _dismiss() {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _accept() async {
    if (_isResponding) return;
    _isResponding = true;

    // Tell the sharer to start capturing + broadcasting, and only open the
    // viewer once that signal is actually written. answerCall swallows its
    // errors, so without gating on the result a transient write failure would
    // leave the viewer on a black screen while the sharer — never told we
    // accepted — never starts capture.
    final answered = await CallSignalingService.answerCall(widget.channelId);
    if (!mounted) return;
    if (!answered) {
      _isResponding = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't accept the screen share — check your "
              'connection and try again.'),
        ),
      );
      return;
    }

    _cancelListeners();

    // Pop the request screen first so the viewer isn't stacked on top of it,
    // then open the viewer (owns the session + full-screen view).
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    FCMService.openScreenShareViewer(
      channelId: widget.channelId,
      sharerName: widget.sharerName,
    );
  }

  void _reject() {
    if (_isResponding) return;
    _isResponding = true;
    _cancelListeners();

    // Signal "declined" so the sharer tears down its pending request.
    CallSignalingService.declineCall(widget.channelId);

    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        widget.sharerPhotoUrl != null && widget.sharerPhotoUrl!.isNotEmpty;

    return PopScope(
      canPop: false, // Force an explicit Accept / Reject choice.
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF00A884),
                Color(0xFF005C4B),
                Color(0xFF111B21),
                Color(0xFF111B21),
              ],
              stops: [0.0, 0.3, 0.6, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, color: Colors.white60, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'End-to-end encrypted',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 60),

                const Text(
                  'Incoming Screen Share',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 40),

                // Animated avatar with pulse ring
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.white24,
                      backgroundImage: hasPhoto
                          ? avatarImage(widget.sharerPhotoUrl!, radius: 65)
                          : null,
                      child: !hasPhoto
                          ? const Icon(Icons.person,
                              size: 65, color: Colors.white70)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  widget.sharerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'wants to share their screen',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),

                const Spacer(),

                // Reject / Accept buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Reject
                      Column(
                        children: [
                          GestureDetector(
                            onTap: _reject,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Reject',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      // Accept
                      Column(
                        children: [
                          GestureDetector(
                            onTap: _accept,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00A884),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.screen_share_rounded,
                                color: Colors.white,
                                size: 34,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Accept',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
