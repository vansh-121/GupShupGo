// CallEncryptionService — per-call key/salt derivation and exchange for
// Agora's built-in media-stream encryption.
//
// Flow:
//   • Caller generates random 32-byte key + 16-byte salt.
//   • Caller wraps {key, salt} as JSON inside a Signal-encrypted envelope
//     and writes it under calls/{channelId}/keyEnvelopes/{calleeUid:deviceId}.
//   • Callee decrypts, then both sides pass key+salt to
//     RtcEngine.enableEncryption(EncryptionConfig).
//
// Agora supports `aes256Gcm2` (recommended) which uses the same AES-256-GCM
// our text/media path uses, so we get one consistent cipher across modalities.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'persistent_signal_stores.dart';
import 'signal_service.dart';

class CallEncryptionKey {
  CallEncryptionKey({required this.key, required this.salt});
  final Uint8List key;   // 32 bytes
  final Uint8List salt;  // 16 bytes

  Map<String, String> toMap() => {
        'k': base64Encode(key),
        's': base64Encode(salt),
      };

  factory CallEncryptionKey.fromMap(Map<String, dynamic> map) =>
      CallEncryptionKey(
        key: base64Decode(map['k'] as String),
        salt: base64Decode(map['s'] as String),
      );

  static CallEncryptionKey generate() {
    return CallEncryptionKey(
      key: signalRandomBytes(32),
      salt: signalRandomBytes(16),
    );
  }
}

class CallEncryptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Caller side: generate key + salt, encrypt for every recipient device,
  /// publish to Firestore. Returns the local copy of the key/salt to feed
  /// into Agora.
  Future<CallEncryptionKey> publishKeyForCallees({
    required String channelId,
    required String senderUid,
    required int senderDeviceId,
    required String calleeUid,
  }) async {
    final key = CallEncryptionKey.generate();
    final payload = Uint8List.fromList(utf8.encode(jsonEncode(key.toMap())));

    final envelopes = await SignalService.instance.encryptForUser(
      senderUid: senderUid,
      senderDeviceId: senderDeviceId,
      recipientUid: calleeUid,
      plaintext: payload,
    );

    final batch = _firestore.batch();
    envelopes.forEach((addr, env) {
      batch.set(
        _firestore
            .collection('calls')
            .doc(channelId)
            .collection('keyEnvelopes')
            .doc(addr),
        env.toMap(),
      );
    });
    await batch.commit();
    return key;
  }

  /// Callee side: fetch the envelope addressed to (uid, deviceId), decrypt,
  /// return the key/salt. Returns null if no envelope is present yet (caller
  /// should retry on the next snapshot).
  Future<CallEncryptionKey?> fetchKey({
    required String channelId,
    required String selfUid,
    required int selfDeviceId,
    required String callerUid,
  }) async {
    final addr = '$selfUid:$selfDeviceId';
    final doc = await _firestore
        .collection('calls')
        .doc(channelId)
        .collection('keyEnvelopes')
        .doc(addr)
        .get();
    if (!doc.exists) return null;

    final env = EncryptedEnvelope.fromMap(doc.data()!);
    // The caller's deviceId is encoded in the envelope key on the sender's
    // side as senderDeviceId. We need to know which session decrypts: scan
    // all of caller's known device ids. In practice caller has 1 device for
    // an outgoing call, so we try deviceId=1 first then 2..10 as fallback.
    for (var d = 1; d <= 10; d++) {
      try {
        final pt = await SignalService.instance.decrypt(callerUid, d, env);
        final map = jsonDecode(utf8.decode(pt)) as Map<String, dynamic>;
        return CallEncryptionKey.fromMap(map);
      } catch (_) {
        // Wrong session; try next deviceId.
      }
    }
    return null;
  }
}
