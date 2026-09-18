import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:video_chat_app/services/crypto/persistent_signal_stores.dart';
import 'package:video_chat_app/services/crypto/signal_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final storage = <String, String>{};

  setUp(() async {
    storage.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      final args = call.arguments as Map;
      final key = args['key'] as String?;
      switch (call.method) {
        case 'read':
          return storage[key];
        case 'write':
          storage[key!] = args['value'] as String;
          return null;
        case 'delete':
          storage.remove(key);
          return null;
        default:
          return null;
      }
    });
    await SignalService.wipe();
  });

  tearDown(() async {
    await SignalService.wipe();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('concurrent initialization shares one identity and session owner',
      () async {
    final services =
        await Future.wait(List.generate(8, (_) => SignalService.init()));
    for (final service in services) {
      expect(service, same(services.first));
    }
    final reloaded = await PersistentSignalStores.load();
    expect(reloaded.identityKeyPair.serialize(),
        services.first.stores.identityKeyPair.serialize());
  });

  test('prewarm and send share one session setup', () async {
    final senderStores = await PersistentSignalStores.load();
    senderStores.suspendAutoFlush();
    storage.clear();
    final receiverStores = await PersistentSignalStores.load();
    receiverStores.suspendAutoFlush();
    final signedKey = generateSignedPreKey(receiverStores.identityKeyPair, 1);
    await receiverStores.signedPreKeyStore.storeSignedPreKey(1, signedKey);

    // Mirror production's _fetchPreKeyBundle, which base64-decodes fresh byte
    // buffers on every fetch. libsignal 0.7.1's verifySig mutates its inputs in
    // place — it reads the sign bit of signature[63] and then clears it — so
    // verifying the SAME signature buffer a second time derives a different
    // point and fails. Handing back one shared PreKeyBundle would make
    // encryptWithFreshSession's rebuild throw InvalidKeyException on a
    // signature that is in fact valid; production never hits this because every
    // fetch decodes its own buffers (and resetSessionFor evicts the cache
    // first). Rebuild from copies per call so each processPreKeyBundle owns its
    // buffers.
    final signedPreKeyPub = signedKey.getKeyPair().publicKey.serialize();
    final signedPreKeySig = signedKey.signature;
    final identityPub = receiverStores.identityKeyPair.getPublicKey().serialize();
    PreKeyBundle freshBundle() => PreKeyBundle(
          receiverStores.registrationId,
          1,
          null,
          null,
          1,
          Curve.decodePoint(Uint8List.fromList(signedPreKeyPub), 0),
          Uint8List.fromList(signedPreKeySig),
          IdentityKey.fromBytes(Uint8List.fromList(identityPub), 0),
        );

    final started = Completer<void>();
    final release = Completer<void>();
    var fetches = 0;
    final sender = SignalService.forTesting(senderStores,
        loadBundle: (_, __) async {
      fetches++;
      if (!started.isCompleted) started.complete();
      await release.future;
      return freshBundle();
    });
    final receiver = SignalService.forTesting(receiverStores,
        loadBundle: (_, __) async => null);

    final prewarm = sender.ensureSession('bob', 1);
    await started.future;
    final sending =
        sender.encrypt('bob', 1, Uint8List.fromList(utf8.encode('hello')));
    await Future<void>.delayed(Duration.zero);
    release.complete();
    await prewarm;
    final envelope = await sending;

    expect(fetches, 1);
    expect(utf8.decode(await receiver.decrypt('alice', 1, envelope)), 'hello');

    final repaired = await Future.wait([
      sender.encryptWithFreshSession(
          'bob', 1, Uint8List.fromList(utf8.encode('repaired'))),
      sender.encrypt('bob', 1, Uint8List.fromList(utf8.encode('next'))),
    ]);
    expect(repaired.first.isPreKeyMessage, isTrue);
    expect(utf8.decode(await receiver.decrypt('alice', 1, repaired.first)),
        'repaired');
    expect(utf8.decode(await receiver.decrypt('alice', 1, repaired.last)),
        'next');
    expect(fetches, 2);

    await sender.resetSessionFor('bob', 1);
    expect(await sender.hasSession('bob', 1), isFalse);
  });

  test('a service whose stores were closed rejects mutation instead of '
      'dropping persistence', () async {
    // The reviewer's scenario: something still holds a SignalService after a
    // reloadFromDisk / wipe closed its stores. Before the guard, encrypt() ran
    // on the live in-memory session and markDirty() silently skipped the write
    // (a closed store is also suspended), so the sender emitted ciphertext it
    // never persisted — the ratchet advanced on disk-state it would reload from
    // on next launch, desyncing the peer permanently. Both the per-address
    // guard and markDirty must now reject.
    final senderStores = await PersistentSignalStores.load();
    senderStores.suspendAutoFlush();
    storage.clear();
    final receiverStores = await PersistentSignalStores.load();
    receiverStores.suspendAutoFlush();
    final signedKey = generateSignedPreKey(receiverStores.identityKeyPair, 1);
    await receiverStores.signedPreKeyStore.storeSignedPreKey(1, signedKey);

    final signedPreKeyPub = signedKey.getKeyPair().publicKey.serialize();
    final signedPreKeySig = signedKey.signature;
    final identityPub =
        receiverStores.identityKeyPair.getPublicKey().serialize();
    final sender = SignalService.forTesting(senderStores,
        loadBundle: (_, __) async => PreKeyBundle(
              receiverStores.registrationId,
              1,
              null,
              null,
              1,
              Curve.decodePoint(Uint8List.fromList(signedPreKeyPub), 0),
              Uint8List.fromList(signedPreKeySig),
              IdentityKey.fromBytes(Uint8List.fromList(identityPub), 0),
            ));

    // Establish a live session first, so the rejection below is the close and
    // not a missing bundle — i.e. without the guard this encrypt would succeed.
    await sender.ensureSession('bob', 1);
    expect(await sender.hasSession('bob', 1), isTrue);

    await senderStores.close();
    expect(senderStores.isClosed, isTrue);

    // Persistence chokepoints both reject.
    expect(senderStores.markDirty, throwsStateError);
    await expectLater(senderStores.flush(), throwsStateError);

    // And the encrypt a stale caller still holds fails loudly, so no
    // unpersisted ciphertext is ever produced.
    await expectLater(
      sender.encrypt('bob', 1, Uint8List.fromList(utf8.encode('nope'))),
      throwsStateError,
    );
  });
}
