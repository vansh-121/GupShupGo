// The quoted-message card, in a chat bubble and in the composer strip.
//
// The quote is a *snapshot*, not a pointer: the reply carries its own encrypted
// copy of the sender name, type, and a short snippet of the message it answers
// (`replyTo*` on MessageModel). So it renders even after the original was
// deleted, cleared, or landed on a device that cannot decrypt it — the same
// model WhatsApp uses, and the reason the card never shows "message unavailable".
//
// [localThumbPath] is resolved by the caller and is best-effort by design. A
// quoted image's `mediaUrl` points at ciphertext in Storage and is useless
// without the media key, so the thumbnail can only come from a local file this
// device already has. When it doesn't, the card degrades to an icon plus
// "Photo", which is enough to identify the message being answered.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class ReplyQuoteCard extends StatelessWidget {
  /// Already resolved to "You" or the peer's display name by the caller.
  final String senderName;

  /// The snapshot snippet. Empty for media with no caption.
  final String? text;

  /// `MessageType.name` of the original.
  final String? type;

  final String? localThumbPath;

  /// Drives the palette. `true` gives the outgoing-bubble treatment.
  final bool isMe;

  final double? width;

  /// Jump to the original. Null when there is nowhere to jump to.
  final VoidCallback? onTap;

  /// Shows a dismiss button when non-null. Composer only.
  final VoidCallback? onClose;

  const ReplyQuoteCard({
    super.key,
    required this.senderName,
    required this.isMe,
    this.text,
    this.type,
    this.localThumbPath,
    this.width,
    this.onTap,
    this.onClose,
  });

  bool get _isMedia => type == 'image' || type == 'video';

  IconData get _icon {
    switch (type) {
      case 'image':
        return Icons.photo_rounded;
      case 'video':
        return Icons.videocam_rounded;
      case 'audio':
        return Icons.mic_rounded;
      default:
        return Icons.format_quote_rounded;
    }
  }

  /// What to show when the original had no text of its own.
  String get _placeholder {
    switch (type) {
      case 'image':
        return 'Photo';
      case 'video':
        return 'Video';
      case 'audio':
        return 'Voice message';
      default:
        return 'Message';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final snippet =
        (text != null && text!.trim().isNotEmpty) ? text!.trim() : _placeholder;
    final showIcon = _isMedia || type == 'audio';

    final thumbFile = localThumbPath == null ? null : File(localThumbPath!);

    return GestureDetector(
      onTap: onTap,
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    senderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: isMe ? Colors.white : c.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (showIcon) ...[
                        Icon(
                          _icon,
                          size: 13,
                          color:
                              isMe ? Colors.white.withOpacity(0.78) : c.textMid,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          snippet,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: isMe
                                ? Colors.white.withOpacity(0.9)
                                : c.textHigh,
                            fontSize: 11.5,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Media thumbnail sits on the trailing edge, WhatsApp-style. Only
            // drawn when the file is actually on this device — see the note at
            // the top of the file about why it can't be fetched.
            if (thumbFile != null && thumbFile.existsSync()) ...[
              const SizedBox(width: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.file(
                  thumbFile,
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                  cacheWidth: 126,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
            if (onClose != null)
              GestureDetector(
                onTap: onClose,
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
}
