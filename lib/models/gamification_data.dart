import 'package:flutter/material.dart';

// ─── Rarity tiers for badges ────────────────────────────────────────────────
enum BadgeRarity { common, rare, epic, legendary }

// ─── Badge Definition ───────────────────────────────────────────────────────
class BadgeDefinition {
  final String id;
  final String title;
  final String description;
  final String icon;
  final List<Color> gradientColors;
  final BadgeRarity rarity;

  const BadgeDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
    this.rarity = BadgeRarity.common,
  });

  /// Look up a badge by its id. Returns null if not found.
  static BadgeDefinition? fromId(String id) {
    try {
      return allBadges.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Rarity label for display.
  String get rarityLabel {
    switch (rarity) {
      case BadgeRarity.common:
        return 'Common';
      case BadgeRarity.rare:
        return 'Rare';
      case BadgeRarity.epic:
        return 'Epic';
      case BadgeRarity.legendary:
        return 'Legendary';
    }
  }

  /// Rarity accent color.
  Color get rarityColor {
    switch (rarity) {
      case BadgeRarity.common:
        return const Color(0xFF94A3B8);
      case BadgeRarity.rare:
        return const Color(0xFF3B82F6);
      case BadgeRarity.epic:
        return const Color(0xFF8B5CF6);
      case BadgeRarity.legendary:
        return const Color(0xFFF59E0B);
    }
  }

  // ─── All badges ───────────────────────────────────────────────────────────
  static const List<BadgeDefinition> allBadges = [
    BadgeDefinition(
      id: 'early_adopter',
      title: 'Early Adopter',
      description: 'Joined GupShupGo as an early pioneer.',
      icon: '🚀',
      gradientColors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
      rarity: BadgeRarity.rare,
    ),
    BadgeDefinition(
      id: 'chatterbox',
      title: 'Chatterbox',
      description: 'Sent 100 messages and counting.',
      icon: '💬',
      gradientColors: [Color(0xFF11998e), Color(0xFF38ef7d)],
      rarity: BadgeRarity.common,
    ),
    BadgeDefinition(
      id: 'vocalist',
      title: 'Vocalist',
      description: 'Sent 10 voice notes to speak your mind.',
      icon: '🎤',
      gradientColors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
      rarity: BadgeRarity.common,
    ),
    BadgeDefinition(
      id: 'offline_hero',
      title: 'Offline Hero',
      description: 'Used mesh chat 10 times without internet.',
      icon: '📡',
      gradientColors: [Color(0xFFf21b3f), Color(0xFFab0e2d)],
      rarity: BadgeRarity.epic,
    ),
    BadgeDefinition(
      id: 'status_superstar',
      title: 'Status Superstar',
      description: 'Shared 5 status updates to document your days.',
      icon: '🌟',
      gradientColors: [Color(0xFFF12711), Color(0xFFF5AF19)],
      rarity: BadgeRarity.common,
    ),
    BadgeDefinition(
      id: 'reputation_master',
      title: 'Reputation Master',
      description: 'Reached 500 Gup Points — a community legend.',
      icon: '🏆',
      gradientColors: [Color(0xFFf857a6), Color(0xFFff5858)],
      rarity: BadgeRarity.legendary,
    ),
    BadgeDefinition(
      id: 'streak_warrior',
      title: 'Bond Warrior',
      description: 'Maintained a 7-day bond with a friend.',
      icon: '⚔️',
      gradientColors: [Color(0xFFFF8008), Color(0xFFFFC837)],
      rarity: BadgeRarity.rare,
    ),
    BadgeDefinition(
      id: 'social_butterfly',
      title: 'Social Butterfly',
      description: 'Reacted to 25 messages — spreading good vibes.',
      icon: '🦋',
      gradientColors: [Color(0xFF667eea), Color(0xFF764ba2)],
      rarity: BadgeRarity.rare,
    ),
    BadgeDefinition(
      id: 'night_owl',
      title: 'Night Owl',
      description: 'Sent 10 messages between midnight and 5 AM.',
      icon: '🦉',
      gradientColors: [Color(0xFF0F2027), Color(0xFF2C5364)],
      rarity: BadgeRarity.epic,
    ),
  ];
}

// ─── Challenge Definition ───────────────────────────────────────────────────
enum ChallengeCategory { lifetime, weekly }

class ChallengeDefinition {
  final String key;
  final String title;
  final String description;
  final String icon;
  final int target;
  final int rewardPoints;
  final ChallengeCategory category;
  /// The badge ID that gets unlocked when this challenge is completed.
  final String? unlocksBadge;

  const ChallengeDefinition({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.target,
    this.rewardPoints = 50,
    this.category = ChallengeCategory.lifetime,
    this.unlocksBadge,
  });

  /// Look up a challenge by its key.
  static ChallengeDefinition? fromKey(String key) {
    try {
      return allChallenges.firstWhere((c) => c.key == key);
    } catch (_) {
      return null;
    }
  }

  // ─── All challenges ─────────────────────────────────────────────────────
  static const List<ChallengeDefinition> allChallenges = [
    // Lifetime challenges
    ChallengeDefinition(
      key: 'messages_sent',
      title: 'Chatterbox',
      description: 'Send 100 messages total.',
      target: 100,
      icon: '💬',
      rewardPoints: 50,
      unlocksBadge: 'chatterbox',
    ),
    ChallengeDefinition(
      key: 'mesh_messages',
      title: 'Offline Hero',
      description: 'Send 10 messages using local mesh.',
      target: 10,
      icon: '📡',
      rewardPoints: 75,
      unlocksBadge: 'offline_hero',
    ),
    ChallengeDefinition(
      key: 'voice_notes',
      title: 'Vocalist',
      description: 'Send 10 voice messages.',
      target: 10,
      icon: '🎤',
      rewardPoints: 50,
      unlocksBadge: 'vocalist',
    ),
    ChallengeDefinition(
      key: 'status_posts',
      title: 'Moments Superstar',
      description: 'Post 5 moments.',
      target: 5,
      icon: '🌟',
      rewardPoints: 50,
      unlocksBadge: 'status_superstar',
    ),
    ChallengeDefinition(
      key: 'reactions_given',
      title: 'Social Butterfly',
      description: 'React to 25 messages — spread good vibes.',
      target: 25,
      icon: '🦋',
      rewardPoints: 60,
      unlocksBadge: 'social_butterfly',
    ),
    ChallengeDefinition(
      key: 'night_messages',
      title: 'Night Owl',
      description: 'Send 10 messages between midnight and 5 AM.',
      target: 10,
      icon: '🦉',
      rewardPoints: 75,
      unlocksBadge: 'night_owl',
    ),
    // Weekly challenges
    ChallengeDefinition(
      key: 'weekly_voice',
      title: 'Voice Week',
      description: 'Send a voice note every day for 7 days.',
      target: 7,
      icon: '🗣️',
      rewardPoints: 100,
      category: ChallengeCategory.weekly,
    ),
    ChallengeDefinition(
      key: 'weekly_streak_keeper',
      title: 'Bond Keeper',
      description: 'Maintain all your active bonds for 7 days.',
      target: 7,
      icon: '🔥',
      rewardPoints: 100,
      category: ChallengeCategory.weekly,
    ),
  ];

  static List<ChallengeDefinition> get lifetimeChallenges =>
      allChallenges.where((c) => c.category == ChallengeCategory.lifetime).toList();

  static List<ChallengeDefinition> get weeklyChallenges =>
      allChallenges.where((c) => c.category == ChallengeCategory.weekly).toList();
}

// ─── Level name helper ────────────────────────────────────────────────────
String getLevelName(int level) {
  if (level <= 1) return 'Novice';
  if (level <= 3) return 'Rising Star';
  if (level <= 5) return 'Conversationalist';
  if (level <= 8) return 'Social Elite';
  if (level <= 12) return 'Chat Legend';
  return 'Gup Guru';
}

/// Returns an emoji icon for a given level range.
String getLevelIcon(int level) {
  if (level <= 1) return '🌱';
  if (level <= 3) return '⭐';
  if (level <= 5) return '💎';
  if (level <= 8) return '👑';
  if (level <= 12) return '🔱';
  return '🌌';
}
