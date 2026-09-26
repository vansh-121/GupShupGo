import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/screens/view_once_viewer_screen.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// The placeholder bubble for a view-once photo or video. It **never** renders
/// the media — not a thumbnail, not a blurred preview. A preview of a
/// self-destructing photo is a copy of it that survives destruction, which is
/// why the send path also skips generating a video poster frame.
///
/// Four states, derived entirely from the message (no local state), so the
/// bubble re-renders correctly the moment `markViewOnceConsumed` overwrites the
/// row or `viewOnceOpenedBy` arrives from Firestore:
///
///  * **sender, unopened** — "Photo · View once", not tappable
///  * **sender, opened** — "Opened", not tappable
///  * **receiver, unopened** — "Photo · View once", tappable → the viewer
///  * **receiver, opened** — "Opened", not tappable
///
/// The sender is never tappable in either state. Their own copy of the key is
/// deliberately kept (it backs the resend protocol), so the guard has to be at
/// the render, not at the key: without it, a sender could re-open a photo they
/// had promised would vanish, and the promise would be for the receiver only.
///
/// "Opened" is decided by two independent signals, either of which is enough:
/// [MessageModel.viewOnceOpenedBy] — cleartext Firestore metadata that outlives
/// a reinstall — and a null [MessageModel.mediaKey], which is what the consumed
/// local row looks like. A fresh install with an empty database still refuses to
/// re-open, because the server-visible list says it was opened.
class ViewOnceBubble extends StatelessWidget {
  const ViewOnceBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.currentUserId,
  });

  final MessageModel message;
  final bool isMe;
  final String currentUserId;

  bool get _isVideo => message.type == MessageType.video;

  /// For the receiver this is "have *I* opened it"; for the sender, "has the
  /// other side opened it". Same list, read from the relevant end.
  bool get _opened => isMe
      ? message.viewOnceOpenedBy.contains(message.receiverId)
      : message.viewOnceOpenedBy.contains(currentUserId);

  /// The payload hasn't merged yet — an undecrypted or still-in-flight message,
  /// where `type` is cleartext but every content field is missing. Distinct
  /// from "opened": there is nothing to show *yet*, rather than ever again.
  bool get _pending => !_opened && (message.mediaKey?.isEmpty ?? true);

  bool get _tappable => !isMe && !_opened && !_pending;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final fg = isMe ? Colors.white : c.textHigh;
    final fgLow = isMe ? Colors.white.withValues(alpha: 0.75) : c.textLow;

    // Spent and pending bubbles both read as inert, which is the honest signal
    // in each case: nothing here responds to a tap.
    final dim = _opened || _pending;
    final glyphColor = dim ? fgLow : fg;

    return InkWell(
      onTap: _tappable ? () => _open(context) : null,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 168, maxWidth: 240),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: glyphColor.withValues(alpha: 0.55)),
              ),
              alignment: Alignment.center,
              child: Icon(
                _opened
                    ? Icons.visibility_off_rounded
                    : (_isVideo
                        ? Icons.play_circle_outline_rounded
                        : Icons.looks_one_rounded),
                size: 20,
                color: glyphColor,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: dim ? fgLow : fg,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      fontStyle: _opened ? FontStyle.italic : FontStyle.normal,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(color: fgLow, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _title {
    if (_opened) return 'Opened';
    return _isVideo ? 'Video' : 'Photo';
  }

  String get _subtitle {
    if (_opened) {
      // Said from the reader's own side: the sender is being told the other
      // person has seen it, the receiver that their one chance is spent.
      return isMe ? 'View once · seen' : 'View once · no longer available';
    }
    if (_pending) return 'View once · not available';
    if (isMe) return 'View once · not opened yet';
    return _isVideo ? 'View once · tap to play' : 'View once · tap to view';
  }

  /// One last confirmation, because the tap is irreversible: opening destroys
  /// the key. A mis-tap in a scrolling list would otherwise burn the message.
  Future<void> _open(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          _isVideo ? 'Play once?' : 'Open once?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          "You can only open this ${_isVideo ? 'video' : 'photo'} one time. "
          "Once you close it, it's gone for good.",
          style: GoogleFonts.poppins(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Open',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ViewOnceViewerScreen(
          message: message,
          currentUserId: currentUserId,
        ),
      ),
    );
  }
}
