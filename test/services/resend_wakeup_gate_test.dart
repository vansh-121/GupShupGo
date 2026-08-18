// The isolate gate: which isolate serves a resend push, and whether it may
// persist what it built.
//
// This is the highest-stakes decision in the resend protocol. PersistentSignalStores
// writes all four Signal stores into one secure-storage key against a per-instance
// baseline, so two live instances in one process overwrite rather than merge — and
// FCM's background handler runs in its own isolate. Get this wrong and a push
// meant to repair one bubble rolls back every peer's ratchet instead.
//
// Both decisions are pulled out as pure functions precisely so they can be
// asserted here, without an isolate, an FCM push, or a Signal store in sight.

import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/services/crypto/resend_wakeup.dart';

void main() {
  group('routing', () {
    test('a live main isolate gets the work handed to it', () {
      // The dangerous case, and the common one: backgrounded-but-alive. Serving
      // here would build a session in a second store instance, and whichever
      // instance flushed last would erase the other's work.
      expect(
        decideResendRoute(mainIsolateAlive: true),
        ResendRoute.handOff,
      );
    });

    test('with no main isolate we serve here — the whole point of the push', () {
      // A process started *by* the push. Nothing else holds the stores, so disk
      // is the only truth and load → mutate → write is safe. This is the case
      // that makes a closed app answer at all.
      expect(
        decideResendRoute(mainIsolateAlive: false),
        ResendRoute.serveHere,
      );
    });

    test('there is no third option — every push is acted on', () {
      // Guards against someone later adding an "ignore" branch: a push that
      // reached us always means a peer is staring at a broken bubble.
      expect(ResendRoute.values, hasLength(2));
    });
  });

  group('persisting after a background serve', () {
    test('flushes when still alone', () {
      expect(mayPersistSessionAfterServing(mainIsolateAliveNow: false), isTrue);
    });

    test('skips the flush if the app launched mid-serve', () {
      // The residual race the routing check can't cover: the user opens the app
      // after we decided to serve. Two instances now exist, so flushing would
      // roll every *other* peer back to whenever this isolate hydrated.
      //
      // Skipping loses only our own session record for the one peer we just
      // answered — they still repair, because a PreKeySignalMessage carries its
      // own handshake — which costs at most one more resend round.
      expect(mayPersistSessionAfterServing(mainIsolateAliveNow: true), isFalse);
    });

    test('the two decisions read liveness independently', () {
      // Deliberately not one shared flag. The routing check happens before the
      // crypto and the flush check after it, and the answer can change in
      // between — that gap is exactly what the second check exists to catch.
      expect(decideResendRoute(mainIsolateAlive: false), ResendRoute.serveHere);
      expect(mayPersistSessionAfterServing(mainIsolateAliveNow: true), isFalse);
    });
  });

  group('liveness detection', () {
    test('reports no main isolate in a bare test binding', () {
      // No registerMainIsolateForResendWakeups() has run, so nothing has claimed
      // the port name. Also pins the constant: renaming it without updating
      // main.dart would silently make every push take the serveHere path.
      expect(mainIsolateIsAlive(), isFalse);
      expect(kMainIsolatePortName, 'gsg.main.isolate');
    });
  });
}
