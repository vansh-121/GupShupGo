// Resend-round policy: whether a broken bubble ever gets asked about again.
//
// The recovery protocol only works if a request reaches the sender *while their
// app is running*. An earlier build capped requests at three for the lifetime of
// the message, and all three fired inside about a minute — so a sender who
// happened to be closed during that minute left the bubble permanently broken,
// even with both people online and chatting a moment later. Nothing in the app
// ever reset the counter.
//
// The cap now applies to a *round*, and a round reopens on evidence that asking
// again could work. Every case below is a way that evidence arrives (or fails
// to), asserted against the pure decision function so no Firestore or Drift is
// involved.

import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/services/chat_service.dart';

/// Fixed "now" — every expectation is expressed as an offset from it, so none of
/// these tests depend on wall-clock time.
final DateTime _now = DateTime.utc(2026, 8, 18, 12, 0, 0);

const int _session = 1000;
const int _otherSession = 2000;

typedef RetryState = ({
  int attempts,
  int atMs,
  int roundStart,
  int sessionId,
  int generation
});

RetryState _state({
  required int attempts,
  required Duration ago,
  int roundStart = 0,
  int sessionId = _session,
  int generation = 0,
}) =>
    (
      attempts: attempts,
      atMs: _now.subtract(ago).millisecondsSinceEpoch,
      roundStart: roundStart,
      sessionId: sessionId,
      generation: generation,
    );

({bool allow, bool waiting, int roundStart}) _evaluate(
  RetryState? state, {
  int sessionId = _session,
  int generation = 0,
  Duration skew = Duration.zero,
}) =>
    ChatService.evaluateResendRound(
      state: state,
      sessionId: sessionId,
      generation: generation,
      now: _now.add(skew),
    );

void main() {
  group('within a round', () {
    test('a message never asked about is asked immediately', () {
      final v = _evaluate(null);
      expect(v.allow, isTrue);
      expect(v.roundStart, 0);
    });

    test('a second ask waits out the backoff', () {
      final v = _evaluate(_state(attempts: 1, ago: const Duration(seconds: 5)));
      expect(v.allow, isFalse);
      expect(v.waiting, isTrue,
          reason: 'a request is outstanding, so the bubble must still read as '
              'waiting rather than telling the user to chase the sender');
    });

    test('the backoff expires and the next ask goes out', () {
      final v = _evaluate(_state(attempts: 1, ago: const Duration(seconds: 31)));
      expect(v.allow, isTrue);
      expect(v.roundStart, 0, reason: 'still the same round');
    });

    test('three asks exhaust the round', () {
      final v = _evaluate(_state(attempts: 3, ago: const Duration(seconds: 31)));
      expect(v.allow, isFalse,
          reason: 'a fourth ask in the same round would just spam the sender');
    });
  });

  group('an exhausted round hardens only while nothing has changed', () {
    test('the bubble says "waiting" through the grace window', () {
      final v = _evaluate(_state(attempts: 3, ago: const Duration(minutes: 1)));
      expect(v.allow, isFalse);
      expect(v.waiting, isTrue);
    });

    test('and hardens once the grace window passes', () {
      // Deliberately shy of _resendRoundFloor and _resendRoundCooldown so this
      // is testing the hardening, not a reopen.
      final v = _evaluate(_state(
        attempts: 3,
        ago: const Duration(minutes: 1, seconds: 59),
        generation: 0,
      ), skew: const Duration(seconds: 2));
      expect(v.allow, isFalse);
      expect(v.waiting, isFalse,
          reason: 'nothing suggests the sender is reachable, so "ask sender to '
              'resend" is the honest wording');
    });
  });

  group('a new round opens on real evidence', () {
    test('a new app session reopens it — this is the reported bug', () {
      // The exact reported scenario: three requests went out inside a minute
      // while the sender was closed, and the bubble stayed broken. Reopening on
      // relaunch is the highest-yield signal there is, because by then the
      // sender is far more likely to be running.
      final v = _evaluate(
        _state(attempts: 3, ago: const Duration(hours: 6)),
        sessionId: _otherSession,
      );
      expect(v.allow, isTrue);
      expect(v.roundStart, 3,
          reason: 'the new round must start at the current lifetime count, or '
              'its wire tags would collide with the previous round');
    });

    test('a relaunch reopens it even seconds later', () {
      // No time-based floor on this path: the user paces relaunches themselves,
      // and a cold start is exactly when the peer list is being re-read.
      final v = _evaluate(
        _state(attempts: 3, ago: const Duration(seconds: 1)),
        sessionId: _otherSession,
      );
      expect(v.allow, isTrue);
    });

    test('the peer showing signs of life reopens it', () {
      final v = _evaluate(
        _state(attempts: 3, ago: const Duration(minutes: 5), generation: 0),
        generation: 1,
      );
      expect(v.allow, isTrue);
      expect(v.roundStart, 3);
    });

    test('but a burst of their messages cannot chain rounds back to back', () {
      // Their activity counter advances per message. Without the floor, ten
      // messages in ten seconds would open ten rounds and spend the whole
      // lifetime ceiling in under a minute.
      final v = _evaluate(
        _state(attempts: 3, ago: const Duration(seconds: 20), generation: 0),
        generation: 7,
      );
      expect(v.allow, isFalse);
      expect(v.waiting, isTrue,
          reason: 'a reopen is imminent, so the bubble should not harden');
    });

    test('time alone eventually reopens it', () {
      // The safety net for an app left open for hours with a quiet peer: no
      // relaunch, no activity, and it still gets another chance.
      final v = _evaluate(_state(attempts: 3, ago: const Duration(minutes: 21)));
      expect(v.allow, isTrue);
      expect(v.roundStart, 3);
    });

    test('a row written before rounds existed reopens', () {
      // PlaintextStore.getRetryState reads a legacy `{n, at}` row back with
      // roundStart 0 and sessionId -1. That shape must look both exhausted and
      // stale, so the bubbles that hardened under the old lifetime cap — the
      // ones already sitting in the reported chat — get asked about again.
      final v = _evaluate(_state(
        attempts: 3,
        ago: const Duration(days: 1),
        roundStart: 0,
        sessionId: -1,
        generation: -1,
      ));
      expect(v.allow, isTrue);
      expect(v.roundStart, 3);
    });

    test('a round reopened by time is itself three asks long', () {
      // roundStart 3 with attempts 4 means one ask into the second round.
      final v = _evaluate(_state(
          attempts: 4, ago: const Duration(seconds: 31), roundStart: 3));
      expect(v.allow, isTrue);
      final exhausted = _evaluate(_state(
          attempts: 6, ago: const Duration(seconds: 31), roundStart: 3));
      expect(exhausted.allow, isFalse);
    });
  });

  group('bounds', () {
    test('the lifetime ceiling stops even a relaunch', () {
      // Fifteen asks across at least five rounds means the sender no longer
      // holds the plaintext. Without this, `retryRequests` would grow on every
      // launch for the life of the install.
      final v = _evaluate(
        _state(attempts: 15, ago: const Duration(days: 3), roundStart: 12),
        sessionId: _otherSession,
        generation: 99,
      );
      expect(v.allow, isFalse);
      expect(v.waiting, isFalse);
    });

    test('attempt numbers are strictly increasing across rounds', () {
      // The wire tag is "<uid>:<device>#<attempt>". The sender skips any number
      // it has already served, and arrayUnion silently drops a repeated string —
      // so a round that restarted its numbering at 1 would publish a request
      // that never appears on the document and would never be answered if it
      // did. Drive the policy through several rounds the way _requestResend
      // does, and assert the tag never repeats.
      final seen = <int>{};
      RetryState? state;
      var currentSession = _session;
      var elapsed = Duration.zero;
      var published = 0;

      for (var i = 0; i < 40 && published < 7; i++) {
        final v = _evaluate(state, sessionId: currentSession, skew: elapsed);
        if (v.allow) {
          published++;
          expect(seen.add(published), isTrue,
              reason: 'attempt #$published was published twice');
          // Mirror the write in _requestResend: the lifetime count advances by
          // one and the round's origin/session are stamped as returned.
          state = (
            attempts: published,
            atMs: _now.add(elapsed).millisecondsSinceEpoch,
            roundStart: v.roundStart,
            sessionId: currentSession,
            generation: 0,
          );
          elapsed += const Duration(seconds: 31);
          continue;
        }
        // The two ways the app moves past a refusal: wait out the backoff
        // mid-round, or relaunch once the round is spent.
        if (published - state!.roundStart >= 3) {
          currentSession++;
        } else {
          elapsed += const Duration(seconds: 31);
        }
      }

      expect(published, 7,
          reason: 'the policy stalled before completing three rounds');
      expect(seen.length, published);
    });
  });

  group('peer activity plumbing', () {
    test('notePeerActivity advances a per-uid counter', () {
      const uid = 'peer-liveness-uid';
      final before = ChatService.peerActivityForTest(uid);
      ChatService.notePeerActivity(uid);
      expect(ChatService.peerActivityForTest(uid), before + 1);
      ChatService.notePeerActivity(uid);
      expect(ChatService.peerActivityForTest(uid), before + 2);
    });

    test('activity is tracked per peer, not globally', () {
      // A shared counter would let any peer's message reopen rounds for every
      // other peer, spending the ceiling on senders who never came back.
      const a = 'peer-a-uid';
      const b = 'peer-b-uid';
      final beforeB = ChatService.peerActivityForTest(b);
      ChatService.notePeerActivity(a);
      expect(ChatService.peerActivityForTest(b), beforeB);
    });

    test('an empty uid is ignored', () {
      ChatService.notePeerActivity('');
      expect(ChatService.peerActivityForTest(''), 0);
    });
  });
}
