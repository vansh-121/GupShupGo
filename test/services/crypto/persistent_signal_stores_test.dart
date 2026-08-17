// Durability tests for the Signal store snapshot.
//
// Every case here is a ratchet-loss bug that produced the *same* user-visible
// symptom — a received message rendering as a placeholder, and then every
// message after it from that peer failing too — without ever crashing. They
// are unit-testable because the snapshot is plain Dart over an in-memory map;
// only the Keystore itself needs faking.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:video_chat_app/services/crypto/persistent_signal_stores.dart';

/// The secure-storage key the four stores are snapshotted under. Mirrors
/// `PersistentSignalStores._storesKey`, which is private.
const String _storesKey = 'gsg_e2ee_stores_v1';

/// In-memory stand-in for the Android Keystore.
///
/// Two capabilities the real one and the package's own test double don't give
/// us, both needed to reason about *ordering* rather than just final content:
///  • per-write latency, so two flushes can be forced to overlap;
///  • [onWriteStart], which fires before a write's latency, so a test can wait
///    until a flush has committed to its snapshot and is mid-write.
class _FakeKeystore {
  static const MethodChannel _channel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  final Map<String, String> data = <String, String>{};

  /// Latency for the Nth write of [_storesKey] (0-based). Later writes, and
  /// writes of any other key, are instant.
  List<Duration> storeWriteDelays = const <Duration>[];

  /// Values of [_storesKey] in the order they became durable — not the order
  /// they were issued. This is the sequence that decides what a restart sees.
  final List<String> committedSnapshots = <String>[];

  /// Fires synchronously as a write begins, before any latency is applied.
  void Function(String key)? onWriteStart;

  int storeWrites = 0;

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
        final value = args['value'] as String;
        final isSnapshot = key == _storesKey;
        final index = isSnapshot ? storeWrites++ : -1;
        onWriteStart?.call(key!);
        if (isSnapshot && index < storeWriteDelays.length) {
          await Future<void>.delayed(storeWriteDelays[index]);
        }
        // After the latency: commit order is completion order.
        data[key!] = value;
        if (isSnapshot) committedSnapshots.add(value);
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeKeystore keystore;

  setUp(() {
    keystore = _FakeKeystore()..install();
  });

  tearDown(() {
    keystore.uninstall();
  });

  test('prekeys survive a round trip whatever their id magnitude (RC6)',
      () async {
    final stores = await PersistentSignalStores.load();

    // Ids the old `for (id in 0..199)` dump silently dropped.
    // DeviceIdentityService.replenishOneTimePreKeysIfLow allocates from
    // `millisecondsSinceEpoch % 1000000`, so in practice *every* replenished
    // prekey looked like this one — generated, published in the key bundle,
    // then lost on the next launch. Peers' PreKeySignalMessages then failed
    // with InvalidKeyIdException and there was nothing local left to try.
    const bigPreKeyId = 847391;
    const bigSignedPreKeyId = 900123;

    final pre = generatePreKeys(bigPreKeyId, 1).first;
    await stores.preKeyStore.storePreKey(pre.id, pre);

    final signed =
        generateSignedPreKey(stores.identityKeyPair, bigSignedPreKeyId);
    await stores.signedPreKeyStore.storeSignedPreKey(signed.id, signed);

    await stores.flush();

    final reloaded = await PersistentSignalStores.load();

    expect(await reloaded.preKeyStore.containsPreKey(bigPreKeyId), isTrue,
        reason: 'one-time prekey outside 0..199 was dropped by the snapshot');
    expect(
        await reloaded.signedPreKeyStore
            .containsSignedPreKey(bigSignedPreKeyId),
        isTrue,
        reason: 'signed prekey outside 0..199 was dropped by the snapshot');

    // The same key material, not merely *some* record filed under that id.
    final rt = await reloaded.preKeyStore.loadPreKey(bigPreKeyId);
    expect(rt.serialize(), pre.serialize());
  });

  test('sessions and pinned identities survive a round trip', () async {
    final stores = await PersistentSignalStores.load();

    const addr = SignalProtocolAddress('peer-uid', 3);
    await stores.sessionStore.storeSession(addr, SessionRecord());

    final peerIdentity = generateIdentityKeyPair().getPublicKey();
    await stores.identityStore.saveIdentity(addr, peerIdentity);

    await stores.flush();

    final reloaded = await PersistentSignalStores.load();
    expect(await reloaded.sessionStore.containsSession(addr), isTrue);
    expect(
      (await reloaded.identityStore.getIdentity(addr))?.serialize(),
      peerIdentity.serialize(),
    );
    // The identity keypair lives under its own storage key, so it must be the
    // same one across launches — losing sessions is recoverable, but a changed
    // identity makes every peer treat us as a new device.
    expect(reloaded.identityKeyPair.serialize(),
        stores.identityKeyPair.serialize());
    expect(reloaded.registrationId, stores.registrationId);
  });

  test('overlapping flushes can never land an older snapshot last (RC2)',
      () async {
    final stores = await PersistentSignalStores.load();

    // The first snapshot write is slow, the second instant. That is all it took
    // for flush #1 — carrying the OLDER snapshot — to land after flush #2 and
    // roll the ratchet backwards, with no crash involved at all.
    keystore.storeWriteDelays = const <Duration>[
      Duration(milliseconds: 150),
      Duration.zero,
    ];

    final firstWriteStarted = Completer<void>();
    keystore.onWriteStart = (String key) {
      if (key == _storesKey && !firstWriteStarted.isCompleted) {
        firstWriteStarted.complete();
      }
    };

    final first = generatePreKeys(1, 1).first;
    await stores.preKeyStore.storePreKey(first.id, first);
    final flush1 = stores.flush();

    // Wait until flush #1 has taken its snapshot (holding only prekey 1) and is
    // mid-write. Without this the second mutation lands before the snapshot is
    // captured and the race can't be observed at all.
    await firstWriteStarted.future;

    final second = generatePreKeys(2, 1).first;
    await stores.preKeyStore.storePreKey(second.id, second);
    final flush2 = stores.flush();

    await Future.wait<void>(<Future<void>>[flush1, flush2]);

    expect(keystore.committedSnapshots, isNotEmpty);
    final landedLast =
        jsonDecode(keystore.committedSnapshots.last) as Map<String, dynamic>;
    expect(
      (landedLast['preKeys'] as Map).keys.map((k) => k.toString()).toSet(),
      containsAll(<String>['1', '2']),
      reason: 'the snapshot that landed last is missing a mutation that was '
          'already in memory before it was written',
    );

    // And a cold start agrees with the commit log.
    final reloaded = await PersistentSignalStores.load();
    expect(await reloaded.preKeyStore.containsPreKey(1), isTrue);
    expect(await reloaded.preKeyStore.containsPreKey(2), isTrue);
  });

  test('a no-op flush does not touch the Keystore', () async {
    final stores = await PersistentSignalStores.load();
    final pre = generatePreKeys(7, 1).first;
    await stores.preKeyStore.storePreKey(pre.id, pre);
    await stores.flush();

    final writesAfterRealFlush = keystore.storeWrites;
    await stores.flush();
    await stores.flush();

    // This is what makes awaiting flush() on every received message
    // affordable: the encode is sub-millisecond, the Keystore write is not.
    expect(keystore.storeWrites, writesAfterRealFlush,
        reason: 'flush() re-wrote an unchanged snapshot');
  });

  test('a mutation made without markDirty is still persisted', () async {
    // Several call sites (bundle publish, prekey replenish, signed-prekey
    // rotation) mutate the stores and then call flush() directly. A
    // dirty-counter would treat those as clean and silently drop freshly
    // generated prekeys — after which every peer's PreKeySignalMessage fails
    // with InvalidKeyIdException. flush() compares content for this reason.
    final stores = await PersistentSignalStores.load();
    await stores.flush();

    final pre = generatePreKeys(21, 1).first;
    await stores.preKeyStore.storePreKey(pre.id, pre); // no markDirty()
    await stores.flush();

    final reloaded = await PersistentSignalStores.load();
    expect(await reloaded.preKeyStore.containsPreKey(21), isTrue);
  });

  test('a corrupt snapshot is discarded without losing the identity',
      () async {
    final stores = await PersistentSignalStores.load();
    final pre = generatePreKeys(11, 1).first;
    await stores.preKeyStore.storePreKey(pre.id, pre);
    await stores.flush();

    keystore.data[_storesKey] = 'not json at all';

    final reloaded = await PersistentSignalStores.load();
    expect(reloaded.identityKeyPair.serialize(),
        stores.identityKeyPair.serialize());
    expect(await reloaded.preKeyStore.containsPreKey(11), isFalse);

    // The bad blob must be gone, so the next flush writes a clean one rather
    // than failing to hydrate on every launch forever.
    expect(keystore.data.containsKey(_storesKey), isFalse);
    final fresh = generatePreKeys(12, 1).first;
    await reloaded.preKeyStore.storePreKey(fresh.id, fresh);
    await reloaded.flush();
    expect(keystore.data.containsKey(_storesKey), isTrue);
  });
}
