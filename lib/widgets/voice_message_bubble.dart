import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/services/voice_recorder_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// A WhatsApp-style voice message player bubble.
///
/// Shows a play/pause button, a waveform-like seek bar, and duration.
/// Works with both network URLs ([mediaUrl]) and local files ([localFilePath]).
class VoiceMessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;

  const VoiceMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  final AudioPlayer _player = AudioPlayer();

  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();

    // Seed duration from the model if available
    if (widget.message.audioDuration != null) {
      _duration = Duration(seconds: widget.message.audioDuration!);
    }

    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
      return;
    }

    // Prefer local file, fall back to network URL
    final localPath = widget.message.localFilePath;
    final networkUrl = widget.message.mediaUrl;

    if (localPath != null && File(localPath).existsSync()) {
      await _player.play(DeviceFileSource(localPath));
    } else if (networkUrl != null) {
      await _player.play(UrlSource(networkUrl));
    } else {
      return;
    }

    setState(() => _isPlaying = true);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final progress =
        _duration.inMilliseconds > 0
            ? _position.inMilliseconds / _duration.inMilliseconds
            : 0.0;

    final durationText = _isPlaying || _position > Duration.zero
        ? VoiceRecorderService.formatDuration(_position)
        : VoiceRecorderService.formatDuration(_duration);

    final accentColor = widget.isMe ? Colors.white : c.primary;
    final trackBg = widget.isMe
        ? Colors.white.withOpacity(0.25)
        : c.primary.withOpacity(0.15);
    final timeColor = widget.isMe
        ? Colors.white.withOpacity(0.7)
        : c.textLow;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Play / Pause button ──────────────────────────────────
        GestureDetector(
          onTap: _togglePlay,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(widget.isMe ? 0.25 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: accentColor,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // ── Waveform + slider ────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Faux waveform bars behind the progress track
              SizedBox(
                height: 28,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return _WaveformTrack(
                      width: constraints.maxWidth,
                      progress: progress,
                      activeColor: accentColor,
                      inactiveColor: trackBg,
                    );
                  },
                ),
              ),
              const SizedBox(height: 2),
              Text(
                durationText,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: timeColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom painter that draws a WhatsApp-style waveform bar visualization.
class _WaveformTrack extends StatelessWidget {
  final double width;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  const _WaveformTrack({
    required this.width,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, 28),
      painter: _WaveformPainter(
        progress: progress,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  _WaveformPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  // Pre-computed pseudo-random waveform heights (0.0 – 1.0).
  // Repeating pattern simulates voice waveform bars.
  static const _bars = [
    0.3, 0.5, 0.8, 0.6, 1.0, 0.4, 0.7, 0.9, 0.35, 0.65,
    0.85, 0.45, 0.7, 0.55, 0.9, 0.3, 0.6, 1.0, 0.5, 0.75,
    0.4, 0.85, 0.55, 0.7, 0.3, 0.9, 0.6, 0.45, 0.8, 0.5,
    0.65, 0.35, 0.75, 0.55, 0.9, 0.4, 0.7, 0.6, 0.85, 0.5,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const barWidth = 2.5;
    const gap = 1.5;
    final barCount = ((size.width + gap) / (barWidth + gap)).floor();
    final maxHeight = size.height * 0.9;
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + gap);
      final normalizedProgress = progress * size.width;
      final isActive = x <= normalizedProgress;

      final heightFactor = _bars[i % _bars.length];
      final barHeight = maxHeight * heightFactor * 0.5;

      final paint = Paint()
        ..color = isActive ? activeColor : inactiveColor
        ..strokeCap = StrokeCap.round
        ..strokeWidth = barWidth
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, centerY),
          width: barWidth,
          height: barHeight.clamp(3.0, maxHeight),
        ),
        const Radius.circular(1.5),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress ||
      old.activeColor != activeColor ||
      old.inactiveColor != inactiveColor;
}
