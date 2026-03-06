import 'package:flutter/material.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/screens/auth/link_accounts_screen.dart';
import 'package:video_chat_app/screens/auth/login_screen.dart';
import 'package:video_chat_app/screens/profile_screen.dart';
import 'package:video_chat_app/services/auth_service.dart';

/// WhatsApp-style settings screen.
class SettingsScreen extends StatefulWidget {
  final UserModel currentUser;

  const SettingsScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  late UserModel _user;

  // Notification prefs (local only — persisted via SharedPreferences if needed)
  bool _messageNotifications = true;
  bool _groupNotifications = true;
  bool _callNotifications = true;
  bool _showReadReceipts = true;
  bool _showLastSeen = true;

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
              child: const Text('Log Out',
                  style: TextStyle(color: Colors.red))),
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

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _user.photoUrl ??
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_user.name)}&background=4CAF50&color=fff&size=128';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
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
              iconColor: Colors.blue,
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
              value: _showLastSeen,
              onChanged: (v) => setState(() => _showLastSeen = v),
            ),
            _divider(),
            _buildSwitchTile(
              icon: Icons.done_all,
              iconColor: Colors.blue,
              title: 'Read receipts',
              subtitle: 'Show blue ticks when you\'ve read messages',
              value: _showReadReceipts,
              onChanged: (v) => setState(() => _showReadReceipts = v),
            ),
            _divider(),
            _buildTile(
              icon: Icons.block,
              iconColor: Colors.red,
              title: 'Blocked contacts',
              subtitle: 'Manage blocked users',
              onTap: () => _showComingSoon('Blocked contacts'),
            ),
          ]),
          const SizedBox(height: 8),

          // ── Notifications ─────────────────────────────────────────────
          _buildSectionHeader('NOTIFICATIONS'),
          _buildCard(children: [
            _buildSwitchTile(
              icon: Icons.chat_bubble_outline,
              iconColor: Colors.blue,
              title: 'Messages',
              subtitle: 'Notifications for new messages',
              value: _messageNotifications,
              onChanged: (v) => setState(() => _messageNotifications = v),
            ),
            _divider(),
            _buildSwitchTile(
              icon: Icons.group_outlined,
              iconColor: Colors.green,
              title: 'Group messages',
              subtitle: 'Notifications for group activity',
              value: _groupNotifications,
              onChanged: (v) => setState(() => _groupNotifications = v),
            ),
            _divider(),
            _buildSwitchTile(
              icon: Icons.call_outlined,
              iconColor: Colors.orange,
              title: 'Calls',
              subtitle: 'Notifications for incoming calls',
              value: _callNotifications,
              onChanged: (v) => setState(() => _callNotifications = v),
            ),
          ]),
          const SizedBox(height: 8),

          // ── Chats ─────────────────────────────────────────────────────
          _buildSectionHeader('CHATS'),
          _buildCard(children: [
            _buildTile(
              icon: Icons.wallpaper,
              iconColor: Colors.purple,
              title: 'Chat wallpaper',
              subtitle: 'Choose a background for your chats',
              onTap: () => _showComingSoon('Chat wallpaper'),
            ),
            _divider(),
            _buildTile(
              icon: Icons.backup_outlined,
              iconColor: Colors.blue,
              title: 'Chat backup',
              subtitle: 'Back up chats to Google Drive',
              onTap: () => _showComingSoon('Chat backup'),
            ),
            _divider(),
            _buildTile(
              icon: Icons.delete_sweep_outlined,
              iconColor: Colors.red,
              title: 'Clear all chats',
              subtitle: 'Delete all message history',
              onTap: () => _showComingSoon('Clear all chats'),
            ),
          ]),
          const SizedBox(height: 8),

          // ── Help ──────────────────────────────────────────────────────
          _buildSectionHeader('HELP'),
          _buildCard(children: [
            _buildTile(
              icon: Icons.help_outline,
              iconColor: Colors.blue,
              title: 'Help Center',
              subtitle: 'FAQs and support',
              onTap: () => _showComingSoon('Help Center'),
            ),
            _divider(),
            _buildTile(
              icon: Icons.bug_report_outlined,
              iconColor: Colors.orange,
              title: 'Report a problem',
              subtitle: 'Something not working?',
              onTap: () => _showComingSoon('Report a problem'),
            ),
            _divider(),
            _buildTile(
              icon: Icons.info_outline,
              iconColor: Colors.grey,
              title: 'App info',
              subtitle: 'Version 1.0.0',
              onTap: () => _showAboutDialog(),
            ),
          ]),
          const SizedBox(height: 8),

          // ── Logout ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton.icon(
              onPressed: _signOut,
              icon:
                  const Icon(Icons.logout, color: Colors.red),
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

  // ── Profile header card ────────────────────────────────────────────────────
  Widget _buildProfileCard(String avatarUrl) {
    return GestureDetector(
      onTap: () async {
        final updated = await Navigator.push<UserModel>(
          context,
          MaterialPageRoute(
              builder: (_) => ProfileScreen(currentUser: _user)),
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
                    _user.about ??
                        'Hey there! I am using GupShupGo.',
                    style: TextStyle(
                        color: Colors.grey[600], fontSize: 13),
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
          style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8)),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      color: Colors.white,
      child: Column(children: children),
    );
  }

  Widget _divider() => Divider(height: 1, indent: 56, color: Colors.grey.shade100);

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
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: Text(subtitle,
          style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      trailing: onTap != null
          ? const Icon(Icons.chevron_right,
              color: Colors.grey, size: 20)
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
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: Text(subtitle,
          style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue,
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming soon!'),
        duration: const Duration(seconds: 2),
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
