import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:video_chat_app/services/secure_screen_service.dart';
import 'package:video_chat_app/widgets/video_message_widgets.dart'
    show resolveVideoDisplayAspect;

/// Full-screen viewer for a **plaintext view-once** photo or video — the kind
/// sent over anonymous chat (a Firebase Storage URL) or the offline mesh (a
/// local file transferred peer-to-peer). Either source is supported: pass
/// [localFilePath] when the bytes are already on disk, [mediaUrl] otherwise.
///
/// Unlike the E2EE [ViewOnceViewerScreen] there is no key to destroy here —
/// these media are never encrypted (there is no Signal session with a stranger,
/// and the mesh has no server at all). So this viewer makes the two guarantees
/// it actually can:
///
///  1. **Capture is blocked while it is open.** [SecureScreenService] sets
///     FLAG_SECURE before the first frame on Android, covering screenshots,
///     recordings and the recent-apps thumbnail. iOS has no equivalent and the
///     footer says so rather than implying one.
///  2. **It opens once.** The caller marks the message consumed the instant it
///     pushes this route, so the bubble flips to "Opened" and can't be reopened
///     for the life of the session.
///
/// What it deliberately does **not** claim is that the bytes are destroyed: an
/// anonymous object lives in Storage until its lifecycle rule reaps it, a mesh
/// file lives in the app's `mesh_*` dir, and a determined receiver on a rooted
/// device could still capture the frame. This is view-once as a courtesy, not
/// as cryptography — the honest ceiling for an unencrypted transfer.
class PlaintextViewOnceViewer extends StatefulWidget {
  const PlaintextViewOnceViewer({
    super.key,
    required this.isVideo,
    this.mediaUrl,
    this.localFilePath,
    this.thumbnailBase64,
  }) : assert(mediaUrl != null || localFilePath != null,
            'need a URL or a local file to show');

  final bool isVideo;

  /// Network source (anonymous chat). Used only when [localFilePath] is null.
  final String? mediaUrl;

  /// On-disk source (offline mesh). Preferred over [mediaUrl] when present.
  final String? localFilePath;

  final String? thumbnailBase64;

  @override
  State<PlaintextViewOnceViewer> createState() =>
      _PlaintextViewOnceViewerState();
}

class _PlaintextViewOnceViewerState extends State<PlaintextViewOnceViewer> {
  VideoPlayerController? _controller;
  double? _aspect;
  bool _loading = true;
  bool _error = false;

  /// A local file, when one was given and it still exists — the mesh source.
  File? get _localFile {
    final path = widget.localFilePath;
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    return file.existsSync() ? file : null;
  }

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
    final local = _localFile;
    final controller = local != null
        ? VideoPlayerController.file(local)
        : VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl!));
    _controller = controller;
    try {
      await controller.initialize();
      final aspect = await resolveVideoDisplayAspect(
        posterBase64: widget.thumbnailBase64,
        filePath: local?.path,
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

    // Image: prefer the on-disk copy, fall back to the network URL.
    final local = _localFile;
    final Widget image = local != null
        ? Image.file(local, fit: BoxFit.contain)
        : Image.network(
            widget.mediaUrl!,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_rounded,
              color: Colors.white54,
              size: 48,
            ),
          );
    return InteractiveViewer(minScale: 1, maxScale: 4, child: image);
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
