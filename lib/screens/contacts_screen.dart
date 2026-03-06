import 'package:flutter/material.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/services/user_service.dart';
import 'package:video_chat_app/screens/call_screen.dart';
import 'package:video_chat_app/screens/chat_screen.dart';
import 'package:video_chat_app/services/fcm_service.dart';

class ContactsScreen extends StatefulWidget {
  final String currentUserId;
  final String? currentUserName;

  ContactsScreen({required this.currentUserId, this.currentUserName});

  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final UserService _userService = UserService();
  final FCMService _fcmService = FCMService();
  final TextEditingController _searchController = TextEditingController();

  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    List<UserModel> results = await _userService.searchUsers(
      query,
      widget.currentUserId,
    );

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  void _initiateCall(UserModel user) async {
    String channelId =
        '${widget.currentUserId}_${user.id}_${DateTime.now().millisecondsSinceEpoch}';

    // Send call notification to the user
    await _fcmService.sendCallNotification(
      user.id,
      widget.currentUserId,
      channelId,
    );

    // Navigate to call screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          channelId: channelId,
          isCaller: true,
          calleeId: user.id,
          calleeName: user.name,
        ),
      ),
    );
  }

  void _openChat(UserModel user) {
    // Convert UserModel to Contact for chat screen compatibility
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

  Widget _buildUserTile(UserModel user) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage(
              user.photoUrl ??
                  'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}&background=4CAF50&color=fff&size=128',
            ),
            backgroundColor: AppColors.primaryLt,
          ),
          if (user.isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.online,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        user.name,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        user.isOnline
            ? 'Online'
            : user.lastSeen != null
                ? 'Last seen ${_formatLastSeen(user.lastSeen!)}'
                : 'Offline',
        style: TextStyle(
          color: user.isOnline ? AppColors.online : AppColors.textMid,
          fontSize: 14,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.videocam_rounded, color: AppColors.primary),
            onPressed: () => _initiateCall(user),
          ),
          IconButton(
            icon: Icon(Icons.message_rounded, color: AppColors.primary),
            onPressed: () => _openChat(user),
          ),
        ],
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Contacts'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _searchUsers,
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        ),
      ),
      body: _searchController.text.isNotEmpty
          ? _buildSearchResults()
          : _buildAllUsers(),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryLt,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHigh),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildUserTile(_searchResults[index]);
      },
    );
  }

  Widget _buildAllUsers() {
    return StreamBuilder<List<UserModel>>(
      stream: _userService.getAllUsers(widget.currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading users: ${snapshot.error}'),
          );
        }

        List<UserModel> users = snapshot.data ?? [];

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLt,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.people_alt_rounded,
                      size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  'No users available',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHigh),
                ),
              ],
            ),
          );
        }

        // Sort users: online first
        users.sort((a, b) {
          if (a.isOnline == b.isOnline) return 0;
          return a.isOnline ? -1 : 1;
        });

        return ListView.separated(
          itemCount: users.length,
          separatorBuilder: (context, index) => const Divider(
            height: 1,
            indent: 72,
            endIndent: 16,
            color: AppColors.divider,
          ),
          itemBuilder: (context, index) {
            return _buildUserTile(users[index]);
          },
        );
      },
    );
  }
}
