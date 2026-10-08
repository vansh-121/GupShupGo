import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:video_chat_app/models/status_model.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/services/crypto/device_identity_service.dart';
import 'package:video_chat_app/services/crypto/encrypted_media_service.dart';
import 'package:video_chat_app/services/crypto/plaintext_store.dart';
import 'package:video_chat_app/services/crypto/signal_service.dart';
import 'package:video_chat_app/services/crypto/vault_cipher.dart';
import 'package:video_chat_app/services/image_compressor.dart';
import 'package:video_chat_app/services/performance_service.dart';
import 'package:video_chat_app/services/subscription_service.dart';
import 'package:video_chat_app/services/gamification_service.dart';

/// Decrypted form of an encrypted status item, kept in the process-wide
/// cache below so the viewer can render instantly when the user taps a
/// status. WhatsApp's UX guarantee is "no spinners on status open" — that
/// only works if the work happens *before* the user taps.
class StatusPlaintext {
  StatusPlaintext.text({required this.text, required this.backgroundColor})
      : localFile = null,
        bytes = null,
        isVideo = false;
  StatusPlaintext.media({
    required File this.localFile,
    required Uint8List this.bytes,
    required this.isVideo,
  })  : text = null,
        backgroundColor = null;

  final String? text;
  final String? backgroundColor;
  final File? localFile;
  final Uint8List? bytes;
  final bool isVideo;
}

class StatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final EncryptedMediaService _media = EncryptedMediaService();
  final DeviceIdentityService _deviceIdentity = DeviceIdentityService();
  final String _statusCollection = 'statuses';

  // Process-wide cache of decrypted status items, populated as soon as
  // the status list streams emit. The viewer reads from here on open —
  // there is no on-demand decryption while a UI screen is visible.
  static final Map<String, StatusPlaintext> _plaintextCache = {};
  // AES content keys for media statuses, keyed by statusItemId.
  // Populated by _preWarmStatusCache from statusVault and by _fetchWrappedKey
  // on first successful decrypt. Allows media to re-download from Storage on
  // reinstall without needing the Signal session to unwrap the key again.
  static final Map<String, Uint8List> _mediaKeyCache = {};
  // Dedupe in-flight pre-decrypts so multiple stream emissions don't fire
  // overlapping decrypt jobs for the same status item.
  static final Map<String, Future<void>> _inFlight = {};
  // Items that can never be decrypted on this install (no AES key in vault,
  // Signal session gone). Hidden from the viewer — same as WhatsApp, which
  // silently drops statuses it can't recover after reinstall.
  static final Set<String> _unrecoverable = {};

  // A freshly-posted status is NOT unrecoverable just because the first
  // decrypt attempt missed. The wrappedKey envelope, the first-time Signal
  // handshake with the poster's device, and the Storage blob all propagate to
  // the viewer independently and can lag the status doc by a few seconds. If
  // we blacklisted on that first miss, the viewer would filter the item out
  // and render "No active status" permanently — even though the key arrives a
  // moment later. So we only give up (and hide the item) once the item is
  // older than this grace window, by which point a genuine reinstall ghost is
  // the only thing that still can't be decrypted. The window is generous
  // enough to absorb clock skew between poster and viewer.
  static const _unrecoverableGrace = Duration(minutes: 15);

  /// Ceiling on how long a viewer waits on a single shared decrypt attempt.
  /// Belt-and-suspenders beyond EncryptedMediaService's download timeout: if the
  /// underlying future wedges for any other reason (e.g. a stuck per-address
  /// Signal lock), the viewer's retry loop must still advance to "tap to retry"
  /// instead of spinning forever. Slightly longer than the download timeout so a
  /// legitimately slow download isn't cut off early.
  static const _decryptWaitCeiling = Duration(seconds: 25);

  /// Mark [item] permanently undecryptable on this install — but only if it is
  /// old enough that a transient propagation / handshake lag can be ruled out.
  /// A recent item is left untouched so the next stream emission or the
  /// viewer's own retry loop can recover it once the key lands.
  static void _giveUpIfStale(StatusItem item) {
    if (DateTime.now().difference(item.createdAt) > _unrecoverableGrace) {
      _unrecoverable.add(item.id);
    }
  }

  static StatusPlaintext? cachedPlaintext(String statusItemId) =>
      _plaintextCache[statusItemId];

  static bool isUnrecoverable(String statusItemId) =>
      _unrecoverable.contains(statusItemId);

  // ─── Status vault (cross-install backup for text statuses) ───────────────
  // Text status plaintext is mirrored to users/{selfUid}/statusVault/{itemId}
  // so it survives reinstall (Signal session wiped → _fetchWrappedKey fails,
  // but vault still has the plaintext). Media statuses are not vaulted —
  // the blobs are too large for Firestore; disk cache covers restarts.
  static const _statusVaultCollection = 'statusVault';

  // Memoised per-uid vault pre-warm — one Firestore collection read at startup
  // instead of per-item misses during decryption.
  static final Map<String, Future<void>> _statusPreWarmCache = {};

  Future<void> _preWarmStatusCache(String selfUid) {
    return _statusPreWarmCache.putIfAbsent(
        selfUid, () => _doPreWarmStatus(selfUid));
  }

  /// Drop the per-uid pre-warm AND the process-wide plaintext / media-key
  /// caches so the next status open re-decrypts from the vault. Called
  /// after VaultCipher unlocks and after VaultCipher.reset.
  static void invalidatePreWarm(String uid) {
    _statusPreWarmCache.remove(uid);
    _plaintextCache.clear();
    _mediaKeyCache.clear();
    _diskPreWarmed = false;
  }

  /// Eagerly populates [_plaintextCache] from the local SQLite store so
  /// previously-seen statuses render on the first frame after app launch,
  /// without waiting for any Firestore query. Text items are pure data
  /// (no file I/O), so this is a single fast SQLite scan.
  static bool _diskPreWarmed = false;

  Future<void> preWarmFromDisk() async {
    if (_diskPreWarmed) return;
    _diskPreWarmed = true;
    try {
      final ps = await PlaintextStore.instance();
      // PlaintextStore uses 'status_content:<itemId>' keys for status items.
      // getAllMessagePayloads excludes status_* rows, so we need a direct query.
      // Reuse getStatusContent per known-cached id? No — we don't know the ids
      // ahead of time. Instead, do a lightweight bulk read of all status_content
      // rows via a new helper.
      final entries = await ps.getAllStatusContents();
      for (final e in entries.entries) {
        if (_plaintextCache.containsKey(e.key)) continue;
        final data = e.value;
        if (data['t'] == 'text') {
          _plaintextCache[e.key] = StatusPlaintext.text(
            text: (data['tx'] as String?) ?? '',
            backgroundColor: (data['bg'] as String?) ?? '#6C5CE7',
          );
        }
        // Media items need file I/O — skip for instant first-frame rendering.
        // They'll be hydrated by _preDecryptOne's disk-cache path on demand.
      }
    } catch (_) {}
  }

  Future<void> _doPreWarmStatus(String selfUid) async {
    // Vault payloads are E2EE — without the unlocked key we can't read them.
    if (!VaultCipher.instance.isReady) return;
    try {
      final snap = await _firestore
          .collection('users')
          .doc(selfUid)
          .collection(_statusVaultCollection)
          .get();

      // Partition docs into text (decrypt to JSON) and media-key (decrypt
      // to bytes), skipping anything already cached. Both batches run on a
      // background isolate via compute() so the main thread stays free.
      final textDocs = <String, Map<String, dynamic>>{};
      final keyDocs = <String, Map<String, dynamic>>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final type = data['t'] as String?;
        if (type == 'text' && !_plaintextCache.containsKey(doc.id)) {
          textDocs[doc.id] = data;
        } else if (type == 'media_key' &&
            !_mediaKeyCache.containsKey(doc.id)) {
          keyDocs[doc.id] = data;
        }
      }

      // Decrypt text + media-key batches in parallel on isolates.
      final results = await Future.wait([
        textDocs.isEmpty
            ? Future.value(<String, Map<String, dynamic>>{})
            : VaultCipher.instance.decryptDocsBatch(textDocs),
        keyDocs.isEmpty
            ? Future.value(<String, Uint8List>{})
            : VaultCipher.instance.decryptBytesBatch(keyDocs),
      ]);

      final textResults = results[0] as Map<String, Map<String, dynamic>>;
      final keyResults = results[1] as Map<String, Uint8List>;

      for (final e in textResults.entries) {
        _plaintextCache[e.key] = StatusPlaintext.text(
          text: (e.value['tx'] as String?) ?? '',
          backgroundColor: (e.value['bg'] as String?) ?? '#6C5CE7',
        );
      }
      _mediaKeyCache.addAll(keyResults);
    } catch (_) {}
  }

  Future<void> _saveTextStatusToVault(
      String selfUid, String itemId, String text, String bg) async {
    final enc =
        await VaultCipher.instance.encryptPayload({'tx': text, 'bg': bg});
    if (enc == null) return; // vault locked — skip rather than leak plaintext
    try {
      await _firestore
          .collection('users')
          .doc(selfUid)
          .collection(_statusVaultCollection)
          .doc(itemId)
          .set({
        't': 'text',
        ...enc,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> _saveMediaKeyToVault(
      String selfUid, String itemId, Uint8List key) async {
    final enc = await VaultCipher.instance.encryptBytes(key);
    if (enc == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(selfUid)
          .collection(_statusVaultCollection)
          .doc(itemId)
          .set({
        't': 'media_key',
        ...enc,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Background pre-decrypt for every encrypted item in [models]. Safe to
  /// call repeatedly from a stream listener — already-decrypted items and
  /// already-in-flight items are skipped. Fire-and-forget from the caller's
  /// perspective; never throws.
  ///
  /// Text items (vault-only, no network) run unbounded in parallel. Media
  /// items (require HTTP download from Storage) run with bounded concurrency
  /// of [_maxConcurrentMediaDownloads] to avoid saturating the connection.
  static const _maxConcurrentMediaDownloads = 3;

  Future<void> preDecryptStatuses(
      List<StatusModel> models, String selfUid) async {
    // Bulk-load the text status vault into _plaintextCache so items that
    // were seen on a previous install (Signal session lost) still render.
    await _preWarmStatusCache(selfUid);

    final textTasks = <Future<void>>[];
    final mediaItems = <(String, StatusItem)>[]; // (ownerUid, item)
    for (final m in models) {
      for (final item in m.activeStatusItems) {
        if (!item.type.startsWith('encrypted')) continue;
        if (_plaintextCache.containsKey(item.id)) continue;
        if (item.type == 'encrypted') {
          // Text items: vault-only decrypt, no network — run unbounded.
          final existing = _inFlight[item.id];
          if (existing != null) {
            textTasks.add(existing);
            continue;
          }
          final future = _preDecryptOne(m.userId, item, selfUid)
              .whenComplete(() => _inFlight.remove(item.id));
          _inFlight[item.id] = future;
          textTasks.add(future);
        } else {
          // Media items: collect for bounded-concurrency download.
          if (!_inFlight.containsKey(item.id)) {
            mediaItems.add((m.userId, item));
          }
        }
      }
    }

    // Fire text decrypts in parallel (fast, CPU-only).
    if (textTasks.isNotEmpty) await Future.wait(textTasks);

    // Media downloads: bounded concurrency to avoid saturating the link.
    if (mediaItems.isNotEmpty) {
      var active = 0;
      final completer = Completer<void>();
      final queue = List<(String, StatusItem)>.of(mediaItems);
      var completed = 0;

      void scheduleNext() {
        while (active < _maxConcurrentMediaDownloads && queue.isNotEmpty) {
          final (ownerUid, item) = queue.removeAt(0);
          active++;
          final future = _preDecryptOne(ownerUid, item, selfUid)
              .whenComplete(() => _inFlight.remove(item.id));
          _inFlight[item.id] = future;
          future.whenComplete(() {
            active--;
            completed++;
            if (completed == mediaItems.length) {
              completer.complete();
            } else {
              scheduleNext();
            }
          });
        }
      }

      scheduleNext();
      await completer.future;
    }
  }

  /// Public entry point for one-off decryption (from the viewer screen).
  /// Goes through the same disk-cache → network → persist pipeline as the
  /// background pre-decrypt, with the same in-flight deduping so two
  /// callers don't kick off overlapping work for the same item.
  Future<void> ensureDecrypted({
    required String ownerUid,
    required StatusItem item,
    required String selfUid,
  }) async {
    if (!item.type.startsWith('encrypted')) return;
    if (_plaintextCache.containsKey(item.id)) return;
    final existing = _inFlight[item.id];
    if (existing != null) {
      // Bounded wait — see [_decryptWaitCeiling]. On timeout we return normally
      // so the caller re-checks the cache and retries or gives up, never hangs.
      await existing.timeout(_decryptWaitCeiling, onTimeout: () {});
      return;
    }
    final fut = _preDecryptOne(ownerUid, item, selfUid)
        .whenComplete(() => _inFlight.remove(item.id));
    _inFlight[item.id] = fut;
    await fut.timeout(_decryptWaitCeiling, onTimeout: () {});
  }

  Future<void> _preDecryptOne(
      String ownerUid, StatusItem item, String selfUid) async {
    final ps = await PlaintextStore.instance();

    // Disk cache hit: hydrate the in-memory cache from previously-decrypted
    // content and skip the network round-trip entirely. This is the path
    // that powers "status playable after app restart / offline" — the
    // same guarantee WhatsApp gives.
    try {
      final disk = await ps.getStatusContent(item.id);
      if (disk != null) {
        if (disk['t'] == 'text') {
          _plaintextCache[item.id] = StatusPlaintext.text(
            text: (disk['tx'] as String?) ?? '',
            backgroundColor: (disk['bg'] as String?) ?? '#6C5CE7',
          );
          return;
        }
        final path = disk['mp'] as String?;
        if (path != null) {
          // Skip the redundant File.exists() syscall — the path came from
          // our own SQLite store. Try reading directly; if the file was
          // deleted by the OS we catch the exception and fall through to
          // the network re-download path.
          try {
            final file = File(path);
            final isVideo = (disk['v'] as bool?) ?? false;
            final bytes = isVideo ? Uint8List(0) : await file.readAsBytes();
            _plaintextCache[item.id] = StatusPlaintext.media(
              localFile: file,
              bytes: bytes,
              isVideo: isVideo,
            );
            return;
          } catch (_) {
            // File gone (OS cache clear, etc.) — fall through to network.
          }
        }
      }
    } catch (_) {
      // Fall through to network decrypt.
    }

    try {
      final result = await decryptStatusItem(
        ownerUid: ownerUid,
        item: item,
        selfUid: selfUid,
        // Pass the vault-restored AES key so media statuses can re-download
        // from Storage on reinstall without needing the Signal session.
        preloadedKey: _mediaKeyCache[item.id],
      );
      if (result == null) {
        // No AES key available yet. Could be a reinstall ghost (vault empty,
        // Signal session gone) OR a freshly-posted status whose envelope has
        // not reached this device yet. Only the former is permanent — see
        // [_giveUpIfStale]. A recent item is left uncached and retryable.
        _giveUpIfStale(item);
        return;
      }
      if (item.type == 'encrypted') {
        final j = result['json'] as Map<String, dynamic>;
        final text = (j['text'] as String?) ?? '';
        final bg = (j['backgroundColor'] as String?) ?? '#6C5CE7';
        _plaintextCache[item.id] =
            StatusPlaintext.text(text: text, backgroundColor: bg);
        await ps.saveStatusContent(
          itemId: item.id,
          type: 'text',
          text: text,
          backgroundColor: bg,
        );
        // Mirror to Firestore vault so text statuses survive reinstall.
        unawaited(_saveTextStatusToVault(selfUid, item.id, text, bg));
      } else {
        final bytes = result['bytes'] as Uint8List;
        final isVideo = item.type == 'encrypted_video';
        final ext = isVideo ? 'mp4' : 'jpg';
        // Persistent dir, not systemTemp — the OS wipes the latter at will.
        final mediaDir = await ps.mediaCacheDir();
        final filePath = '$mediaDir/dec_${item.id}.$ext';
        final file = await File(filePath).writeAsBytes(bytes, flush: true);
        _plaintextCache[item.id] = StatusPlaintext.media(
          localFile: file,
          bytes: bytes,
          isVideo: isVideo,
        );
        await ps.saveStatusContent(
          itemId: item.id,
          type: 'media',
          mediaPath: filePath,
          isVideo: isVideo,
        );
      }
    } catch (_) {
      // A decrypt that threw (Storage read blip, transient handshake failure)
      // is transient by nature, so it must NOT be made terminal: a brief
      // download/connection error would otherwise drop a perfectly valid status
      // into [_unrecoverable] and the viewer would filter it out for the rest of
      // the session. Leave the item uncached and retryable — the next stream
      // emission or the viewer's own retry re-attempts it. Only the genuine
      // "no key anywhere" path above (result == null) ages into unrecoverable.
    }
  }

  // ── E2EE status: wrap a per-status content key for each authorised viewer.
  //
  // Status posts go to multiple viewers, so per-recipient SessionCipher would
  // re-encrypt the same blob N times. Instead:
  //   1. Generate a random AES-256 content key K.
  //   2. Encrypt the blob (text bytes, image/video file) under K via
  //      EncryptedMediaService.
  //   3. For each viewer device, Signal-encrypt K and write under
  //      statuses/{owner}/wrappedKeys/{statusItemId}/{viewerUid:deviceId}.
  //
  // To rotate the viewer set (someone added/removed from contacts), we add
  // or remove the wrappedKey doc — the blob never changes.

  /// Wraps the content key for every viewer's every device. The owner is
  /// All viewers run in parallel, but concurrency is capped so we don't
  /// fire 50+ simultaneous `encryptForUser` calls — each of which does
  /// sequential multi-device Signal encrypts. Capping at 5 keeps CPU
  /// usage bounded without meaningfully slowing down the fan-out.
  static const int _maxConcurrentEncrypts = 5;

  Future<void> _publishWrappedKeys({
    required String ownerUid,
    required int ownerDeviceId,
    required String statusItemId,
    required Uint8List contentKey,
    required List<String> viewerUids,
  }) async {
    final fanout = <String>{...viewerUids, ownerUid}.toList();

    // Record the intended viewer set locally (owner-only, never uploaded) so
    // the key-heal path can authorise a viewer whose content-key wrap fails for
    // every one of their devices below — leaving them with no envelope to prove
    // they were ever an audience member. See [_serveKeyRequest]. Best-effort:
    // the post must not fail if this local write does.
    try {
      await (await PlaintextStore.instance())
          .saveStatusAudience(statusItemId, viewerUids);
    } catch (_) {}

    // Simple fixed-concurrency executor — runs at most [_maxConcurrentEncrypts]
    // viewers in parallel, starts the next as soon as one finishes.
    final semaphore = _Semaphore(_maxConcurrentEncrypts);

    await Future.wait(fanout.map((viewerUid) => semaphore.run(() async {
      final encs = await SignalService.instance.encryptForUser(
        senderUid: ownerUid,
        senderDeviceId: ownerDeviceId,
        recipientUid: viewerUid,
        plaintext: contentKey,
      );
      if (encs.isEmpty) return;
      final batch = _firestore.batch();
      encs.forEach((addr, env) {
        batch.set(
          _firestore
              .collection(_statusCollection)
              .doc(ownerUid)
              .collection('wrappedKeys')
              .doc(statusItemId)
              .collection('envelopes')
              .doc(addr),
          env.toMap(),
        );
      });
      await batch.commit();
    })));
  }

  /// Fetches and decrypts the content key for a status item this device is
  /// authorised to view. Returns null if no envelope is addressed to us.
  ///
  /// [ownerDeviceId] is required: the status owner's deviceId stored in the
  /// status item's metadata. Different devices of the same owner have
  /// separate Signal sessions, so we must use the right one or decryption
  /// silently fails.
  Future<Uint8List?> _fetchWrappedKey({
    required String ownerUid,
    required int ownerDeviceId,
    required String statusItemId,
    required String selfUid,
  }) async {
    final deviceId = await _deviceIdentity.getDeviceId();
    if (deviceId == null) return null;
    final addr = '$selfUid:$deviceId';
    final doc = await _firestore
        .collection(_statusCollection)
        .doc(ownerUid)
        .collection('wrappedKeys')
        .doc(statusItemId)
        .collection('envelopes')
        .doc(addr)
        .get();
    if (!doc.exists) {
      // No envelope for this device. The owner fanned out before this install
      // existed (reinstall → new device id) or the encrypt to us failed. Ask
      // the owner to re-wrap the content key for this device; their app serves
      // it via [startServingKeyRequests]. Without this a dropped envelope was
      // terminal — the status spun, then "tap to retry" against the same
      // missing doc, forever.
      unawaited(_requestStatusKey(
        ownerUid: ownerUid,
        ownerDeviceId: ownerDeviceId,
        statusItemId: statusItemId,
        selfUid: selfUid,
        selfDeviceId: deviceId,
      ));
      return null;
    }
    final env = EncryptedEnvelope.fromMap(doc.data()!);
    try {
      final key = await SignalService.instance
          .decrypt(ownerUid, ownerDeviceId, env);
      // Mirror AES key to vault so future reinstalls can re-download the
      // blob from Storage without needing the Signal session.
      _mediaKeyCache[statusItemId] = key;
      unawaited(_saveMediaKeyToVault(selfUid, statusItemId, key));
      return key;
    } catch (_) {
      return null;
    }
  }

  // ── Status key heal (viewer-missing-key → owner re-wraps) ────────────────
  // Mirrors ChatService's resend protocol for the per-viewer wrapped AES key.
  // Before this, a viewer whose live device never received an envelope had no
  // way to recover: the status spun, then showed "tap to retry" against the
  // same missing doc forever. Now the viewer asks and the owner re-wraps.
  static const _keyRequestsCollection = 'keyRequests';

  /// Items we have already asked for this session, so repeated viewer retries
  /// don't rewrite the (write-once) request doc on every tick.
  static final Set<String> _requestedKeys = <String>{};

  /// Owner-side listener subscription + the uid it is bound to. Static so a
  /// recreated StatusService / provider can't leak a second listener.
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _keyReqSub;
  static String? _keyReqOwner;

  /// Viewer side: ask [ownerUid] to re-wrap the content key for [statusItemId]
  /// for this device. Deterministic id so one device mints at most one pending
  /// request per item. Fire-and-forget; the owner serves asynchronously.
  Future<void> _requestStatusKey({
    required String ownerUid,
    required int ownerDeviceId,
    required String statusItemId,
    required String selfUid,
    required int selfDeviceId,
  }) async {
    if (ownerUid.isEmpty || ownerUid == selfUid) return;
    if (!_requestedKeys.add(statusItemId)) return; // already asked this session
    try {
      final reqId = '${statusItemId}__$selfUid:$selfDeviceId';
      await _firestore
          .collection(_statusCollection)
          .doc(ownerUid)
          .collection(_keyRequestsCollection)
          .doc(reqId)
          .set({
        'itemId': statusItemId,
        'ownerDeviceId': ownerDeviceId,
        'requesterUid': selfUid,
        'requesterDeviceId': selfDeviceId,
        'at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // A pending request may still exist (write-once rule denies the update);
      // harmless. Forget the dedupe entry so a later session can retry.
      _requestedKeys.remove(statusItemId);
      if (kDebugMode) debugPrint('[Status] key request failed: $e');
    }
  }

  /// Owner side: start serving wrapped-key re-wrap requests for [ownerUid].
  /// Idempotent; rebinds if the signed-in user changes. Called from
  /// StatusProvider.initialize so it runs for the whole session, the way the
  /// chat resend listener does.
  void startServingKeyRequests(String ownerUid) {
    if (ownerUid.isEmpty) return;
    if (_keyReqOwner == ownerUid && _keyReqSub != null) return;
    _keyReqSub?.cancel();
    _keyReqOwner = ownerUid;
    _keyReqSub = _firestore
        .collection(_statusCollection)
        .doc(ownerUid)
        .collection(_keyRequestsCollection)
        .snapshots()
        .listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.removed) continue;
        final data = change.doc.data();
        if (data != null) {
          unawaited(_serveKeyRequest(ownerUid, change.doc.id, data));
        }
      }
    }, onError: (e) {
      if (kDebugMode) debugPrint('[Status] keyRequests listen error: $e');
    });
  }

  /// Stop serving (sign-out). Clears the binding so a later sign-in rebinds.
  void stopServingKeyRequests() {
    _keyReqSub?.cancel();
    _keyReqSub = null;
    _keyReqOwner = null;
  }

  Future<void> _serveKeyRequest(
      String ownerUid, String reqId, Map<String, dynamic> data) async {
    final itemId = data['itemId'] as String?;
    final requesterUid = data['requesterUid'] as String?;
    final requesterDeviceId = data['requesterDeviceId'] as int?;
    final reqRef = _firestore
        .collection(_statusCollection)
        .doc(ownerUid)
        .collection(_keyRequestsCollection)
        .doc(reqId);
    if (itemId == null || requesterUid == null || requesterDeviceId == null) {
      try {
        await reqRef.delete();
      } catch (_) {}
      return;
    }
    try {
      // The owner decrypts its own statuses locally (vault / getStatusKey), so
      // it never needs an envelope re-wrapped to itself.
      if (requesterUid == ownerUid) {
        await reqRef.delete();
        return;
      }

      // Only the owner device that actually POSTED this status may serve. The
      // viewer decrypts the envelope against the (ownerUid, ownerDeviceId) from
      // the status metadata, and libsignal sessions are keyed by that address
      // and SHARED with chat — so a different owner device re-wrapping here
      // would pin its own identity under the posting device's address and
      // corrupt that session. A non-matching device returns WITHOUT deleting,
      // so the right device still serves the request when it next sees it.
      final ownerDeviceId = data['ownerDeviceId'] as int?;
      final myDeviceId = await _deviceIdentity.getDeviceId();
      if (ownerDeviceId == null ||
          myDeviceId == null ||
          ownerDeviceId != myDeviceId) {
        return;
      }

      // AUTHORIZATION: only re-wrap for a uid that ALREADY held an envelope for
      // this item. The envelope set IS the authorized-viewer set, so a stranger
      // who writes a request can never obtain a key they were not already
      // granted on a previous device. A reinstalled viewer keeps their old
      // device's envelope on the item, so their uid still matches here.
      final envelopes = _firestore
          .collection(_statusCollection)
          .doc(ownerUid)
          .collection('wrappedKeys')
          .doc(itemId)
          .collection('envelopes');
      final prior = await envelopes
          .where(FieldPath.documentId,
              isGreaterThanOrEqualTo: '$requesterUid:',
              isLessThan: '$requesterUid:')
          .limit(1)
          .get();
      if (prior.docs.isEmpty) {
        // No envelope was ever delivered to this uid. Usually that is a
        // stranger who merely wrote a request — but it is also the one
        // legitimate case the envelope-as-audience check cannot see: a viewer
        // the owner DID post to whose content-key wrap failed for every one of
        // their devices at post time (encryptForUser returned empty), so no
        // envelope was ever written for them. Consult the owner's local record
        // of the intended audience (saved in _publishWrappedKeys, never
        // uploaded) to tell them apart. A uid the owner never shared with — the
        // stranger — is still refused and cleared exactly as before.
        final audience =
            await (await PlaintextStore.instance()).getStatusAudience(itemId);
        if (audience == null || !audience.contains(requesterUid)) {
          await reqRef.delete();
          return;
        }
        // Authorised viewer whose first delivery failed: fall through and
        // re-wrap a fresh envelope for their current device.
      }

      // Recover the content key K. The owner holds it locally (saveStatusKey on
      // post) and/or in the status vault (reinstall-safe, pre-warmed into
      // _mediaKeyCache). If it is genuinely gone, drop the request so it does
      // not pile up — the viewer gives up as stale after the grace window.
      Uint8List? key = _mediaKeyCache[itemId];
      key ??= await (await PlaintextStore.instance()).getStatusKey(itemId);
      if (key == null) {
        await reqRef.delete();
        return;
      }

      // Re-wrap K for the requester's CURRENT device over a fresh session, so a
      // reinstalled viewer (new identity / device id) can decrypt it.
      SignalService.invalidateDeviceCache(requesterUid);
      final env = await SignalService.instance
          .encryptWithFreshSession(requesterUid, requesterDeviceId, key);
      await envelopes.doc('$requesterUid:$requesterDeviceId').set(env.toMap());
      await reqRef.delete();
      if (kDebugMode) {
        debugPrint('[Status] re-wrapped key for $itemId → '
            '$requesterUid:$requesterDeviceId');
      }
    } catch (e) {
      // Leave the request in place for a retry on the next app start (the
      // initial snapshot re-delivers it). Do NOT delete on failure.
      if (kDebugMode) debugPrint('[Status] serve key $reqId failed: $e');
    }
  }

  /// Compute the default viewer set: every other user with whom this user has
  /// an active chat room. The pragmatic "who can see my status" cohort —
  /// matches how most people actually share status updates without exposing
  /// every signed-in user on the platform.
  Future<List<String>> defaultViewerUids(String selfUid) async {
    final snap = await _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: selfUid)
        .get();
    final peers = <String>{};
    for (final d in snap.docs) {
      final parts = List<String>.from(d.data()['participants'] ?? const []);
      for (final p in parts) {
        if (p != selfUid) peers.add(p);
      }
    }
    return peers.toList();
  }

  /// Generates a fresh Firestore id for a status item. Exposed so the provider
  /// can mint the id up front for an optimistic placeholder and hand the SAME
  /// id to the matching upload call — keeping the placeholder and the
  /// server-echoed item on one id so the UI never shows a transient duplicate.
  String newStatusItemId() =>
      _firestore.collection(_statusCollection).doc().id;

  /// Encrypted text status. The text body is encrypted under a per-item
  /// content key; the content key is wrapped per viewer device.
  ///
  /// `viewerUids` is the contact list the user wants to share with
  /// (status privacy — caller is responsible for filtering).
  Future<void> uploadEncryptedTextStatus({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    String? userPhoneNumber,
    required String text,
    required String backgroundColor,
    required List<String> viewerUids,
    String? itemId,
  }) async {
    final ownerDeviceId = await _deviceIdentity.getDeviceId();
    if (ownerDeviceId == null) {
      throw StateError('E2EE not registered — cannot post encrypted status');
    }
    final statusItemId =
        itemId ?? _firestore.collection(_statusCollection).doc().id;

    // Text is tiny, so the ciphertext rides INLINE in the status item instead
    // of a Storage blob. A viewer then decrypts after only the Signal key
    // unwrap — no second HTTP round-trip to Storage, which is what made text
    // statuses slow to open. (Image/video stay Storage-backed; their blobs are
    // far too large for a Firestore document.)
    final sealed = await _media.sealInline(
      Uint8List.fromList(utf8.encode(jsonEncode({
        'type': 'text',
        'text': text,
        'backgroundColor': backgroundColor,
      }))),
    );

    final statusItem = StatusItem(
      id: statusItemId,
      type: 'encrypted',
      text: null,
      createdAt: DateTime.now(),
      viewedBy: [],
      // No Storage object for inline text — the ciphertext is in `caption`.
      imageUrl: null,
      caption: jsonEncode({
        'enc': true,
        'inline': true,
        'iv': base64Encode(sealed.iv),
        'ct': base64Encode(sealed.wire),
        'ownerDeviceId': ownerDeviceId,
      }),
    );

    // Cache the content key locally so this (posting) device can decrypt
    // its own status without a Signal-to-self envelope.
    final ps = await PlaintextStore.instance();
    final ownerKey = sealed.key;
    await ps.saveStatusKey(statusItemId, ownerKey);
    _mediaKeyCache[statusItemId] = ownerKey;
    unawaited(_saveMediaKeyToVault(userId, statusItemId, ownerKey));

    // Order matters: publish wrapped keys BEFORE the status item doc.
    // The status list stream fires as soon as the item doc lands; if the
    // viewer opens it before their envelope exists, `_fetchWrappedKey`
    // returns null and the viewer is stuck on "Decrypting…" with no retry.
    await _publishWrappedKeys(
      ownerUid: userId,
      ownerDeviceId: ownerDeviceId,
      statusItemId: statusItemId,
      contentKey: sealed.key,
      viewerUids: viewerUids,
    );
    await _addStatusItem(
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      userPhoneNumber: userPhoneNumber,
      statusItem: statusItem,
    );
  }

  /// Encrypted image status. Image file is AES-GCM encrypted with a random
  /// content key; the content key is wrapped per viewer device.
  Future<void> uploadEncryptedImageStatus({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    String? userPhoneNumber,
    required File imageFile,
    String? caption,
    required List<String> viewerUids,
    String? itemId,
  }) async {
    // Shrink before encrypt+upload — a 5 MB gallery photo turns into a
    // ~250 KB JPEG that uploads in a second over 4G instead of 15-30s.
    //
    // Pro gets a higher-quality tier. Read straight off
    // `SubscriptionService.isProUnlocked` rather than threading a bool down from
    // the screen: that getter is the same capability gate the UI uses, so a
    // service with no `BuildContext` can't drift from the screen's answer.
    final compressed = await ImageCompressor.compressForStatus(
      imageFile,
      pro: SubscriptionService.instance.isProUnlocked,
    );
    return _uploadEncryptedMedia(
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      userPhoneNumber: userPhoneNumber,
      file: compressed,
      statusType: 'encrypted_image',
      folder: 'encrypted_images',
      contentType: 'image/jpeg',
      caption: caption,
      viewerUids: viewerUids,
      itemId: itemId,
    );
  }

  /// Encrypted video status — same flow as image, different content type.
  Future<void> uploadEncryptedVideoStatus({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    String? userPhoneNumber,
    required File videoFile,
    String? caption,
    required List<String> viewerUids,
    String? itemId,
  }) =>
      _uploadEncryptedMedia(
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        userPhoneNumber: userPhoneNumber,
        file: videoFile,
        statusType: 'encrypted_video',
        folder: 'encrypted_videos',
        contentType: 'video/mp4',
        caption: caption,
        viewerUids: viewerUids,
        itemId: itemId,
      );

  Future<void> _uploadEncryptedMedia({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    String? userPhoneNumber,
    required File file,
    required String statusType,
    required String folder,
    required String contentType,
    String? caption,
    required List<String> viewerUids,
    String? itemId,
  }) async {
    final ownerDeviceId = await _deviceIdentity.getDeviceId();
    if (ownerDeviceId == null) {
      throw StateError('E2EE not registered — cannot post encrypted status');
    }
    final statusItemId =
        itemId ?? _firestore.collection(_statusCollection).doc().id;
    final bundle = await _media.encryptAndUpload(
      file: file,
      storagePath:
          'statuses/$userId/$folder/${DateTime.now().millisecondsSinceEpoch}.bin',
      contentType: contentType,
    );

    final statusItem = StatusItem(
      id: statusItemId,
      type: statusType,
      imageUrl: bundle.url,
      caption: jsonEncode({
        'enc': true,
        'iv': base64Encode(bundle.iv),
        'hash': base64Encode(bundle.hash),
        'caption': caption,
        'ownerDeviceId': ownerDeviceId,
      }),
      createdAt: DateTime.now(),
      viewedBy: [],
    );

    final ps = await PlaintextStore.instance();
    final ownerMediaKey = Uint8List.fromList(bundle.key);
    await ps.saveStatusKey(statusItemId, ownerMediaKey);
    _mediaKeyCache[statusItemId] = ownerMediaKey;
    unawaited(_saveMediaKeyToVault(userId, statusItemId, ownerMediaKey));

    // Wrapped keys must land before the status item is visible to the
    // status list stream — otherwise the viewer opens it, finds no
    // envelope addressed to them, and stays on "Decrypting…" with no retry.
    await _publishWrappedKeys(
      ownerUid: userId,
      ownerDeviceId: ownerDeviceId,
      statusItemId: statusItemId,
      contentKey: Uint8List.fromList(bundle.key),
      viewerUids: viewerUids,
    );
    await _addStatusItem(
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      userPhoneNumber: userPhoneNumber,
      statusItem: statusItem,
    );
  }

  /// Viewer side: decrypts an encrypted status item and returns the
  /// plaintext bytes + iv. Returns null if not authorised.
  ///
  /// [preloadedKey] skips Signal-decrypt entirely — used on reinstall when
  /// _mediaKeyCache already has the AES key from the Firestore status vault.
  Future<Map<String, dynamic>?> decryptStatusItem({
    required String ownerUid,
    required StatusItem item,
    required String selfUid,
    Uint8List? preloadedKey,
  }) async {
    if (item.type != 'encrypted' &&
        item.type != 'encrypted_image' &&
        item.type != 'encrypted_video') {
      return null; // not an encrypted item
    }
    // Parse the metadata up-front so we know which of the owner's devices
    // posted this status. Without the right deviceId we'd address the wrong
    // Signal session and decryption would silently fail.
    final meta = jsonDecode(item.caption ?? '{}') as Map<String, dynamic>;
    final ownerDeviceId = (meta['ownerDeviceId'] as int?) ?? 1;

    // Priority order for the AES content key:
    //   1. preloadedKey (from _mediaKeyCache, pre-warmed from vault)
    //   2. Owner's local SQLite store (no Signal round-trip)
    //   3. Signal-decrypt via _fetchWrappedKey (needs live session)
    Uint8List? key = preloadedKey;
    if (key == null && selfUid == ownerUid) {
      key = await (await PlaintextStore.instance()).getStatusKey(item.id);
    }
    key ??= await _fetchWrappedKey(
      ownerUid: ownerUid,
      ownerDeviceId: ownerDeviceId,
      statusItemId: item.id,
      selfUid: selfUid,
    );
    if (key == null) return null;

    // Inline text statuses carry their ciphertext in `caption` ('ct') rather
    // than a Storage blob, so there is no download — decrypt the bytes in hand.
    // The GCM tag authenticates them, so no SHA hash is carried or checked.
    if (meta['inline'] == true) {
      final pt = await _media.openInline(
        key: key,
        iv: base64Decode(meta['iv'] as String),
        wire: base64Decode(meta['ct'] as String),
      );
      return {
        'type': item.type,
        'bytes': pt,
        if (item.type == 'encrypted')
          'json': jsonDecode(utf8.decode(pt)) as Map<String, dynamic>,
      };
    }

    // Legacy Storage-backed path: text statuses posted before the inline
    // migration, plus all image/video statuses (too large to inline).
    final bundle = MediaKeyBundle(
      key: key,
      iv: base64Decode(meta['iv'] as String),
      hash: base64Decode(meta['hash'] as String),
      url: item.imageUrl ?? '',
      sizeBytes: 0, // unknown; not used by download path
      contentType: item.type == 'encrypted_image'
          ? 'image/jpeg'
          : item.type == 'encrypted_video'
              ? 'video/mp4'
              : 'application/json',
    );
    final pt = await _media.downloadAndDecrypt(bundle);
    return {
      'type': item.type,
      'bytes': pt,
      if (item.type == 'encrypted')
        'json': jsonDecode(utf8.decode(pt)) as Map<String, dynamic>,
    };
  }

  CollectionReference<Map<String, dynamic>> _statusViewersRef({
    required String statusOwnerId,
    required String statusItemId,
  }) {
    return _firestore
        .collection(_statusCollection)
        .doc(statusOwnerId)
        .collection('views')
        .doc(statusItemId)
        .collection('viewers');
  }

  /// Upload a text status.
  Future<void> uploadTextStatus({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    String? userPhoneNumber,
    required String text,
    required String backgroundColor,
  }) async {
    try {
      final statusItem = StatusItem(
        id: _firestore.collection(_statusCollection).doc().id,
        type: 'text',
        text: text,
        backgroundColor: backgroundColor,
        createdAt: DateTime.now(),
        viewedBy: [],
      );

      final docRef = _firestore.collection(_statusCollection).doc(userId);
      final doc = await docRef.get();

      if (doc.exists) {
        // Append to existing status items
        await docRef.update({
          'statusItems': FieldValue.arrayUnion([statusItem.toMap()]),
          'lastUpdated': Timestamp.fromDate(DateTime.now()),
          'userName': userName,
          'userPhotoUrl': userPhotoUrl,
          'userPhoneNumber': userPhoneNumber,
        });
      } else {
        // Create new status document
        final statusModel = StatusModel(
          id: userId,
          userId: userId,
          userName: userName,
          userPhotoUrl: userPhotoUrl,
          userPhoneNumber: userPhoneNumber,
          statusItems: [statusItem],
          lastUpdated: DateTime.now(),
        );
        await docRef.set(statusModel.toMap());
      }

      // Award points and progress challenge
      unawaited(GamificationService.instance.earnPoints(userId, 3));
      unawaited(GamificationService.instance.incrementChallengeProgress(userId, 'status_posts', 1));

      print('Text status uploaded for user: $userId');
    } catch (e) {
      print('Error uploading text status: $e');
      rethrow;
    }
  }

  /// Upload a file to Firebase Storage and return the download URL.
  Future<String> _uploadFileToStorage({
    required String userId,
    required File file,
    required String folder, // 'images' or 'videos'
  }) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
    final storagePath = 'statuses/$userId/$folder/$fileName';
    debugPrint('[StatusService] Uploading to Storage path: $storagePath');
    debugPrint('[StatusService] File exists: ${await file.exists()}');

    return PerformanceService.traceAsync(
      'status_upload_file',
      (trace) async {
        PerformanceService.setAttribute(trace, 'file_type', folder);
        final fileSizeKb = (await file.length() / 1024).round();
        PerformanceService.incrementMetric(trace, 'file_size_kb',
            by: fileSizeKb);

        final ref = _storage.ref().child(storagePath);
        final uploadTask = ref.putFile(file);

        // Listen for progress
        uploadTask.snapshotEvents.listen((event) {
          final progress = event.bytesTransferred / event.totalBytes;
          debugPrint(
              '[StatusService] Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
        });

        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        debugPrint('[StatusService] Upload complete. URL: $downloadUrl');
        return downloadUrl;
      },
    );
  }

  /// Upload an image status from a file.
  Future<void> uploadImageStatus({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    String? userPhoneNumber,
    required File imageFile,
    String? caption,
  }) async {
    try {
      // Pro quality tier — see the note on the encrypted path above for why this
      // reads `isProUnlocked` directly instead of taking a parameter.
      final compressed = await ImageCompressor.compressForStatus(
        imageFile,
        pro: SubscriptionService.instance.isProUnlocked,
      );
      final imageUrl = await _uploadFileToStorage(
        userId: userId,
        file: compressed,
        folder: 'images',
      );

      final statusItem = StatusItem(
        id: _firestore.collection(_statusCollection).doc().id,
        type: 'image',
        imageUrl: imageUrl,
        caption: caption,
        createdAt: DateTime.now(),
        viewedBy: [],
      );

      await _addStatusItem(
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        userPhoneNumber: userPhoneNumber,
        statusItem: statusItem,
      );
      print('Image status uploaded for user: $userId');
    } catch (e) {
      print('Error uploading image status: $e');
      rethrow;
    }
  }

  /// Upload a video status from a file.
  Future<void> uploadVideoStatus({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    String? userPhoneNumber,
    required File videoFile,
    String? caption,
  }) async {
    try {
      // Upload video to Firebase Storage
      final videoUrl = await _uploadFileToStorage(
        userId: userId,
        file: videoFile,
        folder: 'videos',
      );

      final statusItem = StatusItem(
        id: _firestore.collection(_statusCollection).doc().id,
        type: 'video',
        videoUrl: videoUrl,
        caption: caption,
        createdAt: DateTime.now(),
        viewedBy: [],
      );

      await _addStatusItem(
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        userPhoneNumber: userPhoneNumber,
        statusItem: statusItem,
      );
      print('Video status uploaded for user: $userId');
    } catch (e) {
      print('Error uploading video status: $e');
      rethrow;
    }
  }

  /// Helper to add a StatusItem to the user's status document.
  Future<void> _addStatusItem({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    String? userPhoneNumber,
    required StatusItem statusItem,
  }) async {
    final docRef = _firestore.collection(_statusCollection).doc(userId);
    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.update({
        'statusItems': FieldValue.arrayUnion([statusItem.toMap()]),
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'userPhoneNumber': userPhoneNumber,
      });
    } else {
      final statusModel = StatusModel(
        id: userId,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        userPhoneNumber: userPhoneNumber,
        statusItems: [statusItem],
        lastUpdated: DateTime.now(),
      );
      await docRef.set(statusModel.toMap());
    }

    // Award points and progress challenge
    unawaited(GamificationService.instance.earnPoints(userId, 3));
    unawaited(GamificationService.instance.incrementChallengeProgress(userId, 'status_posts', 1));
  }

  /// Get current user's own status.
  Stream<StatusModel?> getMyStatus(String userId) {
    return _firestore
        .collection(_statusCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return StatusModel.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Get a user's status document once.
  Future<StatusModel?> getStatusByUserId(String userId) async {
    final doc =
        await _firestore.collection(_statusCollection).doc(userId).get();
    if (!doc.exists) return null;
    final status = StatusModel.fromFirestore(doc);
    return status.hasActiveStatus ? status : null;
  }

  /// Get all statuses from other users (contacts' statuses).
  Stream<List<StatusModel>> getAllStatuses(String currentUserId) {
    // Get statuses updated in the last 24 hours
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));

    return _firestore
        .collection(_statusCollection)
        .where('lastUpdated', isGreaterThan: Timestamp.fromDate(cutoff))
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => StatusModel.fromFirestore(doc))
          .where((status) =>
              status.userId != currentUserId && status.hasActiveStatus)
          .toList();
    });
  }

  /// Mark a specific status item as viewed by a user.
  Future<void> markStatusAsViewed({
    required String statusOwnerId,
    required String statusItemId,
    required String viewerId,
  }) async {
    try {
      if (statusOwnerId == viewerId) return;

      await _statusViewersRef(
        statusOwnerId: statusOwnerId,
        statusItemId: statusItemId,
      ).doc(viewerId).set({
        'viewerId': viewerId,
        'viewedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error marking status as viewed: $e');
    }
  }

  /// Check whether a viewer has seen a specific status item.
  Future<bool> hasViewedStatusItem({
    required String statusOwnerId,
    required String statusItemId,
    required String viewerId,
  }) async {
    try {
      if (statusOwnerId == viewerId) return true;

      final doc = await _statusViewersRef(
        statusOwnerId: statusOwnerId,
        statusItemId: statusItemId,
      ).doc(viewerId).get();

      return doc.exists;
    } catch (e) {
      print('Error checking status view: $e');
      return false;
    }
  }

  /// Check whether all active items in a status have been viewed.
  Future<bool> hasViewedAllActiveStatusItems({
    required StatusModel statusModel,
    required String viewerId,
  }) async {
    final activeItems = statusModel.activeStatusItems;
    if (activeItems.isEmpty) return false;

    final viewedResults = await Future.wait(
      activeItems.map((item) {
        return hasViewedStatusItem(
          statusOwnerId: statusModel.userId,
          statusItemId: item.id,
          viewerId: viewerId,
        );
      }),
    );

    return viewedResults.every((viewed) => viewed);
  }

  /// Delete a specific status item.
  Future<void> deleteStatusItem({
    required String userId,
    required String statusItemId,
  }) async {
    try {
      final docRef = _firestore.collection(_statusCollection).doc(userId);
      final doc = await docRef.get();

      if (!doc.exists) return;

      final statusModel = StatusModel.fromFirestore(doc);
      final updatedItems = statusModel.statusItems
          .where((item) => item.id != statusItemId)
          .toList();

      if (updatedItems.isEmpty) {
        await docRef.delete();
      } else {
        await docRef.update({
          'statusItems': updatedItems.map((item) => item.toMap()).toList(),
          'lastUpdated': Timestamp.fromDate(DateTime.now()),
        });
      }
      print('Status item deleted: $statusItemId');
    } catch (e) {
      print('Error deleting status item: $e');
      rethrow;
    }
  }

  /// Clean up expired status items (older than 24 hours).
  Future<void> cleanupExpiredStatuses(String userId) async {
    try {
      final docRef = _firestore.collection(_statusCollection).doc(userId);
      final doc = await docRef.get();

      if (!doc.exists) return;

      final statusModel = StatusModel.fromFirestore(doc);
      final activeItems = statusModel.activeStatusItems;

      if (activeItems.isEmpty) {
        await docRef.delete();
      } else if (activeItems.length != statusModel.statusItems.length) {
        await docRef.update({
          'statusItems': activeItems.map((item) => item.toMap()).toList(),
        });
      }
    } catch (e) {
      print('Error cleaning up expired statuses: $e');
    }
  }

  /// Get viewers for a specific status item.
  Future<List<UserModel>> getStatusViewers({
    required String statusOwnerId,
    required String statusItemId,
  }) async {
    try {
      final viewerDocs = await _statusViewersRef(
        statusOwnerId: statusOwnerId,
        statusItemId: statusItemId,
      ).get();

      List<UserModel> viewers = [];
      for (final viewerDoc in viewerDocs.docs) {
        final viewerId = viewerDoc.id;
        final userDoc =
            await _firestore.collection('users').doc(viewerId).get();
        if (userDoc.exists) {
          viewers.add(UserModel.fromFirestore(userDoc));
        }
      }
      return viewers;
    } catch (e) {
      print('Error getting status viewers: $e');
      return [];
    }
  }

  /// Watch the viewer count for a specific status item.
  Stream<int> watchStatusViewCount({
    required String statusOwnerId,
    required String statusItemId,
  }) {
    return _statusViewersRef(
      statusOwnerId: statusOwnerId,
      statusItemId: statusItemId,
    ).snapshots().map((snapshot) => snapshot.size);
  }
}

/// Lightweight fixed-concurrency gate. Allows up to [maxConcurrent]
/// async operations to run in parallel; the rest wait until a slot frees up.
/// Used by `_publishWrappedKeys` to cap Signal encrypt fan-out and by
/// `preDecryptStatuses` to cap media downloads.
class _Semaphore {
  _Semaphore(this._maxConcurrent);
  final int _maxConcurrent;
  int _active = 0;
  final List<Completer<void>> _queue = [];

  Future<void> run(Future<void> Function() fn) async {
    while (_active >= _maxConcurrent) {
      final c = Completer<void>();
      _queue.add(c);
      await c.future;
    }
    _active++;
    try {
      await fn();
    } finally {
      _active--;
      if (_queue.isNotEmpty) {
        _queue.removeAt(0).complete();
      }
    }
  }
}
