import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_chat_app/provider/call_state_provider.dart';
import 'package:video_chat_app/screens/chat_screen.dart';
import 'package:video_chat_app/services/fcm_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String? _currentUser;
  bool _isInitialized = false;
  late TabController _tabController;

  final List<Contact> _contacts = [
    Contact(
      id: 'chirag',
      name: 'Chirag C4D',
      lastMessage: 'Hello Sam !!!',
      time: '2:21 PM',
      avatarUrl:
          'https://ui-avatars.com/api/?name=Chirag+C4D&background=4CAF50&color=fff&size=128',
      isOnline: true,
    ),
    Contact(
      id: 'josh',
      name: 'Josh',
      lastMessage: 'How are you?',
      time: '1:02 PM',
      avatarUrl:
          'https://ui-avatars.com/api/?name=Josh&background=2196F3&color=fff&size=128',
      isOnline: true,
    ),
    Contact(
      id: 'tim',
      name: 'Tim',
      lastMessage: 'Call me maybe?',
      time: '12:21 PM',
      avatarUrl:
          'https://ui-avatars.com/api/?name=Tim&background=FF9800&color=fff&size=128',
      isOnline: false,
    ),
    Contact(
      id: 'stefan',
      name: 'Stefan',
      lastMessage: 'Done Sir !!',
      time: '12:00 PM',
      avatarUrl:
          'https://ui-avatars.com/api/?name=Stefan&background=9C27B0&color=fff&size=128',
      isOnline: true,
    ),
    Contact(
      id: 'ben',
      name: 'Ben',
      lastMessage: 'Please send documents',
      time: '11:30 AM',
      avatarUrl:
          'https://ui-avatars.com/api/?name=Ben&background=F44336&color=fff&size=128',
      isOnline: false,
    ),
    Contact(
      id: 'david',
      name: 'David',
      lastMessage: 'See you tomorrow',
      time: '10:02 AM',
      avatarUrl:
          'https://ui-avatars.com/api/?name=David&background=607D8B&color=fff&size=128',
      isOnline: true,
    ),
    Contact(
      id: 'elena',
      name: 'Elena',
      lastMessage: 'I am leaving now',
      time: '9:30 AM',
      avatarUrl:
          'https://ui-avatars.com/api/?name=Elena&background=E91E63&color=fff&size=128',
      isOnline: false,
    ),
    Contact(
      id: 'neha',
      name: 'Neha',
      lastMessage: 'Hello Sam !!!',
      time: '9:22 AM',
      avatarUrl:
          'https://ui-avatars.com/api/?name=Neha&background=00BCD4&color=fff&size=128',
      isOnline: true,
    ),
    Contact(
      id: 'kiran',
      name: 'Kiran',
      lastMessage: 'Where are you ?',
      time: '9:00 AM',
      avatarUrl:
          'https://ui-avatars.com/api/?name=Kiran&background=795548&color=fff&size=128',
      isOnline: false,
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
      final userId = prefs.getString('user_id') ?? 'sam';
      setState(() {
        _currentUser = userId;
      });

      await FCMService().setupFCM();
      print('App initialized for user: $userId');
    } catch (e) {
      print('Error loading user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing app: $e')),
      );
    }
  }

  Future<void> _setupCallListener() async {
    try {
      final callState = Provider.of<CallStateNotifier>(context, listen: false);
      FCMService().onCallReceived((callerId, channelId) {
        print('Incoming call from $callerId on channel $channelId');
        callState.updateState(CallState.Ringing);
        // Navigate to call screen when call is received
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
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        contact.lastMessage,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            contact.time,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
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
              currentUserId: _currentUser ?? 'sam',
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
      itemCount: 5,
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
          trailing: Icon(
            Icons.videocam,
            color: Colors.blue,
          ),
          onTap: () {
            // Handle call tap
          },
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
              Text('Initializing...', style: TextStyle(fontSize: 16)),
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
          ),
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
              // Handle menu selection
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'profile',
                  child: Text('Profile'),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Text('Settings'),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Text('Switch User'),
                ),
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
            Tab(text: 'Chats'),
            Tab(text: 'Status'),
            Tab(text: 'Calls'),
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
