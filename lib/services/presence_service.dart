import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// WhatsApp-style presence service that uses Firebase Realtime Database's
/// `onDisconnect()` handler to detect when a user goes offline — even on
/// sudden disconnects (phone off, app killed, crash, airplane mode).
///
/// Architecture:
/// ┌──────────────────────────────────────────────────────────────────────┐
/// │ RTDB /presence/{uid}  ← source of truth                             │
/// │   • online   : true/false   ← watched by the `presenceMirror` fn     │
/// │   • lastSeen : server timestamp, heartbeated every 25s               │
/// │                          │                                           │
/// │                          ▼ (Cloud Function, server-side)             │
/// │ Firestore /users/{uid}  ← what every screen actually reads           │
/// │   • isOnline : true/false                                            │
/// │   • lastSeen : timestamp                                             │
/// └──────────────────────────────────────────────────────────────────────┘
///
/// On connect (every time, including background reconnects):
///   1. Register onDisconnect → online=false + lastSeen
///   2. Write the state this app is actually in (online only if foregrounded)
///   3. Mirror to Firestore as a fallback for the Cloud Function
///   4. Start the heartbeat, if foregrounded
///
/// On disconnect (server-side):
///   The RTDB server detects the broken connection and executes the
///   pre-registered onDisconnect write. `presenceMirror` propagates it to
///   Firestore — without that function a force-kill would leave Firestore
///   stuck at `isOnline: true` permanently, since the client is gone.
///
/// Why the heartbeat still matters: onDisconnect is not a hard guarantee.
/// Records have been observed stuck `online: true` for weeks in production.
/// So `online` alone is never trusted — a reader also requires a `lastSeen`
/// fresher than [staleThreshold], and the `presenceSweeper` job clears
/// long-lived ghosts. Three independent layers, because the first two both
/// have real-world failure modes.
class PresenceService {
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<DatabaseEvent>? _connectedSub;
  Timer? _heartbeatTimer;
  String? _userId;
  bool _isSetUp = false;

  /// Whether the app is currently foregrounded. A reconnect that happens
  /// while backgrounded must re-arm `onDisconnect` but must NOT re-mark the
  /// user online.
  bool _isForeground = true;

  /// Duration between heartbeat writes of `lastSeen` to RTDB. Must stay
  /// comfortably below [staleThreshold] so a single missed write can't make
  /// an active user flicker offline.
  static const _heartbeatInterval = Duration(seconds: 25);

  /// If a user's lastSeen is older than this, treat them as offline
  /// regardless of the `isOnline` flag. This is the bound on how long a
  /// dead session can keep claiming to be online, so it is deliberately
  /// tight. Kept in sync with `PRESENCE_STALE_MS` in `functions/index.js`.
  static const staleThreshold = Duration(seconds: 60);

  /// Returns true if [lastSeen] is recent enough that the user should
  /// still be considered online. Call this when reading another user's
  /// presence to guard against stale data.
  static bool isRecentlyActive(DateTime? lastSeen) {
    if (lastSeen == null) return false;
    return DateTime.now().difference(lastSeen) < staleThreshold;
  }

  // ────────────────────────────────────────────────────────────────────
  // Public API
  // ────────────────────────────────────────────────────────────────────

  /// Call once after the user signs in or the app opens with a valid session.
  /// Safe to call multiple times — subsequent calls are no-ops.
  Future<void> setupPresence(String userId) async {
    if (_isSetUp && _userId == userId) return; // already wired up
    // If switching users, tear down the old one first.
    if (_isSetUp) await dispose();

    _userId = userId;
    _isSetUp = true;
    _isForeground = true;

    final presenceRef = _rtdb.ref('presence/$userId');

    // Listen to .info/connected — fires every time the RTDB connection is
    // established (cold start, reconnect after transient drop, etc.). This
    // subscription is kept alive while backgrounded on purpose: an
    // onDisconnect handler is per-connection, so a reconnect we didn't
    // observe would leave the new connection with nothing armed, and a
    // later kill would never be recorded.
    _connectedSub =
        _rtdb.ref('.info/connected').onValue.listen((DatabaseEvent event) {
      final connected = event.snapshot.value as bool? ?? false;
      // Not connected — nothing to do; onDisconnect covers it server-side.
      if (!connected) return;
      _onConnected(userId, presenceRef);
    });
  }

  /// Explicitly mark the user offline (e.g. sign-out).
  /// This writes immediately to both RTDB and Firestore.
  Future<void> goOffline(String userId) async {
    _stopHeartbeat();
    _isForeground = false;
    try {
      // Cancel onDisconnect (we're handling it ourselves now).
      await _rtdb.ref('presence/$userId').onDisconnect().cancel();
      await _rtdb.ref('presence/$userId').set({
        'online': false,
        'lastSeen': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('PresenceService.goOffline RTDB error: $e');
      // Best-effort — if we can't reach the server the onDisconnect
      // handler will kick in anyway.
    }
    // Separate from the RTDB block: an RTDB failure must not skip the
    // Firestore write, since Firestore is what other users read.
    await _mirrorToFirestore(userId, false);
  }

  /// Call when the app lifecycle transitions to resumed.
  Future<void> onAppResumed(String userId) async {
    if (!_isSetUp || _userId != userId) {
      // Fresh wiring (first launch, or a different user).
      if (_isSetUp) await dispose();
      await setupPresence(userId);
      return;
    }

    // Already wired and still connected, so `.info/connected` will not fire
    // again — drive the same path directly to re-arm, go online and restart
    // the heartbeat. Idempotent, so a concurrent reconnect event is harmless.
    _isForeground = true;
    await _onConnected(userId, _rtdb.ref('presence/$userId'));
  }

  /// Call when the app lifecycle transitions to paused/inactive/detached.
  /// Writes offline immediately (a locked screen should read as offline at
  /// once), while leaving the onDisconnect handler armed as a fallback.
  Future<void> onAppPaused(String userId) async {
    _stopHeartbeat();
    // Deliberately NOT cancelling _connectedSub: see setupPresence. The
    // flag is what stops a background reconnect from re-marking us online.
    _isForeground = false;
    try {
      await _rtdb.ref('presence/$userId').set({
        'online': false,
        'lastSeen': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('PresenceService.onAppPaused RTDB error: $e');
      // If the write fails (e.g. already disconnected), the onDisconnect
      // handler will still fire server-side.
    }
    await _mirrorToFirestore(userId, false);
  }

  /// Tear down listeners and timers. Call on dispose or user switch.
  Future<void> dispose() async {
    _stopHeartbeat();
    await _connectedSub?.cancel();
    _connectedSub = null;
    _isSetUp = false;
    _userId = null;
  }

  // ────────────────────────────────────────────────────────────────────
  // Internal helpers
  // ────────────────────────────────────────────────────────────────────

  /// Brings RTDB + Firestore in line with this app's actual state on a fresh
  /// connection. Each store is written in its own try block so a failure in
  /// one cannot skip the other.
  Future<void> _onConnected(String userId, DatabaseReference presenceRef) async {
    final shouldBeOnline = _isForeground;

    try {
      // Register onDisconnect FIRST — it must be armed before the "go online"
      // write, so that a crash immediately afterwards still gets cleaned up.
      await presenceRef.onDisconnect().set({
        'online': false,
        'lastSeen': ServerValue.timestamp,
      });

      await presenceRef.set({
        'online': shouldBeOnline,
        'lastSeen': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('PresenceService: RTDB write on connect failed: $e');
    }

    // Mirror as a fallback. `presenceMirror` normally owns this field, but
    // writing it here too means presence still works if that function is
    // down, and both paths write the same monotonic transition.
    await _mirrorToFirestore(userId, shouldBeOnline);

    if (shouldBeOnline) {
      _startHeartbeat(presenceRef);
    } else {
      _stopHeartbeat();
    }
  }

  /// Mirrors the online status into the Firestore user document so that all
  /// existing Firestore-based queries and UI keep working.
  Future<void> _mirrorToFirestore(String userId, bool isOnline) async {
    try {
      // Always write lastSeen so that stale-detection works for all users,
      // even those with "show last seen" disabled. Privacy (whether to
      // *display* the timestamp to others) is enforced at the UI layer.
      await _firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('PresenceService._mirrorToFirestore error: $e');
    }
  }

  /// Refreshes `lastSeen` in RTDB on an interval. This is what lets readers
  /// distinguish a live session from a stuck `online: true`.
  ///
  /// Only RTDB is touched: `lastSeen` is a sibling of the `online` child that
  /// `presenceMirror` watches, so heartbeats cost no function invocations, and
  /// Firestore still gets a fresh `lastSeen` on every online/offline
  /// transition — ample for the day-granularity digest and reminder jobs.
  void _startHeartbeat(DatabaseReference presenceRef) {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) async {
      try {
        await presenceRef.update({'lastSeen': ServerValue.timestamp});
      } catch (e) {
        debugPrint('PresenceService heartbeat error: $e');
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
}
