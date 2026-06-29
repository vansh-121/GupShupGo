import 'package:flutter/material.dart';
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

/// WhatsApp-style settings screen.
class SettingsScreen extends StatefulWidget {
  final UserModel currentUser;

  const SettingsScreen({Key? key, required this.currentUser}) : super(key: key);

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
        MaterialPageRoute(builder: (_) => LoginScreen()),
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
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_user.name)}&background=4CAF50&color=fff&size=128';

    return Scaffold(
      backgroundColor: c.surfaceAlt,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // ── Profile card ──────────────────────────────────────────────
          _buildProfileCard(avatarUrl),
          const SizedBox(height: 8),

          // ── End-to-end encryption info card ───────────────────────────
          // High-visibility placement so users see the encryption
          // guarantee right after their profile, before scrolling into
          // any other setting — same place WhatsApp puts theirs.
          E2EEBanner.card(
            context,
            body: 'Messages, moments, and calls are secured with the '
                'Signal Protocol. Only you and the people you chat with can '
                'read what is sent, listen to what is said, or see your '
                'status. Not even GupShupGo.',
          ),

          // ── Account ───────────────────────────────────────────────────
          _buildSectionHeader('ACCOUNT'),
          _buildCard(children: [
            _buildTile(
              icon: Icons.person_outline,
              iconColor: AppColors.primary,
              title: 'Profile',
              subtitle: 'Name, about, photo',
              onTap: () async {
                final updated = await Navigator.push<UserModel>(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ProfileScreen(currentUser: _user)),
                );
                if (updated != null) setState(() => _user = updated);
              },
            ),
            _divider(),
            _buildTile(
              icon: Icons.link_rounded,
              iconColor: Colors.purple,
              title: 'Linked sign-in methods',
              subtitle: 'Phone, Google, Email',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => LinkAccountsScreen(user: _user)),
              ),
            ),
            _divider(),
            _buildTile(
              icon: Icons.phone_outlined,
              iconColor: Colors.green,
              title: 'Phone number',
              subtitle: _user.phoneNumber ?? 'Not linked',
              onTap: null,
            ),
            _divider(),
            _buildTile(
              icon: Icons.email_outlined,
              iconColor: Colors.orange,
              title: 'Email',
              subtitle: _user.email ?? 'Not linked',
              onTap: null,
            ),
          ]),
          const SizedBox(height: 8),

          // ── Privacy ───────────────────────────────────────────────────
          _buildSectionHeader('PRIVACY'),
          _buildCard(children: [
            _buildSwitchTile(
              icon: Icons.access_time,
              iconColor: Colors.teal,
              title: 'Last seen',
              subtitle: 'Show when you were last active',
              value: _settings.showLastSeen,
              onChanged: (v) => setState(() => _settings.showLastSeen = v),
            ),
            _divider(),
            _buildSwitchTile(
              icon: Icons.done_all,
              iconColor: AppColors.primary,
              title: 'Read receipts',
              subtitle: 'Show blue ticks when you\'ve read messages',
              value: _settings.showReadReceipts,
              onChanged: (v) => setState(() => _settings.showReadReceipts = v),
            ),
            _divider(),
            _buildTile(
              icon: Icons.block,
              iconColor: Colors.red,
              title: 'Blocked contacts',
              subtitle: 'Manage blocked users',
              onTap: () => _showBlockedContacts(),
            ),
          ]),
          const SizedBox(height: 8),

          // ── Encryption ───────────────────────────────────────────────
          _buildSectionHeader('END-TO-END ENCRYPTION'),
          _buildCard(children: [
            _buildTile(
              icon: Icons.shield_outlined,
              iconColor: AppColors.primary,
              title: 'Vault',
              subtitle: 'PIN, auto-delete window, what\'s stored',
              onTap: _openVaultSettings,
            ),
            _divider(),
            _buildTile(
              icon: Icons.verified_user,
              iconColor: Colors.green,
              title: 'Verify safety number',
              subtitle: 'Confirm a contact\'s identity out-of-band',
              onTap: _verifySafetyNumber,
            ),
          ]),
          const SizedBox(height: 8),

          // ── Notifications ─────────────────────────────────────────────
          _buildSectionHeader('NOTIFICATIONS'),
          _buildCard(children: [
            _buildSwitchTile(
              icon: Icons.chat_bubble_outline,
              iconColor: AppColors.primary,
              title: 'Messages',
              subtitle: 'Notifications for new messages',
              value: _settings.messageNotifications,
              onChanged: (v) =>
                  setState(() => _settings.messageNotifications = v),
            ),
            _divider(),
            _buildSwitchTile(
              icon: Icons.group_outlined,
              iconColor: Colors.green,
              title: 'Group messages',
              subtitle: 'Notifications for group activity',
              value: _settings.groupNotifications,
              onChanged: (v) =>
                  setState(() => _settings.groupNotifications = v),
            ),
            _divider(),
            _buildSwitchTile(
              icon: Icons.call_outlined,
              iconColor: Colors.orange,
              title: 'Calls',
              subtitle: 'Notifications for incoming calls',
              value: _settings.callNotifications,
              onChanged: (v) => setState(() => _settings.callNotifications = v),
            ),
            _divider(),
            _buildSwitchTile(
              icon: Icons.local_fire_department_outlined,
              iconColor: Colors.deepOrange,
              title: 'Bond warnings',
              subtitle: 'Alert when a bond is at risk or broken',
              value: _notifPrefs[NotifPrefs.streakWarnings] ?? true,
              onChanged: (v) => _setNotifPref(NotifPrefs.streakWarnings, v),
            ),
            _divider(),
            _buildSwitchTile(
              icon: Icons.emoji_events_outlined,
              iconColor: Colors.amber,
              title: 'Bond milestones',
              subtitle: 'Celebrate 7, 30, 100-day bond achievements',
              value: _notifPrefs[NotifPrefs.streakMilestones] ?? true,
              onChanged: (v) => _setNotifPref(NotifPrefs.streakMilestones, v),
            ),
            _divider(),
            _buildSwitchTile(
              icon: Icons.bolt_outlined,
              iconColor: const Color(0xFF6C5CE7),
              title: 'Gup Points rewards',
              subtitle: 'Notify when you earn significant Gup Points',
              value: _notifPrefs[NotifPrefs.gupPoints] ?? true,
              onChanged: (v) => _setNotifPref(NotifPrefs.gupPoints, v),
            ),
            _divider(),
            _buildSwitchTile(
              icon: Icons.wb_sunny_outlined,
              iconColor: Colors.teal,
              title: 'Daily digest',
              subtitle: 'Morning summary of your activity',
              value: _notifPrefs[NotifPrefs.dailyDigest] ?? true,
              onChanged: (v) => _setNotifPref(NotifPrefs.dailyDigest, v),
            ),
            _divider(),
            _buildSwitchTile(
              icon: Icons.mark_chat_unread_outlined,
              iconColor: Colors.blue,
              title: 'Unread reminders',
              subtitle: 'Remind about unread messages after 2 hours',
              value: _notifPrefs[NotifPrefs.unreadReminder] ?? true,
              onChanged: (v) => _setNotifPref(NotifPrefs.unreadReminder, v),
            ),
          ]),
          const SizedBox(height: 8),

          // ── Gup ───────────────────────────────────────────────────────
          _buildSectionHeader('GUP'),
          _buildCard(children: [
            _buildTile(
              icon: Icons.delete_sweep_outlined,
              iconColor: Colors.red,
              title: 'Clear all gup',
              subtitle: 'Delete all message history',
              onTap: _clearAllChats,
            ),
          ]),
          const SizedBox(height: 8),

          // ── Appearance ────────────────────────────────────────────────
          _buildSectionHeader('APPEARANCE'),
          _buildCard(children: [
            _buildAppearanceTile(),
          ]),
          const SizedBox(height: 8),

          // ── Help ──────────────────────────────────────────────────────
          _buildSectionHeader('HELP'),
          _buildCard(children: [
            _buildTile(
              icon: Icons.help_outline,
              iconColor: AppColors.primary,
              title: 'Help Center',
              subtitle: 'FAQs and support',
              onTap: _showHelpCenter,
            ),
            _divider(),
            _buildTile(
              icon: Icons.bug_report_outlined,
              iconColor: Colors.orange,
              title: 'Report a problem',
              subtitle: 'Something not working?',
              onTap: _reportProblem,
            ),
            _divider(),
            _buildTile(
              icon: Icons.info_outline,
              iconColor: Colors.grey,
              title: 'App info',
              subtitle: 'Version 1.1.0',
              onTap: () => _showAboutDialog(),
            ),
          ]),
          const SizedBox(height: 8),

          // ── Logout ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Log Out',
                  style: TextStyle(color: Colors.red, fontSize: 15)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
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

  // ── Profile header card ────────────────────────────────────────────────────
  Widget _buildProfileCard(String avatarUrl) {
    final c = AppThemeColors.of(context);
    return GestureDetector(
      onTap: () async {
        final updated = await Navigator.push<UserModel>(
          context,
          MaterialPageRoute(builder: (_) => ProfileScreen(currentUser: _user)),
        );
        if (updated != null) setState(() => _user = updated);
      },
      child: Container(
        color: c.surface,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: NetworkImage(avatarUrl),
              backgroundColor: c.surfaceAlt,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_user.name,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: c.textHigh)),
                  const SizedBox(height: 4),
                  Text(
                    _user.about ?? 'Hey there! I am using GupShupGo.',
                    style: TextStyle(color: c.textMid, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.textLow),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildAppearanceTile() {
    final c = AppThemeColors.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final currentMode = themeProvider.themeMode;

    final options = [
      (ThemeMode.light, Icons.light_mode_outlined, 'Light'),
      (ThemeMode.dark, Icons.dark_mode_outlined, 'Dark'),
      (ThemeMode.system, Icons.brightness_auto_outlined, 'System'),
    ];

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.indigo.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          currentMode == ThemeMode.dark
              ? Icons.dark_mode_outlined
              : currentMode == ThemeMode.light
                  ? Icons.light_mode_outlined
                  : Icons.brightness_auto_outlined,
          color: Colors.indigo,
          size: 20,
        ),
      ),
      title: Text('Theme', style: TextStyle(fontSize: 15, color: c.textHigh)),
      subtitle: Text(
        currentMode == ThemeMode.dark
            ? 'Dark'
            : currentMode == ThemeMode.light
                ? 'Light'
                : 'System default',
        style: TextStyle(color: c.textMid, fontSize: 12),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: c.textLow, size: 20),
      onTap: () {
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Choose theme',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...options.map((opt) {
                      final (mode, icon, label) = opt;
                      final selected = currentMode == mode;
                      return ListTile(
                        leading:
                            Icon(icon, color: selected ? c.primary : c.textMid),
                        title: Text(label,
                            style: TextStyle(
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.normal)),
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
      },
    );
  }

  Widget _buildSectionHeader(String label) {
    final c = AppThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
      child: Text(label,
          style: TextStyle(
              color: c.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8)),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    final c = AppThemeColors.of(context);
    return Container(
      color: c.surface,
      child: Column(children: children),
    );
  }

  Widget _divider() {
    final c = AppThemeColors.of(context);
    return Divider(height: 1, indent: 56, endIndent: 0, color: c.divider);
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    final c = AppThemeColors.of(context);
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: TextStyle(fontSize: 15, color: c.textHigh)),
      subtitle:
          Text(subtitle, style: TextStyle(color: c.textMid, fontSize: 12)),
      trailing: onTap != null
          ? Icon(Icons.chevron_right_rounded, color: c.textLow, size: 20)
          : null,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final c = AppThemeColors.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: TextStyle(fontSize: 15, color: c.textHigh)),
      subtitle:
          Text(subtitle, style: TextStyle(color: c.textMid, fontSize: 12)),
      trailing: Transform.scale(
        scale: 0.82,
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: c.primary,
          activeTrackColor: c.primaryLt,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
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
