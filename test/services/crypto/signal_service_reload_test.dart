// `SignalService.reloadFromDisk()` — the FCM background isolate's only safe way
// to get Signal stores it is allowed to write.
//
// The method is four lines, and every one of them is load-bearing for a failure
// that has no crash and no error message. Android *reuses* the FCM background
// isolate across pushes, so on the second push the cached `_instance` holds
// stores hydrated at the first push. Anything the main isolate has done since —
// including deleting a session — is invisible to it, and its next flush writes
// the stale picture back over the good one, rolling peers' ratchets backwards.
//
// The obvious fix, re-hydrating the existing instance, does not work:
// `PersistentSignalStores.hydrate` *merges* (it replays storePreKey/storeSession
// into whatever is already in memory), so a deleted session would survive
// re-hydration and be written back anyway. Only dropping the instance replaces.
//
// So what is asserted here is specifically **replace, not merge** — and that
// `init()` on its own cannot do it.

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:video_chat_app/services/crypto/persistent_signal_stores.dart';
import 'package:video_chat_app/services/crypto/signal_service.dart';

/// Mirrors the private `PersistentSignalStores._storesKey`.
const String _storesKey = 'gsg_e2ee_stores_v1';

/// Map-backed stand-in for the Keystore. No latency modelling needed here —
/// these tests are about *what* is in memory versus on disk, not write ordering.
class _FakeKeystore {
  static const MethodChannel _channel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  final Map<String, String> data = <String, String>{};

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, _handle);
  }

  void uninstall() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  }

  Future<Object?> _handle(MethodCall call) async {
    final args = (call.arguments as Map?) ?? const <Object?, Object?>{};
    final key = args['key'] as String?;
    switch (call.method) {
      case 'write':
        data[key!] = args['value'] as String;
        return null;
      case 'read':
        return data[key];
      case 'delete':
        data.remove(key);
        return null;
      case 'deleteAll':
        data.clear();
        return null;
      case 'containsKey':
        return data.containsKey(key);
      case 'readAll':
        return Map<String, String>.from(data);
      default:
        return null;
    }
  }
}

const _peerA = SignalProtocolAddress('uid-peer-a', 1);
const _peerB = SignalProtocolAddress('uid-peer-b', 1);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeKeystore keystore;

  setUp(() {
    keystore = _FakeKeystore()..install();
  });

  tearDown(() {
    keystore.uninstall();
  });

  test('drops sessions that exist only in memory', () async {
    // The plan's case, and the one that matters: peer B is on disk, peer A only
    // in the stale instance's memory. A merge would keep both.
    final first = await SignalService.reloadFromDisk();
    await first.stores.sessionStore.storeSession(_peerB, SessionRecord());
    await first.stores.flush();

    // In memory only — never flushed. Stands for a session the main isolate has
    // since deleted, or one this isolate built during an earlier push.
    await first.stores.sessionStore.storeSession(_peerA, SessionRecord());

    final second = await SignalService.reloadFromDisk();

    expect(await second.stores.sessionStore.containsSession(_peerB), isTrue,
        reason: 'reload lost a session that was durably on disk');
    expect(await second.stores.sessionStore.containsSession(_peerA), isFalse,
        reason: 'reload merged in a memory-only session instead of replacing — '
            'a session deleted by the main isolate would come back');
    expect(second.stores, isNot(same(first.stores)),
        reason: 'reload handed back the same store objects, so nothing was '
            'actually re-read from disk');
  });

  test('a dropped session is not written back by the next flush', () async {
    // The half that does the damage. Losing peer A from memory is harmless on
    // its own; the bug is the *write* that follows, which is what reaches the
    // main isolate's stores and every unrelated peer's ratchet.
    final first = await SignalService.reloadFromDisk();
    await first.stores.sessionStore.storeSession(_peerB, SessionRecord());
    await first.stores.flush();
    await first.stores.sessionStore.storeSession(_peerA, SessionRecord());

    final second = await SignalService.reloadFromDisk();
    // Serving a resend mutates the store, exactly as the background isolate
    // would, and then persists — the flush the whole gate is arranged around.
    final pre = generatePreKeys(4242, 1).first;
    await second.stores.preKeyStore.storePreKey(pre.id, pre);
    await second.stores.flush();

    // Read the blob back the way a cold start would, rather than trusting the
    // in-memory instance that just wrote it.
    final onDisk = await PersistentSignalStores.load();
    expect(await onDisk.sessionStore.containsSession(_peerA), isFalse,
        reason: 'the flush resurrected a session that was not on disk');
    expect(await onDisk.sessionStore.containsSession(_peerB), isTrue);
    expect(await onDisk.preKeyStore.containsPreKey(4242), isTrue,
        reason: 'the flush dropped the work this isolate actually did');
  });

  test('init() alone cannot refresh — hence reloadFromDisk', () async {
    // Why the method has to exist at all. init() returns the cached instance, so
    // the background isolate calling init() on its second push keeps serving
    // from stores hydrated during its first.
    final first = await SignalService.reloadFromDisk();
    await first.stores.sessionStore.storeSession(_peerA, SessionRecord());

    final again = await SignalService.init();
    expect(again, same(first));
    expect(await again.stores.sessionStore.containsSession(_peerA), isTrue,
        reason: 'init() rebuilt the stores — that would silently discard '
            'unflushed ratchet state on the main isolate');
  });

  test('keeps this device identity across a reload', () async {
    // The identity keypair lives under its own storage key. If a reload rotated
    // it, every peer would see a new device and stop trusting cached bundles —
    // strictly worse than the problem being solved.
    final first = await SignalService.reloadFromDisk();
    final before = first.stores.identityKeyPair.serialize();
    final regId = first.stores.registrationId;

    final second = await SignalService.reloadFromDisk();

    expect(second.stores.identityKeyPair.serialize(), before);
    expect(second.stores.registrationId, regId);
    expect(second.publicIdentityKey.serialize(),
        first.publicIdentityKey.serialize());
  });

  test('survives a reload with nothing on disk yet', () async {
    // First-ever push on a fresh install: no snapshot, and load() takes the
    // generate-a-new-identity branch. Must not throw — a throw here would run
    // inside the background handler where there is nobody to catch it.
    expect(keystore.data, isEmpty);
    final svc = await SignalService.reloadFromDisk();
    expect(await svc.stores.sessionStore.containsSession(_peerA), isFalse);
    // An identity was generated and persisted, so the *next* reload is the
    // hydrate path rather than this one.
    expect(keystore.data.keys, contains('gsg_e2ee_identity_v1'));
  });

  test('a reload after a corrupt blob still yields usable stores', () async {
    final first = await SignalService.reloadFromDisk();
    await first.stores.sessionStore.storeSession(_peerB, SessionRecord());
    await first.stores.flush();
    expect(jsonDecode(keystore.data[_storesKey]!), isA<Map<String, dynamic>>());

    keystore.data[_storesKey] = '{ truncated';

    // load() wipes the bad blob and keeps the identity; reloadFromDisk must not
    // turn that recovery into an exception on the background path.
    final second = await SignalService.reloadFromDisk();
    expect(await second.stores.sessionStore.containsSession(_peerB), isFalse);
    expect(second.stores.identityKeyPair.serialize(),
        first.stores.identityKeyPair.serialize());
  });
}
