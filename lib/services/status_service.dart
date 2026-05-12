import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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
import 'package:video_chat_app/services/performance_service.dart';

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
      for (final doc in snap.docs) {
        final data = doc.data();
        final type = data['t'] as String?;
        if (type == 'text' && !_plaintextCache.containsKey(doc.id)) {
          final payload = await VaultCipher.instance.decryptDoc(data);
          if (payload == null) continue;
          _plaintextCache[doc.id] = StatusPlaintext.text(
            text: (payload['tx'] as String?) ?? '',
            backgroundColor: (payload['bg'] as String?) ?? '#6C5CE7',
          );
        } else if (type == 'media_key' &&
            !_mediaKeyCache.containsKey(doc.id)) {
          // Restore the AES content key — the encrypted blob is still in
          // Storage, so we can re-download and decrypt without Signal.
          final k = await VaultCipher.instance.decryptBytes(data);
          if (k != null) _mediaKeyCache[doc.id] = k;
        }
      }
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
  Future<void> preDecryptStatuses(
      List<StatusModel> models, String selfUid) async {
    // Bulk-load the text status vault into _plaintextCache so items that
    // were seen on a previous install (Signal session lost) still render.
    await _preWarmStatusCache(selfUid);

    final tasks = <Future<void>>[];
    for (final m in models) {
      for (final item in m.activeStatusItems) {
        if (!item.type.startsWith('encrypted')) continue;
        if (_plaintextCache.containsKey(item.id)) continue;
        final existing = _inFlight[item.id];
        if (existing != null) {
          tasks.add(existing);
          continue;
        }
        final future = _preDecryptOne(m.userId, item, selfUid)
            .whenComplete(() => _inFlight.remove(item.id));
        _inFlight[item.id] = future;
        tasks.add(future);
      }
    }
    if (tasks.isNotEmpty) await Future.wait(tasks);
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
      await existing;
      return;
    }
    final fut = _preDecryptOne(ownerUid, item, selfUid)
        .whenComplete(() => _inFlight.remove(item.id));
    _inFlight[item.id] = fut;
    await fut;
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
          final file = File(path);
          if (await file.exists()) {
            // For video we only need the path (the player opens the file
            // directly). For images we keep bytes in memory for Image.memory.
            final isVideo = (disk['v'] as bool?) ?? false;
            final bytes = isVideo ? Uint8List(0) : await file.readAsBytes();
            _plaintextCache[item.id] = StatusPlaintext.media(
              localFile: file,
              bytes: bytes,
              isVideo: isVideo,
            );
            return;
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
        // No AES key available (vault empty, Signal session gone) — this
        // item cannot be decrypted on this install. Mark it so the viewer
        // can filter it out instead of showing a spinner forever.
        _unrecoverable.add(item.id);
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
      _unrecoverable.add(item.id);
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
  /// always included in the fan-out so they can decrypt their own status
  /// (otherwise "My Status" stays on the "Decrypting…" placeholder forever).
  ///
  /// All viewers run in parallel. Sequential fan-out was the dominant cost
  /// of an upload — each viewer pays one consumeOneTimePreKey HTTP round-trip
  /// per device, and 10 viewers × ~2s adds up to the 40-50s upload the user
  /// was seeing. Different viewers' sessions don't touch the same session
  /// store entry, so concurrent encrypts are safe.
  Future<void> _publishWrappedKeys({
    required String ownerUid,
    required int ownerDeviceId,
    required String statusItemId,
    required Uint8List contentKey,
    required List<String> viewerUids,
  }) async {
    final fanout = <String>{...viewerUids, ownerUid}.toList();
    await Future.wait(fanout.map((viewerUid) async {
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
    }));
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
    if (!doc.exists) return null;
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
  }) async {
    final ownerDeviceId = await _deviceIdentity.getDeviceId();
    if (ownerDeviceId == null) {
      throw StateError('E2EE not registered — cannot post encrypted status');
    }
    final statusItemId = _firestore.collection(_statusCollection).doc().id;

    final bundle = await _media.encryptAndUploadBytes(
      bytes: Uint8List.fromList(utf8.encode(jsonEncode({
        'type': 'text',
        'text': text,
        'backgroundColor': backgroundColor,
      }))),
      storagePath:
          'statuses/$userId/encrypted_text/${DateTime.now().millisecondsSinceEpoch}',
      contentType: 'application/json',
    );

    final statusItem = StatusItem(
      id: statusItemId,
      type: 'encrypted',
      text: null,
      createdAt: DateTime.now(),
      viewedBy: [],
      imageUrl: bundle.url,
      caption: jsonEncode({
        'enc': true,
        'iv': base64Encode(bundle.iv),
        'hash': base64Encode(bundle.hash),
        'ownerDeviceId': ownerDeviceId,
      }),
    );

    // Cache the content key locally so this (posting) device can decrypt
    // its own status without a Signal-to-self envelope.
    final ps = await PlaintextStore.instance();
    final ownerKey = Uint8List.fromList(bundle.key);
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
  }) =>
      _uploadEncryptedMedia(
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        userPhoneNumber: userPhoneNumber,
        file: imageFile,
        statusType: 'encrypted_image',
        folder: 'encrypted_images',
        contentType: 'image/jpeg',
        caption: caption,
        viewerUids: viewerUids,
      );

  /// Encrypted video status — same flow as image, different content type.
  Future<void> uploadEncryptedVideoStatus({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    String? userPhoneNumber,
    required File videoFile,
    String? caption,
    required List<String> viewerUids,
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
  }) async {
    final ownerDeviceId = await _deviceIdentity.getDeviceId();
    if (ownerDeviceId == null) {
      throw StateError('E2EE not registered — cannot post encrypted status');
    }
    final statusItemId = _firestore.collection(_statusCollection).doc().id;
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
      // Upload image to Firebase Storage
      final imageUrl = await _uploadFileToStorage(
        userId: userId,
        file: imageFile,
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
    final cutoff = DateTime.now().subtract(Duration(hours: 24));

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
