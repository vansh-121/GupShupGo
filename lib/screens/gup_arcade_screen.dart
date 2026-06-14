import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/services/chat_cache_service.dart';
import 'package:video_chat_app/services/chat_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';

class GupArcadeScreen extends StatefulWidget {
  final String currentUserId;

  const GupArcadeScreen({Key? key, required this.currentUserId}) : super(key: key);

  @override
  _GupArcadeScreenState createState() => _GupArcadeScreenState();
}

class _GupArcadeScreenState extends State<GupArcadeScreen> {
  final ChatService _chatService = ChatService();
  final ChatCacheService _chatCacheService = ChatCacheService();

  // Definition of badges for rendering
  final List<Map<String, dynamic>> _allBadges = [
    {
      'id': 'early_adopter',
      'title': 'Early Adopter',
      'description': 'Awarded for joining GupShupGo as an early pioneer.',
      'icon': '🚀',
      'colors': [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    },
    {
      'id': 'chatterbox',
      'title': 'Chatterbox',
      'description': 'Send 100 messages to earn this title.',
      'icon': '💬',
      'colors': [Color(0xFF11998e), Color(0xFF38ef7d)],
    },
    {
      'id': 'vocalist',
      'title': 'Vocalist',
      'description': 'Send 10 voice notes to speak your mind.',
      'icon': '🎤',
      'colors': [Color(0xFFFF416C), Color(0xFFFF4B2B)],
    },
    {
      'id': 'offline_hero',
      'title': 'Offline Hero',
      'description': 'Use mesh chat 10 times to communicate without internet.',
      'icon': '📡',
      'colors': [Color(0xFFf21b3f), Color(0xFFab0e2d)],
    },
    {
      'id': 'status_superstar',
      'title': 'Status Superstar',
      'description': 'Share 5 status updates to document your days.',
      'icon': '🌟',
      'colors': [Color(0xFFF12711), Color(0xFFF5AF19)],
    },
    {
      'id': 'reputation_master',
      'title': 'Reputation Master',
      'description': 'Reach 500 Gup Points to become a community legend.',
      'icon': '🏆',
      'colors': [Color(0xFFf857a6), Color(0xFFff5858)],
    },
  ];

  String _getLevelName(int level) {
    if (level <= 1) return 'Novice';
    if (level <= 3) return 'Rising Star';
    if (level <= 5) return 'Conversationalist';
    if (level <= 8) return 'Social Elite';
    return 'Gup Guru';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);

    return Scaffold(
      backgroundColor: c.chatBg,
      appBar: AppBar(
        foregroundColor: c.textHigh,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Gup Arcade',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: c.textHigh,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'Failed to load reputation stats.',
                style: GoogleFonts.poppins(color: c.textMid),
              ),
            );
          }

          final user = UserModel.fromFirestore(snapshot.data!);

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // 1. Level Header Card
                _buildReputationHeader(user, c),
                const SizedBox(height: 20),

                // 2. Active Streaks Section
                _buildStreaksSection(c),
                const SizedBox(height: 20),

                // 3. Challenge Progress
                _buildChallengesSection(user, c),
                const SizedBox(height: 24),

                // 4. Badges Locker Grid
                _buildBadgesLocker(user, c),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReputationHeader(UserModel user, AppThemeColors c) {
    final level = user.level;
    final levelName = _getLevelName(level);
    final pointsInCurrentLevel = user.gupPoints % 100;
    final nextLevelPoints = 100;
    final progress = user.levelProgress;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: c.isDark
              ? [const Color(0xFF1E1E2C), const Color(0xFF2E2E3E)]
              : [c.primary.withOpacity(0.08), c.primary.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.border.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(c.isDark ? 0.25 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Beautiful glowing level circle badge
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [c.primary, c.primary.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: c.primary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'LVL',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white70,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '$level',
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      levelName,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: c.textHigh,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${user.gupPoints} Total Reputation Points',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: c.textMid,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress Bar to next level
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next Level',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.textMid,
                ),
              ),
              Text(
                '$pointsInCurrentLevel / $nextLevelPoints XP',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: c.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 10,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: c.border.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(c.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreaksSection(AppThemeColors c) {
    return StreamBuilder<List<ChatRoom>>(
      stream: _chatService.getChatRooms(widget.currentUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final roomsWithStreaks = snapshot.data!
            .where((room) => room.streakCount > 0)
            .toList();

        if (roomsWithStreaks.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'Active Streaks 🔥',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.textHigh,
                ),
              ),
            ),
            SizedBox(
              height: 105,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: roomsWithStreaks.length,
                itemBuilder: (context, index) {
                  final room = roomsWithStreaks[index];
                  final otherUserId = room.participants
                      .firstWhere((id) => id != widget.currentUserId, orElse: () => '');
                  
                  if (otherUserId.isEmpty) return const SizedBox.shrink();
                  final cachedUser = _chatCacheService.getCachedUser(otherUserId);
                  final name = cachedUser?.name ?? 'Someone';
                  final avatarUrl = cachedUser?.photoUrl ?? 
                      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=6C5CE7&color=fff&size=128';

                  return Container(
                    width: 90,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.border.withOpacity(0.4), width: 0.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(avatarUrl),
                              backgroundColor: c.primaryLt,
                            ),
                            Positioned(
                              bottom: -4,
                              right: -6,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${room.streakCount}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: c.textHigh,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChallengesSection(UserModel user, AppThemeColors c) {
    final List<Map<String, dynamic>> challenges = [
      {
        'key': 'messages_sent',
        'title': 'Chatterbox',
        'description': 'Send 100 messages total.',
        'target': 100,
        'icon': '💬',
      },
      {
        'key': 'mesh_messages',
        'title': 'Offline Hero',
        'description': 'Send 10 messages using local mesh.',
        'target': 10,
        'icon': '📡',
      },
      {
        'key': 'voice_notes',
        'title': 'Vocalist',
        'description': 'Send 10 voice messages.',
        'target': 10,
        'icon': '🎤',
      },
      {
        'key': 'status_posts',
        'title': 'Status Superstar',
        'description': 'Post 5 status updates.',
        'target': 5,
        'icon': '🌟',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Active Challenges',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: c.textHigh,
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: challenges.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            final progress = user.challengeProgress[challenge['key']] ?? 0;
            final target = challenge['target'] as int;
            final isCompleted = user.completedChallenges.contains(challenge['key']);
            final percent = (progress / target).clamp(0.0, 1.0);

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border.withOpacity(0.4), width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isCompleted ? c.primary.withOpacity(0.12) : c.surfaceAlt,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        challenge['icon'],
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              challenge['title'],
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: c.textHigh,
                              ),
                            ),
                            Text(
                              isCompleted ? 'Completed' : '$progress / $target',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isCompleted ? Colors.green[400] : c.textMid,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          challenge['description'],
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: c.textLow,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            height: 6,
                            child: LinearProgressIndicator(
                              value: percent,
                              backgroundColor: c.border.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isCompleted ? Colors.green : c.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBadgesLocker(UserModel user, AppThemeColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Badges Locker',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: c.textHigh,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _allBadges.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) {
            final badge = _allBadges[index];
            final isUnlocked = user.badges.contains(badge['id']);
            final gradientColors = List<Color>.from(badge['colors']);

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUnlocked ? null : c.surface,
                gradient: isUnlocked
                    ? LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isUnlocked ? Colors.yellow.withOpacity(0.3) : c.border.withOpacity(0.4),
                  width: isUnlocked ? 1.5 : 0.5,
                ),
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: gradientColors[0].withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isUnlocked ? Colors.white.withOpacity(0.2) : c.surfaceAlt,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isUnlocked
                          ? Text(
                              badge['icon'],
                              style: const TextStyle(fontSize: 26),
                            )
                          : Icon(
                              Icons.lock_rounded,
                              size: 22,
                              color: c.textLow,
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    badge['title'],
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? Colors.white : c.textHigh,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      badge['description'],
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: isUnlocked ? Colors.white.withOpacity(0.85) : c.textLow,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
