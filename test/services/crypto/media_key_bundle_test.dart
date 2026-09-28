// MediaKeyBundle survives the trip from sender to receiver.
//
// The bundle is the AES-256-GCM key for an encrypted attachment. It is not
// stored next to the blob — it travels *inside* the Signal-encrypted payload,
// which means it is serialized to a Map, JSON-encoded, carried over Firestore
// or the mesh, decoded, merged into a MessageModel, and only then handed back
// to `MediaKeyBundle.fromMap`. Six hops, four of which can quietly change a
// type.
//
// Every failure here is silent and total: a key that comes back with one wrong
// byte doesn't throw at parse time, it throws at *decrypt* time, by which point
// the plaintext is gone from the sender's device and the only copy of the file
// is ciphertext nobody can open. There is no repair path — unlike a failed
// message decrypt, which the resend protocol heals. So the round trip is worth
// pinning byte-for-byte.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/services/crypto/encrypted_media_service.dart';

/// A bundle with values chosen to be hostile to the serializers:
///  * key/iv/hash bytes include 0x00 and 0xFF, so a base64 round trip that
///    truncates or sign-extends is visible
///  * the key is a full 32 bytes and the iv a full 12, the real sizes
///  * `sizeBytes` is large enough to be wrong if anything downcasts to 32-bit
MediaKeyBundle _bundle() => MediaKeyBundle(
      key: List<int>.generate(32, (i) => i == 0 ? 0x00 : (i * 7) & 0xFF)
        ..[31] = 0xFF,
      iv: List<int>.generate(12, (i) => (255 - i * 3) & 0xFF)..[0] = 0x00,
      hash: List<int>.generate(32, (i) => (i * 13 + 1) & 0xFF)..[15] = 0xFF,
      url: 'https://firebasestorage.googleapis.com/v0/b/x/o/'
          'chat_documents%2Falice_bob%2Fa1b2c3?alt=media&token=abc-123',
      sizeBytes: 3221225488, // > 2^31, a real 3 GB-ish ciphertext length
      contentType: 'application/octet-stream',
    );

void _expectSameBundle(MediaKeyBundle actual, MediaKeyBundle expected) {
  expect(actual.key, expected.key, reason: 'AES key changed');
  expect(actual.iv, expected.iv, reason: 'GCM IV changed');
  expect(actual.hash, expected.hash, reason: 'integrity hash changed');
  expect(actual.url, expected.url);
  expect(actual.sizeBytes, expected.sizeBytes);
  expect(actual.contentType, expected.contentType);
}

void main() {
  group('toMap / fromMap', () {
    test('round trips byte-for-byte', () {
      final original = _bundle();
      _expectSameBundle(MediaKeyBundle.fromMap(original.toMap()), original);
    });

    test('survives a JSON encode/decode, as the wire payload does', () {
      final original = _bundle();
      final decoded =
          jsonDecode(jsonEncode(original.toMap())) as Map<String, dynamic>;
      _expectSameBundle(MediaKeyBundle.fromMap(decoded), original);
    });

    test('uses the compact wire keys', () {
      // The payload is Signal-encrypted per message and per device; the short
      // keys are a deliberate size choice, and renaming one silently breaks
      // every in-flight message from an older build.
      expect(_bundle().toMap().keys.toSet(), {'k', 'i', 'h', 'u', 's', 'c'});
    });

    test('defaults a missing content type rather than throwing', () {
      // Bundles written before `contentType` existed are still in vaults and
      // in undelivered payloads.
      final map = _bundle().toMap()..remove('c');
      expect(MediaKeyBundle.fromMap(map).contentType,
          'application/octet-stream');
    });

    test('a key with a zero byte is not truncated', () {
      // base64 has no terminator problem, but a hand-rolled hex or latin-1
      // path would stop at the first NUL — pin it so a future "optimisation"
      // of the encoding has to keep working.
      final original = MediaKeyBundle(
        key: List<int>.filled(32, 0),
        iv: List<int>.filled(12, 0),
        hash: List<int>.filled(32, 0),
        url: 'https://example.test/o/blob',
        sizeBytes: 16,
        contentType: 'image/jpeg',
      );
      final back = MediaKeyBundle.fromMap(original.toMap());
      expect(back.key, hasLength(32));
      expect(back.iv, hasLength(12));
      expect(back.hash, hasLength(32));
    });
  });

  group('through a MessageModel payload', () {
    MessageModel documentMessage(MediaKeyBundle b) => MessageModel(
          id: 'msg-1',
          senderId: 'alice',
          receiverId: 'bob',
          text: 'Q3 report.pdf',
          type: MessageType.document,
          timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000),
          schemaVersion: 2,
          fileName: 'Q3 report.pdf',
          mediaKey: b.toMap(),
        );

    test('survives toJson → jsonEncode → jsonDecode → fromJson', () {
      // This is the local-store path: PlaintextStore persists `message_json`
      // and reads it back on every cold start, so a document bubble that
      // renders before a restart and not after would be caught here.
      final original = _bundle();
      final json = jsonEncode(documentMessage(original).toJson());
      final restored = MessageModel.fromJson(jsonDecode(json));

      expect(restored.mediaKey, isNotNull);
      _expectSameBundle(MediaKeyBundle.fromMap(restored.mediaKey!), original);
      expect(restored.fileName, 'Q3 report.pdf');
      expect(restored.type, MessageType.document);
    });

    test('tolerates a loosely-typed map from the transport layer', () {
      // Firestore and the mesh codec both hand back maps typed
      // `Map<dynamic, dynamic>`. A bare `as Map<String, dynamic>` throws on
      // those — the model routes through a defensive parser instead, and this
      // is what proves it.
      final original = _bundle();
      final loose = <dynamic, dynamic>{...original.toMap()};

      final restored = MessageModel.fromMap(<String, dynamic>{
        'senderId': 'alice',
        'receiverId': 'bob',
        'text': 'Q3 report.pdf',
        'type': 'document',
        'schemaVersion': 2,
        'timestamp': 1700000000000,
        'fileName': 'Q3 report.pdf',
        'mediaKey': loose,
      }, 'msg-1');

      expect(restored.mediaKey, isNotNull,
          reason: 'a Map<dynamic, dynamic> mediaKey was dropped');
      _expectSameBundle(MediaKeyBundle.fromMap(restored.mediaKey!), original);
    });

    test('copyWith carries the bundle through unchanged', () {
      final original = _bundle();
      final edited =
          documentMessage(original).copyWith(status: MessageStatus.read);

      expect(edited.mediaKey, isNotNull);
      _expectSameBundle(MediaKeyBundle.fromMap(edited.mediaKey!), original);
    });

    test('a view-once bundle is dropped by asViewOnceConsumed', () {
      // The inverse guarantee, and the one the whole feature rests on: after
      // consumption the key must be *gone* from the model, not merely ignored
      // by the renderer.
      final consumed = MessageModel(
        id: 'msg-2',
        senderId: 'alice',
        receiverId: 'bob',
        text: '📷 Photo',
        type: MessageType.image,
        timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        schemaVersion: 2,
        mediaKey: _bundle().toMap(),
        viewOnce: true,
      ).asViewOnceConsumed('bob');

      expect(consumed.mediaKey, isNull);
      expect(consumed.mediaUrl, isNull);
      expect(consumed.localFilePath, isNull);
      expect(consumed.videoThumbnailBase64, isNull);
      expect(consumed.viewOnce, isTrue);
      expect(consumed.viewOnceOpenedBy, contains('bob'));

      // And it must still be gone after a persist/restore cycle.
      final restored =
          MessageModel.fromJson(jsonDecode(jsonEncode(consumed.toJson())));
      expect(restored.mediaKey, isNull);
      expect(restored.viewOnce, isTrue);
      expect(restored.viewOnceOpenedBy, contains('bob'));
    });
  });
}
