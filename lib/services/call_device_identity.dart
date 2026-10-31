/// One FCM identity per install, including concurrent auth, Home and resume
/// setup. A read-then-create without this shared future can publish two IDs
/// for the same token and rebind native calling while Accept is in flight.
class CallDeviceIdentity {
  CallDeviceIdentity({
    required this.read,
    required this.write,
    required this.create,
  });

  final Future<String?> Function() read;
  final Future<void> Function(String) write;
  final String Function() create;
  Future<String>? _pending;

  Future<String> getOrCreate() => _pending ??= _load().catchError(
        (Object error, StackTrace stack) {
          _pending = null;
          Error.throwWithStackTrace(error, stack);
        },
      );

  Future<String> _load() async {
    final existing = await read();
    if (existing != null && existing.isNotEmpty) return existing;
    final id = create();
    await write(id);
    return id;
  }
}
