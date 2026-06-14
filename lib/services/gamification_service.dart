import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:video_chat_app/models/user_model.dart';

class GamificationService {
  GamificationService._();
  static final GamificationService instance = GamificationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';

  // Constants for challenge targets
  static const int meshTarget = 10;
  static const int voiceTarget = 10;
  static const int chatTarget = 100;
  static const int statusTarget = 5;

  /// Earn points for doing various actions in the app.
  Future<void> earnPoints(String userId, int points) async {
    try {
      if (userId.isEmpty) return;

      final userDocRef = _firestore.collection(_usersCollection).doc(userId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDocRef);
        if (!snapshot.exists) return;

        final data = snapshot.data() as Map<String, dynamic>;
        final currentPoints = data['gupPoints'] as int? ?? 0;
        final newPoints = currentPoints + points;

        transaction.update(userDocRef, {'gupPoints': newPoints});
      });

      // After updating points, check if we need to unlock level/reputation badges
      await checkAndUnlockBadges(userId);
    } catch (e) {
      debugPrint('Error earning points: $e');
    }
  }

  /// Increments challenge progress for a specific task.
  Future<void> incrementChallengeProgress(String userId, String challengeKey, int amount) async {
    try {
      if (userId.isEmpty) return;

      final userDocRef = _firestore.collection(_usersCollection).doc(userId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDocRef);
        if (!snapshot.exists) return;

        final data = snapshot.data() as Map<String, dynamic>;
        final progressMap = Map<String, int>.from(data['challengeProgress'] ?? {});
        final completed = List<String>.from(data['completedChallenges'] ?? {});
        final badges = List<String>.from(data['badges'] ?? {});
        var currentPoints = data['gupPoints'] as int? ?? 0;

        final currentProgress = progressMap[challengeKey] ?? 0;
        final newProgress = currentProgress + amount;
        progressMap[challengeKey] = newProgress;

        // Check if target met and not already completed
        int target = 999999;
        String badgeToUnlock = '';
        String badgeTitle = '';

        if (challengeKey == 'mesh_messages') {
          target = meshTarget;
          badgeToUnlock = 'offline_hero';
          badgeTitle = 'Offline Hero';
        } else if (challengeKey == 'voice_notes') {
          target = voiceTarget;
          badgeToUnlock = 'vocalist';
          badgeTitle = 'Vocalist';
        } else if (challengeKey == 'messages_sent') {
          target = chatTarget;
          badgeToUnlock = 'chatterbox';
          badgeTitle = 'Chatterbox';
        } else if (challengeKey == 'status_posts') {
          target = statusTarget;
          badgeToUnlock = 'status_superstar';
          badgeTitle = 'Status Superstar';
        }

        final updates = <String, dynamic>{
          'challengeProgress': progressMap,
        };

        if (newProgress >= target && !completed.contains(challengeKey)) {
          completed.add(challengeKey);
          updates['completedChallenges'] = completed;

          // Award bonus points for completing a challenge!
          currentPoints += 50;
          updates['gupPoints'] = currentPoints;

          if (badgeToUnlock.isNotEmpty && !badges.contains(badgeToUnlock)) {
            badges.add(badgeToUnlock);
            updates['badges'] = badges;
          }
        }

        transaction.update(userDocRef, updates);
      });
    } catch (e) {
      debugPrint('Error updating challenge progress: $e');
    }
  }

  /// Evaluates general badges like reputation benchmarks.
  Future<void> checkAndUnlockBadges(String userId) async {
    try {
      if (userId.isEmpty) return;

      final userDocRef = _firestore.collection(_usersCollection).doc(userId);
      final doc = await userDocRef.get();
      if (!doc.exists) return;

      final user = UserModel.fromFirestore(doc);
      final currentBadges = List<String>.from(user.badges);
      var updated = false;

      // 1. Reputation Master Badge (Points >= 500)
      if (user.gupPoints >= 500 && !currentBadges.contains('reputation_master')) {
        currentBadges.add('reputation_master');
        updated = true;
      }

      // 2. Early Adopter Badge (If account created before a certain threshold or auto-awarded on first load)
      if (!currentBadges.contains('early_adopter')) {
        currentBadges.add('early_adopter');
        updated = true;
      }

      if (updated) {
        await userDocRef.update({
          'badges': currentBadges,
        });
      }
    } catch (e) {
      debugPrint('Error checking badges: $e');
    }
  }
}
