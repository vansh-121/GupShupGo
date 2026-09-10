import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// Completion of a Firebase [UploadTask] as a stream of `0.0`–`1.0`, derived
/// from its real byte progress — the input for WhatsApp-style upload percentage.
///
/// Snapshots whose `totalBytes` isn't known yet (Firebase reports `0`/`-1`
/// before the first chunk) are skipped so a consumer never divides by zero or
/// paints a bogus reading. A snapshot with **zero** bytes transferred is also
/// skipped: it carries no real progress, and emitting `0.0` would make the UI
/// paint a literal "0%" through the entire pre-first-byte round-trip. Holding
/// off until the first non-zero fraction lets the call site show an
/// indeterminate spinner during that wait (progress still `null`) and switch
/// to the climbing percentage only once bytes are actually moving — so a small
/// one-chunk upload shows a brief spinner rather than a frozen "0%".
///
/// Failures are deliberately **not** swallowed: a `TaskState.error`/`canceled`
/// surfaces as a stream error and the awaited task future throws, so the call
/// site can reset its progress in a `finally` and report the failure in a
/// `catch` (see the chat/profile upload sites).
Stream<double> uploadProgress(UploadTask task) {
  return task.snapshotEvents
      .where((s) => s.totalBytes > 0 && s.bytesTransferred > 0)
      .map((s) => (s.bytesTransferred / s.totalBytes).clamp(0.0, 1.0));
}

/// A small determinate progress ring with a centred percentage, for surfacing
/// an upload's real progress at a compact slot (the composer paperclip, a
/// profile-photo avatar).
///
/// [progress] is `0.0`–`1.0`. To avoid a one-frame flash on very fast uploads,
/// the ring delays its own first paint by [showDelay], rendering [placeholder]
/// (nothing, by default) until then. Because call sites mount this only while an
/// upload is in flight, an upload that finishes inside that window unmounts the
/// ring before it ever appears — so a sub-[showDelay] upload shows no flicker,
/// while a slower one reveals the ring and tracks the percentage. Pass the
/// slot's idle widget (e.g. the paperclip icon) as [placeholder] so the reveal
/// window looks identical to the resting state.
class UploadProgressRing extends StatefulWidget {
  const UploadProgressRing({
    super.key,
    required this.progress,
    this.size = 30,
    this.showDelay = const Duration(milliseconds: 150),
    this.placeholder = const SizedBox.shrink(),
  });

  final double progress;
  final double size;
  final Duration showDelay;
  final Widget placeholder;

  @override
  State<UploadProgressRing> createState() => _UploadProgressRingState();
}

class _UploadProgressRingState extends State<UploadProgressRing> {
  bool _visible = false;
  Timer? _revealTimer;

  @override
  void initState() {
    super.initState();
    _revealTimer = Timer(widget.showDelay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return widget.placeholder;

    final c = AppThemeColors.of(context);
    final value = widget.progress.clamp(0.0, 1.0);
    final pct = (value * 100).round();

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 2.5,
            backgroundColor: c.border,
            valueColor: AlwaysStoppedAnimation<Color>(c.primary),
          ),
          Text(
            '$pct',
            style: GoogleFonts.poppins(
              fontSize: widget.size * 0.3,
              fontWeight: FontWeight.w600,
              color: c.textMid,
            ),
          ),
        ],
      ),
    );
  }
}
