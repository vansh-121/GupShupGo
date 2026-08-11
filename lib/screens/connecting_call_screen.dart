import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/provider/call_state_provider.dart';
import 'package:video_chat_app/screens/call_screen.dart';
import 'package:video_chat_app/services/call_signaling_service.dart';
import 'package:video_chat_app/services/fcm_service.dart';

/// A lightweight pre-call screen that shows a "connecting" animation while the
/// signaling document and FCM push are set up. Once the async work finishes it
/// automatically navigates to [CallScreen].
///
/// This screen is displayed immediately when the user taps "call", so the UI
/// feels responsive even during a cold-start where the Firestore writes and
/// FCM sends can take 1–3 seconds.
class ConnectingCallScreen extends StatefulWidget {
  final String currentUserId;
  final String calleeId;
  final String calleeName;
  final String? calleePhotoUrl;
  final bool isAudioOnly;

  const ConnectingCallScreen({
    super.key,
    required this.currentUserId,
    required this.calleeId,
    required this.calleeName,
    this.calleePhotoUrl,
    this.isAudioOnly = false,
  });

  @override
  State<ConnectingCallScreen> createState() => _ConnectingCallScreenState();
}

class _ConnectingCallScreenState extends State<ConnectingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String _statusText = 'Connecting...';
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the avatar ring.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _runPreCallSetup();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Run the signaling + FCM setup, then navigate to CallScreen.
  Future<void> _runPreCallSetup() async {
    try {
      final channelId = CallSignalingService.generateChannelId();

      // Update provider state
      if (mounted) {
        Provider.of<CallStateNotifier>(context, listen: false)
            .updateState(CallState.Calling);
      }

      if (mounted) setState(() => _statusText = 'Setting up call...');

      // Create the Firestore signaling document
      await CallSignalingService.createCallDocument(
        channelId: channelId,
        callerId: widget.currentUserId,
        calleeId: widget.calleeId,
      );

      if (mounted) setState(() => _statusText = 'Notifying ${widget.calleeName}...');

      // Send the FCM push notification
      await FCMService().sendCallNotification(
        widget.calleeId,
        widget.currentUserId,
        channelId,
        isAudioOnly: widget.isAudioOnly,
      );

      if (mounted) setState(() => _statusText = 'Ringing...');

      // Small delay so the user sees "Ringing..." before the transition
      await Future.delayed(const Duration(milliseconds: 300));

      // Navigate to the actual call screen
      _navigateToCallScreen(channelId);
    } catch (e) {
      print('Error in pre-call setup: $e');
      if (mounted) {
        setState(() => _statusText = 'Failed to connect');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start call: $e')),
        );
        // Go back after a short delay so the user can read the error
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    }
  }

  void _navigateToCallScreen(String channelId) {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CallScreen(
          channelId: channelId,
          isCaller: true,
          calleeId: widget.calleeId,
          calleeName: widget.calleeName,
          isAudioOnly: widget.isAudioOnly,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAudio = widget.isAudioOnly;
    final Color accentColor =
        isAudio ? const Color(0xFF00A884) : const Color(0xFF4FC3F7);

    return Scaffold(
      backgroundColor: const Color(0xFF111B21),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isAudio
                ? const [
                    Color(0xFF00A884),
                    Color(0xFF005C4B),
                    Color(0xFF111B21),
                    Color(0xFF111B21),
                  ]
                : const [
                    Color(0xFF1A1A2E),
                    Color(0xFF16213E),
                    Color(0xFF0F3460),
                    Color(0xFF0A0A0A),
                  ],
            stops: const [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              // ── Encrypted label ──
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
              const SizedBox(height: 40),
              // ── Callee name ──
              Text(
                widget.calleeName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              // ── Call type label ──
              Text(
                isAudio ? 'GupShup Audio' : 'GupShup Video',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              const Spacer(flex: 1),
              // ── Pulsing avatar with glowing ring ──
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  width: 172,
                  height: 172,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withOpacity(0.5),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.20),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.white12,
                    backgroundImage: widget.calleePhotoUrl != null
                        ? NetworkImage(widget.calleePhotoUrl!)
                        : null,
                    child: widget.calleePhotoUrl == null
                        ? const Icon(Icons.person,
                            size: 75, color: Colors.white70)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // ── Status text (animated crossfade) ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _statusText,
                  key: ValueKey(_statusText),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // ── Indeterminate progress indicator ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 80),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    minHeight: 4,
                  ),
                ),
              ),
              const Spacer(flex: 2),
              // ── Cancel button ──
              GestureDetector(
                onTap: () {
                  if (mounted) Navigator.of(context).pop();
                },
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEA0038),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.call_end,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
