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
  final _inFlightDownloads = <String>{};
  final _processingRooms = <String>{};
  int _syncToken = 0;

  /// Starts listening to the user's active chat rooms and synchronizes
  /// their messages into the local database in the background.
  Future<void> init(String currentUserId, {bool force = false}) async {
    if (_currentUserId == currentUserId && !force) return;
    stop();
    _currentUserId = currentUserId;
    final token = ++_syncToken;

    if (kDebugMode) debugPrint('[SyncService] Initializing background sync for user: $currentUserId');

    // Warm payload caches (SQLite + Vault) before starting room listeners
    try {
      await ChatService.instance.preWarmCaches(currentUserId);
    } catch (e) {
      if (kDebugMode) debugPrint('[SyncService] Cache pre-warm failed: $e');
    }

    if (token != _syncToken) {
      if (kDebugMode) debugPrint('[SyncService] Initialization aborted: newer sync started');
      return;
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
    _inFlightDownloads.clear();
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
      // Guard: skip if this room is already processing a previous snapshot.
      // Firestore can emit a new snapshot before the previous async callback
      // finishes, causing two executions to interleave — both try to decrypt
      // the same messages and write to SQLite concurrently.
      if (!_processingRooms.add(roomId)) return;

      try {
        final store = await PlaintextStore.instance();
        
        // Fetch only recent local messages corresponding to document IDs in snapshot
        final messageIds = snapshot.docs.map((doc) => doc.id).toList();
        final localMessages = await store.getMessagesByIds(messageIds);
        final localMap = {for (final m in localMessages) m.id: m};

        final toSave = <MessageModel>[];
        bool hasChanges = false;
        int decryptIndex = 0;

        for (final doc in snapshot.docs) {
          // Yield to the UI thread every 3 messages with a 4ms delay.
          // Each Signal decrypt takes 10-30ms; 3×30ms = 90ms of CPU before
          // yielding a half-frame (4ms) to the UI. This keeps the 60fps
          // budget happy even during a 50-message burst, while minimizing
          // total sync time compared to yielding after every message.
          // Previously yielded every 5 with Duration.zero which didn't
          // reliably give the UI thread enough time on low-end devices.
          if (++decryptIndex % 3 == 0) {
            await Future.delayed(const Duration(milliseconds: 4));
          }

          final serverMsg = MessageModel.fromFirestore(doc);
          final localMsg = localMap[serverMsg.id];

          final isLockedPlaceholder = localMsg != null && localMsg.text.startsWith('🔒');
          if (localMsg == null || isLockedPlaceholder) {
            final decrypted = await ChatService.instance.decryptForRendering(serverMsg, currentUserId);
            if (decrypted != null) {
              final isStillPlaceholder = isLockedPlaceholder && decrypted.text.startsWith('🔒');
              if (!isStillPlaceholder) {
                toSave.add(decrypted);
                hasChanges = true;
                if (decrypted.mediaUrl != null && decrypted.localFilePath == null) {
                  _triggerMediaDownload(decrypted, roomId);
                }
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
      } finally {
        _processingRooms.remove(roomId);
      }
    }, onError: (e) {
      if (kDebugMode) debugPrint('[SyncService] Messages stream error in room $roomId: $e');
    });

    _messageSubs[roomId] = sub;

    // 2. Perform background sync for messages — delta (if we have local
    //    data) or initial bulk fetch (first install).
    //
    // On first install, `lastSavedTimestamp` is null and the delta query
    // is skipped. That leaves only the real-time snapshot listener to
    // populate the local DB — but that listener can be slow on some devices
    // (Firestore SDK transport negotiation, cold cache). The one-time
    // query below acts as a backup: it fetches the latest 50 messages
    // immediately, ensuring the user sees messages ASAP regardless of
    // listener latency.
    unawaited(() async {
      try {
        final store = await PlaintextStore.instance();
        final lastSavedTimestamp = await store.getLatestMessageTimestamp(roomId);

        Query query;
        if (lastSavedTimestamp != null) {
          // Delta: fetch messages newer than what we have locally
          query = _firestore
              .collection('chatRooms')
              .doc(roomId)
              .collection('messages')
              .where('timestamp',
                  isGreaterThan:
                      Timestamp.fromMillisecondsSinceEpoch(lastSavedTimestamp))
              .orderBy('timestamp');
        } else {
          // First install / no local data: fetch latest 50 as a one-shot
          // backup alongside the real-time listener. Whichever finishes
          // first populates the DB.
          query = _firestore
              .collection('chatRooms')
              .doc(roomId)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(50);
        }

        final querySnap = await query.get();
        if (querySnap.docs.isEmpty) return;

        if (kDebugMode) {
          debugPrint(
              '[SyncService] Found ${querySnap.docs.length} messages in background query for room $roomId');
        }
        final toSave = <MessageModel>[];
        // Process in reverse chronological so the oldest messages come
        // first (matches the listener's order for dedup).
        final docs = lastSavedTimestamp != null
            ? querySnap.docs
            : querySnap.docs.reversed;

        // Chunked processing: decrypt 3 messages, then yield 4ms to the UI.
        // On cold start with 5 rooms × 50 messages = 250 decrypts at
        // ~20ms each, the old per-message Duration.zero yield meant the UI
        // still froze for seconds. Chunking with a real delay gives the
        // engine a reliable half-frame to render between batches.
        int chunkIdx = 0;
        for (final doc in docs) {
          if (++chunkIdx % 3 == 0) {
            await Future.delayed(const Duration(milliseconds: 4));
          }
          final serverMsg = MessageModel.fromFirestore(doc);
          final decrypted = await ChatService.instance
              .decryptForRendering(serverMsg, currentUserId);
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
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              '[SyncService] Error performing background sync in room $roomId: $e');
        }
      }
    }());
  }

  void _triggerMediaDownload(MessageModel message, String chatRoomId) {
    if (_inFlightDownloads.contains(message.id)) return;
    _inFlightDownloads.add(message.id);

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
      } finally {
        _inFlightDownloads.remove(message.id);
      }
    }());
  }

  MessageModel _lockedPlaceholder(MessageModel msg) {
    return msg.copyWith(
      text: '🔒 can\'t decrypt — ask sender to resend',
    );
  }
}
