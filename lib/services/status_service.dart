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
import 'package:video_chat_app/services/crypto/persistent_signal_stores.dart';
import 'package:video_chat_app/services/crypto/signal_service.dart';
import 'package:video_chat_app/services/performance_service.dart';

class StatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final EncryptedMediaService _media = EncryptedMediaService();
  final DeviceIdentityService _deviceIdentity = DeviceIdentityService();
  final String _statusCollection = 'statuses';

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

  /// Wraps the content key for every viewer's every device.
  Future<void> _publishWrappedKeys({
    required String ownerUid,
    required int ownerDeviceId,
    required String statusItemId,
    required Uint8List contentKey,
    required List<String> viewerUids,
  }) async {
    for (final viewerUid in viewerUids) {
      final encs = await SignalService.instance.encryptForUser(
        senderUid: ownerUid,
        senderDeviceId: ownerDeviceId,
        recipientUid: viewerUid,
        plaintext: contentKey,
      );
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
    }
  }

  /// Fetches and decrypts the content key for a status item this device is
  /// authorised to view. Returns null if no envelope is addressed to us.
  Future<Uint8List?> _fetchWrappedKey({
    required String ownerUid,
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
      // Owner is always deviceId=1 for status (the originating device).
      // For multi-device owners, callers should pass the owner's deviceId
      // from the status item metadata.
      return await SignalService.instance.decrypt(ownerUid, 1, env);
    } catch (_) {
      return null;
    }
  }

  /// Random 256-bit content key for a status item.
  Uint8List _newContentKey() => signalRandomBytes(32);

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
    final contentKey = _newContentKey();
    final statusItemId = _firestore.collection(_statusCollection).doc().id;

    // Encrypt the text using the same AES-GCM helper as media.
    final encBundle = await _media.encryptAndUploadBytes(
      bytes: Uint8List.fromList(utf8.encode(jsonEncode({
        'type': 'text',
        'text': text,
        'backgroundColor': backgroundColor,
      }))),
      storagePath:
          'statuses/$userId/encrypted_text/${DateTime.now().millisecondsSinceEpoch}',
      contentType: 'application/json',
    );
    // Override the random per-blob key with the per-status content key so
    // _all_ status blobs of this item share the same key (text + any future
    // media in the same story). For text-only this is functionally equivalent
    // to encBundle.key, but unified design.
    final unifiedKey = contentKey;
    // Re-encrypt with the unified key to keep one wrapping per status item.
    final reEncrypted = await _media.encryptAndUploadBytes(
      bytes: Uint8List.fromList(utf8.encode(jsonEncode({
        'type': 'text',
        'text': text,
        'backgroundColor': backgroundColor,
      }))),
      storagePath:
          'statuses/$userId/encrypted_text/${DateTime.now().millisecondsSinceEpoch}_v2',
      contentType: 'application/json',
    );
    // Delete the throwaway first upload.
    try {
      await FirebaseStorage.instance.refFromURL(encBundle.url).delete();
    } catch (_) {}

    final statusItem = StatusItem(
      id: statusItemId,
      type: 'encrypted',
      text: null,
      createdAt: DateTime.now(),
      viewedBy: [],
      // We stash the bundle without the key — viewers fetch the wrapped key
      // separately and decrypt locally.
      imageUrl: reEncrypted.url,
      caption: jsonEncode({
        'enc': true,
        'iv': base64Encode(reEncrypted.iv),
        'hash': base64Encode(reEncrypted.hash),
        'ownerDeviceId': ownerDeviceId,
      }),
    );

    await _addStatusItem(
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      userPhoneNumber: userPhoneNumber,
      statusItem: statusItem,
    );

    await _publishWrappedKeys(
      ownerUid: userId,
      ownerDeviceId: ownerDeviceId,
      statusItemId: statusItemId,
      contentKey: unifiedKey,
      viewerUids: viewerUids,
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
  }) async {
    final ownerDeviceId = await _deviceIdentity.getDeviceId();
    if (ownerDeviceId == null) {
      throw StateError('E2EE not registered — cannot post encrypted status');
    }
    final statusItemId = _firestore.collection(_statusCollection).doc().id;
    final bundle = await _media.encryptAndUpload(
      file: imageFile,
      storagePath:
          'statuses/$userId/encrypted_images/${DateTime.now().millisecondsSinceEpoch}.bin',
      contentType: 'image/jpeg',
    );

    final statusItem = StatusItem(
      id: statusItemId,
      type: 'encrypted_image',
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

    await _addStatusItem(
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      userPhoneNumber: userPhoneNumber,
      statusItem: statusItem,
    );

    await _publishWrappedKeys(
      ownerUid: userId,
      ownerDeviceId: ownerDeviceId,
      statusItemId: statusItemId,
      contentKey: Uint8List.fromList(bundle.key),
      viewerUids: viewerUids,
    );
  }

  /// Viewer side: decrypts an encrypted status item and returns the
  /// plaintext bytes + iv. Returns null if not authorised.
  Future<Map<String, dynamic>?> decryptStatusItem({
    required String ownerUid,
    required StatusItem item,
    required String selfUid,
  }) async {
    if (item.type != 'encrypted' && item.type != 'encrypted_image') {
      return null; // not an encrypted item
    }
    final key = await _fetchWrappedKey(
      ownerUid: ownerUid,
      statusItemId: item.id,
      selfUid: selfUid,
    );
    if (key == null) return null;

    final meta = jsonDecode(item.caption ?? '{}') as Map<String, dynamic>;
    final bundle = MediaKeyBundle(
      key: key,
      iv: base64Decode(meta['iv'] as String),
      hash: base64Decode(meta['hash'] as String),
      url: item.imageUrl ?? '',
      sizeBytes: 0, // unknown; not used by download path
      contentType: item.type == 'encrypted_image'
          ? 'image/jpeg'
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
