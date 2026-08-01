import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:video_chat_app/models/gamification_data.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/services/streak/streak_api.dart';

class GamificationService {
  GamificationService._();
  static final GamificationService instance = GamificationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';

  /// Simple point-awarding for non-message contexts (calls, status posts, etc.)
  /// where we don't need the full single-transaction gamification handler.
  Future<void> earnPoints(String userId, int points) async {
    try {
      if (userId.isEmpty) return;
      await _firestore.collection(_usersCollection).doc(userId).update({
        'gupPoints': FieldValue.increment(points),
      });
    } catch (e) {
      debugPrint('[Gamification] earnPoints failed: $e');
    }
  }

  /// **Single-transaction** handler called after every message send.
  /// Handles points, challenge progress, badge unlocks, and special tracking
  /// all in ONE atomic Firestore transaction — preventing the race conditions
  /// that caused badges to silently not unlock.
  Future<void> handleMessageSent({
    required String userId,
    required String messageType, // 'text', 'audio', 'image', 'video', 'reaction'
    int pointsToAward = 1,
  }) async {
    try {
      if (userId.isEmpty) return;

      final userDocRef = _firestore.collection(_usersCollection).doc(userId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDocRef);
        if (!snapshot.exists) return;

        final data = snapshot.data() as Map<String, dynamic>;
        final progressMap = Map<String, int>.from(data['challengeProgress'] ?? {});
        final completed = List<String>.from(data['completedChallenges'] ?? []);
        final badges = List<String>.from(data['badges'] ?? []);
        var currentPoints = data['gupPoints'] as int? ?? 0;

        final updates = <String, dynamic>{};

        // ── 1. Award points ───────────────────────────────────────────
        if (messageType != 'reaction') {
          currentPoints += pointsToAward;

          // ── 2. Increment messages_sent challenge ──────────────────
          final msgCount = (progressMap['messages_sent'] ?? 0) + 1;
          progressMap['messages_sent'] = msgCount;
          _checkAndCompleteChallenge('messages_sent', msgCount, progressMap, completed, badges, updates, currentPoints, (pts) => currentPoints = pts);

          // ── 3. Voice note tracking ────────────────────────────────
          if (messageType == 'audio') {
            final voiceCount = (progressMap['voice_notes'] ?? 0) + 1;
            progressMap['voice_notes'] = voiceCount;
            _checkAndCompleteChallenge('voice_notes', voiceCount, progressMap, completed, badges, updates, currentPoints, (pts) => currentPoints = pts);
          }

          // ── 4. Night owl tracking (midnight to 5 AM) ──────────────
          final hour = DateTime.now().hour;
          if (hour >= 0 && hour < 5) {
            final nightCount = (data['nightMessages'] as int? ?? 0) + 1;
            updates['nightMessages'] = nightCount;
            final nightChallengeCount = (progressMap['night_messages'] ?? 0) + 1;
            progressMap['night_messages'] = nightChallengeCount;
            _checkAndCompleteChallenge('night_messages', nightChallengeCount, progressMap, completed, badges, updates, currentPoints, (pts) => currentPoints = pts);
          }
        } else {
          // ── 5. Reaction tracking ──────────────────────────────────
          final reactionCount = (data['reactionsGiven'] as int? ?? 0) + 1;
          updates['reactionsGiven'] = reactionCount;
          final reactionChallengeCount = (progressMap['reactions_given'] ?? 0) + 1;
          progressMap['reactions_given'] = reactionChallengeCount;
          _checkAndCompleteChallenge('reactions_given', reactionChallengeCount, progressMap, completed, badges, updates, currentPoints, (pts) => currentPoints = pts);
        }

        // ── 6. Check reputation-based badges ──────────────────────
        if (currentPoints >= 500 && !badges.contains('reputation_master')) {
          badges.add('reputation_master');
        }
        if (!badges.contains('early_adopter')) {
          badges.add('early_adopter');
        }

        // Night owl badge (check from updated data)
        final nightMsgs = (updates['nightMessages'] as int?) ?? (data['nightMessages'] as int? ?? 0);
        if (nightMsgs >= 10 && !badges.contains('night_owl')) {
          badges.add('night_owl');
        }

        // Social butterfly badge (check from updated data)
        final reactionsGiven = (updates['reactionsGiven'] as int?) ?? (data['reactionsGiven'] as int? ?? 0);
        if (reactionsGiven >= 25 && !badges.contains('social_butterfly')) {
          badges.add('social_butterfly');
        }

        // ── 7. Commit everything in one write ─────────────────────
        updates['gupPoints'] = currentPoints;
        updates['challengeProgress'] = progressMap;
        updates['completedChallenges'] = completed;
        updates['badges'] = badges;

        debugPrint('[Gamification] userId=$userId type=$messageType pts=$currentPoints badges=$badges progress=$progressMap');

        transaction.update(userDocRef, updates);
      });
    } catch (e) {
      debugPrint('[Gamification] handleMessageSent failed: $e');
    }
  }

  /// Helper that checks if a challenge is completed and awards its rewards.
  void _checkAndCompleteChallenge(
    String challengeKey,
    int newProgress,
    Map<String, int> progressMap,
    List<String> completed,
    List<String> badges,
    Map<String, dynamic> updates,
    int currentPoints,
    void Function(int) updatePoints,
  ) {
    final challengeDef = ChallengeDefinition.fromKey(challengeKey);
    if (challengeDef == null) return;

    if (newProgress >= challengeDef.target && !completed.contains(challengeKey)) {
      completed.add(challengeKey);

      // Award bonus points
      final newPts = currentPoints + challengeDef.rewardPoints;
      updatePoints(newPts);

      // Unlock badge
      final badge = challengeDef.unlocksBadge;
      if (badge != null && badge.isNotEmpty && !badges.contains(badge)) {
        badges.add(badge);
        debugPrint('[Gamification] 🏆 BADGE UNLOCKED: $badge (from challenge $challengeKey, progress=$newProgress/${challengeDef.target})');
      }
    }
  }

  /// Awards streak milestone points and the streak_warrior badge at 7 days.
  ///
  /// DEPRECATED — has no callers. Milestones are awarded server-side by
  /// `functions/streak` (idempotently, per `users/{uid}/streakAwards/{roomId}_{threshold}`,
  /// for BOTH participants, on threshold *crossing* rather than exact match).
  /// The client version awarded the sender only and on exact equality, so a
  /// count that skipped a threshold (e.g. a restore from 5 to 12) lost it.
  ///
  /// Kept for one release so an in-flight caller cannot break; it is safe to
  /// call (server awards are idempotency-keyed) but nothing should. Task 10.4
  /// deletes it.
  @Deprecated('Milestones are awarded server-side; removed in task 10.4.')
  Future<void> handleStreakMilestone(String userId, int newStreak) async {
    try {
      if (userId.isEmpty) return;
      final userDocRef = _firestore.collection(_usersCollection).doc(userId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDocRef);
        if (!snapshot.exists) return;

        final data = snapshot.data() as Map<String, dynamic>;
        final longestStreak = data['longestStreak'] as int? ?? 0;
        final badges = List<String>.from(data['badges'] ?? []);
        var currentPoints = data['gupPoints'] as int? ?? 0;

        final updates = <String, dynamic>{};

        if (newStreak > longestStreak) {
          updates['longestStreak'] = newStreak;
        }

        // Milestone rewards
        if (newStreak == 7) {
          currentPoints += 25;
          updates['gupPoints'] = currentPoints;
          if (!badges.contains('streak_warrior')) {
            badges.add('streak_warrior');
            updates['badges'] = badges;
          }
        } else if (newStreak == 30) {
          currentPoints += 50;
          updates['gupPoints'] = currentPoints;
        } else if (newStreak == 100) {
          currentPoints += 100;
          updates['gupPoints'] = currentPoints;
        }

        if (updates.isNotEmpty) {
          transaction.update(userDocRef, updates);
        }
      });
    } catch (e) {
      debugPrint('[Gamification] handleStreakMilestone failed: $e');
    }
  }

  /// Gup Point cost to restore a broken streak, by tier.
  ///
  /// DISPLAY ONLY. The SERVER is authoritative: `POST /streakRestore` computes
  /// the charge with `restoreCost` in `functions/streak/engine.js`, which
  /// mirrors this table (10/25/50/100 at 0/10/30/100). This copy exists so a
  /// card label can show an estimate before a quote is fetched; never deduct,
  /// gate or reconcile points against it. The authoritative figure for a given
  /// room comes back from `GET /streakRestoreQuote` (`cost`).
  static int getRestoreCost(int streakCount) {
    if (streakCount >= 100) return 100;
    if (streakCount >= 30) return 50;
    if (streakCount >= 10) return 25;
    return 10;
  }

  /// Restore a broken streak for [chatRoomId] by calling `POST /streakRestore`.
  ///
  /// A thin passthrough to [StreakApi.streakRestore]. The server owns the whole
  /// decision — window validity against server time, the cost tier, the Pro
  /// weekly allowance, the point deduction and `bridgedThroughDay` — so no
  /// cost is passed in and no Firestore write happens here.
  ///
  /// Prefer calling [StreakApi.instance.streakRestore] directly: it returns a
  /// [StreakRestoreResult] whose status the dialog renders per refusal reason.
  /// This bool-returning shim is kept only for the older call shape.
  Future<bool> restoreStreak({
    required String chatRoomId,
    bool useFreePerk = false,
  }) async {
    if (chatRoomId.isEmpty) return false;
    final result = await StreakApi.instance
        .streakRestore(chatRoomId, useFreePerk: useFreePerk);
    if (!result.isSuccess) {
      debugPrint(
          '[Gamification] restoreStreak refused: ${result.status.name} ${result.message ?? ''}');
    }
    return result.isSuccess;
  }

  /// Increment challenge progress for non-message actions (e.g. status posts).
  Future<void> incrementChallengeProgress(String userId, String challengeKey, int amount) async {
    try {
      if (userId.isEmpty) return;

      final userDocRef = _firestore.collection(_usersCollection).doc(userId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDocRef);
        if (!snapshot.exists) return;

        final data = snapshot.data() as Map<String, dynamic>;
        final progressMap = Map<String, int>.from(data['challengeProgress'] ?? {});
        final completed = List<String>.from(data['completedChallenges'] ?? []);
        final badges = List<String>.from(data['badges'] ?? []);
        var currentPoints = data['gupPoints'] as int? ?? 0;

        final currentProgress = progressMap[challengeKey] ?? 0;
        final newProgress = currentProgress + amount;
        progressMap[challengeKey] = newProgress;

        final updates = <String, dynamic>{
          'challengeProgress': progressMap,
        };

        _checkAndCompleteChallenge(challengeKey, newProgress, progressMap, completed, badges, updates, currentPoints, (pts) => currentPoints = pts);

        updates['completedChallenges'] = completed;
        updates['badges'] = badges;
        updates['gupPoints'] = currentPoints;

        transaction.update(userDocRef, updates);
      });
    } catch (e) {
      debugPrint('[Gamification] incrementChallengeProgress failed: $e');
    }
  }

  /// Returns a stream of the top users by gupPoints from among the user's
  /// chat contacts (friends-only leaderboard).
  Stream<List<UserModel>> getLeaderboard(String currentUserId) {
    return _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .asyncMap((roomSnap) async {
      final peerIds = <String>{currentUserId};
      for (final doc in roomSnap.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        peerIds.addAll(participants);
      }

      if (peerIds.isEmpty) return <UserModel>[];

      final allUsers = <UserModel>[];
      final idList = peerIds.toList();
      for (var i = 0; i < idList.length; i += 30) {
        final chunk = idList.sublist(i, (i + 30 < idList.length) ? i + 30 : idList.length);
        final snap = await _firestore
            .collection(_usersCollection)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in snap.docs) {
          allUsers.add(UserModel.fromFirestore(doc));
        }
      }

      allUsers.sort((a, b) => b.gupPoints.compareTo(a.gupPoints));
      return allUsers;
    });
  }
}
