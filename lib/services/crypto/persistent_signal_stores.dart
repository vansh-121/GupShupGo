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
// Concurrency & durability: all mutations route through `markDirty()`, which
// debounces writes by 3000ms to coalesce bursts of encrypt/decrypt activity.
// `flush()` forces an immediate, awaited write and is what the receive path
// uses after every successful decrypt — the debounce alone is NOT a
// durability guarantee, because a crash or low-memory kill inside the window
// loses the ratchet advance, which desyncs the receive chain and makes every
// *subsequent* message from that peer fail to decrypt too.
//
// `flush()` is strictly serialized behind `_inFlight`. That matters more than
// it looks: an earlier version snapshotted the four stores, then awaited an
// isolate hop and the write, so two overlapping flushes could each snapshot at
// their own start time and the *older* snapshot could land last — silently
// rolling the ratchet backwards with no crash involved at all. Serializing the
// writes and taking the snapshot synchronously closes that window.
//
// Flushing after every single decrypt is affordable because `flush()` compares
// the fresh snapshot against the last one it wrote and skips the Keystore
// write when they match — the encode is sub-millisecond, the Keystore write is
// the expensive part. See [_lastWrittenJson] for why this is content-based
// rather than a dirty counter.

import 'dart:async';
import 'dart:convert';

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

  /// Do **not** put a `SessionRecord` cache in front of this store.
  ///
  /// It looks like free performance — `loadSession` re-parses the protobuf on
  /// every call — but libsignal 0.7.1's `SessionState.fromSessionState` shares
  /// the underlying protobuf instead of deep-copying it, so a *failed* decrypt
  /// mutates the record in memory. That is harmless today only because
  /// `InMemorySessionStore` holds bytes and re-parses on every load, letting
  /// the mutation get collected when `storeSession` is never reached. Handing
  /// out cached instances would make that corruption permanent, which presents
  /// as a peer whose messages stop decrypting for no visible reason.
  final InMemorySessionStore sessionStore;
  final _Persistor _persistor;

  Timer? _debounce;

  /// The exact JSON last written to secure storage, or null if we haven't
  /// written yet this session. [flush] compares a fresh snapshot against this
  /// and skips the Keystore write when they're identical.
  ///
  /// Deliberately content-based rather than a dirty counter: several call
  /// sites (DeviceIdentityService's bundle publish, prekey replenish and
  /// signed-prekey rotation) mutate the stores directly and then call
  /// `flush()` without going through [markDirty]. A counter would treat those
  /// as clean and silently drop freshly generated prekeys — after which every
  /// peer's PreKeySignalMessage fails with InvalidKeyIdException. Comparing
  /// content can't be fooled by a missing markDirty call.
  String? _lastWrittenJson;

  /// The currently-running (or last-completed) flush. New flushes chain onto
  /// this so writes never overlap and can never land out of order.
  Future<void>? _inFlight;

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
          // Baseline for flush()'s unchanged-content check. Re-derive it from
          // the freshly hydrated stores rather than reusing `snapshot`: key
          // ordering and legacy-format entries can differ, and a mismatched
          // baseline would just cost one redundant write on the next flush —
          // but a *matching* one that didn't reflect memory would skip a
          // needed write, which is the failure mode that loses ratchet state.
          stores._lastWrittenJson = stores._persistor.snapshotSync(stores);
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
          stores._lastWrittenJson = null;
        }
      }
    }
    return stores;
  }

  /// Schedules a debounced flush. Call after every mutating store operation.
  ///
  /// The 3000ms window coalesces bursts of encrypt/decrypt activity (sending
  /// 5 rapid messages, opening a chat with 20 sessions) into a single
  /// snapshot write instead of 5-20 individual writes, keeping Keystore
  /// stress low on devices with slow secure storage (Xiaomi, OPPO, etc.).
  ///
  /// This is a latency optimization, NOT a durability guarantee. Anything
  /// that must survive a crash — every receive-side ratchet advance — has to
  /// `await flush()` instead. See [flush].
  void markDirty() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 3000), () {
      unawaited(flush());
    });
  }

  /// Writes a snapshot of all four stores to secure storage and does not
  /// return until it is durably on disk.
  ///
  /// Safe and cheap to call on every received message:
  ///  • Serializes behind any in-flight write rather than racing it, so two
  ///    concurrent callers can never land snapshots out of order.
  ///  • Skips the Keystore write entirely when the snapshot is unchanged,
  ///    which is the common case for repeated calls.
  Future<void> flush() {
    final chained = (_inFlight ?? Future<void>.value()).then((_) => _write());
    // Swallow errors on the chain itself so one failed write doesn't poison
    // every subsequent flush. The returned future still surfaces the error
    // to this caller.
    _inFlight = chained.catchError((_) {});
    return chained;
  }

  Future<void> _write() async {
    _debounce?.cancel();

    // Snapshot synchronously. All four stores keep already-serialized bytes
    // in a plain map, so this is a map copy plus base64 — no awaits, which
    // means no mutation can interleave between reading the stores and
    // encoding them. jsonEncode on tens of KB is sub-millisecond, so there
    // is nothing here worth an isolate hop — and that hop was itself the
    // window that let two flushes land their snapshots out of order.
    final json = _persistor.snapshotSync(this);

    // Unchanged since the last write — the ratchet hasn't moved, so there is
    // nothing to persist. This is what makes flushing after every decrypt
    // affordable: the Keystore write is the expensive part, not the encode.
    if (json == _lastWrittenJson) return;

    await _ss.write(key: _storesKey, value: json);
    _lastWrittenJson = json;
  }

  /// Wipes all key material. Use on signOut + on "Reset encryption" UI action.
  static Future<void> wipe() async {
    await _ss.delete(key: _identityKey);
    await _ss.delete(key: _registrationIdKey);
    await _ss.delete(key: _storesKey);
  }

}

/// Serializes the four stores to / from a single JSON blob. Each entry uses
/// libsignal's own `.serialize()` byte format, base64-encoded for transport.
///
/// Every dump below reads the backing map directly. libsignal's InMemory*
/// stores all keep *already-serialized* bytes (`HashMap<int, Uint8List>` /
/// `HashMap<SignalProtocolAddress, Uint8List>`), so a dump is a map walk plus
/// base64 — no deserialize/reserialize round trip, and crucially no awaits.
/// [snapshotSync] depends on that: it must be impossible for a store mutation
/// to interleave partway through a snapshot.
class _Persistor {
  /// Builds the complete snapshot JSON without yielding to the event loop.
  String snapshotSync(PersistentSignalStores s) {
    return jsonEncode(<String, Map<String, String>>{
      'preKeys': _dumpPreKeys(s.preKeyStore),
      'signedPreKeys': _dumpSignedPreKeys(s.signedPreKeyStore),
      'sessions': _dumpSessions(s.sessionStore),
      'trustedIdentities': _dumpTrustedIdentities(s.identityStore),
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
  // Enumerates the store's actual key set. The previous implementation
  // scanned ids 0..199, which silently dropped every prekey outside that
  // range — and DeviceIdentityService.replenishOneTimePreKeysIfLow allocates
  // ids from `millisecondsSinceEpoch % 1000000`, so every replenished batch
  // was lost on the next app launch.
  Map<String, String> _dumpPreKeys(InMemoryPreKeyStore store) {
    final out = <String, String>{};
    store.store.forEach((id, bytes) {
      out['$id'] = base64Encode(bytes);
    });
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
  // Reads the backing map rather than loadSignedPreKeys(), which returns the
  // records without their ids and would need a deserialize per entry.
  Map<String, String> _dumpSignedPreKeys(InMemorySignedPreKeyStore store) {
    final out = <String, String>{};
    store.store.forEach((id, bytes) {
      out['$id'] = base64Encode(bytes);
    });
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
  Map<String, String> _dumpSessions(InMemorySessionStore store) {
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
  // Unlike the other three stores this one holds live objects, so serialize().
  Map<String, String> _dumpTrustedIdentities(InMemoryIdentityKeyStore store) {
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
