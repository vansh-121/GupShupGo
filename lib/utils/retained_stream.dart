import 'dart:async';

/// Shares one source subscription across views until its owner closes it.
///
/// A plain `asBroadcastStream()` keeps listening when the last view detaches.
/// Keeping that behaviour during a temporary view replacement is useful, but
/// the route must explicitly release the source when it is disposed.
class RetainedStream<T> {
  RetainedStream(Stream<T> source) {
    stream = source.asBroadcastStream(onListen: (subscription) {
      _subscription = subscription;
      if (_closed) unawaited(subscription.cancel());
    });
  }

  late final Stream<T> stream;
  StreamSubscription<T>? _subscription;
  bool _closed = false;

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _subscription?.cancel();
  }
}
