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
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/services/chat_service.dart';
import 'package:video_chat_app/services/crypto/device_identity_service.dart';
import 'package:video_chat_app/services/crypto/plaintext_store.dart';
import 'package:video_chat_app/services/crypto/signal_service.dart';

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

  /// Rooms known to hold at least one message this device can't read.
  ///
  /// Gates the peer-liveness throttle drop in [_processRoomSnapshot]. Repairing
  /// a broken bubble the moment the peer reappears is worth a sweep; doing it in
  /// a healthy room is not, and without this gate every incoming message in an
  /// active conversation would trigger a 50-row read that finds nothing to fix.
  /// [_scheduleReconcile] walks the whole window, so it both sets and clears
  /// this — a room drops out of the set as soon as its messages heal.
  final _roomsWithLockedMessages = <String>{};

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
    _roomsWithLockedMessages.clear();
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

  /// True when a locally-stored message is still a placeholder rather than
  /// real content, and is therefore worth retrying.
  ///
  /// Delegates to [VaultCipher.isPlaceholderText] rather than testing for a
  /// leading 🔒, which matters now that a pending retry renders as ⏳: a
  /// prefix test would read the waiting bubble as real content, so the
  /// snapshot carrying the sender's answer would be classified as metadata
  /// and the repaired message would never be decrypted. That helper also
  /// covers placeholder strings written by earlier builds, which is what lets
  /// already-broken bubbles heal.
  static bool _isLocked(MessageModel m) =>
      VaultCipher.isPlaceholderText(m.text);

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

      // Note any sign that the other participant's app is actually running. A
      // resend request can only be answered by a live app, so this is what lets
      // an exhausted retry round reopen the moment they come back. Without it, a
      // sender who happened to be away for the round's ~60 seconds left the
      // bubble broken until the next app launch.
      final peerSeen = _notePeerLiveness(snapshot, currentUserId);
      if (peerSeen && _roomsWithLockedMessages.contains(roomId)) {
        // Drop the reconcile throttle for this room. The sweep is where an
        // *older* locked message gets another chance, and making the user wait
        // out the remainder of a 60-second window is the difference between the
        // bubble filling in while they watch and it looking broken still.
        //
        // Only for rooms that actually have something to repair: an ordinary
        // back-and-forth would otherwise pay a full-window sweep per message.
        _lastReconcile.remove(roomId);
      }

      if (changed.isEmpty) {
        _scheduleReconcile(roomId, snapshot, currentUserId);
        return;
      }

      // Answer any recipient who told us they couldn't decrypt one of our
      // messages. Deliberately before the content/metadata split below: our
      // own outgoing message reads fine locally, so it always lands in
      // `metadata`, where nothing would ever look at it again. Fire-and-forget
      // — re-encrypting must never delay an incoming bubble.
      _maybeServeResendRequests(roomId, changed, currentUserId);

      final localMessages =
          await store.getMessagesByIds(changed.map((d) => d.id).toList());
      final localMap = {for (final m in localMessages) m.id: m};

      final content = <DocumentSnapshot<Map<String, dynamic>>>[];
      final metadata = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final doc in changed) {
        final localMsg = localMap[doc.id];
        if (localMsg == null || _isLocked(localMsg)) {
          content.add(doc);
          if (localMsg != null) _roomsWithLockedMessages.add(roomId);
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
          // Don't rewrite a placeholder with the *same* placeholder — that's a
          // pointless write and a pointless rebuild of the message list.
          //
          // A placeholder whose text changed is a different matter: 🔒 turning
          // into ⏳ is the user-visible signal that a repair is under way, and
          // suppressing it would leave them staring at "ask sender to resend"
          // while we are in fact already asking.
          final unchanged = wasLocked &&
              _isLocked(decrypted) &&
              decrypted.text == localMsg.text;
          if (!unchanged) {
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

  // ─── Resend protocol (sender side) ──────────────────────────────────────
  //
  // A recipient that can't decrypt one of our messages publishes
  //
  //   retryRequests: ["<uid>:<deviceId>#<attempt>", …]
  //
  // onto that message's document (see ChatService._requestResend). We are the
  // only party who can answer: the server stores ciphertext and nothing else,
  // so no Cloud Function could re-encrypt this even if we put one there.
  //
  // The answer is to tear down our session with that specific device and
  // encrypt the stored plaintext again. With the session gone, libsignal runs
  // a fresh X3DH and produces a PreKeySignalMessage — which decrypts on the
  // other end no matter how far its ratchet had drifted, because
  // SessionBuilder.processV3 archives whatever state it was holding instead of
  // requiring the two chains to line up. That is what makes this a genuine
  // repair rather than another roll of the dice.

  /// Feeds [ChatService.notePeerActivity], which reopens an exhausted resend
  /// round. Returns true if anything was noted.
  ///
  /// Two signals, both meaning "their app was running seconds ago":
  ///  • a message of theirs arriving for the first time;
  ///  • one of ours turning delivered or read — those fields are written by the
  ///    recipient and nobody else.
  ///
  /// Over-triggering is cheap (an extra round of up to three requests, bounded
  /// by ChatService's lifetime ceiling, and only ever for a message that is
  /// genuinely unreadable). Under-triggering is not: it is what left the
  /// reported bubbles broken. So these conditions are deliberately generous.
  bool _notePeerLiveness(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    String currentUserId,
  ) {
    var noted = false;
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.removed) continue;
      final data = change.doc.data();
      if (data == null) continue;
      // Type-tested rather than cast. This method runs before everything else
      // in _processRoomSnapshot, so a `as String?` throwing on a malformed
      // document would abort the entire pass and sync no messages at all.
      final senderId = data['senderId'];
      if (senderId is! String || senderId.isEmpty) continue;

      if (senderId != currentUserId) {
        // Their message. Only `added` counts: a `modified` on a document they
        // authored is normally *our* write — a read receipt, or the retry
        // request itself — and treating that as their liveness would let one
        // request reopen the next round immediately and defeat the cap.
        if (change.type == DocumentChangeType.added) {
          ChatService.notePeerActivity(senderId);
          noted = true;
        }
        continue;
      }

      // Our own message, changed by someone. `added` here is just the cold-start
      // backfill of our own history, which says nothing about them.
      if (change.type != DocumentChangeType.modified) continue;
      final status = data['status'];
      final isReceipt = status == 'delivered' || status == 'read' ||
          status is bool; // legacy isRead payloads
      if (!isReceipt) continue;
      final receiverId = data['receiverId'];
      if (receiverId is! String || receiverId.isEmpty) continue;
      ChatService.notePeerActivity(receiverId);
      noted = true;
    }
    return noted;
  }

  /// Synchronous filter over a snapshot's change set.
  ///
  /// Almost every snapshot contains no requests at all, and the real work — a
  /// device-id lookup, a plaintext read, an X3DH handshake and a write per
  /// requester — must never sit on the path of an ordinary incoming message.
  void _maybeServeResendRequests(
    String roomId,
    List<DocumentSnapshot<Map<String, dynamic>>> docs,
    String currentUserId,
  ) {
    final withRequests = <DocumentSnapshot<Map<String, dynamic>>>[];
    for (final doc in docs) {
      final data = doc.data();
      if (data == null) continue;
      if (data['senderId'] != currentUserId) continue;
      final reqs = data['retryRequests'];
      if (reqs is List && reqs.isNotEmpty) withRequests.add(doc);
    }
    if (withRequests.isEmpty) return;
    unawaited(_serveResendRequests(roomId, withRequests, currentUserId));
  }

  Future<void> _serveResendRequests(
    String roomId,
    List<DocumentSnapshot<Map<String, dynamic>>> docs,
    String currentUserId,
  ) async {
    try {
      final myDeviceId = await DeviceIdentityService().getDeviceId();
      if (myDeviceId == null) return;
      final store = await PlaintextStore.instance();

      for (final doc in docs) {
        final data = doc.data();
        if (data == null) continue;

        // Only the device that produced the original ciphertext holds the
        // plaintext and the identity the requester was addressing. Our other
        // devices see the same request and correctly ignore it.
        if ((data['senderDeviceId'] as int?) != myDeviceId) continue;

        // Group by requester, keeping the highest attempt. Earlier attempts
        // stay in the array — arrayUnion only ever adds — and honouring each
        // one separately would mean three handshakes to deliver one message.
        final byAddress = <String, List<String>>{};
        final highest = <String, int>{};
        for (final tag in (data['retryRequests'] as List).whereType<String>()) {
          final hash = tag.lastIndexOf('#');
          if (hash <= 0) continue;
          final address = tag.substring(0, hash);
          final n = int.tryParse(tag.substring(hash + 1));
          if (n == null) continue;
          (byAddress[address] ??= <String>[]).add(tag);
          if (n > (highest[address] ?? 0)) highest[address] = n;
        }

        for (final address in highest.keys) {
          await _serveOneResend(
            roomId: roomId,
            doc: doc,
            address: address,
            attempt: highest[address]!,
            tags: byAddress[address]!,
            selfUid: currentUserId,
            myDeviceId: myDeviceId,
            store: store,
          );
        }
      }
    } catch (e) {
      // Best-effort by design. The requester keeps its own attempt cap, so a
      // failure here costs at most a retry, never a loop.
      if (kDebugMode) {
        debugPrint('[SyncService] Serving resend requests failed: $e');
      }
    }
  }

  Future<void> _serveOneResend({
    required String roomId,
    required DocumentSnapshot<Map<String, dynamic>> doc,
    required String address,
    required int attempt,
    required List<String> tags,
    required String selfUid,
    required int myDeviceId,
    required PlaintextStore store,
  }) async {
    final colon = address.lastIndexOf(':');
    if (colon <= 0) return;
    final requesterUid = address.substring(0, colon);
    final requesterDeviceId = int.tryParse(address.substring(colon + 1));
    if (requesterDeviceId == null || requesterDeviceId <= 0) return;

    // Firestore's rules let any participant write to a message document —
    // that is what read receipts need — so the guarantee that a request can't
    // make us encrypt our plaintext for some arbitrary uid has to be enforced
    // here. Only the message's recipient, or one of our own other devices,
    // may ask.
    final receiverId = doc.data()?['receiverId'] as String?;
    if (requesterUid != receiverId && requesterUid != selfUid) {
      if (kDebugMode) {
        debugPrint('[SyncService] Ignoring resend request from non-participant '
            '$requesterUid on ${doc.id}');
      }
      return;
    }
    // This device asking itself. Can't happen through ChatService, but a
    // handshake with our own address would corrupt our own session state, so
    // it is worth one line to make it impossible.
    if (requesterUid == selfUid && requesterDeviceId == myDeviceId) return;

    // Idempotency. Firestore re-emits a document on every change — including
    // the change we are about to make — so without this the arrival of our own
    // answer would kick off another identical round.
    if (attempt <= await store.servedRetryAttempt(doc.id, address)) return;

    final payload = await ChatService.instance.ownPayloadFor(selfUid, doc.id);
    if (payload == null) {
      // Plaintext is gone from the memo, SQLite and the vault. Leave the
      // request in place rather than clearing it: a future install that
      // restores the vault with the user's PIN can still answer it.
      if (kDebugMode) {
        debugPrint('[SyncService] No plaintext to resend for ${doc.id}');
      }
      return;
    }

    final signal = SignalService.instance;
    final serverMsg = MessageModel.fromFirestore(doc);

    // Rebuild the wire payload the receive path expects rather than shipping
    // the stored one as-is. They are not the same shape: the stored copy has
    // no `type` (so a resent reaction would render as a message instead of
    // being applied) and does carry `localFilePath`, which is a path on *this*
    // device and meaningless on the other end.
    final wire = <String, dynamic>{
      'type': serverMsg.type.name,
      'text': (payload['text'] as String?) ?? '',
      if (payload['mediaUrl'] != null) 'mediaUrl': payload['mediaUrl'],
      if (payload['audioDuration'] != null)
        'audioDuration': payload['audioDuration'],
      if (payload['reactionTargetMessageId'] != null)
        'reactionTargetMessageId': payload['reactionTargetMessageId'],
      if (payload['statusReplyOwnerId'] != null) ...{
        'statusReplyOwnerId': payload['statusReplyOwnerId'],
        'statusReplyItemId': payload['statusReplyItemId'],
        'statusReplyOwnerName': payload['statusReplyOwnerName'],
        'statusReplyOwnerPhotoUrl': payload['statusReplyOwnerPhotoUrl'],
        'statusReplyType': payload['statusReplyType'],
        'statusReplyText': payload['statusReplyText'],
        'statusReplyMediaUrl': payload['statusReplyMediaUrl'],
        'statusReplyCaption': payload['statusReplyCaption'],
        'statusReplyBackgroundColor': payload['statusReplyBackgroundColor'],
      },
    };

    try {
      // Force a fresh look at the requester's published keys before we
      // handshake. This is the hook that detects a peer reinstall: the
      // identity-change check lives in the device-id fetch, and it is what
      // clears our pinned trust so the new identity key is accepted instead of
      // throwing UntrustedIdentityException below.
      SignalService.invalidateDeviceCache(requesterUid);
      await signal.listDeviceIdsCached(requesterUid);

      // Tear down, then encrypt: `encrypt` calls `ensureSession`, which with
      // no session present performs the X3DH that makes this a prekey message.
      await signal.resetSessionFor(requesterUid, requesterDeviceId);
      final env = await signal.encrypt(
        requesterUid,
        requesterDeviceId,
        Uint8List.fromList(utf8.encode(jsonEncode(wire))),
      );
      // One Keystore write covering both the teardown and the new session. If
      // this were left to the debounce, a kill in the next three seconds would
      // strand us with a session the requester has already ratcheted.
      await signal.stores.flush();

      if (!env.isPreKeyMessage && kDebugMode) {
        // Not fatal — it still decrypts if their chain happens to line up —
        // but it means the reset didn't take, so the repair is no longer
        // guaranteed and that is worth seeing in the logs.
        debugPrint('[SyncService] Resend for ${doc.id} is not a prekey message');
      }

      // Publish the new envelope and retire the request in a single write.
      // `merge: true` deep-merges nested maps, so this adds our entry under
      // `envelopes` without disturbing the ones addressed to other devices —
      // an overwrite would strip every other recipient's copy.
      await _firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .doc(doc.id)
          .set({
        'envelopes': {address: env.toMap()},
        'retryRequests': FieldValue.arrayRemove(tags),
      }, SetOptions(merge: true));

      await store.markRetryServed(doc.id, address, attempt);
      if (kDebugMode) {
        debugPrint('[SyncService] Served resend #$attempt for ${doc.id} '
            'to $address');
      }
    } catch (e) {
      // Includes UntrustedIdentityException, which can still fire if the
      // requester's key rotated between the fetch above and the handshake.
      // Swallowed: their next attempt gets a fresh look at the new key.
      if (kDebugMode) {
        debugPrint('[SyncService] Resend for ${doc.id} to $address failed: $e');
      }
    }
  }

  /// Background self-heal over the full 50-doc window.
  ///
  /// The fast path above only inspects changed documents, so on its own it
  /// can't notice that an *older* message is still a placeholder (the vault was
  /// unlocked since it was stored) or that its media never finished
  /// downloading. This walks the whole window to fix those, but runs off the
  /// sync queue and is never awaited, so it can't delay a new message.
  /// Throttled per room, and skipped while one is in flight.
  ///
  /// This is also what heals bubbles that were already broken before the
  /// resend protocol existed. It needs no resend logic of its own: retrying a
  /// locked message means calling [ChatService.decryptForRendering], and that
  /// is where the request is published, under its own attempt cap and backoff.
  /// The 60-second throttle here doubles as the sweep's rate limit.
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
        var stillLocked = false;

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

          // This sweep is the only place that sees the whole window, so it is
          // also where [_roomsWithLockedMessages] gets its answer. A null
          // decrypt means the fast path would store a placeholder too.
          if (decrypted == null || _isLocked(decrypted)) stillLocked = true;

          // Store a placeholder whose text differs from what's on disk, not
          // just a successful decrypt. Two cases need it: a legacy 🔒 row
          // whose repair is now in flight should show ⏳, and a message the
          // fast path never stored at all should get a bubble rather than
          // silently not existing.
          if (decrypted != null &&
              (!_isLocked(decrypted) || decrypted.text != localMsg?.text)) {
            repaired.add(decrypted);
            if (decrypted.mediaUrl != null && decrypted.localFilePath == null) {
              _triggerMediaDownload(decrypted, roomId);
            }
          }

          if (++processed % 3 == 0) {
            await Future.delayed(const Duration(milliseconds: 4));
          }
        }

        // Self-correcting: a room leaves the set as soon as everything in its
        // window reads, so it stops costing a sweep on every peer message.
        if (stillLocked) {
          _roomsWithLockedMessages.add(roomId);
        } else {
          _roomsWithLockedMessages.remove(roomId);
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

  /// The bubble shown for a message this device can't read yet.
  ///
  /// Uses the shared constant so it can't drift from what ChatService writes —
  /// it did drift once, and the copy here was invisible to
  /// [VaultCipher.isPlaceholderText], so any bubble stamped by this path was
  /// treated as real content and never retried.
  MessageModel _lockedPlaceholder(MessageModel msg) {
    return msg.copyWith(
      text: VaultCipher.undecryptablePlaceholderText,
    );
  }
}
