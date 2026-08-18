// Resend wakeup — serving an E2EE resend request from an FCM push, safely.
//
// Why this file exists at all:
//
// A message that won't decrypt can only be repaired by its *sender*. They hold
// the plaintext; the server holds ciphertext and could not re-encrypt anything
// if it wanted to. So when a recipient publishes a resend request, the sender's
// own device has to notice it — and until now that meant "whenever they next
// open the app", because the only thing watching for requests was SyncService's
// room listener.
//
// A silent FCM data push fixes that. What makes it delicate is *where* the push
// is handled:
//
//   Flutter runs `onBackgroundMessage` in a SEPARATE ISOLATE.
//
// PersistentSignalStores serializes all four Signal stores into ONE
// secure-storage key, diffed against an in-memory baseline held per instance. So
// two live instances in one process do not merge — they overwrite, and the loser
// is whichever flushed first:
//
//   • main isolate flushes last  → the session this isolate just built is erased,
//     but the recipient already consumed the PreKeySignalMessage and moved to it,
//     so the sender's *next* message to them is undecryptable.
//   • this isolate flushes last  → EVERY OTHER PEER's ratchet rolls back to
//     whenever this isolate hydrated. One broken chat becomes several.
//
// The in-flight guard inside PersistentSignalStores is per-instance and cannot
// see across isolates, so it offers no protection here.
//
// Hence the rule this file exists to enforce: **never touch the Signal stores
// from the background isolate while the main isolate is alive in the same
// process.** [mainIsolateIsAlive] is the discriminator, and it is consulted
// twice — once before starting, and again before the only write that matters.
//
// See [decideResendRoute] and [mayPersistSessionAfterServing] for the two
// decisions, both pure and both covered by
// `test/services/resend_wakeup_gate_test.dart`.

import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:video_chat_app/services/crypto/signal_service.dart';
import 'package:video_chat_app/services/sync_service.dart';

/// Name the main isolate publishes a [SendPort] under while it holds live Signal
/// stores.
///
/// `IsolateNameServer` mappings live in the Flutter engine, so they are scoped to
/// the process and visible from both isolates — and they vanish when the process
/// does. That is exactly the question we need answered: a process started *by*
/// an FCM push has no mapping, an app the user has open does.
const String kMainIsolatePortName = 'gsg.main.isolate';

/// Message shape sent over that port. A plain list so it survives the isolate
/// boundary without any shared type.
const String _kResendCommand = 'resend';

/// What a background isolate should do with a resend push.
enum ResendRoute {
  /// The main isolate owns the Signal stores. Hand the work over and stop.
  handOff,

  /// This isolate is alone in the process, so what is on disk is the whole
  /// truth. Safe to load, serve, and write back.
  serveHere,
}

/// The routing decision, isolated from the isolate machinery so it can be
/// asserted directly.
///
/// Deliberately has no "ignore" case: a push that reached us is always worth
/// acting on, the only question is which isolate does it.
@visibleForTesting
ResendRoute decideResendRoute({required bool mainIsolateAlive}) =>
    mainIsolateAlive ? ResendRoute.handOff : ResendRoute.serveHere;

/// Whether a background isolate that has just built a fresh session may persist
/// it.
///
/// Called *after* the crypto, with a re-reading of liveness, because the user can
/// launch the app while we are working — and then the process holds two
/// instances despite [decideResendRoute] having said otherwise.
///
/// Returning false loses the new session locally, and that is the right trade.
/// The recipient still repairs: a PreKeySignalMessage carries its own handshake
/// and they archive their old state when they process it. All that is stale is
/// our own record for that one peer, costing at most one more resend round —
/// whereas flushing would roll back every peer the main isolate has been talking
/// to since it started.
@visibleForTesting
bool mayPersistSessionAfterServing({required bool mainIsolateAliveNow}) =>
    !mainIsolateAliveNow;

/// True when a main isolate in this process has published its port.
bool mainIsolateIsAlive() =>
    IsolateNameServer.lookupPortByName(kMainIsolatePortName) != null;

/// Publishes this isolate as the owner of the Signal stores, and starts serving
/// resend requests handed over by the background isolate.
///
/// Call once from `main()`, and only **after** `SignalService.init()` has
/// returned — the registration is what tells a background isolate to keep its
/// hands off, so it must not be visible before the stores it protects exist.
void registerMainIsolateForResendWakeups() {
  final port = ReceivePort();
  // A previous registration can survive a Flutter hot restart, which would leave
  // the name pointing at a dead port.
  IsolateNameServer.removePortNameMapping(kMainIsolatePortName);
  IsolateNameServer.registerPortWithName(port.sendPort, kMainIsolatePortName);

  port.listen((dynamic msg) {
    if (msg is! List || msg.length != 3 || msg[0] != _kResendCommand) return;
    final roomId = msg[1];
    final messageId = msg[2];
    if (roomId is! String || messageId is! String) return;
    if (kDebugMode) {
      debugPrint('[Resend] handed off from background isolate: $messageId');
    }
    unawaited(SyncService.instance.serveResendNow(roomId, messageId));
  });
}

/// Serves a resend push that arrived while the app is in the foreground.
///
/// Same isolate as everything else, so none of the above applies — this is here
/// only so the answer goes out immediately instead of waiting for the room
/// listener's next snapshot.
Future<void> handleForegroundResendWakeup(Map<String, dynamic> data) async {
  final roomId = (data['roomId'] ?? '').toString();
  final messageId = (data['messageId'] ?? '').toString();
  if (roomId.isEmpty || messageId.isEmpty) return;
  await SyncService.instance.serveResendNow(roomId, messageId);
}

/// Serves a resend push from the FCM background isolate.
///
/// Assumes `Firebase.initializeApp()` has already run and that the push has been
/// confirmed as addressed to the signed-in user. Never throws.
Future<void> handleBackgroundResendWakeup(Map<String, dynamic> data) async {
  final roomId = (data['roomId'] ?? '').toString();
  final messageId = (data['messageId'] ?? '').toString();
  if (roomId.isEmpty || messageId.isEmpty) return;

  if (decideResendRoute(mainIsolateAlive: mainIsolateIsAlive()) ==
      ResendRoute.handOff) {
    final port = IsolateNameServer.lookupPortByName(kMainIsolatePortName);
    // Null only if the app shut down between the check and here; the request is
    // still on the message document, so its next launch picks it up.
    port?.send(<Object>[_kResendCommand, roomId, messageId]);
    if (kDebugMode) {
      debugPrint('[Resend] app is alive — handed $messageId to main isolate');
    }
    return;
  }

  // Sole isolate. Bounded because Android reclaims a background handler after
  // roughly ten seconds; blowing that budget mid-write is worse than not
  // starting, so everything below is inside the timeout.
  try {
    await _serveFromBackgroundIsolate(roomId, messageId)
        .timeout(const Duration(seconds: 12));
  } catch (e) {
    // The request stays on the message document either way, so the worst case is
    // the behaviour we had before this push existed.
    if (kDebugMode) debugPrint('[Resend] background serve failed: $e');
  }
}

Future<void> _serveFromBackgroundIsolate(
    String roomId, String messageId) async {
  // Firestore rules identify us by auth, not by the cached uid the push was
  // filtered against, so the write needs a genuinely restored session.
  final uid = await _awaitRestoredUid();
  if (uid == null) {
    if (kDebugMode) debugPrint('[Resend] no restored auth — skipping');
    return;
  }

  // Fresh stores, not a re-hydrate. Android reuses this isolate across pushes,
  // so a cached SignalService could be hours stale — and hydrate() merges rather
  // than replaces, which would resurrect sessions the main isolate has since
  // deleted and write them back on the next flush.
  await SignalService.reloadFromDisk();

  // `deferFlush` is what makes the gate below the only decision. The serve path
  // normally commits its session write immediately — correct in the main isolate,
  // where a kill seconds later would otherwise strand a session the requester has
  // already ratcheted past. From here that same write is the dangerous one, and it
  // used to land before this function got to vote on it: the app can launch at any
  // point during the serve, and a flush from a second live instance overwrites
  // rather than merges. Holding it in memory means the check below governs whether
  // it is ever persisted at all.
  await SyncService.instance
      .serveResendNow(roomId, messageId, deferFlush: true);

  // The one write that can hurt anyone.
  if (mayPersistSessionAfterServing(mainIsolateAliveNow: mainIsolateIsAlive())) {
    await SignalService.instance.stores.flush();
    if (kDebugMode) debugPrint('[Resend] served $messageId and flushed');
  } else {
    // Not merely "don't flush": the serve's own `markDirty` armed a debounced
    // write, and letting it expire would land this isolate's snapshot three
    // seconds from now — exactly the decision we just declined to make. Outside
    // the kDebugMode guard on purpose; this one has to happen in release.
    SignalService.instance.stores.cancelPendingFlush();
    // The session we just built for this one peer is lost, which costs the
    // requester one more resend round. The prekey message is already published,
    // and they archive their old state on processing it, so the repair itself
    // still lands — see [mayPersistSessionAfterServing] for why that is the
    // acceptable direction to fail in.
    if (kDebugMode) {
      debugPrint('[Resend] app launched mid-serve — skipping flush for $messageId');
    }
  }
}

/// Waits briefly for FirebaseAuth to restore the persisted session.
///
/// A fresh isolate reads credentials from disk asynchronously, so
/// `currentUser` is usually null for the first moment of its life.
Future<String?> _awaitRestoredUid() async {
  final immediate = FirebaseAuth.instance.currentUser?.uid;
  if (immediate != null) return immediate;
  try {
    final user = await FirebaseAuth.instance
        .authStateChanges()
        .firstWhere((u) => u != null)
        .timeout(const Duration(seconds: 5));
    return user?.uid;
  } catch (_) {
    // Timed out, or signed out on this device.
    return FirebaseAuth.instance.currentUser?.uid;
  }
}
