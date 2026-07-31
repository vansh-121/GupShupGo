/// The one place streak arithmetic lives.
///
/// [StreakEngine.evaluate] is a **pure function** of `(stored, participants,
/// event, serverNow)`. It is used by three callers with three different
/// intentions and identical semantics:
///
///  * the server trigger, with `event != null`, to fold one qualifying send in;
///  * the server sweeper / repair job, with `event == null`, to stamp a lapse;
///  * the client repository, with `event == null`, to *derive* what a stored
///    state means right now, for display. The client never persists [next].
///
/// Hard rules for this file (enforced by the purity guard test):
///
///  * no `DateTime.now()` — `serverNow` is always supplied by the caller,
///  * no `toLocal()` — canonical days come from [StreakDay] alone,
///  * no wall-clock `.inDays`, no I/O, no logging, no Firebase.
///
/// ## Two invariants callers rely on
///
///  * **Deterministic.** Same inputs, same [StreakEvaluation]. Nothing is read
///    from ambient state.
///  * **Idempotent.** `evaluate(evaluate(X).next, …)` with the same
///    `participants`, `event` and `serverNow` changes nothing further, and
///    reports [StreakEvaluation.changed] as `false`.
///
/// ## What the engine deliberately does not know
///
///  * **Message type.** Every [Participation] handed to the engine is, by
///    definition, a *qualifying* send. Reactions are excluded once, at the
///    trigger (`streakOnMessageCreate` drops `type == 'reaction'`), because one
///    rule needs one enforcement point. Filtering is the caller's job.
///  * **Clock trust.** `event.instant` is expected to be already clamped to a
///    server-authoritative window; the engine trusts it.
///  * **Side effects.** The engine *reports* `milestonesCrossed` and the
///    `longestRaised` transition; paying out points, appending to
///    `milestonesAwarded`, bumping `rev` and stamping `lastEvaluatedAt` /
///    `lastEvaluatedBy` belong to the writer, in the same transaction.
library;

import 'streak_day.dart';
import 'streak_state.dart';

/// Above this much time remaining, a bond is [StreakRiskLevel.normal]; at or
/// below it, [StreakRiskLevel.atRisk]. Because `deadlineAt` is
/// `dayStartUtc(horizon + 2)`, "more than 24h left" is exactly "still inside
/// the mutual day" and "24h or less" is exactly "you are in the grace day".
const Duration kStreakAtRiskThreshold = Duration(hours: 24);

/// At or below this much time remaining, a bond is [StreakRiskLevel.critical].
const Duration kStreakCriticalThreshold = Duration(hours: 6);

/// One qualifying send by one participant.
///
/// [instant] is the authoritative send time, already clamped by the caller
/// (`clamp(message.timestamp, triggerTime - 48h, triggerTime)`), so the engine
/// can treat it as truth.
class Participation {
  const Participation({required this.uid, required this.instant});

  /// Convenience for `Participation(uid: uid, instant: instant)`.
  const Participation.of(this.uid, this.instant);

  final String uid;

  /// The send instant. Normalised to UTC on use, never to the device zone.
  final DateTime instant;

  /// The canonical day this send falls in.
  StreakDay dayIn({int offsetMinutes = kCanonicalDayOffsetMinutes}) =>
      StreakDay.fromInstant(instant, offsetMinutes: offsetMinutes);

  @override
  bool operator ==(Object other) =>
      other is Participation &&
      other.uid == uid &&
      other.instant.toUtc() == instant.toUtc();

  @override
  int get hashCode => Object.hash(uid, instant.toUtc());

  @override
  String toString() =>
      'Participation($uid, ${instant.toUtc().toIso8601String()})';
}

/// What one evaluation decided.
///
/// [count], [lastMutualDay], [deadlineAt] and [riskLevel] are projections of
/// [next]; they are surfaced directly because the display path wants nothing
/// else.
class StreakEvaluation {
  const StreakEvaluation._({
    required this.count,
    required this.lastMutualDay,
    required this.deadlineAt,
    required this.riskLevel,
    required this.transitions,
    required this.milestonesCrossed,
    required this.next,
    required bool changed,
  }) : _changed = changed;

  /// The live streak count as of `serverNow`. `0` once the deadline has passed.
  final int count;

  /// The newest day both participants sent on. Survives a break, so a broken
  /// bond still knows where it stood.
  final StreakDay? lastMutualDay;

  /// `dayStartUtc(continuityHorizon + 2)`, or `null` when there is no chain.
  final DateTime? deadlineAt;

  final StreakRiskLevel riskLevel;

  /// The transitions this evaluation produced, in the order the engine's steps
  /// produced them. `[StreakTransition.noop]` when nothing happened;
  /// **empty** when the room was refused outright (see step 1).
  final List<StreakTransition> transitions;

  /// Thresholds crossed by this evaluation and not yet in
  /// `stored.milestonesAwarded`. The caller pays them out and records them.
  final List<int> milestonesCrossed;

  /// The state to persist. Field-equal to `stored` when nothing changed.
  final StreakState next;

  final bool _changed;

  /// Whether [next] differs from the state that was evaluated. `false` for a
  /// genuine no-op, which is the writer's signal to skip the write entirely.
  bool get changed => _changed;

  /// The lapsed count held for the restore window (`0` when nothing is
  /// restorable).
  int get previousCount => next.previousCount;

  /// The instant the streak actually lapsed — the deadline, never the instant
  /// the lapse was noticed.
  DateTime? get brokenAt => next.brokenAt;

  DateTime? get restoreDeadlineAt => next.restoreDeadlineAt;

  bool get isBroken => riskLevel == StreakRiskLevel.broken;

  bool includes(StreakTransition transition) => transitions.contains(transition);

  @override
  String toString() => 'StreakEvaluation(count: $count, '
      'lastMutualDay: ${lastMutualDay?.key}, '
      'deadlineAt: ${deadlineAt?.toIso8601String()}, '
      'riskLevel: ${riskLevel.wire}, '
      'transitions: [${transitions.map((t) => t.wire).join(', ')}], '
      'milestonesCrossed: $milestonesCrossed, changed: $changed)';
}

/// The streak specification, as code.
///
/// The JS mirror in `functions/streak/engine.js` is a port of this class and is
/// pinned to it by `test/fixtures/streak_vectors.json`.
class StreakEngine {
  const StreakEngine._();

  /// Bumped when the semantics below change. Persisted on the state document
  /// so a state written by an older engine is recognisable.
  static const int engineVersion = 1;

  /// Reward thresholds, ascending. Crossed, not exact-matched.
  static const List<int> milestones = <int>[7, 30, 100, 365];

  /// Evaluates [stored] as of [serverNow], optionally folding in [event].
  ///
  /// [participants] must hold exactly two distinct uids; see step 1.
  static StreakEvaluation evaluate({
    required StreakState stored,
    required List<String> participants,
    Participation? event,
    required DateTime serverNow,
  }) {
    final now = serverNow.toUtc();

    // ── 1. Refuse anything that is not a two-person room ──────────────────
    //
    // Self-chat (uid == uid) collapses to one participant, so it can never
    // produce a mutual day (2.9). A group room is *refused* rather than
    // guessed at: no group model exists, and inventing semantics here would
    // ship untested behaviour. `stored` is returned untouched so a refusal can
    // never corrupt or erase a document, and `changed` is false so no writer
    // acts on it — while the reported count is 0, so nothing renders.
    final pair = _pairOf(participants);
    if (pair == null) {
      return StreakEvaluation._(
        count: 0,
        lastMutualDay: null,
        deadlineAt: null,
        riskLevel: StreakRiskLevel.normal,
        transitions: const <StreakTransition>[],
        milestonesCrossed: const <int>[],
        next: stored,
        changed: false,
      );
    }

    final offsetMinutes = stored.dayZoneOffsetMinutes;
    final transitions = <StreakTransition>[];

    // A negative count can only come from a corrupt document; treat it as 0 so
    // the repair is implicit rather than propagated.
    final storedCount = stored.count < 0 ? 0 : stored.count;

    var count = storedCount;
    var lastMutualDay = stored.lastMutualDay;
    var bridgedThroughDay = stored.bridgedThroughDay;
    var previousCount = stored.previousCount < 0 ? 0 : stored.previousCount;
    var brokenAt = stored.brokenAt;
    var restoreDeadlineAt = stored.restoreDeadlineAt;

    // ── 2. Record participation, forward only ─────────────────────────────
    //
    // `event.day <= sendDays[uid]` is structurally idempotent: a duplicate
    // delivery, a retry, or a late/out-of-order message for a day already
    // recorded for that uid changes nothing (2.4, 2.11). An event from a uid
    // outside the pair is ignored.
    var sendDays = stored.sendDays;
    var sendInstants = stored.sendInstants;
    if (event != null && pair.contains(event.uid)) {
      final day = event.dayIn(offsetMinutes: offsetMinutes);
      final recorded = sendDays[event.uid];
      if (recorded == null || day > recorded) {
        sendDays = <String, StreakDay>{...sendDays, event.uid: day};
        sendInstants = <String, DateTime>{
          ...sendInstants,
          event.uid: event.instant.toUtc(),
        };
        transitions.add(StreakTransition.participationRecorded);
      }
    }

    // ── 3. A mutual day exists iff both latest send days are the same day ──
    final dayA = sendDays[pair[0]];
    final dayB = sendDays[pair[1]];
    final mutualDay = (dayA != null && dayB != null && dayA == dayB) ? dayA : null;

    // ── 4. Continuity is measured from the anchor or a restore bridge ──────
    final horizon = StreakDay.max(lastMutualDay, bridgedThroughDay);

    // ── 5. A newer mutual day starts, continues or restarts the chain ──────
    if (mutualDay != null &&
        (lastMutualDay == null || mutualDay > lastMutualDay)) {
      if (horizon == null) {
        // Nothing to continue from: the bond's first mutual day.
        count = 1;
        transitions.add(StreakTransition.started);
      } else if (mutualDay.differenceInDays(horizon) <= 1) {
        // Inside the chain: the mutual day itself, or the day right after the
        // horizon. The restore bridge has served its purpose, so it is cleared.
        count = count > 0 ? count + 1 : 1;
        transitions.add(count == 1
            ? StreakTransition.started
            : StreakTransition.incremented);
        bridgedThroughDay = null;
      } else {
        // The chain lapsed before this day. Stamp the break at the deadline it
        // actually missed — not at "now" — then restart at 1. Step 9 closes
        // the restore window immediately if it has already elapsed.
        //
        // `count > 0` guards the double-break: when a previous evaluation (a
        // sweep, or step 8 of this one) has already zeroed the count and
        // stamped the break, re-stamping would overwrite `previousCount` with 0
        // and silently withdraw a live restore offer (3.4, 2.16).
        if (count > 0) {
          previousCount = count;
          brokenAt = horizon.plusDays(2).startUtc(offsetMinutes: offsetMinutes);
          restoreDeadlineAt = brokenAt.add(kStreakRestoreWindow);
          transitions.add(StreakTransition.broken);
        }
        count = 1;
        bridgedThroughDay = null;
        transitions.add(StreakTransition.started);
      }
      lastMutualDay = mutualDay;
    } else if (event != null &&
        mutualDay != null &&
        mutualDay == lastMutualDay) {
      // ── 6. Extra traffic on an already-counted day ──────────────────────
      //
      // THE 1.2 FIX: the anchor does not move and the deadline is not
      // refreshed. Reported for observability only; nothing changes (3.2).
      transitions.add(StreakTransition.sameDay);
    }

    // ── 7. The deadline always follows from the resulting horizon ──────────
    final nextHorizon = StreakDay.max(lastMutualDay, bridgedThroughDay);
    final deadlineAt =
        nextHorizon?.plusDays(2).startUtc(offsetMinutes: offsetMinutes);

    // ── 8. Read-side break ────────────────────────────────────────────────
    //
    // This is the step that makes a lapsed bond render as broken with no
    // writer involved (2.15): the same pure function that the sweeper uses to
    // stamp the break derives it for display.
    if (count > 0 && deadlineAt != null && !now.isBefore(deadlineAt)) {
      previousCount = count;
      brokenAt = deadlineAt;
      restoreDeadlineAt = deadlineAt.add(kStreakRestoreWindow);
      count = 0;
      transitions.add(StreakTransition.broken);
    }

    // ── 9. The restore window closes ──────────────────────────────────────
    //
    // Strictly *after* `restoreDeadlineAt`: the last instant of the window is
    // still restorable, matching `StreakState.isRestorable`.
    if (brokenAt != null &&
        restoreDeadlineAt != null &&
        now.isAfter(restoreDeadlineAt)) {
      previousCount = 0;
      brokenAt = null;
      restoreDeadlineAt = null;
      transitions.add(StreakTransition.restoreWindowExpired);
    }

    // ── 10. Risk level, from the same deadline the break rule uses ────────
    final riskLevel = riskLevelFor(
      deadlineAt: deadlineAt,
      serverNow: now,
      hasBrokenStamp: brokenAt != null,
    );

    // ── 11. Milestones by crossing, not by exact match ────────────────────
    final milestonesCrossed = <int>[
      for (final threshold in milestones)
        if (storedCount < threshold &&
            threshold <= count &&
            !stored.milestonesAwarded.contains(threshold))
          threshold,
    ];
    if (milestonesCrossed.isNotEmpty) {
      transitions.add(StreakTransition.milestoneCrossed);
    }

    // ── 12. Best-ever for this room ───────────────────────────────────────
    var longestForRoom = stored.longestForRoom < 0 ? 0 : stored.longestForRoom;
    if (count > longestForRoom) {
      longestForRoom = count;
      transitions.add(StreakTransition.longestRaised);
    }

    final next = stored.copyWith(
      schemaVersion: kStreakSchemaVersion,
      engineVersion: engineVersion,
      participants: pair,
      count: count,
      lastMutualDay: lastMutualDay,
      bridgedThroughDay: bridgedThroughDay,
      deadlineAt: deadlineAt,
      riskLevel: riskLevel,
      sendDays: sendDays,
      sendInstants: sendInstants,
      previousCount: previousCount,
      brokenAt: brokenAt,
      restoreDeadlineAt: restoreDeadlineAt,
      longestForRoom: longestForRoom,
    );

    if (transitions.isEmpty) transitions.add(StreakTransition.noop);

    return StreakEvaluation._(
      count: count,
      lastMutualDay: lastMutualDay,
      deadlineAt: deadlineAt,
      riskLevel: riskLevel,
      transitions: List<StreakTransition>.unmodifiable(transitions),
      milestonesCrossed: List<int>.unmodifiable(milestonesCrossed),
      next: next,
      changed: !stored.sameDocumentAs(next),
    );
  }

  /// Step 10 in isolation, so the badge can derive the same risk level from a
  /// deadline without re-running an evaluation.
  ///
  /// `remaining > 24h` → [StreakRiskLevel.normal];
  /// `6h < remaining <= 24h` → [StreakRiskLevel.atRisk];
  /// `0 < remaining <= 6h` → [StreakRiskLevel.critical];
  /// `remaining <= 0` → [StreakRiskLevel.broken].
  ///
  /// With no deadline there is nothing to count down to: the level is
  /// [StreakRiskLevel.broken] when a break is stamped (a restorable bond whose
  /// deadline was never recorded, e.g. a legacy projection) and
  /// [StreakRiskLevel.normal] otherwise.
  static StreakRiskLevel riskLevelFor({
    required DateTime? deadlineAt,
    required DateTime serverNow,
    bool hasBrokenStamp = false,
  }) {
    if (deadlineAt == null) {
      return hasBrokenStamp ? StreakRiskLevel.broken : StreakRiskLevel.normal;
    }
    final remaining = deadlineAt.toUtc().difference(serverNow.toUtc());
    if (remaining <= Duration.zero) return StreakRiskLevel.broken;
    if (remaining <= kStreakCriticalThreshold) return StreakRiskLevel.critical;
    if (remaining <= kStreakAtRiskThreshold) return StreakRiskLevel.atRisk;
    return StreakRiskLevel.normal;
  }

  /// The sorted pair of uids, or `null` when [participants] is not exactly two
  /// distinct non-empty uids.
  static List<String>? _pairOf(List<String> participants) {
    final unique = <String>{
      for (final uid in participants)
        if (uid.isNotEmpty) uid,
    };
    if (unique.length != 2) return null;
    final pair = unique.toList()..sort();
    return List<String>.unmodifiable(pair);
  }
}
