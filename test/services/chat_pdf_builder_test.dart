// What the PDF export must survive.
//
// A PDF is glyph-encoded and compressed, so almost nothing about its *appearance*
// is assertable from the bytes — searching the output for "Hey" finds nothing even
// when the word is on the page. That rules out golden-text assertions, so the
// tests here go after the failures this renderer can actually have, all of which
// are throws rather than wrong pixels:
//
//   • `MultiPage` throws — it does not clip — when a single child is taller than
//     a page. That makes bubble chunking and the media tile bounds correctness
//     concerns, not cosmetics, and it is why every message type is built here.
//   • `MemoryImage` throws on bytes it cannot decode. A cached "photo" that is
//     actually a truncated download must degrade to the placeholder tile, because
//     one bad file must not cost the user the whole export.
//   • Reaction chips are nothing but an emoji, so they are suppressed when no
//     emoji font could be loaded — an empty pill reads as a bug.
//
// The fonts below are the PDF base-14 faces, which need no asset bundle and so no
// `TestWidgetsFlutterBinding`. `zapfDingbats` stands in for the colour-emoji font
// the service reads off the platform: what matters to the layout is only whether
// a fallback font is present, not which one. The cost is that base-14 faces have
// no Unicode table, so these runs print "Helvetica has no Unicode support" and
// "unable to draw U+2014" for punctuation the shipped Poppins renders fine. That
// noise is the fixture's, not the renderer's — and the fact that it is a warning
// rather than a throw is itself one of the properties tested below.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/services/chat_export_service.dart';
import 'package:video_chat_app/services/chat_pdf_builder.dart';

const _me = 'alice';
const _them = 'bob';

/// Real 4×3 and 3×8 PNGs. Two aspect ratios because `_photo` derives *both*
/// dimensions from the image — `MultiPage` hands it unbounded height, so a tall
/// photo that scaled by width alone would exceed the page and throw.
final Uint8List _landscapePng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAQAAAADCAYAAAC09K7GAAAAAXNSR0IArs4c6QAAAARnQU1BA'
  'ACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAtSURBVBhXFchBEQAwDMOwwCmIgiicQD'
  'Qr76ankuAEL9hgsjiLt9j9UZziFVt8dWEa9QW/Cj8AAAAASUVORK5CYII=',
);

final Uint8List _portraitPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAMAAAAICAYAAAA870V8AAAAAXNSR0IArs4c6QAAAARnQU1BA'
  'ACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAABJSURBVBhXFccxEQAgDACxyumCA0TUBg'
  '4whANEvBwcPNdsiQjMwAqMmJgTa3Y25sbanYt5sW7nYT6s1xmYA2t0FubCWp2DebAOfhL1OSK'
  's7FC1AAAAAElFTkSuQmCC',
);

ChatPdfFonts _fonts({bool emoji = false}) => ChatPdfFonts(
      regular: pw.Font.helvetica(),
      medium: pw.Font.helvetica(),
      semiBold: pw.Font.helveticaBold(),
      italic: pw.Font.helveticaOblique(),
      emoji: emoji ? pw.Font.zapfDingbats() : null,
    );

MessageModel _msg({
  String id = 'm',
  String from = _them,
  String text = '',
  MessageType type = MessageType.text,
  int? audioDuration,
  DateTime? at,
  bool deletedForEveryone = false,
  DateTime? editedAt,
  Map<String, String>? reactions,
  String? replyToMessageId,
  String? replyToText,
  String? replyToType,
  String? localFilePath,
}) =>
    MessageModel(
      id: id,
      senderId: from,
      receiverId: from == _me ? _them : _me,
      text: text,
      type: type,
      audioDuration: audioDuration,
      timestamp: at ?? DateTime(2024, 3, 5, 9, 4),
      deletedForEveryone: deletedForEveryone,
      editedAt: editedAt,
      reactions: reactions,
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
      replyToType: replyToType,
      localFilePath: localFilePath,
    );

Future<Uint8List> _build(
  List<ChatPdfEntry> entries, {
  bool emoji = false,
}) =>
    ChatPdfBuilder.build(
      entries: entries,
      selfUserId: _me,
      contactName: 'Bob',
      exportedAt: DateTime(2024, 3, 5, 21, 0),
      fonts: _fonts(emoji: emoji),
    );

/// Asserts the bytes are a structurally complete PDF rather than merely
/// non-empty: a truncated write would still pass a length check.
void _expectPdf(Uint8List bytes) {
  expect(bytes.length, greaterThan(1000));
  expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
  final tail = latin1.decode(bytes.sublist(bytes.length - 64));
  expect(tail, contains('%%EOF'));
}

void main() {
  group('document', () {
    test('a one-message chat is a complete PDF', () async {
      _expectPdf(await _build([
        ChatPdfEntry(message: _msg(text: 'Hey, are we still on for Friday?')),
      ]));
    });

    test('an empty chat still produces a readable document', () async {
      // Reachable in principle even though `exportChatPdf` returns null for an
      // empty conversation: the layout must not depend on that guard, because a
      // zero-page PDF is a corrupt file, not an empty one.
      _expectPdf(await _build(const []));
    });

    test('metadata names the contact so file managers show something useful',
        () async {
      // The title is one of the few strings that lands in the output
      // uncompressed, which is exactly why it is worth pinning.
      final bytes = await _build([ChatPdfEntry(message: _msg(text: 'hi'))]);
      expect(latin1.decode(bytes, allowInvalid: true), contains('Bob'));
    });
  });

  group('every message type renders', () {
    // Built one type per test rather than all at once so a failure names the
    // type that broke instead of just "the export".
    final cases = <String, ChatPdfEntry>{
      'text': ChatPdfEntry(message: _msg(text: 'Yes — 7pm at the usual place')),
      'sent text': ChatPdfEntry(message: _msg(from: _me, text: 'On my way')),
      'empty text': ChatPdfEntry(message: _msg(text: '')),
      'edited text': ChatPdfEntry(
        message: _msg(text: 'make that 8pm', editedAt: DateTime(2024, 3, 5, 9, 9)),
      ),
      'photo with caption': ChatPdfEntry(
        message: _msg(type: MessageType.image, text: 'found this'),
        imageBytes: _landscapePng,
      ),
      'photo without caption': ChatPdfEntry(
        message: _msg(type: MessageType.image),
        imageBytes: _landscapePng,
      ),
      'photo not on this device': ChatPdfEntry(
        message: _msg(type: MessageType.image, text: 'gone'),
      ),
      'video': ChatPdfEntry(message: _msg(type: MessageType.video)),
      'video with caption': ChatPdfEntry(
        message: _msg(type: MessageType.video, text: 'watch till the end'),
      ),
      'voice note': ChatPdfEntry(
        message: _msg(type: MessageType.audio, audioDuration: 42),
      ),
      'voice note of unknown length': ChatPdfEntry(
        message: _msg(type: MessageType.audio),
      ),
      'long voice note': ChatPdfEntry(
        message: _msg(type: MessageType.audio, audioDuration: 3671),
      ),
      'deleted for everyone': ChatPdfEntry(
        message: _msg(text: 'retracted', deletedForEveryone: true),
      ),
      'undecryptable placeholder': ChatPdfEntry(
        message: _msg(text: "🔒 This message can't be decrypted"),
      ),
      'reply to text': ChatPdfEntry(
        message: _msg(
          text: 'agreed',
          replyToMessageId: 'm1',
          replyToText: 'shall we move it to 8?',
          replyToType: 'text',
        ),
      ),
      'reply to media': ChatPdfEntry(
        message: _msg(
          text: 'nice one',
          replyToMessageId: 'm1',
          replyToType: 'image',
        ),
      ),
      'reaction row': ChatPdfEntry(message: _msg(type: MessageType.reaction, text: '❤️')),
    };

    cases.forEach((name, entry) {
      test(name, () async => _expectPdf(await _build([entry])));
    });

    test('all of them together, across two days', () async {
      // The day divider, sender runs and page breaks only appear in a sequence,
      // so the combined case is not redundant with the per-type ones.
      final entries = <ChatPdfEntry>[];
      var i = 0;
      for (final entry in cases.values) {
        final day = i.isEven ? 5 : 6;
        entries.add(
          ChatPdfEntry(
            message: _msg(
              id: 'c$i',
              from: i % 3 == 0 ? _me : _them,
              text: entry.message.text,
              type: entry.message.type,
              audioDuration: entry.message.audioDuration,
              at: DateTime(2024, 3, day, 9, i),
              deletedForEveryone: entry.message.deletedForEveryone,
              replyToMessageId: entry.message.replyToMessageId,
              replyToText: entry.message.replyToText,
              replyToType: entry.message.replyToType,
            ),
            imageBytes: entry.imageBytes,
          ),
        );
        i++;
      }
      _expectPdf(await _build(entries));
    });
  });

  group('photos', () {
    test('a tall photo does not overflow the page', () async {
      // The failure this guards is specific: `MultiPage` throws "Widget won't fit
      // into the page" rather than scaling the image down.
      _expectPdf(await _build([
        ChatPdfEntry(
          message: _msg(type: MessageType.image),
          imageBytes: _portraitPng,
        ),
      ]));
    });

    test('undecodable bytes fall back to the placeholder', () async {
      // A truncated download or a file the OS handed back half-written. The
      // export must survive it; losing one tile is not losing the document.
      _expectPdf(await _build([
        ChatPdfEntry(
          message: _msg(type: MessageType.image, text: 'broken'),
          imageBytes: Uint8List.fromList(List<int>.filled(64, 7)),
        ),
      ]));
    });

    test('a PNG header with no image behind it falls back too', () async {
      // Decodable enough to be recognised as a PNG, not enough to draw — the
      // shape a partially downloaded file actually has.
      _expectPdf(await _build([
        ChatPdfEntry(
          message: _msg(type: MessageType.image),
          imageBytes: _landscapePng.sublist(0, 20),
        ),
      ]));
    });
  });

  group('reactions', () {
    test('render as chips when an emoji font is available', () async {
      _expectPdf(await _build(
        [
          ChatPdfEntry(
            message: _msg(
              text: 'we did it',
              reactions: const {_them: '🎉', _me: '🎉', 'carol': '❤️'},
            ),
          ),
        ],
        emoji: true,
      ));
    });

    test('are suppressed without one, and the bubble still renders', () async {
      _expectPdf(await _build([
        ChatPdfEntry(
          message: _msg(text: 'we did it', reactions: const {_them: '🎉'}),
        ),
      ]));
    });

    test('emoji in message text never fails the export', () async {
      // No font here can draw these. `pdf` blanks an unrenderable rune instead
      // of throwing, and that contract is what stops a heart from costing
      // someone their export — worth a test because it is a property of the
      // dependency, not of this code.
      _expectPdf(await _build([
        ChatPdfEntry(message: _msg(text: 'सब ठीक है 🙏🏽 चलो 🎉👨‍👩‍👧‍👦')),
      ]));
    });
  });

  group('long messages', () {
    test('a message far taller than a page is split, not dropped', () async {
      final wall = List.generate(600, (i) => 'word$i').join(' ');
      expect(wall.length, greaterThan(ChatPdfBuilder.charsPerBubble * 2));
      _expectPdf(await _build([ChatPdfEntry(message: _msg(text: wall))]));
    });

    test('a single unbroken token is split too', () async {
      // A pasted data URI or a very long URL: no whitespace to break at, so the
      // whitespace-preferring path has to fall through to a hard cut.
      _expectPdf(await _build([
        ChatPdfEntry(message: _msg(text: 'x' * (ChatPdfBuilder.charsPerBubble * 2 + 7))),
      ]));
    });

    test('many messages span many pages', () async {
      final entries = List.generate(
        400,
        (i) => ChatPdfEntry(
          message: _msg(
            id: 'm$i',
            from: i.isEven ? _me : _them,
            text: 'Message number $i, long enough to take a line or two of the '
                'page so the pagination actually gets exercised.',
            at: DateTime(2024, 3, 1).add(Duration(hours: i)),
          ),
        ),
      );
      _expectPdf(await _build(entries));
    });
  });

  group('chunking', () {
    test('short text is left alone', () {
      expect(ChatPdfBuilder.chunkForTest('hello', 20), ['hello']);
    });

    test('no chunk exceeds the limit', () {
      final text = List.generate(80, (i) => 'word$i').join(' ');
      for (final piece in ChatPdfBuilder.chunkForTest(text, 40)) {
        expect(piece.length, lessThanOrEqualTo(40));
      }
    });

    test('breaks at whitespace rather than mid-word', () {
      final pieces = ChatPdfBuilder.chunkForTest(
        'alpha bravo charlie delta echo foxtrot golf hotel',
        20,
      );
      expect(pieces.length, greaterThan(1));
      // Every piece is whole words: rejoining with single spaces reproduces the
      // original exactly, which can only hold if no word was cut.
      expect(pieces.join(' '), 'alpha bravo charlie delta echo foxtrot golf hotel');
    });

    test('a leading space does not produce a one-word chunk', () {
      // The last-third rule: a break at character 2 of a 30-character window
      // would leave a bubble holding one word and a remainder still too tall.
      final pieces = ChatPdfBuilder.chunkForTest('a ${'b' * 60}', 30);
      expect(pieces.first.length, greaterThan(10));
    });

    test('text with no whitespace is hard-cut without losing characters', () {
      final pieces = ChatPdfBuilder.chunkForTest('y' * 95, 30);
      expect(pieces.every((p) => p.length <= 30), isTrue);
      expect(pieces.join(), 'y' * 95);
    });

    test('the bubble limit is well under a page of text', () {
      // Not arbitrary: the value has to stay small enough that one bubble cannot
      // out-grow an A4 page, which is the condition `MultiPage` throws on.
      expect(ChatPdfBuilder.charsPerBubble, lessThan(2500));
    });
  });

  group('emoji font is loaded only when it is needed', () {
    // The platform colour-emoji font is tens of megabytes. Reading it for a chat
    // that contains none is the difference between an instant export and a
    // visible stall, so the predicate that decides is worth pinning.
    test('plain Latin text does not need it', () {
      expect(
        ChatExportService.needsEmojiFont([_msg(text: 'see you at 7pm, table 4')]),
        isFalse,
      );
    });

    test('Devanagari does not need it — Poppins covers that', () {
      expect(
        ChatExportService.needsEmojiFont([_msg(text: 'नमस्ते, कैसे हो?')]),
        isFalse,
      );
    });

    test('curly quotes and dashes do not need it', () {
      // The explicit reason General Punctuation is left out of the ranges: these
      // are in Poppins, and matching them would load 10 MB of font for an
      // ellipsis.
      expect(
        ChatExportService.needsEmojiFont([_msg(text: '“wait…” — he said')]),
        isFalse,
      );
    });

    test('an emoji anywhere in the text needs it', () {
      expect(
        ChatExportService.needsEmojiFont([_msg(text: 'on my way 🚗')]),
        isTrue,
      );
    });

    test('an arrow or dingbat needs it', () {
      expect(ChatExportService.needsEmojiFont([_msg(text: 'a → b ✓')]), isTrue);
    });

    test('a reaction needs it even when every message is plain', () {
      expect(
        ChatExportService.needsEmojiFont([
          _msg(text: 'nice', reactions: const {_them: '👍'}),
        ]),
        isTrue,
      );
    });

    test('an emoji only in a quoted reply still needs it', () {
      // The quote is drawn from `replyToText`, which is a separate field the
      // scan has to cover — a reply to an emoji-only message would otherwise
      // print an empty quote strip.
      expect(
        ChatExportService.needsEmojiFont([
          _msg(text: 'agreed', replyToText: 'party time 🎉'),
        ]),
        isTrue,
      );
    });
  });
}
