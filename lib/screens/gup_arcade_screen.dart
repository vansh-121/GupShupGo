import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/models/gamification_data.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/services/chat_cache_service.dart';
import 'package:video_chat_app/services/chat_service.dart';
import 'package:video_chat_app/services/gamification_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/widgets/streak_badge.dart';
import 'package:video_chat_app/widgets/streak_restore_dialog.dart';

class GupArcadeScreen extends StatefulWidget {
  final String currentUserId;

  const GupArcadeScreen({super.key, required this.currentUserId});

  @override
  _GupArcadeScreenState createState() => _GupArcadeScreenState();
}

class _GupArcadeScreenState extends State<GupArcadeScreen>
    with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final ChatCacheService _chatCacheService = ChatCacheService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);

    return Scaffold(
      backgroundColor: c.chatBg,
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

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxScrolled) {
              return [
                _buildSliverAppBar(user, c),
              ];
            },
            body: Column(
              children: [
                // Tab bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.border.withOpacity(0.5)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: c.primary,
                    ),
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: c.textMid,
                    labelStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Challenges'),
                      Tab(text: 'Leaderboard'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Tab views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _OverviewTab(
                        user: user,
                        currentUserId: widget.currentUserId,
                        chatService: _chatService,
                        chatCacheService: _chatCacheService,
                      ),
                      _ChallengesTab(user: user),
                      _LeaderboardTab(
                        currentUserId: widget.currentUserId,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(UserModel user, AppThemeColors c) {
    final level = user.level;
    final levelName = getLevelName(level);
    final levelIcon = getLevelIcon(level);
    final pointsInCurrentLevel = user.gupPoints % 100;
    final progress = user.levelProgress;

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: c.chatBg,
      foregroundColor: c.textHigh,
      elevation: 0,
      title: Text(
        'Gup Arcade',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: c.textHigh,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: c.isDark
                  ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                  : [const Color(0xFF6C5CE7).withOpacity(0.08), c.chatBg],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
              child: Row(
                children: [
                  // Animated Level Ring
                  _AnimatedLevelRing(
                    level: level,
                    progress: progress,
                    primaryColor: c.primary,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              levelIcon,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                levelName,
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: c.textHigh,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${user.gupPoints} Gup Points',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: c.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Progress bar
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: SizedBox(
                                  height: 8,
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: c.border.withOpacity(0.3),
                                    valueColor: AlwaysStoppedAnimation<Color>(c.primary),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '$pointsInCurrentLevel/100',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: c.textMid,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ANIMATED LEVEL RING
// ═══════════════════════════════════════════════════════════════════════════════
class _AnimatedLevelRing extends StatefulWidget {
  final int level;
  final double progress;
  final Color primaryColor;

  const _AnimatedLevelRing({
    required this.level,
    required this.progress,
    required this.primaryColor,
  });

  @override
  State<_AnimatedLevelRing> createState() => _AnimatedLevelRingState();
}

class _AnimatedLevelRingState extends State<_AnimatedLevelRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedLevelRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.progress,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: _LevelRingPainter(
            progress: _progressAnimation.value,
            primaryColor: widget.primaryColor,
          ),
          child: Container(
            width: 86,
            height: 86,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'LVL',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: widget.primaryColor.withOpacity(0.7),
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  '${widget.level}',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: widget.primaryColor,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LevelRingPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;

  _LevelRingPainter({required this.progress, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background ring
    final bgPaint = Paint()
      ..color = primaryColor.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: [
          primaryColor.withOpacity(0.6),
          primaryColor,
          primaryColor.withOpacity(0.8),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );

    // Glow dot at the end of the arc
    if (progress > 0.02) {
      final angle = -pi / 2 + 2 * pi * progress;
      final dotCenter = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      final glowPaint = Paint()
        ..color = primaryColor.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(dotCenter, 5, glowPaint);
      canvas.drawCircle(
        dotCenter,
        3,
        Paint()..color = primaryColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LevelRingPainter old) =>
      old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════════════════
// OVERVIEW TAB
// ═══════════════════════════════════════════════════════════════════════════════
class _OverviewTab extends StatelessWidget {
  final UserModel user;
  final String currentUserId;
  final ChatService chatService;
  final ChatCacheService chatCacheService;

  const _OverviewTab({
    required this.user,
    required this.currentUserId,
    required this.chatService,
    required this.chatCacheService,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Quick Stats Row
        _buildQuickStats(c),
        const SizedBox(height: 20),

        // Active Bonds
        _buildStreaksSection(c),
        const SizedBox(height: 20),

        // Badges Locker
        _buildBadgesLocker(c),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildQuickStats(AppThemeColors c) {
    final stats = [
      _QuickStat(
        label: 'Messages',
        value: '${user.challengeProgress['messages_sent'] ?? 0}',
        icon: '💬',
        color: const Color(0xFF11998e),
      ),
      _QuickStat(
        label: 'Voice',
        value: '${user.challengeProgress['voice_notes'] ?? 0}',
        icon: '🎤',
        color: const Color(0xFFFF416C),
      ),
      _QuickStat(
        label: 'Reactions',
        value: '${user.reactionsGiven}',
        icon: '🦋',
        color: const Color(0xFF667eea),
      ),
      _QuickStat(
        label: 'Best Bond',
        value: '${user.longestStreak}',
        icon: '🔥',
        color: const Color(0xFFFF8008),
      ),
    ];

    return Row(
      children: stats.map((stat) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: stat == stats.last ? 0 : 8),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border.withOpacity(0.4), width: 0.5),
            ),
            child: Column(
              children: [
                Text(stat.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 6),
                Text(
                  stat.value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: c.textHigh,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stat.label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: c.textLow,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStreaksSection(AppThemeColors c) {
    return StreamBuilder<List<ChatRoom>>(
      stream: chatService.getChatRooms(currentUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final allRooms = snapshot.data!;
        final roomsWithStreaks = allRooms
            .where((room) => room.streakCount > 0)
            .toList()
          ..sort((a, b) => b.streakCount.compareTo(a.streakCount));

        final brokenStreaks = allRooms
            .where((room) =>
                room.previousStreakCount > 0 &&
                room.streakBrokenAt != null &&
                DateTime.now().difference(room.streakBrokenAt!).inHours <= 24)
            .toList()
          ..sort((a, b) => b.previousStreakCount.compareTo(a.previousStreakCount));

        if (roomsWithStreaks.isEmpty && brokenStreaks.isEmpty) {
          return _buildEmptySection(
            c,
            title: 'Active Bonds 🤝',
            emoji: '🔥',
            message: 'Chat daily with friends to build bonds!',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Active Bonds ─────────────────────────────────────────
            if (roomsWithStreaks.isNotEmpty) ...[
              _sectionHeader('Active Bonds 🤝', '🔥', c),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: roomsWithStreaks.length,
                  itemBuilder: (context, index) {
                    final room = roomsWithStreaks[index];
                    return _buildActiveStreakCard(room, c);
                  },
                ),
              ),
            ],

            // ── Broken Bonds ─────────────────────────────────────────
            if (brokenStreaks.isNotEmpty) ...[
              if (roomsWithStreaks.isNotEmpty) const SizedBox(height: 20),
              _sectionHeader('Broken Bonds 💔', '💔', c),
              const SizedBox(height: 10),
              SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: brokenStreaks.length,
                  itemBuilder: (context, index) {
                    final room = brokenStreaks[index];
                    return _buildBrokenStreakCard(context, room, c);
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildActiveStreakCard(ChatRoom room, AppThemeColors c) {
    final otherUserId = room.participants
        .firstWhere((id) => id != currentUserId, orElse: () => '');
    if (otherUserId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<UserModel?>(
      future: _resolveUser(otherUserId),
      builder: (context, userSnap) {
        final user = userSnap.data;
        final name = user?.name ?? '...';
        final avatarUrl = user?.photoUrl ??
            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=6C5CE7&color=fff&size=128';
        final risk = computeStreakRisk(room.lastInteractionDate);

        final cardColors = switch (risk) {
          StreakRiskLevel.normal => c.isDark
              ? [const Color(0xFF2A2040), const Color(0xFF1E1830)]
              : [const Color(0xFFFFF3E0), Colors.white],
          StreakRiskLevel.atRisk => [
              const Color(0xFFFFB300).withOpacity(0.12),
              const Color(0xFFFFD54F).withOpacity(0.04),
            ],
          StreakRiskLevel.critical => [
              const Color(0xFFFF6B6B).withOpacity(0.15),
              const Color(0xFFFF6B6B).withOpacity(0.04),
            ],
        };

        final borderColor = switch (risk) {
          StreakRiskLevel.normal => Colors.orange.withOpacity(0.2),
          StreakRiskLevel.atRisk => Colors.amber.withOpacity(0.35),
          StreakRiskLevel.critical => Colors.red.withOpacity(0.35),
        };

        return Container(
          width: 100,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: cardColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage(avatarUrl),
                    backgroundColor: c.primaryLt,
                  ),
                  Positioned(
                    bottom: -5,
                    right: -8,
                    child: StreakArcadeBadge(
                      streakCount: room.streakCount,
                      lastInteractionDate: room.lastInteractionDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                name,
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: c.textHigh),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrokenStreakCard(BuildContext context, ChatRoom room, AppThemeColors c) {
    final otherUserId = room.participants
        .firstWhere((id) => id != currentUserId, orElse: () => '');
    if (otherUserId.isEmpty) return const SizedBox.shrink();

    final cost = GamificationService.getRestoreCost(room.previousStreakCount);

    return FutureBuilder<UserModel?>(
      future: _resolveUser(otherUserId),
      builder: (context, userSnap) {
        final user = userSnap.data;
        final name = user?.name ?? '...';
        final avatarUrl = user?.photoUrl ??
            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=6C5CE7&color=fff&size=128';

        return Container(
          width: 110,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: c.isDark
                  ? [const Color(0xFF2A1A1A), const Color(0xFF1A1020)]
                  : [const Color(0xFFFFF5F5), const Color(0xFFFFF0E0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.red.withOpacity(0.25)),
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
                    bottom: -5,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('💔', style: TextStyle(fontSize: 9)),
                          const SizedBox(width: 1),
                          Text(
                            '${room.previousStreakCount}',
                            style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: c.textHigh),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _handleStreakRestore(context, room, name),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8008), Color(0xFFFFC837)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '⚡$cost Restore',
                    style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleStreakRestore(BuildContext context, ChatRoom room, String contactName) async {
    int gupPoints = 0;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      gupPoints = (userDoc.data()?['gupPoints'] as int?) ?? 0;
    } catch (_) {}

    if (!context.mounted || room.streakBrokenAt == null) return;

    await StreakRestoreDialog.show(
      context,
      previousStreakCount: room.previousStreakCount,
      streakBrokenAt: room.streakBrokenAt!,
      userGupPoints: gupPoints,
      contactName: contactName,
      userId: currentUserId,
      chatRoomId: room.id,
    );
  }

  /// Resolves a user by checking cache first, then fetching from Firestore.
  Future<UserModel?> _resolveUser(String userId) async {
    final cached = chatCacheService.getCachedUser(userId);
    if (cached != null) return cached;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists) {
        final u = UserModel.fromFirestore(doc);
        chatCacheService.cacheUser(u);
        return u;
      }
    } catch (_) {}
    return null;
  }

  Widget _buildBadgesLocker(AppThemeColors c) {
    const allBadges = BadgeDefinition.allBadges;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionHeader('Badges Locker', '🏅', c),
            Text(
              '${user.badges.length}/${allBadges.length}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.textMid,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allBadges.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (context, index) {
            final badge = allBadges[index];
            final isUnlocked = user.badges.contains(badge.id);

            return GestureDetector(
              onTap: () => _showBadgeDetail(context, badge, isUnlocked, c),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isUnlocked ? null : c.surface,
                  gradient: isUnlocked
                      ? LinearGradient(
                          colors: badge.gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isUnlocked
                        ? Colors.yellow.withOpacity(0.25)
                        : c.border.withOpacity(0.4),
                    width: isUnlocked ? 1.5 : 0.5,
                  ),
                  boxShadow: isUnlocked
                      ? [
                          BoxShadow(
                            color: badge.gradientColors[0].withOpacity(0.25),
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
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? Colors.white.withOpacity(0.2)
                            : c.surfaceAlt,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isUnlocked
                            ? Text(badge.icon, style: const TextStyle(fontSize: 22))
                            : Icon(Icons.lock_rounded, size: 18, color: c.textLow),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      badge.title,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isUnlocked ? Colors.white : c.textHigh,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    // Rarity label
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? Colors.white.withOpacity(0.15)
                            : badge.rarityColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge.rarityLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: isUnlocked ? Colors.white70 : badge.rarityColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showBadgeDetail(
      BuildContext context, BadgeDefinition badge, bool isUnlocked, AppThemeColors c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              // Badge icon in gradient circle
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: isUnlocked
                      ? LinearGradient(colors: badge.gradientColors)
                      : null,
                  color: isUnlocked ? null : c.surfaceAlt,
                  shape: BoxShape.circle,
                  boxShadow: isUnlocked
                      ? [
                          BoxShadow(
                            color: badge.gradientColors[0].withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isUnlocked
                      ? Text(badge.icon, style: const TextStyle(fontSize: 36))
                      : Icon(Icons.lock_rounded, size: 30, color: c.textLow),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                badge.title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: c.textHigh,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: badge.rarityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge.rarityLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: badge.rarityColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                badge.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: c.textMid,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isUnlocked ? '✅ Unlocked' : '🔒 Keep going to unlock!',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isUnlocked ? Colors.green : c.textLow,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptySection(
    AppThemeColors c, {
    required String title,
    required String emoji,
    required String message,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(title, emoji, c),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border.withOpacity(0.4), width: 0.5),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: c.textMid,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, String emoji, AppThemeColors c) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: c.textHigh,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CHALLENGES TAB
// ═══════════════════════════════════════════════════════════════════════════════
class _ChallengesTab extends StatefulWidget {
  final UserModel user;

  const _ChallengesTab({required this.user});

  @override
  State<_ChallengesTab> createState() => _ChallengesTabState();
}

class _ChallengesTabState extends State<_ChallengesTab> {
  String _filter = 'All'; // All, Lifetime, Weekly

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    const allChallenges = ChallengeDefinition.allChallenges;

    List<ChallengeDefinition> filtered;
    switch (_filter) {
      case 'Lifetime':
        filtered = ChallengeDefinition.lifetimeChallenges;
        break;
      case 'Weekly':
        filtered = ChallengeDefinition.weeklyChallenges;
        break;
      default:
        filtered = allChallenges;
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Filter chips
        Row(
          children: ['All', 'Lifetime', 'Weekly'].map((label) {
            final isActive = _filter == label;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: isActive,
                onSelected: (v) => setState(() => _filter = label),
                selectedColor: c.primary,
                backgroundColor: c.surface,
                labelStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : c.textMid,
                ),
                side: BorderSide(
                  color: isActive ? c.primary : c.border.withOpacity(0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // Challenge cards
        ...filtered.map((challenge) {
          final progress = widget.user.challengeProgress[challenge.key] ?? 0;
          final isCompleted = widget.user.completedChallenges.contains(challenge.key);
          final percent = (progress / challenge.target).clamp(0.0, 1.0);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isCompleted
                    ? Colors.green.withOpacity(0.3)
                    : c.border.withOpacity(0.4),
                width: isCompleted ? 1.5 : 0.5,
              ),
              boxShadow: isCompleted
                  ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.withOpacity(0.1)
                        : c.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check_circle_rounded,
                            color: Colors.green, size: 24)
                        : Text(challenge.icon, style: const TextStyle(fontSize: 22)),
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
                          Flexible(
                            child: Text(
                              challenge.title,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: c.textHigh,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isCompleted) ...[
                                Text(
                                  '$progress/${challenge.target}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: c.textMid,
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Done!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        challenge.description,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: c.textLow,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Progress bar
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
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
                          ),
                          const SizedBox(width: 10),
                          // Reward points badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: c.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+${challenge.rewardPoints} GP',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: c.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LEADERBOARD TAB
// ═══════════════════════════════════════════════════════════════════════════════
class _LeaderboardTab extends StatelessWidget {
  final String currentUserId;

  const _LeaderboardTab({required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);

    return StreamBuilder<List<UserModel>>(
      stream: GamificationService.instance.getLeaderboard(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🏆', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  'Start chatting to see\nyour friends here!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: c.textMid,
                  ),
                ),
              ],
            ),
          );
        }

        // Find current user's rank
        final myRank = users.indexWhere((u) => u.id == currentUserId) + 1;

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // Top 3 podium
                  if (users.length >= 3) ...[
                    _buildPodium(users, c),
                    const SizedBox(height: 16),
                  ],
                  // Remaining list
                  ...users.asMap().entries.map((entry) {
                    final rank = entry.key + 1;
                    final u = entry.value;
                    final isMe = u.id == currentUserId;

                    // Skip top 3 if podium is shown
                    if (rank <= 3 && users.length >= 3) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe
                            ? c.primary.withOpacity(0.08)
                            : c.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isMe
                              ? c.primary.withOpacity(0.3)
                              : c.border.withOpacity(0.3),
                          width: isMe ? 1.5 : 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text(
                              '#$rank',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isMe ? c.primary : c.textMid,
                              ),
                            ),
                          ),
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(
                              u.photoUrl ??
                                  'https://ui-avatars.com/api/?name=${Uri.encodeComponent(u.name)}&background=6C5CE7&color=fff&size=128',
                            ),
                            backgroundColor: c.primaryLt,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isMe ? '${u.name} (You)' : u.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: c.textHigh,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${getLevelIcon(u.level)} ${getLevelName(u.level)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: c.textLow,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${u.gupPoints} GP',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: c.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            // Sticky bottom rank card
            if (myRank > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border(top: BorderSide(color: c.border.withOpacity(0.5))),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '#$myRank',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: c.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your Rank',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.textHigh,
                        ),
                      ),
                    ),
                    Text(
                      '${users.firstWhere((u) => u.id == currentUserId, orElse: () => users.first).gupPoints} GP',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.primary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPodium(List<UserModel> users, AppThemeColors c) {
    final medals = ['🥇', '🥈', '🥉'];
    final medalColors = [
      [const Color(0xFFFFD700), const Color(0xFFF5A623)],
      [const Color(0xFFC0C0C0), const Color(0xFF9E9E9E)],
      [const Color(0xFFCD7F32), const Color(0xFF8B5E3C)],
    ];

    // Reorder: 2nd | 1st | 3rd for visual podium
    final podiumOrder = [1, 0, 2];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: podiumOrder.map((idx) {
        final u = users[idx];
        final isFirst = idx == 0;
        final isMe = u.id == currentUserId;

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: EdgeInsets.symmetric(
              vertical: isFirst ? 20 : 14,
              horizontal: 6,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: c.isDark
                    ? [
                        medalColors[idx][0].withOpacity(0.15),
                        medalColors[idx][1].withOpacity(0.05),
                      ]
                    : [
                        medalColors[idx][0].withOpacity(0.1),
                        Colors.white,
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isMe
                    ? c.primary.withOpacity(0.4)
                    : medalColors[idx][0].withOpacity(0.2),
                width: isMe ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(medals[idx], style: TextStyle(fontSize: isFirst ? 28 : 22)),
                const SizedBox(height: 6),
                CircleAvatar(
                  radius: isFirst ? 26 : 20,
                  backgroundImage: NetworkImage(
                    u.photoUrl ??
                        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(u.name)}&background=6C5CE7&color=fff&size=128',
                  ),
                  backgroundColor: c.primaryLt,
                ),
                const SizedBox(height: 6),
                Text(
                  isMe ? 'You' : u.name,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: c.textHigh,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${u.gupPoints} GP',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: c.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QuickStat {
  final String label;
  final String value;
  final String icon;
  final Color color;

  const _QuickStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
