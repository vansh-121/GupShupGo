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

  /// Fetches the peer's public PreKeyBundle from Firestore. Returns null if
  /// the peer has no devices registered for E2EE. Uses a local cache to
  /// skip the Firestore round-trip when prewarmSessions has already fetched
  /// the bundle.
  Future<PreKeyBundle?> _fetchPreKeyBundle(String peerUid, int deviceId) async {
    final cacheKey = '$peerUid:$deviceId';

    // ── Check the bundle-data cache first ──────────────────────────────
    // Populated by prewarmSessions or a previous send. Avoids one
    // Firestore round-trip (~200-500ms) on the actual send path.
    Map<String, dynamic>? bundle;
    final cached = _bundleDataCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.at) < _bundleFreshWindow) {
      bundle = cached.bundle;
    }

    if (bundle == null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(peerUid)
          .collection('devices')
          .doc('$deviceId')
          .get();
      final data = doc.data();
      if (data == null || data['keyBundle'] == null) return null;
      bundle = data['keyBundle'] as Map<String, dynamic>;
      _bundleDataCache[cacheKey] = (at: DateTime.now(), bundle: bundle);
    }

    final registrationId = bundle['registrationId'] as int;
    final identityPub = base64Decode(bundle['identityPub'] as String);
    final signedPreKeyId = bundle['signedPreKeyId'] as int;
    final signedPreKeyPub =
        base64Decode(bundle['signedPreKeyPub'] as String);
    final signedPreKeySig =
        base64Decode(bundle['signedPreKeySig'] as String);

    // OTPK consumption is fully non-blocking. X3DH establishes a secure
    // session via signed prekey + identity key alone — the one-time prekey
    // only adds initial-message forward secrecy. Removing it from the
    // critical path eliminates the 2-10s Cloud Function cold-start that
    // was the dominant first-message latency. The OTPK is still consumed
    // in the background for pool hygiene.
    // ignore: discarded_futures
    unawaited(() async {
      try {
        await _consumeOneTimePreKey(peerUid, deviceId)
            .timeout(const Duration(seconds: 10));
      } catch (_) {}
    }());

    return PreKeyBundle(
      registrationId,
      deviceId,
      null, // no OTPK — session uses signed prekey only (X3DH still safe)
      null,
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
    final sw = Stopwatch()..start();
    final out = <String, EncryptedEnvelope>{};

    // Fetch both device lists in PARALLEL — previously these were two
    // sequential awaits, adding a full Firestore round-trip on cache miss.
    final deviceLists = await Future.wait([
      _listDeviceIds(recipientUid),
      _listDeviceIds(senderUid),
    ]);
    final recipientDevices = deviceLists[0].toList();
    final senderOtherDevices = deviceLists[1].toList()
      ..removeWhere((d) => d == senderDeviceId);

    // Never Signal-encrypt to our own posting device: it advances the session
    // ratchet at encrypt time and we'd be unable to decrypt the resulting
    // ciphertext on the same device.
    if (recipientUid == senderUid) {
      recipientDevices.removeWhere((d) => d == senderDeviceId);
    }

    print('[E2EE] device lookup: ${sw.elapsedMilliseconds}ms '
        '(recipient=${recipientDevices.length}, sender_other=${senderOtherDevices.length})');

    // Parallel fan-out across devices. Each (peerUid, deviceId) is a
    // separate session, so concurrent encrypts don't race.
    final tasks = <Future<MapEntry<String, EncryptedEnvelope>>>[
      for (final d in recipientDevices)
        encrypt(recipientUid, d, plaintext)
            .then((env) => MapEntry('$recipientUid:$d', env)),
      for (final d in senderOtherDevices)
        encrypt(senderUid, d, plaintext)
            .then((env) => MapEntry('$senderUid:$d', env)),
    ];
    for (final entry in await Future.wait(tasks)) {
      out[entry.key] = entry.value;
    }
    print('[E2EE] encryptForUser total: ${sw.elapsedMilliseconds}ms');
    return out;
  }

  // Stale-while-revalidate cache for device-id lookups. Device lists rarely
  // change (new device only on sign-in) so we keep entries effectively
  // forever and refresh them out-of-band when they age past 5 minutes.
  //
  // The original 60-second hard TTL caused a periodic ~150ms latency spike
  // on the send path: every minute the first send would synchronously
  // re-query Firestore — exactly the "sometimes the send is slow, sometimes
  // it's instant" pattern users see. With this pattern the hot path is
  // always an in-memory map hit; new devices propagate within ~5 min of the
  // next message activity. invalidateDeviceCache() forces an immediate
  // re-fetch when DeviceIdentityService registers a new device locally.
  static final Map<String, ({DateTime at, List<int> ids})> _deviceIdCache = {};
  static const _deviceIdFreshWindow = Duration(minutes: 5);
  static final Set<String> _deviceIdRefreshInFlight = <String>{};

  /// Public wrapper around the cached device-id lookup so other services
  /// (e.g. CallEncryptionService when discovering the caller's deviceId)
  /// can reuse the same cache instead of re-querying Firestore.
  Future<List<int>> listDeviceIdsCached(String uid) => _listDeviceIds(uid);

  Future<List<int>> _listDeviceIds(String uid) async {
    final hit = _deviceIdCache[uid];
    if (hit != null) {
      // Stale-but-usable: return cached IDs immediately, refresh in the
      // background. The send path NEVER blocks on this query after the
      // first lookup for a peer.
      if (DateTime.now().difference(hit.at) > _deviceIdFreshWindow) {
        _refreshDeviceIds(uid);
      }
      return hit.ids;
    }
    return _fetchAndCacheDeviceIds(uid);
  }

  Future<List<int>> _fetchAndCacheDeviceIds(String uid) async {
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

  void _refreshDeviceIds(String uid) {
    if (_deviceIdRefreshInFlight.contains(uid)) return;
    _deviceIdRefreshInFlight.add(uid);
    // ignore: discarded_futures
    _fetchAndCacheDeviceIds(uid).whenComplete(() {
      _deviceIdRefreshInFlight.remove(uid);
    }).catchError((_) => const <int>[]);
  }

  /// Invalidate the device-id cache for a user. Call from
  /// DeviceIdentityService after a fresh registration so subsequent sends
  /// see the new device immediately.
  static void invalidateDeviceCache(String uid) =>
      _deviceIdCache.remove(uid);

  // ── PreKey bundle Firestore cache ──────────────────────────────────────
  // Caches the raw keyBundle data from Firestore so prewarmSessions →
  // ensureSession → _fetchPreKeyBundle skips the Firestore round-trip on
  // the actual send path. Entries are kept for 10 min; the data changes
  // only on signed-prekey rotation (once per week).
  static final Map<String, ({DateTime at, Map<String, dynamic> bundle})>
      _bundleDataCache = {};
  static const _bundleFreshWindow = Duration(minutes: 10);

  /// Pre-establish Signal sessions with every device of every peer in
  /// [peerUids], in the background. After this runs the first encrypt for
  /// each peer becomes a pure local CPU operation — no Firestore read, no
  /// `consumeOneTimePreKey` HTTP round-trip — so the first message of the
  /// session feels as instant as the second.
  ///
  /// Idempotent and safe to call repeatedly. Best-effort: errors per peer
  /// are swallowed so one unreachable peer doesn't stall the rest.
  Future<void> prewarmSessions(List<String> peerUids) async {
    if (peerUids.isEmpty) return;
    await Future.wait(peerUids.map((uid) async {
      try {
        final devices = await _listDeviceIds(uid);
        await Future.wait(devices.map((d) async {
          try {
            await ensureSession(uid, d);
          } catch (_) {}
        }));
      } catch (_) {}
    }));
  }

  /// Warms the consumeOneTimePreKey Cloud Function's container so the
  /// background OTPK consumption after session setup doesn't pay the
  /// cold-start penalty. Uses a real POST (HEAD/OPTIONS don't trigger
  /// container boot in Firebase Functions v2). Best-effort, silent on
  /// failure.
  static Future<void> warmConsumeOneTimePreKey() async {
    try {
      final idToken =
          await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) return;
      // POST with an empty body triggers the container start. The function
      // returns 400 (missing fields) almost instantly once warm; we don't
      // care — the goal is to absorb the boot cost here.
      await http
          .post(
            Uri.parse(
                'https://us-central1-videocallapp-81166.cloudfunctions.net/consumeOneTimePreKey'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: '{}',
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

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
