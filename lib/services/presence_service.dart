import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// WhatsApp-style presence service that uses Firebase Realtime Database's
/// `onDisconnect()` handler to reliably detect when a user goes offline —
/// even on sudden disconnects (phone off, app killed, crash, airplane mode).
///
/// Architecture:
/// ┌────────────────────────────────────────────────────────┐
/// │ RTDB /presence/{uid}  ← source of truth               │
/// │   • online: true/false                                 │
/// │   • lastSeen: server timestamp                         │
/// │                                                        │
/// │ Firestore /users/{uid}  ← mirrored for existing queries│
/// │   • isOnline: true/false                               │
/// │   • lastSeen: server timestamp                         │
/// └────────────────────────────────────────────────────────┘
///
/// On connect:
///   1. Write online=true + lastSeen to RTDB
///   2. Register onDisconnect → online=false + lastSeen
///   3. Mirror to Firestore
///   4. Start heartbeat timer (every 60s)
///
/// On disconnect (server-side):
///   Firebase RTDB server detects broken TCP connection (~60s)
///   and executes the pre-registered onDisconnect write.
///
/// Stale detection (safety net):
///   Any user whose lastSeen is >2 minutes ago is treated as offline
///   by readers, even if isOnline is still true.
class PresenceService {
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<DatabaseEvent>? _connectedSub;
  Timer? _heartbeatTimer;
  String? _userId;
  bool _isSetUp = false;

  /// Duration between heartbeat writes to RTDB + Firestore.
  static const _heartbeatInterval = Duration(seconds: 60);

  /// If a user's lastSeen is older than this, treat them as offline
  /// regardless of the `isOnline` flag. Acts as a safety net for edge
  /// cases where even RTDB onDisconnect is delayed.
  static const staleThreshold = Duration(minutes: 2);

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

    final presenceRef = _rtdb.ref('presence/$userId');

    // Listen to .info/connected — fires every time the RTDB connection
    // is established (cold start, reconnect after transient drop, etc.).
    _connectedSub = _rtdb
        .ref('.info/connected')
        .onValue
        .listen((DatabaseEvent event) async {
      final connected = event.snapshot.value as bool? ?? false;
      if (!connected) return; // offline — nothing to do, onDisconnect handles it

      try {
        // 1. Register onDisconnect FIRST — must be set before the "go online"
        //    write, so that even if we crash right after, the server knows to
        //    clean up.
        await presenceRef.onDisconnect().set({
          'online': false,
          'lastSeen': ServerValue.timestamp,
        });

        // 2. Write "I'm online" to RTDB.
        await presenceRef.set({
          'online': true,
          'lastSeen': ServerValue.timestamp,
        });

        // 3. Mirror to Firestore so existing queries/UI keep working.
        await _mirrorToFirestore(userId, true);

        // 4. Start heartbeat.
        _startHeartbeat(userId, presenceRef);
      } catch (e) {
        debugPrint('PresenceService: error in .info/connected handler: $e');
      }
    });
  }

  /// Explicitly mark the user offline (e.g. sign-out).
  /// This writes immediately to both RTDB and Firestore.
  Future<void> goOffline(String userId) async {
    _stopHeartbeat();
    try {
      // Cancel onDisconnect (we're handling it ourselves now).
      await _rtdb.ref('presence/$userId').onDisconnect().cancel();
      // Write offline.
      await _rtdb.ref('presence/$userId').set({
        'online': false,
        'lastSeen': ServerValue.timestamp,
      });
      await _mirrorToFirestore(userId, false);
    } catch (e) {
      debugPrint('PresenceService.goOffline error: $e');
      // Best-effort — if we can't reach the server the onDisconnect
      // handler will kick in anyway.
    }
  }

  /// Call when the app lifecycle transitions to resumed.
  /// Re-establishes presence after the app was in background.
  Future<void> onAppResumed(String userId) async {
    // Tear down and re-setup cleanly to avoid duplicate writes
    // and overlapping heartbeat timers.
    if (_isSetUp) await dispose();
    await setupPresence(userId);
  }

  /// Call when the app lifecycle transitions to paused/inactive/detached.
  /// Writes offline immediately (for fast transitions like receiving a call),
  /// but keeps the onDisconnect handler alive as a fallback.
  Future<void> onAppPaused(String userId) async {
    _stopHeartbeat();
    // Cancel the .info/connected listener so that transient reconnects
    // while backgrounded don't re-mark the user online.
    await _connectedSub?.cancel();
    _connectedSub = null;
    _isSetUp = false;
    _userId = null;
    try {
      await _rtdb.ref('presence/$userId').set({
        'online': false,
        'lastSeen': ServerValue.timestamp,
      });
      await _mirrorToFirestore(userId, false);
    } catch (e) {
      debugPrint('PresenceService.onAppPaused error: $e');
      // If the write fails (e.g. already disconnected), the onDisconnect
      // handler will still fire server-side.
    }
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

  /// Mirrors the online status from RTDB into the Firestore user document
  /// so that all existing Firestore-based queries and UI keep working.
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

  /// Starts a periodic timer that refreshes `lastSeen` in both RTDB and
  /// Firestore. This serves as a heartbeat so that readers can detect
  /// stale online statuses (e.g. if onDisconnect is delayed).
  void _startHeartbeat(String userId, DatabaseReference presenceRef) {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) async {
      try {
        // Touch RTDB lastSeen.
        await presenceRef.update({
          'lastSeen': ServerValue.timestamp,
        });
        // Always touch Firestore lastSeen (privacy is enforced at display).
        await _firestore.collection('users').doc(userId).update({
          'lastSeen': FieldValue.serverTimestamp(),
        });
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
