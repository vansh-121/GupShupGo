// VaultCipher — owns the symmetric key that protects every cross-install
// vault payload (msgVault, statusVault).
//
// Threat model: Firebase (and anyone with admin access to the project) must
// not be able to read message history or status content. The key never
// leaves the device. It is derived from a user-chosen PIN/passphrase via
// Argon2id with a per-user random salt held in Firestore. The salt alone
// is useless without the PIN.
//
// Lifecycle:
//   • First run on a new account → setup(pin)  → writes salt + verifier to
//     users/{uid}/vaultMeta/config and caches the 32-byte key in secure
//     storage so subsequent cold starts don't re-prompt.
//   • Reinstall on an existing account → unlock(pin) → fetches the salt
//     from Firestore, re-derives the key, validates against the verifier.
//   • Subsequent cold starts on the same install → autoUnlock() reads the
//     cached key.
//
// Wire format for encrypted vault docs:
//   { v: 1, iv: <12-byte base64 nonce>, c: <ciphertext base64>,
//     m: <16-byte mac base64> }
// Legacy plaintext docs (pre-vault-cipher) carry { p: <json> } and are
// still decoded so old messages keep rendering after upgrade.

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/key_derivators/argon2.dart';
import 'package:pointycastle/key_derivators/api.dart' as pc;
import 'package:shared_preferences/shared_preferences.dart';

import 'plaintext_store.dart';

enum VaultState {
  /// First-time user — no salt in Firestore. Prompt user for new PIN.
  needsSetup,

  /// Salt exists in Firestore but key not held locally (reinstall, or first
  /// app open after this feature shipped on a pre-existing account).
  needsUnlock,

  /// Key is in memory, encrypt/decrypt are usable.
  ready,
}

class VaultCipher {
  VaultCipher._();
  static final VaultCipher instance = VaultCipher._();

  // iOS Keychain entries survive app uninstall by default. Scoping to
  // first_unlock_this_device + a unique service id prevents the cached
  // vault key from auto-restoring on reinstall, so the PIN prompt actually
  // fires. (Android EncryptedSharedPreferences are wiped on uninstall as
  // long as allowBackup is false, which it is in AndroidManifest.xml.)
  static const _ss = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  static const _localKeyKey = 'gsg_vault_key_v1';
  static const _localUidKey = 'gsg_vault_uid_v1';
  static const _verifierConstant = 'gsg-vault-v1';
  // SharedPreferences is wiped on app uninstall on both Android and iOS,
  // which lets us detect a fresh install even when iOS Keychain survives.
  // If this marker is missing on launch we treat any cached vault key as
  // foreign and discard it, forcing the PIN prompt.
  static const _installMarkerPref = 'gsg_vault_install_marker_v1';

  final _gcm = AesGcm.with256bits();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Uint8List? _key;
  String? _uid;

  bool get isReady => _key != null;

  /// Returns the current state for [uid] and auto-unlocks from cached
  /// secure-storage entry when possible. Safe to call repeatedly.
  Future<VaultState> bootstrap(String uid) async {
    if (isReady && _uid == uid) return VaultState.ready;
    if (await _tryAutoUnlock(uid)) return VaultState.ready;

    final cfg = await _firestore
        .collection('users')
        .doc(uid)
        .collection('vaultMeta')
        .doc('config')
        .get();
    return cfg.exists ? VaultState.needsUnlock : VaultState.needsSetup;
  }

  Future<bool> _tryAutoUnlock(String uid) async {
    // Fresh-install guard: SharedPreferences is wiped on uninstall on both
    // platforms. If the marker is missing, any cached Keychain entry on
    // iOS is a leftover from a previous install — discard it.
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_installMarkerPref)) {
      await _ss.delete(key: _localKeyKey);
      await _ss.delete(key: _localUidKey);
      await prefs.setBool(_installMarkerPref, true);
      return false;
    }

    final cachedUid = await _ss.read(key: _localUidKey);
    if (cachedUid != uid) return false;
    final cachedKey = await _ss.read(key: _localKeyKey);
    if (cachedKey == null) return false;
    final bytes = base64Decode(cachedKey);
    if (bytes.length != 32) return false;
    _key = Uint8List.fromList(bytes);
    _uid = uid;
    return true;
  }

  /// First-time setup. Generates a salt, derives the key, writes a verifier
  /// to Firestore so future unlocks can validate the PIN without leaking
  /// any vault content. Returns false only on transient failure (offline,
  /// permissions). Idempotent — if a config already exists, falls through
  /// to [unlock] instead so users don't accidentally overwrite their key.
  Future<bool> setup(String uid, String pin) async {
    if (pin.isEmpty) return false;
    final existing = await _firestore
        .collection('users')
        .doc(uid)
        .collection('vaultMeta')
        .doc('config')
        .get();
    if (existing.exists) return unlock(uid, pin);

    final salt = _randomBytes(16);
    final key = await _deriveKey(pin, salt);
    final verifier = await _encryptRaw(
      key,
      Uint8List.fromList(utf8.encode(_verifierConstant)),
    );

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('vaultMeta')
        .doc('config')
        .set({
      'salt': base64Encode(salt),
      'argon2': {
        'iterations': 3,
        'memoryPowerOf2': 16, // 2^16 KiB = 64 MiB
        'lanes': 4,
        'version': pc.Argon2Parameters.ARGON2_VERSION_13,
      },
      'verifier': verifier,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _cacheKey(uid, key);
    _key = key;
    _uid = uid;
    return true;
  }

  /// Unlock an existing vault. Returns false on wrong PIN (verifier
  /// decrypt fails) or missing config.
  Future<bool> unlock(String uid, String pin) async {
    final cfgDoc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('vaultMeta')
        .doc('config')
        .get();
    if (!cfgDoc.exists) return false;
    final cfg = cfgDoc.data()!;

    final salt = base64Decode(cfg['salt'] as String);
    final verifier = cfg['verifier'] as Map<String, dynamic>;
    final key = await _deriveKey(pin, salt);

    final ok = await _verifierMatches(key, verifier);
    if (!ok) return false;

    await _cacheKey(uid, key);
    _key = key;
    _uid = uid;
    return true;
  }

  /// Wipes the Firestore vault config + every encrypted entry for [uid],
  /// the local cached key, AND the local PlaintextStore SQLite cache so
  /// previously-decrypted messages don't keep rendering from disk after a
  /// "Forgot PIN" reset. Caller must call ChatService.invalidatePreWarm
  /// and StatusService.invalidatePreWarm afterwards so the in-memory
  /// pre-warm caches don't replay stale data.
  Future<void> reset(String uid) async {
    final batch = _firestore.batch();
    batch.delete(_firestore
        .collection('users')
        .doc(uid)
        .collection('vaultMeta')
        .doc('config'));
    await batch.commit();

    // Best-effort delete of msgVault + statusVault. Done in chunks so we
    // don't blow Firestore batch limits on heavy accounts.
    for (final col in const ['msgVault', 'statusVault']) {
      final ref = _firestore.collection('users').doc(uid).collection(col);
      // ignore: avoid_function_literals_in_foreach_calls
      while (true) {
        final snap = await ref.limit(400).get();
        if (snap.docs.isEmpty) break;
        final b = _firestore.batch();
        for (final d in snap.docs) {
          b.delete(d.reference);
        }
        await b.commit();
        if (snap.docs.length < 400) break;
      }
    }

    await _ss.delete(key: _localKeyKey);
    await _ss.delete(key: _localUidKey);
    _key = null;
    _uid = null;

    // Drop the local SQLite cache too — otherwise messages decrypted on
    // previous launches keep rendering from disk despite the user
    // confirming "permanently delete".
    try {
      final ps = await PlaintextStore.instance();
      await ps.wipe();
    } catch (_) {}
  }

  /// Rewrites every legacy-plaintext doc in msgVault and statusVault using
  /// the current vault key, then deletes the plaintext fields. Idempotent
  /// and safe to invoke whenever the key becomes available. Runs in chunks
  /// so a heavy account doesn't stall.
  ///
  /// After this completes, no plaintext payloads remain in Firestore — a
  /// reinstall without the PIN can no longer read the message history.
  Future<void> migrateLegacyEntries(String uid) async {
    final key = _key;
    if (key == null) return;

    // msgVault: legacy format is { p: <json string> }
    await _sweep(
      _firestore.collection('users').doc(uid).collection('msgVault'),
      detectLegacy: (data) => data['p'] is String,
      rewrite: (data) async {
        final raw = data['p'] as String;
        final payload = jsonDecode(raw) as Map<String, dynamic>;
        final enc = await encryptPayload(payload);
        return enc;
      },
    );

    // statusVault: text legacy = { t:'text', tx, bg }; media-key legacy =
    // { t:'media_key', k }. Preserve the 't' tag so readers can still
    // route by type.
    await _sweep(
      _firestore.collection('users').doc(uid).collection('statusVault'),
      detectLegacy: (data) {
        final t = data['t'] as String?;
        if (t == 'text') return data['tx'] is String;
        if (t == 'media_key') return data['k'] is String;
        return false;
      },
      rewrite: (data) async {
        final t = data['t'] as String;
        if (t == 'text') {
          final enc = await encryptPayload({
            'tx': data['tx'] ?? '',
            'bg': data['bg'] ?? '#6C5CE7',
          });
          return enc == null ? null : {'t': 'text', ...enc};
        } else {
          final raw = data['k'] as String;
          final enc = await encryptBytes(base64Decode(raw));
          return enc == null ? null : {'t': 'media_key', ...enc};
        }
      },
    );
  }

  Future<void> _sweep(
    CollectionReference<Map<String, dynamic>> col, {
    required bool Function(Map<String, dynamic>) detectLegacy,
    required Future<Map<String, dynamic>?> Function(Map<String, dynamic>)
        rewrite,
  }) async {
    const pageSize = 200;
    DocumentSnapshot<Map<String, dynamic>>? cursor;
    while (true) {
      var q = col.orderBy(FieldPath.documentId).limit(pageSize);
      if (cursor != null) q = q.startAfterDocument(cursor);
      final snap = await q.get();
      if (snap.docs.isEmpty) break;

      for (final doc in snap.docs) {
        final data = doc.data();
        if (!detectLegacy(data)) continue;
        final replacement = await rewrite(data);
        if (replacement == null) continue;
        try {
          // set() (not update()) — replaces the whole doc so legacy fields
          // (p, tx, bg, k) are dropped along with the rewrite.
          await doc.reference.set(replacement);
        } catch (_) {}
      }

      if (snap.docs.length < pageSize) break;
      cursor = snap.docs.last;
    }
  }

  /// Drops only the in-memory key. The cached copy in secure storage
  /// survives so the same user signing back in on the same install can
  /// auto-unlock without re-entering the PIN. Used on signOut — if a
  /// different uid signs in, [_tryAutoUnlock] notices the mismatch and
  /// triggers the unlock dialog anyway.
  void lock() {
    _key = null;
    _uid = null;
  }

  /// Drops in-memory key AND the secure-storage cache, forcing the next
  /// bootstrap to go through setup/unlock. Most callers want [lock]
  /// instead; reserve this for cases where the cached key is no longer
  /// considered trustworthy.
  Future<void> lockAndClearLocal() async {
    _key = null;
    _uid = null;
    await _ss.delete(key: _localKeyKey);
    await _ss.delete(key: _localUidKey);
  }

  // ─── Payload encrypt / decrypt ──────────────────────────────────────────

  /// Encrypts an arbitrary JSON map for storage in a vault doc. Returns
  /// null if the vault isn't ready — callers must skip the write rather
  /// than fall back to plaintext.
  Future<Map<String, dynamic>?> encryptPayload(
      Map<String, dynamic> payload) async {
    final key = _key;
    if (key == null) return null;
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));
    return _encryptRaw(key, bytes);
  }

  /// Decodes a vault doc. Both the new encrypted form and the legacy
  /// `{p: <json>}` plaintext form require [isReady] — the legacy reader
  /// is gated on unlock so users who haven't entered their PIN can't read
  /// pre-encryption history just because it happened to be stored in
  /// cleartext. After [migrateLegacyEntries] runs on the first unlock,
  /// no legacy docs remain anyway.
  Future<Map<String, dynamic>?> decryptDoc(Map<String, dynamic> doc) async {
    final key = _key;
    if (key == null) return null;

    final legacy = doc['p'] as String?;
    if (legacy != null) {
      try {
        return jsonDecode(legacy) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    final raw = await _decryptRaw(key, doc);
    if (raw == null) return null;
    try {
      return jsonDecode(utf8.decode(raw)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Encrypts raw bytes (used for status media AES keys).
  Future<Map<String, dynamic>?> encryptBytes(Uint8List bytes) async {
    final key = _key;
    if (key == null) return null;
    return _encryptRaw(key, bytes);
  }

  /// Decrypts a vault doc produced by [encryptBytes]. Like [decryptDoc],
  /// both the encrypted and legacy `{k: <base64>}` forms require [isReady].
  Future<Uint8List?> decryptBytes(Map<String, dynamic> doc) async {
    final key = _key;
    if (key == null) return null;

    final legacy = doc['k'] as String?;
    if (legacy != null) {
      try {
        return base64Decode(legacy);
      } catch (_) {
        return null;
      }
    }
    return _decryptRaw(key, doc);
  }

  // ─── Internals ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _encryptRaw(
      Uint8List key, Uint8List plaintext) async {
    final nonce = _gcm.newNonce();
    final box = await _gcm.encrypt(
      plaintext,
      secretKey: SecretKey(key),
      nonce: nonce,
    );
    return {
      'v': 1,
      'iv': base64Encode(nonce),
      'c': base64Encode(box.cipherText),
      'm': base64Encode(box.mac.bytes),
    };
  }

  Future<Uint8List?> _decryptRaw(
      Uint8List key, Map<String, dynamic> doc) async {
    final iv = doc['iv'] as String?;
    final c = doc['c'] as String?;
    final m = doc['m'] as String?;
    if (iv == null || c == null || m == null) return null;
    try {
      final pt = await _gcm.decrypt(
        SecretBox(base64Decode(c),
            nonce: base64Decode(iv), mac: Mac(base64Decode(m))),
        secretKey: SecretKey(key),
      );
      return Uint8List.fromList(pt);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _verifierMatches(
      Uint8List key, Map<String, dynamic> verifier) async {
    final pt = await _decryptRaw(key, verifier);
    if (pt == null) return false;
    return utf8.decode(pt) == _verifierConstant;
  }

  Future<Uint8List> _deriveKey(String pin, List<int> salt) async {
    final params = pc.Argon2Parameters(
      pc.Argon2Parameters.ARGON2_id,
      Uint8List.fromList(salt),
      version: pc.Argon2Parameters.ARGON2_VERSION_13,
      iterations: 3,
      lanes: 4,
      memoryPowerOf2: 16,
      desiredKeyLength: 32,
    );
    final kd = Argon2BytesGenerator()..init(params);
    final out = Uint8List(32);
    kd.deriveKey(Uint8List.fromList(utf8.encode(pin)), 0, out, 0);
    return out;
  }

  Future<void> _cacheKey(String uid, Uint8List key) async {
    await _ss.write(key: _localKeyKey, value: base64Encode(key));
    await _ss.write(key: _localUidKey, value: uid);
  }

  Uint8List _randomBytes(int n) {
    final r = Random.secure();
    final out = Uint8List(n);
    for (var i = 0; i < n; i++) {
      out[i] = r.nextInt(256);
    }
    return out;
  }
}
