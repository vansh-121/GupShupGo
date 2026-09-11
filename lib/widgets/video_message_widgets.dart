import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/services/voice_recorder_service.dart';

/// Shared video widgets and helpers used by both the normal chat
/// ([chat_screen.dart]) and the nearby-peer mesh chat ([mesh_chat_screen.dart]).
///
/// A chat video reaches a bubble by two transports — Firebase Storage when
/// online, the offline Nearby mesh when not — and in two screens. This file is
/// the single rendering + playback path so both surfaces stay in parity: the
/// poster tile, the full-screen player, and the small poster/duration probes the
/// mesh send path uses.

// ─── Mesh capture helpers ──────────────────────────────────────────────────────

/// Extracts a video's first-frame poster as a base64 JPEG for a **mesh** send, or
/// null if it can't be decoded.
///
/// Deliberately smaller than the online chat's 360px/q60 poster: a mesh video's
/// poster rides inside the `file_metadata` BYTES packet, which Nearby caps at
/// ~32 KB, so a 240px/q50 still keeps the packet safely under that ceiling. Any
/// failure returns null and the bubble falls back to the film-glyph placeholder;
/// it never blocks the send.
Future<String?> generateMeshVideoPoster(String path) async {
  try {
    final Uint8List? bytes = await VideoThumbnail.thumbnailData(
      video: path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 240,
      quality: 50,
    );
    if (bytes == null || bytes.isEmpty) return null;
    return base64Encode(bytes);
  } catch (_) {
    return null;
  }
}

/// Reads a video's duration in whole seconds for the bubble label, or null if it
/// can't be determined. Mirrors the chat screen's `_probeVideoDuration`: an
/// unreadable file yields null rather than blocking the send.
Future<int?> probeMeshVideoDurationSeconds(String path) async {
  final probe = VideoPlayerController.file(File(path));
  try {
    await probe.initialize();
    final d = probe.value.duration;
    return d == Duration.zero ? null : d.inSeconds;
  } catch (_) {
    return null;
  } finally {
    await probe.dispose();
  }
}

// ─── Poster tile ────────────────────────────────────────────────────────────────

/// The video bubble tile: the first-frame poster (decoded from the inline
/// [MessageModel.videoThumbnailBase64] the sender attached) under a centred play
/// button and, when known, the clip length. Older messages — or any clip whose
/// poster couldn't be extracted — fall back to a dark tile with a faint film
/// glyph. The caller wraps it in a tap gesture that opens [ChatVideoPlayerScreen].
///
/// The poster is decoded once and memoised in [_VideoThumbCache]: Image.memory
/// keys on byte-list identity, so decoding inside build would mint a fresh
/// MemoryImage every frame and thrash the image cache. Same guard the link
/// preview card uses.
class VideoThumbnailTile extends StatelessWidget {
  const VideoThumbnailTile({super.key, required this.message});

  final MessageModel message;

  @override
  Widget build(BuildContext context) {
    final durationSec = message.audioDuration; // reused field; carries clip length
    final poster =
        _VideoThumbCache.get(message.id, message.videoThumbnailBase64);
    return Container(
      width: 220,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (poster != null) ...[
            Positioned.fill(
              child: Image.memory(
                poster,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                // A corrupt/undecodable poster degrades to the film glyph rather
                // than a broken-image box.
                errorBuilder: (_, __, ___) => Icon(
                  Icons.movie_creation_rounded,
                  color: Colors.white.withOpacity(0.10),
                  size: 64,
                ),
              ),
            ),
            // Light scrim so the white play button and duration chip stay legible
            // over a bright frame.
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.18)),
            ),
          ] else
            // No poster (old message or extraction failed): faint film glyph so
            // the empty tile reads as "video", not "broken".
            Icon(Icons.movie_creation_rounded,
                color: Colors.white.withOpacity(0.10), size: 64),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.9), width: 2),
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 34),
          ),
          if (durationSec != null && durationSec > 0)
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_rounded,
                        color: Colors.white, size: 12),
                    const SizedBox(width: 3),
                    Text(
                      VoiceRecorderService.formatDuration(
                          Duration(seconds: durationSec)),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Decoded video posters, keyed by message id. The video twin of `_ThumbCache`
/// in link_preview_card.dart, and there for the same reason: `Image.memory`
/// compares byte lists with `identical()`, so calling `base64Decode` inside
/// `build()` mints a fresh image every frame — a new image-cache entry per
/// rebuild, which in a scrolling list is both a leak and visible jank. Decoding
/// once and returning the *same* `Uint8List` is what lets the image cache work.
///
/// Takes a nullable payload (the field is absent on old messages and on any
/// clip whose poster couldn't be extracted); a null or unusable payload caches
/// and returns null so the bubble falls back to its placeholder.
class _VideoThumbCache {
  static const int _max = 60;
  static final Map<String, Uint8List?> _entries = {};

  static Uint8List? get(String key, String? base64Data) {
    if (_entries.containsKey(key)) return _entries[key];

    Uint8List? decoded;
    if (base64Data != null && base64Data.isNotEmpty) {
      try {
        decoded = base64Decode(base64Data);
        if (decoded.isEmpty) decoded = null;
      } catch (_) {
        // A truncated or corrupted poster is cached as null so we don't retry
        // the decode on every frame.
        decoded = null;
      }
    }

    if (_entries.length >= _max) _entries.remove(_entries.keys.first);
    _entries[key] = decoded;
    return decoded;
  }
}

// ─── Full-screen player ─────────────────────────────────────────────────────────

/// Full-screen player for a chat video. Prefers the sender's local file and
/// falls back to streaming the network URL for the receiver, who has no local
/// copy until they open one. Tap toggles play/pause; the scrubber sits at the
/// bottom. Shared by the normal chat and the mesh chat — the video twin of the
/// full-screen image viewer.
class ChatVideoPlayerScreen extends StatefulWidget {
  const ChatVideoPlayerScreen({
    super.key,
    this.localPath,
    this.url,
    required this.caption,
  });

  final String? localPath;
  final String? url;
  final String caption;

  @override
  State<ChatVideoPlayerScreen> createState() => _ChatVideoPlayerScreenState();
}

class _ChatVideoPlayerScreenState extends State<ChatVideoPlayerScreen> {
  VideoPlayerController? _ctrl;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final local = widget.localPath;
    final VideoPlayerController controller;
    if (local != null && File(local).existsSync()) {
      controller = VideoPlayerController.file(File(local));
    } else if (widget.url != null && widget.url!.isNotEmpty) {
      // Streams directly — no manual download step for the receiver.
      controller = VideoPlayerController.networkUrl(Uri.parse(widget.url!));
    } else {
      if (mounted) setState(() => _error = true);
      return;
    }
    _ctrl = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {});
      controller
        ..setLooping(false)
        ..play();
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final c = _ctrl;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = _ctrl;
    final Widget body;
    if (_error) {
      body = const Text("Couldn't play this video",
          style: TextStyle(color: Colors.white70));
    } else if (c == null || !c.value.isInitialized) {
      body = const CircularProgressIndicator(color: Colors.white70);
    } else {
      body = GestureDetector(
        onTap: _togglePlay,
        child: AspectRatio(
          aspectRatio: c.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(c),
              Align(
                alignment: Alignment.bottomCenter,
                child: VideoProgressIndicator(c, allowScrubbing: true),
              ),
              if (!c.value.isPlaying)
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 48),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.caption,
            style: const TextStyle(fontSize: 14, color: Colors.white70)),
      ),
      body: Center(child: body),
    );
  }
}
