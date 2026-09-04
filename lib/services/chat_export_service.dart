import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/services/chat_pdf_builder.dart';
import 'package:video_chat_app/services/chat_service.dart';
import 'package:video_chat_app/services/crypto/plaintext_store.dart';
import 'package:video_chat_app/services/crypto/vault_cipher.dart';
import 'package:video_chat_app/services/image_compressor.dart';

/// Writes a conversation out for the OS share sheet, as a laid-out PDF
/// ([exportChatPdf]) or a plain-text transcript ([exportChat]).
///
/// ## Why this reads the plaintext store and never decrypts
///
/// The only message source used here is [PlaintextStore.getMessages] — rows this
/// device has **already** decrypted and cached. Exporting deliberately performs
/// zero crypto.
///
/// The tempting alternative, walking history through `ChatService`'s decrypt
/// path, would be actively destructive. A libsignal 0.7.1 decrypt is
/// load → mutate → store on a shared `SessionRecord` with no lock, so replaying
/// a whole conversation through it advances and can corrupt the Signal ratchet —
/// the identical hazard `ChatService`'s pagination code documents. A failed
/// export must never cost the user their ability to receive messages.
///
/// The honest consequence is that the transcript covers only what this device
/// holds locally: a message that arrived on another device, or one still
/// awaiting a resend, is absent. [_header] says so in the file itself rather
/// than letting the user discover a silent gap.
///
/// ## Why the PDF can show real photos without breaking that rule
///
/// The PDF embeds the actual pictures, which sounds like it needs media
/// decryption and does not. `SyncService` already downloads and decrypts every
/// incoming attachment in the background and persists the resulting plain file's
/// path on the message row as `localFilePath`; it is the same file the chat
/// screen renders with `Image.file`. Reading it is a filesystem read of a file
/// this device wrote — no keys, no network, and nothing that touches a Signal
/// session. A message whose file was never downloaded, or whose cache the OS has
/// since reclaimed, gets the placeholder tile instead.
class ChatExportService {
  ChatExportService._();

  /// Shown in place of an image or video. The bytes are not exported; a
  /// transcript is a transcript, and bundling media would turn a 40 KB share
  /// into a multi-hundred-megabyte one.
  static const String mediaOmitted = '<media omitted>';

  /// Shown for a row whose stored text is one of the undecryptable
  /// placeholders. Reproducing `🔒 This message can't be decrypted…` verbatim
  /// would read as if the *export* had failed, so it is restated as what it is:
  /// content this device never held.
  static const String undecryptable = '<message could not be decrypted>';

  /// The rows that belong in a transcript: [ChatService.visibleMessages] minus
  /// reactions.
  ///
  /// Reactions are rendered onto the bubble they target, not as messages of
  /// their own — see the `nonReactionMessages` filter in `chat_screen`. Emitting
  /// them here would produce a transcript full of bare emoji whose referent is
  /// unrecoverable from the text.
  ///
  /// Public so [exportChat] can tell "nothing to export" from "something to
  /// export" without restating the predicate and drifting from it.
  static List<MessageModel> exportableMessages(
    List<MessageModel> messages,
    String selfUserId,
    DateTime? clearedAt,
  ) =>
      ChatService.visibleMessages(messages, selfUserId, clearedAt)
          .where((m) => m.type != MessageType.reaction)
          .toList();

  /// Builds the transcript body. Pure — no I/O, no clock, no Firestore — so the
  /// formatting is testable without a device, which is the whole reason the file
  /// writing lives in [exportChat] instead of here.
  ///
  /// [messages] must already be ascending by timestamp ([PlaintextStore]
  /// guarantees this) and is filtered through [exportableMessages], so a message
  /// the user deleted for themselves or cleared can never appear.
  static String buildTranscript({
    required List<MessageModel> messages,
    required String selfUserId,
    required String contactName,
    required DateTime exportedAt,
    DateTime? clearedAt,
    String selfName = 'You',
  }) {
    final visible = exportableMessages(messages, selfUserId, clearedAt);

    final out = StringBuffer(_header(contactName, exportedAt));
    if (visible.isEmpty) {
      out.writeln('No messages available on this device.');
      return out.toString();
    }
    for (final m in visible) {
      final who = m.senderId == selfUserId ? selfName : contactName;
      out.writeln('${_stamp(m.timestamp)} - $who: ${_body(m)}');
    }
    return out.toString();
  }

  static String _header(String contactName, DateTime exportedAt) =>
      'GupShupGo chat with $contactName\n'
      'Exported ${_stamp(exportedAt)}\n'
      '\n'
      'This transcript contains only the messages stored on this device. '
      'Messages are end-to-end encrypted, so anything received on another '
      'device — or not yet decrypted here — is not included. Photos, videos '
      'and voice notes are listed but their files are not exported.\n'
      '\n';

  /// One message's content, already reduced to display text.
  static String _body(MessageModel m) {
    // Tombstone first: a deleted-for-everyone row keeps whatever text it had
    // before the delete in some code paths, so checking type or text ahead of
    // this flag would leak the retracted content into the export.
    if (m.deletedForEveryone) return ChatService.deletedMessageText;

    switch (m.type) {
      case MessageType.image:
      case MessageType.video:
        // A caption travels in `text`. Continuation lines carry no timestamp
        // prefix, matching how a multi-line text message is emitted below.
        final caption = m.text.trim();
        return caption.isEmpty ? mediaOmitted : '$mediaOmitted\n$caption';
      case MessageType.audio:
        final d = m.audioDuration;
        return d == null || d <= 0
            ? '<voice message>'
            : '<voice message, ${_duration(d)}>';
      case MessageType.reaction:
        // Filtered out in buildTranscript; unreachable, but the switch is
        // exhaustive so a new MessageType breaks the build instead of silently
        // exporting an empty line.
        return '';
      case MessageType.text:
        return VaultCipher.isPlaceholderText(m.text) ? undecryptable : m.text;
    }
  }

  /// `dd/MM/yyyy, HH:mm`, hand-rolled because this project has no direct `intl`
  /// dependency and adding one to format five fields would not be a trade.
  static String _stamp(DateTime t) {
    final l = t.toLocal();
    return '${_two(l.day)}/${_two(l.month)}/${l.year}, '
        '${_two(l.hour)}:${_two(l.minute)}';
  }

  static String _duration(int seconds) =>
      '${seconds ~/ 60}:${_two(seconds % 60)}';

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// Reads the conversation, renders it and writes it to a shareable file.
  ///
  /// Returns `null` when there is nothing to export, so the caller can say so
  /// instead of opening a share sheet on an empty file. Throws if the
  /// `clearedAt` lookup fails — see [ChatService.getClearedAt]; treating an
  /// offline read as "never cleared" would export messages the user had cleared.
  static Future<File?> exportChat({
    required String chatRoomId,
    required String selfUserId,
    required String contactName,
  }) async {
    final store = await PlaintextStore.instance();
    final messages = await store.getMessages(chatRoomId);
    final clearedAt = await ChatService.instance.getClearedAt(
      chatRoomId,
      selfUserId,
    );
    if (exportableMessages(messages, selfUserId, clearedAt).isEmpty) {
      return null;
    }

    final transcript = buildTranscript(
      messages: messages,
      selfUserId: selfUserId,
      contactName: contactName,
      exportedAt: DateTime.now(),
      clearedAt: clearedAt,
    );

    // Temp is right here, unlike the chat-background images: the file exists
    // only long enough for the share sheet to hand it to another app, and
    // leaving transcripts in the documents directory would accumulate plaintext
    // copies of encrypted conversations on disk.
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_fileName(contactName, 'txt')}');
    await file.writeAsString(transcript);
    return file;
  }

  /// A share-sheet filename derived from the contact's name.
  ///
  /// Names are arbitrary user input and reach a real filesystem path here, so
  /// anything a path could interpret — separators, `..`, reserved Windows
  /// characters, control bytes — is collapsed to `_` rather than escaped.
  static String _fileName(String contactName, String extension) {
    var safe = contactName
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (safe.isEmpty || safe.replaceAll('.', '').isEmpty) safe = 'chat';
    if (safe.length > 40) safe = safe.substring(0, 40).trim();
    return 'GupShupGo chat with $safe.$extension';
  }

  // ── PDF ────────────────────────────────────────────────────────────────

  /// Longest edge, in pixels, of a photo embedded in the PDF.
  ///
  /// 900 px is roughly three times the ~250 pt the layout draws a photo at, so
  /// it still looks sharp on paper at 300 dpi while costing a fraction of the
  /// original. Skipping the re-encode would be simpler and would produce a file
  /// nobody can email: a hundred received photos at their sent size is 30 MB
  /// before the text is even laid out.
  static const int photoMaxEdge = 900;
  static const int photoQuality = 62;

  /// Total embedded-photo budget. Past this the remaining photos fall back to
  /// the placeholder tile, so a five-year conversation still produces a file the
  /// share sheet will accept rather than one that fails somewhere downstream.
  static const int photoByteBudget = 18 * 1024 * 1024;

  /// Source files above this are not even read. A cached "photo" this large is
  /// either not a photo or not worth the decode.
  static const int _photoSourceMax = 24 * 1024 * 1024;

  /// Renders the conversation as a PDF and writes it to a shareable file.
  ///
  /// Returns `null` for an empty conversation, matching [exportChat] so the
  /// caller has one "nothing to export" branch rather than two.
  static Future<File?> exportChatPdf({
    required String chatRoomId,
    required String selfUserId,
    required String contactName,
  }) async {
    final store = await PlaintextStore.instance();
    final messages = await store.getMessages(chatRoomId);
    final clearedAt = await ChatService.instance.getClearedAt(
      chatRoomId,
      selfUserId,
    );
    final visible = exportableMessages(messages, selfUserId, clearedAt);
    if (visible.isEmpty) return null;

    final entries = await _entriesWithPhotos(visible);
    final fonts = await _loadFonts(wantEmoji: _needsEmojiFont(visible));

    final bytes = await _render(
      entries: entries,
      selfUserId: selfUserId,
      contactName: contactName,
      fonts: fonts,
    );

    // Temp for the same reason the transcript is — see [exportChat]. A PDF is if
    // anything more sensitive: it carries the photos too.
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_fileName(contactName, 'pdf')}');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Lays out the document, retrying once without the emoji font if that font
  /// turns out to be one the PDF writer cannot use.
  ///
  /// The emoji face is read from whatever the platform happens to ship, so it is
  /// the one input here that was not built for this purpose and the one that can
  /// fail late — during `save()`, after the whole layout has been walked. Losing
  /// the emoji is a far better outcome than losing the export, and a chat is not
  /// worth a crash report over a vendor's font.
  static Future<Uint8List> _render({
    required List<ChatPdfEntry> entries,
    required String selfUserId,
    required String contactName,
    required ChatPdfFonts fonts,
  }) async {
    try {
      return await ChatPdfBuilder.build(
        entries: entries,
        selfUserId: selfUserId,
        contactName: contactName,
        exportedAt: DateTime.now(),
        fonts: fonts,
      );
    } catch (_) {
      if (fonts.emoji == null) rethrow;
      _emojiFont = null;
      _emojiResolved = true;
      return ChatPdfBuilder.build(
        entries: entries,
        selfUserId: selfUserId,
        contactName: contactName,
        exportedAt: DateTime.now(),
        fonts: fonts.withoutEmoji,
      );
    }
  }

  /// Pairs each message with its photo bytes, where there are any to pair.
  ///
  /// Sequential rather than a `Future.wait`: the budget check has to see what
  /// the previous photo cost, and running every decode at once on a long chat is
  /// how an export turns into an OOM on a low-end device.
  static Future<List<ChatPdfEntry>> _entriesWithPhotos(
    List<MessageModel> visible,
  ) async {
    var spent = 0;
    final out = <ChatPdfEntry>[];
    for (final m in visible) {
      Uint8List? bytes;
      final wantsPhoto = m.type == MessageType.image &&
          !m.deletedForEveryone &&
          spent < photoByteBudget;
      if (wantsPhoto) {
        bytes = await _photoBytes(m);
        if (bytes != null) spent += bytes.length;
      }
      out.add(ChatPdfEntry(message: m, imageBytes: bytes));
    }
    return out;
  }

  /// The cached, decrypted file for [m], re-encoded small enough to embed.
  ///
  /// Returns null for every ordinary reason a file might not be there — never
  /// downloaded, cache reclaimed, codec refused it — because all of them mean
  /// the same thing to the layout: draw the placeholder.
  static Future<Uint8List?> _photoBytes(MessageModel m) async {
    final path = m.localFilePath;
    if (path == null || path.isEmpty) return null;
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final length = await file.length();
      if (length <= 0 || length > _photoSourceMax) return null;
      return await ImageCompressor.compressThumbnailBytes(
        await file.readAsBytes(),
        maxEdge: photoMaxEdge,
        quality: photoQuality,
      );
    } catch (_) {
      return null;
    }
  }

  // Fonts are cached for the life of the process: the four Poppins faces are
  // ~630 KB of asset reads, and a user who exports one chat usually exports
  // another. `pw.Font` rebuilds its per-document object on demand, so reusing
  // these across documents is sound.
  static ChatPdfFonts? _textFonts;
  static pw.Font? _emojiFont;
  static bool _emojiResolved = false;

  static Future<ChatPdfFonts> _loadFonts({required bool wantEmoji}) async {
    final text = _textFonts ??= ChatPdfFonts(
      regular: pw.Font.ttf(
        await rootBundle.load('assets/fonts/poppins/Poppins-Regular.ttf'),
      ),
      medium: pw.Font.ttf(
        await rootBundle.load('assets/fonts/poppins/Poppins-Medium.ttf'),
      ),
      semiBold: pw.Font.ttf(
        await rootBundle.load('assets/fonts/poppins/Poppins-SemiBold.ttf'),
      ),
      italic: pw.Font.ttf(
        await rootBundle.load('assets/fonts/poppins/Poppins-Italic.ttf'),
      ),
    );
    if (!wantEmoji) return text;
    return text.withEmoji(await _loadEmojiFont());
  }

  /// Candidate colour-emoji fonts, in preference order.
  ///
  /// Reading the platform's own font is what makes emoji work here at no cost to
  /// the download size — the alternative is bundling ~10 MB of NotoColorEmoji in
  /// the APK, or fetching it at export time and failing offline. These files are
  /// world-readable on Android and the `pdf` package renders their CBDT bitmaps
  /// directly, which is why colour emoji come out in colour.
  ///
  /// iOS is deliberately absent: Apple Color Emoji is an sbix `.ttc`, a format
  /// the PDF writer cannot read, so there is nothing to try and emoji simply do
  /// not draw there. Dropping a monochrome `NotoEmoji-Regular.ttf` into
  /// `assets/fonts/emoji/` (and declaring it in pubspec.yaml) is picked up below
  /// and fixes that for both platforms if it ever matters enough.
  static const List<String> _systemEmojiFonts = [
    '/system/fonts/NotoColorEmoji.ttf',
    '/system/fonts/NotoColorEmojiCompat.ttf',
    '/system/fonts/SamsungColorEmoji.ttf',
    '/product/fonts/NotoColorEmoji.ttf',
    '/system/fonts/NotoColorEmojiLegacy.ttf',
  ];

  static const String _bundledEmojiFont =
      'assets/fonts/emoji/NotoEmoji-Regular.ttf';

  static Future<pw.Font?> _loadEmojiFont() async {
    if (_emojiResolved) return _emojiFont;
    _emojiResolved = true;

    if (Platform.isAndroid) {
      for (final path in _systemEmojiFonts) {
        try {
          final file = File(path);
          if (!await file.exists()) continue;
          final bytes = await file.readAsBytes();
          _emojiFont = pw.Font.ttf(ByteData.sublistView(bytes));
          return _emojiFont;
        } catch (_) {
          // Next candidate. A ROM that ships an unreadable font is not an error
          // the user needs to hear about.
        }
      }
    }

    try {
      _emojiFont = pw.Font.ttf(await rootBundle.load(_bundledEmojiFont));
    } catch (_) {
      // Not bundled, which is the normal case.
      _emojiFont = null;
    }
    return _emojiFont;
  }

  /// Whether anything in the export needs a font Poppins does not have.
  ///
  /// Worth checking before loading one: the platform emoji font is tens of
  /// megabytes, and most conversations do not need it. The ranges are the emoji
  /// and symbol blocks only — general punctuation is left out on purpose, since
  /// curly quotes and ellipses are in Poppins and matching them would load a
  /// 10 MB font for a `…`.
  @visibleForTesting
  static bool needsEmojiFont(List<MessageModel> messages) =>
      _needsEmojiFont(messages);

  static bool _needsEmojiFont(List<MessageModel> messages) {
    for (final m in messages) {
      if (m.reactions?.isNotEmpty ?? false) return true;
      if (_hasSymbolRune(m.text)) return true;
      if (_hasSymbolRune(m.replyToText ?? '')) return true;
    }
    return false;
  }

  static bool _hasSymbolRune(String value) {
    for (final rune in value.runes) {
      if (rune >= 0x1F000) return true; // emoji, pictographs, flags
      if (rune >= 0x2190 && rune <= 0x2BFF) return true; // arrows → dingbats
      if (rune == 0xFE0F || rune == 0x20E3) return true; // emoji/keycap markers
    }
    return false;
  }
}
