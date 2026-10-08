/// Unit tests for [AiAssistantService]'s pure logic — the two pieces that
/// decide what travels to the server and how its answer is read, with no
/// Firebase, no local store, and no network.
///
/// `sendMessage` / `retryLast` themselves lean on the `FirebaseAuth` and
/// `PlaintextStore` singletons, so they're exercised by the on-device E2E pass,
/// not here. What's unit-testable — and worth it — is [buildHistory]'s trim and
/// role-mapping, and [classifyResponse]'s status→outcome routing (the 429/503
/// states the chat UI renders differently from a hard failure).
///
/// Run: `flutter test test/ai_assistant_service_test.dart`
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/services/ai/ai_assistant_service.dart';

void main() {
  group('buildHistory', () {
    const uid = 'user-123';

    MessageModel msg(
      String senderId,
      String text, {
      MessageType type = MessageType.text,
    }) =>
        MessageModel(
          id: '$senderId:$text',
          senderId: senderId,
          receiverId: 'x',
          text: text,
          type: type,
          timestamp: DateTime(2026, 1, 1),
        );

    test('maps user vs model role by senderId', () {
      final turns = AiAssistantService.buildHistory([
        msg(uid, 'hello'),
        msg(kAiRoomId, 'hi there'),
      ], uid);

      expect(turns, [
        {'role': 'user', 'text': 'hello'},
        {'role': 'model', 'text': 'hi there'},
      ]);
    });

    test('skips non-text and blank turns', () {
      final turns = AiAssistantService.buildHistory([
        msg(uid, 'keep me'),
        msg(uid, '   '), // whitespace-only → dropped
        msg(uid, 'an image', type: MessageType.image), // non-text → dropped
        msg(kAiRoomId, 'reply'),
      ], uid);

      expect(turns, [
        {'role': 'user', 'text': 'keep me'},
        {'role': 'model', 'text': 'reply'},
      ]);
    });

    test('trims surrounding whitespace in the sent text', () {
      final turns = AiAssistantService.buildHistory([msg(uid, '  spaced  ')], uid);
      expect(turns.single['text'], 'spaced');
    });

    test('keeps only the most recent 20 turns', () {
      final messages = [for (var i = 0; i < 25; i++) msg(uid, 'm$i')];
      final turns = AiAssistantService.buildHistory(messages, uid);

      expect(turns.length, 20);
      expect(turns.first['text'], 'm5'); // the first five are dropped
      expect(turns.last['text'], 'm24');
    });

    test('an empty transcript yields no turns', () {
      expect(AiAssistantService.buildHistory(const [], uid), isEmpty);
    });
  });

  group('classifyResponse', () {
    test('200 with a reply returns AiReplyReceived + the trimmed reply to save', () {
      final (result, reply) = AiAssistantService.classifyResponse(
        200,
        {'reply': '  hello world  ', 'remaining': 7},
      );

      expect(result, isA<AiReplyReceived>());
      expect((result as AiReplyReceived).remaining, 7);
      expect(reply, 'hello world');
    });

    test('200 with a missing remaining defaults it to 0', () {
      final (result, _) = AiAssistantService.classifyResponse(200, {'reply': 'hi'});
      expect((result as AiReplyReceived).remaining, 0);
    });

    test('200 with a blank reply is treated as busy and persists nothing', () {
      final (result, reply) =
          AiAssistantService.classifyResponse(200, {'reply': '   '});

      expect(result, isA<AiBusy>());
      expect((result as AiBusy).reason, 'empty');
      expect(reply, isNull);
    });

    test('429 maps to AiQuotaExceeded carrying the server flags', () {
      final (result, reply) = AiAssistantService.classifyResponse(
        429,
        {'isPro': true, 'canEarn': false},
      );

      expect(result, isA<AiQuotaExceeded>());
      final quota = result as AiQuotaExceeded;
      expect(quota.isPro, isTrue);
      expect(quota.canEarn, isFalse);
      expect(reply, isNull);
    });

    test('429 with missing flags defaults both to false', () {
      final (result, _) = AiAssistantService.classifyResponse(429, const {});
      final quota = result as AiQuotaExceeded;
      expect(quota.isPro, isFalse);
      expect(quota.canEarn, isFalse);
    });

    test('503 uses the server reason, falling back to "busy"', () {
      expect(
        (AiAssistantService.classifyResponse(503, {'reason': 'disabled'}).$1
                as AiBusy)
            .reason,
        'disabled',
      );
      expect(
        (AiAssistantService.classifyResponse(503, const {}).$1 as AiBusy).reason,
        'busy',
      );
    });

    test('other statuses become AiSendFailed with the best available reason', () {
      expect(
        (AiAssistantService.classifyResponse(500, {'reason': 'boom'}).$1
                as AiSendFailed)
            .message,
        'boom',
      );
      expect(
        (AiAssistantService.classifyResponse(401, {'error': 'unauthorized'}).$1
                as AiSendFailed)
            .message,
        'unauthorized',
      );
      expect(
        (AiAssistantService.classifyResponse(418, const {}).$1 as AiSendFailed)
            .message,
        'http-418',
      );
    });

    test('no outcome but the good-200 one carries a reply to persist', () {
      // Guards the invariant the save path depends on: only a real reply is
      // ever written locally.
      for (final status in [429, 503, 500, 400, 401]) {
        expect(
          AiAssistantService.classifyResponse(status, const {}).$2,
          isNull,
          reason: 'status $status must not persist anything',
        );
      }
    });
  });
}
