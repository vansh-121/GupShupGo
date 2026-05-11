// Smoke test for the libsignal_protocol_dart wiring.
//
// This is intentionally minimal — it proves round-trip encryption works
// between two in-memory peers without touching Firestore, secure storage,
// or any of our wrapper layers. If this fails, the issue is in the
// underlying lib or our basic understanding of the API; full integration
// tests live elsewhere.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

void main() {
  test('Alice ↔ Bob round-trip encrypt/decrypt', () async {
    // Alice
    final aIdentity = generateIdentityKeyPair();
    final aRegId = generateRegistrationId(false);
    final aSession = InMemorySessionStore();
    final aPreKeys = InMemoryPreKeyStore();
    final aSigned = InMemorySignedPreKeyStore();
    final aIdStore = InMemoryIdentityKeyStore(aIdentity, aRegId);

    // Bob
    final bIdentity = generateIdentityKeyPair();
    final bRegId = generateRegistrationId(false);
    final bSession = InMemorySessionStore();
    final bPreKeys = InMemoryPreKeyStore();
    final bSigned = InMemorySignedPreKeyStore();
    final bIdStore = InMemoryIdentityKeyStore(bIdentity, bRegId);

    // Bob publishes his bundle.
    final bSignedPreKey = generateSignedPreKey(bIdentity, 1);
    final bOneTime = generatePreKeys(0, 1).first;
    await bSigned.storeSignedPreKey(bSignedPreKey.id, bSignedPreKey);
    await bPreKeys.storePreKey(bOneTime.id, bOneTime);

    final bobAddr = SignalProtocolAddress('bob', 1);

    // Alice builds a session to Bob from Bob's published bundle.
    final bundle = PreKeyBundle(
      bRegId,
      1,
      bOneTime.id,
      bOneTime.getKeyPair().publicKey,
      bSignedPreKey.id,
      bSignedPreKey.getKeyPair().publicKey,
      bSignedPreKey.signature,
      bIdentity.getPublicKey(),
    );
    final builder =
        SessionBuilder(aSession, aPreKeys, aSigned, aIdStore, bobAddr);
    await builder.processPreKeyBundle(bundle);

    // Alice encrypts.
    final aCipher =
        SessionCipher(aSession, aPreKeys, aSigned, aIdStore, bobAddr);
    final ct = await aCipher.encrypt(
        Uint8List.fromList(utf8.encode('hello bob')));

    expect(ct.getType(), CiphertextMessage.prekeyType);

    // Bob decrypts. PreKey message on first contact.
    final aliceAddr = SignalProtocolAddress('alice', 1);
    final bCipher =
        SessionCipher(bSession, bPreKeys, bSigned, bIdStore, aliceAddr);
    final pt =
        await bCipher.decrypt(PreKeySignalMessage(ct.serialize()));

    expect(utf8.decode(pt), 'hello bob');

    // Now bob encrypts back — should be a regular SignalMessage.
    final ct2 = await bCipher.encrypt(
        Uint8List.fromList(utf8.encode('hi alice')));
    expect(ct2.getType(), CiphertextMessage.whisperType);
    final pt2 = await aCipher
        .decryptFromSignal(SignalMessage.fromSerialized(ct2.serialize()));
    expect(utf8.decode(pt2), 'hi alice');
  });
}
