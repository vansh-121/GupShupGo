import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/services/chat_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// A WhatsApp-style document tile: type glyph, filename, size, and a tap target
/// that downloads-decrypts on first open and hands the file to the OS after.
///
/// Unlike the image and video bubbles, the blob behind this one is **encrypted**
/// (see `EncryptedMediaService`), so there is no URL that renders on its own —
/// the bytes have to come down and through AES-GCM before anything can open
/// them. That is why the tile is a download affordance first and a preview
/// never: it shows the extension glyph rather than a thumbnail, because
/// generating a thumbnail would mean decrypting the whole file just to paint a
/// 40 px square.
///
/// Three states, one tap target:
///  * **not cached** — download icon; tap fetches, decrypts and then opens
///  * **downloading** — determinate-less progress ring (the decrypt has no
///    progress to report and dominates the wall-clock on a large file)
///  * **cached** — open icon; tap goes straight to the handler app
class DocumentBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;

  const DocumentBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  State<DocumentBubble> createState() => _DocumentBubbleState();
}

class _DocumentBubbleState extends State<DocumentBubble> {
  bool _busy = false;

  /// Set once a download has landed, so the glyph flips to "open" without
  /// re-hitting the filesystem on every rebuild.
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _localPath = widget.message.localFilePath;
    _probeCache();
  }

  /// The sender's own copy carries `localFilePath` from the pick, so it opens
  /// with no download. The receiver's doesn't — but a file cached by an earlier
  /// tap is still on disk, and re-deriving its path is cheaper than a network
  /// round trip. `downloadAndCacheEncryptedMedia` already returns early when the
  /// file exists, so this is that call with the network branch unreachable.
  Future<void> _probeCache() async {
    final seeded = _localPath;
    if (seeded != null && await File(seeded).exists()) return;

    // A miss leaves the tile in its "download" state, which is correct.
    final path = await ChatService.instance
        .cachedEncryptedMediaPath(widget.message);
    if (path != null && mounted) setState(() => _localPath = path);
  }

  Future<void> _onTap() async {
    if (_busy) return;

    var path = _localPath;
    if (path == null || !await File(path).exists()) {
      setState(() => _busy = true);
      try {
        path = await ChatService.instance
            .downloadAndCacheEncryptedMedia(widget.message);
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      if (path == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't download this file")),
          );
        }
        return;
      }
      if (mounted) setState(() => _localPath = path);
    }

    // `open_filex` fails when no installed app claims the type — common for
    // .zip on a clean Android, and for anything unusual on iOS. Falling back to
    // the share sheet keeps the file reachable (Save to Files, mail it, hand it
    // to a specific app) instead of dead-ending on an error toast.
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      await Share.shareXFiles([XFile(path)]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final isMe = widget.isMe;
    final fg = isMe ? Colors.white : c.textHigh;
    final fgLow = isMe ? Colors.white.withOpacity(0.75) : c.textLow;

    final name = _displayName(widget.message);
    final ext = _extensionOf(name);
    final size = _fileSize(widget.message);
    final cached = _localPath != null;

    return InkWell(
      onTap: _onTap,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 200, maxWidth: 240),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.white.withOpacity(0.18)
                    : _tintFor(ext).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: _busy
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isMe ? Colors.white : _tintFor(ext),
                      ),
                    )
                  : Icon(
                      _iconFor(ext),
                      size: 22,
                      color: isMe ? Colors.white : _tintFor(ext),
                    ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: fg,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cached
                            ? Icons.open_in_new_rounded
                            : Icons.download_rounded,
                        size: 12,
                        color: fgLow,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          [
                            if (ext.isNotEmpty) ext.toUpperCase(),
                            if (size != null) size,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: fgLow,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The filename, or a generic label if the payload didn't carry one — which
  /// happens on a message this device couldn't decrypt, where `type` is
  /// cleartext but every content field is missing.
  static String _displayName(MessageModel m) {
    final n = m.fileName?.trim();
    return (n == null || n.isEmpty) ? 'Document' : n;
  }

  static String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return '';
    final ext = name.substring(dot + 1).toLowerCase();
    return ext.length > 5 ? '' : ext;
  }

  /// Plaintext size for display.
  ///
  /// `mediaKey['s']` is the *ciphertext* length — plaintext plus the 16-byte
  /// GCM tag appended by `EncryptedMediaService`. Read raw rather than through
  /// `MediaKeyBundle.fromMap` so a malformed bundle degrades to "no size shown"
  /// instead of throwing inside `build`.
  static String? _fileSize(MessageModel m) {
    final raw = m.mediaKey?['s'];
    final cipherBytes = raw is num ? raw.toInt() : null;
    if (cipherBytes == null || cipherBytes <= 16) return null;
    final bytes = cipherBytes - 16;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static IconData _iconFor(String ext) => switch (ext) {
        'pdf' => Icons.picture_as_pdf_rounded,
        'doc' || 'docx' || 'rtf' || 'odt' => Icons.description_rounded,
        'xls' || 'xlsx' || 'csv' || 'ods' => Icons.table_chart_rounded,
        'ppt' || 'pptx' || 'odp' => Icons.slideshow_rounded,
        'zip' || 'rar' || '7z' || 'tar' || 'gz' => Icons.folder_zip_rounded,
        'txt' || 'md' || 'log' => Icons.article_rounded,
        'apk' => Icons.android_rounded,
        'mp3' || 'wav' || 'm4a' || 'flac' || 'ogg' => Icons.audiotrack_rounded,
        'mp4' || 'mov' || 'mkv' || 'avi' || 'webm' => Icons.movie_rounded,
        'png' || 'jpg' || 'jpeg' || 'gif' || 'webp' || 'heic' =>
          Icons.image_rounded,
        _ => Icons.insert_drive_file_rounded,
      };

  /// Familiar per-type colours (Acrobat red, Word blue, Excel green…) so the
  /// tile is identifiable at a glance. Only used on received bubbles — a sent
  /// bubble is already a saturated colour and tints the glyph white instead.
  static Color _tintFor(String ext) => switch (ext) {
        'pdf' => const Color(0xFFE53935),
        'doc' || 'docx' || 'rtf' || 'odt' => const Color(0xFF1E88E5),
        'xls' || 'xlsx' || 'csv' || 'ods' => const Color(0xFF43A047),
        'ppt' || 'pptx' || 'odp' => const Color(0xFFF4511E),
        'zip' || 'rar' || '7z' || 'tar' || 'gz' => const Color(0xFF8E24AA),
        'apk' => const Color(0xFF3DDC84),
        _ => const Color(0xFF607D8B),
      };
}
