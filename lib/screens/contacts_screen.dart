import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
// Prefixed — flutter_contacts' Contact class collides with this app's own
// Contact model (defined in chat_screen.dart) used throughout this file.
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:google_fonts/google_fonts.dart';
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
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: c.textHigh,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Friends can scan this QR code to connect with you instantly',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: c.textMid),
            ),
            const SizedBox(height: 20),
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
                dataModuleStyle: const QrDataModuleStyle(
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
                    style: GoogleFonts.poppins(
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
                    SnackBar(
                      content: Text(
                        'Profile link for @$handle copied!',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
                label: Text('Copy Profile Link', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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

  Future<void> _syncDeviceContacts() async {
    final granted = await fc.FlutterContacts.requestPermission(readonly: true);
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Permission to access contacts was denied.',
              style: GoogleFonts.poppins(),
            ),
          ),
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
          SnackBar(
            content: Text(
              'No GupShupGo users found in your contacts yet.',
              style: GoogleFonts.poppins(),
            ),
          ),
        );
        return;
      }

      _showMatchedContactsSheet(matches);
    } catch (e) {
      if (mounted) {
        setState(() => _isSyncingContacts = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync contacts: $e', style: GoogleFonts.poppins()),
          ),
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
                    style: GoogleFonts.poppins(
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
                    customSubtitle: 'From your device contacts',
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
        scrolledUnderElevation: 0,
        backgroundColor: c.surface,
        elevation: 0,
        title: Text(
          'Contacts & Discover',
          style: GoogleFonts.poppins(
            color: c.textHigh,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_2_rounded, color: c.textHigh, size: 24),
            tooltip: 'My Handle',
            onPressed: _showQRCodeModal,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: c.divider, width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: c.primary,
              indicatorWeight: 3,
              labelColor: c.textHigh,
              unselectedLabelColor: c.textMid,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
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
                                color: c.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: GoogleFonts.poppins(
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
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Glowing Icon Background (Stitch Design)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.primary.withOpacity(0.12),
                        boxShadow: [
                          BoxShadow(
                            color: c.primary.withOpacity(0.2),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.cardBg,
                        border: Border.all(
                          color: c.isDark
                              ? Colors.white.withOpacity(0.1)
                              : c.primary.withOpacity(0.15),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.person_add_rounded,
                        size: 44,
                        color: c.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'No Friends Added Yet',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: c.textHigh,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: c.textMid,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Use the Discover tab to search for users by ',
                        ),
                        TextSpan(
                          text: '@username',
                          style: GoogleFonts.poppins(
                            color: c.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(
                          text: ', phone, or email and send them a friend request!',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Primary Action Button (Discover People)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _tabController.animateTo(2),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      shadowColor: c.primary.withOpacity(0.3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Discover People',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Quick Suggestions Section (Stitch Design Pattern)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'QUICK CONNECT',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c.textMid,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                FutureBuilder<List<QuickConnectSuggestion>>(
                  future: _friendService.getQuickConnectSuggestions(widget.currentUserId),
                  builder: (context, suggestSnapshot) {
                    if (suggestSnapshot.connectionState == ConnectionState.waiting) {
                      return Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: CircularProgressIndicator(color: c.primary),
                        ),
                      );
                    }

                    List<QuickConnectSuggestion> suggestions = suggestSnapshot.data ?? [];
                    if (suggestions.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: c.surfaceAlt,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'No suggestions available at the moment.',
                          style: GoogleFonts.poppins(color: c.textMid, fontSize: 13),
                        ),
                      );
                    }

                    final displayList = suggestions.take(3).toList();

                    return Column(
                      children: displayList
                          .map(
                            (suggestion) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: c.cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: c.isDark
                                        ? Colors.white.withOpacity(0.06)
                                        : c.border,
                                  ),
                                ),
                                child: UserDiscoverTile(
                                  targetUser: suggestion.user,
                                  customSubtitle: suggestion.reasonSubtitle,
                                  currentUserId: widget.currentUserId,
                                  currentUserName: _currentUserModel?.name ??
                                      widget.currentUserName ??
                                      'User',
                                  currentUserUsername: _currentUserModel?.username,
                                  onOpenChat: _openChat,
                                  onInitiateCall: _initiateCall,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          );
        }

        // Sort online first, then alphabetically by name
        friends.sort((a, b) {
          if (a.isOnline != b.isOnline) {
            return a.isOnline ? -1 : 1;
          }
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: friends.length,
          itemBuilder: (context, index) => _buildFriendTile(friends[index]),
        );
      },
    );
  }

  Widget _buildFriendTile(UserModel user) {
    final c = AppThemeColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: c.isDark ? Colors.white.withOpacity(0.05) : c.divider,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 24,
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
                    width: 13,
                    height: 13,
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
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: c.textHigh,
            ),
          ),
          subtitle: Text(
            user.username != null && user.username!.isNotEmpty
                ? '@${user.username}'
                : (user.isOnline ? 'Online' : 'Offline'),
            style: GoogleFonts.poppins(
              color: user.username != null
                  ? c.primary
                  : (user.isOnline ? c.online : c.textMid),
              fontSize: 13,
              fontWeight: user.username != null ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: c.primaryLt,
                  shape: const CircleBorder(),
                ),
                icon: Icon(Icons.videocam_rounded, color: c.primary, size: 20),
                onPressed: () => _initiateCall(user),
              ),
              const SizedBox(width: 6),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: c.primaryLt,
                  shape: const CircleBorder(),
                ),
                icon: Icon(Icons.message_rounded, color: c.primary, size: 20),
                onPressed: () => _openChat(user),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TAB 2: Incoming Requests (Redesigned with Stitch Specs)
  Widget _buildRequestsTab() {
    final c = AppThemeColors.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: _friendService.streamIncomingRequests(widget.currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: c.primary));
        }

        final docs = snapshot.data?.docs ?? [];

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pending Requests Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PENDING REQUESTS (${docs.length})',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c.textMid,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (docs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: c.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: c.isDark ? Colors.white.withOpacity(0.06) : c.divider,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: c.primaryLt,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.mark_email_read_outlined, size: 32, color: c.primary),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No Pending Requests',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: c.textHigh,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'When users send you a connection request, they will show up here.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 12, color: c.textMid),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final requestId = doc.id;
                    final fromUserId = data['fromUserId'] ?? '';
                    final fromName = data['fromName'] ?? 'Unknown User';
                    final fromUsername = data['fromUsername'] ?? '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: c.cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: c.isDark ? Colors.white.withOpacity(0.08) : c.divider,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            radius: 26,
                            backgroundColor: c.primaryLt,
                            child: Text(
                              fromName.isNotEmpty ? fromName[0].toUpperCase() : 'U',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: c.primary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          title: Text(
                            fromName,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: c.textHigh,
                            ),
                          ),
                          subtitle: Text(
                            fromUsername.isNotEmpty ? '@$fromUsername' : 'Wants to connect',
                            style: GoogleFonts.poppins(color: c.textMid, fontSize: 13),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  await _friendService.acceptFriendRequest(
                                    requestId: requestId,
                                    currentUserId: widget.currentUserId,
                                    friendId: fromUserId,
                                  );
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Connected with $fromName!',
                                          style: GoogleFonts.poppins(),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: c.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  'ACCEPT',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: c.isDark ? Colors.white.withOpacity(0.2) : c.border,
                                  ),
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: Icon(Icons.close_rounded, color: c.textMid, size: 18),
                                  onPressed: () async {
                                    await _friendService.declineFriendRequest(requestId);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 28),

              // You Might Know Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'YOU MIGHT KNOW',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c.textMid,
                      letterSpacing: 1.2,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _tabController.animateTo(2),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'SEE ALL',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: c.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2-Column Suggestion Grid
              FutureBuilder<List<QuickConnectSuggestion>>(
                future: _friendService.getQuickConnectSuggestions(widget.currentUserId),
                builder: (context, suggestSnapshot) {
                  if (suggestSnapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: CircularProgressIndicator(color: c.primary),
                      ),
                    );
                  }

                  final suggestions = suggestSnapshot.data ?? [];
                  if (suggestions.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: c.surfaceAlt,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'No suggestions right now.',
                        style: GoogleFonts.poppins(color: c.textMid, fontSize: 13),
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: suggestions.length > 4 ? 4 : suggestions.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemBuilder: (context, index) {
                      final item = suggestions[index];
                      return YouMightKnowCard(
                        targetUser: item.user,
                        reasonSubtitle: item.reasonSubtitle,
                        currentUserId: widget.currentUserId,
                        currentUserName: _currentUserModel?.name ?? widget.currentUserName ?? 'User',
                        currentUserUsername: _currentUserModel?.username,
                      );
                    },
                  );
                },
              ),
            ],
          ),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: GoogleFonts.poppins(color: c.textHigh, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by Name, @username, Phone, Email...',
                  hintStyle: GoogleFonts.poppins(color: c.textLow, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: c.primary),
                  filled: true,
                  fillColor: c.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: c.isDark ? Colors.white.withOpacity(0.05) : Colors.transparent,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: c.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSyncingContacts ? null : _syncDeviceContacts,
                  icon: _isSyncingContacts
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: c.primary,
                          ),
                        )
                      : Icon(Icons.contacts_rounded, size: 18, color: c.primary),
                  label: Text(
                    _isSyncingContacts ? 'Syncing...' : 'Sync Device Contacts',
                    style: GoogleFonts.poppins(
                      color: c.textHigh,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: c.isDark ? Colors.white.withOpacity(0.1) : c.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
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
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: c.textHigh),
              ),
              const SizedBox(height: 4),
              Text(
                'Check the @username, phone number, or email and try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: c.textMid),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            decoration: BoxDecoration(
              color: c.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: c.isDark ? Colors.white.withOpacity(0.05) : c.divider,
              ),
            ),
            child: UserDiscoverTile(
              targetUser: _searchResults[index],
              currentUserId: widget.currentUserId,
              currentUserName: _currentUserModel?.name ?? widget.currentUserName ?? 'User',
              currentUserUsername: _currentUserModel?.username,
              onOpenChat: _openChat,
              onInitiateCall: _initiateCall,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiscoveryDefault() {
    final c = AppThemeColors.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.primaryLt,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: c.primary.withOpacity(0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: c.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.explore_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discover People on GupShupGo',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: c.textHigh,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Send a friend request to connect, or search by custom @username, phone number, or email.',
                        style: GoogleFonts.poppins(fontSize: 12, color: c.textMid, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'SUGGESTED USERS',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: c.textMid,
              letterSpacing: 1.2,
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
                return Text('No suggested users available right now.', style: GoogleFonts.poppins(color: c.textMid));
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: suggested.length > 8 ? 8 : suggested.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: c.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: c.isDark ? Colors.white.withOpacity(0.05) : c.divider,
                        ),
                      ),
                      child: UserDiscoverTile(
                        targetUser: suggested[index],
                        currentUserId: widget.currentUserId,
                        currentUserName: _currentUserModel?.name ?? widget.currentUserName ?? 'User',
                        currentUserUsername: _currentUserModel?.username,
                        onOpenChat: _openChat,
                        onInitiateCall: _initiateCall,
                      ),
                    ),
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

/// You Might Know Suggestion Card (2-Column Grid Item)
class YouMightKnowCard extends StatefulWidget {
  final UserModel targetUser;
  final String reasonSubtitle;
  final String currentUserId;
  final String currentUserName;
  final String? currentUserUsername;

  const YouMightKnowCard({
    super.key,
    required this.targetUser,
    required this.reasonSubtitle,
    required this.currentUserId,
    required this.currentUserName,
    this.currentUserUsername,
  });

  @override
  State<YouMightKnowCard> createState() => _YouMightKnowCardState();
}

class _YouMightKnowCardState extends State<YouMightKnowCard> {
  final FriendRequestService _friendService = FriendRequestService();
  bool _isSending = false;
  bool _isRequested = false;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final user = widget.targetUser;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: c.isDark ? Colors.white.withOpacity(0.08) : c.divider,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(
              user.photoUrl ??
                  'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}&background=4CAF50&color=fff&size=128',
            ),
            backgroundColor: c.primaryLt,
          ),
          const SizedBox(height: 8),
          Text(
            user.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: c.textHigh,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.reasonSubtitle.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: c.textMid,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 34,
            child: _isRequested
                ? OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'Requested',
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _isSending
                        ? null
                        : () async {
                            setState(() => _isSending = true);
                            bool ok = await _friendService.sendFriendRequest(
                              fromUserId: widget.currentUserId,
                              toUserId: user.id,
                              fromName: widget.currentUserName,
                              fromUsername: widget.currentUserUsername,
                            );
                            if (mounted) {
                              setState(() {
                                _isSending = false;
                                if (ok) _isRequested = true;
                              });
                            }
                          },
                    icon: _isSending
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.person_add_rounded, size: 14),
                    label: Text(
                      'ADD FRIEND',
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
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
  final String? customSubtitle;
  final Function(UserModel) onOpenChat;
  final Function(UserModel) onInitiateCall;

  const UserDiscoverTile({
    super.key,
    required this.targetUser,
    required this.currentUserId,
    required this.currentUserName,
    this.currentUserUsername,
    this.customSubtitle,
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
            style: GoogleFonts.poppins(),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(
          user.photoUrl ??
              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}&background=4CAF50&color=fff&size=128',
        ),
        backgroundColor: c.primaryLt,
      ),
      title: Text(
        user.name,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: c.textHigh,
        ),
      ),
      subtitle: Text(
        widget.customSubtitle ??
            (user.username != null && user.username!.isNotEmpty
                ? '@${user.username}'
                : (user.email ?? 'GupShupGo User')),
        style: GoogleFonts.poppins(color: c.textMid, fontSize: 13),
      ),
      trailing: _isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: c.primary),
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
              style: IconButton.styleFrom(
                backgroundColor: c.primaryLt,
                shape: const CircleBorder(),
              ),
              icon: Icon(Icons.videocam_rounded, color: c.primary, size: 20),
              onPressed: () => widget.onInitiateCall(widget.targetUser),
            ),
            const SizedBox(width: 6),
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: c.primaryLt,
                shape: const CircleBorder(),
              ),
              icon: Icon(Icons.message_rounded, color: c.primary, size: 20),
              onPressed: () => widget.onOpenChat(widget.targetUser),
            ),
          ],
        );

      case ConnectionStateStatus.pendingSent:
        return OutlinedButton.icon(
          onPressed: null, // Disabled when pending
          icon: const Icon(Icons.hourglass_top_rounded, size: 14),
          label: Text('Requested', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

      case ConnectionStateStatus.pendingReceived:
        return ElevatedButton.icon(
          onPressed: () async {
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
          icon: const Icon(Icons.check_rounded, size: 14),
          label: Text('Accept', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.person_add_rounded, size: 14),
          label: Text('Add Friend', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: c.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
    }
  }
}
