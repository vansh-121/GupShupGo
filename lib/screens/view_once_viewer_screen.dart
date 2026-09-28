import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/services/chat_service.dart';
import 'package:video_chat_app/services/crypto/encrypted_media_service.dart';
import 'package:video_chat_app/services/secure_screen_service.dart';

/// Full-screen viewer for a view-once photo or video. Opening it **consumes**
/// the message.
///
/// The order of operations here is the whole feature, so it is deliberate:
///
///  1. decrypt the media into **memory** — never through
///     `downloadAndCacheEncryptedMedia`, which would leave a decrypted copy in
///     the ordinary chat-media cache that nothing later deletes;
///  2. call [ChatService.markViewOnceConsumed] *immediately*, before a single
///     pixel is on screen. That destroys every copy of the AES key — memo,
///     SQLite payload row, cross-install vault — leaving the Storage blob
///     permanently unopenable.
///
/// Consuming on decrypt rather than on close is what makes this survive a
/// crash: if the app is force-stopped while the photo is up, the key is already
/// gone and the message cannot be re-opened. Marking on close would leave a
/// window where killing the app preserved the media.
///
/// Video is the one compromise. `video_player` cannot play from a byte buffer,
/// so the clip is written to a **temp file** for the life of the viewer and
/// deleted in [dispose]. The key is still destroyed at step 2, so this file is
/// the only plaintext copy in existence and it does not outlive the screen.
///
/// While this route is on top, the window carries FLAG_SECURE on Android (see
/// [SecureScreenService]), so screenshots, screen recordings and the
/// recent-apps thumbnail are all blocked. iOS has no equivalent — the UI says
/// so rather than implying a guarantee the platform can't make.
class ViewOnceViewerScreen extends StatefulWidget {
  const ViewOnceViewerScreen({
    super.key,
    required this.message,
    required this.currentUserId,
  });

  final MessageModel message;
  final String currentUserId;

  @override
  State<ViewOnceViewerScreen> createState() => _ViewOnceViewerScreenState();
}

class _ViewOnceViewerScreenState extends State<ViewOnceViewerScreen> {
  Uint8List? _imageBytes;
  VideoPlayerController? _videoController;
  File? _tempVideoFile;
  String? _error;
  bool _loading = true;

  bool get _isVideo => widget.message.type == MessageType.video;

  @override
  void initState() {
    super.initState();
    // Set before the first frame, so there is no gap in which the media is
    // visible without capture blocking.
    SecureScreenService.instance.enable();
    _openAndConsume();
  }

  @override
  void dispose() {
    SecureScreenService.instance.disable();
    _videoController?.dispose();
    // The only plaintext copy of a view-once video. Fire-and-forget: dispose
    // can't await, and the file is in the OS temp dir either way.
    final temp = _tempVideoFile;
    if (temp != null) {
      temp.delete().catchError((Object e) {
        if (kDebugMode) debugPrint('[ViewOnce] temp cleanup failed: $e');
        return temp;
      });
    }
    super.dispose();
  }

  Future<void> _openAndConsume() async {
    final keyMap = widget.message.mediaKey;
    if (keyMap == null || keyMap.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'This media is no longer available.';
      });
      return;
    }

    try {
      // 1. Decrypt into memory. Constant-time SHA-256 verify + AES-256-GCM,
      //    isolate-offloaded above 32 KB, inside the service.
      final bundle = MediaKeyBundle.fromMap(keyMap);
      final plaintext = await EncryptedMediaService().downloadAndDecrypt(bundle);

      // 2. Consume before rendering — see the class doc. Awaited so a failure
      //    to destroy the key is surfaced as an error instead of silently
      //    showing media that stays re-openable.
      await ChatService.instance.markViewOnceConsumed(
        message: widget.message,
        currentUserId: widget.currentUserId,
      );

      if (!mounted) return;

      if (_isVideo) {
        final dir = await getTemporaryDirectory();
        final file = File(p.join(dir.path,
            'vo_${widget.message.id}_${DateTime.now().millisecondsSinceEpoch}.mp4'));
        await file.writeAsBytes(plaintext, flush: true);
        _tempVideoFile = file;

        final controller = VideoPlayerController.file(file);
        await controller.initialize();
        if (!mounted) {
          controller.dispose();
          return;
        }
        await controller.setLooping(false);
        await controller.play();
        setState(() {
          _videoController = controller;
          _loading = false;
        });
      } else {
        setState(() {
          _imageBytes = plaintext;
          _loading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ViewOnce] open failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Couldn't open this media.";
      });
    }
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
          _isVideo ? 'Video · View once' : 'Photo · View once',
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
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded,
                color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final controller = _videoController;
    if (controller != null) {
      return AspectRatio(
        aspectRatio: controller.value.aspectRatio == 0
            ? 16 / 9
            : controller.value.aspectRatio,
        child: GestureDetector(
          onTap: () => setState(() {
            controller.value.isPlaying ? controller.pause() : controller.play();
          }),
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(controller),
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: controller,
                builder: (_, value, __) => value.isPlaying
                    ? const SizedBox.shrink()
                    : const Icon(Icons.play_arrow_rounded,
                        color: Colors.white70, size: 64),
              ),
            ],
          ),
        ),
      );
    }

    final bytes = _imageBytes;
    if (bytes != null) {
      return InteractiveViewer(
        minScale: 1,
        maxScale: 4,
        child: Image.memory(bytes, fit: BoxFit.contain),
      );
    }
    return const SizedBox.shrink();
  }

  /// The honest caveat. On Android the flag genuinely blocks capture; on iOS
  /// there is no API that can, so the copy promises only what holds everywhere:
  /// this is the one time it can be opened.
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
