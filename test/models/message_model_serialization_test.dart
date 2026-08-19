// Serializer coverage for every field that may carry message content.
//
// A message's content crosses seven independent copies of the same key list on
// its way from one composer to another screen: five serializers here, the wire
// payload and the sender's vault copy in ChatService, and a third hand-built
// copy in SyncService's resend path. Adding a field and missing one of those
// sites does not throw — it silently drops the value, and each site drops it in
// a different scenario (cold restart, mesh hop, resend-after-decrypt-failure)
// that a quick manual test will not reproduce.
//
// So `kMessageContentKeys` is the single declared list, and these tests assert
// the serializers and ChatService.applyPayload actually honour it. This is the
// test that catches a missed serializer; the remaining sites are covered by the
// two-device matrix in the plan (notably step 7, the resend round).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/services/chat_service.dart';

/// A message with every link-preview and reply-quote field populated with a
/// distinguishable value, so a field silently swapped for another is visible.
MessageModel _fullyPopulated() => MessageModel(
      id: 'msg-1',
      senderId: 'alice',
      receiverId: 'bob',
      text: 'look at this https://flutter.dev',
      timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      schemaVersion: 2,
      senderDeviceId: 7,
      linkPreviewUrl: 'https://flutter.dev',
      linkPreviewTitle: 'Flutter - Build apps for any screen',
      linkPreviewDescription: 'Flutter transforms the app development process.',
      linkPreviewSiteName: 'flutter.dev',
      linkPreviewImageBase64: 'aGVsbG8=',
      replyToMessageId: 'msg-0',
      replyToSenderId: 'bob',
      replyToSenderName: 'Bob',
      replyToType: 'image',
      replyToText: 'here is the screenshot',
    );

/// Every key in [kMessageContentKeys] mapped to a sentinel of the right type.
Map<String, dynamic> _sentinelPayload() {
  final payload = <String, dynamic>{};
  for (final key in kMessageContentKeys) {
    // audioDuration is the one non-String content key.
    payload[key] = key == 'audioDuration' ? 4242 : 'sentinel::$key';
  }
  return payload;
}

void main() {
  group('kMessageContentKeys', () {
    test('has no duplicates', () {
      expect(
          kMessageContentKeys.toSet(), hasLength(kMessageContentKeys.length));
    });

    test('covers the link preview and reply quote families', () {
      for (final key in const [
        'linkPreviewUrl',
        'linkPreviewTitle',
        'linkPreviewDescription',
        'linkPreviewSiteName',
        'linkPreviewImageBase64',
        'replyToMessageId',
        'replyToSenderId',
        'replyToSenderName',
        'replyToType',
        'replyToText',
      ]) {
        expect(kMessageContentKeys, contains(key));
      }
    });
  });

  group('toJson / fromJson (mesh transport + local Drift cache)', () {
    test('preserves every link preview and reply quote field', () {
      final original = _fullyPopulated();
      final restored = MessageModel.fromJson(original.toJson());

      expect(restored.linkPreviewUrl, original.linkPreviewUrl);
      expect(restored.linkPreviewTitle, original.linkPreviewTitle);
      expect(restored.linkPreviewDescription, original.linkPreviewDescription);
      expect(restored.linkPreviewSiteName, original.linkPreviewSiteName);
      expect(restored.linkPreviewImageBase64, original.linkPreviewImageBase64);
      expect(restored.replyToMessageId, original.replyToMessageId);
      expect(restored.replyToSenderId, original.replyToSenderId);
      expect(restored.replyToSenderName, original.replyToSenderName);
      expect(restored.replyToType, original.replyToType);
      expect(restored.replyToText, original.replyToText);
    });

    test('an unset field round-trips as null, not as an empty string', () {
      // hasLinkPreview / hasReplyQuote gate rendering on null vs empty, and an
      // empty-string card would draw a blank strip in the bubble.
      final bare = MessageModel(
        id: 'm',
        senderId: 'a',
        receiverId: 'b',
        text: 'hi',
        timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
      final restored = MessageModel.fromJson(bare.toJson());
      expect(restored.linkPreviewUrl, isNull);
      expect(restored.replyToMessageId, isNull);
      expect(restored.hasLinkPreview, isFalse);
      expect(restored.hasReplyQuote, isFalse);
    });
  });

  group('toMap / fromMap (Firestore document)', () {
    test('preserves every link preview and reply quote field', () {
      final original = _fullyPopulated();
      final restored = MessageModel.fromMap(original.toMap(), original.id);

      expect(restored.linkPreviewUrl, original.linkPreviewUrl);
      expect(restored.linkPreviewTitle, original.linkPreviewTitle);
      expect(restored.linkPreviewDescription, original.linkPreviewDescription);
      expect(restored.linkPreviewSiteName, original.linkPreviewSiteName);
      expect(restored.linkPreviewImageBase64, original.linkPreviewImageBase64);
      expect(restored.replyToMessageId, original.replyToMessageId);
      expect(restored.replyToSenderId, original.replyToSenderId);
      expect(restored.replyToSenderName, original.replyToSenderName);
      expect(restored.replyToType, original.replyToType);
      expect(restored.replyToText, original.replyToText);
    });

    test('a null field is omitted from the document rather than written', () {
      final bare = MessageModel(
        id: 'm',
        senderId: 'a',
        receiverId: 'b',
        text: '',
        timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        schemaVersion: 2,
      );
      final map = bare.toMap();
      for (final key in const [
        'linkPreviewUrl',
        'linkPreviewTitle',
        'linkPreviewDescription',
        'linkPreviewSiteName',
        'linkPreviewImageBase64',
        'replyToMessageId',
        'replyToSenderId',
        'replyToSenderName',
        'replyToType',
        'replyToText',
      ]) {
        expect(map.containsKey(key), isFalse,
            reason: '$key should be absent, not an explicit null');
      }
      // Sanity: the timestamp really did go out as a Firestore type, so this
      // is exercising the Firestore serializer and not toJson by accident.
      expect(map['timestamp'], isA<Timestamp>());
    });
  });

  group('copyWith', () {
    test('carries the new fields through untouched', () {
      final original = _fullyPopulated();
      final copy = original.copyWith(text: 'edited');

      expect(copy.text, 'edited');
      expect(copy.linkPreviewUrl, original.linkPreviewUrl);
      expect(copy.linkPreviewImageBase64, original.linkPreviewImageBase64);
      expect(copy.replyToMessageId, original.replyToMessageId);
      expect(copy.replyToText, original.replyToText);
      expect(copy.replyToType, original.replyToType);
    });
  });

  group('ChatService.applyPayload', () {
    test('consumes every key declared in kMessageContentKeys', () {
      // The load-bearing test. Decryption hands applyPayload the inner JSON
      // from the Signal envelope; a key it fails to read is a field that
      // decrypts fine and then never renders, with nothing logged.
      //
      // Asserting through toJson() checks both halves at once: a key missing
      // from applyPayload reads back null, and so does a key missing from the
      // serializer.
      final payload = _sentinelPayload();
      final bare = MessageModel(
        id: 'm',
        senderId: 'a',
        receiverId: 'b',
        text: '', // v2 commits text as '' — the real text is in the payload
        timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        schemaVersion: 2,
      );

      final json = ChatService.applyPayload(bare, payload).toJson();

      for (final key in kMessageContentKeys) {
        expect(json[key], payload[key],
            reason: '"$key" is declared in kMessageContentKeys but did not '
                'survive applyPayload -> toJson. Check both '
                'ChatService.applyPayload and the MessageModel serializers.');
      }
    });

    test('an envelope from an older sender leaves the fields null', () {
      // The realistic base: a v2 Firestore doc, where plumbing point 5 has
      // already nulled every content field before the write. An old sender's
      // envelope carries no preview/quote keys at all, and the result must
      // simply have none rather than empty strings that would draw a blank
      // card strip in the bubble.
      final fromFirestore = MessageModel(
        id: 'm',
        senderId: 'a',
        receiverId: 'b',
        text: '',
        timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        schemaVersion: 2,
      );
      final applied =
          ChatService.applyPayload(fromFirestore, {'text': 'plain'});

      expect(applied.text, 'plain');
      expect(applied.linkPreviewUrl, isNull);
      expect(applied.replyToMessageId, isNull);
      expect(applied.hasLinkPreview, isFalse);
      expect(applied.hasReplyQuote, isFalse);
    });

    test('cannot clear a field the base already had — and need not', () {
      // applyPayload routes through copyWith, whose `?? this.x` fallback means
      // an absent payload key preserves the base value instead of clearing it.
      // That is safe only because of plumbing point 5: a v2 document is
      // committed with every content field null, so the base is always empty
      // when a payload is applied to it. Pinned here so the day someone gives
      // copyWith explicit-null semantics, or drops a point-5 guard, this test
      // is the one that argues about it.
      final base = _fullyPopulated();
      final applied = ChatService.applyPayload(base, {'text': 'plain'});

      expect(applied.linkPreviewUrl, base.linkPreviewUrl);
      expect(applied.replyToMessageId, base.replyToMessageId);
    });

    test('a payload with no text at all yields empty text, not null', () {
      // Unlike the other keys, `text` is read as `?? ''` rather than left to
      // copyWith — a non-null String field cannot hold null, and a bubble with
      // no text is a legitimate state (an image with no caption).
      expect(ChatService.applyPayload(_fullyPopulated(), const {}).text, '');
    });
  });

  group('render gates', () {
    test('hasLinkPreview requires a non-empty URL', () {
      final base = _fullyPopulated();
      expect(base.hasLinkPreview, isTrue);
      // copyWith cannot null a field out, so build the empty case directly.
      expect(
        MessageModel(
          id: 'm',
          senderId: 'a',
          receiverId: 'b',
          text: 'hi',
          timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000),
          linkPreviewUrl: '',
        ).hasLinkPreview,
        isFalse,
      );
    });

    test('hasReplyQuote requires a non-empty original id', () {
      final base = _fullyPopulated();
      expect(base.hasReplyQuote, isTrue);
      expect(
        MessageModel(
          id: 'm',
          senderId: 'a',
          receiverId: 'b',
          text: 'hi',
          timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000),
          replyToMessageId: '',
        ).hasReplyQuote,
        isFalse,
      );
    });
  });

  test('kReplySnippetMaxLength stays small enough to fan out safely', () {
    // The snippet is duplicated once per recipient device inside a single
    // Firestore document (1 MiB ceiling). 160 chars is two rendered lines and
    // a rounding error against that budget; a few thousand would not be.
    expect(kReplySnippetMaxLength, greaterThan(40));
    expect(kReplySnippetMaxLength, lessThanOrEqualTo(320));
  });
}
