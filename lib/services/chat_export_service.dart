import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/services/chat_service.dart';
import 'package:video_chat_app/services/crypto/plaintext_store.dart';
import 'package:video_chat_app/services/crypto/vault_cipher.dart';

/// Writes a conversation out as a plain-text transcript for the OS share sheet.
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
    final file = File('${dir.path}/${_fileName(contactName)}');
    await file.writeAsString(transcript);
    return file;
  }

  /// A share-sheet filename derived from the contact's name.
  ///
  /// Names are arbitrary user input and reach a real filesystem path here, so
  /// anything a path could interpret — separators, `..`, reserved Windows
  /// characters, control bytes — is collapsed to `_` rather than escaped.
  static String _fileName(String contactName) {
    var safe = contactName
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (safe.isEmpty || safe.replaceAll('.', '').isEmpty) safe = 'chat';
    if (safe.length > 40) safe = safe.substring(0, 40).trim();
    return 'GupShupGo chat with $safe.txt';
  }
}
