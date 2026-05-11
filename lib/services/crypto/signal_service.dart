// SignalService — high-level E2EE API for the rest of the app.
//
// Responsibilities:
//  • Hold the singleton PersistentSignalStores
//  • Build a session with a peer device (lazy, on first message)
//  • encrypt(peerUid, peerDeviceId, plaintext) → ciphertext bytes
//  • decrypt(peerUid, peerDeviceId, ciphertext, isPrekey) → plaintext bytes
//  • For convenience, encryptForUser() fans out to ALL of a user's devices
//    and returns a Map<deviceId, ciphertext> the ChatService writes to
//    Firestore as a single message envelope.
//
// Multi-device contract:
//   • A *user* is identified by their Firebase UID.
//   • A *device* is identified by an integer deviceId (1, 2, 3…) chosen
//     by the device at first registration and stored in secure storage.
//     Device 1 is conventionally the user's primary phone.
//   • Each (uid, deviceId) pair has its own Signal session.
//   • To encrypt a message to user B, we encrypt N copies — one per
//     device B has registered — and one extra copy for every OTHER
//     device the sender has registered (for self-sync).
//
// The PreKeyBundle for a peer is fetched from Firestore at
//   users/{peerUid}/devices/{deviceId}/keyBundle
// and the one-time prekey is "consumed" via the Cloud Function
// `consumeOneTimePreKey` (one-time prekeys are deleted after one use to
// preserve forward secrecy at session setup).

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import 'persistent_signal_stores.dart';

class SignalService {
  SignalService._(this._stores);
  final PersistentSignalStores _stores;

  static SignalService? _instance;
  static SignalService get instance {
    final i = _instance;
    if (i == null) {
      throw StateError(
          'SignalService.init() must be called before instance is used.');
    }
    return i;
  }

  static Future<SignalService> init() async {
    if (_instance != null) return _instance!;
    final stores = await PersistentSignalStores.load();
    _instance = SignalService._(stores);
    return _instance!;
  }

  PersistentSignalStores get stores => _stores;

  IdentityKey get publicIdentityKey =>
      _stores.identityKeyPair.getPublicKey();

  // ── Sessions ────────────────────────────────────────────────────────────

  /// True iff we already have an established session with (peerUid, deviceId).
  Future<bool> hasSession(String peerUid, int peerDeviceId) async {
    final addr = SignalProtocolAddress(peerUid, peerDeviceId);
    return _stores.sessionStore.containsSession(addr);
  }

  /// Build a session by fetching the peer's PreKeyBundle from Firestore.
  /// Idempotent — bails out cheaply if a session already exists.
  Future<void> ensureSession(String peerUid, int peerDeviceId) async {
    final addr = SignalProtocolAddress(peerUid, peerDeviceId);
    if (await _stores.sessionStore.containsSession(addr)) return;

    final bundle = await _fetchPreKeyBundle(peerUid, peerDeviceId);
    if (bundle == null) {
      throw StateError(
          'No keyBundle for $peerUid:$peerDeviceId — peer is not E2EE-ready.');
    }

    final builder = SessionBuilder(
      _stores.sessionStore,
      _stores.preKeyStore,
      _stores.signedPreKeyStore,
      _stores.identityStore,
      addr,
    );
    await builder.processPreKeyBundle(bundle);
    _stores.markDirty();
  }

  /// Fetches the peer's public PreKeyBundle from Firestore, consuming one
  /// one-time prekey via the Cloud Function. Returns null if the peer has no
  /// devices registered for E2EE.
  Future<PreKeyBundle?> _fetchPreKeyBundle(String peerUid, int deviceId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(peerUid)
        .collection('devices')
        .doc('$deviceId')
        .get();
    final data = doc.data();
    if (data == null || data['keyBundle'] == null) return null;
    final bundle = data['keyBundle'] as Map<String, dynamic>;

    final registrationId = bundle['registrationId'] as int;
    final identityPub = base64Decode(bundle['identityPub'] as String);
    final signedPreKeyId = bundle['signedPreKeyId'] as int;
    final signedPreKeyPub =
        base64Decode(bundle['signedPreKeyPub'] as String);
    final signedPreKeySig =
        base64Decode(bundle['signedPreKeySig'] as String);

    // Consume a one-time prekey atomically via Cloud Function. Falls back to
    // a no-OTPK bundle if the peer is out of one-time keys (less forward
    // secrecy but still functional).
    int? oneTimePreKeyId;
    Uint8List? oneTimePreKeyPub;
    try {
      final otpk = await _consumeOneTimePreKey(peerUid, deviceId);
      if (otpk != null) {
        oneTimePreKeyId = otpk['id'] as int;
        oneTimePreKeyPub = base64Decode(otpk['pub'] as String);
      }
    } catch (e) {
      // Falls through to no-OTPK bundle.
      // ignore: avoid_print
      print('consumeOneTimePreKey failed: $e — proceeding without OTPK');
    }

    return PreKeyBundle(
      registrationId,
      deviceId,
      oneTimePreKeyId,
      oneTimePreKeyPub == null ? null : Curve.decodePoint(oneTimePreKeyPub, 0),
      signedPreKeyId,
      Curve.decodePoint(signedPreKeyPub, 0),
      signedPreKeySig,
      IdentityKey.fromBytes(identityPub, 0),
    );
  }

  Future<Map<String, dynamic>?> _consumeOneTimePreKey(
      String peerUid, int deviceId) async {
    final idToken =
        await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) return null;
    final response = await http.post(
      Uri.parse(
          'https://us-central1-videocallapp-81166.cloudfunctions.net/consumeOneTimePreKey'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'targetUid': peerUid, 'deviceId': deviceId}),
    );
    if (response.statusCode != 200) return null;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['preKey'] == null) return null;
    return body['preKey'] as Map<String, dynamic>;
  }

  // ── Encrypt / Decrypt ───────────────────────────────────────────────────

  /// Encrypt for a single peer device.
  Future<EncryptedEnvelope> encrypt(
      String peerUid, int peerDeviceId, Uint8List plaintext) async {
    await ensureSession(peerUid, peerDeviceId);
    final addr = SignalProtocolAddress(peerUid, peerDeviceId);
    final cipher = SessionCipher(
      _stores.sessionStore,
      _stores.preKeyStore,
      _stores.signedPreKeyStore,
      _stores.identityStore,
      addr,
    );
    final ct = await cipher.encrypt(plaintext);
    _stores.markDirty();
    return EncryptedEnvelope(
      bytes: ct.serialize(),
      isPreKeyMessage: ct.getType() == CiphertextMessage.prekeyType,
    );
  }

  /// Decrypt from a single peer device.
  Future<Uint8List> decrypt(
      String peerUid, int peerDeviceId, EncryptedEnvelope env) async {
    final addr = SignalProtocolAddress(peerUid, peerDeviceId);
    final cipher = SessionCipher(
      _stores.sessionStore,
      _stores.preKeyStore,
      _stores.signedPreKeyStore,
      _stores.identityStore,
      addr,
    );

    Uint8List plaintext;
    if (env.isPreKeyMessage) {
      final msg = PreKeySignalMessage(env.bytes);
      plaintext = await cipher.decrypt(msg);
    } else {
      final msg = SignalMessage.fromSerialized(env.bytes);
      plaintext = await cipher.decryptFromSignal(msg);
    }
    _stores.markDirty();
    return plaintext;
  }

  /// Fan-out encrypt for every device the recipient (and the sender's other
  /// devices, for self-sync) has registered. Returns a map keyed by
  /// "<uid>:<deviceId>" → envelope.
  Future<Map<String, EncryptedEnvelope>> encryptForUser({
    required String senderUid,
    required int senderDeviceId,
    required String recipientUid,
    required Uint8List plaintext,
  }) async {
    final out = <String, EncryptedEnvelope>{};
    final recipientDevices =
        await _listDeviceIds(recipientUid);
    final senderOtherDevices = (await _listDeviceIds(senderUid))
      ..removeWhere((d) => d == senderDeviceId);

    for (final d in recipientDevices) {
      out['$recipientUid:$d'] = await encrypt(recipientUid, d, plaintext);
    }
    for (final d in senderOtherDevices) {
      out['$senderUid:$d'] = await encrypt(senderUid, d, plaintext);
    }
    return out;
  }

  // 60-second cache for device-id lookups. The expensive Firestore query
  // was firing twice per message (once for sender, once for recipient),
  // which dominated end-to-end send latency. Device lists rarely change —
  // new devices register at sign-in time, weeks apart — so this cache is
  // safe and the TTL prevents stale state from lingering more than a
  // minute after a new device joins.
  static final Map<String, ({DateTime at, List<int> ids})> _deviceIdCache = {};

  Future<List<int>> _listDeviceIds(String uid) async {
    final hit = _deviceIdCache[uid];
    if (hit != null &&
        DateTime.now().difference(hit.at).inSeconds < 60) {
      return hit.ids;
    }
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .where('keyBundle', isNull: false)
        .get();
    final ids = snap.docs
        .map((d) => int.tryParse(d.id))
        .whereType<int>()
        .toList();
    _deviceIdCache[uid] = (at: DateTime.now(), ids: ids);
    return ids;
  }

  /// Invalidate the device-id cache for a user. Call from
  /// DeviceIdentityService after a fresh registration so subsequent sends
  /// see the new device immediately.
  static void invalidateDeviceCache(String uid) =>
      _deviceIdCache.remove(uid);

  // ── Wipe (used by signOut and "Reset encryption") ───────────────────────
  static Future<void> wipe() async {
    await PersistentSignalStores.wipe();
    _instance = null;
  }
}

/// A serialized Signal ciphertext together with the flag the recipient needs
/// to decide between PreKeySignalMessage and SignalMessage.
class EncryptedEnvelope {
  EncryptedEnvelope({required this.bytes, required this.isPreKeyMessage});

  final Uint8List bytes;
  final bool isPreKeyMessage;

  Map<String, dynamic> toMap() => {
        'ct': base64Encode(bytes),
        'pk': isPreKeyMessage,
      };

  factory EncryptedEnvelope.fromMap(Map<String, dynamic> map) =>
      EncryptedEnvelope(
        bytes: base64Decode(map['ct'] as String),
        isPreKeyMessage: map['pk'] as bool,
      );
}
