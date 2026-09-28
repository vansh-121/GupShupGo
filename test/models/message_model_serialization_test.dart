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
      videoThumbnailBase64: 'dmlkZW8=',
      replyToMessageId: 'msg-0',
      replyToSenderId: 'bob',
      replyToSenderName: 'Bob',
      replyToType: 'image',
      replyToText: 'here is the screenshot',
    );

/// A document attachment, a location pin and a view-once flag, in one model.
///
/// Kept apart from [_fullyPopulated] because these three never co-occur on a
/// real message — a location carries no [MessageModel.mediaKey] and a document
/// is never view-once — and because [_fullyPopulated] is the base for the
/// "applyPayload cannot clear what the base already had" test, whose invariant
/// is deliberately different for `viewOnce`.
MessageModel _attachmentPopulated() => MessageModel(
      id: 'msg-2',
      senderId: 'alice',
      receiverId: 'bob',
      text: 'Q3 report.pdf',
      type: MessageType.document,
      timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      schemaVersion: 2,
      senderDeviceId: 7,
      fileName: 'Q3 report.pdf',
      mediaKey: const <String, dynamic>{
        'k': 'a2V5',
        'i': 'aXY=',
        'h': 'aGFzaA==',
        'u': 'https://example.test/o/blob',
        's': 1234,
        'c': 'application/pdf',
      },
      latitude: 12.9716,
      longitude: 77.5946,
      viewOnce: true,
      viewOnceOpenedBy: const ['bob'],
    );

/// Sentinels for the content keys that are not Strings.
///
/// Kept as a table rather than a chain of ternaries in [_sentinelPayload]: five
/// of the thirty keys are now non-String, and the next one added should be a
/// one-line entry here rather than another branch.
const Map<String, Object> _kNonStringSentinels = <String, Object>{
  'audioDuration': 4242,
  'latitude': 12.9716,
  'longitude': 77.5946,
  'viewOnce': true,
  // Shaped like a real MediaKeyBundle.toMap() — the compact wire keys are
  // k/i/h/u/s/c. A plain String here would pass applyPayload's `is Map` check
  // by failing it, i.e. silently, which is the exact class of bug this file
  // exists to catch.
  'mediaKey': <String, dynamic>{
    'k': 'a2V5',
    'i': 'aXY=',
    'h': 'aGFzaA==',
    'u': 'https://example.test/o/blob',
    's': 1234,
    'c': 'application/pdf',
  },
};

/// Every key in [kMessageContentKeys] mapped to a sentinel of the right type.
Map<String, dynamic> _sentinelPayload() {
  final payload = <String, dynamic>{};
  for (final key in kMessageContentKeys) {
    payload[key] = _kNonStringSentinels[key] ?? 'sentinel::$key';
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

    test('excludes the delete and edit metadata', () {
      // These three must stay OUT of the list, and the reason is the mirror
      // image of why everything else is in it. A content key gets a
      // `schemaVersion == 2 ? null : …` guard so it never reaches the server in
      // the clear. These have to be on the server document to work at all: a
      // delete that lives only on one device comes back with the next
      // reinstall's 50-document backfill, and a tombstone the receiver's sync
      // cannot see is indistinguishable from a document that slid out of the
      // window.
      //
      // Nothing here tells the server anything it did not already know — who
      // talked to whom, and when, is plaintext on the document regardless. If a
      // later change "fixes" these into the encrypted payload, delete and edit
      // both stop working across devices, and this test is the warning.
      for (final key in const [
        'deletedFor',
        'deletedForEveryone',
        'editedAt',
      ]) {
        expect(kMessageContentKeys, isNot(contains(key)));
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
      expect(restored.videoThumbnailBase64, original.videoThumbnailBase64);
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

    test('delete and edit metadata round-trips', () {
      final original = _fullyPopulated().copyWith(
        deletedFor: const ['bob'],
        deletedForEveryone: true,
        editedAt: DateTime.fromMillisecondsSinceEpoch(1700000060000),
      );
      final restored = MessageModel.fromJson(original.toJson());

      expect(restored.deletedFor, const ['bob']);
      expect(restored.deletedForEveryone, isTrue);
      expect(restored.editedAt, original.editedAt);
      expect(restored.isEdited, isTrue);
      expect(restored.isDeletedFor('bob'), isTrue);
      expect(restored.isDeletedFor('alice'), isFalse);
    });

    test('a row written by the old build reads as undeleted and unedited', () {
      // Drift stores the whole model as one JSON blob, so rows written before
      // these fields existed simply lack the keys. `deletedFor` in particular
      // must default to an empty list and never to null, or every caller needs
      // its own `?? const []`.
      final legacy = MessageModel.fromJson(const {
        'id': 'm',
        'senderId': 'a',
        'receiverId': 'b',
        'text': 'hi',
        'timestamp': 1700000000000,
      });

      expect(legacy.deletedFor, isEmpty);
      expect(legacy.deletedForEveryone, isFalse);
      expect(legacy.editedAt, isNull);
      expect(legacy.isEdited, isFalse);
      expect(legacy.isDeletedFor('a'), isFalse);
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
      expect(restored.videoThumbnailBase64, original.videoThumbnailBase64);
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
        'videoThumbnailBase64',
        'replyToMessageId',
        'replyToSenderId',
        'replyToSenderName',
        'replyToType',
        'replyToText',
        'fileName',
        'mediaKey',
        'latitude',
        'longitude',
        'viewOnce',
        'viewOnceOpenedBy',
      ]) {
        expect(map.containsKey(key), isFalse,
            reason: '$key should be absent, not an explicit null');
      }
      // Sanity: the timestamp really did go out as a Firestore type, so this
      // is exercising the Firestore serializer and not toJson by accident.
      expect(map['timestamp'], isA<Timestamp>());
    });

    test('delete and edit metadata round-trips', () {
      final original = _fullyPopulated().copyWith(
        deletedFor: const ['bob'],
        deletedForEveryone: true,
        editedAt: DateTime.fromMillisecondsSinceEpoch(1700000060000),
      );
      final map = original.toMap();
      expect(map['editedAt'], isA<Timestamp>());

      final restored = MessageModel.fromMap(map, original.id);
      expect(restored.deletedFor, const ['bob']);
      expect(restored.deletedForEveryone, isTrue);
      expect(restored.editedAt, original.editedAt);
    });

    test('an undeleted, unedited message writes none of the three keys', () {
      // Not cosmetic. This map is occasionally handed to a merging set(), and an
      // unconditional `deletedFor: []` would wipe the *other* participant's
      // "delete for me" — silently un-deleting a message on their device.
      final map = _fullyPopulated().toMap();
      for (final key in const [
        'deletedFor',
        'deletedForEveryone',
        'editedAt',
      ]) {
        expect(map.containsKey(key), isFalse,
            reason: '$key must not be written when it has nothing to say');
      }
    });
  });

  group('copyWith', () {
    test('carries the new fields through untouched', () {
      final original = _fullyPopulated();
      final copy = original.copyWith(text: 'edited');

      expect(copy.text, 'edited');
      expect(copy.linkPreviewUrl, original.linkPreviewUrl);
      expect(copy.linkPreviewImageBase64, original.linkPreviewImageBase64);
      expect(copy.videoThumbnailBase64, original.videoThumbnailBase64);
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

  group('attachment, location and view-once fields', () {
    test('round-trip through toJson / fromJson', () {
      // The local Drift cache and the mesh wire. A document that loses its
      // mediaKey here is a bubble that can never be opened again after a cold
      // restart — the ciphertext in Storage stays, but the only key is gone.
      final original = _attachmentPopulated();
      final restored = MessageModel.fromJson(original.toJson());

      expect(restored.type, MessageType.document);
      expect(restored.fileName, 'Q3 report.pdf');
      expect(restored.mediaKey, original.mediaKey);
      expect(restored.latitude, 12.9716);
      expect(restored.longitude, 77.5946);
      expect(restored.viewOnce, isTrue);
      expect(restored.viewOnceOpenedBy, const ['bob']);
    });

    test('round-trip through toMap / fromMap', () {
      final original = _attachmentPopulated();
      final restored = MessageModel.fromMap(original.toMap(), original.id);

      expect(restored.type, MessageType.document);
      expect(restored.fileName, 'Q3 report.pdf');
      expect(restored.mediaKey, original.mediaKey);
      expect(restored.latitude, 12.9716);
      expect(restored.longitude, 77.5946);
      expect(restored.viewOnce, isTrue);
      expect(restored.viewOnceOpenedBy, const ['bob']);
    });

    test('a whole-number coordinate survives as a double', () {
      // JSON gives back an int for 0.0, and `as double?` would throw on it.
      // Null Island is a real coordinate and so is the prime meridian.
      final restored = MessageModel.fromJson(const {
        'id': 'm',
        'senderId': 'a',
        'receiverId': 'b',
        'text': '',
        'timestamp': 1700000000000,
        'type': 'location',
        'latitude': 0,
        'longitude': 51,
      });

      expect(restored.latitude, 0.0);
      expect(restored.longitude, 51.0);
    });

    test('an unknown type from a newer build degrades to text', () {
      // Forward compatibility in the direction we cannot control. This is why
      // the send path also puts a human-readable fallback in `text`.
      final restored = MessageModel.fromJson(const {
        'id': 'm',
        'senderId': 'a',
        'receiverId': 'b',
        'text': '📍 Location',
        'timestamp': 1700000000000,
        'type': 'hologram',
      });

      expect(restored.type, MessageType.text);
      expect(restored.text, '📍 Location');
    });

    test('viewOnceOpenedBy is NOT a content key', () {
      // The mirror of the deletedFor/editedAt rule. It has to live on the
      // plaintext Firestore document or the sender never learns their media was
      // opened, and a reinstalled receiver loses the one flag that keeps it
      // unopenable. If a later change "fixes" it into the envelope, view-once
      // stops working across devices and this test is the warning.
      expect(kMessageContentKeys, isNot(contains('viewOnceOpenedBy')));
      expect(_attachmentPopulated().toMap()['viewOnceOpenedBy'],
          const ['bob']);
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
