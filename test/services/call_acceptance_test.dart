import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/services/call_acceptance.dart';

void main() {
  test('duplicate Accept and resume share one server claim', () async {
    final h = _Harness();
    final first = h.acceptance.connect();
    final duplicate = h.acceptance.connect();
    expect(identical(first, duplicate), isTrue);
    expect(await first, CallAnswerOutcome.accepted);
    expect(h.answers, 1);
    expect(h.acknowledgments, 1);
    expect(h.acceptance.readyForMedia, isTrue);
    expect(h.finishes, 0);
    await h.acceptance.close();
  });

  test('does not claim a cancelled native inbox', () async {
    final h = _Harness()..pending = false;
    expect(await h.acceptance.connect(), CallAnswerOutcome.cancelled);
    await h.acceptance.close();
    expect(h.answers, 0);
    expect(h.acknowledgments, 0);
    expect(h.acceptance.readyForMedia, isFalse);
  });

  for (final outcome in [
    CallAnswerOutcome.answeredElsewhere,
    CallAnswerOutcome.expired,
    CallAnswerOutcome.ended,
    CallAnswerOutcome.missing,
    CallAnswerOutcome.signedOut,
  ]) {
    test('$outcome never starts media or acknowledges acceptance', () async {
      final h = _Harness()..answer = (() async => outcome);
      expect(await h.acceptance.connect(), outcome);
      await h.acceptance.close();
      expect(h.acknowledgments, 0);
      expect(h.acceptance.readyForMedia, isFalse);
    });
  }

  test('End while answer is in flight prevents late media startup', () async {
    final h = _Harness();
    final response = Completer<CallAnswerOutcome>();
    final started = Completer<void>();
    h.answer = () {
      started.complete();
      return response.future;
    };
    final connection = h.acceptance.connect();
    await started.future;
    await h.acceptance.close();
    response.complete(CallAnswerOutcome.accepted);
    expect(await connection, CallAnswerOutcome.cancelled);
    expect(h.acceptance.readyForMedia, isFalse);
    expect(h.acknowledgments, 0);
    // One cleanup when closing, another to retract the eventual server answer.
    expect(h.releases, 2);
    expect(h.finishes, 1);
  });

  test('cancellation after server answer prevents a native acknowledgement',
      () async {
    final h = _Harness();
    h.answer = () async {
      h.pending = false;
      return CallAnswerOutcome.accepted;
    };
    expect(await h.acceptance.connect(), CallAnswerOutcome.cancelled);
    await h.acceptance.close();
    expect(h.acknowledgments, 0);
    expect(h.acceptance.readyForMedia, isFalse);
  });

  test('a rejected acknowledgement cannot start media', () async {
    final h = _Harness()..acknowledge = (() async => false);
    expect(await h.acceptance.connect(), CallAnswerOutcome.cancelled);
    await h.acceptance.close();
    expect(h.acceptance.readyForMedia, isFalse);
  });

  test('End during native acknowledgement prevents a late join', () async {
    final h = _Harness();
    final response = Completer<bool>();
    final started = Completer<void>();
    h.acknowledge = () {
      started.complete();
      return response.future;
    };
    final connection = h.acceptance.connect();
    await started.future;
    await h.acceptance.close();
    response.complete(true);
    expect(await connection, CallAnswerOutcome.cancelled);
    expect(h.acceptance.readyForMedia, isFalse);
  });

  test('a transient transaction failure retries without consuming the inbox',
      () async {
    final h = _Harness();
    h.answer = () async {
      if (h.answers == 1) {
        throw const CallAcceptanceException('transaction_unavailable',
            retryable: true);
      }
      return CallAnswerOutcome.accepted;
    };
    expect(await h.acceptance.connect(), CallAnswerOutcome.accepted);
    expect(h.answers, 2);
    expect(h.finishes, 0);
    expect(h.events, contains('answer_transaction_unavailable'));
    await h.acceptance.close();
  });

  test('permission denial records its stage and does not retry or join',
      () async {
    final h = _Harness()
      ..answer = (() async =>
          throw const CallAcceptanceException('transaction_permission-denied'));
    expect(await h.acceptance.connect(), CallAnswerOutcome.failed);
    await h.acceptance.close();
    expect(h.answers, 1);
    expect(h.acknowledgments, 0);
    expect(h.events, contains('answer_transaction_permission-denied'));
  });

  test('persistent network errors have a bounded retry count', () async {
    final h = _Harness()
      ..answer = (() async => throw const CallAcceptanceException(
          'transaction_unavailable',
          retryable: true));
    expect(await h.acceptance.connect(), CallAnswerOutcome.failed);
    await h.acceptance.close();
    expect(h.answers, 3);
    expect(h.acceptance.readyForMedia, isFalse);
  });
}

class _Harness {
  bool pending = true;
  int answers = 0;
  int acknowledgments = 0;
  int finishes = 0;
  int releases = 0;
  final events = <String>[];
  Future<CallAnswerOutcome> Function() answer =
      () async => CallAnswerOutcome.accepted;
  Future<bool> Function() acknowledge = () async => true;

  late final acceptance = CallAcceptance(
    isPending: () async => pending,
    answer: () {
      answers++;
      return answer();
    },
    acknowledge: () {
      acknowledgments++;
      return acknowledge();
    },
    finishNative: () async {
      finishes++;
    },
    releaseClaim: () async {
      releases++;
    },
    onEvent: events.add,
    retryDelay: Duration.zero,
  );
}
