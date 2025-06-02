import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_chat_app/provider/call_state_provider.dart';
import 'package:video_chat_app/screens/call_screen.dart';
import 'package:video_chat_app/screens/chat_screen.dart';
import 'package:video_chat_app/services/fcm_service.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String? _currentUser;
  bool _isInitialized = false;
  late TabController _tabController;

  final List<String> _availableUsers = ['user_a', 'user_b'];

  final List<Contact> _contacts = [
    Contact(
      id: 'user_a',
      name: 'User A',
      lastMessage: 'Hello!',
      time: '10:20 PM',
      avatarUrl:
          'https://ui-avatars.com/api/?name=User+A&background=4CAF50&color=fff&size=128',
      isOnline: true,
    ),
    Contact(
      id: 'user_b',
      name: 'User B',
      lastMessage: 'How are you?',
      time: '1:02 PM',
      avatarUrl:
          'https://ui-avatars.com/api/?name=User+B&background=2196F3&color=fff&size=128',
      isOnline: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeApp();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await _loadUser();
    await _setupCallListener();
    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? _availableUsers[0];
      setState(() {
        _currentUser = userId;
      });
      await FCMService().setupFCM(userId: userId);
      print('App initialized for user: $userId');
    } catch (e) {
      print('Error loading user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing app: $e')),
      );
    }
  }

  Future<void> _switchUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    setState(() {
      _currentUser = userId;
    });
    await FCMService().setupFCM(userId: userId);
    print('Switched to user: $userId');
  }

  Future<void> _setupCallListener() async {
    try {
      final callState = Provider.of<CallStateNotifier>(context, listen: false);
      FCMService().onCallReceived((callerId, channelId) {
        print('Incoming call from $callerId on channel $channelId');
        callState.updateState(CallState.Ringing);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CallScreen(channelId: channelId, isCaller: false),
          ),
        );
      });
    } catch (e) {
      print('Error setting up call listener: $e');
    }
  }

  Widget _buildContactItem(Contact contact) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage(contact.avatarUrl),
            backgroundColor: Colors.grey[300],
          ),
          if (contact.isOnline)
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
        contact.name,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        contact.lastMessage,
        style: TextStyle(color: Colors.grey[600], fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            contact.time,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Text(
              '1',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              contact: contact,
              currentUserId: _currentUser ?? _availableUsers[0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatsTab() {
    return ListView.separated(
      itemCount: _contacts.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        indent: 72,
        endIndent: 16,
      ),
      itemBuilder: (context, index) {
        return _buildContactItem(_contacts[index]);
      },
    );
  }

  Widget _buildStatusTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Status updates coming soon',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCallsTab() {
    return ListView.builder(
      itemCount: _contacts.length,
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        return ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage(contact.avatarUrl),
          ),
          title: Text(
            contact.name,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Row(
            children: [
              Icon(
                index % 2 == 0 ? Icons.call_received : Icons.call_made,
                size: 16,
                color: index % 2 == 0 ? Colors.green : Colors.red,
              ),
              SizedBox(width: 4),
              Text(
                '${contact.time} • Video',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.videocam, color: Colors.blue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    contact: contact,
                    currentUserId: _currentUser ?? _availableUsers[0],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(height: 20),
              Text('Initializing...',
                  style: TextStyle(
                      fontSize: 16,
                      fontFamily: GoogleFonts.poppins().fontFamily)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          'Messages',
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: GoogleFonts.poppins().fontFamily),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.black),
            onPressed: () {
              // Implement search
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) {
              if (value == 'switch_user') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Switch User'),
                    content: DropdownButtonFormField<String>(
                      value: _currentUser,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Select User',
                      ),
                      items: _availableUsers.map((user) {
                        return DropdownMenuItem(
                          value: user,
                          child: Text(user.replaceAll('_', ' ').toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _switchUser(value);
                          Navigator.pop(context);
                        }
                      },
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(value: 'profile', child: Text('Profile')),
                PopupMenuItem(value: 'settings', child: Text('Settings')),
                PopupMenuItem(value: 'switch_user', child: Text('Switch User')),
              ];
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
                child: Text('Chats',
                    style: TextStyle(
                        fontFamily: GoogleFonts.poppins().fontFamily))),
            Tab(
                child: Text('Status',
                    style: TextStyle(
                        fontFamily: GoogleFonts.poppins().fontFamily))),
            Tab(
                child: Text('Calls',
                    style: TextStyle(
                        fontFamily: GoogleFonts.poppins().fontFamily))),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatsTab(),
          _buildStatusTab(),
          _buildCallsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle new chat/call
        },
        backgroundColor: Colors.blue,
        child: Icon(Icons.message, color: Colors.white),
      ),
    );
  }
}
