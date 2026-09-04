// What a chat export is allowed to contain.
//
// Export is the one feature in the app that takes an end-to-end encrypted
// conversation and writes it to a file another app will read, so the interesting
// assertions here are all about *exclusion*:
//
//   • A message the user deleted for themselves, or cleared, must not reappear
//     in a file they are about to hand to someone else.
//   • A "deleted for everyone" row must render as a tombstone even though the
//     retracted text can still be sitting in `text` on some code paths — the one
//     bug in this file that would leak content the sender explicitly retracted.
//   • An undecryptable placeholder must read as missing content, not as our own
//     lock-emoji error string, which would look like the export had failed.
//   • Ciphertext from `envelopes` must never reach the transcript.
//
// [ChatExportService.buildTranscript] and [ChatExportService.exportableMessages]
// are pure by design — the file writing lives in `exportChat` precisely so the
// formatting can be pinned with no device, no Firestore and no crypto. Every
// timestamp below is built with the local-time constructor, because `_stamp`
// renders `toLocal()` and a UTC literal would make the golden depend on the
// machine's timezone.

import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/services/chat_export_service.dart';
import 'package:video_chat_app/services/chat_service.dart';
import 'package:video_chat_app/services/crypto/vault_cipher.dart';

const _me = 'alice';
const _them = 'bob';
const _contact = 'Bob';

MessageModel _msg({
  String id = 'm',
  String from = _them,
  String text = '',
  MessageType type = MessageType.text,
  int? audioDuration,
  DateTime? at,
  List<String> deletedFor = const [],
  bool deletedForEveryone = false,
  Map<String, Map<String, dynamic>>? envelopes,
}) =>
    MessageModel(
      id: id,
      senderId: from,
      receiverId: from == _me ? _them : _me,
      text: text,
      type: type,
      audioDuration: audioDuration,
      timestamp: at ?? DateTime(2024, 3, 5, 9, 4),
      deletedFor: deletedFor,
      deletedForEveryone: deletedForEveryone,
      envelopes: envelopes,
    );

String _transcript(
  List<MessageModel> messages, {
  DateTime? clearedAt,
}) =>
    ChatExportService.buildTranscript(
      messages: messages,
      selfUserId: _me,
      contactName: _contact,
      exportedAt: DateTime(2024, 3, 5, 21, 0),
      clearedAt: clearedAt,
    );

void main() {
  group('golden transcript', () {
    /// One of every row type the exporter has to render, in the order
    /// `PlaintextStore` returns them (ascending).
    List<MessageModel> conversation() => [
          _msg(
            id: 'm1',
            text: 'Hey, are we still on for Friday?',
            at: DateTime(2024, 3, 5, 9, 4),
          ),
          _msg(
            id: 'm2',
            from: _me,
            text: 'Yes — 7pm at the usual place',
            at: DateTime(2024, 3, 5, 9, 5),
          ),
          _msg(
            id: 'm3',
            from: _me,
            type: MessageType.image,
            text: 'found this',
            at: DateTime(2024, 3, 5, 9, 6),
          ),
          _msg(
            id: 'm4',
            type: MessageType.image,
            at: DateTime(2024, 3, 5, 9, 7),
          ),
          _msg(
            id: 'm5',
            type: MessageType.audio,
            audioDuration: 65,
            at: DateTime(2024, 3, 5, 9, 8),
          ),
          _msg(
            id: 'm6',
            from: _me,
            type: MessageType.audio,
            audioDuration: 5,
            at: DateTime(2024, 3, 5, 9, 9),
          ),
          _msg(
            id: 'm7',
            from: _me,
            text: 'the retracted secret',
            deletedForEveryone: true,
            at: DateTime(2024, 3, 5, 9, 10),
          ),
          _msg(
            id: 'm8',
            text: VaultCipher.undecryptablePlaceholderText,
            at: DateTime(2024, 3, 5, 9, 11),
          ),
          _msg(
            id: 'm9',
            type: MessageType.reaction,
            text: '❤️',
            at: DateTime(2024, 3, 5, 9, 12),
          ),
          _msg(
            id: 'm10',
            from: _me,
            text: 'deleted from my side only',
            deletedFor: const [_me],
            at: DateTime(2024, 3, 5, 9, 13),
          ),
        ];

    // Pinned literally rather than assembled from the service's own constants:
    // this is the format an external text editor will show, so it is worth
    // breaking the test on any change to it, including a change to the
    // constants themselves.
    const expectedBody = '05/03/2024, 09:04 - Bob: Hey, are we still on for Friday?\n'
        '05/03/2024, 09:05 - You: Yes — 7pm at the usual place\n'
        '05/03/2024, 09:06 - You: <media omitted>\n'
        'found this\n'
        '05/03/2024, 09:07 - Bob: <media omitted>\n'
        '05/03/2024, 09:08 - Bob: <voice message, 1:05>\n'
        '05/03/2024, 09:09 - You: <voice message, 0:05>\n'
        '05/03/2024, 09:10 - You: This message was deleted\n'
        '05/03/2024, 09:11 - Bob: <message could not be decrypted>\n';

    test('renders every row type exactly', () {
      expect(_transcript(conversation()), endsWith(expectedBody));
    });

    test('the header names the contact and the export time', () {
      final t = _transcript(conversation());

      expect(t, startsWith('GupShupGo chat with Bob\n'));
      expect(t, contains('Exported 05/03/2024, 21:00\n'));
    });

    test('the header states that the transcript is device-local', () {
      // The honest limitation of exporting from the plaintext store: a message
      // decrypted on another device is simply absent. Saying so in the file is
      // the difference between a documented gap and a silent one.
      expect(
        _transcript(conversation()),
        contains('only the messages stored on this device'),
      );
    });

    test('no row appears twice and nothing extra sneaks in', () {
      // `endsWith` above would still pass if a stray line were prepended to the
      // body, so pin the line count too: 4 header lines (title, exported, blank,
      // limitation) + 1 blank + 8 message lines + 1 caption continuation.
      final lines = _transcript(conversation()).trimRight().split('\n');

      expect(lines.where((l) => l.contains(' - ')), hasLength(8));
      expect(lines.where((l) => l == 'found this'), hasLength(1));
    });
  });

  group('what must never reach the file', () {
    test('a retracted message does not leak its text', () {
      // The load-bearing case. A tombstone row can still carry the pre-delete
      // text in `text` depending on the path that produced it, so checking
      // `type` or `text` before `deletedForEveryone` would write content the
      // sender explicitly retracted into a file they are about to share.
      final t = _transcript([
        _msg(
          from: _me,
          text: 'transfer the money to account 4471',
          deletedForEveryone: true,
        ),
      ]);

      expect(t, isNot(contains('4471')));
      expect(t, contains(ChatService.deletedMessageText));
    });

    test('a message I deleted for myself is absent', () {
      final t = _transcript([
        _msg(from: _me, text: 'said too much', deletedFor: const [_me]),
      ]);

      expect(t, isNot(contains('said too much')));
    });

    test('a message the peer deleted for themselves is still mine to export', () {
      // The half that is easy to get backwards: `deletedFor` is per-user, so
      // filtering on the peer's entry would silently drop their side of the
      // conversation out of my own backup.
      final t = _transcript([
        _msg(text: 'still on my device', deletedFor: const [_them]),
      ]);

      expect(t, contains('still on my device'));
    });

    test('messages before a cleared-chat cutoff are absent', () {
      final t = _transcript(
        [
          _msg(text: 'before the clear', at: DateTime(2024, 3, 5, 8, 0)),
          _msg(text: 'after the clear', at: DateTime(2024, 3, 5, 10, 0)),
        ],
        clearedAt: DateTime(2024, 3, 5, 9, 0),
      );

      expect(t, isNot(contains('before the clear')));
      expect(t, contains('after the clear'));
    });

    test('ciphertext never reaches the transcript', () {
      // Export reads already-decrypted rows and performs zero crypto, so the
      // envelope a row was delivered in is dead weight here. If it ever showed
      // up in the output it would mean the exporter had started walking the
      // encrypted payload — the path that can corrupt a Signal ratchet.
      final t = _transcript([
        _msg(
          text: 'plain and cached',
          envelopes: const {
            'bob:3': {'body': 'MzM0ZmFrZS1jaXBoZXJ0ZXh0'},
          },
        ),
      ]);

      expect(t, contains('plain and cached'));
      expect(t, isNot(contains('MzM0ZmFrZS1jaXBoZXJ0ZXh0')));
    });
  });

  group('placeholder rows', () {
    test('every undecryptable placeholder reads as missing content', () {
      // Reproducing our own error strings verbatim would read as though the
      // export had failed rather than as though the message never arrived.
      // Legacy placeholders count: rows written by older builds are still in
      // the local store.
      for (final placeholder in [
        VaultCipher.undecryptablePlaceholderText,
        VaultCipher.pendingRetryPlaceholderText,
        "🔒 can't decrypt — ask sender to resend",
      ]) {
        final t = _transcript([_msg(text: placeholder)]);

        expect(t, contains(ChatExportService.undecryptable));
        expect(t, isNot(contains('🔒')));
        expect(t, isNot(contains('⏳')));
      }
    });

    test('a voice note with no known duration still renders', () {
      // `audioDuration` is null on rows that predate it and 0 on a recording
      // that failed to measure; neither should produce `<voice message, 0:00>`.
      for (final d in <int?>[null, 0]) {
        expect(
          _transcript([_msg(type: MessageType.audio, audioDuration: d)]),
          contains('<voice message>\n'),
        );
      }
    });

    test('an empty conversation says so instead of producing a bare header', () {
      final t = _transcript(const []);

      expect(t, contains('No messages available on this device.'));
      expect(t, isNot(contains(' - ')));
    });

    test('a conversation that is empty only after filtering says the same', () {
      // The reason `exportChat` calls `exportableMessages` rather than checking
      // `messages.isEmpty`: a chat full of reactions and self-deletes has rows
      // but nothing to export.
      final t = _transcript([
        _msg(type: MessageType.reaction, text: '👍'),
        _msg(from: _me, text: 'gone', deletedFor: const [_me]),
      ]);

      expect(t, contains('No messages available on this device.'));
    });
  });

  group('exportableMessages', () {
    test('reactions are dropped', () {
      // They render onto the bubble they target, so exporting them would
      // produce lines of bare emoji whose referent is unrecoverable.
      final messages = [
        _msg(id: 'text'),
        _msg(id: 'reaction', type: MessageType.reaction, text: '❤️'),
      ];

      expect(
        ChatExportService.exportableMessages(messages, _me, null).map((m) => m.id),
        ['text'],
      );
    });

    test('a tombstone survives so the gap is explained', () {
      final messages = [_msg(id: 'gone', deletedForEveryone: true)];

      expect(
        ChatExportService.exportableMessages(messages, _me, null),
        hasLength(1),
      );
    });

    test('ascending order is preserved', () {
      // The store guarantees it and the transcript relies on it; a filter that
      // reordered would produce a conversation that reads backwards.
      final messages = [
        _msg(id: 'a', at: DateTime(2024, 3, 5, 9, 0)),
        _msg(id: 'b', at: DateTime(2024, 3, 5, 9, 1)),
        _msg(id: 'c', at: DateTime(2024, 3, 5, 9, 2)),
      ];

      expect(
        ChatExportService.exportableMessages(messages, _me, null).map((m) => m.id),
        ['a', 'b', 'c'],
      );
    });

    test('it is exactly visibleMessages minus reactions', () {
      // Stated as an equality so the two predicates cannot drift apart: the
      // whole point of the shared helper is that a transcript can never contain
      // a message the chat screen was already hiding.
      final messages = [
        _msg(id: 'keep'),
        _msg(id: 'mine', from: _me, deletedFor: const [_me]),
        _msg(id: 'theirs', deletedFor: const [_them]),
        _msg(id: 'tombstone', deletedForEveryone: true),
      ];

      expect(
        ChatExportService.exportableMessages(messages, _me, null).map((m) => m.id),
        ChatService.visibleMessages(messages, _me, null)
            .where((m) => m.type != MessageType.reaction)
            .map((m) => m.id),
      );
    });
  });
}
