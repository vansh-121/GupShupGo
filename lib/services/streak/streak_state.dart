/// The authoritative streak state document, as a pure Dart value type.
///
/// Mirrors `chatRooms/{roomId}/streak/state` at `schemaVersion: 2` (see the
/// design's "Authoritative state document"). This file is the only place the
/// document's shape is written down on the client.
///
/// Hard rules for this file (enforced by the purity guard test):
///
///  * no `DateTime.now()` — every instant is supplied by the caller,
///  * no `toLocal()` — the device zone is irrelevant to a streak,
///  * no `cloud_firestore` import — see "Timestamps" below.
///
/// ## Timestamps
///
/// The Firestore layer hands us `Timestamp` values, but importing
/// `cloud_firestore` here would drag the plugin into the pure domain layer and
/// into every engine test. Instead:
///
///  * **Reading** goes through [streakInstantFrom], which normalises anything
///    the transport can produce to a UTC [DateTime]: a `DateTime`, epoch
///    millis, an ISO-8601 string, a JSON-serialised Timestamp
///    (`{_seconds, _nanoseconds}`), or — duck-typed, with no import — any
///    object exposing `toDate()` or `millisecondsSinceEpoch`, which is exactly
///    what `Timestamp` is.
///  * **Writing** emits UTC [DateTime] values from [toMap]. `cloud_firestore`
///    converts `DateTime` to `Timestamp` on write, so the persisted document is
///    identical to one written with explicit `Timestamp`s, and the engine stays
///    testable with no Firebase at all.
///  * [toCacheJson] emits epoch millis instead, because the disk cache is
///    `jsonEncode`d.
library;

import 'streak_day.dart';

/// The schema version this client writes and understands.
const int kStreakSchemaVersion = 2;

/// The oldest `schemaVersion` on `chatRooms/{roomId}/streak/state` that the v2
/// reader accepts. Anything lower means "fall back to [StreakState.fromLegacy]"
/// during the dual-read compatibility window.
const int kStreakMinStateSchemaVersion = 2;

/// Marks a [StreakState] projected from the legacy `ChatRoom` fields rather
/// than read from the authoritative document.
const int kStreakLegacySchemaVersion = 1;

/// Beyond this window an observed state is considered stale: the count still
/// renders (so the chat list is never blank offline) but the countdown is
/// suppressed and the repository revalidates.
const Duration kStreakFreshnessWindow = Duration(minutes: 15);

/// How long a broken streak stays restorable.
const Duration kStreakRestoreWindow = Duration(hours: 24);

/// How the badge should present a bond, stamped by the server and re-derived
/// by the client from `deadlineAt`.
enum StreakRiskLevel {
  normal,
  atRisk,
  critical,
  broken;

  /// The persisted string. Pinned here so renaming a Dart identifier can never
  /// silently change the wire format.
  String get wire => switch (this) {
        StreakRiskLevel.normal => 'normal',
        StreakRiskLevel.atRisk => 'atRisk',
        StreakRiskLevel.critical => 'critical',
        StreakRiskLevel.broken => 'broken',
      };

  /// Parses [value], returning `null` when it is not a known level.
  static StreakRiskLevel? tryParse(Object? value) {
    if (value is StreakRiskLevel) return value;
    if (value is! String) return null;
    for (final level in StreakRiskLevel.values) {
      if (level.wire == value) return level;
    }
    return null;
  }

  /// Parses [value], falling back to [fallback] for unknown or missing input so
  /// a future writer's new level cannot break an old client.
  static StreakRiskLevel parse(
    Object? value, {
    StreakRiskLevel fallback = StreakRiskLevel.normal,
  }) =>
      tryParse(value) ?? fallback;
}

/// One thing the engine decided about a state. Emitted as a list, in the order
/// the engine's steps produced them.
enum StreakTransition {
  participationRecorded,
  started,
  incremented,
  sameDay,
  broken,
  restoreWindowExpired,
  milestoneCrossed,
  longestRaised,
  noop;

  /// The persisted string. Pinned, for the same reason as
  /// [StreakRiskLevel.wire] — the shared golden fixture and the JS engine both
  /// depend on these exact spellings.
  String get wire => switch (this) {
        StreakTransition.participationRecorded => 'participationRecorded',
        StreakTransition.started => 'started',
        StreakTransition.incremented => 'incremented',
        StreakTransition.sameDay => 'sameDay',
        StreakTransition.broken => 'broken',
        StreakTransition.restoreWindowExpired => 'restoreWindowExpired',
        StreakTransition.milestoneCrossed => 'milestoneCrossed',
        StreakTransition.longestRaised => 'longestRaised',
        StreakTransition.noop => 'noop',
      };

  static StreakTransition? tryParse(Object? value) {
    if (value is StreakTransition) return value;
    if (value is! String) return null;
    for (final transition in StreakTransition.values) {
      if (transition.wire == value) return transition;
    }
    return null;
  }
}

/// Who or what triggered an evaluation. Stored as `lastEvaluatedBy`.
class StreakEvaluationSource {
  const StreakEvaluationSource._();

  static const String send = 'send';
  static const String sweep = 'sweep';
  static const String restore = 'restore';
  static const String repair = 'repair';
  static const String nudge = 'nudge';
  static const String read = 'read';
}

/// Sentinel for [StreakState.copyWith], so "leave alone" and "set to null" are
/// distinguishable on nullable fields.
const Object _unset = Object();

/// The `chatRooms/{roomId}/streak/state` document.
///
/// Immutable value type: two states with equal fields are equal and hash
/// alike, which is what lets the engine report `changed == false` for a genuine
/// no-op.
class StreakState {
  const StreakState({
    this.schemaVersion = kStreakSchemaVersion,
    this.engineVersion = 0,
    this.rev = 0,
    this.dayZone = kCanonicalDayZone,
    this.dayZoneOffsetMinutes = kCanonicalDayOffsetMinutes,
    this.participants = const <String>[],
    this.count = 0,
    this.lastMutualDay,
    this.bridgedThroughDay,
    this.deadlineAt,
    this.riskLevel = StreakRiskLevel.normal,
    this.sendDays = const <String, StreakDay>{},
    this.sendInstants = const <String, DateTime>{},
    this.previousCount = 0,
    this.brokenAt,
    this.restoreDeadlineAt,
    this.restoredAt,
    this.restoredBy,
    this.restoreCostPaid,
    this.milestonesAwarded = const <int>[],
    this.longestForRoom = 0,
    this.recentApplied = const <String, DateTime>{},
    this.notifiedAt = const <String, DateTime>{},
    this.lastEvaluatedAt,
    this.lastEvaluatedBy,
    this.repairedAt,
    this.repairSource,
    this.repairPreviousLegacyCount,
    this.extraFields = const <String, dynamic>{},
    this.receivedAt,
    this.cachedAt,
  });

  /// A brand-new, never-evaluated state for [participants].
  factory StreakState.empty({List<String> participants = const <String>[]}) =>
      StreakState(participants: _sortedUnique(participants));

  // --- document fields -------------------------------------------------------

  final int schemaVersion;
  final int engineVersion;

  /// Incremented on every server write; the stale-writer guard.
  final int rev;

  final String dayZone;
  final int dayZoneOffsetMinutes;

  /// Sorted, denormalised for rules and collection-group sweeps.
  final List<String> participants;

  final int count;

  /// The newest day both participants sent on. The streak anchor.
  final StreakDay? lastMutualDay;

  /// Set by a restore; never a real mutual day. Keeps the chain continuous
  /// without pretending a mutual day happened.
  final StreakDay? bridgedThroughDay;

  /// `dayStartUtc(continuityHorizon + 2)`. UTC.
  final DateTime? deadlineAt;

  final StreakRiskLevel riskLevel;

  /// Latest qualifying send day per participant.
  final Map<String, StreakDay> sendDays;

  /// Server instant of that send, for diagnostics. UTC.
  final Map<String, DateTime> sendInstants;

  final int previousCount;

  /// The deadline that lapsed, not the instant the sweeper noticed. UTC.
  final DateTime? brokenAt;

  /// `brokenAt + 24h`. UTC.
  final DateTime? restoreDeadlineAt;

  final DateTime? restoredAt;
  final String? restoredBy;
  final int? restoreCostPaid;

  /// Thresholds already paid out, so a re-award is impossible.
  final List<int> milestonesAwarded;

  final int longestForRoom;

  /// `'uid#YYYY-MM-DD' -> instant`, pruned to three days. Guards the
  /// non-idempotent side effects.
  final Map<String, DateTime> recentApplied;

  /// `'atRisk' | 'critical' | 'broken' | 'milestone_7' | ... -> instant`.
  final Map<String, DateTime> notifiedAt;

  final DateTime? lastEvaluatedAt;

  /// One of [StreakEvaluationSource].
  final String? lastEvaluatedBy;

  final DateTime? repairedAt;

  /// `'history'`, `'history:truncated'`, `'fallback:no-history'`.
  final String? repairSource;

  final int? repairPreviousLegacyCount;

  /// Fields written by a newer engine that this build does not know about.
  /// Carried through [toMap] and [toCacheJson] so a round trip never drops
  /// data.
  final Map<String, dynamic> extraFields;

  // --- transport metadata (never persisted on the server document) -----------

  /// When this state arrived from the Firestore stream. UTC.
  final DateTime? receivedAt;

  /// When this state was written to the disk cache. UTC.
  final DateTime? cachedAt;

  // --- derived ---------------------------------------------------------------

  /// `max(lastMutualDay, bridgedThroughDay)` — the day continuity is measured
  /// from.
  StreakDay? get continuityHorizon =>
      StreakDay.max(lastMutualDay, bridgedThroughDay);

  /// True when this state was projected from the legacy `ChatRoom` fields
  /// rather than read from the authoritative document.
  bool get isLegacyProjection => schemaVersion < kStreakMinStateSchemaVersion;

  /// True while a broken streak can still be restored (relative to [now]).
  bool isRestorable(DateTime now) =>
      brokenAt != null &&
      restoreDeadlineAt != null &&
      !now.toUtc().isAfter(restoreDeadlineAt!);

  /// The instant this state was observed: the stream emission, else the cache
  /// write. `null` when the state was constructed in memory.
  DateTime? get observedAt => receivedAt ?? cachedAt;

  /// Whether the observation is older than [window]. An unobserved state is
  /// treated as stale, because nothing vouches for it.
  bool isStaleAt(DateTime now, {Duration window = kStreakFreshnessWindow}) {
    final anchor = observedAt;
    if (anchor == null) return true;
    return now.toUtc().difference(anchor) > window;
  }

  /// The latest send day recorded for [uid], or `null`.
  StreakDay? sendDayFor(String uid) => sendDays[uid];

  // --- reading ---------------------------------------------------------------

  /// Hydrates the authoritative document.
  ///
  /// Returns `null` when [data] is null, empty, or carries a `schemaVersion`
  /// below [kStreakMinStateSchemaVersion] — the caller then falls back to
  /// [StreakState.fromLegacy]. A *higher* schema version is accepted: unknown
  /// fields are preserved in [extraFields], so a newer writer degrades to
  /// "some fields I don't use" rather than "no streak".
  ///
  /// Every field is optional and every malformed value is dropped rather than
  /// thrown on; a partially-written document must still render a count.
  static StreakState? fromStateDoc(
    Map<String, dynamic>? data, {
    DateTime? receivedAt,
    List<String>? participantsFallback,
  }) {
    if (data == null || data.isEmpty) return null;
    final schemaVersion = _asInt(data['schemaVersion'], 0);
    if (schemaVersion < kStreakMinStateSchemaVersion) return null;
    return _fromMap(
      data,
      schemaVersion: schemaVersion,
      receivedAt: receivedAt?.toUtc(),
      cachedAt: null,
      participantsFallback: participantsFallback,
    );
  }

  /// Projects the legacy `ChatRoom` streak fields onto a [StreakState] for the
  /// dual-read window.
  ///
  /// Takes the raw field values rather than a `ChatRoom` so this file does not
  /// have to import the model (and through it `cloud_firestore`). Instants may
  /// be anything [streakInstantFrom] accepts. See [fromLegacyRoomMap] for the
  /// map-shaped convenience entry point.
  ///
  /// The projection is deliberately conservative: it derives an anchor and a
  /// deadline from `lastInteractionDate`, and leaves everything the legacy
  /// schema cannot know (milestones, bridged days, notification bookkeeping)
  /// empty. `riskLevel` is a placeholder — the engine recomputes it from
  /// `deadlineAt` on every read.
  static StreakState fromLegacy({
    List<String> participants = const <String>[],
    int streakCount = 0,
    Object? lastInteractionDate,
    Map<String, dynamic> lastSentAt = const <String, dynamic>{},
    int previousStreakCount = 0,
    Object? streakBrokenAt,
    int offsetMinutes = kCanonicalDayOffsetMinutes,
    DateTime? receivedAt,
    DateTime? cachedAt,
  }) {
    final count = streakCount < 0 ? 0 : streakCount;
    final interaction = streakInstantFrom(lastInteractionDate);
    final anchor = count > 0 && interaction != null
        ? StreakDay.fromInstant(interaction, offsetMinutes: offsetMinutes)
        : null;
    final broken = streakInstantFrom(streakBrokenAt);

    final sendInstants = <String, DateTime>{};
    final sendDays = <String, StreakDay>{};
    lastSentAt.forEach((uid, value) {
      final instant = streakInstantFrom(value);
      if (instant == null) return;
      sendInstants[uid] = instant;
      sendDays[uid] = StreakDay.fromInstant(instant, offsetMinutes: offsetMinutes);
    });

    return StreakState(
      schemaVersion: kStreakLegacySchemaVersion,
      engineVersion: 0,
      rev: 0,
      dayZoneOffsetMinutes: offsetMinutes,
      participants: _sortedUnique(participants),
      count: count,
      lastMutualDay: anchor,
      deadlineAt: anchor?.plusDays(2).startUtc(offsetMinutes: offsetMinutes),
      riskLevel: count == 0 && broken != null
          ? StreakRiskLevel.broken
          : StreakRiskLevel.normal,
      sendDays: sendDays,
      sendInstants: sendInstants,
      previousCount: previousStreakCount < 0 ? 0 : previousStreakCount,
      brokenAt: broken,
      restoreDeadlineAt: broken?.add(kStreakRestoreWindow),
      longestForRoom: count,
      receivedAt: receivedAt?.toUtc(),
      cachedAt: cachedAt?.toUtc(),
    );
  }

  /// [fromLegacy] driven by a room-shaped map: a raw `chatRooms/{roomId}`
  /// document, `ChatRoom.toMap()`, or a legacy cache entry.
  static StreakState fromLegacyRoomMap(
    Map<String, dynamic>? room, {
    List<String>? participants,
    int offsetMinutes = kCanonicalDayOffsetMinutes,
    DateTime? receivedAt,
    DateTime? cachedAt,
  }) {
    final data = room ?? const <String, dynamic>{};
    return fromLegacy(
      participants: participants ?? _asStringList(data['participants']),
      streakCount: _asInt(data['streakCount'], 0),
      lastInteractionDate: data['lastInteractionDate'],
      lastSentAt: _asDynamicMap(data['lastSentAt']),
      previousStreakCount: _asInt(data['previousStreakCount'], 0),
      streakBrokenAt: data['streakBrokenAt'],
      offsetMinutes: offsetMinutes,
      receivedAt: receivedAt,
      cachedAt: cachedAt,
    );
  }

  /// Hydrates a state persisted by [toCacheJson].
  ///
  /// Returns `null` when the block is absent, empty or carries no usable
  /// `schemaVersion`. Unlike [fromStateDoc] this accepts a legacy projection
  /// (`schemaVersion == 1`), because that is what an older cache entry holds.
  static StreakState? fromCacheJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return null;
    final schemaVersion = _asInt(json['schemaVersion'], 0);
    if (schemaVersion < kStreakLegacySchemaVersion) return null;
    return _fromMap(
      json,
      schemaVersion: schemaVersion,
      receivedAt: streakInstantFrom(json['receivedAt']),
      cachedAt: streakInstantFrom(json['cachedAt']),
    );
  }

  static StreakState _fromMap(
    Map<String, dynamic> data, {
    required int schemaVersion,
    DateTime? receivedAt,
    DateTime? cachedAt,
    List<String>? participantsFallback,
  }) {
    final participants = _asStringList(data['participants']);
    return StreakState(
      schemaVersion: schemaVersion,
      engineVersion: _asInt(data['engineVersion'], 0),
      rev: _asInt(data['rev'], 0),
      dayZone: data['dayZone'] is String
          ? data['dayZone'] as String
          : kCanonicalDayZone,
      dayZoneOffsetMinutes:
          _asInt(data['dayZoneOffsetMinutes'], kCanonicalDayOffsetMinutes),
      participants: participants.isEmpty
          ? _sortedUnique(participantsFallback ?? const <String>[])
          : participants,
      count: _asInt(data['count'], 0),
      lastMutualDay: _asDay(data['lastMutualDay']),
      bridgedThroughDay: _asDay(data['bridgedThroughDay']),
      deadlineAt: streakInstantFrom(data['deadlineAt']),
      riskLevel: StreakRiskLevel.parse(data['riskLevel']),
      sendDays: _asDayMap(data['sendDays']),
      sendInstants: _asInstantMap(data['sendInstants']),
      previousCount: _asInt(data['previousCount'], 0),
      brokenAt: streakInstantFrom(data['brokenAt']),
      restoreDeadlineAt: streakInstantFrom(data['restoreDeadlineAt']),
      restoredAt: streakInstantFrom(data['restoredAt']),
      restoredBy: data['restoredBy'] is String
          ? data['restoredBy'] as String
          : null,
      restoreCostPaid: _asNullableInt(data['restoreCostPaid']),
      milestonesAwarded: _asIntList(data['milestonesAwarded']),
      longestForRoom: _asInt(data['longestForRoom'], 0),
      recentApplied: _asInstantMap(data['recentApplied']),
      notifiedAt: _asInstantMap(data['notifiedAt']),
      lastEvaluatedAt: streakInstantFrom(data['lastEvaluatedAt']),
      lastEvaluatedBy: data['lastEvaluatedBy'] is String
          ? data['lastEvaluatedBy'] as String
          : null,
      repairedAt: streakInstantFrom(data['repairedAt']),
      repairSource: data['repairSource'] is String
          ? data['repairSource'] as String
          : null,
      repairPreviousLegacyCount:
          _asNullableInt(data['repairPreviousLegacyCount']),
      extraFields: _unknownFields(data),
      receivedAt: receivedAt?.toUtc(),
      cachedAt: cachedAt?.toUtc(),
    );
  }

  // --- writing ---------------------------------------------------------------

  /// The persistence payload.
  ///
  /// Instants are emitted as UTC [DateTime]s; `cloud_firestore` converts them
  /// to `Timestamp` on write. Unknown fields read from a newer writer are
  /// re-emitted first, so a known field always wins.
  Map<String, dynamic> toMap() => <String, dynamic>{
        ...extraFields,
        'schemaVersion': schemaVersion,
        'engineVersion': engineVersion,
        'rev': rev,
        'dayZone': dayZone,
        'dayZoneOffsetMinutes': dayZoneOffsetMinutes,
        'participants': List<String>.unmodifiable(participants),
        'count': count,
        'lastMutualDay': lastMutualDay?.key,
        'bridgedThroughDay': bridgedThroughDay?.key,
        'deadlineAt': deadlineAt,
        'riskLevel': riskLevel.wire,
        'sendDays': sendDays.map((uid, day) => MapEntry(uid, day.key)),
        'sendInstants': Map<String, DateTime>.of(sendInstants),
        'previousCount': previousCount,
        'brokenAt': brokenAt,
        'restoreDeadlineAt': restoreDeadlineAt,
        'restoredAt': restoredAt,
        'restoredBy': restoredBy,
        'restoreCostPaid': restoreCostPaid,
        'milestonesAwarded': List<int>.unmodifiable(milestonesAwarded),
        'longestForRoom': longestForRoom,
        'recentApplied': Map<String, DateTime>.of(recentApplied),
        'notifiedAt': Map<String, DateTime>.of(notifiedAt),
        'lastEvaluatedAt': lastEvaluatedAt,
        'lastEvaluatedBy': lastEvaluatedBy,
        'repairedAt': repairedAt,
        'repairSource': repairSource,
        'repairPreviousLegacyCount': repairPreviousLegacyCount,
      };

  /// The `jsonEncode`-safe disk-cache payload: instants become epoch millis and
  /// [cachedAt] records when the snapshot was taken.
  Map<String, dynamic> toCacheJson({DateTime? cachedAt}) {
    final stamp = (cachedAt ?? this.cachedAt ?? receivedAt)?.toUtc();
    return <String, dynamic>{
      ...extraFields,
      'schemaVersion': schemaVersion,
      'engineVersion': engineVersion,
      'rev': rev,
      'dayZone': dayZone,
      'dayZoneOffsetMinutes': dayZoneOffsetMinutes,
      'participants': List<String>.of(participants),
      'count': count,
      'lastMutualDay': lastMutualDay?.key,
      'bridgedThroughDay': bridgedThroughDay?.key,
      'deadlineAt': _millis(deadlineAt),
      'riskLevel': riskLevel.wire,
      'sendDays': sendDays.map((uid, day) => MapEntry(uid, day.key)),
      'sendInstants':
          sendInstants.map((uid, at) => MapEntry(uid, _millis(at))),
      'previousCount': previousCount,
      'brokenAt': _millis(brokenAt),
      'restoreDeadlineAt': _millis(restoreDeadlineAt),
      'restoredAt': _millis(restoredAt),
      'restoredBy': restoredBy,
      'restoreCostPaid': restoreCostPaid,
      'milestonesAwarded': List<int>.of(milestonesAwarded),
      'longestForRoom': longestForRoom,
      'recentApplied':
          recentApplied.map((key, at) => MapEntry(key, _millis(at))),
      'notifiedAt': notifiedAt.map((key, at) => MapEntry(key, _millis(at))),
      'lastEvaluatedAt': _millis(lastEvaluatedAt),
      'lastEvaluatedBy': lastEvaluatedBy,
      'repairedAt': _millis(repairedAt),
      'repairSource': repairSource,
      'repairPreviousLegacyCount': repairPreviousLegacyCount,
      'cachedAt': _millis(stamp),
    };
  }

  /// This state tagged with the instant it arrived from the stream.
  StreakState withReceivedAt(DateTime instant) =>
      copyWith(receivedAt: instant.toUtc());

  StreakState copyWith({
    int? schemaVersion,
    int? engineVersion,
    int? rev,
    String? dayZone,
    int? dayZoneOffsetMinutes,
    List<String>? participants,
    int? count,
    Object? lastMutualDay = _unset,
    Object? bridgedThroughDay = _unset,
    Object? deadlineAt = _unset,
    StreakRiskLevel? riskLevel,
    Map<String, StreakDay>? sendDays,
    Map<String, DateTime>? sendInstants,
    int? previousCount,
    Object? brokenAt = _unset,
    Object? restoreDeadlineAt = _unset,
    Object? restoredAt = _unset,
    Object? restoredBy = _unset,
    Object? restoreCostPaid = _unset,
    List<int>? milestonesAwarded,
    int? longestForRoom,
    Map<String, DateTime>? recentApplied,
    Map<String, DateTime>? notifiedAt,
    Object? lastEvaluatedAt = _unset,
    Object? lastEvaluatedBy = _unset,
    Object? repairedAt = _unset,
    Object? repairSource = _unset,
    Object? repairPreviousLegacyCount = _unset,
    Map<String, dynamic>? extraFields,
    Object? receivedAt = _unset,
    Object? cachedAt = _unset,
  }) {
    return StreakState(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      engineVersion: engineVersion ?? this.engineVersion,
      rev: rev ?? this.rev,
      dayZone: dayZone ?? this.dayZone,
      dayZoneOffsetMinutes: dayZoneOffsetMinutes ?? this.dayZoneOffsetMinutes,
      participants: participants ?? this.participants,
      count: count ?? this.count,
      lastMutualDay: _pick(lastMutualDay, this.lastMutualDay),
      bridgedThroughDay: _pick(bridgedThroughDay, this.bridgedThroughDay),
      deadlineAt: _pick(deadlineAt, this.deadlineAt),
      riskLevel: riskLevel ?? this.riskLevel,
      sendDays: sendDays ?? this.sendDays,
      sendInstants: sendInstants ?? this.sendInstants,
      previousCount: previousCount ?? this.previousCount,
      brokenAt: _pick(brokenAt, this.brokenAt),
      restoreDeadlineAt: _pick(restoreDeadlineAt, this.restoreDeadlineAt),
      restoredAt: _pick(restoredAt, this.restoredAt),
      restoredBy: _pick(restoredBy, this.restoredBy),
      restoreCostPaid: _pick(restoreCostPaid, this.restoreCostPaid),
      milestonesAwarded: milestonesAwarded ?? this.milestonesAwarded,
      longestForRoom: longestForRoom ?? this.longestForRoom,
      recentApplied: recentApplied ?? this.recentApplied,
      notifiedAt: notifiedAt ?? this.notifiedAt,
      lastEvaluatedAt: _pick(lastEvaluatedAt, this.lastEvaluatedAt),
      lastEvaluatedBy: _pick(lastEvaluatedBy, this.lastEvaluatedBy),
      repairedAt: _pick(repairedAt, this.repairedAt),
      repairSource: _pick(repairSource, this.repairSource),
      repairPreviousLegacyCount:
          _pick(repairPreviousLegacyCount, this.repairPreviousLegacyCount),
      extraFields: extraFields ?? this.extraFields,
      receivedAt: _pick(receivedAt, this.receivedAt),
      cachedAt: _pick(cachedAt, this.cachedAt),
    );
  }

  // --- equality --------------------------------------------------------------

  /// Field equality, ignoring the transport metadata ([receivedAt], [cachedAt])
  /// so a re-delivered identical document counts as unchanged.
  bool sameDocumentAs(StreakState other) =>
      schemaVersion == other.schemaVersion &&
      engineVersion == other.engineVersion &&
      rev == other.rev &&
      dayZone == other.dayZone &&
      dayZoneOffsetMinutes == other.dayZoneOffsetMinutes &&
      _listEquals(participants, other.participants) &&
      count == other.count &&
      lastMutualDay == other.lastMutualDay &&
      bridgedThroughDay == other.bridgedThroughDay &&
      deadlineAt == other.deadlineAt &&
      riskLevel == other.riskLevel &&
      _mapEquals(sendDays, other.sendDays) &&
      _mapEquals(sendInstants, other.sendInstants) &&
      previousCount == other.previousCount &&
      brokenAt == other.brokenAt &&
      restoreDeadlineAt == other.restoreDeadlineAt &&
      restoredAt == other.restoredAt &&
      restoredBy == other.restoredBy &&
      restoreCostPaid == other.restoreCostPaid &&
      _listEquals(milestonesAwarded, other.milestonesAwarded) &&
      longestForRoom == other.longestForRoom &&
      _mapEquals(recentApplied, other.recentApplied) &&
      _mapEquals(notifiedAt, other.notifiedAt) &&
      lastEvaluatedAt == other.lastEvaluatedAt &&
      lastEvaluatedBy == other.lastEvaluatedBy &&
      repairedAt == other.repairedAt &&
      repairSource == other.repairSource &&
      repairPreviousLegacyCount == other.repairPreviousLegacyCount &&
      _mapEquals(extraFields, other.extraFields);

  @override
  bool operator ==(Object other) =>
      other is StreakState &&
      sameDocumentAs(other) &&
      receivedAt == other.receivedAt &&
      cachedAt == other.cachedAt;

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        engineVersion,
        rev,
        participants.join(','),
        count,
        lastMutualDay,
        bridgedThroughDay,
        deadlineAt,
        riskLevel,
        previousCount,
        brokenAt,
        restoreDeadlineAt,
        longestForRoom,
        Object.hashAll(milestonesAwarded),
        Object.hashAll(sendDays.keys.toList()..sort()),
        lastEvaluatedAt,
        lastEvaluatedBy,
        repairSource,
        receivedAt,
        cachedAt,
      );

  @override
  String toString() => 'StreakState(count: $count, '
      'lastMutualDay: ${lastMutualDay?.key}, '
      'bridgedThroughDay: ${bridgedThroughDay?.key}, '
      'deadlineAt: ${deadlineAt?.toIso8601String()}, '
      'riskLevel: ${riskLevel.wire}, previousCount: $previousCount, '
      'brokenAt: ${brokenAt?.toIso8601String()}, rev: $rev)';

  // --- parsing helpers -------------------------------------------------------

  /// Keys this build knows about; anything else lands in [extraFields].
  static const Set<String> _knownFields = <String>{
    'schemaVersion',
    'engineVersion',
    'rev',
    'dayZone',
    'dayZoneOffsetMinutes',
    'participants',
    'count',
    'lastMutualDay',
    'bridgedThroughDay',
    'deadlineAt',
    'riskLevel',
    'sendDays',
    'sendInstants',
    'previousCount',
    'brokenAt',
    'restoreDeadlineAt',
    'restoredAt',
    'restoredBy',
    'restoreCostPaid',
    'milestonesAwarded',
    'longestForRoom',
    'recentApplied',
    'notifiedAt',
    'lastEvaluatedAt',
    'lastEvaluatedBy',
    'repairedAt',
    'repairSource',
    'repairPreviousLegacyCount',
    // Transport metadata, handled separately.
    'cachedAt',
    'receivedAt',
  };

  static Map<String, dynamic> _unknownFields(Map<String, dynamic> data) {
    final extras = <String, dynamic>{};
    data.forEach((key, value) {
      if (!_knownFields.contains(key)) extras[key] = value;
    });
    return extras;
  }

  static T? _pick<T>(Object? candidate, T? current) =>
      identical(candidate, _unset) ? current : candidate as T?;

  static List<String> _sortedUnique(Iterable<String> uids) {
    final set = <String>{...uids.where((uid) => uid.isNotEmpty)};
    final list = set.toList()..sort();
    return list;
  }

  static List<String> _asStringList(Object? value) {
    if (value is! Iterable) return const <String>[];
    return _sortedUnique(value.whereType<String>());
  }

  static Map<String, dynamic> _asDynamicMap(Object? value) {
    if (value is! Map) return const <String, dynamic>{};
    final out = <String, dynamic>{};
    value.forEach((key, entry) {
      if (key is String) out[key] = entry;
    });
    return out;
  }

  static int _asInt(Object? value, int fallback) => _asNullableInt(value) ?? fallback;

  static int? _asNullableInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static List<int> _asIntList(Object? value) {
    if (value is! Iterable) return const <int>[];
    final out = <int>{};
    for (final entry in value) {
      final parsed = _asNullableInt(entry);
      if (parsed != null) out.add(parsed);
    }
    final list = out.toList()..sort();
    return list;
  }

  static StreakDay? _asDay(Object? value) {
    if (value is StreakDay) return value;
    if (value is String) return StreakDay.tryParse(value);
    return null;
  }

  static Map<String, StreakDay> _asDayMap(Object? value) {
    final out = <String, StreakDay>{};
    _asDynamicMap(value).forEach((key, entry) {
      final day = _asDay(entry);
      if (day != null) out[key] = day;
    });
    return out;
  }

  static Map<String, DateTime> _asInstantMap(Object? value) {
    final out = <String, DateTime>{};
    _asDynamicMap(value).forEach((key, entry) {
      final instant = streakInstantFrom(entry);
      if (instant != null) out[key] = instant;
    });
    return out;
  }

  static int? _millis(DateTime? value) => value?.toUtc().millisecondsSinceEpoch;
}

/// Normalises any transport representation of an instant to a UTC [DateTime].
///
/// Accepts, in order: `DateTime`, epoch millis (`int`/`num`), an ISO-8601
/// `String`, a JSON-serialised Firestore timestamp
/// (`{_seconds, _nanoseconds}` or `{seconds, nanoseconds}`), and — duck-typed,
/// so `cloud_firestore` need not be imported — any object exposing `toDate()`
/// or `millisecondsSinceEpoch`, which covers `Timestamp`.
///
/// Returns `null` for anything unusable. Parsing a streak document must never
/// throw: a malformed field costs one value, not the whole streak.
DateTime? streakInstantFrom(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.round(), isUtc: true);
  }
  if (value is String) return DateTime.tryParse(value)?.toUtc();
  if (value is Map) {
    final seconds = value['_seconds'] ?? value['seconds'];
    if (seconds is num) {
      final nanos = value['_nanoseconds'] ?? value['nanoseconds'] ?? 0;
      final nanoMillis = nanos is num ? nanos.toInt() ~/ 1000000 : 0;
      return DateTime.fromMillisecondsSinceEpoch(
        seconds.toInt() * 1000 + nanoMillis,
        isUtc: true,
      );
    }
    return null;
  }
  // Duck-typed `Timestamp`. A dynamic call on an object without the member
  // throws NoSuchMethodError, which is exactly the "unusable" case.
  try {
    final Object? converted = (value as dynamic).toDate();
    if (converted is DateTime) return converted.toUtc();
  } catch (_) {
    // fall through
  }
  try {
    final Object? millis = (value as dynamic).millisecondsSinceEpoch;
    if (millis is int) {
      return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    }
  } catch (_) {
    // fall through
  }
  return null;
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) return false;
  }
  return true;
}
