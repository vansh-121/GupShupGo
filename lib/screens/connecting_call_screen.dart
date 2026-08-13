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

  /// Set when the user taps Cancel. [_runPreCallSetup] checks this after every
  /// await so it can stop before notifying the callee — or retract an
  /// already-created call — instead of blindly finishing the setup.
  bool _cancelled = false;

  /// The signaling channel id, hoisted to state so [_cancelCall] can retract
  /// the call document even while [_runPreCallSetup] is still mid-flight.
  String? _channelId;

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
      _channelId = channelId;

      // Cancelled before any work started — nothing to clean up.
      if (_cancelled) return;

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

      // Cancelled while the document was being created — retract it before we
      // ever notify the callee, so no push is sent for an abandoned call.
      if (_cancelled) {
        await CallSignalingService.endCall(channelId);
        return;
      }

      if (mounted) {
        setState(() => _statusText = 'Notifying ${widget.calleeName}...');
      }

      // Send the FCM push notification
      await FCMService().sendCallNotification(
        widget.calleeId,
        widget.currentUserId,
        channelId,
        isAudioOnly: widget.isAudioOnly,
      );

      // Cancelled while the push was in flight — the callee may already be
      // ringing, so mark the call ended. Their IncomingCallScreen listens for
      // this and dismisses, instead of ringing for a caller who has left with
      // no CallScreen to clean up the signaling state.
      if (_cancelled) {
        await CallSignalingService.endCall(channelId);
        return;
      }

      if (mounted) setState(() => _statusText = 'Ringing...');

      // Small delay so the user sees "Ringing..." before the transition
      await Future.delayed(const Duration(milliseconds: 300));

      if (_cancelled) {
        await CallSignalingService.endCall(channelId);
        return;
      }

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

  /// Cancels the outgoing call. Setup may still be running (creating the
  /// signaling document / sending the push), so flag the cancellation for
  /// [_runPreCallSetup] to observe, and best-effort retract the call document
  /// if it already exists — otherwise the callee could keep ringing for a call
  /// the caller has already abandoned.
  void _cancelCall() {
    _cancelled = true;

    final id = _channelId;
    if (id != null) {
      // Fire-and-forget immediate retraction for the common case where the
      // document already exists. If it doesn't yet, this is a harmless no-op —
      // _runPreCallSetup re-checks _cancelled after the create and ends it.
      CallSignalingService.endCall(id);
    }

    if (mounted) {
      Provider.of<CallStateNotifier>(context, listen: false)
          .updateState(CallState.Idle);
      Navigator.of(context).pop();
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

    return PopScope(
      // Setup runs asynchronously (create signaling doc + send push), so a
      // system back — like the Cancel button — must route through _cancelCall
      // to retract the call rather than silently popping and leaving it running.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _cancelCall();
      },
      child: Scaffold(
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
                  onTap: _cancelCall,
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
      ),
    );
  }
}
