import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/services/crypto/device_identity_service.dart';
import 'package:video_chat_app/services/crypto/plaintext_store.dart';
import 'package:video_chat_app/services/crypto/signal_service.dart';
import 'package:video_chat_app/services/crypto/vault_cipher.dart';
import 'package:video_chat_app/services/fcm_service.dart';
import 'package:video_chat_app/services/gamification_service.dart';

class ChatService {
  static final ChatService instance = ChatService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FCMService _fcmService = FCMService();
  final DeviceIdentityService _deviceIdentity = DeviceIdentityService();
  final String _chatRoomsCollection = 'chatRooms';
  final String _messagesCollection = 'messages';

  // The placeholder we write to chatRoom.lastMessage — the room doc is
  // visible to the server, so we never put plaintext there.
  static const String _encryptedPreviewPlaceholder = '🔒 Encrypted message';

  // What we render in place of an E2EE message this install can't decrypt.
  //
  // Two states, because most failures are recoverable and it would be wrong
  // to tell the user to go chase the sender while we are still repairing it
  // ourselves:
  //
  //  • [_pendingRetryPlaceholderText] — a resend request is in flight.
  //  • [_undecryptablePlaceholderText] — a round of [_maxResendAttempts] went
  //    unanswered and nothing suggests the sender is reachable. The bubble can
  //    still go back to "waiting" later: see [evaluateResendRound], which opens
  //    a fresh round when they relaunch, when the peer shows signs of life, or
  //    after [_resendRoundCooldown].
  //
  // Either way we render a bubble instead of dropping the message, so the
  // user knows something arrived rather than watching read receipts climb
  // against messages they never saw.
  static const String _undecryptablePlaceholderText =
      VaultCipher.undecryptablePlaceholderText;
  static const String _pendingRetryPlaceholderText =
      VaultCipher.pendingRetryPlaceholderText;

  /// Build a placeholder MessageModel for E2EE messages we can't decrypt.
  ///
  /// Keeps the message's real schemaVersion. It used to force 1 so that
  /// downstream code would skip re-decrypt attempts — but that also made the
  /// placeholder permanent, because a v1 message returns early from
  /// [decryptForRendering] and can therefore never be retried. Suppressing
  /// *pointless* retries is [_decryptFailures]' job, and unlike a schema
  /// downgrade it expires; [VaultCipher.isPlaceholderText] is what tells
  /// callers this text is a placeholder rather than real content.
  MessageModel _lockedPlaceholder(MessageModel raw) => raw.copyWith(
        text: _undecryptablePlaceholderText,
      );

  // ─── Local send outbox (WhatsApp-style optimistic UI) ───────────────────
  //
  // The Firestore stream is the source of truth for delivered messages, but
  // it can't render a bubble until the commit lands — that's 100–800ms on a
  // good network, longer on a flaky one. The outbox plugs that gap: the
  // moment sendMessage() is called we build a MessageModel with
  // status=sending, drop it into _outbox, and emit it through every active
  // getMessages() stream so the bubble appears in the same frame as the
  // tap. The actual encrypt + Firestore commit runs in the background; on
  // success the entry is removed (Firestore re-delivers the canonical
  // message with status=sent), on failure the entry is updated to
  // status=failed so the user sees an error indicator and can retry.

  // All decrypted message bodies (both incoming and outgoing) live in a
  // local sqflite DB via PlaintextStore. The Firestore stream is the
  // transport, the local DB is the source of truth for rendering — the
  // same architecture WhatsApp uses.

  // ─── Streak state ───────────────────────────────────────────────────────
  // Streaks are owned entirely by the server-side engine and read through
  // StreakRepository. ChatService neither reads nor writes streak state on
  // the send path — the message document itself is the participation event.

  // ─── Per-room send lock ───────────────────────────────────────────────
  // Prevents race conditions when the user taps Send rapidly. Only one
  // _commitMessage can be in-flight per room at a time; subsequent sends
  // queue up and execute sequentially. Without this, two concurrent sends
  // could both read stale streak state or produce duplicate message IDs.
  final Map<String, Future<void>> _sendLocks = {};
  // Max time a send can wait for the lock + commit before timing out
  // (marks the message as failed so the user can retry).
  static const _sendTimeout = Duration(seconds: 30);

  /// Returns true iff the peer has at least one device with a published
  /// key bundle (i.e. they've upgraded to an E2EE-capable build).
  ///
  /// Stale-while-revalidate. Cached entries are returned instantly; if the
  /// cached value is older than 5 minutes we kick off a background refresh
  /// but DO NOT block the send. The previous 60-second hard TTL caused a
  /// periodic latency spike — once a minute the first send to a peer
  /// synchronously queried Firestore before encryption could begin, which
  /// is exactly the "sometimes the send is slow, sometimes it's instant"
  /// symptom users perceive.
  static final Map<String, ({DateTime at, bool has})> _peerBundleCache = {};
  static const _peerBundleFreshWindow = Duration(minutes: 5);
  static final Set<String> _peerBundleRefreshInFlight = <String>{};

  Future<bool> _peerHasKeyBundle(String peerUid) async {
    final hit = _peerBundleCache[peerUid];
    if (hit != null) {
      if (DateTime.now().difference(hit.at) > _peerBundleFreshWindow) {
        _refreshPeerBundle(peerUid);
      }
      return hit.has;
    }
    // Try the SignalService device-id cache before hitting Firestore.
    // encryptForUser() will call _listDeviceIds() on the same collection
    // anyway, so reusing its cache saves a redundant Firestore query
    // (~300-500ms) on the first message after cold start. The prewarm
    // path populates this cache at app open, so on a warm path this
    // resolves synchronously from memory.
    try {
      final devices = await SignalService.instance.listDeviceIdsCached(peerUid);
      final has = devices.isNotEmpty;
      _peerBundleCache[peerUid] = (at: DateTime.now(), has: has);
      return has;
    } catch (_) {
      // SignalService not initialized yet — fall back to direct query.
      return _fetchPeerBundle(peerUid);
    }
  }

  Future<bool> _fetchPeerBundle(String peerUid) async {
    final snap = await _firestore
        .collection('users')
        .doc(peerUid)
        .collection('devices')
        .where('keyBundle', isNull: false)
        .limit(1)
        .get();
    final has = snap.docs.isNotEmpty;
    _peerBundleCache[peerUid] = (at: DateTime.now(), has: has);
    return has;
  }

  void _refreshPeerBundle(String peerUid) {
    if (_peerBundleRefreshInFlight.contains(peerUid)) return;
    _peerBundleRefreshInFlight.add(peerUid);
    // ignore: discarded_futures
    _fetchPeerBundle(peerUid).whenComplete(() {
      _peerBundleRefreshInFlight.remove(peerUid);
    }).catchError((_) => false);
  }

  // ─── Payload cache pre-warm ──────────────────────────────────────────────
  // On every chat open we bulk-load both the local SQLite store AND the
  // Firestore message vault into _payloadMemo in ONE pass before the message
  // subscription starts. This means the first Firestore snapshot resolves
  // synchronously via memo (no awaits per-message), which is how WhatsApp
  // renders instantly even on a reinstall.
  //
  // The Future is memoised per uid so concurrent opens or rapid navigation
  // between chats never trigger duplicate network reads.
  static final Map<String, Future<void>> _preWarmSqliteCache = {};
  static final Map<String, Future<void>> _preWarmVaultCache = {};

  Future<void> _preWarmSqlite(String uid) {
    return _preWarmSqliteCache.putIfAbsent(uid, () => _doPreWarmSqlite(uid));
  }

  Future<void> _preWarmVault(String uid) {
    return _preWarmVaultCache.putIfAbsent(uid, () => _doPreWarmVault(uid));
  }

  /// Public entry point to trigger both SQLite and Firestore Vault pre-warming
  /// in parallel. Called by SyncService during initialization.
  Future<void> preWarmCaches(String uid) async {
    await Future.wait([
      _preWarmSqlite(uid),
      _preWarmVault(uid),
    ]);
  }

  /// Drop the per-uid pre-warm cache AND the process-wide decrypted-
  /// payload memo so the next chat open re-derives every preview from
  /// disk/vault. Called after VaultCipher unlocks (so previously-skipped
  /// vault reads can complete) and after VaultCipher.reset (so wiped
  /// history doesn't keep rendering from RAM).
  static void invalidatePreWarm(String uid) {
    _preWarmSqliteCache.remove(uid);
    _preWarmVaultCache.remove(uid);
    _payloadMemo.clear();
    // Also drop the failure cooldowns. Unlocking the vault is exactly the
    // event that can turn a previous failure into a success, so keeping the
    // 20-second gate would make the re-emit below a no-op for the bubbles
    // that most need it.
    _decryptFailures.clear();
    // Notify any active chat / chat-list stream subscribers so they can
    // re-decrypt their currently-displayed snapshot without waiting for
    // the next Firestore change. Without this, the home screen card and
    // open chat would stay on the "🔒 can't decrypt" placeholder until
    // some unrelated Firestore event (a typing indicator, a new message)
    // happened to fire.
    _vaultReadyNotifier.add(null);
  }

  // Broadcast tick the moment the vault becomes usable (post-unlock,
  // post-reinstall). Subscribers re-run their decrypt pass against the
  // most recent raw Firestore snapshot they've cached.
  static final StreamController<void> _vaultReadyNotifier =
      StreamController<void>.broadcast();

  Future<void> _doPreWarmSqlite(String uid) async {
    // 1. SQLite bulk-load (local IO, ~10-50ms) — populates memo from prior
    //    decryption sessions on the same install. Bounded to the 500 most-
    //    recent messages so load time stays sub-50ms even on heavy accounts.
    try {
      final store = await PlaintextStore.instance();
      final all = await store.getAllMessagePayloads();
      for (final e in all.entries) {
        // Skip anything an older build persisted as a placeholder — see
        // [_addToMemo]. This is the path where it would matter most, because a
        // poisoned row survives every restart.
        if (isPlaceholderPayload(e.value)) continue;
        _payloadMemo.putIfAbsent(e.key, () => e.value);
      }
    } catch (_) {}
  }

  Future<void> _doPreWarmVault(String uid) async {
    // 2. Firestore vault bulk-read (one network query, not N) — restores
    //    history on reinstall where SQLite was wiped but vault survived.
    //    Bounded to the 500 most-recent docs; older messages fall through to
    //    the per-message vault fallback in decryptForRendering.
    //    Decrypts run on a background isolate via decryptDocsBatch so the
    //    main thread stays free for rendering during cold start.
    if (!VaultCipher.instance.isReady) return;
    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection(_vaultCollection)
          .orderBy('createdAt', descending: true)
          .limit(500)
          .get();
      final pending = <String, Map<String, dynamic>>{};
      for (final doc in snap.docs) {
        if (!_payloadMemo.containsKey(doc.id)) {
          pending[doc.id] = doc.data();
        }
      }
      if (pending.isNotEmpty) {
        final results = await VaultCipher.instance.decryptDocsBatch(pending);
        results.removeWhere((_, v) => isPlaceholderPayload(v));
        _payloadMemo.addAll(results);
      }
    } catch (_) {}
  }

  // ─── Firestore message vault (cross-install backup) ─────────────────────
  // Decrypted plaintext payloads are mirrored to
  //   users/{uid}/msgVault/{messageId}
  // so that a fresh install can recover message history even after the local
  // PlaintextStore (SQLite) and Signal session state are both wiped. Vault
  // writes are fire-and-forget: the local SQLite store is the primary cache
  // and vault failures are non-fatal.
  static const _vaultCollection = 'msgVault';

  Future<void> _saveToVault(
      String uid, String messageId, Map<String, dynamic> payload) async {
    // Never vault a placeholder. The vault is the last line of recovery and
    // survives reinstalls, so a placeholder in it would outlive every other
    // copy and keep answering "can't decrypt" long after a repair was possible.
    if (isPlaceholderPayload(payload)) return;
    // Drop the write rather than leak plaintext if the vault key isn't
    // available yet. PlaintextStore still has the message locally; the
    // post-unlock migration in HomeScreen flushes anything missing.
    final enc = await VaultCipher.instance.encryptPayload(payload);
    if (enc == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection(_vaultCollection)
          .doc(messageId)
          .set({...enc, 'createdAt': FieldValue.serverTimestamp()});
    } catch (_) {}
  }

  /// Recovers a payload **we** produced, for a message we sent, from whichever
  /// tier still has it: the in-memory memo, SQLite, then the cross-install
  /// vault.
  ///
  /// This is what lets SyncService answer a recipient's resend request. Only
  /// meaningful for our own outgoing messages — for a received message the
  /// caller wants [decryptForRendering], which also advances the ratchet.
  Future<Map<String, dynamic>?> ownPayloadFor(
      String selfUid, String messageId) async {
    final memo = _payloadMemo[messageId];
    if (memo != null) return memo;

    final store = await PlaintextStore.instance();
    final cached = await store.get(messageId);
    if (cached != null) {
      _addToMemo(messageId, cached);
      return cached;
    }

    // Reinstalled since sending, or the send-path SQLite write was lost.
    final vaulted = await _loadFromVault(selfUid, messageId);
    if (vaulted != null) {
      _addToMemo(messageId, vaulted);
      unawaited(store.save(messageId, vaulted));
    }
    return vaulted;
  }

  Future<Map<String, dynamic>?> _loadFromVault(
      String uid, String messageId) async {
    // Await any in-flight bulk prewarm first. If it's already completed, this
    // returns instantly. This prevents firing 100+ concurrent individual
    // Firestore reads when the bulk load is already fetching them or has
    // completed.
    final prewarm = _preWarmVaultCache[uid];
    if (prewarm != null) {
      await prewarm;
      final memo = _payloadMemo[messageId];
      if (memo != null) return memo;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection(_vaultCollection)
          .doc(messageId)
          .get();
      if (!doc.exists) return null;
      final payload = await VaultCipher.instance.decryptDoc(doc.data()!);
      // Treat a vaulted placeholder as a miss. Nothing should write one — only
      // successful decrypts and our own outgoing messages are vaulted — but a
      // placeholder here would be worse than elsewhere: the vault outlives
      // reinstalls, so it would suppress the repair on every future install
      // too, not just this one.
      if (payload != null && isPlaceholderPayload(payload)) return null;
      return payload;
    } catch (_) {
      return null;
    }
  }

  /// Resolves a Firestore MessageModel into its rendered form.
  ///
  /// • v1 (legacy plaintext) messages pass through unchanged.
  /// • v2 (E2EE) messages are answered from the local PlaintextStore. We
  ///   only call into libsignal on a cache miss, then persist the result
  ///   so the next render is a pure SQLite hit.
  /// • If the envelope isn't addressed to this device (e.g. after reinstall
  ///   with a new device ID) or the ratchet can't decrypt, we check the
  ///   Firestore message vault — a per-user cross-install plaintext backup —
  ///   before returning null.
  // In-memory cache of decrypted payloads keyed by message id. Firestore
  // re-emits the entire message list on every read receipt / typing change,
  // so without this we'd hit SQLite N times per snapshot. Memory cost is
  // small — a Map<String, dynamic> per message — and it's wiped on signOut
  // along with the rest of the crypto state.
  // In-memory cache of decrypted payloads keyed by message id. Firestore
  // re-emits the entire message list on every read receipt / typing change,
  // so without this we'd hit SQLite N times per snapshot.
  //
  // LRU eviction: LinkedHashMap preserves insertion order, so when the cache
  // exceeds [_memoMaxSize] we drop the oldest entries (FIFO). On a heavy user
  // with 1000+ messages across chats this prevents unbounded memory growth
  // — each entry is a Map<String, dynamic> that can be several KB for media
  // messages.
  static const _memoMaxSize = 500;

  /// Decrypted payloads keyed by message id. **Successes only.**
  ///
  /// A failure must never be memoized here. This map is consulted before
  /// everything else in [decryptForRendering], so an entry holding the
  /// placeholder text is indistinguishable from real content: it survives for
  /// the life of the process and short-circuits every mechanism that exists to
  /// repair the message — the reconcile sweep, the post-unlock vault re-emit,
  /// and the resend protocol's own follow-up decrypt. That is what turned a
  /// single transient failure into a bubble that stayed broken for hours.
  /// Rate-limiting retries is [_decryptFailures]' job.
  static final Map<String, Map<String, dynamic>> _payloadMemo = {};

  /// Adds an entry to [_payloadMemo] with automatic LRU eviction.
  /// When the cache exceeds [_memoMaxSize], the oldest 100 entries are
  /// removed (FIFO order via LinkedHashMap insertion ordering).
  ///
  /// Placeholders are rejected outright. The memo is consulted before every
  /// other source in [decryptForRendering] and is never invalidated by a
  /// resend, so one placeholder in here is a message that can never be
  /// repaired for the rest of the session. Nothing is *supposed* to offer one —
  /// the failure path deliberately doesn't memoize — but this is the single
  /// chokepoint where that assumption can be enforced instead of assumed.
  static void _addToMemo(String key, Map<String, dynamic> value) {
    if (isPlaceholderPayload(value)) return;
    _payloadMemo[key] = value;
    if (_payloadMemo.length > _memoMaxSize) {
      final keysToRemove = _payloadMemo.keys.take(100).toList();
      for (final k in keysToRemove) {
        _payloadMemo.remove(k);
      }
    }
  }

  /// True if [payload] holds one of our placeholder strings rather than real
  /// content — i.e. it was written by a build that persisted failures, and
  /// treating it as content would make the message permanently unreadable.
  @visibleForTesting
  static bool isPlaceholderPayload(Map<String, dynamic> payload) =>
      VaultCipher.isPlaceholderText((payload['text'] as String?) ?? '');

  /// Test seams for the [_payloadMemo] chokepoint. The no-negative-caching
  /// invariant is the one that turned a transient failure into an all-day
  /// broken bubble, so it is worth asserting directly rather than trusting the
  /// call sites to keep honouring it.
  @visibleForTesting
  static void memoizeForTest(String key, Map<String, dynamic> value) =>
      _addToMemo(key, value);

  @visibleForTesting
  static Map<String, dynamic>? memoEntryForTest(String key) =>
      _payloadMemo[key];

  // ─── Decrypt-failure throttling ─────────────────────────────────────────
  //
  // Firestore re-emits every message in a room on any change to it — a
  // typing indicator, a read receipt, a delivery tick. Re-running libsignal
  // for a message we just failed to decrypt is expensive (a failed decrypt
  // walks up to 40 archived ratchet states) and floods the log, so we skip
  // it for a short cooldown and render the placeholder we last chose.
  //
  // The critical difference from the negative memo this replaces: the entry
  // is keyed on the *ciphertext we failed on* and it expires. The instant a
  // resend lands, `envFingerprint` no longer matches and we decrypt
  // immediately instead of sitting on a stale placeholder; and even with no
  // resend, the cooldown lapses so reconcile passes and vault unlocks still
  // get a genuine retry.
  static const Duration _decryptCooldown = Duration(seconds: 20);
  static final Map<String, ({DateTime at, int envFingerprint, String text})>
      _decryptFailures = {};

  static void _noteDecryptFailure(
      String messageId, int envFingerprint, String text) {
    _decryptFailures[messageId] =
        (at: DateTime.now(), envFingerprint: envFingerprint, text: text);
    if (_decryptFailures.length > _memoMaxSize) {
      for (final k in _decryptFailures.keys.take(100).toList()) {
        _decryptFailures.remove(k);
      }
    }
  }

  /// Cheap identity for an envelope's ciphertext, so we can tell "the same
  /// message failed again" from "the sender re-encrypted it for us".
  static int _envFingerprint(Map<String, dynamic> env) =>
      Object.hash(env['ct'], env['pk']);

  // Dedup set for decrypt-skip log messages. Without this, the same
  // message ID would log every time a Firestore emission re-triggers
  // decryptForRendering (typing, read receipts, etc.).
  static final Set<String> _loggedDecryptSkips = {};

  /// Decrypts already in flight, keyed by message id.
  ///
  /// Two callers racing the same document is routine on launch: SyncService's
  /// fast path walks the backlog while the chat screen's own
  /// [getMessagesPaginated] walks the same documents. Neither has written
  /// anything yet, so both miss the memo *and* the plaintext store, and both
  /// reach libsignal.
  ///
  /// The per-address lock in [SignalService] stops that from corrupting the
  /// ratchet, but on its own it would still be user-visible: the loser arrives
  /// after the winner's decrypt has consumed the counter, gets
  /// DuplicateMessageException, and [classifyDecryptFailure] reads that as "ask
  /// the sender to resend". The bubble shows ⏳ and a resend goes out for a
  /// message we just decrypted and stored. Sharing one Future makes the
  /// duplicate free instead of a false failure.
  static final Map<String, Future<MessageModel?>> _inFlightDecrypts = {};

  Future<MessageModel?> decryptForRendering(MessageModel msg, String selfUid) {
    if (msg.schemaVersion < 2) return Future.value(msg);

    // In-memory hot path — no I/O, resolves on the next microtask.
    final memo = _payloadMemo[msg.id];
    if (memo != null) return Future.value(_applyPayload(msg, memo));

    // A caller that joins an in-flight decrypt gets the model built from the
    // *other* caller's snapshot of this document. Those differ only in
    // transport metadata (delivery ticks, read receipts), both callers persist
    // what they receive, and the next snapshot corrects it — a much better
    // trade than decrypting one ciphertext twice.
    final joined = _inFlightDecrypts[msg.id];
    if (joined != null) return joined;

    final work = _decryptForRenderingUncached(msg, selfUid);
    _inFlightDecrypts[msg.id] = work;
    return work.whenComplete(() {
      // Identity-checked: `whenComplete` runs as a microtask, so a fresh call
      // for this id could already have installed its own entry.
      if (_inFlightDecrypts[msg.id] == work) _inFlightDecrypts.remove(msg.id);
    });
  }

  Future<MessageModel?> _decryptForRenderingUncached(
      MessageModel msg, String selfUid) async {
    final store = await PlaintextStore.instance();

    final cachedPayload = await store.get(msg.id);
    // A placeholder on disk is not an answer. `save()` uses insertOrIgnore, so
    // one persisted by an older build would otherwise be returned here forever
    // and shadow every repair — fall through and try to decrypt properly.
    if (cachedPayload != null && !isPlaceholderPayload(cachedPayload)) {
      _addToMemo(msg.id, cachedPayload);
      return _applyPayload(msg, cachedPayload);
    }

    // Need to actually decrypt. Find an envelope addressed to this device.
    final envelopes = msg.envelopes;
    final deviceId = await _deviceIdentity.getDeviceId();

    // No envelope for this device — happens after reinstall (new device ID)
    // or if the sender's fan-out didn't include us. Fall back to the
    // Firestore message vault which was populated when we first decrypted
    // this message on a previous install.
    final env = (envelopes == null || envelopes.isEmpty || deviceId == null)
        ? null
        : envelopes['$selfUid:$deviceId'];

    if (env == null) {
      final vaultPayload = await _loadFromVault(selfUid, msg.id);
      if (vaultPayload != null) {
        _addToMemo(msg.id, vaultPayload);
        // Fire-and-forget: memo is the source of truth for rendering;
        // SQLite is only for crash/restart recovery.
        unawaited(store.save(msg.id, vaultPayload));
      }
      return vaultPayload != null ? _applyPayload(msg, vaultPayload) : null;
    }

    // Recently failed on this exact ciphertext — don't re-run libsignal for
    // every read receipt in the room, just re-render what we showed last
    // time. A resend changes the ciphertext, so this never delays a repair.
    final envFingerprint = _envFingerprint(env);
    final lastFailure = _decryptFailures[msg.id];
    if (lastFailure != null &&
        lastFailure.envFingerprint == envFingerprint &&
        DateTime.now().difference(lastFailure.at) < _decryptCooldown) {
      return _applyPayload(msg, <String, dynamic>{'text': lastFailure.text});
    }

    try {
      final pt = await SignalService.instance.decrypt(
        msg.senderId,
        msg.senderDeviceId ?? 1,
        EncryptedEnvelope.fromMap(env),
      );
      final payload = jsonDecode(utf8.decode(pt)) as Map<String, dynamic>;
      _addToMemo(msg.id, payload);

      final chatRoomId = getChatRoomId(msg.senderId, msg.receiverId);

      // Handle reaction processing E2EE client-side
      if (payload['type'] == 'reaction') {
        final targetId = payload['reactionTargetMessageId'] as String?;
        final emoji = payload['text'] as String?;
        if (targetId != null && emoji != null) {
          unawaited(store.addReaction(
            targetMessageId: targetId,
            chatRoomId: chatRoomId,
            userId: msg.senderId,
            emoji: emoji,
          ));
          // Earn points for the receiver of the reaction (the owner of target message)
          unawaited(() async {
            final list = await store.getMessagesByIds([targetId]);
            if (list.isNotEmpty && list.first.senderId == selfUid) {
              await GamificationService.instance.earnPoints(selfUid, 5);
            }
          }());
        }
      }

      // ── Durability barrier ────────────────────────────────────────────
      // Two things must be on disk before this bubble is allowed on screen:
      // the plaintext we just recovered, and the ratchet advance that
      // consuming this ciphertext caused. Neither used to be awaited — the
      // save was fire-and-forget and the ratchet only got a 3-second
      // debounce — so for ~3s after every received message a force-stop,
      // low-memory kill or crash lost both.
      //
      // Losing the ratchet advance is the worse half: our receive chain
      // falls behind the sender's, so every *subsequent* message from them
      // fails verifyMac too. One kill in that window is what produces a
      // whole run of undecryptable bubbles rather than a single one.
      //
      // Order matters. Plaintext first means a crash between the two writes
      // can only cost us a ratchet advance, which the resend protocol
      // repairs automatically. Flushing first and crashing would lose the
      // message itself, permanently — nothing can rebuild a plaintext that
      // was never written and whose ciphertext is now spent.
      await store.save(msg.id, payload);
      await SignalService.instance.stores.flush();

      // Cosmetic / cross-install only — safe to leave in the background.
      if (payload['type'] != 'reaction') {
        unawaited(store.saveRoomPreview(
          chatRoomId: chatRoomId,
          messageId: msg.id,
          text: (payload['text'] as String?) ?? '',
        ));
      }
      unawaited(_saveToVault(selfUid, msg.id, payload));
      _decryptFailures.remove(msg.id);
      return _applyPayload(msg, payload);
    } catch (e) {
      // NOTE: this used to delete the Signal session for anything that
      // smelled like a broken session. That made things strictly worse. A
      // deleted session cannot decrypt any of the messages already in flight
      // from that peer either, and the peer is never told, so they keep
      // ratcheting forward from a state we just threw away — one bad message
      // became a permanently dead conversation. The receive path now never
      // destroys session state; recovery is the sender's job, via the resend
      // request below. See SignalService.resetSessionFor.
      final failure = classifyDecryptFailure(e);

      if (failure.clearTrust) {
        // The one exception: the peer's identity key genuinely changed, so
        // the pin we hold can never verify anything they send again. Drop it
        // (not the session) so the resend's handshake is accepted.
        try {
          final addr =
              SignalProtocolAddress(msg.senderId, msg.senderDeviceId ?? 1);
          SignalService.instance.stores.identityStore.trustedKeys.remove(addr);
          SignalService.instance.stores.markDirty();
        } catch (_) {}
      }

      // Libsignal couldn't decrypt — try the vault before giving up.
      final vaultPayload = await _loadFromVault(selfUid, msg.id);
      if (vaultPayload != null) {
        _addToMemo(msg.id, vaultPayload);
        unawaited(store.save(msg.id, vaultPayload));
        _decryptFailures.remove(msg.id);
        return _applyPayload(msg, vaultPayload);
      }

      // Log once per message to avoid flooding the console on every
      // Firestore re-emission (typing, read receipt, etc.).
      if (kDebugMode && _loggedDecryptSkips.add(msg.id)) {
        debugPrint('decrypt failed for ${msg.id} (${e.runtimeType}): $e');
      }

      // Ask the sender to re-encrypt, and tell the user we're on it rather
      // than telling them to go chase the sender themselves. The bubble only
      // hardens into "ask sender to resend" once the requests go unanswered.
      final pending = failure.requestResend
          ? await _requestResend(
              msg: msg,
              selfUid: selfUid,
              selfDeviceId: deviceId,
              store: store,
            )
          : false;

      final lockedPayload = <String, dynamic>{
        'text': pending
            ? _pendingRetryPlaceholderText
            : _undecryptablePlaceholderText,
      };
      // Deliberately NOT _addToMemo — see [_payloadMemo].
      _noteDecryptFailure(
          msg.id, envFingerprint, lockedPayload['text'] as String);
      return _applyPayload(msg, lockedPayload);
    }
  }

  /// What to do about a decrypt failure.
  ///
  /// `requestResend` — ask the sender to re-encrypt over a fresh session.
  /// `clearTrust` — drop the pinned identity key for this peer device.
  ///
  /// Only reached once the plaintext store *and* the vault have both missed,
  /// so "we already have this message" is never a possibility here.
  ///
  /// Note what this function deliberately cannot express: deleting the session.
  /// An earlier build tore down the ratchet on `InvalidMessageException`, which
  /// escalated one unreadable message into a permanently dead conversation —
  /// the peer was never told, so they kept ratcheting forward against a session
  /// we had thrown away. Recovery is the sender's job now; see [_requestResend].
  @visibleForTesting
  static ({bool requestResend, bool clearTrust}) classifyDecryptFailure(
      Object e) {
    // Already decrypted once — the ratchet consumed this counter and will
    // never accept this ciphertext again.
    //
    // The intuitive reading is "we've seen it, don't ask again", and that is
    // correct for the ordinary case: Firestore re-emits every message on every
    // room change, and those re-emissions return from the plaintext store at
    // the top of decryptForRendering without ever reaching libsignal.
    //
    // Getting here instead means the ratchet moved past this message while no
    // copy of the plaintext survives anywhere — retention pruning, a failed
    // SQLite write. A resend still repairs that, because the answer arrives as
    // a PreKeySignalMessage on a brand-new session and never touches the
    // exhausted counter. It also can't storm: this branch is unreachable
    // whenever the plaintext exists, and the attempt cap bounds it regardless.
    if (e is DuplicateMessageException) {
      return (requestResend: true, clearTrust: false);
    }

    // The peer's identity key changed — a reinstall, or an attack. Either
    // way nothing they send verifies against the key we pinned, so clear the
    // pin and let their fresh handshake establish a new one.
    //
    // Matched with `is` rather than by message: this exception has no
    // toString() override, so it stringifies to "Instance of '…'" and a
    // text match would silently never fire.
    if (e is UntrustedIdentityException) {
      return (requestResend: true, clearTrust: true);
    }

    // Everything else is a resend candidate:
    //  • InvalidMessageException — MAC mismatch / no matching ratchet state.
    //    Usually our chain fell behind the sender's. libsignal already tried
    //    all 40 archived states before throwing, so there is nothing local
    //    left to attempt.
    //  • NoSessionException — no session at all; only the sender can start
    //    one that decrypts (a PreKeySignalMessage).
    //  • InvalidKeyIdException — the prekey the sender used is gone from our
    //    store. They must re-handshake against a key we still hold.
    //  • AssertionError / ArgumentError / TypeError / RangeError — corrupt or
    //    truncated ciphertext. Same remedy: get a fresh copy.
    //
    // InvalidMessageException is not exported from the package barrel, so it
    // has to be matched by runtime type name rather than `is` — but it lands
    // in this default branch anyway, which is why the check is a comment and
    // not code.
    return (requestResend: true, clearTrust: false);
  }

  // ─── Resend protocol (receiver side) ────────────────────────────────────
  //
  // When a message won't decrypt, the only party that can repair it is the
  // sender: they hold the plaintext and can re-encrypt it over a brand-new
  // session. So we publish a request onto the message document itself —
  //
  //   retryRequests: ["<ourUid>:<ourDeviceId>#<attempt>", …]
  //
  // — which the sender sees immediately, because SyncService already keeps a
  // live listener on the last 50 messages of every room. They answer by
  // adding an envelope addressed to us; because they tear their session down
  // first, it arrives as a PreKeySignalMessage, and those decrypt no matter
  // how far our ratchet had drifted (SessionBuilder archives our old state
  // instead of requiring it to line up).
  //
  // Deliberately not a Cloud Function and not a new collection. The server
  // holds only ciphertext, so it could not re-encrypt anything even if asked;
  // and message docs are already writable by both participants — that is what
  // read receipts use — so this needs no security-rules change.
  static const int _maxResendAttempts = 3;
  static const Duration _resendBackoff = Duration(seconds: 30);

  /// How long after the final attempt of a round we keep saying "waiting"
  /// before admitting defeat and telling the user to ask the sender.
  static const Duration _resendGrace = Duration(minutes: 2);

  /// A round of [_maxResendAttempts] runs its course in about a minute, and it
  /// can only be answered by a sender whose app is running. An earlier build
  /// applied the cap to the *lifetime* of the message, so if the sender simply
  /// wasn't running during that one minute the bubble was broken forever — even
  /// with both people online and chatting minutes later, nothing ever asked
  /// again. The cap now applies per round, and an exhausted round reopens on any
  /// evidence that asking again could work: a new app session, the peer showing
  /// signs of life ([notePeerActivity]), or simply enough time passing.
  static const Duration _resendRoundCooldown = Duration(minutes: 20);

  /// Minimum gap between rounds opened because the peer showed signs of life.
  ///
  /// Their activity counter advances on every message they send, so a burst of
  /// ten messages while our bubble is still broken would otherwise reopen ten
  /// rounds in as many seconds and spend the whole [_maxResendTotalAttempts]
  /// ceiling in under a minute. A relaunch is exempt — the user paces that
  /// themselves — and the cooldown path is already twenty minutes.
  static const Duration _resendRoundFloor = Duration(minutes: 2);

  /// Absolute ceiling across every round. Rounds only open on a real signal, so
  /// this is not what normally stops us — it exists so a message whose sender is
  /// gone for good cannot grow `retryRequests` without bound across hundreds of
  /// launches. Reaching it is the one case that still hardens permanently, and
  /// by then the message has been asked for across at least five separate
  /// rounds, which in practice means the sender no longer holds the plaintext.
  static const int _maxResendTotalAttempts = 15;

  /// Identifies this launch. A round recorded under a different value belongs to
  /// a previous process and never blocks a new one — reopening on relaunch is
  /// the highest-yield signal available, because a sender who was away during
  /// the original 60-second round is far more likely to be reachable now.
  static final int _appSessionId = DateTime.now().microsecondsSinceEpoch;

  /// Per-peer liveness counter, bumped by [notePeerActivity]. Deliberately in
  /// memory only: a restart resets it to zero, but a restart already reopens
  /// every round through [_appSessionId], so nothing is lost by not persisting.
  static final Map<String, int> _peerActivity = <String, int>{};

  // Requests mid-write, so a burst of snapshot re-emissions can't fire the
  // same one several times before the first write lands.
  static final Set<String> _resendInFlight = <String>{};

  /// Records that [uid]'s app has shown signs of life — they sent something, or
  /// they marked something of ours delivered/read. Called from
  /// `SyncService._notePeerLiveness`.
  ///
  /// This is the signal the old lifetime cap had no way to express. A resend
  /// request can only be answered by a running app, so "the peer is running
  /// right now" is precisely the moment it becomes worth asking again.
  static void notePeerActivity(String uid) {
    if (uid.isEmpty) return;
    _peerActivity[uid] = (_peerActivity[uid] ?? 0) + 1;
  }

  @visibleForTesting
  static int peerActivityForTest(String uid) => _peerActivity[uid] ?? 0;

  /// Whether a fresh resend request may go out now, given the recorded state.
  ///
  /// Pure, and separated from the Firestore write, because this is the decision
  /// that determines whether a broken bubble ever repairs itself at all.
  ///
  /// `allow` — publish a request now. `waiting` — only meaningful when `allow`
  /// is false; true means keep the "⏳ waiting" wording because an answer could
  /// still arrive, false means let the bubble harden into "ask sender to
  /// resend". `roundStart` — what to record as the current round's origin,
  /// which is [state]'s own value mid-round and its total attempt count when a
  /// new round is being opened.
  @visibleForTesting
  static ({bool allow, bool waiting, int roundStart}) evaluateResendRound({
    required ({
      int attempts,
      int atMs,
      int roundStart,
      int sessionId,
      int generation
    })? state,
    required int sessionId,
    required int generation,
    required DateTime now,
  }) {
    if (state == null) return (allow: true, waiting: false, roundStart: 0);

    if (state.attempts >= _maxResendTotalAttempts) {
      return (allow: false, waiting: false, roundStart: state.roundStart);
    }

    final last = DateTime.fromMillisecondsSinceEpoch(state.atMs);
    final sinceLast = now.difference(last);
    final inRound = state.attempts - state.roundStart;

    if (inRound < _maxResendAttempts) {
      // Mid-round. Honour the backoff so a burst of snapshot re-emissions
      // can't turn one broken bubble into three writes a second.
      if (sinceLast < _resendBackoff) {
        return (allow: false, waiting: true, roundStart: state.roundStart);
      }
      return (allow: true, waiting: false, roundStart: state.roundStart);
    }

    // Round exhausted. Reopen only on evidence that asking again could work.
    final newSession = state.sessionId != sessionId;
    final peerSeen =
        state.generation != generation && sinceLast >= _resendRoundFloor;
    final cooledDown = sinceLast >= _resendRoundCooldown;
    if (newSession || peerSeen || cooledDown) {
      // The new round starts where the lifetime count currently stands, so the
      // next wire tag is strictly greater than every tag already published.
      return (allow: true, waiting: false, roundStart: state.attempts);
    }

    // Nothing new to go on. Keep the "waiting" wording briefly so the round's
    // final request has a fair chance to be answered, then let it harden.
    //
    // Note that [_resendRoundFloor] and [_resendGrace] are both two minutes, so
    // a peer who *has* shown signs of life crosses the floor at the same moment
    // the grace expires: the round reopens rather than the bubble hardening.
    return (
      allow: false,
      waiting: sinceLast < _resendGrace,
      roundStart: state.roundStart,
    );
  }

  /// Publishes a resend request for [msg], subject to the round cap and
  /// backoff.
  ///
  /// Returns true while the bubble should still render as "waiting" — either
  /// we just asked, or the last ask is recent enough that the answer could
  /// still be in flight.
  Future<bool> _requestResend({
    required MessageModel msg,
    required String selfUid,
    required int? selfDeviceId,
    required PlaintextStore store,
  }) async {
    // Without a device id we can't tell the sender who to encrypt for.
    if (selfDeviceId == null) return false;

    final now = DateTime.now();
    final state = await store.getRetryState(msg.id);
    final generation = _peerActivity[msg.senderId] ?? 0;
    final round = evaluateResendRound(
      state: state,
      sessionId: _appSessionId,
      generation: generation,
      now: now,
    );
    if (!round.allow) return round.waiting;
    if (!_resendInFlight.add(msg.id)) return true;

    // Lifetime-monotonic, not per-round. The sender skips any tag number it has
    // already answered, and `arrayUnion` silently drops a duplicate string, so
    // restarting a new round at #1 would produce a request that never appears
    // on the document and would never be served if it did.
    final attempt = (state?.attempts ?? 0) + 1;
    try {
      final roomId = getChatRoomId(msg.senderId, msg.receiverId);
      await _firestore
          .collection(_chatRoomsCollection)
          .doc(roomId)
          .collection(_messagesCollection)
          .doc(msg.id)
          .update({
        'retryRequests':
            FieldValue.arrayUnion(['$selfUid:$selfDeviceId#$attempt']),
      });
      // Wake the sender's app if it isn't running. Strictly after the write
      // above — a sender woken before the request exists would find nothing to
      // serve — and strictly fire-and-forget, because the tag on the document is
      // the protocol and this is only an accelerator. A failure here must not
      // cost an attempt from the cap or take down the path that already works.
      unawaited(_publishResendWakeup(
        roomId: roomId,
        messageId: msg.id,
        senderId: msg.senderId,
        selfUid: selfUid,
        selfDeviceId: selfDeviceId,
        attempt: attempt,
      ));
      await store.saveRetryState(
        msg.id,
        attempts: attempt,
        atMs: now.millisecondsSinceEpoch,
        roundStart: round.roundStart,
        sessionId: _appSessionId,
        generation: generation,
      );
      if (kDebugMode) {
        debugPrint('[E2EE] resend request #$attempt for ${msg.id} '
            '(${attempt - round.roundStart}/$_maxResendAttempts this round) '
            '→ ${msg.senderId}');
      }
      return true;
    } catch (e) {
      // Offline, or the message was deleted. Nothing to show but the hard
      // failure; the reconcile sweep will try again later. Note that no
      // attempt was recorded, so this costs us nothing from the cap.
      if (kDebugMode) debugPrint('[E2EE] resend request failed: $e');
      return false;
    } finally {
      _resendInFlight.remove(msg.id);
    }
  }

  /// Asks the server to wake [senderId]'s app so it can serve the request we
  /// just published.
  ///
  /// A resend can only be answered by the sender's own device — the server holds
  /// no plaintext — so if their app isn't running, nothing happens until they
  /// next launch it. This doc triggers the `notifyResendRequest` Cloud Function,
  /// which sends them a silent data push.
  ///
  /// A collection of its own rather than a trigger on the message document:
  /// message docs are updated constantly by read receipts and delivery ticks, so
  /// watching them would invoke a Function a few times per message to do nothing
  /// almost every time. This one fires only on a real request.
  ///
  /// Nothing reads it back — see `firestore.rules`, where reads are denied
  /// outright.
  Future<void> _publishResendWakeup({
    required String roomId,
    required String messageId,
    required String senderId,
    required String selfUid,
    required int selfDeviceId,
    required int attempt,
  }) async {
    // Both guards are also enforced in firestore.rules, so a write that trips
    // one would be rejected anyway. Checking here saves the round trip.
    if (senderId.isEmpty || senderId == selfUid) return;
    try {
      // A deterministic id, not `add()`, so one request can mint at most one
      // push. With an auto id every write succeeded, which made the rules'
      // "is a retry actually pending" check a bound on *which* messages could be
      // woken but not on how many times — a modified client could have spun that
      // one legitimately-pending request into unlimited high-priority pushes.
      // Here the second write to the same id is an update, and updates are
      // denied. `attempt` is lifetime-monotonic (see above), so genuine retries
      // never collide with a spent id.
      //
      // The Function deliberately leaves these documents in place after sending:
      // deleting one would hand its id straight back and reopen the hole.
      final id = '${roomId}_${messageId}_${selfUid}_${selfDeviceId}_$attempt';
      await _firestore.collection('resendWakeups').doc(id).set({
        'roomId': roomId,
        'messageId': messageId,
        'senderId': senderId,
        'requesterId': selfUid,
        'deviceId': selfDeviceId,
        'attempt': attempt,
        'at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Swallowed on purpose. The request itself is already on the message
      // document, so the sender still repairs the bubble the moment they open
      // the app — this only makes it sooner.
      if (kDebugMode) debugPrint('[E2EE] resend wakeup failed: $e');
    }
  }

  /// Lifts the decrypted inner payload back onto a message whose Firestore doc
  /// carries nothing but ciphertext.
  ///
  /// Static and `@visibleForTesting` on purpose: it is pure (only `copyWith`),
  /// and every key it must consume is listed in [kMessageContentKeys]. A test
  /// asserts the two stay in sync, because a key that reaches here unread
  /// decrypts fine and then simply never renders — the quietest of the seven
  /// failure modes described on that constant.
  @visibleForTesting
  static MessageModel applyPayload(
      MessageModel msg, Map<String, dynamic> payload) {
    return msg.copyWith(
      text: (payload['text'] as String?) ?? '',
      mediaUrl: payload['mediaUrl'] as String?,
      audioDuration: payload['audioDuration'] as int?,
      reactionTargetMessageId: payload['reactionTargetMessageId'] as String?,
      statusReplyOwnerId: payload['statusReplyOwnerId'] as String?,
      statusReplyItemId: payload['statusReplyItemId'] as String?,
      statusReplyOwnerName: payload['statusReplyOwnerName'] as String?,
      statusReplyOwnerPhotoUrl: payload['statusReplyOwnerPhotoUrl'] as String?,
      statusReplyType: payload['statusReplyType'] as String?,
      statusReplyText: payload['statusReplyText'] as String?,
      statusReplyMediaUrl: payload['statusReplyMediaUrl'] as String?,
      statusReplyCaption: payload['statusReplyCaption'] as String?,
      statusReplyBackgroundColor:
          payload['statusReplyBackgroundColor'] as String?,
      linkPreviewUrl: payload['linkPreviewUrl'] as String?,
      linkPreviewTitle: payload['linkPreviewTitle'] as String?,
      linkPreviewDescription: payload['linkPreviewDescription'] as String?,
      linkPreviewSiteName: payload['linkPreviewSiteName'] as String?,
      linkPreviewImageBase64: payload['linkPreviewImageBase64'] as String?,
      replyToMessageId: payload['replyToMessageId'] as String?,
      replyToSenderId: payload['replyToSenderId'] as String?,
      replyToSenderName: payload['replyToSenderName'] as String?,
      replyToType: payload['replyToType'] as String?,
      replyToText: payload['replyToText'] as String?,
    );
  }

  MessageModel _applyPayload(MessageModel msg, Map<String, dynamic> payload) =>
      applyPayload(msg, payload);

  // Generate a unique chat room ID from two user IDs
  String getChatRoomId(String userId1, String userId2) {
    // Sort IDs to ensure consistency regardless of who initiates the chat
    List<String> ids = [userId1, userId2];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Create or get existing chat room
  Future<ChatRoom> getOrCreateChatRoom(
      String currentUserId, String otherUserId) async {
    String chatRoomId = getChatRoomId(currentUserId, otherUserId);

    DocumentSnapshot doc =
        await _firestore.collection(_chatRoomsCollection).doc(chatRoomId).get();

    if (doc.exists) {
      return ChatRoom.fromFirestore(doc);
    }

    // Create new chat room with initial lastMessageTime so it shows in queries
    ChatRoom newChatRoom = ChatRoom(
      id: chatRoomId,
      participants: [currentUserId, otherUserId],
      lastMessageTime: DateTime.now(),
      unreadCount: {currentUserId: 0, otherUserId: 0},
    );

    await _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .set(newChatRoom.toMap());

    return newChatRoom;
  }

  // Send a message
  Future<MessageModel> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
    String? senderName,
    MessageType type = MessageType.text,
    String? mediaUrl,
    String? statusReplyOwnerId,
    String? statusReplyItemId,
    String? statusReplyOwnerName,
    String? statusReplyOwnerPhotoUrl,
    String? statusReplyType,
    String? statusReplyText,
    String? statusReplyMediaUrl,
    String? statusReplyCaption,
    String? statusReplyBackgroundColor,
    int? audioDuration,
    String? localFilePath,
    String? reactionTargetMessageId,
    // ── Link preview (resolved by the SENDER, see LinkPreviewService) ────
    String? linkPreviewUrl,
    String? linkPreviewTitle,
    String? linkPreviewDescription,
    String? linkPreviewSiteName,
    String? linkPreviewImageBase64,
    // ── Reply quote (a self-contained snapshot, not a pointer) ───────────
    String? replyToMessageId,
    String? replyToSenderId,
    String? replyToSenderName,
    String? replyToType,
    String? replyToText,
  }) async {
    String chatRoomId = getChatRoomId(senderId, receiverId);
    final chatRoomRef =
        _firestore.collection(_chatRoomsCollection).doc(chatRoomId);

    // Firestore generates the doc id synchronously client-side, so we have a
    // stable id to publish into the outbox before any async work begins.
    DocumentReference messageRef =
        chatRoomRef.collection(_messagesCollection).doc();

    // ── Optimistic bubble: WhatsApp behaviour ───────────────────────────
    final optimistic = MessageModel(
      id: messageRef.id,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      type: type,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      mediaUrl: mediaUrl,
      audioDuration: audioDuration,
      statusReplyOwnerId: statusReplyOwnerId,
      statusReplyItemId: statusReplyItemId,
      statusReplyOwnerName: statusReplyOwnerName,
      statusReplyOwnerPhotoUrl: statusReplyOwnerPhotoUrl,
      statusReplyType: statusReplyType,
      statusReplyText: statusReplyText,
      statusReplyMediaUrl: statusReplyMediaUrl,
      statusReplyCaption: statusReplyCaption,
      statusReplyBackgroundColor: statusReplyBackgroundColor,
      localFilePath: localFilePath,
      reactionTargetMessageId: reactionTargetMessageId,
      linkPreviewUrl: linkPreviewUrl,
      linkPreviewTitle: linkPreviewTitle,
      linkPreviewDescription: linkPreviewDescription,
      linkPreviewSiteName: linkPreviewSiteName,
      linkPreviewImageBase64: linkPreviewImageBase64,
      replyToMessageId: replyToMessageId,
      replyToSenderId: replyToSenderId,
      replyToSenderName: replyToSenderName,
      replyToType: replyToType,
      replyToText: replyToText,
    );
    final ps = await PlaintextStore.instance();

    // If this is a reaction type message, do not save it as a new message bubble in outbox.
    // Instead, update the target message's reactions directly in local SQLite!
    if (type == MessageType.reaction && reactionTargetMessageId != null) {
      await ps.addReaction(
        targetMessageId: reactionTargetMessageId,
        chatRoomId: chatRoomId,
        userId: senderId,
        emoji: text,
      );
    } else {
      await ps.saveMessage(optimistic, chatRoomId);
    }

    try {
      // ── Per-room send lock: prevent races when user taps Send rapidly ──
      // Only one _commitMessage can be in-flight per room. Subsequent sends
      // wait for the previous one to finish, ensuring streak state, batch
      // ordering, and Firestore writes are serialized.
      final prevLock = _sendLocks[chatRoomId];
      final thisLock = Completer<void>();
      _sendLocks[chatRoomId] = thisLock.future;

      try {
        if (prevLock != null) await prevLock;

        final msg = await _commitMessage(
          chatRoomId: chatRoomId,
          chatRoomRef: chatRoomRef,
          messageRef: messageRef,
          senderId: senderId,
          receiverId: receiverId,
          text: text,
          senderName: senderName,
          type: type,
          mediaUrl: mediaUrl,
          audioDuration: audioDuration,
          statusReplyOwnerId: statusReplyOwnerId,
          statusReplyItemId: statusReplyItemId,
          statusReplyOwnerName: statusReplyOwnerName,
          statusReplyOwnerPhotoUrl: statusReplyOwnerPhotoUrl,
          statusReplyType: statusReplyType,
          statusReplyText: statusReplyText,
          statusReplyMediaUrl: statusReplyMediaUrl,
          statusReplyCaption: statusReplyCaption,
          statusReplyBackgroundColor: statusReplyBackgroundColor,
          localFilePath: localFilePath,
          reactionTargetMessageId: reactionTargetMessageId,
          linkPreviewUrl: linkPreviewUrl,
          linkPreviewTitle: linkPreviewTitle,
          linkPreviewDescription: linkPreviewDescription,
          linkPreviewSiteName: linkPreviewSiteName,
          linkPreviewImageBase64: linkPreviewImageBase64,
          replyToMessageId: replyToMessageId,
          replyToSenderId: replyToSenderId,
          replyToSenderName: replyToSenderName,
          replyToType: replyToType,
          replyToText: replyToText,
        ).timeout(_sendTimeout, onTimeout: () {
          throw TimeoutException(
              'Send timed out after ${_sendTimeout.inSeconds}s');
        });

        return msg;
      } finally {
        thisLock.complete();
        // Clean up if this is still the current lock
        if (_sendLocks[chatRoomId] == thisLock.future) {
          _sendLocks.remove(chatRoomId);
        }
      }
    } catch (e) {
      // Keep the bubble visible with a failed indicator so the user can
      // see what didn't go through.
      if (type != MessageType.reaction) {
        await ps.saveMessage(
            optimistic.copyWith(status: MessageStatus.failed), chatRoomId);
      }
      rethrow;
    }
  }

  Future<MessageModel> _commitMessage({
    required String chatRoomId,
    required DocumentReference chatRoomRef,
    required DocumentReference messageRef,
    required String senderId,
    required String receiverId,
    required String text,
    String? senderName,
    required MessageType type,
    String? mediaUrl,
    int? audioDuration,
    String? statusReplyOwnerId,
    String? statusReplyItemId,
    String? statusReplyOwnerName,
    String? statusReplyOwnerPhotoUrl,
    String? statusReplyType,
    String? statusReplyText,
    String? statusReplyMediaUrl,
    String? statusReplyCaption,
    String? statusReplyBackgroundColor,
    String? localFilePath,
    String? reactionTargetMessageId,
    String? linkPreviewUrl,
    String? linkPreviewTitle,
    String? linkPreviewDescription,
    String? linkPreviewSiteName,
    String? linkPreviewImageBase64,
    String? replyToMessageId,
    String? replyToSenderId,
    String? replyToSenderName,
    String? replyToType,
    String? replyToText,
  }) async {
    final sw = Stopwatch()..start();
    // ── E2EE: build the inner plaintext payload, encrypt for every device
    //         of receiver + sender's other devices (multi-device fan-out).
    // Run device-id lookup, peer-bundle check, AND in-flight prewarm join
    // in PARALLEL. The awaitPrewarm is the critical coordination: if
    // prewarmSessions from initState is still running, we piggyback on it
    // instead of firing redundant Firestore queries. When no prewarm is
    // running, awaitPrewarm returns instantly (zero cost).
    final setupResults = await Future.wait<dynamic>([
      _deviceIdentity.getDeviceId(),
      _peerHasKeyBundle(receiverId),
      SignalService.instance.awaitPrewarm(receiverId),
    ]);
    final senderDeviceId = setupResults[0] as int?;
    final canEncrypt = senderDeviceId != null && (setupResults[1] as bool);
    if (kDebugMode)
      debugPrint(
          '[SEND] setup: ${sw.elapsedMilliseconds}ms (canEncrypt=$canEncrypt)');

    Map<String, Map<String, dynamic>>? envelopes;
    String storedText = text;
    int schemaVersion = 1;

    if (canEncrypt) {
      // The payload that flows inside the Signal envelope. We can extend this
      // with media metadata, status reply blocks, etc. — nothing inside is
      // visible to the server.
      final payload = jsonEncode({
        'type': type.name,
        'text': text,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        if (audioDuration != null) 'audioDuration': audioDuration,
        if (reactionTargetMessageId != null)
          'reactionTargetMessageId': reactionTargetMessageId,
        if (statusReplyOwnerId != null) ...{
          'statusReplyOwnerId': statusReplyOwnerId,
          'statusReplyItemId': statusReplyItemId,
          'statusReplyOwnerName': statusReplyOwnerName,
          'statusReplyOwnerPhotoUrl': statusReplyOwnerPhotoUrl,
          'statusReplyType': statusReplyType,
          'statusReplyText': statusReplyText,
          'statusReplyMediaUrl': statusReplyMediaUrl,
          'statusReplyCaption': statusReplyCaption,
          'statusReplyBackgroundColor': statusReplyBackgroundColor,
        },
        // Sender-resolved OpenGraph metadata. It rides inside the envelope so
        // the receiver renders the card without ever contacting the link host —
        // no IP leak to whoever sent the link, and it still works offline.
        if (linkPreviewUrl != null) ...{
          'linkPreviewUrl': linkPreviewUrl,
          'linkPreviewTitle': linkPreviewTitle,
          'linkPreviewDescription': linkPreviewDescription,
          'linkPreviewSiteName': linkPreviewSiteName,
          'linkPreviewImageBase64': linkPreviewImageBase64,
        },
        if (replyToMessageId != null) ...{
          'replyToMessageId': replyToMessageId,
          'replyToSenderId': replyToSenderId,
          'replyToSenderName': replyToSenderName,
          'replyToType': replyToType,
          'replyToText': replyToText,
        },
      });

      try {
        final encs = await SignalService.instance.encryptForUser(
          senderUid: senderId,
          senderDeviceId: senderDeviceId,
          recipientUid: receiverId,
          plaintext: Uint8List.fromList(utf8.encode(payload)),
        );
        if (kDebugMode)
          debugPrint('[SEND] encrypt: ${sw.elapsedMilliseconds}ms');

        // A v2 message the recipient has no envelope for is the one shape we
        // must never commit: their `env == null` branch cannot tell it apart
        // from a genuine decrypt failure, so it renders as a permanent
        // placeholder with no error to classify and nothing to retry — we did
        // encrypt successfully, so no resend request would ever repair it.
        //
        // Tested against the recipient's own address rather than `encs.isEmpty`.
        // encryptForUser also fans out to the sender's other devices, so a
        // self-sync envelope on its own would satisfy an emptiness check while
        // leaving the recipient with nothing to open — reachable now that a
        // per-device encrypt failure is skipped instead of fatal. In a self-chat
        // the recipient *is* one of those other devices and the prefix still
        // matches, so the check is correct in both shapes.
        final reachable = encs.keys.any((k) => k.startsWith('$receiverId:'));
        if (!reachable) {
          throw StateError(
              'no envelope addressed to $receiverId (${encs.length} written)');
        }

        envelopes = encs.map((k, v) => MapEntry(k, v.toMap()));
        storedText = '';
        schemaVersion = 2;

        final outgoingPayload = <String, dynamic>{
          'text': text,
          'mediaUrl': mediaUrl,
          'audioDuration': audioDuration,
          if (reactionTargetMessageId != null)
            'reactionTargetMessageId': reactionTargetMessageId,
          'statusReplyOwnerId': statusReplyOwnerId,
          'statusReplyItemId': statusReplyItemId,
          'statusReplyOwnerName': statusReplyOwnerName,
          'statusReplyOwnerPhotoUrl': statusReplyOwnerPhotoUrl,
          'statusReplyType': statusReplyType,
          'statusReplyText': statusReplyText,
          'statusReplyMediaUrl': statusReplyMediaUrl,
          'statusReplyCaption': statusReplyCaption,
          'statusReplyBackgroundColor': statusReplyBackgroundColor,
          if (linkPreviewUrl != null) ...{
            'linkPreviewUrl': linkPreviewUrl,
            'linkPreviewTitle': linkPreviewTitle,
            'linkPreviewDescription': linkPreviewDescription,
            'linkPreviewImageBase64': linkPreviewImageBase64,
            'linkPreviewSiteName': linkPreviewSiteName,
          },
          if (replyToMessageId != null) ...{
            'replyToMessageId': replyToMessageId,
            'replyToSenderId': replyToSenderId,
            'replyToSenderName': replyToSenderName,
            'replyToType': replyToType,
            'replyToText': replyToText,
          },
          if (localFilePath != null) 'localFilePath': localFilePath,
        };
        // Populate the in-memory memo SYNCHRONOUSLY so the stream's
        // snapshot for our own message never needs any async lookup.
        _addToMemo(messageRef.id, outgoingPayload);

        // Fire SQLite persistence in the background — the in-memory memo
        // is already set, so rendering is instant. SQLite is only needed
        // for crash recovery / cold restart.
        final ps = await PlaintextStore.instance();
        unawaited(Future.wait([
          if (type != MessageType.reaction)
            ps.saveRoomPreview(
              chatRoomId: chatRoomId,
              messageId: messageRef.id,
              text: statusReplyOwnerId != null
                  ? 'Replied to status: $text'
                  : text,
            ),
          ps.save(messageRef.id, outgoingPayload),
        ]));
        // Mirror to the cross-install vault so the sender's history
        // survives a reinstall (new device ID loses the Firestore envelope
        // but can recover from the vault).
        unawaited(_saveToVault(senderId, messageRef.id, outgoingPayload));
      } catch (e) {
        // Fail the send rather than fall back to plaintext.
        //
        // `canEncrypt` is true here: the peer has published a key bundle, so
        // both sides believe this conversation is end-to-end encrypted. Falling
        // through would commit `storedText` — still the original body, because
        // the assignments above never ran — along with a plaintext room
        // preview, to Firestore in the clear. That is a downgrade the sender
        // never consented to and cannot see, and one an attacker can induce by
        // arranging for our encrypt to fail.
        //
        // Nothing is committed at this point: the memo, SQLite and vault writes
        // all sit after the envelopes exist, and the Firestore batch is built
        // below. sendMessage's catch marks the optimistic bubble
        // MessageStatus.failed and rethrows, so this surfaces as the same
        // visible failed send as a network error — bubble with a failed marker,
        // snackbar, text restored to the composer — instead of a message that
        // looks sent and went out unencrypted.
        //
        // Plaintext remains the path for a peer with no key bundle at all
        // (`canEncrypt == false`). Never encrypting to someone who cannot
        // decrypt is a different situation from declining to use encryption we
        // know they support.
        // ignore: avoid_print
        print('E2EE encrypt failed for $receiverId, refusing plaintext '
            'downgrade: $e');
        rethrow;
      }
    }

    MessageModel message = MessageModel(
      id: messageRef.id,
      senderId: senderId,
      receiverId: receiverId,
      text: storedText,
      type: type,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      mediaUrl: schemaVersion == 2 ? null : mediaUrl,
      statusReplyOwnerId: schemaVersion == 2 ? null : statusReplyOwnerId,
      statusReplyItemId: schemaVersion == 2 ? null : statusReplyItemId,
      statusReplyOwnerName: schemaVersion == 2 ? null : statusReplyOwnerName,
      statusReplyOwnerPhotoUrl:
          schemaVersion == 2 ? null : statusReplyOwnerPhotoUrl,
      statusReplyType: schemaVersion == 2 ? null : statusReplyType,
      statusReplyText: schemaVersion == 2 ? null : statusReplyText,
      statusReplyMediaUrl: schemaVersion == 2 ? null : statusReplyMediaUrl,
      statusReplyCaption: schemaVersion == 2 ? null : statusReplyCaption,
      statusReplyBackgroundColor:
          schemaVersion == 2 ? null : statusReplyBackgroundColor,
      audioDuration: schemaVersion == 2 ? null : audioDuration,
      schemaVersion: schemaVersion,
      senderDeviceId: senderDeviceId,
      envelopes: envelopes,
      localFilePath: localFilePath,
      reactionTargetMessageId: reactionTargetMessageId,
      // Same rule as every other content field: on v2 these are committed as
      // null so nothing but ciphertext reaches Firestore. A link preview would
      // otherwise hand the server the page title, and a reply quote a verbatim
      // snippet of the message being answered — both plaintext.
      linkPreviewUrl: schemaVersion == 2 ? null : linkPreviewUrl,
      linkPreviewTitle: schemaVersion == 2 ? null : linkPreviewTitle,
      linkPreviewDescription:
          schemaVersion == 2 ? null : linkPreviewDescription,
      linkPreviewSiteName: schemaVersion == 2 ? null : linkPreviewSiteName,
      linkPreviewImageBase64:
          schemaVersion == 2 ? null : linkPreviewImageBase64,
      replyToMessageId: schemaVersion == 2 ? null : replyToMessageId,
      replyToSenderId: schemaVersion == 2 ? null : replyToSenderId,
      replyToSenderName: schemaVersion == 2 ? null : replyToSenderName,
      replyToType: schemaVersion == 2 ? null : replyToType,
      replyToText: schemaVersion == 2 ? null : replyToText,
    );
    final lastMessagePreview = schemaVersion == 2
        ? _encryptedPreviewPlaceholder
        : (statusReplyOwnerId != null ? 'Replied to status: $text' : text);

    // Use batch write for consistency
    WriteBatch batch = _firestore.batch();

    // Add message
    batch.set(messageRef, message.toMap());

    // Update chat room details (only update preview fields if NOT a reaction)
    final roomUpdates = <String, dynamic>{
      'id': chatRoomId,
      'participants': [senderId, receiverId]..sort(),
    };

    if (type != MessageType.reaction) {
      roomUpdates['lastMessage'] = lastMessagePreview;
      roomUpdates['lastMessageTime'] = Timestamp.fromDate(message.timestamp);
      roomUpdates['lastMessageSenderId'] = senderId;
      roomUpdates['lastMessageStatus'] = MessageStatus.sent.name;
      roomUpdates['unreadCount.$senderId'] = FieldValue.increment(0);
      roomUpdates['unreadCount.$receiverId'] = FieldValue.increment(1);
    }

    batch.set(
      chatRoomRef,
      roomUpdates,
      SetOptions(merge: true),
    );

    if (kDebugMode)
      debugPrint('[SEND] pre-commit: ${sw.elapsedMilliseconds}ms');
    await batch.commit();
    if (kDebugMode)
      debugPrint(
          '[SEND] committed: ${sw.elapsedMilliseconds}ms — ${message.id}');

    // Award points, progress challenges, and unlock badges in a single
    // Firestore transaction — avoids the race condition where multiple
    // sequential transactions on the same user doc cause stale reads.
    unawaited(() async {
      try {
        await GamificationService.instance.handleMessageSent(
          userId: senderId,
          messageType:
              type.name, // 'text', 'audio', 'image', 'video', 'reaction'
        );
      } catch (e) {
        debugPrint('Error awarding gamification on commit: $e');
      }
    }());

    // Fire-and-forget the FCM push.
    unawaited(() async {
      try {
        // Skip notification for reaction message types
        if (type == MessageType.reaction) return;

        final displayName = senderName ?? 'Someone';
        final previewText = schemaVersion == 2 ? 'New message' : text;
        await _fcmService.sendMessageNotification(
          receiverId: receiverId,
          senderId: senderId,
          senderName: displayName,
          message: previewText,
          chatRoomId: chatRoomId,
        );
      } catch (e) {
        if (kDebugMode) debugPrint('Error sending message notification: $e');
      }
    }());

    return message;
  }

  // Get messages stream for a chat room.
  // Respects the per-user `clearedAt` timestamp written by "Clear all chats"
  // so only messages AFTER the clear time are shown to this user.
  //
  // Implementation note: the messages-subcollection subscription is started
  // ONCE and kept alive for the lifetime of the returned stream. The
  // chatRoom doc subscription (only used to track `clearedAt`) runs in
  // parallel — it can fire dozens of times per minute (typing indicators,
  // lastMessage updates, read-receipt status writes, etc.), but we keep
  // the messages stream untouched across those changes. Previously this
  // used `asyncExpand`, which tore down and rebuilt the entire messages
  // subscription on every chatRoom doc tick — that re-decryption pass was
  // the source of the visible "Today combines with previous list" reflow
  // the user reported after the outbox was introduced (sending a message
  // updates chatRoom.lastMessage as part of the same batch, which fired
  // the asyncExpand teardown right after the optimistic bubble appeared).
  /// Everything this user should actually see, in one place.
  ///
  /// Two independent per-user hides, both driven by server state so they
  /// survive a reinstall and reach the user's other devices:
  ///  • `clearedAt` — "clear chat", a timestamp on the room document;
  ///  • `deletedFor` — "delete for me", an array on the message document.
  ///
  /// A tombstone (`deletedForEveryone`) is deliberately **not** filtered here:
  /// the "This message was deleted" marker is the whole point of it.
  ///
  /// Static and `@visibleForTesting` because it is pure, and because the
  /// `deletedFor` half is easy to get subtly wrong — filtering on the peer's
  /// deletion instead of your own hides the message for the wrong person.
  @visibleForTesting
  static List<MessageModel> visibleMessages(
    List<MessageModel> messages,
    String currentUserId,
    DateTime? clearedAt,
  ) {
    return messages
        .where((m) => !m.isDeletedFor(currentUserId))
        .where((m) => clearedAt == null || m.timestamp.isAfter(clearedAt))
        .toList();
  }

  Stream<List<MessageModel>> getMessages(
      String currentUserId, String otherUserId) {
    final chatRoomId = getChatRoomId(currentUserId, otherUserId);
    final controller = StreamController<List<MessageModel>>();

    StreamSubscription<List<MessageModel>>? dbSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? chatRoomSub;

    DateTime? clearedAt;
    List<MessageModel> latestMessages = const [];

    void emit() {
      if (controller.isClosed) return;
      controller.add(visibleMessages(latestMessages, currentUserId, clearedAt));
    }

    controller.onListen = () async {
      try {
        final ps = await PlaintextStore.instance();
        dbSub = ps.watchMessages(chatRoomId).listen(
          (data) {
            latestMessages = data;
            emit();
          },
          onError: (e, st) {
            if (!controller.isClosed) controller.addError(e, st);
          },
        );

        // Listen to chatRoom document to track clearedAt (cleared chats)
        chatRoomSub = _firestore
            .collection(_chatRoomsCollection)
            .doc(chatRoomId)
            .snapshots()
            .listen((snap) {
          DateTime? newClearedAt;
          if (snap.exists) {
            final data = snap.data();
            final clearedAtMap = data?['clearedAt'] as Map<String, dynamic>?;
            final ts = clearedAtMap?[currentUserId];
            if (ts is Timestamp) newClearedAt = ts.toDate();
          }
          if (newClearedAt != clearedAt) {
            clearedAt = newClearedAt;
            emit();
          }
        });
      } catch (e, st) {
        if (!controller.isClosed) {
          controller.addError(e, st);
          controller.close();
        }
      }
    };

    controller.onCancel = () async {
      await dbSub?.cancel();
      await chatRoomSub?.cancel();
    };

    return controller.stream;
  }

  // Get paginated messages (for loading older messages)
  Future<List<MessageModel>> getMessagesPaginated({
    required String currentUserId,
    required String otherUserId,
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    String chatRoomId = getChatRoomId(currentUserId, otherUserId);

    Query query = _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    QuerySnapshot snapshot = await query.get();

    final raw = snapshot.docs
        .map((doc) => MessageModel.fromFirestore(doc))
        .toList()
        .reversed
        .toList();
    // Sequential, NOT Future.wait. Every message in this page shares one Signal
    // session per peer, and a decrypt is load → parse → mutate → store with no
    // lock anywhere in libsignal 0.7.1. Run them concurrently and they all load
    // the same pre-advance state, then the last store() wins — every other
    // message's ratchet advance and skipped-message-keys are silently lost, so
    // the session ends up at a position the sender never sent from and the rest
    // of the page fails to decrypt.
    //
    // It only shows up when a backlog exists, which is why it looked like "the
    // app was killed" caused it: a page of 20 fresh ciphertexts is the only time
    // this runs more than one real decrypt at once. The two sibling call sites
    // (fetchOlderMessages, SyncService._processRoomSnapshot) were already loops.
    final resolved = <MessageModel>[];
    for (final m in raw) {
      final r = await decryptForRendering(m, currentUserId);
      resolved.add(r ?? _lockedPlaceholder(m));
    }
    return resolved;
  }

  /// Fetches older messages from Firestore, decrypts them, and batch-saves them to SQLite.
  /// Returns the number of new older messages fetched.
  Future<int> fetchOlderMessages({
    required String chatRoomId,
    required DateTime beforeTimestamp,
    required String currentUserId,
    int limit = 50,
  }) async {
    final snap = await _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .where('timestamp', isLessThan: Timestamp.fromDate(beforeTimestamp))
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    if (snap.docs.isEmpty) return 0;

    final store = await PlaintextStore.instance();
    final toSave = <MessageModel>[];

    for (final doc in snap.docs) {
      final msg = MessageModel.fromFirestore(doc);
      final decrypted = await decryptForRendering(msg, currentUserId);
      toSave.add(decrypted ?? _lockedPlaceholder(msg));
    }

    if (toSave.isNotEmpty) {
      await store.saveMessagesBatch(toSave, chatRoomId);
    }

    return snap.docs.length;
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(
      String currentUserId, String otherUserId) async {
    String chatRoomId = getChatRoomId(currentUserId, otherUserId);

    // Get unread messages sent by the other user (capped at 200 to avoid
    // unbounded reads on rooms with thousands of unread messages — the batch
    // limit is 500 ops, so 200 leaves headroom for the chatRoom update).
    QuerySnapshot unreadMessages = await _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', whereIn: ['sent', 'delivered'])
        .limit(200)
        .get();

    if (unreadMessages.docs.isEmpty) return;

    WriteBatch batch = _firestore.batch();

    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'status': 'read'});
    }

    // Reset unread count. Only update lastMessageStatus if the last message
    // was sent by the OTHER user — otherwise we'd incorrectly show blue ticks
    // on our own outgoing message.
    final chatRoomDoc =
        await _firestore.collection(_chatRoomsCollection).doc(chatRoomId).get();
    final chatData = chatRoomDoc.data();
    final updateMap = <String, dynamic>{'unreadCount.$currentUserId': 0};
    if (chatData != null && chatData['lastMessageSenderId'] != currentUserId) {
      updateMap['lastMessageStatus'] = MessageStatus.read.name;
    }
    batch.update(
      _firestore.collection(_chatRoomsCollection).doc(chatRoomId),
      updateMap,
    );

    await batch.commit();
    print('Marked ${unreadMessages.docs.length} messages as read');
  }

  // Mark messages as delivered when receiver opens chat or receives them
  Future<void> markMessagesAsDelivered(
      String currentUserId, String otherUserId) async {
    String chatRoomId = getChatRoomId(currentUserId, otherUserId);

    // Get sent messages (not yet delivered) sent by the other user.
    // Capped at 200 to avoid unbounded reads — the batch limit is 500 ops.
    QuerySnapshot sentMessages = await _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'sent')
        .limit(200)
        .get();

    if (sentMessages.docs.isEmpty) return;

    WriteBatch batch = _firestore.batch();

    for (var doc in sentMessages.docs) {
      batch.update(doc.reference, {'status': 'delivered'});
    }

    // Update lastMessageStatus on chatRoom
    batch.update(
      _firestore.collection(_chatRoomsCollection).doc(chatRoomId),
      {'lastMessageStatus': MessageStatus.delivered.name},
    );

    await batch.commit();
    print('Marked ${sentMessages.docs.length} messages as delivered');
  }

  // Mark ALL messages as delivered across ALL chats when app opens.
  // Uses a collectionGroup query (one round-trip) instead of the previous
  // N+1 pattern (one read per chat room) to avoid hammering Firestore on
  // every app resume.
  //
  // Requires a composite collection-group index on the `messages` group:
  //   receiverId ASC, status ASC
  // Add to firestore.indexes.json if Firestore reports a missing index.
  Future<void> markAllMessagesAsDeliveredOnAppOpen(String currentUserId) async {
    try {
      final sentSnap = await _firestore
          .collectionGroup(_messagesCollection)
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'sent')
          .limit(500)
          .get();

      if (sentSnap.docs.isEmpty) return;

      // Group docs by chatRoomId so we can update lastMessageStatus per room.
      final byRoom =
          <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
      for (final doc in sentSnap.docs) {
        final chatRoomId = doc.reference.parent.parent?.id;
        if (chatRoomId == null) continue;
        byRoom.putIfAbsent(chatRoomId, () => []).add(doc);
      }

      // Commit in chunks ≤ 490 ops (Firestore hard limit is 500 per batch).
      const maxOps = 490;
      var batch = _firestore.batch();
      var opCount = 0;

      Future<void> maybeFlush() async {
        if (opCount >= maxOps) {
          await batch.commit();
          batch = _firestore.batch();
          opCount = 0;
        }
      }

      for (final entry in byRoom.entries) {
        for (final doc in entry.value) {
          batch.update(doc.reference, {'status': 'delivered'});
          opCount++;
          await maybeFlush();
        }
        batch.update(
          _firestore.collection(_chatRoomsCollection).doc(entry.key),
          {'lastMessageStatus': MessageStatus.delivered.name},
        );
        opCount++;
        await maybeFlush();
      }

      if (opCount > 0) await batch.commit();

      final total = sentSnap.docs.length;
      if (total > 0) print('Marked $total messages as delivered on app open');
    } catch (e) {
      print('Error marking messages as delivered on app open: $e');
    }
  }

  // Get chat rooms for a user.
  // Hides chats the user has cleared (via "Clear all chats") unless a new
  // message arrived after the clear timestamp — in that case the chat
  // reappears automatically (WhatsApp behaviour).
  Stream<List<ChatRoom>> getChatRooms(String userId) {
    // Manual controller so the chat list can be re-emitted on
    // vault-ready ticks as well as on every Firestore snapshot. Without
    // this, post-reinstall the home screen would stay on "🔒 Encrypted
    // message" / "🔒 can't decrypt" placeholders until some unrelated
    // chatRoom change happened to retrigger the asyncMap.
    final controller = StreamController<List<ChatRoom>>();
    QuerySnapshot<Map<String, dynamic>>? latestSnap;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? roomsSub;
    StreamSubscription<void>? vaultReadySub;

    Future<List<ChatRoom>> process(
        QuerySnapshot<Map<String, dynamic>> snapshot) async {
      final ps = await PlaintextStore.instance();
      final previews = await ps.getAllRoomPreviewsWithMeta();

      // Build the room list with cached previews applied, and collect
      // rooms whose cached preview is missing or stale.
      final chatRooms = <ChatRoom>[];
      final needsPreview = <int>[]; // indexes into chatRooms

      for (final doc in snapshot.docs) {
        final data = doc.data();
        var chatRoom = ChatRoom.fromMap(data, doc.id);

        final clearedAtMap = data['clearedAt'] as Map<String, dynamic>?;
        if (clearedAtMap != null && clearedAtMap[userId] != null) {
          final clearedAt = (clearedAtMap[userId] as Timestamp).toDate();
          if (chatRoom.lastMessageTime == null ||
              !chatRoom.lastMessageTime!.isAfter(clearedAt)) {
            continue;
          }
        }

        final localPreview = previews[chatRoom.id];
        final roomMs = chatRoom.lastMessageTime?.millisecondsSinceEpoch ?? 0;
        final isFresh =
            localPreview != null && localPreview.updatedAt + 1000 >= roomMs;

        if (isFresh) {
          chatRoom = ChatRoom(
            id: chatRoom.id,
            participants: chatRoom.participants,
            lastMessage: localPreview.text,
            lastMessageTime: chatRoom.lastMessageTime,
            lastMessageSenderId: chatRoom.lastMessageSenderId,
            lastMessageStatus: chatRoom.lastMessageStatus,
            unreadCount: chatRoom.unreadCount,
            streakCount: chatRoom.streakCount,
            lastInteractionDate: chatRoom.lastInteractionDate,
            lastSentAt: chatRoom.lastSentAt,
            previousStreakCount: chatRoom.previousStreakCount,
            streakBrokenAt: chatRoom.streakBrokenAt,
          );
        } else if (chatRoom.lastMessage == _encryptedPreviewPlaceholder ||
            localPreview != null) {
          needsPreview.add(chatRooms.length);
        }

        chatRooms.add(chatRoom);
      }

      // Decrypt stale previews with frame yields between batches.
      // Batch size is high (20) so most users see a single batch — identical
      // to the original parallel behavior. The frame yield only fires for
      // exceptional cases (20+ stale rooms after reinstall), where it
      // prevents the main-thread buildup that triggers ANR.
      if (needsPreview.isNotEmpty) {
        const batchSize = 20;
        for (int start = 0; start < needsPreview.length; start += batchSize) {
          final end = (start + batchSize).clamp(0, needsPreview.length);
          final batch = needsPreview.sublist(start, end);
          await Future.wait(batch.map((i) async {
            final room = chatRooms[i];
            try {
              final latest = await _firestore
                  .collection(_chatRoomsCollection)
                  .doc(room.id)
                  .collection(_messagesCollection)
                  .orderBy('timestamp', descending: true)
                  .limit(1)
                  .get();
              if (latest.docs.isEmpty) return;
              final msg = MessageModel.fromFirestore(latest.docs.first);
              final decrypted = await decryptForRendering(msg, userId);
              final text = decrypted == null
                  ? _undecryptablePlaceholderText
                  : (decrypted.text.isNotEmpty
                      ? decrypted.text
                      : (decrypted.mediaUrl != null ? 'Media' : ''));
              if (text.isEmpty) return;
              await ps.saveRoomPreview(
                chatRoomId: room.id,
                messageId: msg.id,
                text: text,
              );
              chatRooms[i] = ChatRoom(
                id: room.id,
                participants: room.participants,
                lastMessage: text,
                lastMessageTime: room.lastMessageTime,
                lastMessageSenderId: room.lastMessageSenderId,
                lastMessageStatus: room.lastMessageStatus,
                unreadCount: room.unreadCount,
                streakCount: room.streakCount,
                lastInteractionDate: room.lastInteractionDate,
                lastSentAt: room.lastSentAt,
                previousStreakCount: room.previousStreakCount,
                streakBrokenAt: room.streakBrokenAt,
              );
            } catch (_) {}
          }));
          if (start + batchSize < needsPreview.length) {
            await Future.delayed(Duration.zero);
          }
        }
      }

      // Sort locally to handle null lastMessageTime
      chatRooms.sort((a, b) {
        if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });

      return chatRooms;
    }

    Future<void> emitFromCachedSnap() async {
      final snap = latestSnap;
      if (snap == null) return;
      try {
        final rooms = await process(snap);
        if (!controller.isClosed) controller.add(rooms);
      } catch (e, st) {
        if (!controller.isClosed) controller.addError(e, st);
      }
    }

    controller.onListen = () {
      roomsSub = _firestore
          .collection(_chatRoomsCollection)
          .where('participants', arrayContains: userId)
          .snapshots()
          .listen((snap) {
        latestSnap = snap;
        // ignore: discarded_futures
        emitFromCachedSnap();
      }, onError: (e, st) {
        if (!controller.isClosed) controller.addError(e, st);
      });

      // Re-emit on vault-ready ticks so post-reinstall placeholders get
      // replaced with real previews the moment the user enters their PIN
      // — no need to wait for an unrelated chatRoom mutation.
      vaultReadySub = _vaultReadyNotifier.stream.listen((_) {
        // ignore: discarded_futures
        emitFromCachedSnap();
      });
    };
    controller.onCancel = () async {
      await roomsSub?.cancel();
      await vaultReadySub?.cancel();
    };
    return controller.stream;
  }

  // ─── Delete a message ─────────────────────────────────────────────────────
  //
  // Replaces an earlier `deleteMessage` that hard-deleted the document and had
  // no callers. A hard delete cannot work here: SyncService deliberately reads
  // a vanished document as "slid out of the 50-document window, not deleted",
  // so the recipient's bubble would stay on screen forever. And the rules only
  // permit deleting your *own* message, which rules out "delete for me" on one
  // the peer sent.

  /// How long after sending its sender may still delete a message for everyone,
  /// or edit it.
  ///
  /// Client-side only: a modified client could ignore it. `firestore.rules`
  /// enforces *who* may edit or tombstone a message (the sender-owned field list
  /// on the messages update rule) but not *when* — a window check there would
  /// have to read the document's own timestamp on every read receipt, and the
  /// cost of a bypass is cosmetic, so this stays a UI affordance.
  static const Duration editWindow = Duration(hours: 48);

  /// What both the bubble and the chat-list preview show for a tombstone.
  static const String deletedMessageText = 'This message was deleted';

  /// Whether a message sent at [sentAt] is still inside [editWindow].
  ///
  /// Static and pure so the boundary is testable without a clock or a Firestore
  /// handle, and so the menu can grey out Edit and "Delete for everyone" using
  /// the very same predicate the service enforces — one definition, not two that
  /// can drift apart.
  static bool withinEditWindow(DateTime sentAt, {DateTime? now}) =>
      (now ?? DateTime.now()).difference(sentAt) <= editWindow;

  /// "Delete for me" — hides the message for [currentUserId] on every device
  /// they own, permanently, leaving it untouched for the other participant.
  ///
  /// The flag lives on the server document, not just in the local database,
  /// because a local-only delete does not survive: SyncService backfills the
  /// newest 50 documents on a fresh install and would hand the message straight
  /// back, and a second device would never learn of it. Either participant may
  /// write this — the rules allow a non-sender to update a message document,
  /// which is how read receipts work — but only ever to add their *own* uid,
  /// which is why this is an `arrayUnion` of exactly one element and not a
  /// whole-list write.
  Future<void> deleteMessageForMe({
    required String currentUserId,
    required String otherUserId,
    required String messageId,
  }) async {
    final chatRoomId = getChatRoomId(currentUserId, otherUserId);
    final docRef = _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .doc(messageId);

    var serverHasDoc = true;
    try {
      await docRef.update({
        'deletedFor': FieldValue.arrayUnion([currentUserId]),
      });
    } on FirebaseException catch (e) {
      if (e.code != 'not-found') rethrow;
      // Never reached Firestore — still in the outbox, mesh-only, or already
      // removed by an older build. With no document to carry the flag, the
      // local row is the only copy there is, so deleting it outright is both
      // correct and durable.
      serverHasDoc = false;
    }

    final ps = await PlaintextStore.instance();
    if (serverHasDoc) {
      // Mirror locally so the bubble disappears now rather than when the
      // snapshot comes back. The read filter keys off this same field.
      final local = await ps.getMessagesByIds([messageId]);
      if (local.isNotEmpty) {
        final m = local.first;
        await ps.saveMessage(
          m.copyWith(deletedFor: [...m.deletedFor, currentUserId]),
          chatRoomId,
        );
      }
    } else {
      await ps.deleteMessage(messageId, chatRoomId);
    }

    await _recomputeRoomPreview(chatRoomId, currentUserId);
  }

  /// "Delete for everyone" — replaces the message with a tombstone for both
  /// participants and takes the content off the server.
  ///
  /// Sender-only, and only inside [editWindow]; callers should check
  /// [withinEditWindow] before offering it.
  ///
  /// A tombstone rather than a document delete, for the reason above. The
  /// content genuinely goes, though: this strips the ciphertext along with
  /// every plaintext content field a legacy v1 document may still carry, so
  /// what remains on the server is a marker and nothing else.
  Future<void> deleteMessageForEveryone({
    required String currentUserId,
    required String otherUserId,
    required String messageId,
  }) async {
    final chatRoomId = getChatRoomId(currentUserId, otherUserId);

    await _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .doc(messageId)
        .update({
      'deletedForEveryone': true,
      'text': '',
      'mediaUrl': null,
      'envelopes': FieldValue.delete(),
      'retryRequests': FieldValue.delete(),
      'reactions': FieldValue.delete(),
      // v1 documents carry these in the clear, including a base64 thumbnail.
      'linkPreviewUrl': FieldValue.delete(),
      'linkPreviewTitle': FieldValue.delete(),
      'linkPreviewDescription': FieldValue.delete(),
      'linkPreviewSiteName': FieldValue.delete(),
      'linkPreviewImageBase64': FieldValue.delete(),
      'replyToText': FieldValue.delete(),
    });

    final ps = await PlaintextStore.instance();

    // Our stored plaintext has to go too, or the resend protocol would happily
    // re-encrypt and serve a deleted message back to anyone who asks for it.
    // `forgetCachedPayload` rather than a bare `ps.delete`: the in-memory memo
    // is checked first and would otherwise still hold the text for the life of
    // the process.
    await forgetCachedPayload(messageId);

    final local = await ps.getMessagesByIds([messageId]);
    if (local.isNotEmpty) {
      // Not copyWith — see MessageModel.asTombstone. copyWith cannot null a
      // field out, so it would leave the media URL, the downloaded file and the
      // link-preview thumbnail on a row we just told the user was deleted.
      await ps.saveMessage(local.first.asTombstone(), chatRoomId);
    }

    await _recomputeRoomPreview(chatRoomId, currentUserId);
  }

  /// Re-derives the chat-list preview from the newest message still visible to
  /// [currentUserId]. Without this, deleting the most recent message leaves its
  /// text sitting in the chat list.
  Future<void> _recomputeRoomPreview(
      String chatRoomId, String currentUserId) async {
    try {
      final ps = await PlaintextStore.instance();
      final visible =
          visibleMessages(await ps.getMessages(chatRoomId), currentUserId, null);
      if (visible.isEmpty) return;

      final newest = visible.reduce(
          (a, b) => b.timestamp.isAfter(a.timestamp) ? b : a);
      final text = newest.deletedForEveryone
          ? deletedMessageText
          : (newest.text.isNotEmpty
              ? newest.text
              : (newest.mediaUrl != null ? 'Media' : ''));
      if (text.isEmpty) return;

      await ps.saveRoomPreview(
        chatRoomId: chatRoomId,
        messageId: newest.id,
        text: text,
      );
    } catch (e) {
      // Cosmetic: a stale preview is not worth failing a delete over.
      if (kDebugMode) debugPrint('[ChatService] preview recompute failed: $e');
    }
  }

  // ─── Edit a message ───────────────────────────────────────────────────────

  /// Forgets every cached plaintext for [messageId], so the next
  /// [decryptForRendering] genuinely opens the envelope again.
  ///
  /// Needed for exactly one event: an edit. Every other change to a message
  /// leaves its ciphertext alone, which is why [decryptForRendering] can open
  /// with a memo hit and never look at the envelope at all. An edit replaces the
  /// ciphertext under a **stable message id**, so all three plaintext tiers now
  /// hold the pre-edit text — and any one of them, on its own, is enough to keep
  /// showing it forever.
  ///
  /// Called by SyncService when a document arrives with a newer `editedAt` than
  /// the copy we hold.
  Future<void> forgetCachedPayload(String messageId) async {
    _payloadMemo.remove(messageId);
    // A decrypt already in flight was started against the *old* ciphertext;
    // leaving it here would hand its result to the caller asking about the new
    // one.
    _inFlightDecrypts.remove(messageId);
    // Keyed by an envelope fingerprint, so a stale entry can't block the new
    // ciphertext — but it costs nothing to drop and keeps the tiers consistent.
    _decryptFailures.remove(messageId);
    final store = await PlaintextStore.instance();
    // Deleted rather than overwritten: `save` is insertOrIgnore.
    await store.delete(messageId);
  }

  /// Edits the text of a message we sent. Sender-only, and only inside
  /// [editWindow].
  ///
  /// The hard part is not the write. A message id is *stable* across an edit
  /// while its ciphertext is not, and three caches key plaintext by message id
  /// — the in-memory memo, the PlaintextStore row, and the cross-install vault.
  /// [decryptForRendering] answers from the first that hits without ever
  /// consulting the envelope, so every tier has to be replaced here, and the
  /// PlaintextStore row has to be *deleted* first: its `save` is insertOrIgnore
  /// and would otherwise quietly keep the old text.
  Future<void> editMessage({
    required String senderId,
    required String receiverId,
    required String messageId,
    required String newText,
  }) async {
    final trimmed = newText.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('an edit cannot empty a message — delete it instead');
    }

    final chatRoomId = getChatRoomId(senderId, receiverId);
    final docRef = _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .doc(messageId);

    // Re-checked against the server copy rather than trusted from the caller's
    // model: the UI's copy can be minutes old, and every one of these is a
    // condition the recipient's client would have no way to reject.
    final snap = await docRef.get();
    if (!snap.exists) throw StateError('message $messageId no longer exists');
    final existing = MessageModel.fromFirestore(snap);
    if (existing.senderId != senderId) {
      throw StateError('only the sender may edit a message');
    }
    if (existing.deletedForEveryone) {
      throw StateError('a deleted message cannot be edited');
    }
    if (!withinEditWindow(existing.timestamp)) {
      throw StateError('the edit window for this message has closed');
    }

    // Read the old payload *before* touching any cache — it carries the reply
    // quote, link preview and media metadata that the edit has to preserve.
    final basePayload = existing.schemaVersion >= 2
        ? await ownPayloadFor(senderId, messageId)
        : null;

    final ps = await PlaintextStore.instance();

    if (existing.schemaVersion < 2) {
      // Legacy plaintext message. Its text is already on the document in the
      // clear, so leaving it there is not a downgrade — whereas encrypting it
      // now would make a message an old client could read a moment ago
      // unreadable to it.
      await docRef.update({
        'text': trimmed,
        'editedAt': FieldValue.serverTimestamp(),
      });
    } else {
      final deviceId = await _deviceIdentity.getDeviceId();
      if (deviceId == null || !await _peerHasKeyBundle(receiverId)) {
        throw StateError('cannot re-encrypt this edit for $receiverId');
      }

      final payload = <String, dynamic>{...?basePayload, 'text': trimmed};
      // `type` travels in the wire payload but never in the stored one;
      // `localFilePath` is the reverse — a path on this device that must never
      // reach the wire. See kMessageContentKeys.
      final wire = <String, dynamic>{...payload, 'type': existing.type.name}
        ..remove('localFilePath');

      final encs = await SignalService.instance.encryptForUser(
        senderUid: senderId,
        senderDeviceId: deviceId,
        recipientUid: receiverId,
        plaintext: Uint8List.fromList(utf8.encode(jsonEncode(wire))),
      );
      // Same guard as the send path: a v2 message with no envelope addressed to
      // the recipient renders for them as a permanent placeholder that no
      // resend request can ever repair.
      if (!encs.keys.any((k) => k.startsWith('$receiverId:'))) {
        throw StateError(
            'no envelope addressed to $receiverId (${encs.length} written)');
      }

      await docRef.update({
        'envelopes': encs.map((k, v) => MapEntry(k, v.toMap())),
        'senderDeviceId': deviceId,
        // Item 5 of the kMessageContentKeys contract. On a v2 document the
        // plaintext must never be written, and this is the one line in the edit
        // path where a slip would put message content into Firestore in the
        // clear.
        'text': '',
        'editedAt': FieldValue.serverTimestamp(),
        // The old ciphertext is gone, so an outstanding resend request against
        // it is meaningless — and serving one would re-publish the pre-edit
        // text under the new envelope's id.
        'retryRequests': FieldValue.delete(),
      });

      // Replace all three plaintext tiers. Delete before save, per above.
      await ps.delete(messageId);
      _addToMemo(messageId, payload);
      await ps.save(messageId, payload);
      unawaited(_saveToVault(senderId, messageId, payload));
    }

    // Local row, so our own bubble updates now instead of when the snapshot
    // returns. `saveMessage` is insertOrReplace, so this upserts.
    final local = await ps.getMessagesByIds([messageId]);
    if (local.isNotEmpty) {
      await ps.saveMessage(
        local.first.copyWith(text: trimmed, editedAt: DateTime.now()),
        chatRoomId,
      );
    }

    await _recomputeRoomPreview(chatRoomId, senderId);
  }

  // Get unread message count for a user across all chats
  Stream<int> getTotalUnreadCount(String userId) {
    return _firestore
        .collection(_chatRoomsCollection)
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data();
        Map<String, dynamic> unreadCount =
            Map<String, dynamic>.from(data['unreadCount'] ?? {});
        total += (unreadCount[userId] as int?) ?? 0;
      }
      return total;
    });
  }

  // Check if chat room exists
  Future<bool> chatRoomExists(String currentUserId, String otherUserId) async {
    String chatRoomId = getChatRoomId(currentUserId, otherUserId);
    DocumentSnapshot doc =
        await _firestore.collection(_chatRoomsCollection).doc(chatRoomId).get();
    return doc.exists;
  }

  // ─── Typing Indicator ───────────────────────────────────────────────

  /// Set typing status for a user in a chat room.
  /// Writes the current server timestamp when typing, or removes the entry
  /// when the user stops typing.
  Future<void> setTypingStatus({
    required String currentUserId,
    required String otherUserId,
    required bool isTyping,
  }) async {
    String chatRoomId = getChatRoomId(currentUserId, otherUserId);

    await _firestore.collection(_chatRoomsCollection).doc(chatRoomId).set(
      {
        'typing': {
          currentUserId: isTyping ? FieldValue.serverTimestamp() : null,
        },
      },
      SetOptions(merge: true),
    );
  }

  /// Returns a real-time stream that emits `true` when the other user is
  /// currently typing (i.e. their typing timestamp is less than 5 seconds old).
  Stream<bool> getTypingStatus({
    required String currentUserId,
    required String otherUserId,
  }) {
    String chatRoomId = getChatRoomId(currentUserId, otherUserId);

    return _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return false;

      final data = snapshot.data();
      if (data == null) return false;

      final typing = data['typing'] as Map<String, dynamic>?;
      if (typing == null) return false;

      final otherTypingTimestamp = typing[otherUserId];
      if (otherTypingTimestamp == null) return false;

      if (otherTypingTimestamp is Timestamp) {
        final diff =
            DateTime.now().difference(otherTypingTimestamp.toDate()).inSeconds;
        return diff < 5;
      }

      return false;
    });
  }

  /// Downloads a media file from [message.mediaUrl] and stores it locally.
  /// Returns the local file path if successful, or null otherwise.
  Future<String?> downloadAndCacheMedia(MessageModel message) async {
    final urlStr = message.mediaUrl;
    if (urlStr == null || urlStr.isEmpty) return null;

    try {
      final dbDir = (await getApplicationSupportDirectory()).path;
      final cacheDir = Directory(p.join(dbDir, 'gsg_chat_media'));
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      // Determine the extension (simple check)
      String extension = 'bin';
      if (message.type == MessageType.image) {
        extension = 'jpg';
      } else if (message.type == MessageType.audio) {
        extension = 'm4a';
      } else if (message.type == MessageType.video) {
        extension = 'mp4';
      } else {
        // Fallback: parse from URL path if possible
        try {
          final uri = Uri.parse(urlStr);
          final pathSegments = uri.pathSegments;
          if (pathSegments.isNotEmpty) {
            final fileName = pathSegments.last;
            final dotIdx = fileName.lastIndexOf('.');
            if (dotIdx != -1) {
              extension = fileName.substring(dotIdx + 1);
            }
          }
        } catch (_) {}
      }

      final localPath = p.join(cacheDir.path, '${message.id}.$extension');
      final localFile = File(localPath);

      if (await localFile.exists()) {
        return localPath;
      }

      // Fetch from network
      final response = await http.get(Uri.parse(urlStr));
      if (response.statusCode == 200) {
        await localFile.writeAsBytes(response.bodyBytes);
        return localPath;
      } else {
        if (kDebugMode)
          debugPrint(
              '[ChatService] Failed to download media: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ChatService] Error downloading media: $e');
      return null;
    }
  }

  /// Wipes all in-memory caches. Call on sign-out to free memory and
  /// prevent stale data from leaking across user sessions.
  ///
  /// Streak state is not part of this: it lives in [StreakRepository], which
  /// is cleared separately on the sign-out path via `clearAll()`.
  static void clearCaches() {
    _payloadMemo.clear();
    _decryptFailures.clear();
    _resendInFlight.clear();
    _loggedDecryptSkips.clear();
    _peerBundleCache.clear();
    _peerBundleRefreshInFlight.clear();
    _preWarmVaultCache.clear();
  }
}
