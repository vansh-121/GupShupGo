import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
// Prefixed — flutter_contacts' Contact class collides with this app's own
// Contact model (defined in chat_screen.dart) used throughout this file.
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/services/user_service.dart';
import 'package:video_chat_app/services/friend_request_service.dart';
import 'package:video_chat_app/screens/call_screen.dart';
import 'package:video_chat_app/screens/chat_screen.dart';
import 'package:video_chat_app/services/fcm_service.dart';
import 'package:video_chat_app/services/call_signaling_service.dart';

class ContactsScreen extends StatefulWidget {
  final String currentUserId;
  final String? currentUserName;

  /// Tab to open on (0 = Friends, 1 = Requests, 2 = Discover). Defaults to
  /// Friends. Used when deep-linking from a friend-request notification.
  final int initialTabIndex;

  const ContactsScreen({
    super.key,
    required this.currentUserId,
    this.currentUserName,
    this.initialTabIndex = 0,
  });

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final FriendRequestService _friendService = FriendRequestService();
  final FCMService _fcmService = FCMService();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;

  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;

  UserModel? _currentUserModel;
  bool _isSyncingContacts = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _userService.getUserById(widget.currentUserId);
    if (mounted) {
      setState(() {
        _currentUserModel = user;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      List<UserModel> results = await _userService.searchUsersMultiField(
        query,
        widget.currentUserId,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _initiateCall(UserModel user) async {
    final channelId = CallSignalingService.generateChannelId();

    await CallSignalingService.createCallDocument(
      channelId: channelId,
      callerId: widget.currentUserId,
      calleeId: user.id,
    );

    await _fcmService.sendCallNotification(
      user.id,
      widget.currentUserId,
      channelId,
    );

    if (!mounted) return;

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
          currentUserName: widget.currentUserName ?? _currentUserModel?.name,
        ),
      ),
    );
  }

  void _showQRCodeModal() {
    final c = AppThemeColors.of(context);
    String handle = _currentUserModel?.username ?? widget.currentUserId;
    String qrData = 'https://gupshupgo.app/u/$handle';

    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'My Profile QR Code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: c.textHigh,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Friends can scan this QR code to connect with you instantly',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.textMid),
            ),
            const SizedBox(height: 20),
            // High-resolution QR Code Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200.0,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: c.primary,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.circle,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: c.primaryLt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.alternate_email_rounded, color: c.primary, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '@$handle',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: c.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: qrData));
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Profile link for @$handle copied!')),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy Profile Link'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Reads device contacts (phone numbers + emails), matches them against
  /// registered GupShupGo accounts via [UserService.matchDeviceContacts],
  /// and shows the matches in a bottom sheet with Add Friend / Message
  /// actions — reusing the same [UserDiscoverTile] as the Discover tab.
  Future<void> _syncDeviceContacts() async {
    final granted = await fc.FlutterContacts.requestPermission(readonly: true);
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission to access contacts was denied.')),
        );
      }
      return;
    }

    setState(() => _isSyncingContacts = true);

    try {
      final deviceContacts = await fc.FlutterContacts.getContacts(
        withProperties: true,
      );

      final rawPhones = <String>[];
      final rawEmails = <String>[];
      for (final contact in deviceContacts) {
        rawPhones.addAll(contact.phones.map((p) => p.number));
        rawEmails.addAll(contact.emails.map((e) => e.address));
      }

      final matches = await _userService.matchDeviceContacts(
        rawPhoneNumbers: rawPhones,
        rawEmails: rawEmails,
        currentUserId: widget.currentUserId,
      );

      if (!mounted) return;
      setState(() => _isSyncingContacts = false);

      if (matches.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No GupShupGo users found in your contacts yet.'),
          ),
        );
        return;
      }

      _showMatchedContactsSheet(matches);
    } catch (e) {
      if (mounted) {
        setState(() => _isSyncingContacts = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sync contacts: $e')),
        );
      }
    }
  }

  void _showMatchedContactsSheet(List<UserModel> matches) {
    final c = AppThemeColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.contacts_rounded, color: c.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${matches.length} contact${matches.length > 1 ? 's' : ''} on GupShupGo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: c.textHigh,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: matches.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, indent: 72, color: c.divider),
                itemBuilder: (context, index) {
                  return UserDiscoverTile(
                    targetUser: matches[index],
                    currentUserId: widget.currentUserId,
                    currentUserName:
                        _currentUserModel?.name ?? widget.currentUserName ?? 'User',
                    currentUserUsername: _currentUserModel?.username,
                    onOpenChat: (user) {
                      Navigator.pop(context);
                      _openChat(user);
                    },
                    onInitiateCall: (user) {
                      Navigator.pop(context);
                      _initiateCall(user);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        title: const Text('Contacts & Discover'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_rounded),
            tooltip: 'My Handle',
            onPressed: _showQRCodeModal,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: c.primary,
          labelColor: c.primary,
          unselectedLabelColor: c.textMid,
          tabs: [
            const Tab(text: 'Friends'),
            StreamBuilder<QuerySnapshot>(
              stream: _friendService.streamIncomingRequests(widget.currentUserId),
              builder: (context, snapshot) {
                int count = snapshot.data?.docs.length ?? 0;
                return Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Requests'),
                      if (count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const Tab(text: 'Discover'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsTab(),
          _buildRequestsTab(),
          _buildDiscoverTab(),
        ],
      ),
    );
  }

  // TAB 1: Friends (Only explicit accepted connections)
  Widget _buildFriendsTab() {
    final c = AppThemeColors.of(context);

    return StreamBuilder<List<UserModel>>(
      stream: _friendService.streamFriends(widget.currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: c.primary));
        }

        List<UserModel> friends = snapshot.data ?? [];

        if (friends.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: c.primaryLt,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.people_outline_rounded, size: 48, color: c.primary),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'No Friends Added Yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: c.textHigh,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use the Discover tab to search for users by @username, phone, or email and send them a friend request!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: c.textMid),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _tabController.animateTo(2),
                    icon: const Icon(Icons.person_add_rounded),
                    label: const Text('Discover People'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Sort online first, then alphabetically by name so ordering within
        // each group is stable across rebuilds instead of following
        // whatever order Firestore happens to return.
        friends.sort((a, b) {
          if (a.isOnline != b.isOnline) {
            return a.isOnline ? -1 : 1;
          }
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

        return ListView.separated(
          itemCount: friends.length,
          separatorBuilder: (_, __) => Divider(height: 1, indent: 72, color: c.divider),
          itemBuilder: (context, index) => _buildFriendTile(friends[index]),
        );
      },
    );
  }

  Widget _buildFriendTile(UserModel user) {
    final c = AppThemeColors.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundImage: NetworkImage(
              user.photoUrl ??
                  'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}&background=4CAF50&color=fff&size=128',
            ),
            backgroundColor: c.primaryLt,
          ),
          if (user.isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: c.online,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        user.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        user.username != null && user.username!.isNotEmpty
            ? '@${user.username}'
            : (user.isOnline ? 'Online' : 'Offline'),
        style: TextStyle(
          color: user.username != null ? c.primary : (user.isOnline ? c.online : c.textMid),
          fontSize: 13,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.videocam_rounded, color: c.primary),
            onPressed: () => _initiateCall(user),
          ),
          IconButton(
            icon: Icon(Icons.message_rounded, color: c.primary),
            onPressed: () => _openChat(user),
          ),
        ],
      ),
    );
  }

  // TAB 2: Incoming Requests
  Widget _buildRequestsTab() {
    final c = AppThemeColors.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: _friendService.streamIncomingRequests(widget.currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: c.primary));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: c.primaryLt,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.mark_email_read_outlined, size: 48, color: c.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Pending Requests',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: c.textHigh,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When users send you a connection request, they will show up here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: c.textMid),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: c.divider),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final requestId = docs[index].id;
            final fromUserId = data['fromUserId'] ?? '';
            final fromName = data['fromName'] ?? 'Unknown User';
            final fromUsername = data['fromUsername'] ?? '';

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: c.primaryLt,
                child: Text(
                  fromName.isNotEmpty ? fromName[0].toUpperCase() : 'U',
                  style: TextStyle(fontWeight: FontWeight.bold, color: c.primary),
                ),
              ),
              title: Text(
                fromName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              subtitle: Text(
                fromUsername.isNotEmpty ? '@$fromUsername' : 'Wants to connect',
                style: TextStyle(color: c.textMid, fontSize: 13),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _friendService.acceptFriendRequest(
                        requestId: requestId,
                        currentUserId: widget.currentUserId,
                        friendId: fromUserId,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Connected with $fromName!')),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    onPressed: () async {
                      await _friendService.declineFriendRequest(requestId);
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

  // TAB 3: Universal Search & Discover
  Widget _buildDiscoverTab() {
    final c = AppThemeColors.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by Name, @username, Phone, Email...',
                  prefixIcon: Icon(Icons.search, color: c.primary),
                  filled: true,
                  fillColor: c.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSyncingContacts ? null : _syncDeviceContacts,
                      icon: _isSyncingContacts
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.contacts_rounded, size: 18),
                      label: Text(_isSyncingContacts ? 'Syncing...' : 'Sync Device Contacts'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _searchController.text.isNotEmpty
              ? _buildSearchResults()
              : _buildDiscoveryDefault(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    final c = AppThemeColors.of(context);

    if (_isSearching) {
      return Center(child: CircularProgressIndicator(color: c.primary));
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_search_rounded, size: 48, color: c.textMid),
              const SizedBox(height: 12),
              Text(
                'No Matching Users Found',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: c.textHigh),
              ),
              const SizedBox(height: 4),
              Text(
                'Check the @username, phone number, or email and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: c.textMid),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => Divider(height: 1, indent: 72, color: c.divider),
      itemBuilder: (context, index) {
        return UserDiscoverTile(
          targetUser: _searchResults[index],
          currentUserId: widget.currentUserId,
          currentUserName: _currentUserModel?.name ?? widget.currentUserName ?? 'User',
          currentUserUsername: _currentUserModel?.username,
          onOpenChat: _openChat,
          onInitiateCall: _initiateCall,
        );
      },
    );
  }

  Widget _buildDiscoveryDefault() {
    final c = AppThemeColors.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.primaryLt,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.explore_rounded, color: c.primary, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discover People on GupShupGo',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: c.textHigh,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Send a friend request to connect, or search by custom @username, phone number, or email.',
                        style: TextStyle(fontSize: 12, color: c.textMid),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Suggested Users',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: c.textHigh,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<UserModel>>(
            stream: _userService.getAllUsers(widget.currentUserId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: c.primary));
              }

              List<UserModel> suggested = snapshot.data ?? [];
              if (suggested.isEmpty) {
                return Text('No suggested users available right now.', style: TextStyle(color: c.textMid));
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: suggested.length > 8 ? 8 : suggested.length,
                separatorBuilder: (_, __) => Divider(height: 1, indent: 72, color: c.divider),
                itemBuilder: (context, index) {
                  return UserDiscoverTile(
                    targetUser: suggested[index],
                    currentUserId: widget.currentUserId,
                    currentUserName: _currentUserModel?.name ?? widget.currentUserName ?? 'User',
                    currentUserUsername: _currentUserModel?.username,
                    onOpenChat: _openChat,
                    onInitiateCall: _initiateCall,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Dynamic User Discover Tile featuring live connection state & Send Request action
class UserDiscoverTile extends StatefulWidget {
  final UserModel targetUser;
  final String currentUserId;
  final String currentUserName;
  final String? currentUserUsername;
  final Function(UserModel) onOpenChat;
  final Function(UserModel) onInitiateCall;

  const UserDiscoverTile({
    super.key,
    required this.targetUser,
    required this.currentUserId,
    required this.currentUserName,
    this.currentUserUsername,
    required this.onOpenChat,
    required this.onInitiateCall,
  });

  @override
  State<UserDiscoverTile> createState() => _UserDiscoverTileState();
}

class _UserDiscoverTileState extends State<UserDiscoverTile> {
  final FriendRequestService _friendService = FriendRequestService();
  ConnectionStateStatus _status = ConnectionStateStatus.none;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    ConnectionStateStatus s = await _friendService.getConnectionStatus(
      widget.currentUserId,
      widget.targetUser.id,
    );
    if (mounted) {
      setState(() {
        _status = s;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendRequest() async {
    if (_isSending) return;
    setState(() => _isSending = true);

    bool success = await _friendService.sendFriendRequest(
      fromUserId: widget.currentUserId,
      toUserId: widget.targetUser.id,
      fromName: widget.currentUserName,
      fromUsername: widget.currentUserUsername,
    );

    if (mounted) {
      setState(() {
        _isSending = false;
        if (success) {
          _status = ConnectionStateStatus.pendingSent;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Friend request sent to ${widget.targetUser.name}!'
                : 'Friend request is already pending or failed.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final user = widget.targetUser;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 26,
        backgroundImage: NetworkImage(
          user.photoUrl ??
              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}&background=4CAF50&color=fff&size=128',
        ),
        backgroundColor: c.primaryLt,
      ),
      title: Text(
        user.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        user.username != null && user.username!.isNotEmpty
            ? '@${user.username}'
            : (user.email ?? 'GupShupGo User'),
        style: TextStyle(color: c.textMid, fontSize: 13),
      ),
      trailing: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : _buildActionWidget(c),
    );
  }

  Widget _buildActionWidget(AppThemeColors c) {
    switch (_status) {
      case ConnectionStateStatus.friends:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.videocam_rounded, color: c.primary),
              onPressed: () => widget.onInitiateCall(widget.targetUser),
            ),
            IconButton(
              icon: Icon(Icons.message_rounded, color: c.primary),
              onPressed: () => widget.onOpenChat(widget.targetUser),
            ),
          ],
        );

      case ConnectionStateStatus.pendingSent:
        return OutlinedButton.icon(
          onPressed: null, // Disabled when pending
          icon: const Icon(Icons.hourglass_top_rounded, size: 16),
          label: const Text('Requested'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

      case ConnectionStateStatus.pendingReceived:
        return ElevatedButton.icon(
          onPressed: () async {
            // Find incoming request ID and accept
            QuerySnapshot snap = await FirebaseFirestore.instance
                .collection('friend_requests')
                .where('fromUserId', isEqualTo: widget.targetUser.id)
                .where('toUserId', isEqualTo: widget.currentUserId)
                .where('status', isEqualTo: 'pending')
                .limit(1)
                .get();

            if (snap.docs.isNotEmpty) {
              await _friendService.acceptFriendRequest(
                requestId: snap.docs.first.id,
                currentUserId: widget.currentUserId,
                friendId: widget.targetUser.id,
              );
              if (mounted) {
                setState(() => _status = ConnectionStateStatus.friends);
              }
            }
          },
          icon: const Icon(Icons.check_rounded, size: 16),
          label: const Text('Accept'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

      case ConnectionStateStatus.none:
      default:
        return ElevatedButton.icon(
          onPressed: _isSending ? null : _sendRequest,
          icon: _isSending
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.person_add_rounded, size: 16),
          label: const Text('Add Friend'),
          style: ElevatedButton.styleFrom(
            backgroundColor: c.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
    }
  }
}
