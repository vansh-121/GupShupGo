// SyncService — background sync pipeline from Firestore to local Drift database.
//
// Why this exists:
//
// In a local-first architecture, the UI never reads directly from the network.
// It subscribes to a local SQLite watch stream which is updated by this sync
// service.
//
// Responsibilities:
//  • Maintain active Firestore snapshot listeners for all chat rooms the user
//    participates in.
//  • When new messages are received, check if they are already present locally.
//  • Decrypt new/changed messages on the fly and save them in batch to SQLite.
//  • Handle updating message delivery/read status locally.
//  • Update chat room previews when new messages arrive.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/services/chat_service.dart';
import 'package:video_chat_app/services/crypto/plaintext_store.dart';

import 'package:video_chat_app/services/crypto/vault_cipher.dart';

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, StreamSubscription> _messageSubs = {};
  StreamSubscription? _roomsSub;
  String? _currentUserId;

  /// Starts listening to the user's active chat rooms and synchronizes
  /// their messages into the local database in the background.
  Future<void> init(String currentUserId, {bool force = false}) async {
    if (_currentUserId == currentUserId && !force) return;
    stop();
    _currentUserId = currentUserId;

    if (kDebugMode) debugPrint('[SyncService] Initializing background sync for user: $currentUserId');

    // Warm payload caches (SQLite + Vault) before starting room listeners
    try {
      await ChatService.instance.preWarmCaches(currentUserId);
    } catch (e) {
      if (kDebugMode) debugPrint('[SyncService] Cache pre-warm failed: $e');
    }

    _roomsSub = _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .listen((roomsSnap) {
      final activeRoomIds = <String>{};
      for (final doc in roomsSnap.docs) {
        final roomId = doc.id;
        activeRoomIds.add(roomId);
        _startSyncingRoom(roomId, currentUserId);
      }

      // Clean up subscriptions for rooms that are no longer active/visible
      final currentSubs = _messageSubs.keys.toList();
      for (final roomId in currentSubs) {
        if (!activeRoomIds.contains(roomId)) {
          if (kDebugMode) debugPrint('[SyncService] Stopping sync for room: $roomId');
          _messageSubs.remove(roomId)?.cancel();
        }
      }
    }, onError: (e) {
      if (kDebugMode) debugPrint('[SyncService] Rooms stream subscription error: $e');
    });
  }

  /// Cancels all active Firestore subscriptions. Call on sign-out.
  void stop() {
    if (_currentUserId != null && kDebugMode) {
      debugPrint('[SyncService] Stopping background sync for user: $_currentUserId');
    }
    _roomsSub?.cancel();
    _roomsSub = null;
    for (final sub in _messageSubs.values) {
      sub.cancel();
    }
    _messageSubs.clear();
    _currentUserId = null;
  }

  void _startSyncingRoom(String roomId, String currentUserId) {
    if (_messageSubs.containsKey(roomId)) return;

    if (kDebugMode) debugPrint('[SyncService] Starting sync for room: $roomId');

    // 1. Set up the sliding-window real-time listener for the last 50 messages
    final sub = _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) async {
      try {
        final store = await PlaintextStore.instance();
        
        // Fetch only recent local messages corresponding to document IDs in snapshot
        final messageIds = snapshot.docs.map((doc) => doc.id).toList();
        final localMessages = await store.getMessagesByIds(messageIds);
        final localMap = {for (final m in localMessages) m.id: m};

        final toSave = <MessageModel>[];
        bool hasChanges = false;

        for (final doc in snapshot.docs) {
          final serverMsg = MessageModel.fromFirestore(doc);
          final localMsg = localMap[serverMsg.id];

          final isLockedPlaceholder = localMsg != null && localMsg.text.startsWith('🔒');
          if (localMsg == null || isLockedPlaceholder) {
            final decrypted = await ChatService.instance.decryptForRendering(serverMsg, currentUserId);
            if (decrypted != null) {
              toSave.add(decrypted);
              hasChanges = true;
              if (decrypted.mediaUrl != null && decrypted.localFilePath == null) {
                _triggerMediaDownload(decrypted, roomId);
              }
            } else if (localMsg == null && VaultCipher.instance.isReady) {
              toSave.add(_lockedPlaceholder(serverMsg));
              hasChanges = true;
            }
          } else {
            // Check if status, sync status, or media changed
            if (localMsg.status != serverMsg.status ||
                localMsg.syncPending != serverMsg.syncPending ||
                localMsg.mediaUrl != serverMsg.mediaUrl) {
              final updated = localMsg.copyWith(
                status: serverMsg.status,
                syncPending: serverMsg.syncPending,
                mediaUrl: serverMsg.mediaUrl,
              );
              toSave.add(updated);
              hasChanges = true;
              if (updated.mediaUrl != null && updated.localFilePath == null) {
                _triggerMediaDownload(updated, roomId);
              }
            } else {
              // Trigger media download if the local message hasn't cached it yet
              if (localMsg.mediaUrl != null && localMsg.localFilePath == null) {
                _triggerMediaDownload(localMsg, roomId);
              }
            }
          }
        }

        if (hasChanges && toSave.isNotEmpty) {
          await store.saveMessagesBatch(toSave, roomId);

          // Update chat room preview locally using the decrypted form of the last message
          final latestDoc = snapshot.docs.isNotEmpty ? snapshot.docs.first : null;
          if (latestDoc != null) {
            final latestMsgId = latestDoc.id;
            MessageModel? decryptedLatest;
            for (final msg in toSave) {
              if (msg.id == latestMsgId) {
                decryptedLatest = msg;
                break;
              }
            }
            decryptedLatest ??= localMap[latestMsgId];

            if (decryptedLatest != null) {
              final previewText = decryptedLatest.text.isNotEmpty
                  ? decryptedLatest.text
                  : (decryptedLatest.mediaUrl != null ? 'Media' : '');
              if (previewText.isNotEmpty) {
                await store.saveRoomPreview(
                  chatRoomId: roomId,
                  messageId: decryptedLatest.id,
                  text: previewText,
                );
              }
            }
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[SyncService] Error syncing messages in room $roomId: $e');
      }
    }, onError: (e) {
      if (kDebugMode) debugPrint('[SyncService] Messages stream error in room $roomId: $e');
    });

    _messageSubs[roomId] = sub;

    // 2. Perform background delta sync for historical messages since lastSavedTimestamp
    unawaited(() async {
      try {
        final store = await PlaintextStore.instance();
        final lastSavedTimestamp = await store.getLatestMessageTimestamp(roomId);
        if (lastSavedTimestamp != null) {
          if (kDebugMode) {
            debugPrint('[SyncService] Delta query for room $roomId from timestamp $lastSavedTimestamp');
          }
          final querySnap = await _firestore
              .collection('chatRooms')
              .doc(roomId)
              .collection('messages')
              .where('timestamp', isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(lastSavedTimestamp))
              .orderBy('timestamp')
              .get();

          if (querySnap.docs.isNotEmpty) {
            if (kDebugMode) {
              debugPrint('[SyncService] Found ${querySnap.docs.length} messages in delta query for room $roomId');
            }
            final toSave = <MessageModel>[];
            for (final doc in querySnap.docs) {
              final serverMsg = MessageModel.fromFirestore(doc);
              final decrypted = await ChatService.instance.decryptForRendering(serverMsg, currentUserId);
              if (decrypted != null) {
                toSave.add(decrypted);
                if (decrypted.mediaUrl != null) {
                  _triggerMediaDownload(decrypted, roomId);
                }
              } else if (VaultCipher.instance.isReady) {
                toSave.add(_lockedPlaceholder(serverMsg));
              }
            }
            if (toSave.isNotEmpty) {
              await store.saveMessagesBatch(toSave, roomId);
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[SyncService] Error performing background delta sync in room $roomId: $e');
        }
      }
    }());
  }

  void _triggerMediaDownload(MessageModel message, String chatRoomId) {
    unawaited(() async {
      try {
        final localPath = await ChatService.instance.downloadAndCacheMedia(message);
        if (localPath != null) {
          final store = await PlaintextStore.instance();
          final updatedMsg = message.copyWith(localFilePath: localPath);
          await store.saveMessage(updatedMsg, chatRoomId);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[SyncService] Error downloading media for message ${message.id}: $e');
        }
      }
    }());
  }

  MessageModel _lockedPlaceholder(MessageModel msg) {
    return msg.copyWith(
      text: '🔒 can\'t decrypt — ask sender to resend',
    );
  }
}
