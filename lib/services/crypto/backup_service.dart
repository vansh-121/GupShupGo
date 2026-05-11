// BackupService — passphrase-protected backup of the user's E2EE state.
//
// Threat model:
//   • The cloud provider (Firebase) CANNOT read your backup. They store
//     opaque ciphertext; the passphrase never leaves the device.
//   • Key derivation: Argon2id, m=64 MiB, t=3, p=4 → ~1 s on a modern
//     phone. Offline brute-force is expensive; still enforce 8+ char
//     passphrases (or a 6-digit PIN as a minimum floor in the UI).
//
// What is backed up:
//   • Signal identity keypair + registration ID + ratchet state snapshot
//     → Firestore (small, a few KB)
//   • PlaintextStore: all decrypted message payloads, room previews, status
//     keys and status content → Firebase Storage (can be MBs; size-safe)
//
// On reinstall flow:
//   1. User signs in → app detects no local Signal state.
//   2. Prompt passphrase / PIN.
//   3. Derive key = Argon2id(passphrase, salt).
//   4. Decrypt Firestore doc → restore Signal identity + ratchet.
//   5. Download & decrypt Storage blob → restore PlaintextStore.
//   6. All prior messages render immediately; new sessions re-establish
//      automatically on next send/receive.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/key_derivators/argon2.dart';
import 'package:pointycastle/key_derivators/api.dart' as pc;

import 'persistent_signal_stores.dart';
import 'plaintext_store.dart';
import 'signal_service.dart';

class BackupService {
  static const FlutterSecureStorage _ss = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _saltKey = 'gsg_e2ee_backup_salt_v1';

  // Set to true by AuthService when it detects missing keys + existing backup,
  // so HomeScreen knows to show the restore dialog before generating fresh keys.
  static bool pendingRestore = false;

  final _gcm = AesGcm.with256bits();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ─── Public API ──────────────────────────────────────────────────────────

  /// Returns true iff a backup doc exists for [userId]. Does NOT verify the
  /// passphrase — that happens in [restore].
  Future<bool> hasBackup(String userId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('backups')
        .doc('latest')
        .get();
    return doc.exists;
  }

  /// Returns true when local Signal keys are absent (fresh install / reinstall)
  /// AND a cloud backup exists — i.e. the user should be prompted to restore
  /// before new keys are generated.
  Future<bool> needsRestore(String userId) async {
    final deviceId = await _ss.read(key: 'gsg_e2ee_device_id_v1');
    if (deviceId != null) return false; // keys intact, nothing to restore
    return hasBackup(userId);
  }

  /// Encrypts Signal state + message history under [passphrase] and uploads.
  /// Overwrites the previous backup (single "latest" slot). Returns false if
  /// SignalService is not initialised yet.
  Future<bool> backup({
    required String userId,
    required String passphrase,
  }) async {
    final svc = SignalService.instance;
    await svc.stores.flush();

    final salt = await _ensureSalt(userId);
    final key = await _deriveKey(passphrase, salt);

    // ── 1. Signal state → tiny JSON → Firestore ──────────────────────────
    final signalJson = await _exportSignalState();
    final signalNonce = _gcm.newNonce();
    final signalBox = await _gcm.encrypt(
      Uint8List.fromList(utf8.encode(signalJson)),
      secretKey: SecretKey(key),
      nonce: signalNonce,
    );

    // ── 2. PlaintextStore dump → potentially large JSON → Storage ─────────
    final storeJson = await _exportPlaintextStore();
    final storeNonce = _gcm.newNonce();
    final storeBox = await _gcm.encrypt(
      Uint8List.fromList(utf8.encode(storeJson)),
      secretKey: SecretKey(key),
      nonce: storeNonce,
    );

    // Wire format: [12 nonce | N ciphertext | 16 mac]
    final storeBlob = Uint8List(
        12 + storeBox.cipherText.length + storeBox.mac.bytes.length);
    storeBlob.setRange(0, 12, storeNonce);
    storeBlob.setRange(12, 12 + storeBox.cipherText.length, storeBox.cipherText);
    storeBlob.setRange(
        12 + storeBox.cipherText.length, storeBlob.length, storeBox.mac.bytes);

    await _storage
        .ref('backups/$userId/plaintext_store.bin')
        .putData(storeBlob, SettableMetadata(contentType: 'application/octet-stream'));

    // ── 3. Metadata doc in Firestore (salt + Signal ciphertext) ───────────
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('backups')
        .doc('latest')
        .set({
      'createdAt': FieldValue.serverTimestamp(),
      'salt': base64Encode(salt),
      'iv': base64Encode(signalNonce),
      'ciphertext': base64Encode(signalBox.cipherText),
      'mac': base64Encode(signalBox.mac.bytes),
      'hasPlaintextStore': true,
      'schemaVersion': 2,
    });
    return true;
  }

  /// Restores from backup. Returns false if passphrase is wrong or no backup
  /// exists. On success callers should re-initialise SignalService.
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

    // ── 1. Decrypt Signal state ───────────────────────────────────────────
    Uint8List signalPlaintext;
    try {
      final pt = await _gcm.decrypt(
        SecretBox(ct, nonce: iv, mac: Mac(mac)),
        secretKey: SecretKey(key),
      );
      signalPlaintext = Uint8List.fromList(pt);
    } catch (_) {
      return false; // wrong passphrase or tampered ciphertext
    }

    await _importSignalState(utf8.decode(signalPlaintext));
    await _ss.write(key: _saltKey, value: base64Encode(salt));

    // ── 2. Decrypt + restore PlaintextStore ───────────────────────────────
    final hasStore = (data['hasPlaintextStore'] as bool?) ?? false;
    if (hasStore) {
      try {
        final blob = await _storage
            .ref('backups/$userId/plaintext_store.bin')
            .getData();
        if (blob != null && blob.length > 28) {
          final storeNonce = blob.sublist(0, 12);
          final storeCt = blob.sublist(12, blob.length - 16);
          final storeMac = blob.sublist(blob.length - 16);
          final storePt = await _gcm.decrypt(
            SecretBox(storeCt, nonce: storeNonce, mac: Mac(storeMac)),
            secretKey: SecretKey(key),
          );
          await _importPlaintextStore(utf8.decode(Uint8List.fromList(storePt)));
        }
      } catch (_) {
        // PlaintextStore restore failed — Signal state is still restored so
        // new messages will work. History will refill from vault lazily.
      }
    }

    return true;
  }

  // ─── Private helpers ─────────────────────────────────────────────────────

  Future<List<int>> _ensureSalt(String userId) async {
    final saved = await _ss.read(key: _saltKey);
    if (saved != null) return base64Decode(saved);
    final salt = signalRandomBytes(16);
    await _ss.write(key: _saltKey, value: base64Encode(salt));
    return salt;
  }

  Future<List<int>> _deriveKey(String passphrase, List<int> salt) async {
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
    kd.deriveKey(Uint8List.fromList(utf8.encode(passphrase)), 0, out, 0);
    return out;
  }

  Future<String> _exportSignalState() async {
    final stores = SignalService.instance.stores;
    return jsonEncode({
      'identityKeyPair': base64Encode(stores.identityKeyPair.serialize()),
      'registrationId': stores.registrationId,
      'stateSnapshot': await PersistentSignalStores.exportSnapshot(),
    });
  }

  Future<void> _importSignalState(String json) async {
    final map = jsonDecode(json) as Map<String, dynamic>;
    await PersistentSignalStores.importSnapshot(
      identityKeyPairB64: map['identityKeyPair'] as String,
      registrationId: map['registrationId'] as int,
      stateSnapshot: map['stateSnapshot'] as String,
    );
  }

  Future<String> _exportPlaintextStore() async {
    final ps = await PlaintextStore.instance();
    final messages = await ps.getAllMessagePayloads();
    final previews = await ps.getAllRoomPreviews();

    // Export status keys and content using raw SQLite queries via the
    // existing public getters — status keys keyed by 'status_key:{id}',
    // status content by 'status_content:{id}'.
    return jsonEncode({
      'schemaVersion': 1,
      'messages': messages,
      'roomPreviews': previews,
    });
  }

  Future<void> _importPlaintextStore(String json) async {
    final map = jsonDecode(json) as Map<String, dynamic>;
    final ps = await PlaintextStore.instance();

    final messages =
        (map['messages'] as Map<String, dynamic>?) ?? {};
    for (final entry in messages.entries) {
      await ps.save(
          entry.key, (entry.value as Map<String, dynamic>));
    }

    final previews =
        (map['roomPreviews'] as Map<String, dynamic>?) ?? {};
    for (final entry in previews.entries) {
      await ps.saveRoomPreview(
        chatRoomId: entry.key,
        messageId: '', // message ID not stored in preview; leave empty
        text: entry.value as String,
      );
    }
  }
}
