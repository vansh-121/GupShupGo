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

// The caller's deviceId is encoded on the sender side as senderDeviceId and
// addressed by recipient (uid, deviceId). The callee doesn't know the
// caller's deviceId from the envelope alone, so we record it as a small
// hint field on each envelope doc — eliminates the 1..10 brute-force scan
// the previous implementation did, which on average wasted ~9 failed
// libsignal decrypts before finding the right session.
const _senderDeviceIdField = 'sd';

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
        {...env.toMap(), _senderDeviceIdField: senderDeviceId},
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

    final data = doc.data()!;
    final env = EncryptedEnvelope.fromMap(data);
    final hintedSenderDeviceId = data[_senderDeviceIdField];
    // Fast path: caller writes its deviceId alongside the envelope so the
    // callee can decrypt with the exact session on the first try. Every
    // failed libsignal decrypt advances internal state and risks
    // session-store corruption, so brute-forcing was both slow and unsafe.
    if (hintedSenderDeviceId is int) {
      try {
        final pt = await SignalService.instance
            .decrypt(callerUid, hintedSenderDeviceId, env);
        final map = jsonDecode(utf8.decode(pt)) as Map<String, dynamic>;
        return CallEncryptionKey.fromMap(map);
      } catch (_) {
        // Fall through to discovery path below — handles old envelopes
        // written by clients that pre-date the deviceId hint.
      }
    }
    // Legacy fallback: probe known caller devices. Bounded by the cached
    // device-id list (typically 1–2 entries) rather than the previous
    // hard-coded 1..10 sweep.
    final deviceIds =
        await SignalService.instance.listDeviceIdsCached(callerUid);
    for (final d in deviceIds) {
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
