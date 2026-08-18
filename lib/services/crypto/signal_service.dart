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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import 'persistent_signal_stores.dart';

class SignalService {
  SignalService._(this._stores);
  final PersistentSignalStores _stores;

  Future<T> _runSignalAction<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    runZonedGuarded(() async {
      try {
        final res = await action();
        completer.complete(res);
      } catch (e, st) {
        completer.completeError(e, st);
      }
    }, (error, stack) {
      if (!completer.isCompleted) {
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }

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

  /// Drops the cached instance so the next [init] builds a genuinely fresh set
  /// of stores from what is on disk right now.
  ///
  /// **For the FCM background isolate only.** Android reuses that isolate across
  /// pushes, so a second push would otherwise keep serving from stores hydrated
  /// at the first push — by which time the main isolate may have started and
  /// written a newer blob. Re-hydrating the existing instance is not a
  /// substitute: [PersistentSignalStores.hydrate] *merges* into whatever is
  /// already in memory, so a session the main isolate deliberately deleted would
  /// survive here and be written back on the next flush.
  ///
  /// Never call this from the main isolate. Everything holding a reference to
  /// the old instance would keep mutating stores that no longer get persisted.
  static Future<SignalService> reloadFromDisk() async {
    _instance = null;
    return init();
  }

  PersistentSignalStores get stores => _stores;

  IdentityKey get publicIdentityKey => _stores.identityKeyPair.getPublicKey();

  // ── Sessions ────────────────────────────────────────────────────────────

  /// True iff we already have an established session with (peerUid, deviceId).
  Future<bool> hasSession(String peerUid, int peerDeviceId) async {
    final addr = SignalProtocolAddress(peerUid, peerDeviceId);
    return _stores.sessionStore.containsSession(addr);
  }

  /// Build a session by fetching the peer's PreKeyBundle from Firestore.
  /// Idempotent — bails out cheaply if a session already exists.
  Future<void> ensureSession(String peerUid, int peerDeviceId) {
    return _runSignalAction(() async {
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
    });
  }

  /// Tears down our session with (peerUid, peerDeviceId) so the next
  /// [encrypt] performs a fresh X3DH handshake and produces a
  /// `PreKeySignalMessage`.
  ///
  /// This is the **sender-side** recovery primitive, used when a recipient
  /// reports it could not decrypt. A prekey message is self-healing on the
  /// receiving end: `SessionBuilder.processV3` archives whatever ratchet state
  /// the receiver had before installing the new session, so it decrypts no
  /// matter how far the two chains had drifted apart.
  ///
  /// The receive path must NEVER call this. Deleting a session because a
  /// message failed to decrypt only guarantees that every message already in
  /// flight from that peer fails too — the peer doesn't know and keeps
  /// ratcheting forward from a state we just threw away.
  ///
  /// Deliberately leaves `identityStore.trustedKeys[addr]` intact. Dropping
  /// the pinned identity here would make us silently accept any substituted
  /// identity key on the next handshake. A genuine identity change is
  /// detected — and trust cleared — in [_fetchAndCacheDeviceIds], which
  /// compares the published `identityPub` against what we pinned.
  ///
  /// Does not flush; the caller is expected to `await stores.flush()` after
  /// the subsequent encrypt so the teardown and the new session persist
  /// together in one Keystore write.
  Future<void> resetSessionFor(String peerUid, int peerDeviceId) {
    return _runSignalAction(() async {
      final addr = SignalProtocolAddress(peerUid, peerDeviceId);
      await _stores.sessionStore.deleteSession(addr);
      // Drop the cached bundle too: a deliberate reset means we want the
      // handshake built from freshly fetched keys, not from a copy that may
      // be up to 10 minutes stale (or pre-date a signed-prekey rotation).
      _bundleDataCache.remove('$peerUid:$peerDeviceId');
      _stores.markDirty();
    });
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
    final signedPreKeyPub = base64Decode(bundle['signedPreKeyPub'] as String);
    final signedPreKeySig = base64Decode(bundle['signedPreKeySig'] as String);

    // Since we are establishing the session without using a one-time prekey (OPK),
    // we do not consume it on the server. This preserves the peer's OPK pool
    // for future sessions that actually require it.
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
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
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
      String peerUid, int peerDeviceId, Uint8List plaintext) {
    return _runSignalAction(() async {
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
    });
  }

  /// Decrypt from a single peer device.
  Future<Uint8List> decrypt(
      String peerUid, int peerDeviceId, EncryptedEnvelope env) {
    return _runSignalAction(() async {
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
    });
  }

  /// Fan-out encrypt for every device the recipient (and the sender's other
  /// devices, for self-sync) has registered. Returns a map keyed by
  /// "<uid>:<deviceId>" → envelope.
  /// Max devices to encrypt to per user. No real user has more than 3-4
  /// devices; entries beyond this are stale registrations from reinstalls
  /// whose keys were wiped. Encrypting to them wastes CPU, bloats the
  /// message doc (each envelope is ~500 bytes of ciphertext), and slows
  /// Firestore reads/writes for the entire conversation.
  static const _maxDevicesPerUser = 5;

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
    var recipientDevices = deviceLists[0].toList();
    final senderOtherDevices = deviceLists[1].toList()
      ..removeWhere((d) => d == senderDeviceId);

    // Never Signal-encrypt to our own posting device: it advances the session
    // ratchet at encrypt time and we'd be unable to decrypt the resulting
    // ciphertext on the same device.
    if (recipientUid == senderUid) {
      recipientDevices.removeWhere((d) => d == senderDeviceId);
    }

    // ── Safety cap: keep the N most recently active devices ─────────────
    // Stale device entries from reinstalls accumulate in Firestore. Until
    // every user's DeviceIdentityService prunes them on next registration,
    // this cap prevents the 50+ envelope bloat that makes every message doc
    // huge.
    //
    // _listDeviceIds already returns ids newest-first (see _sortByRecency),
    // so the cap is a plain head-take. It used to sort by id and keep the
    // HIGHEST, on the assumption that the latest install has the highest id —
    // the opposite of what _allocateDeviceId does. See _sortByRecency for why
    // that silently dropped fresh installs.
    if (recipientDevices.length > _maxDevicesPerUser) {
      if (kDebugMode) {
        debugPrint(
            '[E2EE] ⚠ $recipientUid has ${recipientDevices.length} devices — '
            'capping to $_maxDevicesPerUser (stale entries from reinstalls)');
      }
      recipientDevices = recipientDevices.sublist(0, _maxDevicesPerUser);
    }
    if (senderOtherDevices.length > _maxDevicesPerUser) {
      if (kDebugMode) {
        debugPrint(
            '[E2EE] ⚠ $senderUid has ${senderOtherDevices.length + 1} devices — '
            'capping other-device fan-out to $_maxDevicesPerUser');
      }
      senderOtherDevices.removeRange(
          _maxDevicesPerUser, senderOtherDevices.length);
    }

    if (kDebugMode) {
      debugPrint('[E2EE] device lookup: ${sw.elapsedMilliseconds}ms '
          '(recipient=${recipientDevices.length}, sender_other=${senderOtherDevices.length})');
    }

    // Sequential fan-out across devices with event loop yielding.
    // Since Dart is single-threaded on the main isolate, parallelizing CPU-bound
    // encryption tasks doesn't yield actual concurrency. Instead, we run them
    // sequentially and yield control to the event loop before each task using
    // Future.delayed(Duration.zero). This allows Flutter's engine to process
    // pending microtasks (stream subscriptions, frame callbacks) between
    // CPU-bound encrypts, keeping the UI responsive.
    for (final d in recipientDevices) {
      await Future.delayed(Duration.zero);
      final env = await encrypt(recipientUid, d, plaintext);
      out['$recipientUid:$d'] = env;
    }
    for (final d in senderOtherDevices) {
      await Future.delayed(Duration.zero);
      final env = await encrypt(senderUid, d, plaintext);
      out['$senderUid:$d'] = env;
    }
    if (kDebugMode)
      debugPrint('[E2EE] encryptForUser total: ${sw.elapsedMilliseconds}ms');
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
  static const _deviceIdCacheMaxSize = 200;
  static final Set<String> _deviceIdRefreshInFlight = <String>{};
  static final Map<String, Future<List<int>>> _deviceIdsQueries = {};

  /// Public wrapper around the cached device-id lookup so other services
  /// (e.g. CallEncryptionService when discovering the caller's deviceId)
  /// can reuse the same cache instead of re-querying Firestore.
  Future<List<int>> listDeviceIdsCached(String uid) => _listDeviceIds(uid);

  // Background check for peer reinstalls. Compares the peer's Firestore
  // `deviceUpdatedAt` timestamp (written by DeviceIdentityService on every
  // new device registration) against our cache age. If the peer registered
  // a new device after our cache was populated, we invalidate and force a
  // fresh query so the next message encrypts to the correct device(s).
  void _checkDeviceUpdatedAt(String uid, DateTime cacheTime) {
    // Don't re-check if we already have an in-flight refresh.
    if (_deviceIdRefreshInFlight.contains(uid)) return;
    _deviceIdRefreshInFlight.add(uid);
    () async {
      try {
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final data = userDoc.data();
        if (data != null) {
          final ts = data['deviceUpdatedAt'];
          if (ts is Timestamp) {
            final updatedAt = ts.toDate();
            if (updatedAt.isAfter(cacheTime)) {
              // Peer registered a new device AFTER our cache was built.
              // Bust the cache and fetch fresh device IDs.
              _deviceIdCache.remove(uid);
              _bundleDataCache.removeWhere((k, _) => k.startsWith('$uid:'));
              await _fetchAndCacheDeviceIds(uid);
            }
          }
        }
      } catch (_) {}
      _deviceIdRefreshInFlight.remove(uid);
    }();
  }

  /// Device ids for [uid], **ordered newest-first** (see [_sortByRecency]).
  ///
  /// That ordering is a contract, not incidental: every caller that caps the
  /// fan-out takes the head of this list. The cache is only ever populated by
  /// [_fetchAndCacheDeviceIds], which sorts before storing, so cache hits are
  /// ordered too.
  Future<List<int>> _listDeviceIds(String uid) async {
    final hit = _deviceIdCache[uid];
    if (hit != null) {
      final age = DateTime.now().difference(hit.at);
      // Stale-but-usable: return cached IDs immediately, refresh in the
      // background. The send path NEVER blocks on this query after the
      // first lookup for a peer.
      if (age > _deviceIdFreshWindow) {
        _refreshDeviceIds(uid);
      } else {
        // Cache is fresh enough by TTL, but the peer may have reinstalled.
        // Kick off a lightweight background check against the peer's
        // Firestore `deviceUpdatedAt` field. If they registered a new
        // device after our cache was built, the cache is busted for the
        // NEXT send (this send still uses the cached value — the check
        // runs in parallel and is non-blocking).
        _checkDeviceUpdatedAt(uid, hit.at);
      }
      return hit.ids;
    }
    return _fetchAndCacheDeviceIds(uid);
  }

  Future<List<int>> _fetchAndCacheDeviceIds(String uid) async {
    final existing = _deviceIdsQueries[uid];
    if (existing != null) return existing;

    final future = () async {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('devices')
            .where('keyBundle', isNull: false)
            .get();
        final ids = <int>[];
        // Publication time per device, for the newest-first ordering applied
        // once the walk finishes.
        final recency = <int, DateTime>{};

        // ── Populate bundle-data cache from the bulk query ──────────────────
        // We're already downloading every device doc (including its full
        // keyBundle data) just to discover the device IDs. Previously that
        // bundle data was thrown away, and ensureSession → _fetchPreKeyBundle
        // re-read each device doc individually (~200-500ms per read). Now we
        // cache the bundle data here so those reads become free cache hits.
        // On the send path this eliminates ~10 redundant Firestore reads.
        final now = DateTime.now();
        for (final doc in snap.docs) {
          final deviceId = int.tryParse(doc.id);
          if (deviceId == null) continue;
          ids.add(deviceId);
          final data = doc.data();
          final bundle = data['keyBundle'] as Map<String, dynamic>?;
          if (bundle != null) {
            _bundleDataCache['$uid:$deviceId'] = (at: now, bundle: bundle);
            final ts = _bundleRecency(bundle);
            if (ts != null) recency[deviceId] = ts;

            // Check if identity key changed (indicating a reinstall on the same deviceId)
            final identityPubStr = bundle['identityPub'] as String?;
            if (identityPubStr != null) {
              final addr = SignalProtocolAddress(uid, deviceId);
              final trustedKey = _stores.identityStore.trustedKeys[addr];
              if (trustedKey != null) {
                final currentPubBytes = trustedKey.serialize();
                final newPubBytes = base64Decode(identityPubStr);
                if (!listEquals(currentPubBytes, newPubBytes)) {
                  // ignore: avoid_print
                  print(
                      '[Signal] Identity key changed for $uid:$deviceId (reinstall). Wiping session.');
                  await _stores.sessionStore.deleteSession(addr);
                  _stores.identityStore.trustedKeys.remove(addr);
                  _stores.markDirty();
                }
              }
            }
          }
        }

        // ── Detect device-list changes (peer reinstall / new device) ────────
        // If any device IDs disappeared since our last fetch, the peer
        // reinstalled or rotated their identity. Delete the stale Signal
        // sessions and bundle-data cache so the next ensureSession() fetches
        // the new key bundle and does a fresh X3DH handshake instead of
        // encrypting with a dead session the receiver can never decrypt.
        final prev = _deviceIdCache[uid];
        if (prev != null) {
          final prevSet = prev.ids.toSet();
          final currSet = ids.toSet();
          final removed = prevSet.difference(currSet);
          if (removed.isNotEmpty) {
            // ignore: avoid_print
            print(
                '[Signal] device change for $uid: removed=$removed, added=${currSet.difference(prevSet)}');
            // Parallel cleanup — the previous sequential await-in-loop created
            // 27+ microtask hops that interleaved with GC pauses.
            await Future.wait(removed.map((d) async {
              try {
                await _stores.sessionStore.deleteSession(
                  SignalProtocolAddress(uid, d),
                );
              } catch (_) {}
              _bundleDataCache.remove('$uid:$d');
            }));
            // Also clear bundle cache for any new devices so we fetch fresh bundles
            for (final d in currSet.difference(prevSet)) {
              _bundleDataCache.remove('$uid:$d');
            }
            _stores.markDirty();
          }
        }

        _sortByRecency(ids, recency);
        _deviceIdCache[uid] = (at: now, ids: ids);
        // LRU eviction: cap cache size to prevent unbounded growth
        // for users who message hundreds of unique peers.
        if (_deviceIdCache.length > _deviceIdCacheMaxSize) {
          final keysToRemove = _deviceIdCache.keys.take(50).toList();
          for (final k in keysToRemove) {
            _deviceIdCache.remove(k);
          }
        }
        return ids;
      } finally {
        _deviceIdsQueries.remove(uid);
      }
    }();

    _deviceIdsQueries[uid] = future;
    return future;
  }

  /// Newest key-material timestamp a device has published: its registration
  /// (`createdAt`) or its last signed-prekey rotation (`rotatedAt`), both
  /// written by DeviceIdentityService. Null for devices registered before
  /// either field existed.
  static DateTime? _bundleRecency(Map<String, dynamic> bundle) {
    DateTime? best;
    for (final field in const ['createdAt', 'rotatedAt']) {
      final v = bundle[field];
      if (v is Timestamp) {
        final d = v.toDate();
        if (best == null || d.isAfter(best)) best = d;
      }
    }
    return best;
  }

  /// Orders device ids newest-first, so anything that has to cap the list
  /// keeps the devices most likely to be alive.
  ///
  /// The cap used to rank by device id and keep the highest, on the stated
  /// assumption that the newest install always has the highest id. But
  /// `DeviceIdentityService._allocateDeviceId` hands out the *smallest unused*
  /// id — so after a reinstall left a gap, the fresh install took a LOW id and
  /// a highest-wins cap discarded it in favour of the dead registrations above
  /// it. Peers then encrypted only to devices that no longer exist: the live
  /// device received no envelope of its own, which surfaces as a permanent
  /// undecryptable bubble with no error for the retry path to act on.
  ///
  /// `rotatedAt` is what makes this a liveness signal rather than an install
  /// clock — the signed prekey rotates weekly, so an active device keeps
  /// refreshing its timestamp while an uninstalled one freezes in the past.
  ///
  /// Devices with no timestamp sort last, highest id first. That is the old
  /// heuristic, kept only as a tiebreak among entries where we know nothing
  /// better; a device that has published a timestamp always outranks one that
  /// hasn't.
  static void _sortByRecency(List<int> ids, Map<int, DateTime> recency) {
    ids.sort((a, b) {
      final ra = recency[a];
      final rb = recency[b];
      if (ra != null && rb != null) {
        final byTime = rb.compareTo(ra);
        return byTime != 0 ? byTime : b.compareTo(a);
      }
      if (ra != null) return -1;
      if (rb != null) return 1;
      return b.compareTo(a);
    });
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
  static void invalidateDeviceCache(String uid) => _deviceIdCache.remove(uid);

  /// Trigger a non-blocking background refresh of the device-id cache for
  /// [uid]. Unlike [invalidateDeviceCache] (which wipes the cache and forces
  /// the next lookup to block on Firestore), this keeps the cached data
  /// available for immediate use while fetching fresh data in the background.
  /// When the refresh completes, [_fetchAndCacheDeviceIds] auto-detects
  /// device-list changes and cleans up stale sessions / bundle caches.
  ///
  /// Call from chat screen open so that if the peer reinstalled, we detect
  /// the change within seconds rather than waiting for the 5-min
  /// stale-while-revalidate window.
  static void refreshDeviceCache(String uid) {
    if (_instance == null) return; // Signal not initialized yet
    _instance!._refreshDeviceIds(uid);
  }

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
  // Memoized prewarm futures so the send path can join an in-flight
  // prewarm instead of starting redundant Firestore queries. Without this,
  // prewarmSessions from initState and _commitMessage race: the user sends
  // before prewarm completes, and the send path repeats all the same work.
  static final Map<String, Future<void>> _prewarmFutures = {};

  Future<void> prewarmSessions(List<String> peerUids) async {
    if (peerUids.isEmpty) return;
    await Future.wait(peerUids.map((uid) {
      return _prewarmFutures.putIfAbsent(uid, () => _prewarmSingle(uid));
    }));
  }

  Future<void> _prewarmSingle(String uid) async {
    try {
      final devices = await _listDeviceIds(uid);

      // If we are prewarming our own device list, we only need to fetch the device list
      // (which _listDeviceIds above did) to populate _deviceIdCache[uid].
      // We can skip ensureSession because we don't build sessions with our own devices.
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == currentUid) return;

      // Apply the same cap as encryptForUser so we don't build sessions
      // for stale devices that will never be used. Already newest-first out
      // of _listDeviceIds, so this is a head-take.
      var capped = devices.toList();
      if (capped.length > _maxDevicesPerUser) {
        capped = capped.sublist(0, _maxDevicesPerUser);
      }
      for (final d in capped) {
        await Future.delayed(Duration.zero);
        try {
          await ensureSession(uid, d);
        } catch (_) {}
      }
    } catch (_) {
    } finally {
      _prewarmFutures.remove(uid);
    }
  }

  /// Await any in-flight prewarm for [peerUid] so the send path
  /// piggybacks on work already running rather than duplicating it.
  /// Returns immediately if no prewarm is running.
  Future<void> awaitPrewarm(String peerUid) async {
    final f = _prewarmFutures[peerUid];
    if (f != null) await f;
  }

  /// Warms the consumeOneTimePreKey Cloud Function's container so the
  /// background OTPK consumption after session setup doesn't pay the
  /// cold-start penalty. Uses a real POST (HEAD/OPTIONS don't trigger
  /// container boot in Firebase Functions v2). Best-effort, silent on
  /// failure.
  static Future<void> warmConsumeOneTimePreKey() async {
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
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
