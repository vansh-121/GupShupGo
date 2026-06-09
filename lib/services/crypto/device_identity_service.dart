// DeviceIdentityService — owns deviceId lifecycle, key generation, and
// publishing the public PreKeyBundle to Firestore.
//
// Called from AuthService after every successful sign-in:
//   await DeviceIdentityService().registerIfNeeded(userId);
//
// First call on a given install:
//   1. Pick a deviceId (smallest unused id under users/{uid}/devices/).
//   2. SignalService.init() generates an identity keypair + 100 OTPKs.
//   3. Publish the public bundle to users/{uid}/devices/{deviceId}/keyBundle.
//
// Subsequent calls are cheap no-ops once the local "registered" flag is set.
// We also expose replenishOneTimePreKeysIfLow(), called periodically by
// the FCM ping path when Firestore reports OTPK count < 20.

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import 'signal_service.dart';

class DeviceIdentityService {
  static const _deviceIdKey = 'gsg_e2ee_device_id_v1';
  static const _registeredFlagKey = 'gsg_e2ee_registered_v1';

  static const FlutterSecureStorage _ss = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// The local deviceId, or null if this install has never registered.
  ///
  /// Memoised once read — the deviceId is immutable for the lifetime of
  /// an install (we never re-allocate). Without this memo, every
  /// `sendMessage` was paying a secure-storage round-trip just to look up
  /// a constant.
  static int? _cachedDeviceId;
  Future<int?> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId;
    final s = await _ss.read(key: _deviceIdKey);
    if (s == null) return null;
    _cachedDeviceId = int.parse(s);
    return _cachedDeviceId;
  }

  Future<int> _allocateDeviceId(String uid) async {
    final existing = await _firestore
        .collection('users')
        .doc(uid)
        .collection('devices')
        .get();
    final used = existing.docs.map((d) => int.tryParse(d.id)).whereType<int>().toSet();
    var id = 1;
    while (used.contains(id)) {
      id++;
    }
    return id;
  }

  /// Deletes ALL device docs for [uid] except the newly registered [keepDeviceId].
  ///
  /// Every app reinstall registers a new deviceId but never cleaned up the old
  /// one. Over time this causes 50+ stale entries, each with a valid keyBundle.
  /// The send path then encrypts one copy per device — bloating every message
  /// doc to 50+ envelopes (~50-100 KB) and slowing Firestore reads/writes for
  /// everyone in the conversation. The old devices can never decrypt anyway
  /// (their Signal keys were wiped on uninstall), so removing them is safe.
  Future<void> _pruneStaleDevices(String uid, int keepDeviceId) async {
    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('devices')
          .get();
      final stale = snap.docs.where((d) {
        final id = int.tryParse(d.id);
        return id != null && id != keepDeviceId;
      }).toList();
      if (stale.isEmpty) return;
      // Batch-delete stale devices + their oneTimePreKeys subcollections.
      // Firestore batches are limited to 500 ops; chunk if needed.
      const maxOps = 490;
      var batch = _firestore.batch();
      var ops = 0;
      for (final doc in stale) {
        batch.delete(doc.reference);
        ops++;
        if (ops >= maxOps) {
          await batch.commit();
          batch = _firestore.batch();
          ops = 0;
        }
        // Best-effort: also wipe the oneTimePreKeys subcollection. Firestore
        // doesn't cascade-delete subcollections, so orphaned OTPKs stay around
        // forever otherwise. We cap at 110 docs per device (100 OTPKs + margin)
        // to avoid unbounded reads.
        try {
          final otpkSnap = await doc.reference
              .collection('oneTimePreKeys')
              .limit(110)
              .get();
          for (final otpk in otpkSnap.docs) {
            batch.delete(otpk.reference);
            ops++;
            if (ops >= maxOps) {
              await batch.commit();
              batch = _firestore.batch();
              ops = 0;
            }
          }
        } catch (_) {}
      }
      if (ops > 0) await batch.commit();
      // ignore: avoid_print
      print('[E2EE] pruned ${stale.length} stale device(s) for $uid, '
          'kept device $keepDeviceId');
    } catch (e) {
      // ignore: avoid_print
      print('[E2EE] stale device prune failed (non-fatal): $e');
    }
  }

  static const _prunedFlagKey = 'gsg_e2ee_pruned_stale_v1';

  /// Idempotent: registers this device for the given user iff not already
  /// registered. Returns the deviceId in use.
  Future<int> registerIfNeeded(String userId) async {
    final already = await _ss.read(key: _registeredFlagKey);
    if (already == userId) {
      final id = await getDeviceId();
      if (id != null) {
        // One-time retroactive prune for existing users. New installs get
        // cleaned during registration (below); this catches users who
        // already have 40+ stale device docs from prior reinstalls.
        final pruned = await _ss.read(key: _prunedFlagKey);
        if (pruned != userId) {
          unawaited(() async {
            try {
              await _pruneStaleDevices(userId, id);
              await _ss.write(key: _prunedFlagKey, value: userId);
            } catch (_) {}
          }());
        }
        return id;
      }
    }

    final svc = await SignalService.init();
    final deviceId = await _allocateDeviceId(userId);

    final signedPreKey =
        generateSignedPreKey(svc.stores.identityKeyPair, _signedPreKeyId());
    await svc.stores.signedPreKeyStore
        .storeSignedPreKey(signedPreKey.id, signedPreKey);

    final preKeys = generatePreKeys(0, 100);
    for (final pk in preKeys) {
      await svc.stores.preKeyStore.storePreKey(pk.id, pk);
    }

    final publicOneTimePreKeys = preKeys
        .map((p) => {
              'id': p.id,
              'pub': base64Encode(p.getKeyPair().publicKey.serialize()),
            })
        .toList();

    final bundle = {
      'registrationId': svc.stores.registrationId,
      'identityPub': base64Encode(
          svc.stores.identityKeyPair.getPublicKey().serialize()),
      'signedPreKeyId': signedPreKey.id,
      'signedPreKeyPub':
          base64Encode(signedPreKey.getKeyPair().publicKey.serialize()),
      'signedPreKeySig': base64Encode(signedPreKey.signature),
      'createdAt': FieldValue.serverTimestamp(),
    };

    final deviceRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('devices')
        .doc('$deviceId');

    // Write the bundle and a separate `oneTimePreKeys` subcollection so the
    // Cloud Function can atomically consume + delete one per session start.
    final batch = _firestore.batch();
    batch.set(deviceRef, {'keyBundle': bundle}, SetOptions(merge: true));
    for (final otpk in publicOneTimePreKeys) {
      batch.set(
        deviceRef.collection('oneTimePreKeys').doc('${otpk['id']}'),
        otpk,
      );
    }
    await batch.commit();

    await svc.stores.flush();
    await _ss.write(key: _deviceIdKey, value: '$deviceId');
    await _ss.write(key: _registeredFlagKey, value: userId);
    _cachedDeviceId = deviceId;
    // Drop the cached device list so peers see this device on their next
    // send instead of waiting up to 60s for the TTL to expire.
    SignalService.invalidateDeviceCache(userId);

    // Clean up stale device entries from previous installs. Fire-and-forget
    // so registration returns quickly; the prune is best-effort.
    unawaited(_pruneStaleDevices(userId, deviceId));

    return deviceId;
  }

  /// Refills the one-time prekey pool on Firestore if it's running low.
  /// Idempotent and cheap when the pool is healthy.
  Future<void> replenishOneTimePreKeysIfLow(String userId) async {
    final deviceId = await getDeviceId();
    if (deviceId == null) return;

    final otpkSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('devices')
        .doc('$deviceId')
        .collection('oneTimePreKeys')
        .get();
    if (otpkSnap.size >= 20) return;

    final svc = SignalService.instance;
    // Start IDs after the highest existing local prekey id to avoid collisions.
    final start = DateTime.now().millisecondsSinceEpoch % 1000000;
    final preKeys = generatePreKeys(start, 100);
    final batch = _firestore.batch();
    for (final pk in preKeys) {
      await svc.stores.preKeyStore.storePreKey(pk.id, pk);
      batch.set(
        _firestore
            .collection('users')
            .doc(userId)
            .collection('devices')
            .doc('$deviceId')
            .collection('oneTimePreKeys')
            .doc('${pk.id}'),
        {
          'id': pk.id,
          'pub': base64Encode(pk.getKeyPair().publicKey.serialize()),
        },
      );
    }
    await batch.commit();
    await svc.stores.flush();
  }

  /// Returns the signed-prekey id for this rotation period (one new
  /// SignedPreKey per week, identified by the week-since-epoch number).
  int _signedPreKeyId() {
    final weeks = DateTime.now().millisecondsSinceEpoch ~/
        Duration(days: 7).inMilliseconds;
    return weeks & 0xFFFFFF;
  }

  /// Rotates the SignedPreKey if it's older than 7 days. Call from the
  /// app-resume hook or a background task.
  ///
  /// IMPORTANT: Old signed pre-keys are retained for [_signedPreKeyRetention]
  /// rotation periods. A peer may cache our Firestore keyBundle for minutes
  /// or hours; if we delete the old signed pre-key immediately after
  /// rotation, their PreKeyMessage references a signedPreKeyId we no
  /// longer have → InvalidKeyIdException on decrypt. Keeping the last 3
  /// weeks' worth ensures those in-flight sessions still decrypt.
  static const _signedPreKeyRetention = 3; // keep last N rotation periods

  Future<void> rotateSignedPreKeyIfStale(String userId) async {
    final deviceId = await getDeviceId();
    if (deviceId == null) return;

    final svc = SignalService.instance;
    final newId = _signedPreKeyId();
    if (await svc.stores.signedPreKeyStore.containsSignedPreKey(newId)) {
      return;
    }
    final signedPreKey =
        generateSignedPreKey(svc.stores.identityKeyPair, newId);
    await svc.stores.signedPreKeyStore
        .storeSignedPreKey(signedPreKey.id, signedPreKey);

    // ── Prune signed pre-keys older than the retention window ──────────
    // We keep the current + previous N rotation-period keys. Each rotation
    // period is one week, so _signedPreKeyRetention = 3 means we keep
    // ~4 weeks of keys total (current + 3 previous).
    try {
      final allSpks = await svc.stores.signedPreKeyStore.loadSignedPreKeys();
      final currentWeek = newId;
      for (final spk in allSpks) {
        // Only prune keys whose ID is a rotation-period ID and is old
        // enough. IDs wrap at 0xFFFFFF but in practice they increase
        // monotonically, so a simple difference check works for the
        // lifetime of the app.
        if (spk.id != currentWeek &&
            (currentWeek - spk.id) > _signedPreKeyRetention) {
          await svc.stores.signedPreKeyStore.removeSignedPreKey(spk.id);
        }
      }
    } catch (e) {
      // Non-fatal: worst case we keep a few extra keys in memory/storage.
      // ignore: avoid_print
      print('[E2EE] signed pre-key prune failed (non-fatal): $e');
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('devices')
        .doc('$deviceId')
        .set({
      'keyBundle': {
        'signedPreKeyId': signedPreKey.id,
        'signedPreKeyPub':
            base64Encode(signedPreKey.getKeyPair().publicKey.serialize()),
        'signedPreKeySig': base64Encode(signedPreKey.signature),
        'rotatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
    await svc.stores.flush();
  }

  Future<void> wipeLocal() async {
    await _ss.delete(key: _deviceIdKey);
    await _ss.delete(key: _registeredFlagKey);
    _cachedDeviceId = null;
  }
}
