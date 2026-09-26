import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:video_chat_app/services/secure_screen_service.dart';
import 'package:video_chat_app/widgets/video_message_widgets.dart'
    show resolveVideoDisplayAspect;

/// Full-screen viewer for an anonymous-chat **view-once** photo or video.
///
/// Unlike the E2EE [ViewOnceViewerScreen], there is no key to destroy here —
/// anonymous media is a plaintext upload with no Signal session to seal it (see
/// `AnonymousChatService.uploadAnonymousMedia`). So this viewer makes the two
/// guarantees it actually can:
///
///  1. **Capture is blocked while it is open.** [SecureScreenService] sets
///     FLAG_SECURE before the first frame on Android, covering screenshots,
///     recordings and the recent-apps thumbnail. iOS has no equivalent and the
///     footer says so rather than implying one.
///  2. **It opens once.** The caller marks the message consumed the instant it
///     pushes this route, so the bubble flips to "Opened" and can't be reopened
///     for the life of the session — the same local, resets-on-leave model the
///     blur gate on received media already uses.
///
/// What it deliberately does **not** claim is that the bytes are destroyed: the
/// object lives in Storage until the `anonymous_media/` lifecycle rule reaps it,
/// and a determined receiver on a rooted device could still capture the frame.
/// This is view-once as a courtesy, not as cryptography — which is the honest
/// ceiling for an unencrypted stranger upload.
class AnonymousViewOnceViewer extends StatefulWidget {
  const AnonymousViewOnceViewer({
    super.key,
    required this.isVideo,
    required this.mediaUrl,
    this.thumbnailBase64,
  });

  final bool isVideo;
  final String mediaUrl;
  final String? thumbnailBase64;

  @override
  State<AnonymousViewOnceViewer> createState() =>
      _AnonymousViewOnceViewerState();
}

class _AnonymousViewOnceViewerState extends State<AnonymousViewOnceViewer> {
  VideoPlayerController? _controller;
  double? _aspect;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    // Before the first frame, so there is never a window where the media is
    // visible without capture blocking.
    SecureScreenService.instance.enable();
    if (widget.isVideo) {
      _initVideo();
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    SecureScreenService.instance.disable();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initVideo() async {
    final controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl));
    _controller = controller;
    try {
      await controller.initialize();
      final aspect = await resolveVideoDisplayAspect(
        posterBase64: widget.thumbnailBase64,
        filePath: null,
      );
      if (!mounted) return;
      setState(() {
        _aspect = aspect;
        _loading = false;
      });
      controller
        ..setLooping(false)
        ..play();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    setState(() => c.value.isPlaying ? c.pause() : c.play());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.isVideo ? 'Video · View once' : 'Photo · View once',
          style: GoogleFonts.poppins(fontSize: 15, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: Center(child: _buildContent())),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const CircularProgressIndicator(color: Colors.white);
    }
    if (_error) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          "Couldn't open this media.",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
        ),
      );
    }

    final controller = _controller;
    if (widget.isVideo && controller != null) {
      return GestureDetector(
        onTap: _togglePlay,
        child: AspectRatio(
          aspectRatio: _aspect ??
              (controller.value.aspectRatio == 0
                  ? 16 / 9
                  : controller.value.aspectRatio),
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(controller),
              Align(
                alignment: Alignment.bottomCenter,
                child: VideoProgressIndicator(controller, allowScrubbing: true),
              ),
              if (!controller.value.isPlaying)
                const Icon(Icons.play_arrow_rounded,
                    color: Colors.white70, size: 64),
            ],
          ),
        ),
      );
    }

    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: Image.network(
        widget.mediaUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.broken_image_rounded,
          color: Colors.white54,
          size: 48,
        ),
      ),
    );
  }

  /// Same honest caveat as the E2EE viewer: on Android the flag genuinely
  /// blocks capture; on iOS there is no API that can.
  Widget _buildFooter() {
    final enforceable = SecureScreenService.instance.isEnforceable;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            enforceable ? Icons.screenshot_monitor_rounded : Icons.info_outline,
            size: 15,
            color: Colors.white38,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              enforceable
                  ? "Screenshots are blocked. You can't open this again."
                  : "You can't open this again. Screenshots can't be blocked on iOS.",
              style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}
