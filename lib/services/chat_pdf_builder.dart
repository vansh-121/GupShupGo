// Renders an exported conversation as a printable PDF.
//
// ## Why this is a separate renderer, not a flag on the text one
//
// The text transcript in `ChatExportService` reduces every message to one line
// of characters. A PDF is a layout: bubbles have sides, photos have aspect
// ratios, a day break is a divider rather than a repeated date prefix. Trying to
// serve both from one function would mean a formatter that returns strings for
// one caller and widgets for the other, so the two live apart and share only the
// vocabulary they genuinely have in common — `ChatService.deletedMessageText`
// and `VaultCipher.isPlaceholderText`, both read from their owners here exactly
// as the text path reads them.
//
// ## What this file may and may not touch
//
// Nothing here does I/O. Fonts arrive as [ChatPdfFonts] and photos as already
// decoded bytes on [ChatPdfEntry], which is what keeps the whole layout
// unit-testable with no device, no filesystem and no platform channels — and,
// more importantly, keeps the decision about *which* bytes are safe to read out
// of the layout code entirely. `ChatExportService` owns that, including the
// standing rule that an export performs zero crypto.
//
// ## Fonts, emoji and missing glyphs
//
// Poppins ships with this app as a real font asset and covers Latin and
// Devanagari, so ordinary Hindi and English messages render as selectable text.
// Emoji are not in any text font: they arrive through [ChatPdfFonts.emoji],
// which `ChatExportService` fills from the platform's own colour-emoji font when
// there is one. When that is absent the `pdf` package draws a blank for those
// runes rather than throwing, so an export never fails over a heart — it just
// loses it. Reaction chips are suppressed entirely in that case, because a chip
// is nothing *but* an emoji and an empty one reads as a bug.

import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/services/chat_service.dart';
import 'package:video_chat_app/services/crypto/vault_cipher.dart';

// ── Palette ──────────────────────────────────────────────────────────────
//
// Fixed and light, deliberately: this is paper. The app's dark mode exists so a
// screen at 1 a.m. is bearable, and reproducing it here would mean a page that
// costs a cartridge to print and is unreadable in the one place a printed chat
// gets read. The hues are the app's own so the export still looks like GupShupGo.
const PdfColor _brand = PdfColor.fromInt(0xFF6C5CE7);
const PdfColor _brandDeep = PdfColor.fromInt(0xFF5246BE);
const PdfColor _brandTint = PdfColor.fromInt(0xFFEDE9FE);
const PdfColor _sentEnd = PdfColor.fromInt(0xFF5B4CD8);
const PdfColor _received = PdfColor.fromInt(0xFFF4F3FB);
const PdfColor _line = PdfColor.fromInt(0xFFE4E1F5);
const PdfColor _ink = PdfColor.fromInt(0xFF1E293B);
const PdfColor _inkMid = PdfColor.fromInt(0xFF64748B);
const PdfColor _inkLow = PdfColor.fromInt(0xFF94A3B8);
const PdfColor _white = PdfColor.fromInt(0xFFFFFFFF);
const PdfColor _onSent = PdfColor.fromInt(0xFFFFFFFF);
const PdfColor _onSentSoft = PdfColor.fromInt(0xFFD8D2FA);
const PdfColor _slate = PdfColor.fromInt(0xFF2F3542);

// Opaque stand-ins for what would naturally be a translucent white overlay on a
// sent bubble. `pdf` emits fills as `r g b rg` and drops the alpha channel
// silently — a `0x33FFFFFF` panel comes out solid white, which on the purple
// gradient is not a subtle inset but a hole. These are the flattened results,
// picked against the middle of the gradient so a nested panel reads as a lighter
// layer of the same bubble.
const PdfColor _sentPanel = PdfColor.fromInt(0xFF8478EC);
const PdfColor _sentBadge = PdfColor.fromInt(0xFF9C93F1);

/// The five faces of Poppins this renderer draws with, plus an optional
/// colour-emoji font to fall back to.
///
/// Passed in rather than loaded here so the layout stays free of `rootBundle`
/// and therefore testable off-device. [emoji] is nullable because it is a
/// best-effort read of a platform font — see the file header.
@immutable
class ChatPdfFonts {
  const ChatPdfFonts({
    required this.regular,
    required this.medium,
    required this.semiBold,
    required this.italic,
    this.emoji,
  });

  final pw.Font regular;
  final pw.Font medium;
  final pw.Font semiBold;
  final pw.Font italic;
  final pw.Font? emoji;

  /// The same faces with [font] as the emoji fallback. Null [font] is allowed and
  /// means the same as never having one, so the caller does not need a branch
  /// around a best-effort load that came back empty.
  ChatPdfFonts withEmoji(pw.Font? font) => ChatPdfFonts(
        regular: regular,
        medium: medium,
        semiBold: semiBold,
        italic: italic,
        emoji: font,
      );

  /// The same faces with the emoji fallback dropped — the retry path for a
  /// platform font the PDF writer turns out not to be able to use.
  ChatPdfFonts get withoutEmoji => emoji == null ? this : withEmoji(null);

  List<pw.Font> get _fallback => emoji == null ? const [] : [emoji!];
}

/// One row of the export: the message, plus the photo bytes if this device still
/// has the file and the budget allowed embedding it.
///
/// [imageBytes] must be JPEG or PNG. Null means "render the placeholder tile" —
/// which is the honest outcome for a photo that was never downloaded here, or
/// one that lost its cache file, and is not an error.
@immutable
class ChatPdfEntry {
  const ChatPdfEntry({required this.message, this.imageBytes});

  final MessageModel message;
  final Uint8List? imageBytes;
}

/// A drawn media tile together with the width it occupies.
///
/// The width is not bookkeeping. A bubble takes its width from its widest child,
/// and the timestamp under a photo has to right-align against *the photo* — which
/// is only possible if the row holding it is given the tile's width instead of
/// the column's maximum. Returning the two together is what stops the two numbers
/// from drifting apart, which is how a photo ends up in a bubble half a page
/// wider than itself.
@immutable
class _MediaTile {
  const _MediaTile(this.width, this.child);

  final double width;
  final pw.Widget child;
}

class ChatPdfBuilder {
  ChatPdfBuilder._();

  /// Longest run of characters put in a single bubble.
  ///
  /// A bubble is one indivisible box to `MultiPage`, and a child taller than the
  /// page throws instead of splitting. At 9.5 pt in a 400 pt column this is
  /// roughly a third of a page, so even scripts with much wider glyphs than
  /// Latin stay far from the ceiling. Longer messages continue into a second
  /// bubble rather than being truncated: an export that silently drops the end of
  /// a long message would be worse than one that wraps it.
  static const int charsPerBubble = 1800;

  /// Hard ceiling for `MultiPage`, whose own default is 20. A year of daily
  /// chatting is a few hundred pages, so this is a runaway guard, not a limit
  /// anyone should reach.
  static const int maxPages = 4000;

  static const double _bubbleMaxFraction = 0.76;
  static const double _photoMaxWidth = 250;
  static const double _photoMaxHeight = 300;

  /// Width of the drawn tiles — video, voice note, missing-media placeholder.
  /// One number for all three so a chat containing every kind of attachment
  /// still has a single media column rather than three ragged ones.
  static const double _tileWidth = 190;

  /// Floor for the column around a media tile, so the timestamp beneath always
  /// has room. A photo can legitimately be a handful of points wide — a sticker
  /// saved as an image, a cropped thumbnail — and a 6 pt bubble with `09:04`
  /// hanging out of its side is worse than a little empty space.
  static const double _mediaMinWidth = 104;

  /// Renders [entries] and returns the PDF bytes.
  ///
  /// [entries] must already be filtered and ordered by the caller —
  /// `ChatExportService.exportableMessages` decides what belongs in an export,
  /// and duplicating that predicate here is how the two would drift.
  static Future<Uint8List> build({
    required List<ChatPdfEntry> entries,
    required String selfUserId,
    required String contactName,
    required DateTime exportedAt,
    required ChatPdfFonts fonts,
    String selfName = 'You',
  }) async {
    final doc = pw.Document(
      title: 'GupShupGo chat with $contactName',
      author: 'GupShupGo',
      creator: 'GupShupGo',
      subject: 'Chat transcript exported ${_dateLong(exportedAt)}',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        maxPages: maxPages,
        margin: const pw.EdgeInsets.fromLTRB(34, 32, 34, 24),
        theme: pw.ThemeData.withFont(
          base: fonts.regular,
          bold: fonts.semiBold,
          italic: fonts.italic,
          fontFallback: fonts._fallback,
        ),
        // Page 1 carries the cover, which is its own header; repeating the
        // running one above it would push the cover down for no reason.
        header: (ctx) =>
            ctx.pageNumber == 1 ? pw.SizedBox() : _runningHeader(fonts, contactName),
        footer: (ctx) => _footer(ctx, fonts),
        build: (ctx) => _body(
          entries: entries,
          selfUserId: selfUserId,
          contactName: contactName,
          exportedAt: exportedAt,
          fonts: fonts,
          selfName: selfName,
        ),
      ),
    );

    return doc.save();
  }

  // ── Page furniture ─────────────────────────────────────────────────────

  static pw.Widget _runningHeader(ChatPdfFonts fonts, String contactName) =>
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 14),
        padding: const pw.EdgeInsets.only(bottom: 8),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.7)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              contactName,
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
              style: pw.TextStyle(font: fonts.medium, fontSize: 9, color: _inkMid),
            ),
            pw.Text(
              'GupShupGo',
              style: pw.TextStyle(
                font: fonts.semiBold,
                fontSize: 9,
                color: _brand,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );

  static pw.Widget _footer(pw.Context ctx, ChatPdfFonts fonts) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 12),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Exported from GupShupGo',
              style: pw.TextStyle(font: fonts.regular, fontSize: 8, color: _inkLow),
            ),
            pw.Text(
              '${ctx.pageNumber} / ${ctx.pagesCount}',
              style: pw.TextStyle(font: fonts.medium, fontSize: 8, color: _inkLow),
            ),
          ],
        ),
      );

  // ── Body ───────────────────────────────────────────────────────────────

  static List<pw.Widget> _body({
    required List<ChatPdfEntry> entries,
    required String selfUserId,
    required String contactName,
    required DateTime exportedAt,
    required ChatPdfFonts fonts,
    required String selfName,
  }) {
    final out = <pw.Widget>[
      _cover(
        entries: entries,
        contactName: contactName,
        exportedAt: exportedAt,
        fonts: fonts,
      ),
      _disclosure(fonts),
    ];

    if (entries.isEmpty) {
      out.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 40),
          child: pw.Center(
            child: pw.Text(
              'No messages are stored on this device.',
              style: pw.TextStyle(font: fonts.italic, fontSize: 10, color: _inkMid),
            ),
          ),
        ),
      );
      return out;
    }

    DateTime? day;
    String? runSender;
    for (final entry in entries) {
      final m = entry.message;
      final local = m.timestamp.toLocal();
      final isNewDay = day == null || !_sameDay(day, local);
      if (isNewDay) {
        out.add(_dayDivider(local, fonts));
        day = local;
      }

      // A name is drawn once per run rather than once per bubble: on a printed
      // page the alignment already says who is speaking, and repeating the name
      // down a long reply chain is the noisiest thing a transcript can do.
      final showName = isNewDay || runSender != m.senderId;
      runSender = m.senderId;

      out.addAll(
        _messageBubbles(
          entry: entry,
          isMe: m.senderId == selfUserId,
          who: m.senderId == selfUserId ? selfName : contactName,
          showName: showName,
          fonts: fonts,
        ),
      );
    }

    out.add(_closing(entries.length, fonts));
    return out;
  }

  static pw.Widget _cover({
    required List<ChatPdfEntry> entries,
    required String contactName,
    required DateTime exportedAt,
    required ChatPdfFonts fonts,
  }) {
    final span = entries.isEmpty
        ? 'No messages on this device'
        : _spanLabel(
            entries.first.message.timestamp.toLocal(),
            entries.last.message.timestamp.toLocal(),
          );

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(24, 22, 24, 24),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(18),
        gradient: const pw.LinearGradient(
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
          colors: [_brand, _brandDeep],
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              _wordmark(fonts),
              pw.Spacer(),
              pw.Text(
                'Chat export',
                style: pw.TextStyle(
                  font: fonts.medium,
                  fontSize: 9,
                  color: _onSentSoft,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 26),
          pw.Text(
            contactName,
            maxLines: 2,
            style: pw.TextStyle(
              font: fonts.semiBold,
              fontSize: 25,
              color: _white,
              lineSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 7),
          pw.Text(
            span,
            style: pw.TextStyle(font: fonts.regular, fontSize: 10, color: _onSentSoft),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            '${_plural(entries.length, 'message')} · exported ${_dateLong(exportedAt)}',
            style: pw.TextStyle(font: fonts.regular, fontSize: 10, color: _onSentSoft),
          ),
        ],
      ),
    );
  }

  /// The rounded "G" badge. A typographic mark rather than the app icon asset:
  /// the icon is a PNG that would be decoded to raw pixels and embedded
  /// uncompressed, which is a lot of bytes for something 24 pt wide.
  static pw.Widget _wordmark(ChatPdfFonts fonts) => pw.Row(
        children: [
          pw.Container(
            width: 22,
            height: 22,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: _white,
              borderRadius: pw.BorderRadius.circular(7),
            ),
            child: pw.Text(
              'G',
              style: pw.TextStyle(font: fonts.semiBold, fontSize: 13, color: _brand),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            'GupShupGo',
            style: pw.TextStyle(
              font: fonts.semiBold,
              fontSize: 13,
              color: _white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      );

  /// The same limitation the text transcript states in its header, kept because
  /// it is the one thing about this file a reader could otherwise misread: a gap
  /// here is encryption working, not the export failing.
  static pw.Widget _disclosure(ChatPdfFonts fonts) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 14, bottom: 6),
        // The accent bar is the accent-coloured *background* of an outer box that
        // an inner box covers all but 3 pt of, rather than a left BorderSide: the
        // PDF widget layer asserts that a border with a radius is uniform, and a
        // rounded card with one thick edge is exactly the combination it rejects.
        // Nesting also keeps the bar the full height of the text without needing
        // a stretch, which has no defined height inside a MultiPage.
        decoration: const pw.BoxDecoration(
          color: _brand,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
        ),
        child: pw.Container(
          margin: const pw.EdgeInsets.only(left: 3),
          padding: const pw.EdgeInsets.fromLTRB(12, 11, 14, 12),
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF8F7FF),
            borderRadius: pw.BorderRadius.only(
              topLeft: pw.Radius.circular(2),
              bottomLeft: pw.Radius.circular(2),
              topRight: pw.Radius.circular(10),
              bottomRight: pw.Radius.circular(10),
            ),
          ),
          child: pw.Text(
            'These messages are end-to-end encrypted, so this file holds only '
            'what this device had already decrypted and saved. Anything received '
            'on another device, or not yet delivered here, is not in it. Photos '
            'are included where the file is still on this device; videos and '
            'voice notes are listed but not embedded.',
            style: pw.TextStyle(
              font: fonts.regular,
              fontSize: 8.5,
              color: _inkMid,
              lineSpacing: 2.2,
            ),
          ),
        ),
      );

  static pw.Widget _closing(int count, ChatPdfFonts fonts) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 22),
        child: pw.Column(
          children: [
            pw.Container(height: 0.7, color: _line),
            pw.SizedBox(height: 9),
            pw.Text(
              'End of conversation · ${_plural(count, 'message')}',
              style: pw.TextStyle(font: fonts.regular, fontSize: 8.5, color: _inkLow),
            ),
          ],
        ),
      );

  static pw.Widget _dayDivider(DateTime day, ChatPdfFonts fonts) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 20, bottom: 12),
        child: pw.Row(
          children: [
            pw.Expanded(child: pw.Container(height: 0.7, color: _line)),
            pw.Container(
              margin: const pw.EdgeInsets.symmetric(horizontal: 10),
              padding: const pw.EdgeInsets.symmetric(horizontal: 11, vertical: 4),
              decoration: pw.BoxDecoration(
                color: _brandTint,
                borderRadius: pw.BorderRadius.circular(20),
              ),
              child: pw.Text(
                _dateLong(day),
                style: pw.TextStyle(
                  font: fonts.medium,
                  fontSize: 8.5,
                  color: _brandDeep,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            pw.Expanded(child: pw.Container(height: 0.7, color: _line)),
          ],
        ),
      );

  // ── Bubbles ────────────────────────────────────────────────────────────

  /// One message as one or more bubbles — more than one only when its text is
  /// longer than [charsPerBubble]. See that constant for why splitting beats
  /// both truncating and trusting the page to be tall enough.
  static List<pw.Widget> _messageBubbles({
    required ChatPdfEntry entry,
    required bool isMe,
    required String who,
    required bool showName,
    required ChatPdfFonts fonts,
  }) {
    final m = entry.message;

    // Tombstone first, exactly as the text path does it: a deleted-for-everyone
    // row keeps its old text in some code paths, so branching on type or text
    // ahead of this flag would print the retracted content.
    if (m.deletedForEveryone) {
      return [
        _bubble(
          isMe: isMe,
          who: who,
          showName: showName,
          fonts: fonts,
          entry: entry,
          isTail: true,
          body: [
            _bodyText(
              value: ChatService.deletedMessageText,
              isMe: isMe,
              fonts: fonts,
              italic: true,
              meta: m,
            ),
          ],
        ),
      ];
    }

    switch (m.type) {
      case MessageType.image:
      case MessageType.video:
        return [
          _bubble(
            isMe: isMe,
            who: who,
            showName: showName,
            fonts: fonts,
            entry: entry,
            isTail: true,
            body: [
              _mediaColumn(
                tile: m.type == MessageType.image
                    ? _photo(entry, fonts)
                    : _videoTile(fonts),
                caption: m.text.trim(),
                message: m,
                isMe: isMe,
                fonts: fonts,
              ),
            ],
          ),
        ];

      case MessageType.audio:
        return [
          _bubble(
            isMe: isMe,
            who: who,
            showName: showName,
            fonts: fonts,
            entry: entry,
            isTail: true,
            body: [
              _mediaColumn(
                tile: _voiceNote(m.audioDuration, isMe, fonts),
                message: m,
                isMe: isMe,
                fonts: fonts,
              ),
            ],
          ),
        ];

      case MessageType.reaction:
        // Filtered out upstream — reactions are drawn on the bubble they target.
        // Kept so a new MessageType breaks the build instead of rendering blank.
        return const [];

      case MessageType.text:
        final raw = VaultCipher.isPlaceholderText(m.text)
            ? null
            : m.text.trimRight();
        if (raw == null) {
          return [
            _bubble(
              isMe: isMe,
              who: who,
              showName: showName,
              fonts: fonts,
              entry: entry,
              isTail: true,
              body: [
                _bodyText(
                  value: 'This message could not be decrypted on this device',
                  isMe: isMe,
                  fonts: fonts,
                  italic: true,
                  meta: m,
                ),
              ],
            ),
          ];
        }

        final chunks = _chunk(raw, charsPerBubble);
        return [
          for (var i = 0; i < chunks.length; i++)
            _bubble(
              isMe: isMe,
              who: who,
              // Only the first chunk introduces the speaker and only the last
              // carries the timestamp, so a split message still reads as one.
              showName: showName && i == 0,
              fonts: fonts,
              entry: entry,
              isTail: i == chunks.length - 1,
              body: [
                _bodyText(
                  value: chunks[i],
                  isMe: isMe,
                  fonts: fonts,
                  meta: i == chunks.length - 1 ? m : null,
                ),
              ],
            ),
        ];
    }
  }

  static pw.Widget _bubble({
    required bool isMe,
    required String who,
    required bool showName,
    required ChatPdfFonts fonts,
    required ChatPdfEntry entry,
    required bool isTail,
    required List<pw.Widget> body,
  }) {
    final m = entry.message;
    final maxWidth =
        (PdfPageFormat.a4.width - 68) * _bubbleMaxFraction;
    final reactions = isTail ? _reactionChips(m, fonts) : null;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Row(
        mainAxisAlignment:
            isMe ? pw.MainAxisAlignment.end : pw.MainAxisAlignment.start,
        children: [
          pw.ConstrainedBox(
            constraints: pw.BoxConstraints(maxWidth: maxWidth),
            child: pw.Column(
              crossAxisAlignment: isMe
                  ? pw.CrossAxisAlignment.end
                  : pw.CrossAxisAlignment.start,
              children: [
                if (showName)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3, left: 3, right: 3),
                    child: pw.Text(
                      who,
                      maxLines: 1,
                      overflow: pw.TextOverflow.clip,
                      style: pw.TextStyle(
                        font: fonts.semiBold,
                        fontSize: 8.5,
                        color: isMe ? _brandDeep : _inkMid,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                pw.Container(
                  padding: const pw.EdgeInsets.fromLTRB(11, 8, 11, 7),
                  decoration: pw.BoxDecoration(
                    color: isMe ? _brand : _received,
                    gradient: isMe
                        ? const pw.LinearGradient(
                            begin: pw.Alignment.topLeft,
                            end: pw.Alignment.bottomRight,
                            colors: [_brand, _sentEnd],
                          )
                        : null,
                    border: isMe
                        ? null
                        : const pw.Border.fromBorderSide(
                            pw.BorderSide(color: _line, width: 0.7),
                          ),
                    // The clipped corner is the bubble's tail: sent points
                    // right, received points left, which is what makes a
                    // greyscale print still readable as a conversation.
                    borderRadius: pw.BorderRadius.only(
                      topLeft: const pw.Radius.circular(12),
                      topRight: const pw.Radius.circular(12),
                      bottomLeft: pw.Radius.circular(isMe ? 12 : 3),
                      bottomRight: pw.Radius.circular(isMe ? 3 : 12),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (m.hasReplyQuote) ...[
                        _replyQuote(m, isMe, fonts),
                        pw.SizedBox(height: 6),
                      ],
                      ...body,
                    ],
                  ),
                ),
                if (reactions != null)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 3, left: 4, right: 4),
                    child: reactions,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// [value] with the emoji presentation selectors removed.
  ///
  /// U+FE0F and U+FE0E are zero-width hints that say "draw the previous
  /// character as emoji / as text". A text renderer is meant to consume them; the
  /// PDF writer instead looks them up as characters, finds no glyph in Poppins or
  /// in the platform emoji font, and draws a missing-glyph box. So `❤️` — which is
  /// U+2764 followed by U+FE0F — comes out as a heart followed by a tofu square.
  /// Dropping them loses nothing: they carry no ink of their own.
  static String _drawable(String value) => value
      .replaceAll('️', '') // VARIATION SELECTOR-16 (emoji presentation)
      .replaceAll('︎', ''); // VARIATION SELECTOR-15 (text presentation)

  /// A text body, with the timestamp riding at the end of its last line when
  /// [meta] is given.
  ///
  /// Inline, and that inlining is the whole reason bubbles hug their text. A
  /// `Row` inside a `Column` defaults to `MainAxisSize.max`, so a timestamp on a
  /// row of its own claims the entire 76% column and every bubble on the page
  /// comes out the same width — a table of rows, not a conversation. As a
  /// trailing span the timestamp costs nothing beyond the line it sits on, which
  /// is also exactly where a chat app puts it.
  static pw.Widget _bodyText({
    required String value,
    required bool isMe,
    required ChatPdfFonts fonts,
    bool italic = false,
    MessageModel? meta,
  }) {
    final body = pw.TextStyle(
      font: italic ? fonts.italic : fonts.regular,
      fontSize: 9.5,
      color: italic
          ? (isMe ? _onSentSoft : _inkMid)
          : (isMe ? _onSent : _ink),
      lineSpacing: 2.4,
    );
    if (meta == null) return pw.Text(_drawable(value), style: body);

    final stamp = pw.TextStyle(
      font: fonts.regular,
      fontSize: 7,
      color: isMe ? _onSentSoft : _inkLow,
    );

    return pw.RichText(
      text: pw.TextSpan(
        style: body,
        children: [
          pw.TextSpan(text: _drawable(value)),
          if (meta.isEdited)
            pw.TextSpan(
              text: '   edited',
              style: pw.TextStyle(
                font: fonts.italic,
                fontSize: 7,
                color: isMe ? _onSentSoft : _inkLow,
              ),
            ),
          pw.TextSpan(text: '   ${_time(meta.timestamp.toLocal())}', style: stamp),
        ],
      ),
    );
  }

  /// A media tile with its caption and timestamp, in a column exactly as wide as
  /// the tile.
  ///
  /// The explicit width does two jobs: it lets the bubble hug the tile instead of
  /// stretching to the full column, and it gives the timestamp row a right edge
  /// to align against. The caption then wraps at the tile's edge, which is what
  /// the chat screen does too.
  static pw.Widget _mediaColumn({
    required _MediaTile tile,
    required MessageModel message,
    required bool isMe,
    required ChatPdfFonts fonts,
    String caption = '',
  }) =>
      pw.SizedBox(
        width: tile.width < _mediaMinWidth ? _mediaMinWidth : tile.width,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            tile.child,
            if (caption.isNotEmpty) ...[
              pw.SizedBox(height: 7),
              _bodyText(value: caption, isMe: isMe, fonts: fonts),
            ],
            pw.SizedBox(height: 4),
            _metaRow(message, isMe, fonts),
          ],
        ),
      );

  /// The timestamp on a row of its own, for bubbles whose body is a tile rather
  /// than text. Only ever used inside [_mediaColumn] — its `MainAxisSize.max` is
  /// deliberate there, because the enclosing width is the tile's and filling it
  /// is what right-aligns the stamp.
  static pw.Widget _metaRow(MessageModel m, bool isMe, ChatPdfFonts fonts) =>
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          if (m.isEdited)
            pw.Text(
              'edited · ',
              style: pw.TextStyle(
                font: fonts.italic,
                fontSize: 7,
                color: isMe ? _onSentSoft : _inkLow,
              ),
            ),
          pw.Text(
            _time(m.timestamp.toLocal()),
            style: pw.TextStyle(
              font: fonts.regular,
              fontSize: 7,
              color: isMe ? _onSentSoft : _inkLow,
            ),
          ),
        ],
      );

  /// The quoted strip a reply carries, mirroring the accent bar the chat screen
  /// draws. Truncated hard: a quote is a pointer, and a full copy of the quoted
  /// message would double the length of every reply chain in the file.
  static pw.Widget _replyQuote(MessageModel m, bool isMe, ChatPdfFonts fonts) {
    final label = (m.replyToSenderName ?? '').trim();
    final quoted = _replyPreview(m);

    return pw.Container(
      // Accent strip as a nested background rather than a left BorderSide — a
      // bordered box with a radius trips an assert in the PDF widget layer, and
      // this keeps the strip exactly as tall as the quote. Same shape as
      // [_disclosure].
      decoration: pw.BoxDecoration(
        color: isMe ? _white : _brand,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Container(
        margin: const pw.EdgeInsets.only(left: 2),
        padding: const pw.EdgeInsets.fromLTRB(7, 5, 8, 6),
        decoration: pw.BoxDecoration(
          color: isMe ? _sentPanel : const PdfColor.fromInt(0xFFEAE7F8),
          borderRadius: const pw.BorderRadius.only(
            topLeft: pw.Radius.circular(1),
            bottomLeft: pw.Radius.circular(1),
            topRight: pw.Radius.circular(6),
            bottomRight: pw.Radius.circular(6),
          ),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (label.isNotEmpty)
              pw.Text(
                label,
                maxLines: 1,
                overflow: pw.TextOverflow.clip,
                style: pw.TextStyle(
                  font: fonts.semiBold,
                  fontSize: 7.5,
                  color: isMe ? _white : _brandDeep,
                ),
              ),
            if (quoted.isNotEmpty)
              pw.Text(
                _drawable(quoted),
                maxLines: 2,
                overflow: pw.TextOverflow.clip,
                style: pw.TextStyle(
                  font: fonts.regular,
                  fontSize: 8,
                  color: isMe ? _onSentSoft : _inkMid,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _replyPreview(MessageModel m) {
    final text = (m.replyToText ?? '').trim();
    if (text.isNotEmpty) {
      return text.length > 140 ? '${text.substring(0, 140).trimRight()}…' : text;
    }
    switch (m.replyToType) {
      case 'image':
        return 'Photo';
      case 'video':
        return 'Video';
      case 'audio':
        return 'Voice message';
      default:
        return '';
    }
  }

  /// Reaction chips, or null when there are none — or when there is no emoji
  /// font, since the chip would then be an empty pill.
  static pw.Widget? _reactionChips(MessageModel m, ChatPdfFonts fonts) {
    final reactions = m.reactions;
    if (reactions == null || reactions.isEmpty || fonts.emoji == null) return null;

    final counts = <String, int>{};
    for (final emoji in reactions.values) {
      final key = _drawable(emoji.trim());
      if (key.isEmpty) continue;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;

    return pw.Wrap(
      spacing: 3,
      runSpacing: 3,
      children: [
        for (final e in counts.entries)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: pw.BoxDecoration(
              color: _white,
              borderRadius: pw.BorderRadius.circular(9),
              border: const pw.Border.fromBorderSide(
                pw.BorderSide(color: _line, width: 0.7),
              ),
            ),
            child: pw.Text(
              e.value > 1 ? '${e.key} ${e.value}' : e.key,
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: 8,
                color: _inkMid,
                fontFallback: fonts._fallback,
              ),
            ),
          ),
      ],
    );
  }

  // ── Media ──────────────────────────────────────────────────────────────

  /// The photo itself when its bytes came through, and a labelled tile when they
  /// did not.
  ///
  /// The width and height are both computed here rather than left to `BoxFit`:
  /// inside a `MultiPage` column the height constraint is unbounded, so an
  /// `Image` given only a width would size itself from the source pixels and a
  /// tall photo could exceed the page — which `MultiPage` reports as a thrown
  /// exception, not a scrollbar.
  static _MediaTile _photo(ChatPdfEntry entry, ChatPdfFonts fonts) {
    final bytes = entry.imageBytes;
    if (bytes != null) {
      try {
        final image = pw.MemoryImage(bytes);
        final w = (image.width ?? 1).toDouble();
        final h = (image.height ?? 1).toDouble();
        final scale = (w <= 0 || h <= 0)
            ? 1.0
            : [_photoMaxWidth / w, _photoMaxHeight / h, 1.0].reduce(
                (a, b) => a < b ? a : b,
              );
        return _MediaTile(
          w * scale,
          pw.ClipRRect(
            horizontalRadius: 8,
            verticalRadius: 8,
            child: pw.Image(
              image,
              width: w * scale,
              height: h * scale,
              fit: pw.BoxFit.cover,
            ),
          ),
        );
      } catch (_) {
        // Bytes that no decoder recognises. A placeholder is a better answer
        // than a failed export of an otherwise fine conversation.
      }
    }
    return _mediaPlaceholder('Photo not stored on this device', fonts);
  }

  static _MediaTile _videoTile(ChatPdfFonts fonts) => _MediaTile(
        _tileWidth,
        pw.Container(
          width: _tileWidth,
          height: 74,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: _slate,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Container(
                width: 20,
                height: 20,
                alignment: pw.Alignment.center,
                decoration: const pw.BoxDecoration(
                  color: _white,
                  shape: pw.BoxShape.circle,
                ),
                child: _playGlyph(_slate),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'Video',
                style: pw.TextStyle(
                  font: fonts.medium,
                  fontSize: 9,
                  color: _white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      );

  /// A vector triangle rather than a ▶ character: that glyph is not in Poppins,
  /// so it would come out as a blank box on the one tile whose whole job is to
  /// look like a video.
  static pw.Widget _playGlyph(PdfColor color) => pw.CustomPaint(
        size: const PdfPoint(9, 10),
        painter: (canvas, size) {
          canvas
            ..setFillColor(color)
            ..moveTo(1, 0.5)
            ..lineTo(1, size.y - 0.5)
            ..lineTo(size.x, size.y / 2)
            ..closePath()
            ..fillPath();
        },
      );

  static _MediaTile _voiceNote(int? seconds, bool isMe, ChatPdfFonts fonts) {
    // A drawn waveform, because the alternative is a row that just says
    // "audio". The bar heights are fixed rather than sampled: the file holds no
    // amplitude data, and inventing one per message would imply information the
    // export does not have. The count is chosen to fill [_tileWidth] alongside
    // the play badge and the longest duration a voice note can carry.
    const bars = <double>[
      4, 6, 9, 12, 8, 13, 10, 15, 11, 7, 12, 9, 14, 10, 6, 11, //
      15, 9, 13, 8, 12, 6, 10, 14, 9, 12, 7, 11, 8, 5, 9, 4, //
    ];

    return _MediaTile(
      _tileWidth,
      pw.SizedBox(
        width: _tileWidth,
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              width: 18,
              height: 18,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                color: isMe ? _sentBadge : _brandTint,
                shape: pw.BoxShape.circle,
              ),
              child: _playGlyph(isMe ? _white : _brand),
            ),
            pw.SizedBox(width: 7),
            for (final h in bars)
              pw.Container(
                width: 1.6,
                height: h,
                margin: const pw.EdgeInsets.only(right: 1.6),
                decoration: pw.BoxDecoration(
                  color: isMe ? _onSentSoft : _inkLow,
                  borderRadius: pw.BorderRadius.circular(1),
                ),
              ),
            pw.Expanded(
              child: pw.Text(
                seconds == null || seconds <= 0 ? 'Voice' : _duration(seconds),
                textAlign: pw.TextAlign.right,
                maxLines: 1,
                style: pw.TextStyle(
                  font: fonts.medium,
                  fontSize: 8,
                  color: isMe ? _onSent : _inkMid,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static _MediaTile _mediaPlaceholder(String label, ChatPdfFonts fonts) =>
      _MediaTile(
        _tileWidth,
        pw.Container(
          width: _tileWidth,
          height: 62,
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFF1F0F9),
            borderRadius: pw.BorderRadius.circular(8),
            border: const pw.Border.fromBorderSide(
              pw.BorderSide(color: _line, width: 0.7),
            ),
          ),
          child: pw.Text(
            label,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(font: fonts.italic, fontSize: 8, color: _inkMid),
          ),
        ),
      );

  // ── Formatting ─────────────────────────────────────────────────────────

  /// Splits [value] into pieces of at most [limit] characters, preferring a
  /// break at whitespace so a bubble never ends mid-word. Falls back to a hard
  /// cut for text with no spaces at all, which is the only way to bound the
  /// height of a 4,000-character URL.
  @visibleForTesting
  static List<String> chunkForTest(String value, int limit) =>
      _chunk(value, limit);

  static List<String> _chunk(String value, int limit) {
    if (value.length <= limit) return [value];

    final out = <String>[];
    var rest = value;
    while (rest.length > limit) {
      var cut = rest.lastIndexOf(RegExp(r'\s'), limit);
      // Only honour a break in the last third of the window; a space at
      // character 5 would otherwise produce a one-word bubble followed by an
      // equally oversized remainder.
      if (cut < limit ~/ 3) cut = limit;
      out.add(rest.substring(0, cut).trimRight());
      rest = rest.substring(cut).trimLeft();
    }
    if (rest.isNotEmpty) out.add(rest);
    return out;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _spanLabel(DateTime first, DateTime last) =>
      _sameDay(first, last)
          ? _dateLong(first)
          : '${_dateLong(first)} — ${_dateLong(last)}';

  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// `4 September 2026`. Hand-rolled for the same reason the text transcript's
  /// stamp is: this project carries no direct `intl` dependency, and adding one
  /// to name twelve months would not be a trade.
  static String _dateLong(DateTime t) {
    final l = t.toLocal();
    return '${l.day} ${_months[l.month - 1]} ${l.year}';
  }

  static String _time(DateTime t) =>
      '${_two(t.hour)}:${_two(t.minute)}';

  static String _duration(int seconds) =>
      '${seconds ~/ 60}:${_two(seconds % 60)}';

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _plural(int n, String noun) =>
      n == 1 ? '1 $noun' : '$n ${noun}s';
}
