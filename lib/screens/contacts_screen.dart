import 'package:flutter/material.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/services/user_service.dart';
import 'package:video_chat_app/screens/call_screen.dart';
import 'package:video_chat_app/screens/chat_screen.dart';
import 'package:video_chat_app/services/fcm_service.dart';

class ContactsScreen extends StatefulWidget {
  final String currentUserId;

  ContactsScreen({required this.currentUserId});

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
    String channelId = '${widget.currentUserId}_${user.id}_${DateTime.now().millisecondsSinceEpoch}';
    
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
            backgroundColor: Colors.grey[300],
          ),
          if (user.isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.green,
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
          color: user.isOnline ? Colors.green : Colors.grey[600],
          fontSize: 14,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.videocam, color: Colors.blue),
            onPressed: () => _initiateCall(user),
          ),
          IconButton(
            icon: Icon(Icons.message, color: Colors.blue),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Contacts'),
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
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      return Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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
          return Center(child: CircularProgressIndicator());
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
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No users available',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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
          separatorBuilder: (context, index) => Divider(
            height: 1,
            indent: 72,
            endIndent: 16,
          ),
          itemBuilder: (context, index) {
            return _buildUserTile(users[index]);
          },
        );
      },
    );
  }
}
