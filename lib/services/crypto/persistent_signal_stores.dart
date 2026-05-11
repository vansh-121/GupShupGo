// E2EE: persistent Signal Protocol stores.
//
// libsignal_protocol_dart ships InMemory* stores. We need persistence across
// app launches, so we wrap them: load a snapshot at startup, mark dirty on
// every write, and flush periodically (and on app pause) to secure storage.
//
// Why secure storage and not sqflite for everything:
// - Identity *private* key MUST be in Keystore/Keychain. flutter_secure_storage
//   gives us that with no extra ceremony.
// - PreKeys, SignedPreKeys, and Sessions contain sensitive ratchet state
//   (chain keys, root key, ephemeral private keys). On a rooted device, sqflite
//   files are readable; flutter_secure_storage is not. So we keep them all in
//   secure storage.
// - The snapshot is small in practice (≤100 prekeys + a handful of sessions ≈
//   tens of KB). When it grows beyond ~256 KB we'll migrate sessions to an
//   sqflite DB encrypted with a Keystore-held key.
//
// Concurrency: all mutations route through `_flushSoon()` which debounces
// writes by 250ms. `flush()` forces an immediate write — call before app
// background, on signOut, and before backup snapshot.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

class PersistentSignalStores {
  PersistentSignalStores._({
    required this.identityKeyPair,
    required this.registrationId,
    required _Persistor persistor,
  })  : identityStore =
            InMemoryIdentityKeyStore(identityKeyPair, registrationId),
        preKeyStore = InMemoryPreKeyStore(),
        signedPreKeyStore = InMemorySignedPreKeyStore(),
        sessionStore = InMemorySessionStore(),
        _persistor = persistor;

  /// Direct, synchronous access — these are immutable for the lifetime of
  /// the device install. The InMemoryIdentityKeyStore wraps them with the
  /// async API that libsignal's SessionCipher / SessionBuilder expect.
  final IdentityKeyPair identityKeyPair;
  final int registrationId;

  final InMemoryIdentityKeyStore identityStore;
  final InMemoryPreKeyStore preKeyStore;
  final InMemorySignedPreKeyStore signedPreKeyStore;
  final InMemorySessionStore sessionStore;
  final _Persistor _persistor;

  Timer? _debounce;

  static const _identityKey = 'gsg_e2ee_identity_v1';
  static const _registrationIdKey = 'gsg_e2ee_registration_id_v1';
  static const _storesKey = 'gsg_e2ee_stores_v1';

  static const FlutterSecureStorage _ss = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Loads existing stores from secure storage, or generates a fresh identity
  /// if none exists. The identity keypair and registration id are returned so
  /// callers can publish the public bundle on first install.
  static Future<PersistentSignalStores> load() async {
    final identityB64 = await _ss.read(key: _identityKey);
    final regIdStr = await _ss.read(key: _registrationIdKey);

    IdentityKeyPair identityKeyPair;
    int registrationId;
    bool generated = false;

    if (identityB64 == null || regIdStr == null) {
      identityKeyPair = generateIdentityKeyPair();
      registrationId = generateRegistrationId(false);
      await _ss.write(
        key: _identityKey,
        value: base64Encode(identityKeyPair.serialize()),
      );
      await _ss.write(key: _registrationIdKey, value: '$registrationId');
      generated = true;
    } else {
      identityKeyPair =
          IdentityKeyPair.fromSerialized(base64Decode(identityB64));
      registrationId = int.parse(regIdStr);
    }

    final stores = PersistentSignalStores._(
      identityKeyPair: identityKeyPair,
      registrationId: registrationId,
      persistor: _Persistor(),
    );

    if (!generated) {
      final snapshot = await _ss.read(key: _storesKey);
      if (snapshot != null) {
        try {
          await stores._persistor.hydrate(snapshot, stores);
        } catch (e) {
          // A corrupted snapshot would otherwise brick E2EE forever. The
          // identity keypair is preserved (different storage key), so peers
          // who've already trusted this device's identity stay trusted; only
          // the per-peer ratchet sessions are lost and will be re-established
          // on the next message. We delete the snapshot so the next flush()
          // writes a clean one.
          // ignore: avoid_print
          print('PersistentSignalStores hydrate failed — wiping snapshot: $e');
          await _ss.delete(key: _storesKey);
        }
      }
    }
    return stores;
  }

  /// Schedules a debounced flush. Call after every mutating store operation.
  void markDirty() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), flush);
  }

  /// Forces an immediate snapshot of all stores to secure storage. Call on
  /// app pause/detach and before any backup.
  Future<void> flush() async {
    _debounce?.cancel();
    final snapshot = await _persistor.snapshot(this);
    await _ss.write(key: _storesKey, value: snapshot);
  }

  /// Wipes all key material. Use on signOut + on "Reset encryption" UI action.
  static Future<void> wipe() async {
    await _ss.delete(key: _identityKey);
    await _ss.delete(key: _registrationIdKey);
    await _ss.delete(key: _storesKey);
  }

  /// Used by BackupService — returns the latest stores snapshot JSON.
  static Future<String?> exportSnapshot() async {
    return _ss.read(key: _storesKey);
  }

  /// Used by BackupService restore — rewrites identity + snapshot from the
  /// decrypted backup. Caller must call SignalService.init() again after.
  static Future<void> importSnapshot({
    required String identityKeyPairB64,
    required int registrationId,
    required String? stateSnapshot,
  }) async {
    await _ss.write(key: _identityKey, value: identityKeyPairB64);
    await _ss.write(key: _registrationIdKey, value: '$registrationId');
    if (stateSnapshot != null) {
      await _ss.write(key: _storesKey, value: stateSnapshot);
    } else {
      await _ss.delete(key: _storesKey);
    }
  }
}

/// Serializes the four stores to / from a single JSON blob. Each entry uses
/// libsignal's own `.serialize()` byte format, base64-encoded for transport.
class _Persistor {
  Future<String> snapshot(PersistentSignalStores s) async {
    return jsonEncode({
      'preKeys': await _dumpPreKeys(s.preKeyStore),
      'signedPreKeys': await _dumpSignedPreKeys(s.signedPreKeyStore),
      'sessions': await _dumpSessions(s.sessionStore),
      'trustedIdentities':
          await _dumpTrustedIdentities(s.identityStore),
    });
  }

  Future<void> hydrate(String json, PersistentSignalStores s) async {
    final map = jsonDecode(json) as Map<String, dynamic>;
    await _restorePreKeys(map['preKeys'] ?? {}, s.preKeyStore);
    await _restoreSignedPreKeys(
        map['signedPreKeys'] ?? {}, s.signedPreKeyStore);
    await _restoreSessions(map['sessions'] ?? {}, s.sessionStore);
    await _restoreTrustedIdentities(
        map['trustedIdentities'] ?? {}, s.identityStore);
  }

  // ── PreKeys ────────────────────────────────────────────────────────────
  Future<Map<String, String>> _dumpPreKeys(InMemoryPreKeyStore store) async {
    final out = <String, String>{};
    // No public iterator exposed; we track ids elsewhere. Anything we never
    // stored locally won't be in the snapshot. (DeviceIdentityService keeps
    // the canonical id list and re-stores on hydrate failure.)
    for (var id = 0; id < 200; id++) {
      if (await store.containsPreKey(id)) {
        final rec = await store.loadPreKey(id);
        out['$id'] = base64Encode(rec.serialize());
      }
    }
    return out;
  }

  Future<void> _restorePreKeys(
      Map<String, dynamic> map, InMemoryPreKeyStore store) async {
    for (final entry in map.entries) {
      final id = int.parse(entry.key);
      final rec = PreKeyRecord.fromBuffer(base64Decode(entry.value as String));
      await store.storePreKey(id, rec);
    }
  }

  // ── SignedPreKeys ──────────────────────────────────────────────────────
  Future<Map<String, String>> _dumpSignedPreKeys(
      InMemorySignedPreKeyStore store) async {
    final out = <String, String>{};
    for (final rec in await store.loadSignedPreKeys()) {
      out['${rec.id}'] = base64Encode(rec.serialize());
    }
    return out;
  }

  Future<void> _restoreSignedPreKeys(
      Map<String, dynamic> map, InMemorySignedPreKeyStore store) async {
    for (final entry in map.entries) {
      final id = int.parse(entry.key);
      final rec = SignedPreKeyRecord.fromSerialized(
          base64Decode(entry.value as String));
      await store.storeSignedPreKey(id, rec);
    }
  }

  // ── Sessions ───────────────────────────────────────────────────────────
  // Key format: "<uid>|<deviceId>" → base64(SessionRecord serialized bytes).
  // libsignal_protocol_dart's InMemorySessionStore stores already-serialized
  // bytes in a public `sessions` HashMap<SignalProtocolAddress, Uint8List>,
  // so we can dump them directly without round-tripping through
  // SessionRecord.serialize().
  Future<Map<String, String>> _dumpSessions(
      InMemorySessionStore store) async {
    final out = <String, String>{};
    store.sessions.forEach((addr, bytes) {
      out['${addr.getName()}|${addr.getDeviceId()}'] = base64Encode(bytes);
    });
    return out;
  }

  Future<void> _restoreSessions(
      Map<String, dynamic> map, InMemorySessionStore store) async {
    for (final entry in map.entries) {
      final parts = entry.key.split('|');
      final addr = SignalProtocolAddress(parts[0], int.parse(parts[1]));
      final rec =
          SessionRecord.fromSerialized(base64Decode(entry.value as String));
      await store.storeSession(addr, rec);
    }
  }

  // ── Trusted identities ─────────────────────────────────────────────────
  // store.trustedKeys is the public HashMap<SignalProtocolAddress, IdentityKey>.
  Future<Map<String, String>> _dumpTrustedIdentities(
      InMemoryIdentityKeyStore store) async {
    final out = <String, String>{};
    store.trustedKeys.forEach((addr, key) {
      out['${addr.getName()}|${addr.getDeviceId()}'] =
          base64Encode(key.serialize());
    });
    return out;
  }

  Future<void> _restoreTrustedIdentities(
      Map<String, dynamic> map, InMemoryIdentityKeyStore store) async {
    for (final entry in map.entries) {
      final parts = entry.key.split('|');
      final addr = SignalProtocolAddress(parts[0], int.parse(parts[1]));
      final key = IdentityKey.fromBytes(base64Decode(entry.value as String), 0);
      await store.saveIdentity(addr, key);
    }
  }
}

/// Helper: random bytes via libsignal's RNG, exposed for media-key generation
/// and Agora-call-key generation outside the Signal layer.
Uint8List signalRandomBytes(int length) {
  // Uses the same RNG libsignal uses internally; falls through to the
  // platform-secure RNG.
  return generateRandomBytes(length);
}
