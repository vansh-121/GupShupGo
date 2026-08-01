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
  int _syncToken = 0;

  /// Per-room sequential Future chain. Instead of discarding snapshots when a
  /// room is already processing, we queue them: each new snapshot's processing
  /// Future is chained after the previous one, ensuring they execute in order
  /// without interleaving or dropping updates.
  final _roomSyncQueues = <String, Future<void>>{};

  /// Rooms with a background reconcile pass currently running, so bursts of
  /// snapshots don't stack redundant full-window walks.
  final _reconcilingRooms = <String>{};

  /// Last time a reconcile ran per room, used to throttle it.
  final _lastReconcile = <String, DateTime>{};
  static const _reconcileInterval = Duration(seconds: 60);

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
    _roomSyncQueues.clear();
    _reconcilingRooms.clear();
    _lastReconcile.clear();
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
        .listen((snapshot) {
      // Sequential queue per room — chain this snapshot's processing after
      // any previous one. Never discard snapshots; otherwise a message that
      // arrives during decrypt would be silently lost forever.
      final prev = _roomSyncQueues[roomId] ?? Future.value();
      _roomSyncQueues[roomId] = prev.then((_) => _processRoomSnapshot(
            roomId,
            snapshot,
            currentUserId,
          ));
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
        // Used in query order: the backfill query is `descending: true`, so
        // the newest messages — the bottom of the conversation, which is
        // what the user actually looks at — land in SQLite first. The delta
        // query is ascending, which is already correct for filling forward.
        final docs = querySnap.docs;

        // Progressive flush: write the first message on its own so the UI
        // can render it immediately, then let the batch size double
        // (1, 2, 4, 8, 16) so a large backfill still commits efficiently.
        // The old code accumulated all 50 and wrote once at the very end,
        // which meant nothing appeared until the whole pass finished.
        final pending = <MessageModel>[];
        var flushAt = 1;
        var processed = 0;
        final total = docs.length;

        Future<void> flush() async {
          if (pending.isEmpty) return;
          await store.saveMessagesBatch(List.of(pending), roomId);
          pending.clear();
          if (flushAt < 16) flushAt *= 2;
        }

        for (final doc in docs) {
          final serverMsg = MessageModel.fromFirestore(doc);
          final decrypted = await ChatService.instance
              .decryptForRendering(serverMsg, currentUserId);
          if (decrypted != null) {
            pending.add(decrypted);
            if (decrypted.mediaUrl != null) {
              _triggerMediaDownload(decrypted, roomId);
            }
          } else if (VaultCipher.instance.isReady) {
            pending.add(_lockedPlaceholder(serverMsg));
          }

          if (pending.length >= flushAt) await flush();

          // Yield to the UI only when there is genuinely more heavy work
          // queued behind us. Yielding on the last item just delays the
          // write for no benefit.
          if (++processed % 3 == 0 && processed < total) {
            await Future.delayed(const Duration(milliseconds: 4));
          }
        }
        await flush();
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              '[SyncService] Error performing background sync in room $roomId: $e');
        }
      }
    }());
  }

  /// True when a locally-stored message is still an undecryptable
  /// placeholder (rendered as "🔒 …") and therefore worth retrying.
  static bool _isLocked(MessageModel m) => m.text.startsWith('🔒');

  /// Processes a single Firestore snapshot for [roomId]: decrypts new
  /// messages, updates previews, triggers media downloads. Runs via the
  /// per-room sequential queue so snapshots are never dropped.
  ///
  /// Latency design (this is what makes an incoming message appear
  /// instantly instead of after several seconds):
  ///
  ///  1. Only the documents Firestore reports as *changed* are inspected.
  ///     A new message is one document, not the whole 50-doc window. The
  ///     previous full-window walk meant every read receipt re-processed
  ///     50 messages.
  ///  2. Content (a message that needs decrypting — a new bubble the user
  ///     is waiting for) is handled strictly before metadata (delivery /
  ///     read ticks on messages already on screen). Opening a chat fires
  ///     markDelivered + markRead, and that churn used to queue ahead of
  ///     the very message being waited on.
  ///  3. Decrypted messages are written to SQLite progressively — the
  ///     first one on its own — so the chat screen's watch stream fires
  ///     immediately rather than after the entire pass commits.
  ///  4. The UI yield only happens when real work remains behind it, never
  ///     before the first message has been persisted.
  Future<void> _processRoomSnapshot(
    String roomId,
    QuerySnapshot<Map<String, dynamic>> snapshot,
    String currentUserId,
  ) async {
    try {
      final store = await PlaintextStore.instance();

      // `removed` means the document slid out of the 50-doc window, not
      // that it was deleted — never act on those locally.
      final changed = snapshot.docChanges
          .where((c) => c.type != DocumentChangeType.removed)
          .map((c) => c.doc)
          .toList();

      if (changed.isEmpty) {
        _scheduleReconcile(roomId, snapshot, currentUserId);
        return;
      }

      final localMessages =
          await store.getMessagesByIds(changed.map((d) => d.id).toList());
      final localMap = {for (final m in localMessages) m.id: m};

      final content = <DocumentSnapshot<Map<String, dynamic>>>[];
      final metadata = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final doc in changed) {
        final localMsg = localMap[doc.id];
        if (localMsg == null || _isLocked(localMsg)) {
          content.add(doc);
        } else {
          metadata.add(doc);
        }
      }

      // Everything we persisted in this pass, for the preview update below.
      final saved = <String, MessageModel>{};

      // ── Pass 1: content ─────────────────────────────────────────────
      final pending = <MessageModel>[];
      var flushAt = 1;
      var processed = 0;

      Future<void> flush() async {
        if (pending.isEmpty) return;
        await store.saveMessagesBatch(List.of(pending), roomId);
        for (final m in pending) {
          saved[m.id] = m;
        }
        pending.clear();
        if (flushAt < 16) flushAt *= 2;
      }

      for (final doc in content) {
        final serverMsg = MessageModel.fromFirestore(doc);
        final localMsg = localMap[serverMsg.id];
        final wasLocked = localMsg != null && _isLocked(localMsg);

        final decrypted = await ChatService.instance
            .decryptForRendering(serverMsg, currentUserId);

        if (decrypted != null) {
          // Don't overwrite an existing placeholder with another
          // placeholder — that's a pointless write and a pointless
          // rebuild of the message list.
          final stillLocked = wasLocked && _isLocked(decrypted);
          if (!stillLocked) {
            pending.add(decrypted);
            if (decrypted.mediaUrl != null && decrypted.localFilePath == null) {
              _triggerMediaDownload(decrypted, roomId);
            }
          }
        } else if (localMsg == null && VaultCipher.instance.isReady) {
          pending.add(_lockedPlaceholder(serverMsg));
        }

        if (pending.length >= flushAt) await flush();

        if (++processed % 3 == 0 && processed < content.length) {
          await Future.delayed(const Duration(milliseconds: 4));
        }
      }
      await flush();

      // ── Pass 2: metadata ────────────────────────────────────────────
      // Tick marks on messages already rendered. One batch, no yields —
      // there is no decryption here, so there's nothing to throttle.
      final statusUpdates = <MessageModel>[];
      for (final doc in metadata) {
        final serverMsg = MessageModel.fromFirestore(doc);
        final localMsg = localMap[serverMsg.id];
        if (localMsg == null) continue;

        if (localMsg.status != serverMsg.status ||
            localMsg.syncPending != serverMsg.syncPending ||
            localMsg.mediaUrl != serverMsg.mediaUrl) {
          final updated = localMsg.copyWith(
            status: serverMsg.status,
            syncPending: serverMsg.syncPending,
            mediaUrl: serverMsg.mediaUrl,
          );
          statusUpdates.add(updated);
          if (updated.mediaUrl != null && updated.localFilePath == null) {
            _triggerMediaDownload(updated, roomId);
          }
        } else if (localMsg.mediaUrl != null &&
            localMsg.localFilePath == null) {
          _triggerMediaDownload(localMsg, roomId);
        }
      }
      if (statusUpdates.isNotEmpty) {
        await store.saveMessagesBatch(statusUpdates, roomId);
        for (final m in statusUpdates) {
          saved[m.id] = m;
        }
      }

      // ── Chat-list preview ───────────────────────────────────────────
      // Only the newest message drives the preview. If it wasn't part of
      // this change set, the preview can't have changed — skip the write.
      if (snapshot.docs.isNotEmpty) {
        final latest = saved[snapshot.docs.first.id];
        if (latest != null) {
          final previewText = latest.text.isNotEmpty
              ? latest.text
              : (latest.mediaUrl != null ? 'Media' : '');
          if (previewText.isNotEmpty) {
            await store.saveRoomPreview(
              chatRoomId: roomId,
              messageId: latest.id,
              text: previewText,
            );
          }
        }
      }

      // If this snapshot's change set already covered the entire window —
      // which is the case for the first snapshot of a room, where every doc
      // arrives as `added` — the fast path just did the reconcile's job.
      // Don't walk all 50 documents a second time on cold start.
      final wasFullPass = changed.length >= snapshot.docs.length;
      if (wasFullPass) {
        _lastReconcile[roomId] = DateTime.now();
      } else {
        _scheduleReconcile(roomId, snapshot, currentUserId);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SyncService] Error syncing messages in room $roomId: $e');
      }
    }
  }

  /// Background self-heal over the full 50-doc window.
  ///
  /// The fast path above only inspects changed documents, so on its own it
  /// can't notice that an *older* message is still a 🔒 placeholder (the
  /// vault was unlocked since it was stored) or that its media never
  /// finished downloading. This walks the whole window to fix those, but
  /// runs off the sync queue and is never awaited, so it can't delay a new
  /// message. Throttled per room, and skipped while one is in flight.
  void _scheduleReconcile(
    String roomId,
    QuerySnapshot<Map<String, dynamic>> snapshot,
    String currentUserId,
  ) {
    if (_reconcilingRooms.contains(roomId)) return;
    final last = _lastReconcile[roomId];
    final now = DateTime.now();
    if (last != null && now.difference(last) < _reconcileInterval) return;

    _reconcilingRooms.add(roomId);
    _lastReconcile[roomId] = now;

    unawaited(() async {
      try {
        final store = await PlaintextStore.instance();
        final ids = snapshot.docs.map((d) => d.id).toList();
        if (ids.isEmpty) return;
        final localMessages = await store.getMessagesByIds(ids);
        final localMap = {for (final m in localMessages) m.id: m};

        final repaired = <MessageModel>[];
        var processed = 0;

        for (final doc in snapshot.docs) {
          final localMsg = localMap[doc.id];

          // Missing media on an otherwise-healthy message: just retry the
          // download, no decryption needed.
          if (localMsg != null && !_isLocked(localMsg)) {
            if (localMsg.mediaUrl != null && localMsg.localFilePath == null) {
              _triggerMediaDownload(localMsg, roomId);
            }
            continue;
          }

          // Locked placeholder, or a message the fast path never stored.
          final serverMsg = MessageModel.fromFirestore(doc);
          final decrypted = await ChatService.instance
              .decryptForRendering(serverMsg, currentUserId);
          if (decrypted != null && !_isLocked(decrypted)) {
            repaired.add(decrypted);
            if (decrypted.mediaUrl != null && decrypted.localFilePath == null) {
              _triggerMediaDownload(decrypted, roomId);
            }
          }

          if (++processed % 3 == 0) {
            await Future.delayed(const Duration(milliseconds: 4));
          }
        }

        if (repaired.isNotEmpty) {
          await store.saveMessagesBatch(repaired, roomId);
          if (kDebugMode) {
            debugPrint(
                '[SyncService] Reconcile repaired ${repaired.length} message(s) in room $roomId');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[SyncService] Reconcile failed for room $roomId: $e');
        }
      } finally {
        _reconcilingRooms.remove(roomId);
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
