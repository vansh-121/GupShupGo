import 'package:flutter/material.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/screens/call_screen.dart';
import 'package:video_chat_app/screens/connecting_call_screen.dart';
import 'package:video_chat_app/screens/chat_screen.dart';
import 'package:video_chat_app/screens/contacts_screen.dart' show UserDiscoverTile;
import 'package:video_chat_app/services/call_signaling_service.dart';
import 'package:video_chat_app/services/fcm_service.dart';
import 'package:video_chat_app/services/user_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// Opened when a `https://gupshupgo.app/u/<username>` link is tapped (QR
/// scan, shared link, or the intent-filter deep link) and the app is
/// already signed in. Looks the target user up by their unique handle and
/// shows a minimal profile with the same connect/message actions used in
/// the Discover tab.
class PublicProfileScreen extends StatefulWidget {
  final String username;
  final String currentUserId;
  final String? currentUserName;

  const PublicProfileScreen({
    super.key,
    required this.username,
    required this.currentUserId,
    this.currentUserName,
  });

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
    final user = await _userService.getUserByUsername(widget.username);
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
              '@${widget.username} not found',
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 56,
            backgroundImage: NetworkImage(
              user.photoUrl ??
                  'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}&background=6C5CE7&color=fff&size=256',
            ),
            backgroundColor: c.primaryLt,
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: c.textHigh,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@${user.username}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: c.primary,
            ),
          ),
          if (user.about != null && user.about!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              user.about!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.textMid),
            ),
          ],
          const SizedBox(height: 28),
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
              ),
            ),
        ],
      ),
    );
  }
}
