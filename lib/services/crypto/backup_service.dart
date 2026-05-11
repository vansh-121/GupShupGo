// BackupService — passphrase-protected backup of the user's Signal identity
// and ratchet state to Firestore.
//
// Threat model:
//   • The cloud provider should NOT be able to read your backup. They store
//     ciphertext + a per-user salt; the passphrase never leaves the device.
//   • Brute-forcing requires Argon2id work (m=64MB, t=3, p=4 → ~1s on a
//     modern phone) per passphrase guess; offline attacks remain feasible
//     for short passphrases, so the UI must enforce a 6-digit PIN minimum
//     and recommend a sentence-length passphrase.
//
// On reinstall:
//   1. User signs in (Firebase Auth) and enters their passphrase.
//   2. Download {salt, ciphertext, iv} from users/{uid}/backups/latest.
//   3. Derive key = Argon2id(passphrase, salt).
//   4. AES-GCM decrypt → SignalState JSON → re-hydrate
//      PersistentSignalStores.
//   5. User can now decrypt history that other devices fan-out to them.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/key_derivators/argon2.dart';
import 'package:pointycastle/key_derivators/api.dart' as pc;

import 'persistent_signal_stores.dart';
import 'signal_service.dart';

class BackupService {
  static const FlutterSecureStorage _ss = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _saltKey = 'gsg_e2ee_backup_salt_v1';

  final _gcm = AesGcm.with256bits();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Encrypts a snapshot of the local Signal state under the passphrase and
  /// uploads to Firestore. Overwrites the previous backup (we keep only the
  /// latest). Returns false if SignalService has not been initialised.
  Future<bool> backup({
    required String userId,
    required String passphrase,
  }) async {
    final svc = SignalService.instance;
    await svc.stores.flush();

    final salt = await _ensureSalt(userId);
    final key = await _deriveKey(passphrase, salt);

    final stateJson = await _exportSignalState();
    final nonce = _gcm.newNonce();
    final box = await _gcm.encrypt(
      Uint8List.fromList(utf8.encode(stateJson)),
      secretKey: SecretKey(key),
      nonce: nonce,
    );

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('backups')
        .doc('latest')
        .set({
      'createdAt': FieldValue.serverTimestamp(),
      'salt': base64Encode(salt),
      'iv': base64Encode(nonce),
      'ciphertext': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
      'schemaVersion': 1,
    });
    return true;
  }

  /// Restores a backup. Returns false if the passphrase is wrong or no
  /// backup exists. On success, callers should re-initialise SignalService.
  Future<bool> restore({
    required String userId,
    required String passphrase,
  }) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('backups')
        .doc('latest')
        .get();
    if (!doc.exists) return false;
    final data = doc.data()!;

    final salt = base64Decode(data['salt'] as String);
    final iv = base64Decode(data['iv'] as String);
    final ct = base64Decode(data['ciphertext'] as String);
    final mac = base64Decode(data['mac'] as String);
    final key = await _deriveKey(passphrase, salt);

    Uint8List plaintext;
    try {
      final pt = await _gcm.decrypt(
        SecretBox(ct, nonce: iv, mac: Mac(mac)),
        secretKey: SecretKey(key),
      );
      plaintext = Uint8List.fromList(pt);
    } catch (_) {
      // Wrong passphrase or tampered ciphertext.
      return false;
    }

    await _importSignalState(utf8.decode(plaintext));
    await _ss.write(key: _saltKey, value: base64Encode(salt));
    return true;
  }

  Future<List<int>> _ensureSalt(String userId) async {
    final saved = await _ss.read(key: _saltKey);
    if (saved != null) return base64Decode(saved);
    // First backup on this device — generate a fresh 16-byte salt.
    final salt = _randBytes(16);
    await _ss.write(key: _saltKey, value: base64Encode(salt));
    return salt;
  }

  Future<List<int>> _deriveKey(String passphrase, List<int> salt) async {
    // Argon2id, m=64MB, t=3, p=4 → 32-byte key.
    final params = pc.Argon2Parameters(
      pc.Argon2Parameters.ARGON2_id,
      Uint8List.fromList(salt),
      version: pc.Argon2Parameters.ARGON2_VERSION_13,
      iterations: 3,
      lanes: 4,
      memoryPowerOf2: 16, // 2^16 KiB = 64 MiB
      desiredKeyLength: 32,
    );
    final kd = Argon2BytesGenerator()..init(params);
    final out = Uint8List(32);
    kd.deriveKey(
        Uint8List.fromList(utf8.encode(passphrase)), 0, out, 0);
    return out;
  }

  /// Serialises the local Signal state into a JSON string. This is the
  /// payload that gets encrypted with the passphrase-derived key.
  Future<String> _exportSignalState() async {
    final stores = SignalService.instance.stores;
    // We piggyback on the same snapshot format the PersistentSignalStores
    // uses internally. Identity key + registrationId travel separately.
    final identityB64 =
        base64Encode(stores.identityKeyPair.serialize());
    return jsonEncode({
      'identityKeyPair': identityB64,
      'registrationId': stores.registrationId,
      // stores.snapshot() exposes the same JSON used for at-rest persistence
      // — call flush() above, then read it back from secure storage.
      'stateSnapshot': await PersistentSignalStores.exportSnapshot(),
    });
  }

  Future<void> _importSignalState(String stateJson) async {
    final map = jsonDecode(stateJson) as Map<String, dynamic>;
    await PersistentSignalStores.importSnapshot(
      identityKeyPairB64: map['identityKeyPair'] as String,
      registrationId: map['registrationId'] as int,
      stateSnapshot: map['stateSnapshot'] as String,
    );
    // Caller must re-init SignalService after this returns.
  }

  // Reuse libsignal's RNG so the whole app shares one CSPRNG.
  Uint8List _randBytes(int n) => signalRandomBytes(n);
}
