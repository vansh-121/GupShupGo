import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/models/call_log_model.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/models/status_model.dart';
import 'package:video_chat_app/provider/call_state_provider.dart';
import 'package:video_chat_app/provider/status_provider.dart';
import 'package:video_chat_app/screens/call_screen.dart';
import 'package:video_chat_app/screens/chat_screen.dart';
import 'package:video_chat_app/screens/contacts_screen.dart';
import 'package:video_chat_app/screens/add_text_status_screen.dart';
import 'package:video_chat_app/screens/add_media_status_screen.dart';
import 'package:video_chat_app/screens/status_viewer_screen.dart';
import 'package:video_chat_app/screens/auth/login_screen.dart';
import 'package:video_chat_app/services/fcm_service.dart';
import 'package:video_chat_app/services/auth_service.dart';
import 'package:video_chat_app/services/user_service.dart';
import 'package:video_chat_app/services/chat_service.dart';
import 'package:video_chat_app/services/call_log_service.dart';
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
  final ChatService _chatService = ChatService();
  final CallLogService _callLogService = CallLogService();

  // ignore: unused_field
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
          // Mark all messages as delivered when app comes to foreground
          _chatService.markAllMessagesAsDeliveredOnAppOpen(_currentUserId!);
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
    // Mark all messages as delivered on app open
    if (_currentUserId != null) {
      await _chatService.markAllMessagesAsDeliveredOnAppOpen(_currentUserId!);
      // Initialize status provider
      final statusProvider =
          Provider.of<StatusProvider>(context, listen: false);
      statusProvider.initialize(_currentUserId!);
    }
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

  Future<void> _setupCallListener() async {
    try {
      final callState = Provider.of<CallStateNotifier>(context, listen: false);
      _fcmService.onCallReceived((callerId, channelId, isAudioOnly) {
        print('Incoming call from $callerId on channel $channelId (${isAudioOnly ? 'Audio' : 'Video'})');
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
                  isAudioOnly: isAudioOnly,
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
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
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
              currentUserName: _currentUser?.name,
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatsTab() {
    if (_currentUserId == null) {
      return Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<ChatRoom>>(
      stream: _chatService.getChatRooms(_currentUserId!),
      builder: (context, chatSnapshot) {
        if (chatSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final chatRooms = chatSnapshot.data ?? [];

        if (chatRooms.isEmpty) {
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ContactsScreen(
                          currentUserId: _currentUserId!,
                          currentUserName: _currentUser?.name,
                        ),
                      ),
                    );
                  },
                  child: Text('Start a conversation'),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: chatRooms.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            indent: 72,
            endIndent: 16,
          ),
          itemBuilder: (context, index) {
            final chatRoom = chatRooms[index];
            // Get the other participant's ID
            final otherUserId = chatRoom.participants
                .firstWhere((id) => id != _currentUserId, orElse: () => '');

            if (otherUserId.isEmpty) return SizedBox.shrink();

            return FutureBuilder<UserModel?>(
              future: _userService.getUserById(otherUserId),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey[300],
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    title: Container(
                      height: 16,
                      width: 100,
                      color: Colors.grey[200],
                    ),
                  );
                }

                final user = userSnapshot.data!;
                final unreadCount = chatRoom.unreadCount[_currentUserId] ?? 0;

                return _buildChatRoomItem(user, chatRoom, unreadCount);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildChatRoomItem(
      UserModel user, ChatRoom chatRoom, int unreadCount) {
    final contact = Contact(
      id: user.id,
      name: user.name,
      lastMessage: chatRoom.lastMessage ?? 'Tap to chat',
      time: chatRoom.lastMessageTime != null
          ? _formatChatTime(chatRoom.lastMessageTime!)
          : '',
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
      subtitle: Row(
        children: [
          if (chatRoom.lastMessageSenderId == _currentUserId)
            Padding(
              padding: EdgeInsets.only(right: 4),
              child: _buildMessageStatusIcon(chatRoom.lastMessageStatus),
            ),
          Expanded(
            child: Text(
              contact.lastMessage,
              style: TextStyle(
                color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                fontSize: 14,
                fontWeight:
                    unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            contact.time,
            style: TextStyle(
              color: unreadCount > 0 ? Colors.blue : Colors.grey[600],
              fontSize: 12,
            ),
          ),
          if (unreadCount > 0) ...[
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              contact: contact,
              currentUserId: _currentUserId!,
              currentUserName: _currentUser?.name,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageStatusIcon(MessageStatus? status) {
    switch (status) {
      case MessageStatus.sent:
        return Icon(Icons.done, size: 16, color: Colors.grey);
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: 16, color: Colors.grey);
      case MessageStatus.read:
        return Icon(Icons.done_all, size: 16, color: Colors.blue);
      default:
        return Icon(Icons.done, size: 16, color: Colors.grey);
    }
  }

  String _formatChatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      String hour = dateTime.hour > 12
          ? (dateTime.hour - 12).toString()
          : dateTime.hour == 0
              ? '12'
              : dateTime.hour.toString();
      String minute = dateTime.minute.toString().padLeft(2, '0');
      String period = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } else if (messageDate == today.subtract(Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dateTime.weekday - 1];
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Widget _buildStatusTab() {
    if (_currentUserId == null) {
      return Center(child: CircularProgressIndicator());
    }

    return Consumer<StatusProvider>(
      builder: (context, statusProvider, child) {
        final myStatus = statusProvider.myStatus;
        final otherStatuses = statusProvider.otherStatuses;
        final hasMyStatus = statusProvider.hasMyStatus;

        return ListView(
          children: [
            // My Status section
            _buildMyStatusTile(myStatus, hasMyStatus),

            // Divider
            if (otherStatuses.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Recent updates',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // Other users' statuses
            ...otherStatuses.map((status) => _buildStatusTile(status)),

            // Empty state
            if (otherStatuses.isEmpty)
              Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.update, size: 64, color: Colors.grey[300]),
                      SizedBox(height: 16),
                      Text(
                        'No status updates yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap the pencil icon to share a status',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMyStatusTile(StatusModel? myStatus, bool hasMyStatus) {
    final avatarUrl = _currentUser?.photoUrl ??
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_currentUser?.name ?? "Me")}&background=4CAF50&color=fff&size=128';

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          Container(
            padding: EdgeInsets.all(hasMyStatus ? 2 : 0),
            decoration: hasMyStatus
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue, width: 2),
                  )
                : null,
            child: CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(avatarUrl),
              backgroundColor: Colors.grey[300],
            ),
          ),
          if (!hasMyStatus)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(Icons.add, color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
      title: Text(
        'My Status',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        hasMyStatus
            ? '${myStatus!.activeStatusItems.length} status update${myStatus.activeStatusItems.length > 1 ? "s" : ""} · Tap to view'
            : 'Tap to add status update',
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
      onTap: () {
        if (hasMyStatus) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StatusViewerScreen(
                statusModel: myStatus!,
                currentUserId: _currentUserId!,
                isMyStatus: true,
              ),
            ),
          );
        } else {
          _navigateToAddStatus();
        }
      },
    );
  }

  Widget _buildStatusTile(StatusModel status) {
    final activeItems = status.activeStatusItems;
    if (activeItems.isEmpty) return SizedBox.shrink();

    final allViewed =
        activeItems.every((item) => item.viewedBy.contains(_currentUserId));

    final avatarUrl = status.userPhotoUrl ??
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(status.userName)}&background=4CAF50&color=fff&size=128';

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: allViewed ? Colors.grey[400]! : Colors.blue,
            width: 2,
          ),
        ),
        child: CircleAvatar(
          radius: 26,
          backgroundImage: NetworkImage(avatarUrl),
          backgroundColor: Colors.grey[300],
        ),
      ),
      title: Text(
        status.userName,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        _formatStatusTime(status.lastUpdated),
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StatusViewerScreen(
              statusModel: status,
              currentUserId: _currentUserId!,
            ),
          ),
        );
      },
    );
  }

  String _formatStatusTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return 'Yesterday';
  }

  void _navigateToAddStatus() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTextStatusScreen(
          userId: _currentUserId!,
          userName: _currentUser?.name ?? 'User',
          userPhotoUrl: _currentUser?.photoUrl,
          userPhoneNumber: _currentUser?.phoneNumber,
        ),
      ),
    );
  }

  void _navigateToAddMediaStatus() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMediaStatusScreen(
          userId: _currentUserId!,
          userName: _currentUser?.name ?? 'User',
          userPhotoUrl: _currentUser?.photoUrl,
          userPhoneNumber: _currentUser?.phoneNumber,
        ),
      ),
    );
  }

  Widget _buildCallsTab() {
    if (_currentUserId == null) {
      return Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<CallLogModel>>(
      stream: _callLogService.getCallLogs(_currentUserId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

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

        final callLogs = snapshot.data!;
        return ListView.builder(
          itemCount: callLogs.length,
          itemBuilder: (context, index) {
            final log = callLogs[index];
            
            // Get the other person's information
            final otherPersonName = log.getOtherPersonName(_currentUserId!);
            final otherPersonPhotoUrl = log.getOtherPersonPhotoUrl(_currentUserId!);
            final otherPersonId = log.callerId == _currentUserId ? log.calleeId : log.callerId;
            
            // Determine icon and color based on call type and status
            IconData callIcon;
            Color callIconColor;
            
            if (log.callType == CallType.incoming) {
              callIcon = Icons.call_received;
              callIconColor = log.status == CallStatus.missed 
                  ? Colors.red 
                  : Colors.green;
            } else if (log.callType == CallType.outgoing) {
              callIcon = Icons.call_made;
              callIconColor = log.status == CallStatus.cancelled 
                  ? Colors.red 
                  : Colors.green;
            } else {
              callIcon = Icons.call_missed;
              callIconColor = Colors.red;
            }
            
            // Format timestamp (e.g., "Today", "Yesterday", or date)
            String formatTimestamp(DateTime timestamp) {
              final now = DateTime.now();
              final difference = now.difference(timestamp);
              
              if (difference.inDays == 0) {
                final hour = timestamp.hour.toString().padLeft(2, '0');
                final minute = timestamp.minute.toString().padLeft(2, '0');
                return '$hour:$minute';
              } else if (difference.inDays == 1) {
                return 'Yesterday';
              } else if (difference.inDays < 7) {
                return '${difference.inDays} days ago';
              } else {
                return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
              }
            }

            return ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(
                  otherPersonPhotoUrl ??
                      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(otherPersonName)}&background=4CAF50&color=fff&size=128',
                ),
              ),
              title: Text(
                otherPersonName,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Row(
                children: [
                  Icon(
                    callIcon,
                    size: 16,
                    color: callIconColor,
                  ),
                  SizedBox(width: 4),
                  Text(
                    log.status == CallStatus.answered 
                        ? log.getFormattedDuration() 
                        : log.status.toString().split('.').last.capitalize(),
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatTimestamp(log.timestamp),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.videocam, color: Colors.blue),
                    onPressed: () {
                      final contact = Contact(
                        id: otherPersonId,
                        name: otherPersonName,
                        lastMessage: '',
                        time: '',
                        avatarUrl: otherPersonPhotoUrl ??
                            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(otherPersonName)}&background=4CAF50&color=fff&size=128',
                        isOnline: false,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            contact: contact,
                            currentUserId: _currentUserId!,
                            currentUserName: _currentUser?.name,
                          ),
                        ),
                      );
                    },
                  ),
                ],
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
                    builder: (_) => ContactsScreen(
                      currentUserId: _currentUserId!,
                      currentUserName: _currentUser?.name,
                    ),
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
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildFAB() {
    return AnimatedBuilder2(
      animation: _tabController.animation!,
      builder: (context, child) {
        final index = _tabController.index;
        if (index == 1) {
          // Status tab - show add status FABs
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: 'statusTextBtn',
                mini: true,
                backgroundColor: Colors.white,
                onPressed: () {
                  if (_currentUserId != null) {
                    _navigateToAddStatus();
                  }
                },
                child: Icon(Icons.edit, color: Colors.blue, size: 20),
              ),
              SizedBox(height: 12),
              FloatingActionButton(
                heroTag: 'statusCameraBtn',
                backgroundColor: Colors.blue,
                onPressed: () {
                  if (_currentUserId != null) {
                    _navigateToAddMediaStatus();
                  }
                },
                child: Icon(Icons.camera_alt, color: Colors.white),
              ),
            ],
          );
        }
        // Chats & Calls tabs - show message FAB
        return FloatingActionButton(
          heroTag: 'chatFab',
          backgroundColor: Colors.blue,
          onPressed: () {
            if (_currentUserId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ContactsScreen(
                    currentUserId: _currentUserId!,
                    currentUserName: _currentUser?.name,
                  ),
                ),
              );
            }
          },
          child: Icon(Icons.message, color: Colors.white),
        );
      },
    );
  }
}

/// Helper AnimatedBuilder widget for FAB animation.
class AnimatedBuilder2 extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder2({
    Key? key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(key: key, listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
