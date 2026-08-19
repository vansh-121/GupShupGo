// The four decisions behind the message hold menu's delete and edit.
//
// Each is a pure function, extracted and made static precisely because it is
// small enough to look obviously right and consequential enough to be worth
// pinning:
//
//   • ChatService.visibleMessages  — who sees what after a "delete for me".
//     Filter on the wrong uid and the message vanishes for the wrong person.
//   • ChatService.withinEditWindow — the 48h boundary, shared by Edit and
//     "Delete for everyone" so the menu greys out exactly what the service
//     refuses.
//   • SyncService.isNewerEdit      — whether an incoming document gets
//     decrypted again. This one decides whether an edit is ever visible to its
//     recipient at all: the metadata pass copies tick marks and never opens an
//     envelope, so a `false` here drops the new text on the floor forever.
//   • MessageModel.asTombstone     — that "deleted for everyone" genuinely
//     destroys content rather than flagging it.
//
// None of them needs Firestore, a clock, or a running app.

import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/services/chat_service.dart';
import 'package:video_chat_app/services/sync_service.dart';

const _alice = 'alice';
const _bob = 'bob';

MessageModel _msg({
  required String id,
  List<String> deletedFor = const [],
  bool deletedForEveryone = false,
  int minutesAgo = 0,
  String text = 'hello',
}) =>
    MessageModel(
      id: id,
      senderId: _alice,
      receiverId: _bob,
      text: text,
      timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000)
          .subtract(Duration(minutes: minutesAgo)),
      deletedFor: deletedFor,
      deletedForEveryone: deletedForEveryone,
    );

void main() {
  group('visibleMessages', () {
    test('a message I deleted for myself is hidden from me', () {
      final messages = [_msg(id: 'm1', deletedFor: const [_alice])];

      expect(ChatService.visibleMessages(messages, _alice, null), isEmpty);
    });

    test('a message the peer deleted is still visible to me', () {
      // The half that is easy to get backwards. `deletedFor` is per-user, so
      // filtering on the peer's entry would delete their messages off my
      // screen — and this is the assertion that catches it.
      final messages = [_msg(id: 'm1', deletedFor: const [_bob])];

      expect(ChatService.visibleMessages(messages, _alice, null), hasLength(1));
    });

    test('a tombstone survives the filter', () {
      // Deliberate: the whole point of "delete for everyone" is the marker it
      // leaves behind. Filtering it out here would leave the receiver with a
      // silently missing message and no explanation.
      final messages = [_msg(id: 'm1', deletedForEveryone: true, text: '')];

      expect(ChatService.visibleMessages(messages, _bob, null), hasLength(1));
    });

    test('both filters apply together', () {
      // clearedAt is the existing per-user hide ("clear chat"); deletedFor is
      // the new one. They are independent and must compose.
      final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      final messages = [
        _msg(id: 'old', minutesAgo: 120),
        _msg(id: 'deleted', deletedFor: const [_alice]),
        _msg(id: 'keep'),
      ];

      final visible = ChatService.visibleMessages(
        messages,
        _alice,
        now.subtract(const Duration(minutes: 60)),
      );

      expect(visible.map((m) => m.id), ['keep']);
    });

    test('an empty list stays empty rather than throwing', () {
      expect(ChatService.visibleMessages(const [], _alice, null), isEmpty);
    });
  });

  group('withinEditWindow', () {
    final sentAt = DateTime.fromMillisecondsSinceEpoch(1700000000000);

    test('a message sent moments ago is editable', () {
      expect(
        ChatService.withinEditWindow(sentAt,
            now: sentAt.add(const Duration(minutes: 1))),
        isTrue,
      );
    });

    test('the boundary itself is still inside the window', () {
      // Inclusive, so a message at exactly 48h does not flicker between
      // editable and not depending on which side of a millisecond it lands.
      expect(
        ChatService.withinEditWindow(sentAt, now: sentAt.add(ChatService.editWindow)),
        isTrue,
      );
    });

    test('one millisecond past the boundary is outside', () {
      expect(
        ChatService.withinEditWindow(
          sentAt,
          now: sentAt.add(ChatService.editWindow +
              const Duration(milliseconds: 1)),
        ),
        isFalse,
      );
    });

    test('a clock that has gone backwards does not close the window', () {
      // Reachable: `timestamp` can be a server timestamp while `now` is this
      // device's clock. A negative difference must read as "recent", never as
      // expired.
      expect(
        ChatService.withinEditWindow(sentAt,
            now: sentAt.subtract(const Duration(minutes: 5))),
        isTrue,
      );
    });
  });

  group('isNewerEdit', () {
    final t0 = DateTime.fromMillisecondsSinceEpoch(1700000000000);

    test('a never-edited message needs no re-decrypt', () {
      // The overwhelmingly common case: every read receipt and tick mark in the
      // room passes through here. Returning true would re-run libsignal on the
      // whole window on every snapshot.
      expect(SyncService.isNewerEdit(null, null), isFalse);
    });

    test('the first edit to arrive triggers a re-decrypt', () {
      expect(SyncService.isNewerEdit(null, t0), isTrue);
    });

    test('an edit we have already applied does not re-trigger', () {
      expect(SyncService.isNewerEdit(t0, t0), isFalse);
    });

    test('a second edit triggers again', () {
      expect(
        SyncService.isNewerEdit(t0, t0.add(const Duration(seconds: 30))),
        isTrue,
      );
    });

    test('an older server timestamp is ignored', () {
      // Guards against an out-of-order snapshot walking the local copy
      // backwards to a superseded version of the text.
      expect(
        SyncService.isNewerEdit(t0, t0.subtract(const Duration(seconds: 30))),
        isFalse,
      );
    });

    test('a server document with no editedAt never re-triggers', () {
      // Would otherwise loop forever: routed to content, decrypted, saved with
      // editedAt still set locally, and re-routed on the next snapshot.
      expect(SyncService.isNewerEdit(t0, null), isFalse);
    });
  });

  group('asTombstone', () {
    /// A message carrying something in every field a tombstone has to destroy.
    MessageModel loaded() => MessageModel(
          id: 'm1',
          senderId: _alice,
          receiverId: _bob,
          text: 'the secret',
          type: MessageType.image,
          timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000),
          mediaUrl: 'https://example.com/photo.jpg',
          localFilePath: '/data/user/0/app/photo.jpg',
          audioDuration: 12,
          schemaVersion: 2,
          senderDeviceId: 7,
          envelopes: const {'bob:3': {'body': 'ciphertext'}},
          reactions: const {'bob': '❤️'},
          linkPreviewUrl: 'https://example.com',
          linkPreviewImageBase64: 'aGVsbG8=',
          replyToMessageId: 'm0',
          replyToText: 'the quoted secret',
          deletedFor: const [_bob],
        );

    test('destroys every trace of content', () {
      // The reason this exists rather than a copyWith call: copyWith is
      // `x ?? this.x` for all forty parameters, so it cannot clear a field —
      // `copyWith(deletedForEveryone: true, text: '')` leaves the media URL, the
      // downloaded file, the envelopes, the reactions and the base64 preview
      // thumbnail sitting on a row the user was just told is deleted.
      final t = loaded().asTombstone();

      expect(t.text, isEmpty);
      expect(t.mediaUrl, isNull);
      expect(t.localFilePath, isNull);
      expect(t.audioDuration, isNull);
      expect(t.envelopes, isNull);
      expect(t.reactions, isNull);
      expect(t.linkPreviewUrl, isNull);
      expect(t.linkPreviewImageBase64, isNull);
      expect(t.replyToMessageId, isNull);
      expect(t.replyToText, isNull);
      expect(t.hasLinkPreview, isFalse);
      expect(t.hasReplyQuote, isFalse);
    });

    test('keeps what the bubble still needs to render itself', () {
      final original = loaded();
      final t = original.asTombstone();

      expect(t.id, original.id);
      expect(t.senderId, original.senderId);
      expect(t.receiverId, original.receiverId);
      expect(t.timestamp, original.timestamp);
      expect(t.deletedForEveryone, isTrue);
      // The peer's own "delete for me" must survive: a tombstone tells them the
      // message is gone, but so did their earlier decision, and dropping it
      // would resurrect the row on their screen.
      expect(t.deletedFor, const [_bob]);
    });

    test('survives a round-trip through the local cache', () {
      // Tombstones reach the UI through Drift, so the JSON serializer has to
      // carry the flag — otherwise the bubble reverts to rendering an empty
      // message after a restart.
      final t = MessageModel.fromJson(loaded().asTombstone().toJson());

      expect(t.deletedForEveryone, isTrue);
      expect(t.text, isEmpty);
      expect(t.mediaUrl, isNull);
    });
  });
}
