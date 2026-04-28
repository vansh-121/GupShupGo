import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/screens/auth/link_accounts_screen.dart';
import 'package:video_chat_app/screens/auth/login_screen.dart';
import 'package:video_chat_app/screens/profile_screen.dart';
import 'package:video_chat_app/services/auth_service.dart';
import 'package:video_chat_app/services/settings_service.dart';
import 'package:video_chat_app/services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final ChatService _chatService = ChatService();
  late UserModel _user;

  @override
  void initState() {
    super.initState();
    _user = widget.currentUser;
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
          const SnackBar(
            content: Text('All chats cleared'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear chats: $e'),
            backgroundColor: Colors.red,
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
          return Padding(
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
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Help Center',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textHigh),
                ),
                const SizedBox(height: 20),
                _buildFAQItem(
                  'How do I start a new chat?',
                  'Tap the message icon (💬) at the bottom-right of the Chats tab, '
                      'or use the search icon in the top bar to find contacts.',
                ),
                _buildFAQItem(
                  'How do I make a voice or video call?',
                  'Open a chat with the person you want to call. '
                      'Tap the phone icon (🔊) for an audio call or the '
                      'camera icon (📹) for a video call in the top bar.',
                ),
                _buildFAQItem(
                  'How do I share a status update?',
                  'Go to the Status tab and tap the pencil icon for a text status '
                      'or the camera icon for a photo/video status.',
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
                const Text(
                  'Still need help?',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.textHigh),
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
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(question,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.textHigh)),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(answer,
              style: const TextStyle(fontSize: 13, color: AppColors.textMid)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _user.photoUrl ??
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_user.name)}&background=4CAF50&color=fff&size=128';

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // ── Profile card ──────────────────────────────────────────────
          _buildProfileCard(avatarUrl),
          const SizedBox(height: 8),

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
              onChanged: (v) =>
                  setState(() => _settings.showReadReceipts = v),
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
              onChanged: (v) =>
                  setState(() => _settings.callNotifications = v),
            ),
          ]),
          const SizedBox(height: 8),

          // ── Chats ─────────────────────────────────────────────────────
          _buildSectionHeader('CHATS'),
          _buildCard(children: [
            _buildTile(
              icon: Icons.delete_sweep_outlined,
              iconColor: Colors.red,
              title: 'Clear all chats',
              subtitle: 'Delete all message history',
              onTap: _clearAllChats,
            ),
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
              subtitle: 'Version 1.0.1',
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

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
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
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Blocked Contacts',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHigh)),
            const SizedBox(height: 12),
            if (blockedUsers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No blocked contacts',
                      style: TextStyle(color: AppColors.textMid)),
                ),
              )
            else
              ...blockedUsers.map((user) => ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(user.photoUrl ??
                          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}&background=4CAF50&color=fff&size=128'),
                      backgroundColor: Colors.grey[200],
                    ),
                    title: Text(user.name),
                    trailing: TextButton(
                      onPressed: () async {
                        await _unblockUser(user.id);
                        Navigator.pop(context);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('${user.name} unblocked')),
                          );
                        }
                      },
                      child: const Text('Unblock',
                          style: TextStyle(color: AppColors.primary)),
                    ),
                  )),
            const SizedBox(height: 12),
          ],
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
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_user.id)
        .update({
      'blockedUsers': FieldValue.arrayRemove([userId]),
    });
  }

  // ── Profile header card ────────────────────────────────────────────────────
  Widget _buildProfileCard(String avatarUrl) {
    return GestureDetector(
      onTap: () async {
        final updated = await Navigator.push<UserModel>(
          context,
          MaterialPageRoute(builder: (_) => ProfileScreen(currentUser: _user)),
        );
        if (updated != null) setState(() => _user = updated);
      },
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: NetworkImage(avatarUrl),
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_user.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(
                    _user.about ?? 'Hey there! I am using GupShupGo.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
      child: Text(label,
          style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8)),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      color: AppColors.surface,
      child: Column(children: children),
    );
  }

  Widget _divider() => const Divider(
      height: 1, indent: 56, endIndent: 0, color: AppColors.divider);

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
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
      title: Text(title,
          style: const TextStyle(fontSize: 15, color: AppColors.textHigh)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppColors.textMid, fontSize: 12)),
      trailing: onTap != null
          ? const Icon(Icons.chevron_right_rounded,
              color: AppColors.textLow, size: 20)
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
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 15, color: AppColors.textHigh)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppColors.textMid, fontSize: 12)),
      trailing: Transform.scale(
        scale: 0.82,
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
          activeTrackColor: AppColors.primaryLt,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'GupShupGo',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026 GupShupGo',
    );
  }
}
