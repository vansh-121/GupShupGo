import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:video_chat_app/screens/call_screen.dart';

/// Full-screen incoming call UI shown when the app is in the foreground.
///
/// Mirrors the native CallKit full-screen UI but uses the same green/teal
/// gradient as the in-call screen (CallScreen) for visual consistency.
class IncomingCallScreen extends StatefulWidget {
  final String channelId;
  final String callerId;
  final String callerName;
  final String? callerPhotoUrl;
  final bool isAudioOnly;

  const IncomingCallScreen({
    Key? key,
    required this.channelId,
    required this.callerId,
    required this.callerName,
    this.callerPhotoUrl,
    this.isAudioOnly = false,
  }) : super(key: key);

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _autoDeclineTimer;
  StreamSubscription? _callKitSubscription;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the avatar ring
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Auto-decline after 45 seconds (matches CallKit timeout)
    _autoDeclineTimer = Timer(const Duration(seconds: 45), () {
      if (mounted) _dismissScreen();
    });

    // Listen for CallKit events to auto-dismiss when:
    // - Caller hangs up (actionCallEnded)
    // - Call times out (actionCallTimeout)
    // - User declines from notification (actionCallDecline)
    _callKitSubscription =
        FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null || !mounted) return;

      if (event.event == Event.actionCallDecline ||
          event.event == Event.actionCallTimeout ||
          event.event == Event.actionCallEnded) {
        _dismissScreen();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _autoDeclineTimer?.cancel();
    _callKitSubscription?.cancel();
    super.dispose();
  }

  /// Safely pops this screen (used by auto-timeout and CallKit event listener).
  void _dismissScreen() {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _acceptCall() {
    // Cancel listeners FIRST — endCall fires actionCallEnded which
    // would otherwise trigger _dismissScreen and kill the navigation.
    _callKitSubscription?.cancel();
    _autoDeclineTimer?.cancel();

    // Stop the CallKit ringtone/notification
    FlutterCallkitIncoming.endCall(widget.channelId);

    // Navigate to the call screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CallScreen(
          channelId: widget.channelId,
          isCaller: false,
          calleeId: widget.callerId,
          calleeName: widget.callerName,
          isAudioOnly: widget.isAudioOnly,
        ),
      ),
    );
  }

  void _declineCall() {
    // Cancel listeners FIRST
    _callKitSubscription?.cancel();
    _autoDeclineTimer?.cancel();

    // Stop the CallKit ringtone/notification
    FlutterCallkitIncoming.endCall(widget.channelId);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button from dismissing
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
                // Encrypted label
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

                // Call type label
                Text(
                  widget.isAudioOnly
                      ? 'Incoming Voice Call'
                      : 'Incoming Video Call',
                  style: const TextStyle(
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
                      backgroundImage:
                          widget.callerPhotoUrl != null &&
                                  widget.callerPhotoUrl!.isNotEmpty
                              ? NetworkImage(widget.callerPhotoUrl!)
                              : null,
                      child: widget.callerPhotoUrl == null ||
                              widget.callerPhotoUrl!.isEmpty
                          ? const Icon(Icons.person,
                              size: 65, color: Colors.white70)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Caller name
                Text(
                  widget.callerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isAudioOnly ? 'Voice Call' : 'Video Call',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),

                const Spacer(),

                // Accept / Decline buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Decline button
                      Column(
                        children: [
                          GestureDetector(
                            onTap: _declineCall,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.call_end,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Decline',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      // Accept button
                      Column(
                        children: [
                          GestureDetector(
                            onTap: _acceptCall,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00A884),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.isAudioOnly
                                    ? Icons.call
                                    : Icons.videocam,
                                color: Colors.white,
                                size: 36,
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
