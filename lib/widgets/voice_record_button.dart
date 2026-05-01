import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/services/voice_recorder_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// WhatsApp-style hold-to-record microphone button.
///
/// When the user long-presses:
///  • Recording starts and a recording UI overlay appears.
///  • Sliding left cancels the recording.
///  • Releasing the press sends the voice note.
///
/// [onVoiceSent] is called with the path to the .m4a file and the duration
/// in seconds once the user releases their finger.
class VoiceRecordButton extends StatefulWidget {
  final VoiceRecorderService recorderService;
  final Future<void> Function(String filePath, int durationSeconds) onVoiceSent;
  final bool enabled;

  const VoiceRecordButton({
    super.key,
    required this.recorderService,
    required this.onVoiceSent,
    this.enabled = true,
  });

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton>
    with SingleTickerProviderStateMixin {
  String? _recordingPath;
  bool _isCancelled = false;
  double _slideOffset = 0;

  // Animation for the pulsing mic ring while recording
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _onLongPressStart(LongPressStartDetails details) async {
    if (!widget.enabled) return;
    HapticFeedback.mediumImpact();
    _isCancelled = false;
    _slideOffset = 0;

    final path = await widget.recorderService.startRecording();
    if (path != null) {
      _recordingPath = path;
      _pulseController.repeat(reverse: true);
    }
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!widget.recorderService.isRecording) return;

    setState(() {
      _slideOffset = details.offsetFromOrigin.dx;
    });

    // If slid far enough left, mark as cancelled
    if (_slideOffset < -100 && !_isCancelled) {
      _isCancelled = true;
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _onLongPressEnd(LongPressEndDetails details) async {
    if (!widget.recorderService.isRecording) return;

    _pulseController.stop();
    _pulseController.reset();

    if (_isCancelled) {
      await widget.recorderService.cancelRecording();
      _recordingPath = null;
      setState(() {
        _slideOffset = 0;
        _isCancelled = false;
      });
      return;
    }

    final durationSeconds = widget.recorderService.elapsed.inSeconds;
    final path = await widget.recorderService.stopRecording();

    if (path != null && durationSeconds > 0) {
      await widget.onVoiceSent(path, durationSeconds);
    }

    setState(() {
      _slideOffset = 0;
      _recordingPath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final isRecording = widget.recorderService.isRecording;

    // When recording, show full-width recording overlay
    if (isRecording) {
      return _buildRecordingOverlay(c);
    }

    // Default: mic button
    return GestureDetector(
      onLongPressStart: _onLongPressStart,
      onLongPressMoveUpdate: _onLongPressMoveUpdate,
      onLongPressEnd: _onLongPressEnd,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isRecording ? _pulseAnimation.value : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isRecording ? c.error : c.primary,
                shape: BoxShape.circle,
                boxShadow: isRecording
                    ? [
                        BoxShadow(
                          color: c.error.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.mic_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecordingOverlay(AppThemeColors c) {
    return Expanded(
      child: Row(
        children: [
          // ── Slide-to-cancel indicator ──────────────────────────
          Expanded(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _isCancelled ? 0.3 : 1.0,
              child: Row(
                children: [
                  // Recording duration
                  _PulsingDot(color: c.error),
                  const SizedBox(width: 8),
                  ListenableBuilder(
                    listenable: widget.recorderService,
                    builder: (context, _) {
                      return Text(
                        VoiceRecorderService.formatDuration(
                            widget.recorderService.elapsed),
                        style: GoogleFonts.poppins(
                          color: c.textHigh,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFeatures: [
                            const FontFeature.tabularFigures(),
                          ],
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  if (!_isCancelled)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chevron_left_rounded,
                            color: c.textLow, size: 18),
                        Text(
                          'Slide to cancel',
                          style: GoogleFonts.poppins(
                            color: c.textLow,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Release to cancel',
                      style: GoogleFonts.poppins(
                        color: c.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),

          // ── Mic button (pulsing) ──────────────────────────────
          GestureDetector(
            onLongPressStart: _onLongPressStart,
            onLongPressMoveUpdate: _onLongPressMoveUpdate,
            onLongPressEnd: _onLongPressEnd,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: c.error.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A small red dot that pulses on/off — indicates active recording.
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Opacity(
        opacity: _animation.value,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
