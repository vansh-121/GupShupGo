/// The client's read path for streaks.
///
/// Everything the UI knows about a bond comes from here, and everything here is
/// *derived*: the repository streams the authoritative
/// `chatRooms/{roomId}/streak/state` document and re-runs the same pure
/// [StreakEngine] the server uses, with `event: null` and
/// `serverNow: ServerClock.now()`. Steps 7–10 of the engine turn a lapsed bond
/// into `count: 0, riskLevel: broken, previousCount: <lapsed>` with no writer
/// involved, which is what lets a badge decay live and lets a cached room never
/// render as active past its deadline (design §5, requirements 2.15, 2.19).
///
/// **This class never writes streak fields.** Its only outbound call is the
/// rate-limited `POST /streakEvaluate` nudge, which asks the *server* to
/// converge; see [_maybeNudge].
///
/// Hard rules for this file (enforced by the purity guard test — this file is
/// NOT exempt):
///
///  * no `DateTime.now()` — time comes from [ServerClock.now],
///  * no `toLocal()`,
///  * no `.inDays`.
///
/// ## Listener strategy
///
/// One Firestore listener per *room*, shared by every subscriber of that room
/// ([watch] hands out an independent view stream over a ref-counted channel),
/// plus one global 60-second ticker for the whole app. So a chat list showing
/// N rooms costs N document listeners and 1 timer — not one listener per widget
/// row, and not one timer per badge. [watchMany] folds the same channels into a
/// single `Stream<Map<String, StreakView>>` so the home list rebuilds once per
/// change rather than once per row.
///
/// A collection-group listener on `streak` filtered by `participants` would
/// collapse the N listeners into one, but it needs a collection-group index
/// that this change does not deploy, so it is deliberately not used.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'server_clock.dart';
import 'streak_api.dart';
import 'streak_day.dart';
import 'streak_engine.dart';
import 'streak_state.dart';

/// Everything the UI renders about one bond, and nothing else.
///
/// Deliberately self-sufficient: a widget holding a [StreakView] needs neither
/// the engine nor [StreakState]. Every instant is UTC.
@immutable
class StreakView {
  const StreakView({
    required this.roomId,
    required this.count,
    required this.riskLevel,
    required this.evaluatedAt,
    this.deadlineAt,
    this.previousCount = 0,
    this.restoreDeadlineAt,
    this.isRestorable = false,
    this.lastMutualDay,
    this.clockTrusted = false,
    this.stale = true,
    this.isLegacyProjection = false,
    this.hasState = false,
  });

  /// A view for a room with nothing known about it yet: no badge, no countdown.
  factory StreakView.empty(String roomId, {required DateTime evaluatedAt}) =>
      StreakView(
        roomId: roomId,
        count: 0,
        riskLevel: StreakRiskLevel.normal,
        evaluatedAt: evaluatedAt,
        clockTrusted: ServerClock.trusted,
      );

  final String roomId;

  /// The live count as of [evaluatedAt]. `0` once the deadline has passed.
  final int count;

  final StreakRiskLevel riskLevel;

  /// The server time the derivation used. The countdown is measured from here.
  final DateTime evaluatedAt;

  /// When the bond lapses, or `null` when there is no chain.
  final DateTime? deadlineAt;

  /// The lapsed count held for the restore window (`0` when not restorable).
  final int previousCount;

  /// End of the restore window.
  final DateTime? restoreDeadlineAt;

  /// Whether the restore offer is still open as of [evaluatedAt].
  final bool isRestorable;

  /// The newest day both participants sent on. Survives a break.
  final StreakDay? lastMutualDay;

  /// Whether [evaluatedAt] came from a clock sample taken this session. When
  /// false the UI must not render a ticking countdown — the count and the risk
  /// level are still server-stamped and safe to show.
  final bool clockTrusted;

  /// Whether the underlying observation is older than [kStreakFreshnessWindow].
  /// A stale view still renders its count (so the list is never blank offline)
  /// but the countdown is suppressed.
  final bool stale;

  /// True when the view was projected from the legacy room fields because the
  /// v2 state document has not been written for this room yet.
  final bool isLegacyProjection;

  /// False for a placeholder view (nothing observed for this room yet).
  final bool hasState;

  // --- convenience -----------------------------------------------------------

  /// Whether a badge should be shown at all: a live streak, or a broken one the
  /// user can still restore.
  bool get hasBadge => count > 0 || isRestorable;

  /// Whether the bond is currently lapsed.
  bool get isBroken => riskLevel == StreakRiskLevel.broken;

  /// Whether a countdown may be rendered: there is a deadline, the clock is
  /// trustworthy, and the observation is fresh.
  bool get canShowCountdown =>
      count > 0 && deadlineAt != null && clockTrusted && !stale;

  /// Time left before the bond lapses, as of [evaluatedAt]. [Duration.zero]
  /// once past the deadline, `null` with no deadline.
  Duration? get timeRemaining {
    final deadline = deadlineAt;
    if (deadline == null) return null;
    final remaining = deadline.difference(evaluatedAt);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Time left to restore a broken bond, as of [evaluatedAt].
  Duration? get restoreTimeRemaining {
    final deadline = restoreDeadlineAt;
    if (deadline == null) return null;
    final remaining = deadline.difference(evaluatedAt);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// The count worth showing on a broken-bond card.
  int get restorableCount => isRestorable ? previousCount : 0;

  @override
  bool operator ==(Object other) =>
      other is StreakView &&
      other.roomId == roomId &&
      other.count == count &&
      other.riskLevel == riskLevel &&
      other.evaluatedAt == evaluatedAt &&
      other.deadlineAt == deadlineAt &&
      other.previousCount == previousCount &&
      other.restoreDeadlineAt == restoreDeadlineAt &&
      other.isRestorable == isRestorable &&
      other.lastMutualDay == lastMutualDay &&
      other.clockTrusted == clockTrusted &&
      other.stale == stale &&
      other.isLegacyProjection == isLegacyProjection &&
      other.hasState == hasState;

  @override
  int get hashCode => Object.hash(
        roomId,
        count,
        riskLevel,
        evaluatedAt,
        deadlineAt,
        previousCount,
        restoreDeadlineAt,
        isRestorable,
        lastMutualDay,
        clockTrusted,
        stale,
        isLegacyProjection,
        hasState,
      );

  @override
  String toString() => 'StreakView($roomId, count: $count, '
      'risk: ${riskLevel.wire}, deadlineAt: ${deadlineAt?.toIso8601String()}, '
      'previousCount: $previousCount, restorable: $isRestorable, '
      'stale: $stale, clockTrusted: $clockTrusted, legacy: $isLegacyProjection)';
}

/// Read-only access to streak state, derived through the engine on every read.
class StreakRepository {
  StreakRepository._();

  static final StreakRepository instance = StreakRepository._();

  /// How often a live view re-derives, so a badge decays without a write.
  static const Duration tickInterval = Duration(minutes: 1);

  /// Client-side floor between two nudges for the same room. The endpoint is
  /// rate-limited server-side too; this stops a rebuild storm from ever
  /// reaching it.
  static const Duration nudgeCooldown = Duration(minutes: 5);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, _RoomChannel> _channels = <String, _RoomChannel>{};

  /// Last derived view per room, kept after the last listener leaves so a
  /// re-subscribe (a rebuild, a list scroll) renders instantly.
  final Map<String, StreakView> _views = <String, StreakView>{};

  /// States handed in by the disk cache (task 7.4) before the stream lands.
  final Map<String, StreakState> _seeded = <String, StreakState>{};

  /// Participants known per room, so a state document with an empty
  /// `participants` array can still be evaluated.
  final Map<String, List<String>> _participants = <String, List<String>>{};

  final Map<String, DateTime> _lastNudgeAt = <String, DateTime>{};

  Timer? _ticker;

  // ── Public API ────────────────────────────────────────────────────────────

  /// The latest derived view for [roomId], or `null` when nothing is known yet.
  ///
  /// Synchronous and allocation-free: for a list row that just wants to paint
  /// the value it already had.
  StreakView? latest(String roomId) => _views[roomId];

  /// Streams the derived view for [roomId].
  ///
  /// Emits immediately with whatever is known (a placeholder when nothing is),
  /// then on every state-document change and every [tickInterval] tick. The
  /// underlying Firestore listener is shared between all subscribers of the
  /// same room and closed when the last one leaves.
  Stream<StreakView> watch(String roomId) {
    if (roomId.isEmpty) {
      return Stream<StreakView>.value(
        StreakView.empty(roomId, evaluatedAt: ServerClock.now()),
      );
    }
    final channel = _channelFor(roomId);
    StreamSubscription<StreakView>? sub;
    late final StreamController<StreakView> out;
    out = StreamController<StreakView>(
      onListen: () {
        channel.retain();
        sub = channel.views.listen(out.add, onError: out.addError);
        out.add(channel.derive(emit: false));
      },
      onCancel: () async {
        await sub?.cancel();
        sub = null;
        channel.release();
      },
    );
    return out.stream;
  }

  /// Streams the derived views for [roomIds] as one map.
  ///
  /// One emission per change across the whole set, so the chat list rebuilds
  /// once instead of once per row. Room ids absent from the map simply have no
  /// observation yet.
  Stream<Map<String, StreakView>> watchMany(Iterable<String> roomIds) {
    final ids = <String>{...roomIds.where((id) => id.isNotEmpty)}.toList();
    final subs = <StreamSubscription<StreakView>>[];
    final current = <String, StreakView>{};
    late final StreamController<Map<String, StreakView>> out;

    void publish() {
      if (out.isClosed) return;
      out.add(Map<String, StreakView>.unmodifiable(current));
    }

    out = StreamController<Map<String, StreakView>>(
      onListen: () {
        for (final id in ids) {
          final channel = _channelFor(id);
          channel.retain();
          subs.add(channel.views.listen((view) {
            current[id] = view;
            publish();
          }, onError: (Object e) {
            debugPrint('[StreakRepository] $id stream error: $e');
          }));
          current[id] = channel.derive(emit: false);
        }
        publish();
      },
      onCancel: () async {
        for (final sub in subs) {
          await sub.cancel();
        }
        subs.clear();
        for (final id in ids) {
          _channels[id]?.release();
        }
      },
    );
    return out.stream;
  }

  /// Hands the repository a room document it already has, so the legacy
  /// dual-read fallback and the participant list cost no extra Firestore read.
  ///
  /// Safe to call on every room-list emission: a v2 state document always wins
  /// over the legacy projection.
  void primeRoom(String roomId, Map<String, dynamic>? roomData) {
    if (roomId.isEmpty || roomData == null) return;
    final participants = <String>[
      for (final uid in (roomData['participants'] as Iterable? ??
              const <dynamic>[])
          .whereType<String>())
        if (uid.isNotEmpty) uid,
    ]..sort();
    if (participants.isNotEmpty) _participants[roomId] = participants;
    final legacy = StreakState.fromLegacyRoomMap(
      roomData,
      participants: participants.isEmpty ? null : participants,
      receivedAt: ServerClock.now(),
    );
    _channels[roomId]?.offerLegacy(legacy);
    if (!_channels.containsKey(roomId)) _seeded[roomId] = legacy;
  }

  /// Hands the repository a state restored from the disk cache (task 7.4), so
  /// the first frame after a cold start renders a count instead of a blank.
  void primeCachedState(String roomId, StreakState? state) {
    if (roomId.isEmpty || state == null) return;
    if (state.participants.isNotEmpty) {
      _participants[roomId] = state.participants;
    }
    final channel = _channels[roomId];
    if (channel != null) {
      channel.offerCached(state);
    } else {
      _seeded[roomId] = state;
    }
  }

  /// Drops every stream, the derived map and all cached state.
  ///
  /// Replaces `ChatService.clearStreakCache()` on the sign-out path (3.14), and
  /// clears the clock sample with it — the next user's device must not inherit
  /// this session's offset.
  Future<void> clearAll() async {
    final channels = _channels.values.toList();
    _channels.clear();
    for (final channel in channels) {
      await channel.dispose();
    }
    _views.clear();
    _seeded.clear();
    _participants.clear();
    _lastNudgeAt.clear();
    _ticker?.cancel();
    _ticker = null;
    await ServerClock.clear();
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  _RoomChannel _channelFor(String roomId) => _channels.putIfAbsent(
        roomId,
        () => _RoomChannel(repository: this, roomId: roomId),
      );

  void _onChannelIdle(_RoomChannel channel) {
    if (_channels[channel.roomId] != channel) return;
    _channels.remove(channel.roomId);
    channel.dispose();
    if (_channels.isEmpty) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  void _ensureTicker() {
    _ticker ??= Timer.periodic(tickInterval, (_) {
      for (final channel in _channels.values.toList()) {
        channel.derive();
      }
    });
  }

  DocumentReference<Map<String, dynamic>> _stateRef(String roomId) => _firestore
      .collection('chatRooms')
      .doc(roomId)
      .collection('streak')
      .doc('state');

  DocumentReference<Map<String, dynamic>> _roomRef(String roomId) =>
      _firestore.collection('chatRooms').doc(roomId);

  /// Asks the server to re-evaluate [roomId], at most once per
  /// [nudgeCooldown] per room.
  ///
  /// Fired when the *derived* state is broken but `stored.brokenAt` is null:
  /// the client can see the lapse the sweeper has not stamped yet, so it asks
  /// the server to converge rather than writing anything itself. Skipped when
  /// the clock is untrusted — an unverified `now` is not evidence of a lapse.
  void _maybeNudge(String roomId, StreakState stored, StreakEvaluation derived) {
    if (!derived.transitions.contains(StreakTransition.broken)) return;
    if (stored.brokenAt != null) return;
    if (!ServerClock.trusted) return;
    final now = ServerClock.now();
    final last = _lastNudgeAt[roomId];
    if (last != null && now.difference(last) < nudgeCooldown) return;
    _lastNudgeAt[roomId] = now;
    // Fire and forget: the endpoint is idempotent and rate-limited server-side,
    // and a failure only costs us a slightly later convergence.
    StreakApi.instance.streakEvaluate(roomId);
  }
}

/// One room's shared listener, stored state and derived-view fan-out.
class _RoomChannel {
  _RoomChannel({required this.repository, required this.roomId}) {
    _stored = repository._seeded[roomId];
  }

  final StreakRepository repository;
  final String roomId;

  final StreamController<StreakView> _views =
      StreamController<StreakView>.broadcast();

  Stream<StreakView> get views => _views.stream;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _stateSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roomSub;

  /// The most recent usable state: the v2 document when present, otherwise the
  /// legacy projection or a cached block.
  StreakState? _stored;

  /// Whether a v2 state document has been seen. Once it has, the legacy
  /// fallback is switched off for good.
  bool _hasV2 = false;

  int _listeners = 0;

  void retain() {
    _listeners++;
    if (_listeners == 1) _start();
  }

  void release() {
    _listeners--;
    if (_listeners <= 0) {
      _listeners = 0;
      repository._onChannelIdle(this);
    }
  }

  void _start() {
    repository._ensureTicker();
    _stateSub ??= repository._stateRef(roomId).snapshots().listen(
      _onStateSnapshot,
      onError: (Object error) {
        debugPrint('[StreakRepository] $roomId state listener error: $error');
        // Keep whatever we had; a dropped listener must never blank the badge.
        derive();
      },
    );
  }

  void _onStateSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final state = StreakState.fromStateDoc(
      snapshot.data(),
      receivedAt: ServerClock.now(),
      participantsFallback: repository._participants[roomId],
    );
    if (state != null) {
      // Dual-read: the authoritative document wins outright.
      _hasV2 = true;
      _stored = state;
      if (state.participants.isNotEmpty) {
        repository._participants[roomId] = state.participants;
      }
      _stopLegacyListener();
      derive();
      return;
    }
    // No usable v2 document (missing, or schemaVersion < 2): fall back to the
    // legacy room fields so a room the repair has not reached still renders.
    _startLegacyListener();
    derive();
  }

  void _startLegacyListener() {
    if (_hasV2 || _roomSub != null) return;
    _roomSub = repository._roomRef(roomId).snapshots().listen(
      (snapshot) {
        if (_hasV2) return;
        final data = snapshot.data();
        if (data == null) return;
        repository.primeRoom(roomId, data);
      },
      onError: (Object error) {
        debugPrint('[StreakRepository] $roomId room listener error: $error');
      },
    );
  }

  void _stopLegacyListener() {
    _roomSub?.cancel();
    _roomSub = null;
  }

  /// Accepts a legacy projection. Ignored once a v2 document has been seen.
  void offerLegacy(StreakState legacy) {
    if (_hasV2) return;
    _stored = legacy;
    derive();
  }

  /// Accepts a state restored from the disk cache. Ignored once anything newer
  /// has been observed from the network.
  void offerCached(StreakState cached) {
    if (_hasV2) return;
    final current = _stored;
    if (current != null && current.rev > cached.rev) return;
    _stored = cached;
    derive();
  }

  /// Re-runs the engine against the stored state and publishes the result.
  ///
  /// [emit] false is used for the synchronous first value handed to a new
  /// subscriber, which is delivered on its own stream instead.
  StreakView derive({bool emit = true}) {
    final now = ServerClock.now();
    final stored = _stored;
    if (stored == null) {
      final view = StreakView.empty(roomId, evaluatedAt: now);
      repository._views[roomId] = view;
      if (emit && _views.hasListener) _views.add(view);
      return view;
    }

    final participants = stored.participants.isNotEmpty
        ? stored.participants
        : (repository._participants[roomId] ?? const <String>[]);

    final evaluation = StreakEngine.evaluate(
      stored: stored,
      participants: participants,
      serverNow: now,
    );

    final next = evaluation.next;
    final view = StreakView(
      roomId: roomId,
      count: evaluation.count,
      riskLevel: evaluation.riskLevel,
      evaluatedAt: now,
      deadlineAt: evaluation.deadlineAt,
      previousCount: next.previousCount,
      restoreDeadlineAt: next.restoreDeadlineAt,
      isRestorable: next.isRestorable(now),
      lastMutualDay: evaluation.lastMutualDay,
      clockTrusted: ServerClock.trusted,
      stale: stored.isStaleAt(now),
      isLegacyProjection: stored.isLegacyProjection,
      hasState: true,
    );

    repository._maybeNudge(roomId, stored, evaluation);

    repository._views[roomId] = view;
    if (emit && _views.hasListener) _views.add(view);
    return view;
  }

  Future<void> dispose() async {
    await _stateSub?.cancel();
    _stateSub = null;
    await _roomSub?.cancel();
    _roomSub = null;
    if (!_views.isClosed) await _views.close();
  }
}
