// ════════════════════════════════════════════════════════════════════════════
//  FROZEN LEGACY STREAK REFERENCE — THE SPECIFICATION OF THE BUG
// ════════════════════════════════════════════════════════════════════════════
//
// This file is a verbatim, frozen transcription of the streak logic that lives
// inline in `ChatService._commitMessage` (lib/services/chat_service.dart,
// ~lines 832-1014) plus the satellite legacy paths it cooperates with
// (`GamificationService.handleStreakMilestone`, `GamificationService.restoreStreak`,
// `SubscriptionService.canRestoreStreakFree` / `recordStreakRestore`).
//
// RULES FOR THIS FILE (from the design's Testing Strategy):
//   * It is NEVER imported by production code (`lib/**`).
//   * It is NEVER "fixed". It is the specification of the bug. When the engine
//     lands, tests are pointed at the engine and their assertions inverted —
//     this file stays exactly as it is.
//
// FAITHFULNESS NOTES — the only deviations from the original source, each one
// a mechanical parameterisation of something the original reads from ambient
// global state, so that the same code can be driven deterministically from a
// test:
//
//   1. `DateTime.now()`         → the `now` parameter (an absolute instant).
//      The original calls `DateTime.now()` twice (once inside the streak block,
//      once in the post-commit `lastSentAt` write); both are exposed
//      (`now`, `postCommitNow`) so 1.7's two-timestamp split stays visible.
//   2. The device's local timezone (`DateTime(y, m, d)`, `.toLocal()`)
//                              → the `zone` parameter ([LegacyDeviceZone]).
//      `DateTime(y, m, d)` on a local `DateTime` is modelled as
//      `DateTime.utc(y, m, d)` over the zone's *wall clock* reading, and
//      `today.difference(lastMutualDay).inDays` is modelled as the difference
//      between the two wall-clock midnights' *absolute instants*, which is
//      exactly what Dart does for local `DateTime`s (and is precisely why a
//      DST-shortened day yields 0 — see [LegacyDeviceZone.wallDayDifference]).
//   3. `Timestamp.fromDate(x)` → `x` (a plain `DateTime`), so the test suite
//      does not need `cloud_firestore`.
//   4. `_streakCache[chatRoomId]` → the `cache` parameter, and the entry the
//      block writes back is returned as [LegacyEvaluation.nextCache]. Callers
//      thread it themselves, which is what makes the per-device cache lifetime
//      explicit in tests.
//   5. The Firestore batch write is returned as [LegacyEvaluation.roomUpdates]
//      instead of being committed; [legacyMergeRoomDoc] models
//      `set(..., SetOptions(merge: true))` last-writer-wins semantics.
//
// Everything else — branch order, comparison operators, the unconditional
// `lastInteraction: now` cache rewrite, the missing TTL comparison, the
// `otherUserId` self-alias, the exact-match milestone thresholds — is copied
// as-is.
//
// ignore_for_file: prefer_const_constructors

/// Namespace for the frozen legacy facts the tests assert against.
class LegacyStreakReference {
  LegacyStreakReference._();

  /// Verbatim from `ChatService`:
  ///
  /// ```dart
  /// static final Map<String, _StreakCacheEntry> _streakCache = {};
  /// static const _streakCacheTtl = Duration(minutes: 30);
  /// ```
  ///
  /// The TTL is *declared and never compared against anything* — `cacheHit` is
  /// literally `cached != null`. Defect 1.3.
  static const Duration declaredCacheTtl = Duration(minutes: 30);

  /// Number of times [legacyEvaluate] has been called. Used by the read-path
  /// test (defects 1.13 / 1.17) to prove that displaying a room never
  /// evaluates the streak at all.
  static int evaluateCallCount = 0;

  static void resetCallCount() => evaluateCallCount = 0;
}

// ── Device timezone model ──────────────────────────────────────────────────

/// The evaluating device's local timezone, which the legacy code uses as the
/// streak day boundary (defects 1.5 and 1.6).
///
/// A "wall" `DateTime` in this file is always UTC-flagged, but its fields carry
/// the *local* reading of the device clock. The UTC flag is only a carrier: it
/// keeps the host machine's real timezone out of the computation.
class LegacyDeviceZone {
  const LegacyDeviceZone({
    required this.name,
    required this.baseOffsetMinutes,
    this.dstOffsetMinutes,
    this.dstStartUtc,
    this.dstEndUtc,
  });

  final String name;
  final int baseOffsetMinutes;
  final int? dstOffsetMinutes;
  final DateTime? dstStartUtc;
  final DateTime? dstEndUtc;

  /// Asia/Kolkata — fixed +05:30, no DST.
  static final LegacyDeviceZone ist = LegacyDeviceZone(
    name: 'Asia/Kolkata (+05:30)',
    baseOffsetMinutes: 330,
  );

  /// America/Los_Angeles with the real 2024 DST rule: PST (−08:00) until
  /// 2024-03-10T10:00Z, PDT (−07:00) until 2024-11-03T09:00Z.
  static final LegacyDeviceZone pacific2024 = LegacyDeviceZone(
    name: 'America/Los_Angeles (2024 DST)',
    baseOffsetMinutes: -480,
    dstOffsetMinutes: -420,
    dstStartUtc: DateTime.utc(2024, 3, 10, 10),
    dstEndUtc: DateTime.utc(2024, 11, 3, 9),
  );

  /// Fixed −07:00, no DST (the "partner in the US" device of the design's
  /// cross-timezone example).
  static final LegacyDeviceZone fixedMinus7 = LegacyDeviceZone(
    name: 'UTC-07:00',
    baseOffsetMinutes: -420,
  );

  /// Fixed −08:00, no DST.
  static final LegacyDeviceZone fixedMinus8 = LegacyDeviceZone(
    name: 'UTC-08:00',
    baseOffsetMinutes: -480,
  );

  int offsetMinutesAt(DateTime instant) {
    final utc = instant.toUtc();
    if (dstOffsetMinutes != null &&
        dstStartUtc != null &&
        !utc.isBefore(dstStartUtc!) &&
        (dstEndUtc == null || utc.isBefore(dstEndUtc!))) {
      return dstOffsetMinutes!;
    }
    return baseOffsetMinutes;
  }

  /// The device's wall-clock reading of [instant] — models `.toLocal()`.
  DateTime wall(DateTime instant) =>
      instant.toUtc().add(Duration(minutes: offsetMinutesAt(instant)));

  /// `DateTime(now.year, now.month, now.day)` — midnight of the wall day.
  DateTime dayKey(DateTime wallTime) =>
      DateTime.utc(wallTime.year, wallTime.month, wallTime.day);

  /// The absolute instant at which a wall-clock reading occurs. Two-pass
  /// offset resolution, as any real zone implementation does.
  DateTime instantOfWall(DateTime wallTime) {
    final guess = wallTime.subtract(Duration(minutes: baseOffsetMinutes));
    final offset = offsetMinutesAt(guess);
    final candidate = wallTime.subtract(Duration(minutes: offset));
    return wallTime.subtract(Duration(minutes: offsetMinutesAt(candidate)));
  }

  /// Models `today.difference(lastMutualDay).inDays` for two *local*
  /// `DateTime`s: Dart subtracts absolute instants, so a local day shortened
  /// by a spring-forward transition is 23 hours and `inDays` collapses to 0.
  /// Defect 1.6.
  int wallDayDifference(DateTime todayKey, DateTime otherDayKey) =>
      instantOfWall(todayKey).difference(instantOfWall(otherDayKey)).inDays;
}

// ── Data carriers ─────────────────────────────────────────────────────────

/// The streak-relevant slice of a `chatRooms/{id}` document.
class LegacyRoomDoc {
  LegacyRoomDoc({
    this.exists = true,
    this.streakCount = 0,
    this.lastInteractionDate,
    Map<String, DateTime>? lastSentAt,
    this.previousStreakCount = 0,
    this.streakBrokenAt,
  }) : lastSentAt = Map<String, DateTime>.from(lastSentAt ?? const {});

  final bool exists;
  final int streakCount;
  final DateTime? lastInteractionDate;
  final Map<String, DateTime> lastSentAt;
  final int previousStreakCount;
  final DateTime? streakBrokenAt;

  LegacyRoomDoc copyWith({
    int? streakCount,
    DateTime? lastInteractionDate,
    bool clearLastInteractionDate = false,
    Map<String, DateTime>? lastSentAt,
    int? previousStreakCount,
    DateTime? streakBrokenAt,
    bool clearStreakBrokenAt = false,
  }) =>
      LegacyRoomDoc(
        exists: exists,
        streakCount: streakCount ?? this.streakCount,
        lastInteractionDate: clearLastInteractionDate
            ? null
            : (lastInteractionDate ?? this.lastInteractionDate),
        lastSentAt: lastSentAt ?? this.lastSentAt,
        previousStreakCount: previousStreakCount ?? this.previousStreakCount,
        streakBrokenAt:
            clearStreakBrokenAt ? null : (streakBrokenAt ?? this.streakBrokenAt),
      );

  @override
  String toString() => 'LegacyRoomDoc(streakCount: $streakCount, '
      'lastInteractionDate: $lastInteractionDate, lastSentAt: $lastSentAt, '
      'previousStreakCount: $previousStreakCount, '
      'streakBrokenAt: $streakBrokenAt)';
}

/// Verbatim transcription of `_StreakCacheEntry` (chat_service.dart ~1708).
///
/// [filledAt] is *not* in the original — it is added here only so tests can
/// show that no code path ever compares it against
/// [LegacyStreakReference.declaredCacheTtl]. `legacyEvaluate` never reads it.
class LegacyStreakCacheEntry {
  LegacyStreakCacheEntry({
    required this.streakCount,
    required this.lastInteraction,
    Map<String, DateTime>? lastSentAt,
    this.previousStreakCount = 0,
    this.streakBrokenAt,
    this.filledAt,
  }) : lastSentAt = Map<String, DateTime>.from(lastSentAt ?? const {});

  final int streakCount;
  final DateTime? lastInteraction;
  final Map<String, DateTime> lastSentAt;
  final int previousStreakCount;
  final DateTime? streakBrokenAt;
  final DateTime? filledAt;

  /// `_StreakCacheEntry.fromFirestore(data)`.
  factory LegacyStreakCacheEntry.fromRoomDoc(
    LegacyRoomDoc data, {
    DateTime? filledAt,
  }) =>
      LegacyStreakCacheEntry(
        streakCount: data.streakCount,
        lastInteraction: data.lastInteractionDate,
        lastSentAt: data.lastSentAt,
        previousStreakCount: data.previousStreakCount,
        streakBrokenAt: data.streakBrokenAt,
        filledAt: filledAt,
      );

  @override
  String toString() => 'LegacyStreakCacheEntry(streakCount: $streakCount, '
      'lastInteraction: $lastInteraction, lastSentAt: $lastSentAt, '
      'previousStreakCount: $previousStreakCount, '
      'streakBrokenAt: $streakBrokenAt)';
}

/// Which branch of the legacy `if` ladder ran.
enum LegacyBranch {
  /// `else { debugPrint('[STREAK] Waiting for other user…') }`
  waitingForOtherUser,

  /// `if (lastInteraction == null)` → streak starts at 1.
  firstMutualDay,

  /// `daysDiff == 0` → count unchanged, `lastInteractionDate` refreshed.
  sameDay,

  /// `daysDiff == 1` → count + 1.
  incremented,

  /// `daysDiff >= 2` → broken, restart at 1.
  brokenAndRestarted,
}

/// The exact-match, sender-only milestone call the legacy send path fires:
/// `unawaited(GamificationService.instance.handleStreakMilestone(senderId, newStreak))`.
class LegacyMilestoneCall {
  LegacyMilestoneCall(this.userId, this.newStreak);
  final String userId;
  final int newStreak;

  @override
  String toString() => 'handleStreakMilestone($userId, $newStreak)';
}

class LegacyEvaluation {
  LegacyEvaluation({
    required this.roomUpdates,
    required this.currentStreak,
    required this.newStreak,
    required this.cacheHit,
    required this.readFirestore,
    required this.otherUserId,
    required this.otherSentToday,
    required this.todayKey,
    required this.lastMutualDayKey,
    required this.daysDiff,
    required this.branch,
    required this.nextCache,
    required this.postCommitLastSentAtUpdate,
    required this.milestoneCall,
  });

  /// The `set(merge: true)` payload the batch carries.
  final Map<String, Object?> roomUpdates;
  final int currentStreak;
  final int newStreak;
  final bool cacheHit;

  /// Whether the block performed the blocking `chatRoomRef.get()`.
  final bool readFirestore;
  final String otherUserId;
  final bool otherSentToday;
  final DateTime todayKey;
  final DateTime? lastMutualDayKey;

  /// `today.difference(lastMutualDay).inDays`, or null when that line was
  /// never reached.
  final int? daysDiff;
  final LegacyBranch branch;

  /// The entry written back into `_streakCache`.
  final LegacyStreakCacheEntry nextCache;

  /// The separate, fire-and-forget, post-`batch.commit()` write:
  /// `chatRoomRef.update({'lastSentAt.$senderId': Timestamp.fromDate(DateTime.now())})`.
  /// Not part of [roomUpdates] — defects 1.7 / 1.8.
  final Map<String, DateTime> postCommitLastSentAtUpdate;

  final LegacyMilestoneCall? milestoneCall;

  int? get streakCountWritten => roomUpdates['streakCount'] as int?;
  DateTime? get lastInteractionDateWritten =>
      roomUpdates['lastInteractionDate'] as DateTime?;
  bool get wroteLastInteractionDate =>
      roomUpdates.containsKey('lastInteractionDate');

  @override
  String toString() => 'LegacyEvaluation(branch: $branch, '
      'currentStreak: $currentStreak → newStreak: $newStreak, '
      'cacheHit: $cacheHit, otherSentToday: $otherSentToday, '
      'daysDiff: $daysDiff, roomUpdates: $roomUpdates)';
}

// ── The frozen block ──────────────────────────────────────────────────────

/// Verbatim transcription of the streak block in `ChatService._commitMessage`.
///
/// [cache] is the room's `_streakCache` entry (null = cache miss, which is the
/// only path that reads Firestore). [now] is the sending device's clock.
/// [zone] is that device's local timezone. [messageType] is the message type —
/// the legacy block ignores it entirely, which is defect 1.10.
LegacyEvaluation legacyEvaluate({
  required LegacyRoomDoc stored,
  required String senderId,
  required String receiverId,
  LegacyStreakCacheEntry? cache,
  required DateTime now,
  LegacyDeviceZone? zone,
  String messageType = 'text',
  DateTime? postCommitNow,
}) {
  LegacyStreakReference.evaluateCallCount++;
  final tz = zone ?? LegacyDeviceZone.ist;

  // The room payload the batch already carries before the streak block runs.
  final roomUpdates = <String, Object?>{
    'id': 'room',
    'participants': [senderId, receiverId]..sort(),
  };
  if (messageType != 'reaction') {
    roomUpdates['lastMessageSenderId'] = senderId;
    roomUpdates['lastMessageTime'] = now;
  }

  // ── Try in-memory streak cache first (hot path) ──────────────────
  LegacyStreakCacheEntry? cached = cache;
  final bool cacheHit = cached != null;
  bool readFirestore = false;
  int currentStreak;
  DateTime? lastInteraction;
  Map<String, DateTime> lastSentAt;
  int previousStreakCount;
  DateTime? streakBrokenAt;

  if (cacheHit) {
    currentStreak = cached.streakCount;
    lastInteraction = cached.lastInteraction;
    lastSentAt = Map<String, DateTime>.from(cached.lastSentAt);
    previousStreakCount = cached.previousStreakCount;
    streakBrokenAt = cached.streakBrokenAt;
  } else {
    // Cache miss — do the Firestore read (cold start or room not yet cached).
    readFirestore = true;
    currentStreak = 0;
    lastInteraction = null;
    lastSentAt = {};
    previousStreakCount = 0;
    streakBrokenAt = null;

    if (stored.exists) {
      cached = LegacyStreakCacheEntry.fromRoomDoc(stored, filledAt: now);
      currentStreak = cached.streakCount;
      lastInteraction = cached.lastInteraction;
      lastSentAt = Map<String, DateTime>.from(cached.lastSentAt);
      previousStreakCount = cached.previousStreakCount;
      streakBrokenAt = cached.streakBrokenAt;
    }
  }

  final nowWall = tz.wall(now);
  final today = tz.dayKey(nowWall);

  // Clean up expired restore windows (>24h after break)
  if (streakBrokenAt != null && now.difference(streakBrokenAt).inHours > 24) {
    previousStreakCount = 0;
    streakBrokenAt = null;
    roomUpdates['previousStreakCount'] = 0;
    roomUpdates['streakBrokenAt'] = null;
  }

  // Record this sender's last-send time (in-memory for the logic below).
  // NOTE (original comment): lastSentAt is intentionally NOT written via
  // roomUpdates — set(merge:true) treats 'lastSentAt.$uid' as a literal
  // top-level field name. It is written by a separate update() after commit.
  lastSentAt[senderId] = now;

  // Determine the other participant
  final otherUserId = senderId == receiverId ? senderId : receiverId;
  final otherLastSent = lastSentAt[otherUserId];

  int newStreak = currentStreak;

  // Check if BOTH participants have sent at least one message TODAY
  final otherLocal = otherLastSent == null ? null : tz.wall(otherLastSent);
  final otherSentToday = otherLocal != null &&
      otherLocal.year == today.year &&
      otherLocal.month == today.month &&
      otherLocal.day == today.day;

  int? daysDiff;
  DateTime? lastMutualDayKey;
  LegacyBranch branch;

  // Only evaluate streak when today becomes a mutual day
  if (otherSentToday) {
    if (lastInteraction == null) {
      // First-ever mutual day — start the streak
      newStreak = 1;
      roomUpdates['lastInteractionDate'] = now;
      branch = LegacyBranch.firstMutualDay;
    } else {
      final lastMutualDay = tz.dayKey(tz.wall(lastInteraction));
      lastMutualDayKey = lastMutualDay;
      daysDiff = tz.wallDayDifference(today, lastMutualDay);

      if (daysDiff == 0) {
        // Same day — count stays, but refresh the interaction timestamp so
        // the streak badge timer resets.
        roomUpdates['lastInteractionDate'] = now;
        branch = LegacyBranch.sameDay;
      } else if (daysDiff == 1) {
        // Yesterday → streak increments!
        newStreak = currentStreak + 1;
        roomUpdates['lastInteractionDate'] = now;
        branch = LegacyBranch.incremented;
      } else {
        // 2+ days gap → streak broken
        if (currentStreak > 0) {
          previousStreakCount = currentStreak;
          streakBrokenAt = now;
          roomUpdates['previousStreakCount'] = currentStreak;
          roomUpdates['streakBrokenAt'] = now;
        }
        newStreak = 1; // Fresh mutual day starts a new streak
        roomUpdates['lastInteractionDate'] = now;
        branch = LegacyBranch.brokenAndRestarted;
      }
    }
  } else {
    branch = LegacyBranch.waitingForOtherUser;
  }

  roomUpdates['streakCount'] = newStreak;

  // ── Update in-memory cache so the next send to this room skips the
  //     Firestore read entirely (hot path).
  //
  // NOTE: `lastInteraction: now` is written on EVERY branch, including
  // `waitingForOtherUser` — the anchor advances without a mutual day.
  // Defect 1.2.
  final nextCache = LegacyStreakCacheEntry(
    streakCount: newStreak,
    lastInteraction: now,
    lastSentAt: lastSentAt,
    previousStreakCount: previousStreakCount,
    streakBrokenAt: streakBrokenAt,
    filledAt: cached?.filledAt ?? now,
  );

  // Fire streak milestone rewards in the background — exact match, sender only.
  LegacyMilestoneCall? milestoneCall;
  if (newStreak > currentStreak &&
      (newStreak == 7 || newStreak == 30 || newStreak == 100)) {
    milestoneCall = LegacyMilestoneCall(senderId, newStreak);
  }

  return LegacyEvaluation(
    roomUpdates: roomUpdates,
    currentStreak: currentStreak,
    newStreak: newStreak,
    cacheHit: cacheHit,
    readFirestore: readFirestore,
    otherUserId: otherUserId,
    otherSentToday: otherSentToday,
    todayKey: today,
    lastMutualDayKey: lastMutualDayKey,
    daysDiff: daysDiff,
    branch: branch,
    nextCache: nextCache,
    // Second `DateTime.now()`, fire-and-forget, after batch.commit().
    postCommitLastSentAtUpdate: {senderId: postCommitNow ?? now},
    milestoneCall: milestoneCall,
  );
}

/// Models `batch.set(chatRoomRef, roomUpdates, SetOptions(merge: true))`:
/// every key present in the payload overwrites the stored value, keys absent
/// from the payload are left alone. Last writer wins — there is no transaction
/// and no read-modify-write guard. Defect 1.4.
LegacyRoomDoc legacyMergeRoomDoc(
  LegacyRoomDoc stored,
  Map<String, Object?> roomUpdates, {
  Map<String, DateTime>? postCommitLastSentAtUpdate,
}) {
  final lastSentAt = Map<String, DateTime>.from(stored.lastSentAt);
  postCommitLastSentAtUpdate?.forEach((uid, instant) {
    lastSentAt[uid] = instant;
  });
  return LegacyRoomDoc(
    exists: true,
    streakCount: roomUpdates.containsKey('streakCount')
        ? roomUpdates['streakCount'] as int
        : stored.streakCount,
    lastInteractionDate: roomUpdates.containsKey('lastInteractionDate')
        ? roomUpdates['lastInteractionDate'] as DateTime?
        : stored.lastInteractionDate,
    lastSentAt: lastSentAt,
    previousStreakCount: roomUpdates.containsKey('previousStreakCount')
        ? roomUpdates['previousStreakCount'] as int
        : stored.previousStreakCount,
    streakBrokenAt: roomUpdates.containsKey('streakBrokenAt')
        ? roomUpdates['streakBrokenAt'] as DateTime?
        : stored.streakBrokenAt,
  );
}

// ── Read path (there is no evaluation on read) ─────────────────────────────

/// What every display path does today: `room.streakCount`, verbatim, with no
/// evaluation and no freshness check — `StreakBadge(streakCount: room.streakCount,
/// lastInteractionDate: room.lastInteractionDate)` in home_screen / chat_screen /
/// gup_arcade_screen, and `ChatCacheService._chatRoomFromJson` rehydrating the
/// same two fields verbatim. Defects 1.13 / 1.17.
int legacyDisplayStreakCount(LegacyRoomDoc stored) => stored.streakCount;

/// `ChatCacheService._chatRoomFromJson` — no `cachedAt`, no evaluation.
LegacyRoomDoc legacyCacheRehydrate(Map<String, Object?> json) => LegacyRoomDoc(
      streakCount: (json['streakCount'] as int?) ?? 0,
      lastInteractionDate: json['lastInteractionDate'] as DateTime?,
      previousStreakCount: (json['previousStreakCount'] as int?) ?? 0,
      streakBrokenAt: json['streakBrokenAt'] as DateTime?,
    );

// ── Restore (GamificationService.restoreStreak) ────────────────────────────

class LegacyRestoreOutcome {
  LegacyRestoreOutcome({
    required this.succeeded,
    required this.roomUpdates,
    required this.pointsAfter,
    required this.invalidatedCacheOnThisDeviceOnly,
  });

  final bool succeeded;
  final Map<String, Object?> roomUpdates;
  final int pointsAfter;

  /// `ChatService.invalidateStreakCache(chatRoomId)` — only ever runs on the
  /// restoring device; the partner's static cache is untouched. Defect 1.19.
  final bool invalidatedCacheOnThisDeviceOnly;
}

/// Verbatim transcription of `GamificationService.restoreStreak`: the 24-hour
/// window is validated against the *client* clock, and the restore writes
/// `lastInteractionDate: DateTime.now()` — fabricating a mutual-day anchor on
/// a day when no mutual message happened. Defects 1.18 / 1.19.
LegacyRestoreOutcome legacyRestoreStreak({
  required LegacyRoomDoc stored,
  required int gupPoints,
  required int cost,
  required DateTime clientNow,
}) {
  if (gupPoints < cost) {
    return LegacyRestoreOutcome(
      succeeded: false,
      roomUpdates: const {},
      pointsAfter: gupPoints,
      invalidatedCacheOnThisDeviceOnly: false,
    );
  }
  final previousStreak = stored.previousStreakCount;
  if (previousStreak <= 0) {
    return LegacyRestoreOutcome(
      succeeded: false,
      roomUpdates: const {},
      pointsAfter: gupPoints,
      invalidatedCacheOnThisDeviceOnly: false,
    );
  }
  final brokenAt = stored.streakBrokenAt;
  if (brokenAt == null) {
    return LegacyRestoreOutcome(
      succeeded: false,
      roomUpdates: const {},
      pointsAfter: gupPoints,
      invalidatedCacheOnThisDeviceOnly: false,
    );
  }
  if (clientNow.difference(brokenAt).inHours > 24) {
    return LegacyRestoreOutcome(
      succeeded: false,
      roomUpdates: const {},
      pointsAfter: gupPoints,
      invalidatedCacheOnThisDeviceOnly: false,
    );
  }

  return LegacyRestoreOutcome(
    succeeded: true,
    roomUpdates: <String, Object?>{
      'streakCount': previousStreak,
      'previousStreakCount': 0,
      'streakBrokenAt': null,
      'lastInteractionDate': clientNow,
    },
    pointsAfter: gupPoints - cost,
    invalidatedCacheOnThisDeviceOnly: true,
  );
}

/// `GamificationService.getRestoreCost` — tiered, display-and-charge in one.
int legacyRestoreCost(int streakCount) {
  if (streakCount >= 100) return 100;
  if (streakCount >= 30) return 50;
  if (streakCount >= 10) return 25;
  return 10;
}

// ── Milestones (GamificationService.handleStreakMilestone) ─────────────────

/// Verbatim transcription of the transaction body in
/// `GamificationService.handleStreakMilestone`. Returns the `updates` map it
/// would write (empty map = no write at all). Exact-match thresholds, and
/// `longestStreak` is only ever touched from inside here. Defects 1.21 / 1.22.
Map<String, Object?> legacyMilestoneUpdates({
  required int newStreak,
  required int longestStreak,
  required int gupPoints,
  required List<String> badges,
}) {
  final updates = <String, Object?>{};
  var currentPoints = gupPoints;
  final nextBadges = List<String>.from(badges);

  if (newStreak > longestStreak) {
    updates['longestStreak'] = newStreak;
  }

  if (newStreak == 7) {
    currentPoints += 25;
    updates['gupPoints'] = currentPoints;
    if (!nextBadges.contains('streak_warrior')) {
      nextBadges.add('streak_warrior');
      updates['badges'] = nextBadges;
    }
  } else if (newStreak == 30) {
    currentPoints += 50;
    updates['gupPoints'] = currentPoints;
  } else if (newStreak == 100) {
    currentPoints += 100;
    updates['gupPoints'] = currentPoints;
  }

  return updates;
}

// ── Pro free-restore perk (SubscriptionService) ────────────────────────────

/// Keys from `SubscriptionService`.
const String kLastStreakRestore = 'last_streak_restore';
const String kStreakRestoreCount = 'streak_restore_count';

/// `SubscriptionService._weekNumber` — ISO-8601-ish week number.
int legacyWeekNumber(DateTime date) {
  final dayOfYear = date.difference(DateTime.utc(date.year, 1, 1)).inDays;
  return ((dayOfYear - date.weekday + 10) / 7).floor();
}

/// `SubscriptionService.canRestoreStreakFree`, driven by an in-memory
/// stand-in for `SharedPreferences`.
bool legacyCanRestoreStreakFree({
  required bool isPro,
  required Map<String, int> prefs,
  required DateTime now,
}) {
  if (!isPro) return false;

  final lastRestore = prefs[kLastStreakRestore];
  final restoreCount = prefs[kStreakRestoreCount] ?? 0;

  if (lastRestore == null) return true; // never restored

  final lastDate = DateTime.fromMillisecondsSinceEpoch(lastRestore, isUtc: true);

  final lastWeek = legacyWeekNumber(lastDate);
  final currentWeek = legacyWeekNumber(now);

  if (currentWeek != lastWeek || now.year != lastDate.year) {
    return true; // new week
  }

  return restoreCount < 1; // 1 free restore per week for Pro
}

/// `SubscriptionService.recordStreakRestore`. The write happens *first*, then
/// the same key is read back, so `lastDate == now` and therefore
/// `lastWeek == currentWeek` on every single call — the reset branch is dead
/// code and the counter only ever grows. Defect 1.20.
///
/// Returns the `(lastWeek, currentWeek)` pair it computed, so the test can
/// assert they are always equal.
({int lastWeek, int currentWeek, int count}) legacyRecordStreakRestore({
  required Map<String, int> prefs,
  required DateTime now,
}) {
  prefs[kLastStreakRestore] = now.millisecondsSinceEpoch;

  final lastRestore = prefs[kLastStreakRestore];
  final lastDate = lastRestore != null
      ? DateTime.fromMillisecondsSinceEpoch(lastRestore, isUtc: true)
      : now;
  final lastWeek = legacyWeekNumber(lastDate);
  final currentWeek = legacyWeekNumber(now);

  var count = prefs[kStreakRestoreCount] ?? 0;
  if (currentWeek != lastWeek || now.year != lastDate.year) {
    count = 1; // reset for new week — unreachable
  } else {
    count += 1;
  }
  prefs[kStreakRestoreCount] = count;

  return (lastWeek: lastWeek, currentWeek: currentWeek, count: count);
}

// ════════════════════════════════════════════════════════════════════════════
//  FROZEN LEGACY BADGE RULE (defect 1.15)
// ════════════════════════════════════════════════════════════════════════════
//
// Verbatim transcription of the risk/countdown logic that used to live in
// `lib/widgets/streak_badge.dart`: a three-value enum with 20h/36h/48h
// thresholds measured off `lastInteractionDate`, i.e. a *different* rule from
// the calendar-day break rule the rest of the system used. Task 8.1 replaced
// the widget's copy with the deadline-based canonical rule; this frozen copy
// stays so the exploration test still pins the original divergence.

/// The legacy badge's own risk enum — three values, no `broken` state.
enum LegacyBadgeRiskLevel { normal, atRisk, critical }

/// Verbatim `computeStreakRisk` from the pre-fix `streak_badge.dart`.
LegacyBadgeRiskLevel legacyComputeStreakRisk(DateTime? lastInteractionDate) {
  if (lastInteractionDate == null) return LegacyBadgeRiskLevel.normal;
  final hoursSince = DateTime.now().difference(lastInteractionDate).inHours;
  if (hoursSince >= 36) return LegacyBadgeRiskLevel.critical;
  if (hoursSince >= 20) return LegacyBadgeRiskLevel.atRisk;
  return LegacyBadgeRiskLevel.normal;
}

/// Verbatim `computeTimeRemaining` from the pre-fix `streak_badge.dart`:
/// 48 hours from `lastInteractionDate`, unrelated to the break deadline.
Duration? legacyComputeTimeRemaining(DateTime? lastInteractionDate) {
  if (lastInteractionDate == null) return null;
  final expiry = lastInteractionDate.add(const Duration(hours: 48));
  final remaining = expiry.difference(DateTime.now());
  if (remaining.isNegative) return Duration.zero;
  return remaining;
}
