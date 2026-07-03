// E2EE: persistent Signal Protocol stores.
//
// libsignal_protocol_dart ships InMemory* stores. We need persistence across
// app launches, so we wrap them: load a snapshot at startup, mark dirty on
// every write, and flush periodically (and on app pause) to secure storage.
//
// Why secure storage and not SQLite/Drift for everything:
// - Identity *private* key MUST be in Keystore/Keychain. flutter_secure_storage
//   gives us that with no extra ceremony.
// - PreKeys, SignedPreKeys, and Sessions contain sensitive ratchet state
//   (chain keys, root key, ephemeral private keys). On a rooted device, SQLite/Drift
//   files are readable; flutter_secure_storage is not. So we keep them all in
//   secure storage.
// - The snapshot is small in practice (≤100 prekeys + a handful of sessions ≈
//   tens of KB). When it grows beyond ~256 KB we'll migrate sessions to an
//   encrypted Drift database with a Keystore-held key.
//
// Concurrency: all mutations route through `markDirty()` which debounces
// writes by 1500ms. `flush()` forces an immediate write — called before app
// background and on signOut. The 1.5s window
// coalesces a burst of encrypts/decrypts (typing, reading a chat) into a
// single snapshot write; the previous 250ms window was rewriting the entire
// store ~4× per second during active chat which dominated end-to-end
// message latency. The flush-on-pause guarantee in main()/AuthService keeps
// the durability story unchanged: nothing committed to memory is lost
// across an app background.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

class PersistentSignalStores {
  PersistentSignalStores._({
    required this.identityKeyPair,
    required this.registrationId,
    required _Persistor persistor,
  })  : identityStore =
            InMemoryIdentityKeyStore(identityKeyPair, registrationId),
        preKeyStore = SafePreKeyStore(),
        signedPreKeyStore = SafeSignedPreKeyStore(),
        sessionStore = InMemorySessionStore(),
        _persistor = persistor;

  /// Direct, synchronous access — these are immutable for the lifetime of
  /// the device install. The InMemoryIdentityKeyStore wraps them with the
  /// async API that libsignal's SessionCipher / SessionBuilder expect.
  final IdentityKeyPair identityKeyPair;
  final int registrationId;

  final InMemoryIdentityKeyStore identityStore;
  final SafePreKeyStore preKeyStore;
  final SafeSignedPreKeyStore signedPreKeyStore;
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
  ///
  /// The 3000ms debounce window coalesces bursts of encrypt/decrypt activity
  /// (sending 5 rapid messages, opening a chat with 20 sessions) into a single
  /// snapshot write instead of 5-20 individual writes, significantly reducing
  /// main-thread JSON serialization and disk I/O on low-end devices.
  void markDirty() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 3000), flush);
  }

  /// Forces an immediate snapshot of all stores to secure storage. Call on
  /// app pause/detach.
  ///
  /// The CPU-heavy JSON serialization is moved to a background isolate via
  /// [compute] so the main thread stays responsive during active messaging.
  Future<void> flush() async {
    _debounce?.cancel();

    // Collect serialized store data (in-memory ops, fast — map copies + base64)
    final preKeys = await _persistor._dumpPreKeys(preKeyStore);
    final signedPreKeys = await _persistor._dumpSignedPreKeys(signedPreKeyStore);
    final sessions = await _persistor._dumpSessions(sessionStore);
    final trusted = await _persistor._dumpTrustedIdentities(identityStore);

    // JSON encode on a background isolate so the main thread isn't blocked
    // by CPU-intensive serialization of potentially hundreds of sessions.
    final json = await compute(_encodeSnapshot, <String, Map<String, String>>{
      'preKeys': preKeys,
      'signedPreKeys': signedPreKeys,
      'sessions': sessions,
      'trustedIdentities': trusted,
    });

    await _ss.write(key: _storesKey, value: json);
  }

  /// JSON-serializes the stores snapshot on a background isolate.
  /// This is a top-level function so it can be invoked via [compute].
  static String _encodeSnapshot(Map<String, Map<String, String>> data) =>
      jsonEncode(data);

  /// Wipes all key material. Use on signOut + on "Reset encryption" UI action.
  static Future<void> wipe() async {
    await _ss.delete(key: _identityKey);
    await _ss.delete(key: _registrationIdKey);
    await _ss.delete(key: _storesKey);
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
    // Fire all slot checks in one parallel batch — avoids 200 sequential
    // microtask-hops on every flush(). Each containsPreKey / loadPreKey call
    // is a synchronous HashMap lookup wrapped in an async API; running them
    // concurrently collapses all 200 into a single event-loop burst.
    final entries = await Future.wait(
      List.generate(200, (id) async {
        if (!await store.containsPreKey(id)) return null;
        final rec = await store.loadPreKey(id);
        return MapEntry('$id', base64Encode(rec.serialize()));
      }),
    );
    for (final e in entries) {
      if (e != null) out[e.key] = e.value;
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

class SafePreKeyStore extends InMemoryPreKeyStore {
  @override
  Future<PreKeyRecord> loadPreKey(int preKeyId) async {
    try {
      return await super.loadPreKey(preKeyId);
    } catch (e, st) {
      return Future.error(e, st);
    }
  }

  @override
  Future<void> storePreKey(int preKeyId, PreKeyRecord record) async {
    try {
      await super.storePreKey(preKeyId, record);
    } catch (e, st) {
      return Future.error(e, st);
    }
  }

  @override
  Future<bool> containsPreKey(int preKeyId) async {
    try {
      return await super.containsPreKey(preKeyId);
    } catch (e, st) {
      return Future.error(e, st);
    }
  }

  @override
  Future<void> removePreKey(int preKeyId) async {
    try {
      await super.removePreKey(preKeyId);
    } catch (e, st) {
      return Future.error(e, st);
    }
  }
}

class SafeSignedPreKeyStore extends InMemorySignedPreKeyStore {
  @override
  Future<SignedPreKeyRecord> loadSignedPreKey(int signedPreKeyId) async {
    try {
      return await super.loadSignedPreKey(signedPreKeyId);
    } catch (e, st) {
      return Future.error(e, st);
    }
  }

  @override
  Future<void> storeSignedPreKey(int signedPreKeyId, SignedPreKeyRecord record) async {
    try {
      await super.storeSignedPreKey(signedPreKeyId, record);
    } catch (e, st) {
      return Future.error(e, st);
    }
  }

  @override
  Future<bool> containsSignedPreKey(int signedPreKeyId) async {
    try {
      return await super.containsSignedPreKey(signedPreKeyId);
    } catch (e, st) {
      return Future.error(e, st);
    }
  }

  @override
  Future<void> removeSignedPreKey(int signedPreKeyId) async {
    try {
      await super.removeSignedPreKey(signedPreKeyId);
    } catch (e, st) {
      return Future.error(e, st);
    }
  }

  @override
  Future<List<SignedPreKeyRecord>> loadSignedPreKeys() async {
    try {
      return await super.loadSignedPreKeys();
    } catch (e, st) {
      return Future.error(e, st);
    }
  }
}
