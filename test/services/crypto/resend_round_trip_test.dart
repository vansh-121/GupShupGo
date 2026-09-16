// End-to-end proof that the resend protocol self-heals a broken conversation.
//
// chat_recovery_test.dart deliberately stops at the pure-function boundary and
// notes that "the end-to-end recovery loop is covered by the two-device manual
// matrix" — i.e. it is never automated. This is that automation, at the crypto
// layer: two real SignalService instances (Alice and Bob) over real libsignal
// state, no Firestore or Drift. It reproduces the production failure — a normal
// message Bob cannot decrypt because his session state was lost — and then
// drives the exact repair the sender performs in SyncService._serveOneResend
// (`signal.encryptWithFreshSession`), asserting Bob's bubble actually heals and
// the conversation keeps flowing afterward.
//
// The one crypto invariant the whole protocol rests on: the repair must be a
// PreKeySignalMessage. Only a prekey message carries the X3DH material that lets
// SessionBuilder.processV3 rebuild the receiver's session from nothing; a plain
// SignalMessage would just fail the same way the original did.

import 'dart:convert';

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

  Uint8List bytes(String s) => Uint8List.fromList(utf8.encode(s));

  const aliceAddr = SignalProtocolAddress('alice', 1);

  test('an undecryptable message self-heals once the sender serves a resend',
      () async {
    // Two independent devices, each with its own secure-storage-backed stores.
    // `storage.clear()` between the loads stops Bob from reading back the
    // identity Alice just wrote, so they get distinct identities exactly as two
    // phones would.
    final aliceStores = await PersistentSignalStores.load();
    aliceStores.suspendAutoFlush();
    storage.clear();
    final bobStores = await PersistentSignalStores.load();
    bobStores.suspendAutoFlush();

    // Each device publishes a signed prekey under id 1. The stores are
    // separate, so the shared id is not a collision.
    final aliceSigned = generateSignedPreKey(aliceStores.identityKeyPair, 1);
    await aliceStores.signedPreKeyStore.storeSignedPreKey(1, aliceSigned);
    final bobSigned = generateSignedPreKey(bobStores.identityKeyPair, 1);
    await bobStores.signedPreKeyStore.storeSignedPreKey(1, bobSigned);

    // Rebuild each bundle from copied byte buffers on every fetch. libsignal
    // 0.7.1's verifySig mutates signature[63] in place, so a shared PreKeyBundle
    // verifies once and then throws on reuse. Production is safe because
    // _fetchPreKeyBundle base64-decodes fresh buffers per call; these factories
    // reproduce that. (Same note lives in signal_service_concurrency_test.dart.)
    final aliceSignedPub = aliceSigned.getKeyPair().publicKey.serialize();
    final aliceSignedSig = aliceSigned.signature;
    final aliceIdentityPub =
        aliceStores.identityKeyPair.getPublicKey().serialize();
    PreKeyBundle aliceBundle() => PreKeyBundle(
          aliceStores.registrationId,
          1,
          null,
          null,
          1,
          Curve.decodePoint(Uint8List.fromList(aliceSignedPub), 0),
          Uint8List.fromList(aliceSignedSig),
          IdentityKey.fromBytes(Uint8List.fromList(aliceIdentityPub), 0),
        );

    final bobSignedPub = bobSigned.getKeyPair().publicKey.serialize();
    final bobSignedSig = bobSigned.signature;
    final bobIdentityPub = bobStores.identityKeyPair.getPublicKey().serialize();
    PreKeyBundle bobBundle() => PreKeyBundle(
          bobStores.registrationId,
          1,
          null,
          null,
          1,
          Curve.decodePoint(Uint8List.fromList(bobSignedPub), 0),
          Uint8List.fromList(bobSignedSig),
          IdentityKey.fromBytes(Uint8List.fromList(bobIdentityPub), 0),
        );

    final alice = SignalService.forTesting(aliceStores,
        loadBundle: (_, __) async => bobBundle());
    final bob = SignalService.forTesting(bobStores,
        loadBundle: (_, __) async => aliceBundle());

    // ── 1. A working conversation. Alice's opening message is a prekey message
    // (every new session opens with one); Bob decrypts it and now holds a
    // session for Alice.
    final opening = await alice.encrypt('bob', 1, bytes('hey bob'));
    expect(opening.isPreKeyMessage, isTrue);
    expect(utf8.decode(await bob.decrypt('alice', 1, opening)), 'hey bob');

    // Bob replies. This is load-bearing, not decoration: until the initiator
    // receives a reply it keeps sending PreKeySignalMessages, and a prekey
    // message would heal Bob on its own — masking the failure this test exists
    // to reproduce. Once Alice decrypts Bob's reply her session is settled and
    // her later sends are plain SignalMessages.
    final reply = await bob.encrypt('alice', 1, bytes('hi alice'));
    expect(reply.isPreKeyMessage, isFalse);
    expect(utf8.decode(await alice.decrypt('bob', 1, reply)), 'hi alice');

    // ── 2. Bob loses his session state. This stands in for the production
    // failure modes the rest of the fix targets — a dropped ratchet persist, a
    // concurrent read-modify-write, a mutation on a closed store — each of which
    // leaves Bob unable to advance Alice's ratchet.
    await bobStores.sessionStore.deleteSession(aliceAddr);
    expect(await bobStores.sessionStore.containsSession(aliceAddr), isFalse);

    // ── 3. Alice, with no way to know, sends a normal message on her intact
    // session. This is the bubble the user sees as "⏳ Waiting for this
    // message": a plain SignalMessage Bob has no session to open.
    final undecryptable =
        await alice.encrypt('bob', 1, bytes('are you there?'));
    expect(undecryptable.isPreKeyMessage, isFalse,
        reason: 'nothing has told Alice to re-handshake, so this is a normal '
            'message — exactly the kind that strands the receiver');
    await expectLater(
      bob.decrypt('alice', 1, undecryptable),
      throwsA(isA<NoSessionException>()),
    );

    // ── 4. Bob requests a resend; Alice serves it. This mirrors
    // SyncService._serveOneResend: the same plaintext, re-encrypted over a
    // freshly reset session. The returned envelope MUST be a prekey message or
    // the repair cannot work.
    final repair =
        await alice.encryptWithFreshSession('bob', 1, bytes('are you there?'));
    expect(repair.isPreKeyMessage, isTrue,
        reason: 'a resend that is not a prekey message carries no X3DH material '
            'and would strand Bob exactly as the original did');

    // ── 5. The heal. Bob processes the prekey message on a brand-new session
    // and reads the message that was stuck a moment ago.
    expect(
        utf8.decode(await bob.decrypt('alice', 1, repair)), 'are you there?');

    // ── 6. Forward health. The conversation is genuinely repaired, not patched
    // for one message. Bob replies on the new session (settling Alice out of
    // her pending-prekey state), and Alice's next message flows as a normal
    // SignalMessage without another handshake.
    final backToYou = await bob.encrypt('alice', 1, bytes('yes, here now'));
    expect(backToYou.isPreKeyMessage, isFalse);
    expect(utf8.decode(await alice.decrypt('bob', 1, backToYou)), 'yes, here now');

    final afterHeal = await alice.encrypt('bob', 1, bytes('great, it works'));
    expect(afterHeal.isPreKeyMessage, isFalse,
        reason: 'the healed session is fully established both ways, so normal '
            'messaging has resumed');
    expect(utf8.decode(await bob.decrypt('alice', 1, afterHeal)),
        'great, it works');
  });
}
