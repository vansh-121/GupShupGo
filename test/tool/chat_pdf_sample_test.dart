// Writes a sample chat PDF so the layout can be looked at, not just asserted on.
//
// `chat_pdf_builder_test.dart` proves the renderer does not throw. It cannot prove
// the page looks good — a PDF's text is glyph-encoded and its content streams are
// compressed, so nothing about the design is readable from the bytes. This file
// closes that gap the only way it can be closed: it produces the real document,
// with the real bundled Poppins faces, for a human to open.
//
// Skipped by default, because a test that writes a file on every suite run is a
// side effect nobody asked for. To generate the sample:
//
//   $env:CHAT_PDF_SAMPLE = '1'                      # PowerShell
//   fvm flutter test test/tool/chat_pdf_sample_test.dart
//
// then open `build/chat_pdf_sample.pdf`. Run it after touching anything in
// `chat_pdf_builder.dart`: every layout regression this project has hit so far —
// an oversized child, a border the writer rejects, a glyph no font holds — shows
// up on page one.

import 'dart:io';

import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/services/chat_pdf_builder.dart';

const _me = 'alice';
const _them = 'bob';

/// Where an emoji font might live on a desktop, so the sample shows what a phone
/// will show. Segoe UI Emoji carries real outlines alongside its colour layers,
/// so the PDF writer draws it in monochrome rather than not at all — enough to
/// confirm the chips and inline emoji are placed correctly.
const List<String> _desktopEmojiFonts = [
  r'C:\Windows\Fonts\seguiemj.ttf',
  '/System/Library/Fonts/Apple Color Emoji.ttc',
  '/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf',
];

MessageModel _m({
  required String id,
  String from = _them,
  String text = '',
  MessageType type = MessageType.text,
  int? audioDuration,
  required DateTime at,
  bool deletedForEveryone = false,
  DateTime? editedAt,
  Map<String, String>? reactions,
  String? replyToMessageId,
  String? replyToText,
  String? replyToSenderName,
  String? replyToType,
}) =>
    MessageModel(
      id: id,
      senderId: from,
      receiverId: from == _me ? _them : _me,
      text: text,
      type: type,
      audioDuration: audioDuration,
      timestamp: at,
      deletedForEveryone: deletedForEveryone,
      editedAt: editedAt,
      reactions: reactions,
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
      replyToSenderName: replyToSenderName,
      replyToType: replyToType,
    );

void main() {
  final enabled = Platform.environment['CHAT_PDF_SAMPLE'] == '1';

  test(
    'writes build/chat_pdf_sample.pdf',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();

      Future<pw.Font> face(String name) async =>
          pw.Font.ttf(await rootBundle.load('assets/fonts/poppins/$name.ttf'));

      pw.Font? emoji;
      for (final path in _desktopEmojiFonts) {
        final file = File(path);
        if (!file.existsSync()) continue;
        try {
          emoji = pw.Font.ttf(ByteData.sublistView(await file.readAsBytes()));
          break;
        } catch (_) {
          // A font this writer cannot parse — same fallback the service takes.
        }
      }

      final fonts = ChatPdfFonts(
        regular: await face('Poppins-Regular'),
        medium: await face('Poppins-Medium'),
        semiBold: await face('Poppins-SemiBold'),
        italic: await face('Poppins-Italic'),
        emoji: emoji,
      );

      // The app icon stands in for a received photo: a real asset, so the sample
      // exercises the actual embed-and-clip path rather than a synthetic tile.
      final photo = (await rootBundle.load('assets/icon/app_icon.png'))
          .buffer
          .asUint8List();

      DateTime d1(int h, int m) => DateTime(2026, 8, 30, h, m);
      DateTime d2(int h, int m) => DateTime(2026, 9, 2, h, m);

      final entries = <ChatPdfEntry>[
        ChatPdfEntry(
          message: _m(
            id: '1',
            text: 'Are we still on for Friday? नमस्ते 🙏',
            at: d1(9, 12),
          ),
        ),
        ChatPdfEntry(
          message: _m(
            id: '2',
            from: _me,
            text: 'Yes — 7pm at the usual place',
            at: d1(9, 14),
            reactions: const {_them: '👍'},
          ),
        ),
        ChatPdfEntry(
          message: _m(
            id: '3',
            from: _me,
            text: 'make that 7:30, meeting ran over',
            editedAt: d1(9, 21),
            at: d1(9, 20),
          ),
        ),
        ChatPdfEntry(
          message: _m(
            id: '4',
            text: 'works for me',
            replyToMessageId: '3',
            replyToSenderName: 'You',
            replyToText: 'make that 7:30, meeting ran over',
            replyToType: 'text',
            at: d1(9, 24),
          ),
        ),
        ChatPdfEntry(
          message: _m(
            id: '5',
            text: 'look what I found in the old album',
            type: MessageType.image,
            at: d1(9, 31),
            reactions: const {_me: '❤️', 'carol': '❤️', 'dan': '😂'},
          ),
          imageBytes: photo,
        ),
        ChatPdfEntry(
          message: _m(id: '6', from: _me, type: MessageType.image, at: d1(9, 33)),
        ),
        ChatPdfEntry(
          message: _m(
            id: '7',
            type: MessageType.audio,
            audioDuration: 47,
            at: d1(9, 40),
          ),
        ),
        ChatPdfEntry(
          message: _m(
            id: '8',
            from: _me,
            type: MessageType.video,
            text: 'watch till the end',
            at: d1(9, 42),
          ),
        ),
        ChatPdfEntry(
          message: _m(
            id: '9',
            text: 'this one got pulled back',
            deletedForEveryone: true,
            at: d2(11, 2),
          ),
        ),
        ChatPdfEntry(
          message: _m(
            id: '10',
            from: _me,
            text: 'A deliberately long one, so the sample shows how a paragraph '
                'wraps inside a bubble and where the timestamp lands once the '
                'text runs past a single line. It should read like a chat, not '
                'like a table of rows: the bubble keeps its tail, the metadata '
                'stays quiet in the corner, and nothing about it should look '
                'like a database dump printed sideways.',
            at: d2(11, 5),
          ),
        ),
        ChatPdfEntry(
          message: _m(
            id: '11',
            text: 'agreed 🎉 see you then',
            at: d2(11, 9),
          ),
        ),
      ];

      final bytes = await ChatPdfBuilder.build(
        entries: entries,
        selfUserId: _me,
        contactName: 'Bob Sharma',
        exportedAt: DateTime(2026, 9, 4, 18, 30),
        fonts: fonts,
      );

      final out = File('build/chat_pdf_sample.pdf');
      await out.parent.create(recursive: true);
      await out.writeAsBytes(bytes, flush: true);

      // ignore: avoid_print
      print('Wrote ${out.absolute.path} (${bytes.length ~/ 1024} KB, '
          'emoji font: ${emoji == null ? 'none' : 'yes'})');

      expect(bytes.length, greaterThan(1000));
    },
    skip: enabled ? false : 'set CHAT_PDF_SAMPLE=1 to write the sample PDF',
  );
}
