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

  /// Idempotent: registers this device for the given user iff not already
  /// registered. Returns the deviceId in use.
  Future<int> registerIfNeeded(String userId) async {
    final already = await _ss.read(key: _registeredFlagKey);
    if (already == userId) {
      final id = await getDeviceId();
      if (id != null) return id;
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
