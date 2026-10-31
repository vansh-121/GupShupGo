import 'dart:async';

enum CallAnswerOutcome {
  accepted,
  answeredElsewhere,
  expired,
  ended,
  missing,
  signedOut,
  wrongAccount,
  cancelled,
  failed,
}

/// A classified signaling error; only transient failures should be retried.
class CallAcceptanceException implements Exception {
  const CallAcceptanceException(this.code, {this.retryable = false});

  final String code;
  final bool retryable;
}

/// Owns one Accept attempt, independently of navigation and media startup.
/// Closing is immediate, including while a server transaction is in flight.
/// [releaseClaim] must check ownership on the server before ending a call.
class CallAcceptance {
  CallAcceptance({
    required this.isPending,
    required this.answer,
    required this.acknowledge,
    required this.finishNative,
    required this.releaseClaim,
    required this.onEvent,
    this.retryDelay = const Duration(seconds: 1),
  });

  final Future<bool> Function() isPending;
  final Future<CallAnswerOutcome> Function() answer;
  final Future<bool> Function() acknowledge;
  final Future<void> Function() finishNative;
  final Future<void> Function() releaseClaim;
  final void Function(String) onEvent;
  final Duration retryDelay;

  Future<CallAnswerOutcome>? _connection;
  Future<void>? _closing;
  bool _closed = false;
  bool _readyForMedia = false;

  bool get readyForMedia => _readyForMedia && !_closed;

  Future<CallAnswerOutcome> connect() => _connection ??= _connect();

  Future<CallAnswerOutcome> _connect() async {
    try {
      for (var attempt = 0; attempt < 3 && !_closed; attempt++) {
        if (!await isPending() || _closed) {
          onEvent('accept_inbox_unavailable');
          return CallAnswerOutcome.cancelled;
        }
        CallAnswerOutcome outcome;
        try {
          onEvent('answer_started');
          outcome = await answer();
        } on CallAcceptanceException catch (error) {
          onEvent('answer_${error.code}');
          if (!error.retryable || attempt == 2 || _closed) {
            return CallAnswerOutcome.failed;
          }
          await Future<void>.delayed(retryDelay);
          continue;
        }
        onEvent('answer_${outcome.name}');
        if (_closed) {
          // close() may have run before the answer committed. Check again so
          // an eventual successful transaction cannot leave an orphaned call.
          if (outcome == CallAnswerOutcome.accepted) {
            unawaited(_release());
          }
          return CallAnswerOutcome.cancelled;
        }
        if (outcome != CallAnswerOutcome.accepted) return outcome;
        if (!await isPending() || _closed || !await acknowledge() || _closed) {
          onEvent('accept_handoff_cancelled');
          return CallAnswerOutcome.cancelled;
        }
        _readyForMedia = true;
        onEvent('accept_ready_for_media');
        return CallAnswerOutcome.accepted;
      }
      return CallAnswerOutcome.cancelled;
    } catch (error) {
      onEvent('accept_error_${error.runtimeType}');
      return CallAnswerOutcome.failed;
    } finally {
      if (!readyForMedia) unawaited(close());
    }
  }

  Future<void> close() {
    _closed = true;
    return _closing ??= _close();
  }

  Future<void> _close() async {
    onEvent('accept_closed');
    await Future.wait([
      () async {
        try {
          await finishNative();
        } catch (_) {
          onEvent('native_finish_unavailable');
        }
      }(),
      _release(),
    ]);
  }

  Future<void> _release() async {
    try {
      await releaseClaim();
    } catch (_) {
      onEvent('answer_cleanup_unavailable');
    }
  }
}
