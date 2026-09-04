import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/models/gamification_data.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/screens/call_screen.dart';
import 'package:video_chat_app/screens/connecting_call_screen.dart';
import 'package:video_chat_app/screens/chat_screen.dart';
import 'package:video_chat_app/screens/contacts_screen.dart' show UserDiscoverTile;
import 'package:video_chat_app/services/call_signaling_service.dart';
import 'package:video_chat_app/services/fcm_service.dart';
import 'package:video_chat_app/services/feature_flag_service.dart';
import 'package:video_chat_app/services/presence_service.dart';
import 'package:video_chat_app/services/user_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/utils/avatar_image.dart';
import 'package:video_chat_app/widgets/premium_badge.dart';

/// Shows one person's public profile.
///
/// Two ways in:
///  * [username] — a `https://gupshupgo.app/u/<username>` link (QR scan,
///    shared link, or the intent-filter deep link), which is looked up by
///    handle.
///  * [initialUser] — a row that was tapped in Contacts or Discover, which
///    already holds the full [UserModel]. Skips the lookup entirely, and is
///    the only path that works for users who never set a handle
///    (`UserModel.username` is nullable).
///
/// Exactly one is required. The connect/message actions are the same
/// [UserDiscoverTile] used in the Discover tab.
class PublicProfileScreen extends StatefulWidget {
  final String? username;
  final UserModel? initialUser;
  final String currentUserId;
  final String? currentUserName;

  const PublicProfileScreen({
    super.key,
    this.username,
    this.initialUser,
    required this.currentUserId,
    this.currentUserName,
  }) : assert(username != null || initialUser != null,
            'PublicProfileScreen needs a username to look up or a preloaded user');

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final UserService _userService = UserService();
  final FCMService _fcmService = FCMService();

  UserModel? _user;
  bool _isLoading = true;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Tapped from a list that already holds the record — no refetch, and no
    // dependence on a handle the user may never have set.
    final preloaded = widget.initialUser;
    if (preloaded != null) {
      setState(() {
        _user = preloaded;
        _notFound = false;
        _isLoading = false;
      });
      return;
    }

    final user = await _userService.getUserByUsername(widget.username!);
    if (!mounted) return;
    setState(() {
      _user = user;
      _notFound = user == null;
      _isLoading = false;
    });
  }

  void _openChat(UserModel user) {
    final contact = Contact(
      id: user.id,
      name: user.name,
      lastMessage: '',
      time: '',
      avatarUrl: user.photoUrl ??
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}&background=4CAF50&color=fff&size=128',
      isOnline: user.isOnline,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          contact: contact,
          currentUserId: widget.currentUserId,
          currentUserName: widget.currentUserName,
        ),
      ),
    );
  }

  void _initiateCall(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConnectingCallScreen(
          currentUserId: widget.currentUserId,
          calleeId: user.id,
          calleeName: user.name,
          calleePhotoUrl: user.photoUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(title: const Text('Profile')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: c.primary))
          : _notFound
              ? _buildNotFound(c)
              : _buildProfile(c),
    );
  }

  Widget _buildNotFound(AppThemeColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 56, color: c.textMid),
            const SizedBox(height: 16),
            Text(
              // _notFound is only reachable via the handle lookup, but don't
              // rely on that to avoid printing "@null".
              widget.username != null
                  ? '@${widget.username} not found'
                  : 'User not found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: c.textHigh,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This handle doesn\'t exist or the link is broken.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.textMid),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile(AppThemeColors c) {
    final user = _user!;
    final hasHandle = user.username != null && user.username!.isNotEmpty;
    // isOnline alone can be stale if a disconnect was never recorded, so it is
    // cross-checked against lastSeen exactly as UserService does on read.
    final isOnline =
        user.isOnline && PresenceService.isRecentlyActive(user.lastSeen);
    // user.isPro reflects only their own subscription; the flag decides whether
    // Pro exists in the UI at all. Checked here as well as inside PremiumBadge
    // so the spacer does not leave a gap next to a badge that hid itself.
    final showPro = user.isPro && FeatureFlagService.instance.isProEnabled;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 56,
            backgroundImage: avatarImage(
              user.photoUrl ??
                  'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}&background=6C5CE7&color=fff&size=256',
              radius: 56,
            ),
            backgroundColor: c.primaryLt,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  user.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: c.textHigh,
                  ),
                ),
              ),
              // PremiumBadge hides itself when the Pro flag is off.
              if (showPro) ...[
                const SizedBox(width: 8),
                const PremiumBadge(size: PremiumBadgeSize.medium),
              ],
            ],
          ),
          if (hasHandle) ...[
            const SizedBox(height: 4),
            Text(
              '@${user.username}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: c.primary,
              ),
            ),
          ],
          // isOnline implies a non-null lastSeen, so this covers both states.
          if (user.lastSeen != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOnline ? c.online : c.textLow,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isOnline
                      ? 'Online'
                      : 'Last seen ${_formatLastSeen(user.lastSeen!)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isOnline ? c.online : c.textMid,
                  ),
                ),
              ],
            ),
          ],
          if (user.about != null && user.about!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              user.about!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.textMid),
            ),
          ],
          const SizedBox(height: 22),
          _buildStatsCard(c, user),
          _buildBadges(c, user),
          if (user.createdAt != null) ...[
            const SizedBox(height: 16),
            Text(
              'Joined ${_formatJoined(user.createdAt!)}',
              style: GoogleFonts.poppins(fontSize: 11.5, color: c.textLow),
            ),
          ],
          const SizedBox(height: 24),
          if (user.id == widget.currentUserId)
            Text(
              'This is your own profile link.',
              style: TextStyle(fontSize: 13, color: c.textMid),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: c.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border.withOpacity(0.5)),
              ),
              child: UserDiscoverTile(
                targetUser: user,
                currentUserId: widget.currentUserId,
                currentUserName: widget.currentUserName ?? 'User',
                onOpenChat: _openChat,
                onInitiateCall: _initiateCall,
                // onOpenProfile deliberately unset: this screen *is* the
                // profile, so wiring it would navigate to itself forever.
              ),
            ),
        ],
      ),
    );
  }

  /// Level, progress to the next one, and the same three stats the user sees
  /// on their own profile ([profile_screen.dart]'s stats row).
  Widget _buildStatsCard(AppThemeColors c, UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Level ${user.level}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.textHigh,
                ),
              ),
              const Spacer(),
              Text(
                '${user.gupPoints} Gup Points',
                style: GoogleFonts.poppins(fontSize: 11.5, color: c.textMid),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: user.levelProgress,
              minHeight: 6,
              backgroundColor: c.surface,
              color: c.primary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _miniStat(c, '⚡', '${user.gupPoints}', 'Points'),
              _miniStatDivider(c),
              _miniStat(c, '🏅', '${user.badges.length}', 'Badges'),
              _miniStatDivider(c),
              _miniStat(c, '🔥', '${user.longestStreak}', 'Best Bond'),
            ],
          ),
        ],
      ),
    );
  }

  /// Earned badges, resolved through the shared catalog. Ids with no
  /// definition are skipped so a badge added server-side cannot break this.
  Widget _buildBadges(AppThemeColors c, UserModel user) {
    final earned = user.badges
        .map(BadgeDefinition.fromId)
        .whereType<BadgeDefinition>()
        .toList();
    if (earned.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        children: [
          Text(
            'BADGES',
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: c.textLow,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final badge in earned)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badge.rarityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: badge.rarityColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(badge.icon, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 5),
                      Text(
                        badge.title,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: c.textHigh,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(AppThemeColors c, String emoji, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 3),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: c.textHigh,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 10, color: c.textLow),
          ),
        ],
      ),
    );
  }

  Widget _miniStatDivider(AppThemeColors c) {
    return Container(
      width: 1,
      height: 28,
      color: c.border.withValues(alpha: 0.4),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
  }

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String _formatJoined(DateTime createdAt) =>
      '${_monthNames[createdAt.month - 1]} ${createdAt.year}';
}
