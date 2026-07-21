import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_chat_app/widgets/e2ee_banner.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/provider/theme_provider.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/screens/auth/link_accounts_screen.dart';
import 'package:video_chat_app/screens/auth/login_screen.dart';
import 'package:video_chat_app/screens/profile_screen.dart';
import 'package:video_chat_app/screens/vault_settings_screen.dart';
import 'package:video_chat_app/services/auth_service.dart';
import 'package:video_chat_app/services/crypto/safety_number_service.dart';
import 'package:video_chat_app/services/settings_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_chat_app/services/notification_service.dart';
import 'package:video_chat_app/provider/subscription_provider.dart';
import 'package:video_chat_app/screens/premium_screen.dart';
import 'package:video_chat_app/widgets/premium_badge.dart';
import 'package:video_chat_app/widgets/premium_gate.dart';

/// WhatsApp-style settings screen.
class SettingsScreen extends StatefulWidget {
  final UserModel currentUser;

  const SettingsScreen({super.key, required this.currentUser});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final SettingsService _settings = SettingsService();
  late UserModel _user;
  Map<String, bool> _notifPrefs = {};

  @override
  void initState() {
    super.initState();
    _user = widget.currentUser;
    _loadNotifPrefs();
  }

  Future<void> _loadNotifPrefs() async {
    final prefs = await NotificationService.instance.getPreferences();
    if (mounted) setState(() => _notifPrefs = prefs);
  }

  Future<void> _setNotifPref(String key, bool value) async {
    await NotificationService.instance.setPreference(key, value);
    setState(() => _notifPrefs[key] = value);
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out of GupShupGo?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Log Out', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  // ── Clear all chats ──────────────────────────────────────────────────────
  Future<void> _clearAllChats() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all chats'),
        content: const Text(
          'This will permanently delete all your message history. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete All',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      // Show a loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clearing chats...')),
        );
      }

      final userId = _user.id;
      final firestore = FirebaseFirestore.instance;

      // Get all chat rooms the user is part of
      final chatRoomsSnapshot = await firestore
          .collection('chatRooms')
          .where('participants', arrayContains: userId)
          .get();

      final batch = firestore.batch();
      for (final chatDoc in chatRoomsSnapshot.docs) {
        // Set a per-user clearedAt timestamp — messages before this are hidden
        // for THIS user only (the other participant still sees everything).
        batch.update(chatDoc.reference, {
          'clearedAt.$userId': Timestamp.now(),
          'unreadCount.$userId': 0,
        });
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All chats cleared'),
            backgroundColor: AppThemeColors.of(context).success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear chats: $e'),
            backgroundColor: AppThemeColors.of(context).error,
          ),
        );
      }
    }
  }

  // ── Report a problem ─────────────────────────────────────────────────────
  Future<void> _reportProblem() async {
    final subjectController = TextEditingController();
    final bodyController = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Report a Problem'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                decoration: InputDecoration(
                  hintText: 'Brief summary',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Describe the problem...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Send')),
        ],
      ),
    );

    if (submitted != true) return;

    final subject = subjectController.text.trim().isNotEmpty
        ? subjectController.text.trim()
        : 'Bug Report';
    final body = bodyController.text.trim().isNotEmpty
        ? bodyController.text.trim()
        : 'No details provided';

    final mailUri = Uri(
      scheme: 'mailto',
      path: 'gupshupgo.support@gmail.com',
      queryParameters: {
        'subject': '[GupShupGo] $subject',
        'body': '$body\n\n---\nUser: ${_user.name}\nID: ${_user.id}',
      },
    );

    try {
      if (await canLaunchUrl(mailUri)) {
        await launchUrl(mailUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report noted — no email app found to send it'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open email app: $e')),
        );
      }
    }
  }

  // ── Help Center ──────────────────────────────────────────────────────────
  void _showHelpCenter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppThemeColors.of(context).textLow,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Help Center',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppThemeColors.of(context).textHigh),
                  ),
                  const SizedBox(height: 20),
                  _buildFAQItem(
                    'How do I start a new chat?',
                    'Tap the message icon (💬) at the bottom-right of the Gup tab, '
                        'or use the search icon in the top bar to find contacts.',
                  ),
                  _buildFAQItem(
                    'How do I make a voice or video call?',
                    'Open a chat with the person you want to call. '
                        'Tap the phone icon (🔊) for an audio call or the '
                        'camera icon (📹) for a video call in the top bar.',
                  ),
                  _buildFAQItem(
                    'How do I share a moment?',
                    'Go to the Moments tab and tap the pencil icon for a text moment '
                        'or the camera icon for a photo/video moment.',
                  ),
                  _buildFAQItem(
                    'How do I edit my profile?',
                    'Tap your profile picture in the top-right menu, then '
                        'tap your avatar to change your photo, or edit your '
                        'name and about section.',
                  ),
                  _buildFAQItem(
                    'How do I block someone?',
                    'Open a chat with the person, tap the ⋮ menu in the top-right, '
                        'and select "Block contact".',
                  ),
                  _buildFAQItem(
                    'Why am I not receiving notifications?',
                    'Check that notifications are enabled in Settings → Notifications. '
                        'Also ensure your phone\'s system notification settings '
                        'allow GupShupGo to send alerts.',
                  ),
                  _buildFAQItem(
                    'How do I mute a chat?',
                    'Open the chat, tap the ⋮ menu, and select "Mute notifications". '
                        'You\'ll still receive messages but won\'t get push notifications.',
                  ),
                  _buildFAQItem(
                    'How do I log out?',
                    'Go to Settings (gear icon in menu) and scroll to the bottom. '
                        'Tap "Log Out".',
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Still need help?',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppThemeColors.of(context).textHigh),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _reportProblem();
                    },
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Contact Support'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side:
                          BorderSide(color: AppThemeColors.of(context).primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    final c = AppThemeColors.of(context);
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(question,
          style: TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14, color: c.textHigh)),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(answer, style: TextStyle(fontSize: 13, color: c.textMid)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final avatarUrl = _user.photoUrl ??
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_user.name)}&background=7C5CFC&color=fff&size=128';

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.textHigh, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: c.textHigh,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        children: [
          // ── Top User Profile Header (Stitch Design) ──────────────────────────
          GestureDetector(
            onTap: () async {
              final updated = await Navigator.push<UserModel>(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen(currentUser: _user)),
              );
              if (updated != null) setState(() => _user = updated);
            },
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundImage: NetworkImage(avatarUrl),
                  backgroundColor: c.surfaceAlt,
                ),
                const SizedBox(height: 12),
                Text(
                  _user.name,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: c.textHigh,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (_user.about != null && _user.about!.isNotEmpty)
                      ? _user.about!
                      : 'Hey there! I am using GupShupGo.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: c.textMid,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── GupShupGo Pro subscription card ────────────────────────────────
          if (context.watch<SubscriptionProvider>().isProFeatureVisible) ...[
            _buildProCard(),
            const SizedBox(height: 16),
          ],

          // ── 1. Account Section Card (Full Width) ────────────────────────────
          _buildStitchCard(
            title: 'Account',
            children: [
              _buildStitchTile(
                icon: Icons.person_outline_rounded,
                title: 'Profile',
                onTap: () async {
                  final updated = await Navigator.push<UserModel>(
                    context,
                    MaterialPageRoute(builder: (_) => ProfileScreen(currentUser: _user)),
                  );
                  if (updated != null) setState(() => _user = updated);
                },
              ),
              _buildStitchDivider(),
              _buildStitchTile(
                icon: Icons.link_rounded,
                title: 'Linked sign-in methods',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LinkAccountsScreen(user: _user)),
                ),
              ),
              _buildStitchDivider(),
              _buildStitchTile(
                icon: Icons.phone_outlined,
                title: 'Phone number',
                trailingText: _user.phoneNumber ?? 'Not linked',
              ),
              _buildStitchDivider(),
              _buildStitchTile(
                icon: Icons.email_outlined,
                title: 'Email',
                trailingText: _user.email ?? 'Not linked',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 2 & 3. Side-by-Side Cards Grid (Privacy & Appearance) ───────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Card: Privacy
              Expanded(
                child: _buildStitchCard(
                  title: 'Privacy',
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  children: [
                    _buildStitchSwitchRow(
                      icon: Icons.access_time_rounded,
                      title: 'Last seen',
                      value: _settings.showLastSeen,
                      onChanged: (v) => setState(() => _settings.showLastSeen = v),
                    ),
                    const SizedBox(height: 10),
                    _buildStitchSwitchRow(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'Read receipts',
                      value: _settings.showReadReceipts,
                      onChanged: (v) => setState(() => _settings.showReadReceipts = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right Card: Appearance
              Expanded(
                child: _buildStitchCard(
                  title: 'Appearance',
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  children: [
                    _buildStitchCompactTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Theme',
                      subtitle: context.watch<ThemeProvider>().themeMode == ThemeMode.dark
                          ? 'Dark'
                          : context.watch<ThemeProvider>().themeMode == ThemeMode.light
                              ? 'Light'
                              : 'System',
                      onTap: _showThemeModal,
                    ),
                    const SizedBox(height: 10),
                    _buildStitchCompactTile(
                      icon: Icons.g_translate_rounded,
                      title: 'App Language',
                      subtitle: 'English',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('English (US) is active')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 4. Help & Security Card (Full Width) ────────────────────────────
          _buildStitchCard(
            title: 'Help & Security',
            children: [
              _buildStitchTile(
                icon: Icons.help_outline_rounded,
                title: 'Help Center',
                onTap: _showHelpCenter,
              ),
              _buildStitchDivider(),
              _buildStitchTile(
                icon: Icons.description_outlined,
                title: 'Report a problem',
                onTap: _reportProblem,
              ),
              _buildStitchDivider(),
              _buildStitchTile(
                icon: Icons.shield_outlined,
                title: 'End-to-end encryption (Vault)',
                onTap: _openVaultSettings,
              ),
              _buildStitchDivider(),
              _buildStitchTile(
                icon: Icons.verified_user_outlined,
                title: 'Verify safety number',
                onTap: _verifySafetyNumber,
              ),
              _buildStitchDivider(),
              _buildStitchTile(
                icon: Icons.block_outlined,
                title: 'Blocked contacts',
                onTap: _showBlockedContacts,
              ),
              _buildStitchDivider(),
              _buildStitchTile(
                icon: Icons.delete_sweep_outlined,
                title: 'Clear all gup history',
                onTap: _clearAllChats,
              ),
              _buildStitchDivider(),
              _buildStitchTile(
                icon: Icons.info_outline_rounded,
                title: 'App info',
                trailingText: 'v1.1.0',
                onTap: _showAboutDialog,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Log Out Button (Stitch Design) ──────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _signOut,
              style: OutlinedButton.styleFrom(
                backgroundColor: c.isDark ? const Color(0xFF121422) : c.surfaceAlt,
                side: BorderSide(
                  color: c.error.withOpacity(0.7),
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Log Out',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.error,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Stitch Custom Card & Tile Builders ─────────────────────────────────────
  Widget _buildStitchCard({
    required String title,
    required List<Widget> children,
    EdgeInsetsGeometry? padding,
  }) {
    final c = AppThemeColors.of(context);
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: c.textHigh,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStitchTile({
    required IconData icon,
    required String title,
    String? trailingText,
    VoidCallback? onTap,
    bool compact = false,
  }) {
    final c = AppThemeColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: c.textMid, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: compact ? 13.5 : 15,
                  fontWeight: FontWeight.w500,
                  color: c.textHigh,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailingText != null) ...[
              const SizedBox(width: 8),
              Text(
                trailingText,
                style: GoogleFonts.poppins(
                  fontSize: compact ? 12 : 13,
                  color: c.textMid,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 6),
            ],
            Icon(Icons.chevron_right_rounded, color: c.textMid, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildStitchCompactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final c = AppThemeColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(icon, color: c.textMid, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.textHigh,
                    ),
                    maxLines: 1,
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: c.textMid,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.textMid, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStitchSwitchRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final c = AppThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: c.textMid, size: 15),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: c.textHigh,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onChanged(!value),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 16,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: value ? c.primary : c.border,
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStitchDivider() {
    final c = AppThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Divider(color: c.border.withOpacity(0.5), height: 1),
    );
  }

  void _showThemeModal() {
    final c = AppThemeColors.of(context);
    final themeProvider = context.read<ThemeProvider>();
    final currentMode = themeProvider.themeMode;

    final options = [
      (ThemeMode.light, Icons.light_mode_outlined, 'Light'),
      (ThemeMode.dark, Icons.dark_mode_outlined, 'Dark'),
      (ThemeMode.system, Icons.brightness_auto_outlined, 'System'),
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: c.textLow,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Choose theme',
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w700, color: c.textHigh)),
                  ),
                ),
                const SizedBox(height: 8),
                ...options.map((opt) {
                  final (mode, icon, label) = opt;
                  final selected = currentMode == mode;
                  return ListTile(
                    leading: Icon(icon, color: selected ? c.primary : c.textMid),
                    title: Text(label,
                        style: GoogleFonts.poppins(
                            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                            color: c.textHigh)),
                    trailing: selected
                        ? Icon(Icons.check_rounded, color: c.primary)
                        : null,
                    onTap: () {
                      context.read<ThemeProvider>().setThemeMode(mode);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── GupShupGo Pro card ────────────────────────────────────────────────────
  Widget _buildProCard() {
    final c = AppThemeColors.of(context);
    final sub = context.watch<SubscriptionProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PremiumScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: sub.isPro
                  ? [
                      const Color(0xFFFFD700).withOpacity(0.12),
                      const Color(0xFFFFA500).withOpacity(0.06),
                    ]
                  : [
                      c.primary.withOpacity(0.08),
                      c.primary.withOpacity(0.03),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: sub.isPro
                  ? const Color(0xFFFFD700).withOpacity(0.3)
                  : c.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: sub.isPro
                        ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
                        : [c.primary, c.primary.withOpacity(0.7)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'GupShupGo Pro',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: c.textHigh,
                          ),
                        ),
                        if (sub.isPro) ...[
                          const SizedBox(width: 8),
                          const PremiumBadge(size: PremiumBadgeSize.small),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub.isPro
                          ? '${sub.subscription.planLabel} · ${sub.subscription.daysRemaining} days left'
                          : 'Unlock premium features',
                      style: TextStyle(
                        fontSize: 12,
                        color: c.textMid,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                sub.isPro ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
                color: sub.isPro
                    ? const Color(0xFFFFD700)
                    : c.textLow,
                size: sub.isPro ? 24 : 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openVaultSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VaultSettingsScreen(uid: widget.currentUser.id),
      ),
    );
  }

  Future<void> _verifySafetyNumber() async {
    final c = AppThemeColors.of(context);
    final selfUid = widget.currentUser.id;

    // Show a bottom-sheet contact picker populated from existing chats.
    final peerUser = await showModalBottomSheet<UserModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SafetyNumberContactPicker(selfUid: selfUid),
    );

    if (peerUser == null || !mounted) return;

    // Show a loading indicator while computing.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final n = await SafetyNumberService().safetyNumberFor(
      selfUserId: selfUid,
      peerUserId: peerUser.id,
    );

    if (!mounted) return;
    Navigator.pop(context); // dismiss loading

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(
                peerUser.photoUrl ??
                    'https://ui-avatars.com/api/?name=${Uri.encodeComponent(peerUser.name)}&background=4CAF50&color=fff&size=128',
              ),
              backgroundColor: c.surfaceAlt,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                peerUser.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: n == null
            ? const Text(
                'This contact hasn\'t published an encryption key bundle yet. '
                'They may be using an older version of GupShupGo.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'If the number below matches on ${peerUser.name}\'s device, '
                    'your end-to-end encryption is verified.',
                    style: TextStyle(fontSize: 13, color: c.textMid),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      n,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        height: 1.8,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: c.textLow),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Compare this number in person or over a trusted call.',
                          style: TextStyle(fontSize: 11, color: c.textLow),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ── Blocked contacts dialog ────────────────────────────────────────────
  void _showBlockedContacts() async {
    final blockedIds = await _getBlockedUserIds();

    if (!mounted) return;

    if (blockedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No blocked contacts')),
      );
      return;
    }

    // Fetch user details for blocked IDs
    final firestore = FirebaseFirestore.instance;
    final List<UserModel> blockedUsers = [];
    for (final id in blockedIds) {
      final doc = await firestore.collection('users').doc(id).get();
      if (doc.exists) {
        blockedUsers.add(UserModel.fromFirestore(doc));
      }
    }

    if (!mounted) return;

    final c = AppThemeColors.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: c.textLow,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Blocked Contacts',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: c.textHigh)),
              const SizedBox(height: 12),
              if (blockedUsers.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('No blocked contacts',
                        style: TextStyle(color: c.textMid)),
                  ),
                )
              else
                ...blockedUsers.map((user) => ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(user.photoUrl ??
                            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}&background=4CAF50&color=fff&size=128'),
                        backgroundColor: c.surfaceAlt,
                      ),
                      title: Text(user.name),
                      trailing: TextButton(
                        onPressed: () async {
                          await _unblockUser(user.id);
                          Navigator.pop(context);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${user.name} unblocked')),
                            );
                          }
                        },
                        child:
                            Text('Unblock', style: TextStyle(color: c.primary)),
                      ),
                    )),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<String>> _getBlockedUserIds() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user.id)
        .get();
    if (!doc.exists) return [];
    final data = doc.data();
    if (data == null) return [];
    return List<String>.from(data['blockedUsers'] ?? []);
  }

  Future<void> _unblockUser(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(_user.id).update({
      'blockedUsers': FieldValue.arrayRemove([userId]),
    });
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'GupShupGo',
      applicationVersion: '1.1.0',
      applicationLegalese: '© 2026 GupShupGo',
    );
  }
}

// ── Contact picker for safety number verification ─────────────────────────
/// A bottom-sheet widget that lists the user's recent chat contacts so they
/// can tap one to verify their safety number — no Firebase UID needed.
class _SafetyNumberContactPicker extends StatefulWidget {
  final String selfUid;
  const _SafetyNumberContactPicker({required this.selfUid});

  @override
  State<_SafetyNumberContactPicker> createState() =>
      _SafetyNumberContactPickerState();
}

class _SafetyNumberContactPickerState
    extends State<_SafetyNumberContactPicker> {
  List<UserModel> _contacts = [];
  List<UserModel> _filtered = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Fetch all chatRooms the current user participates in.
      final snap = await firestore
          .collection('chatRooms')
          .where('participants', arrayContains: widget.selfUid)
          .get();

      // Collect unique peer UIDs.
      final peerUids = <String>{};
      for (final doc in snap.docs) {
        final parts = List<String>.from(doc.data()['participants'] ?? []);
        for (final uid in parts) {
          if (uid != widget.selfUid) peerUids.add(uid);
        }
      }

      // Resolve each peer UID into a UserModel.
      final users = <UserModel>[];
      for (final uid in peerUids) {
        final userDoc = await firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          users.add(UserModel.fromFirestore(userDoc));
        }
      }

      // Sort alphabetically.
      users
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (mounted) {
        setState(() {
          _contacts = users;
          _filtered = users;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _contacts
          : _contacts.where((u) => u.name.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.85,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Column(
          children: [
            // ── Handle + title ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: c.textLow,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.verified_user, color: c.primary, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Verify a contact',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: c.textHigh,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select a contact to view your shared safety number.',
                    style: TextStyle(fontSize: 13, color: c.textMid),
                  ),
                  const SizedBox(height: 14),
                  // ── Search bar ────────────────────────────────────────
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearch,
                    decoration: InputDecoration(
                      hintText: 'Search contacts...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: c.surfaceAlt,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // ── Contact list ──────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              _contacts.isEmpty
                                  ? 'No contacts yet.\nStart a chat first!'
                                  : 'No matching contacts.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: c.textMid),
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            indent: 72,
                            color: c.textLow.withOpacity(0.2),
                          ),
                          itemBuilder: (_, i) {
                            final user = _filtered[i];
                            final avatar = user.photoUrl ??
                                'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}&background=4CAF50&color=fff&size=128';
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(avatar),
                                backgroundColor: c.surfaceAlt,
                              ),
                              title: Text(
                                user.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: c.textHigh,
                                ),
                              ),
                              subtitle: Text(
                                user.about ??
                                    'Hey there! I am using GupShupGo.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    TextStyle(fontSize: 12, color: c.textMid),
                              ),
                              trailing: Icon(Icons.chevron_right,
                                  color: c.textLow, size: 20),
                              onTap: () => Navigator.pop(context, user),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}
