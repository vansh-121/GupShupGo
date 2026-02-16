import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:video_chat_app/models/status_model.dart';
import 'package:video_chat_app/models/user_model.dart';

class StatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _statusCollection = 'statuses';

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
      final docRef =
          _firestore.collection(_statusCollection).doc(statusOwnerId);
      final doc = await docRef.get();

      if (!doc.exists) return;

      final statusModel = StatusModel.fromFirestore(doc);
      final updatedItems = statusModel.statusItems.map((item) {
        if (item.id == statusItemId && !item.viewedBy.contains(viewerId)) {
          return StatusItem(
            id: item.id,
            type: item.type,
            text: item.text,
            imageUrl: item.imageUrl,
            videoUrl: item.videoUrl,
            thumbnailUrl: item.thumbnailUrl,
            caption: item.caption,
            backgroundColor: item.backgroundColor,
            createdAt: item.createdAt,
            viewedBy: [...item.viewedBy, viewerId],
          );
        }
        return item;
      }).toList();

      await docRef.update({
        'statusItems': updatedItems.map((item) => item.toMap()).toList(),
      });
    } catch (e) {
      print('Error marking status as viewed: $e');
    }
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
      final doc = await _firestore
          .collection(_statusCollection)
          .doc(statusOwnerId)
          .get();

      if (!doc.exists) return [];

      final statusModel = StatusModel.fromFirestore(doc);
      final statusItem = statusModel.statusItems
          .where((item) => item.id == statusItemId)
          .firstOrNull;

      if (statusItem == null) return [];

      List<UserModel> viewers = [];
      for (String viewerId in statusItem.viewedBy) {
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
}
