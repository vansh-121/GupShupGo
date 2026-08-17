// Recovery-path invariants for the E2EE receive pipeline.
//
// The reported bug was a received message rendering as
// "🔒 This message can't be decrypted on this device" — and then every message
// after it from the same peer failing too, for hours, in a chat that had been
// working minutes earlier. Losing one ratchet advance explains the first
// failure; what made it *permanent* were three separate invariants being
// violated at once. Each is asserted here.
//
// These are deliberately narrow, pure-function tests. decryptForRendering
// itself needs Firestore, Drift and libsignal all wired together, so the
// end-to-end recovery loop is covered by the two-device manual matrix.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:video_chat_app/services/chat_service.dart';
import 'package:video_chat_app/services/crypto/vault_cipher.dart';

/// Stand-in for libsignal's `InvalidMessageException`, which is not exported
/// from the package barrel and so cannot be constructed here. What matters is
/// that an unrecognised failure type lands in the default branch rather than
/// falling through to something more destructive.
class _UnexportedInvalidMessageException implements Exception {}

void main() {
  group('placeholder vocabulary', () {
    test('both live placeholders are recognised as placeholders', () {
      expect(
          VaultCipher.isPlaceholderText(VaultCipher.pendingRetryPlaceholderText),
          isTrue);
      expect(
          VaultCipher.isPlaceholderText(
              VaultCipher.undecryptablePlaceholderText),
          isTrue);
    });

    test('the pre-fix placeholder is still recognised', () {
      // Bubbles broken before this build persist this exact string in
      // `localMessages`. If it reads as real content it is never retried, so
      // the backfill sweep would skip precisely the messages it exists for.
      expect(
        VaultCipher.isPlaceholderText('🔒 can\'t decrypt — ask sender to resend'),
        isTrue,
      );
    });

    test('the two states are distinct strings', () {
      // "waiting" while a resend is in flight vs. "ask the sender" once
      // retries are exhausted. Collapsing them would either tell the user to
      // chase the sender while we are still repairing it ourselves, or never
      // tell them at all.
      expect(VaultCipher.pendingRetryPlaceholderText,
          isNot(VaultCipher.undecryptablePlaceholderText));
    });

    test('real message text is not mistaken for a placeholder', () {
      for (final text in <String>[
        '',
        'hey',
        '🔒',
        '🔒 Encrypted message', // the chatRoom preview placeholder
        'This message can\'t be decrypted on this device.', // no lock emoji
        '${VaultCipher.undecryptablePlaceholderText} ', // trailing space
      ]) {
        expect(VaultCipher.isPlaceholderText(text), isFalse,
            reason: 'treated ${text.isEmpty ? '<empty>' : text} as a '
                'placeholder — a real message would be silently re-decrypted '
                'and could be overwritten by a resend');
      }
    });
  });

  group('no negative caching (RC1)', () {
    test('isPlaceholderPayload reads the text field', () {
      expect(
        ChatService.isPlaceholderPayload(<String, dynamic>{
          'text': VaultCipher.pendingRetryPlaceholderText,
        }),
        isTrue,
      );
      expect(
        ChatService.isPlaceholderPayload(<String, dynamic>{'text': 'hello'}),
        isFalse,
      );
      // A payload with no text at all (a media message) is real content.
      expect(
        ChatService.isPlaceholderPayload(<String, dynamic>{
          'mediaUrl': 'https://example.test/x.jpg',
        }),
        isFalse,
      );
    });

    test('the payload memo refuses to hold a placeholder', () {
      // The memo is consulted before every other source and is never
      // invalidated by a resend, so one placeholder in here is a message that
      // can never be repaired for the rest of the process lifetime. That is
      // what turned a single transient failure into an all-day broken bubble.
      const id = 'msg-placeholder-must-not-memoize';
      ChatService.memoizeForTest(id, <String, dynamic>{
        'text': VaultCipher.undecryptablePlaceholderText,
      });
      expect(ChatService.memoEntryForTest(id), isNull);

      ChatService.memoizeForTest(id, <String, dynamic>{
        'text': VaultCipher.pendingRetryPlaceholderText,
      });
      expect(ChatService.memoEntryForTest(id), isNull);
    });

    test('the payload memo still holds real content', () {
      const id = 'msg-real-content-memoizes';
      ChatService.memoizeForTest(id, <String, dynamic>{'text': 'real text'});
      expect(ChatService.memoEntryForTest(id)?['text'], 'real text');
    });
  });

  group('decrypt-failure classification (RC3)', () {
    test('every failure asks the sender to resend', () {
      // The sender is the only party that can repair an unreadable message —
      // they hold the plaintext and can re-encrypt over a fresh session.
      // Anything that reaches the classifier has already missed the plaintext
      // store *and* the vault, so there is no local remedy left to try.
      final failures = <Object>[
        DuplicateMessageException('counter already consumed'),
        UntrustedIdentityException('peer-uid', null),
        _UnexportedInvalidMessageException(),
        AssertionError('corrupt state'),
        ArgumentError('bad ciphertext'),
        RangeError('truncated'),
        Exception('something else entirely'),
      ];
      for (final e in failures) {
        expect(ChatService.classifyDecryptFailure(e).requestResend, isTrue,
            reason: '${e.runtimeType} would render a dead placeholder with no '
                'attempt at recovery');
      }
    });

    test('trust is cleared only for a genuine identity change', () {
      // Clearing the pinned identity on anything else would make us silently
      // accept a substituted identity key on the next handshake.
      expect(
        ChatService.classifyDecryptFailure(
                UntrustedIdentityException('peer-uid', null))
            .clearTrust,
        isTrue,
      );
      for (final e in <Object>[
        DuplicateMessageException('dup'),
        _UnexportedInvalidMessageException(),
        AssertionError('corrupt'),
        Exception('other'),
      ]) {
        expect(ChatService.classifyDecryptFailure(e).clearTrust, isFalse,
            reason: '${e.runtimeType} dropped the pinned identity key');
      }
    });

    test('a duplicate is still recoverable', () {
      // Counter-intuitive but deliberate: Firestore re-emits every message on
      // every room change, and those re-emissions return from the plaintext
      // store long before libsignal is reached. Getting a duplicate *here*
      // means the ratchet moved past the message while no copy of the
      // plaintext survives, and a resend does repair that — the answer arrives
      // as a PreKeySignalMessage on a brand-new session and never touches the
      // exhausted counter.
      final v = ChatService.classifyDecryptFailure(
          DuplicateMessageException('already processed'));
      expect(v.requestResend, isTrue);
      expect(v.clearTrust, isFalse);
    });
  });

  group('no session teardown on the receive path (RC3, source guard)', () {
    // Tearing the ratchet down because *one* message failed only guarantees
    // that every message already in flight from that peer fails too — the peer
    // is never told and keeps ratcheting forward from a state we discarded.
    // Recovery belongs to the sender; see SignalService.resetSessionFor, which
    // is called from the send side only.
    test('neither ChatService nor SyncService deletes a session', () {
      for (final path in <String>[
        'lib/services/chat_service.dart',
        'lib/services/sync_service.dart',
      ]) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: '$path is missing');

        final lines = file.readAsLinesSync();
        final violations = <String>[];
        for (var i = 0; i < lines.length; i++) {
          // Strip line comments — the ban is on code, not on prose about it.
          final commentAt = lines[i].indexOf('//');
          final code =
              commentAt == -1 ? lines[i] : lines[i].substring(0, commentAt);
          if (code.contains('deleteSession')) {
            violations.add('$path:${i + 1}');
          }
        }
        expect(violations, isEmpty,
            reason: 'deleteSession on the receive path turns one unreadable '
                'message into a permanently dead conversation: '
                '${violations.join(', ')}');
      }
    });
  });
}
