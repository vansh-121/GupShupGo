// The link preview card, in a chat bubble and in the composer strip.
//
// Everything rendered here arrived inside the encrypted payload — the sender
// resolved it (see LinkPreviewService) and shipped title/description/thumbnail
// with the message. This widget never touches the network, which is the whole
// point: opening a chat cannot leak your IP to whoever sent you a link, and the
// card still draws with the radio off.
//
// Geometry deliberately mirrors `_buildStatusReplyPreview` in chat_screen.dart —
// same 10px radius, same 3px left border, same 46x58 thumbnail — so a bubble
// holding both cards reads as one design rather than two.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../utils/url_opener.dart';

/// Decoded thumbnails, keyed by caller-supplied id.
///
/// `MemoryImage` compares byte lists with `identical()`, so calling
/// `base64Decode` inside `build()` hands Flutter a brand-new image every frame:
/// a fresh image-cache entry per rebuild, which in a scrolling list is both a
/// leak and visible jank. Decoding once and handing back the *same* `Uint8List`
/// instance is what makes the image cache work at all here.
class _ThumbCache {
  static const int _max = 60;
  static final Map<String, Uint8List?> _entries = {};

  static Uint8List? get(String key, String base64Data) {
    if (_entries.containsKey(key)) return _entries[key];

    Uint8List? decoded;
    try {
      decoded = base64Decode(base64Data);
      if (decoded.isEmpty) decoded = null;
    } catch (_) {
      // A truncated or corrupted thumbnail is cached as null so we don't retry
      // the decode on every frame.
      decoded = null;
    }

    if (_entries.length >= _max) _entries.remove(_entries.keys.first);
    _entries[key] = decoded;
    return decoded;
  }
}

class LinkPreviewCard extends StatelessWidget {
  final String url;
  final String? title;
  final String? description;
  final String? siteName;
  final String? imageBase64;

  /// Drives the palette. `true` gives the outgoing-bubble treatment (white on a
  /// translucent overlay); `false` gives the incoming/composer treatment.
  final bool isMe;

  /// Null means "fill the parent" — used by the composer strip.
  final double? width;

  /// Cache key for the decoded thumbnail. Must identify the *bytes*, not the
  /// slot on screen — a hit on this key returns the stored image without
  /// re-checking [imageBase64], so reusing one key for two different links
  /// redraws the first link's thumbnail. Message id for bubbles (unique
  /// already); key by URL for the composer, whose card outlives its content.
  final String cacheKey;

  /// Shows a dismiss button when non-null. Composer only.
  final VoidCallback? onClose;

  const LinkPreviewCard({
    super.key,
    required this.url,
    required this.cacheKey,
    required this.isMe,
    this.title,
    this.description,
    this.siteName,
    this.imageBase64,
    this.width,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final thumb =
        imageBase64 == null ? null : _ThumbCache.get(cacheKey, imageBase64!);

    final headline = (title != null && title!.isNotEmpty) ? title! : url;
    final subtitle = (description != null && description!.isNotEmpty)
        ? description!
        : (siteName ?? '');

    return GestureDetector(
      onTap: () => openExternalUrl(context, url),
      child: Container(
        width: width,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.white.withOpacity(0.16)
              : c.surfaceAlt.withOpacity(0.92),
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(
              color: isMe ? Colors.white.withOpacity(0.75) : c.primary,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: SizedBox(
                width: 46,
                height: 58,
                child: thumb != null
                    ? Image.memory(
                        thumb,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) => _fallbackThumb(c),
                      )
                    : _fallbackThumb(c),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (siteName != null && siteName!.isNotEmpty)
                    Text(
                      siteName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color:
                            isMe ? Colors.white.withOpacity(0.82) : c.primary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    headline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: isMe ? Colors.white : c.textHigh,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: isMe ? Colors.white.withOpacity(0.9) : c.textMid,
                        fontSize: 11,
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onClose != null)
              GestureDetector(
                onTap: onClose,
                // Padding rather than an IconButton: IconButton's 48px minimum
                // tap target would force the card taller than the thumbnail.
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(Icons.close_rounded, size: 18, color: c.textMid),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackThumb(AppThemeColors c) => Container(
        color: isMe ? Colors.white.withOpacity(0.12) : c.surface,
        alignment: Alignment.center,
        child: Icon(
          Icons.link_rounded,
          size: 20,
          color: isMe ? Colors.white.withOpacity(0.8) : c.textLow,
        ),
      );
}
