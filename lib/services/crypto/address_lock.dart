// Serializes async work per key.
//
// Extracted from SignalService so the ordering guarantee it provides is
// asserted directly rather than inferred. It exists because a libsignal
// operation is an unlocked read-modify-write over one peer's SessionRecord —
// load, parse, advance the ratchet, store — and two of those overlapping on one
// address means the later store discards the earlier's advance. The receive
// chain then trails the sender's and every subsequent message from them fails
// verifyMac, so a single race produces a run of undecryptable messages rather
// than one.
//
// See `test/services/crypto/address_lock_test.dart`.

import 'dart:async';

import 'package:flutter/foundation.dart';

/// Runs actions one-at-a-time per key, and concurrently across keys.
///
/// Deliberately not a general-purpose mutex: there is no timeout and no
/// reentrancy support. A caller that re-enters [run] with a key it already
/// holds will wait on itself forever, so the actions passed in must not reach
/// back into the same lock. That constraint is cheap to honour at the one call
/// site that matters and keeps the implementation small enough to reason about.
class AddressLock {
  /// Tail of the queue per key: the future that completes when the operation
  /// currently last in line has finished.
  final Map<String, Future<void>> _tails = {};

  /// Number of keys with work queued. Should return to zero once everything
  /// settles — a non-zero idle value means the map is leaking.
  @visibleForTesting
  int get pendingKeys => _tails.length;

  /// Runs [action] once every previously-queued action for [key] has settled.
  ///
  /// The returned future carries [action]'s result or error. An action that
  /// throws still releases the lock, because the queue is chained on internal
  /// completers that are only ever completed normally — a failing decrypt must
  /// not strand every later message from that peer.
  Future<T> run<T>(String key, Future<T> Function() action) {
    final predecessor = _tails[key] ?? Future<void>.value();
    final release = Completer<void>();
    _tails[key] = release.future;

    return predecessor.then((_) => action()).whenComplete(() {
      release.complete();
      // Only the tail clears the entry, so the map holds one future per
      // *contended* key rather than one per key ever used. Identity-checked
      // because this callback runs as a microtask, by which time a fresh call
      // may already have installed its own tail.
      if (_tails[key] == release.future) _tails.remove(key);
    });
  }
}
