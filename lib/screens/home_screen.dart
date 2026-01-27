import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/provider/call_state_provider.dart';
import 'package:video_chat_app/screens/call_screen.dart';
import 'package:video_chat_app/screens/chat_screen.dart';
import 'package:video_chat_app/screens/contacts_screen.dart';
import 'package:video_chat_app/screens/auth/phone_auth_screen.dart';
import 'package:video_chat_app/services/fcm_service.dart';
import 'package:video_chat_app/services/auth_service.dart';
import 'package:video_chat_app/services/user_service.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  String? _currentUserId;
  UserModel? _currentUser;
  bool _isInitialized = false;
  late TabController _tabController;

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final FCMService _fcmService = FCMService();

  List<UserModel> _recentContacts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    if (_currentUserId != null) {
      _userService.updateOnlineStatus(_currentUserId!, false);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_currentUserId != null) {
      switch (state) {
        case AppLifecycleState.resumed:
          _userService.updateOnlineStatus(_currentUserId!, true);
          break;
        case AppLifecycleState.paused:
        case AppLifecycleState.inactive:
        case AppLifecycleState.detached:
          _userService.updateOnlineStatus(_currentUserId!, false);
          break;
        case AppLifecycleState.hidden:
          break;
      }
    }
  }

  Future<void> _initializeApp() async {
    await _loadUser();
    await _setupCallListener();
    _loadRecentContacts();
    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _loadUser() async {
    try {
      _currentUser = await _authService.getSavedUser();
      if (_currentUser != null) {
        setState(() {
          _currentUserId = _currentUser!.id;
        });
        await _fcmService.setupFCM(userId: _currentUserId!);
        await _userService.setupPresence(_currentUserId!);
        print('App initialized for user: ${_currentUser!.name}');
      }
    } catch (e) {
      print('Error loading user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing app: $e')),
        );
      }
    }
  }

  void _loadRecentContacts() {
    if (_currentUserId == null) return;
    _userService.getAllUsers(_currentUserId!).listen((users) {
      if (mounted) {
        setState(() {
          _recentContacts = users.take(10).toList();
        });
      }
    });
  }

  Future<void> _setupCallListener() async {
    try {
      final callState = Provider.of<CallStateNotifier>(context, listen: false);
      _fcmService.onCallReceived((callerId, channelId) {
        print('Incoming call from $callerId on channel $channelId');
        callState.updateState(CallState.Ringing);
        
        _userService.getUserById(callerId).then((caller) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CallScreen(
                  channelId: channelId,
                  isCaller: false,
                  calleeId: callerId,
                  calleeName: caller?.name ?? 'Unknown',
                ),
              ),
            );
          }
        });
      });
    } catch (e) {
      print('Error setting up call listener: $e');
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PhoneAuthScreen()),
      );
    }
  }

  Widget _buildContactItem(UserModel user) {
    final contact = Contact(
      id: user.id,
      name: user.name,
      lastMessage: 'Tap to chat',
      time: '',
      avatarUrl: user.photoUrl ??
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}&background=4CAF50&color=fff&size=128',
      isOnline: user.isOnline,
    );
    
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
        user.name,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        contact.lastMessage,
        style: TextStyle(color: Colors.grey[600], fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: user.isOnline
          ? Icon(Icons.circle, color: Colors.green, size: 12)
          : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              contact: contact,
              currentUserId: _currentUserId!,
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatsTab() {
    if (_recentContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No recent chats',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            TextButton(
              onPressed: () {
                if (_currentUserId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ContactsScreen(currentUserId: _currentUserId!),
                    ),
                  );
                }
              },
              child: Text('Browse Contacts'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _recentContacts.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        indent: 72,
        endIndent: 16,
      ),
      itemBuilder: (context, index) {
        return _buildContactItem(_recentContacts[index]);
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
    if (_currentUserId == null) {
      return Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<UserModel>>(
      stream: _userService.getAllUsers(_currentUserId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.call, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No call history',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final users = snapshot.data!;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(
                  user.photoUrl ??
                      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}&background=4CAF50&color=fff&size=128',
                ),
              ),
              title: Text(
                user.name,
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
                    'Video',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.videocam, color: Colors.blue),
                onPressed: () {
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
                      builder: (context) => ChatScreen(
                        contact: contact,
                        currentUserId: _currentUserId!,
                      ),
                    ),
                  );
                },
              ),
            );
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
              if (_currentUserId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ContactsScreen(currentUserId: _currentUserId!),
                  ),
                );
              }
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) {
              if (value == 'profile') {
                // Show profile screen
              } else if (value == 'settings') {
                // Show settings screen
              } else if (value == 'logout') {
                _signOut();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.black),
                      SizedBox(width: 12),
                      Text('Profile'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: Colors.black),
                      SizedBox(width: 12),
                      Text('Settings'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Logout', style: TextStyle(color: Colors.red)),
                    ],
                  ),
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
          if (_currentUserId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ContactsScreen(currentUserId: _currentUserId!),
              ),
            );
          }
        },
        backgroundColor: Colors.blue,
        child: Icon(Icons.message, color: Colors.white),
      ),
    );
  }
}
