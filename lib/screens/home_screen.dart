import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/models/call_log_model.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/models/status_model.dart';
import 'package:video_chat_app/provider/status_provider.dart';
import 'package:video_chat_app/screens/chat_screen.dart';
import 'package:video_chat_app/screens/contacts_screen.dart';
import 'package:video_chat_app/screens/add_text_status_screen.dart';
import 'package:video_chat_app/screens/add_media_status_screen.dart';
import 'package:video_chat_app/screens/status_viewer_screen.dart';
import 'package:video_chat_app/screens/auth/login_screen.dart';
import 'package:video_chat_app/screens/nearby_peers_screen.dart';
import 'package:video_chat_app/screens/profile_screen.dart';
import 'package:video_chat_app/screens/settings_screen.dart';
import 'package:video_chat_app/services/fcm_service.dart';
import 'package:video_chat_app/services/auth_service.dart';
import 'package:video_chat_app/services/user_service.dart';
import 'package:video_chat_app/services/chat_service.dart';
import 'package:video_chat_app/services/chat_cache_service.dart';
import 'package:video_chat_app/services/call_log_service.dart';
import 'package:video_chat_app/services/status_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/services/mesh_network_service.dart';
import 'package:video_chat_app/services/update_service.dart';
import 'package:video_chat_app/services/crypto/plaintext_store.dart';
import 'package:video_chat_app/services/crypto/vault_cipher.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/widgets/vault_pin_dialog.dart';
import 'package:video_chat_app/widgets/whats_new_dialog.dart';

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
  final ChatCacheService _chatCacheService = ChatCacheService();
  final CallLogService _callLogService = CallLogService();
  final StatusService _statusService = StatusService();
  final UpdateService _updateService = UpdateService();

  // ignore: unused_field
  List<UserModel> _recentContacts = [];
  StreamSubscription? _recentContactsSub;
  bool _isRefreshingUsers = false; // debounce for background user refresh
  List<ChatRoom>? _lastCachedRooms; // guard against redundant cache writes

  // Tracks Firebase Auth presence so we can show a non-blocking re-verify
  // banner when the local session exists but Firebase has no user (typical
  // for phone-auth users on MIUI/HyperOS Redmi devices that wiped Firebase's
  // internal store, where there is no silent re-auth path).
  StreamSubscription<User?>? _authSub;
  bool _hasFirebaseSession = FirebaseAuth.instance.currentUser != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      final has = user != null;
      if (mounted && has != _hasFirebaseSession) {
        setState(() => _hasFirebaseSession = has);
      }
    });
    _initializeApp();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _recentContactsSub?.cancel();
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
          // Keep this device's FCM token fresh after reinstall, data clear,
          // Play Services recovery, or token rotation.
          unawaited(_fcmService.setupFCM(userId: _currentUserId!));
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
    _loadUser();

    // ── Load cached user profiles from disk for instant chat list ──
    _chatCacheService.loadUserCacheFromDisk();

    // ── Upgrade fallback: user_id exists but cached_user doesn't yet ──
    // This only happens once — on the first launch after the caching update.
    if (_currentUser == null && _currentUserId == null) {
      final userId = _authService.getCurrentUser()?.uid;
      if (userId != null) {
        _currentUserId = userId;
        // One-time Firestore read to seed the cache
        final user = await _authService.refreshUserFromFirestore();
        if (user != null && mounted) {
          _currentUser = user;
        }
      }
    }

    if (_currentUserId != null) {
      // ── Update MeshNetworkService with the authenticated identity ──
      // Applies userId + displayName together so peers see the user's real
      // name (not the pre-auth "Guest XXXX" placeholder), and re-broadcasts
      // if mesh was already running from the pre-auth flow.
      final mesh = Provider.of<MeshNetworkService>(context, listen: false);
      final name = (_currentUser?.name ?? '').trim();
      mesh.applyIdentity(
        userId: _currentUserId!,
        displayName: name.isEmpty ? mesh.displayName : name,
      );

      // ── Show UI immediately ──
      setState(() {
        _isInitialized = true;
      });

      // ── E2EE restore prompt + What's New — both need the Navigator ────────
      // addPostFrameCallback guarantees the first frame (including the
      // Navigator overlay) is built before we call showDialog. Calling
      // showDialog before the first frame silently no-ops on some devices.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        // Vault prompt must fire even if Signal registration is offline /
        // transiently failing — otherwise the user would silently see no
        // chats with no explanation. Each step is isolated in its own
        // try/catch so a failure in one never blocks the next.
        try {
          await _authService
              .ensureE2EERegisteredForCurrentSession(_currentUserId!);
        } catch (e) {
          debugPrint('[E2EE] registration failed in post-frame: $e');
        }
        if (!mounted) return;
        try {
          await _ensureVaultReady(_currentUserId!);
        } catch (e) {
          debugPrint('[Vault] readiness failed: $e');
        }
        if (!mounted) return;
        maybeShowWhatsNew(context);
      });

      // ── Run non-blocking setup concurrently ──
      _setupCallListener();
      _loadRecentContacts();

      final statusProvider =
          Provider.of<StatusProvider>(context, listen: false);
      statusProvider.initialize(_currentUserId!);

      // ── Background tasks — never block UI ──
      Future.wait([
        _fcmService
            .setupFCM(userId: _currentUserId!)
            .catchError((e) => print('FCM setup failed (non-critical): $e')),
        _userService.setupPresence(_currentUserId!).catchError(
            (e) => print('Presence setup failed (non-critical): $e')),
        _chatService
            .markAllMessagesAsDeliveredOnAppOpen(_currentUserId!)
            .catchError((e) => print('Background delivery sync error: $e')),
      ]);

      // ── Check for app updates via Google Play native API ──
      _updateService.checkAndPromptUpdate();

      // ── Refresh user profile from Firestore in background ──
      _authService.refreshUserFromFirestore().then((freshUser) {
        if (freshUser != null && mounted) {
          setState(() {
            _currentUser = freshUser;
          });
          // Keep mesh display name in sync if the canonical name changed.
          final freshName = freshUser.name.trim();
          if (freshName.isNotEmpty) {
            mesh.applyIdentity(userId: freshUser.id, displayName: freshName);
          }
        }
      });
    } else {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  /// Loads user from local cache (synchronous — no Firestore read).
  void _loadUser() {
    try {
      _currentUser = _authService.getSavedUser();
      if (_currentUser != null) {
        _currentUserId = _currentUser!.id;
        print('User loaded from cache: ${_currentUser!.name}');
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

  /// Bootstraps the E2EE vault key.
  ///
  /// • Auto-unlocks from the cached key in secure storage when possible
  ///   (warm path on every cold start after the first).
  /// • If the user has a vault config in Firestore but no local key
  ///   (reinstall, or first run after this feature shipped on an
  ///   already-onboarded account) → show the unlock dialog. The dialog
  ///   blocks until they enter the right PIN or reset.
  /// • If no vault config exists yet → show setup dialog so the user picks
  ///   a PIN before any vault writes happen. Until they finish, vault
  ///   writes silently skip — we never leak plaintext to Firestore.
  /// • After the vault is ready, drop in-memory pre-warm caches so the
  ///   next chat / status open re-reads the vault, and kick off a
  ///   background backfill of any local messages that aren't in the
  ///   vault yet (e.g. messages sent while the vault was still locked).
  Future<void> _ensureVaultReady(String uid) async {
    final state = await VaultCipher.instance.bootstrap(uid);
    if (state == VaultState.ready) {
      _migrateAndBackfillInBackground(uid);
      return;
    }
    if (!mounted) return;
    final ok = await VaultPinDialog.show(
      context: context,
      uid: uid,
      mode: state == VaultState.needsSetup
          ? VaultPinMode.setup
          : VaultPinMode.unlock,
    );
    if (!ok) return;
    ChatService.invalidatePreWarm(uid);
    StatusService.invalidatePreWarm(uid);
    _migrateAndBackfillInBackground(uid);
  }

  /// Background sweep that (a) re-encrypts any legacy plaintext vault docs
  /// produced by older app versions and (b) pushes anything in the local
  /// PlaintextStore that hasn't made it to the vault yet. Both passes are
  /// idempotent so a partial run on a previous launch heals on the next.
  void _migrateAndBackfillInBackground(String uid) {
    unawaited(() async {
      try {
        await VaultCipher.instance.migrateLegacyEntries(uid);
      } catch (_) {}
      try {
        final pruned = await VaultCipher.instance.applyRetention(uid);
        if (pruned > 0) {
          // Pruned entries leave stale previews in the in-memory caches;
          // drop them so the chat list refreshes.
          ChatService.invalidatePreWarm(uid);
          StatusService.invalidatePreWarm(uid);
        }
      } catch (_) {}
      _backfillVaultInBackground(uid);
    }());
  }

  /// Walks the local PlaintextStore and pushes any message not yet in
  /// the encrypted msgVault. Fire-and-forget — failures are non-fatal
  /// and retried opportunistically by future sends/receives.
  void _backfillVaultInBackground(String uid) {
    unawaited(() async {
      try {
        if (!VaultCipher.instance.isReady) return;
        final store = await PlaintextStore.instance();
        final local = await store.getAllMessagePayloads();
        if (local.isEmpty) return;
        final col = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('msgVault');
        // Probe what already lives in the vault — one read up front avoids
        // a per-message round trip on cold start.
        final existing = await col.get();
        final present = existing.docs.map((d) => d.id).toSet();
        final missing = local.entries
            .where((e) => !present.contains(e.key))
            .toList();
        for (final entry in missing) {
          final enc =
              await VaultCipher.instance.encryptPayload(entry.value);
          if (enc == null) return;
          try {
            await col.doc(entry.key).set(enc);
          } catch (_) {}
        }
      } catch (_) {}
    }());
  }

  Future<void> _setupCallListener() async {
    // ── Call acceptance/decline is now handled globally ──────────────────
    // The CallKit event listener in main.dart handles accept/decline/timeout
    // for ALL app states (foreground, background, killed). No per-screen
    // listener is needed anymore.
    //
    // Foreground FCM data messages → CallKit notification (handled in
    // FCMService.setupFCM via onMessage listener).
    // Background FCM data messages → CallKit notification (handled in
    // FCMService._firebaseMessagingBackgroundHandler).
    // Accept tap → CallScreen navigation (handled in main.dart
    // _handleCallAccepted via navigatorKey).
    print('Call listener: handled globally by CallKit in main.dart');
  }

  /// Non-blocking strip shown above the tabs when Firebase Auth has no
  /// session but local prefs still consider the user logged in (typical
  /// for phone-auth users after MIUI/HyperOS clears Firebase's internal
  /// store on aggressive force-stop). Tapping it routes to the login flow
  /// for re-verification; cached chats and offline mesh remain accessible
  /// in the meantime.
  Widget _buildReverifyBanner() {
    final c = AppThemeColors.of(context);
    return Material(
      color: c.primary.withOpacity(0.10),
      child: InkWell(
        onTap: _signOut,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.sync_problem_rounded, color: c.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Reconnect — tap to verify and receive new messages',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: c.textHigh,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.primary, size: 22),
            ],
          ),
        ),
      ),
    );
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
    _recentContactsSub?.cancel();
    _recentContactsSub =
        _userService.getAllUsers(_currentUserId!).listen((users) {
      if (mounted) {
        setState(() {
          _recentContacts = users.take(10).toList();
        });
      }
    });
  }

  Widget _buildContactItem(UserModel user) {
    final c = AppThemeColors.of(context);
    final contact = Contact(
      id: user.id,
      name: user.name,
      lastMessage: 'Tap to chat',
      time: '',
      avatarUrl: user.photoUrl ??
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}&background=6C5CE7&color=fff&size=128',
      isOnline: user.isOnline,
    );

    return InkWell(
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(contact.avatarUrl),
                  backgroundColor: c.primaryLt,
                ),
                if (contact.isOnline)
                  Positioned(
                    bottom: 1,
                    right: 1,
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
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                user.name,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: c.textHigh),
              ),
            ),
            if (user.isOnline)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.online.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Online',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: c.online,
                      fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatsTab() {
    if (_currentUserId == null) {
      return Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<ChatRoom>>(
      stream: _chatService.getChatRooms(_currentUserId!),
      builder: (context, chatSnapshot) {
        final c = AppThemeColors.of(context);
        // ── Use cached data while Firestore stream is still connecting ──
        List<ChatRoom> chatRooms;
        if (chatSnapshot.connectionState == ConnectionState.waiting &&
            !chatSnapshot.hasData) {
          chatRooms = _chatCacheService.getCachedChatRooms();
          if (chatRooms.isEmpty) {
            // No cache yet — show a brief loading indicator
            return Center(child: CircularProgressIndicator());
          }
        } else {
          chatRooms = chatSnapshot.data ?? [];
          // ── Auth-loss safety net ─────────────────────────────────────
          // If Firebase Auth has no session (typical on MIUI/HyperOS after
          // force-stop wipes Firebase's persistence), Firestore returns an
          // empty list because security rules deny unauthenticated reads.
          // Don't let that empty result overwrite a non-empty cached list —
          // keep showing the cache until either re-auth succeeds or the
          // stream emits real data again.
          if (chatRooms.isEmpty && !_authService.hasFirebaseSession) {
            final cached = _chatCacheService.getCachedChatRooms();
            if (cached.isNotEmpty) {
              chatRooms = cached;
            }
          } else if (chatRooms != _lastCachedRooms) {
            // ── Cache only when data actually changes (avoids redundant I/O
            //    on parent rebuilds that don't carry new stream data) ──
            _lastCachedRooms = chatRooms;
            _chatCacheService.cacheChatRooms(chatRooms);
            // ── Refresh user profiles (online status) in background ──
            _refreshChatUsersInBackground(chatRooms);
          }
        }

        if (chatRooms.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => _manualRefresh(chatRooms),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: c.primaryLt,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: c.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No chats yet',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: c.textHigh,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start a conversation by tapping the button below',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: c.textMid,
                          ),
                        ),
                        const SizedBox(height: 28),
                        ElevatedButton.icon(
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
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('New chat'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _manualRefresh(chatRooms),
          child: ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              final otherUserId = chatRoom.participants
                  .firstWhere((id) => id != _currentUserId, orElse: () => '');

              if (otherUserId.isEmpty) return SizedBox.shrink();

              // ── Try cached user first (instant, no Firestore) ──
              final cachedUser = _chatCacheService.getCachedUser(otherUserId);
              if (cachedUser != null) {
                final unreadCount = _effectiveUnreadCount(chatRoom);
                return _buildChatRoomItem(cachedUser, chatRoom, unreadCount);
              }

              // ── No cache yet — fetch once and cache for next time ──
              return FutureBuilder<UserModel?>(
                future: _fetchAndCacheUser(otherUserId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return _buildChatRoomPlaceholder();
                  }

                  final user = userSnapshot.data!;
                  final unreadCount = _effectiveUnreadCount(chatRoom);
                  return _buildChatRoomItem(user, chatRoom, unreadCount);
                },
              );
            },
          ),
        );
      },
    );
  }

  /// Called by RefreshIndicator — re-fetches all user profiles and
  /// re-triggers cache on the next stream emission.
  Future<void> _manualRefresh(List<ChatRoom> chatRooms) async {
    // Invalidate cache guard so next stream data re-runs caching logic
    _lastCachedRooms = null;
    // Re-fetch all user profiles in parallel
    final userIds = <String>{};
    for (final room in chatRooms) {
      for (final id in room.participants) {
        if (id != _currentUserId) userIds.add(id);
      }
    }
    try {
      final users = await Future.wait(
        userIds.map((id) => _userService.getUserById(id)),
      );
      for (final user in users) {
        if (user != null) _chatCacheService.cacheUser(user);
      }
      if (mounted) setState(() {});
    } catch (e) {
      print('Manual refresh error: $e');
    }
  }

  /// Fetches a user from Firestore and caches it locally so subsequent
  /// rebuilds don't hit the network.
  Future<UserModel?> _fetchAndCacheUser(String userId) async {
    final user = await _userService.getUserById(userId);
    if (user != null) {
      _chatCacheService.cacheUser(user);
    }
    return user;
  }

  /// Refreshes all chat participant profiles (including online status) in the
  /// background. When done, updates the cache and triggers a rebuild so the
  /// green online badges reflect real-time state.
  void _refreshChatUsersInBackground(List<ChatRoom> chatRooms) {
    if (_isRefreshingUsers) return; // debounce — one refresh at a time
    _isRefreshingUsers = true;
    // Collect unique other-user IDs
    final userIds = <String>{};
    for (final room in chatRooms) {
      for (final id in room.participants) {
        if (id != _currentUserId) userIds.add(id);
      }
    }

    // Fetch all in parallel
    Future.wait(
      userIds.map((id) => _userService.getUserById(id)),
    ).then((users) {
      bool changed = false;
      for (final user in users) {
        if (user != null) {
          final cached = _chatCacheService.getCachedUser(user.id);
          // Only trigger rebuild if online status actually changed
          if (cached == null ||
              cached.isOnline != user.isOnline ||
              cached.name != user.name ||
              cached.photoUrl != user.photoUrl) {
            changed = true;
          }
          _chatCacheService.cacheUser(user);
        }
      }
      if (changed && mounted) {
        setState(() {}); // Rebuild with fresh online badges
      }
      _isRefreshingUsers = false;
    }).catchError((e) {
      print('Background user refresh error: $e');
      _isRefreshingUsers = false;
    });
  }

  /// Minimal placeholder while a single user profile is being fetched.
  Widget _buildChatRoomPlaceholder() {
    final c = AppThemeColors.of(context);
    return ListTile(
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: c.primaryLt,
      ),
      title: Container(
        height: 14,
        width: 120,
        decoration: BoxDecoration(
          color: c.divider,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      subtitle: Container(
        height: 10,
        width: 80,
        margin: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
          color: c.divider,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  int _effectiveUnreadCount(ChatRoom chatRoom) {
    final storedUnread = chatRoom.unreadCount[_currentUserId] ?? 0;
    if (storedUnread > 0) return storedUnread;

    final isIncomingLastMessage = chatRoom.lastMessageSenderId != null &&
        chatRoom.lastMessageSenderId != _currentUserId;
    final isUnreadLastMessage =
        chatRoom.lastMessageStatus == MessageStatus.sent ||
            chatRoom.lastMessageStatus == MessageStatus.delivered;

    return isIncomingLastMessage && isUnreadLastMessage ? 1 : 0;
  }

  Widget _buildChatRoomItem(
      UserModel user, ChatRoom chatRoom, int unreadCount) {
    final c = AppThemeColors.of(context);
    final contact = Contact(
      id: user.id,
      name: user.name,
      lastMessage: chatRoom.lastMessage ?? 'Tap to chat',
      time: chatRoom.lastMessageTime != null
          ? _formatChatTime(chatRoom.lastMessageTime!)
          : '',
      avatarUrl: user.photoUrl ??
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}&background=6C5CE7&color=fff&size=128',
      isOnline: user.isOnline,
    );

    return InkWell(
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(contact.avatarUrl),
                  backgroundColor: c.primaryLt,
                ),
                if (contact.isOnline)
                  Positioned(
                    bottom: 1,
                    right: 1,
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
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.name,
                          style: GoogleFonts.poppins(
                            fontWeight: unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w600,
                            fontSize: 15,
                            color: c.textHigh,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        contact.time,
                        style: GoogleFonts.poppins(
                          color: unreadCount > 0 ? c.primary : c.textLow,
                          fontSize: 11,
                          fontWeight: unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (chatRoom.lastMessageSenderId == _currentUserId)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: _buildMessageStatusIcon(
                              chatRoom.lastMessageStatus),
                        ),
                      Expanded(
                        child: Text(
                          contact.lastMessage,
                          style: GoogleFonts.poppins(
                            color: unreadCount > 0 ? c.textHigh : c.textMid,
                            fontSize: 13,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageStatusIcon(MessageStatus? status) {
    final c = AppThemeColors.of(context);
    switch (status) {
      case MessageStatus.sent:
        return Icon(Icons.done_rounded, size: 14, color: c.textLow);
      case MessageStatus.delivered:
        return Icon(Icons.done_all_rounded, size: 14, color: c.textLow);
      case MessageStatus.read:
        return Icon(Icons.done_all_rounded, size: 14, color: c.primary);
      default:
        return Icon(Icons.done_rounded, size: 14, color: c.textLow);
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
        final c = AppThemeColors.of(context);
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Recent updates',
                  style: GoogleFonts.poppins(
                    color: c.textMid,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

            // Other users' statuses
            ...otherStatuses.map((status) => _buildStatusTile(status)),

            // Empty state
            if (otherStatuses.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLt,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_stories_rounded,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No updates yet',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHigh,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap the camera icon to share a status',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textMid,
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
    final c = AppThemeColors.of(context);
    final avatarUrl = _currentUser?.photoUrl ??
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_currentUser?.name ?? "Me")}&background=6C5CE7&color=fff&size=128';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          Container(
            padding: EdgeInsets.all(hasMyStatus ? 2 : 0),
            decoration: hasMyStatus
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: c.primary, width: 2.5),
                  )
                : null,
            child: CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(avatarUrl),
              backgroundColor: c.primaryLt,
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
                  color: c.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.surface, width: 2),
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
      title: Text(
        'My Status',
        style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600, fontSize: 15, color: c.textHigh),
      ),
      subtitle: Text(
        hasMyStatus
            ? '${myStatus!.activeStatusItems.length} update${myStatus.activeStatusItems.length > 1 ? "s" : ""} · Tap to view'
            : 'Tap to add a status update',
        style: GoogleFonts.poppins(color: c.textMid, fontSize: 13),
      ),
      onTap: () {
        if (hasMyStatus) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StatusViewerScreen(
                statusModel: myStatus!,
                currentUserId: _currentUserId!,
                currentUserName: _currentUser?.name,
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
    final c = AppThemeColors.of(context);
    final activeItems = status.activeStatusItems;
    if (activeItems.isEmpty) return const SizedBox.shrink();

    final avatarUrl = status.userPhotoUrl ??
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(status.userName)}&background=6C5CE7&color=fff&size=128';

    return FutureBuilder<bool>(
      future: _statusService.hasViewedAllActiveStatusItems(
        statusModel: status,
        viewerId: _currentUserId!,
      ),
      builder: (context, snapshot) {
        final allViewed = snapshot.data ??
            activeItems.every((item) => item.viewedBy.contains(_currentUserId));

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: allViewed ? c.textLow : c.primary,
                width: 2.5,
              ),
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundImage: NetworkImage(avatarUrl),
              backgroundColor: c.primaryLt,
            ),
          ),
          title: Text(
            status.userName,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, fontSize: 15, color: c.textHigh),
          ),
          subtitle: Text(
            _formatStatusTime(status.lastUpdated),
            style: GoogleFonts.poppins(color: c.textMid, fontSize: 13),
          ),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StatusViewerScreen(
                  statusModel: status,
                  currentUserId: _currentUserId!,
                  currentUserName: _currentUser?.name,
                ),
              ),
            );
            if (mounted) setState(() {});
          },
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
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
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
        final c = AppThemeColors.of(context);
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: c.primaryLt,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.call_outlined,
                    size: 48,
                    color: c.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No call history',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: c.textHigh,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your recent calls will appear here',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: c.textMid,
                  ),
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
            final otherPersonPhotoUrl =
                log.getOtherPersonPhotoUrl(_currentUserId!);
            final otherPersonId =
                log.callerId == _currentUserId ? log.calleeId : log.callerId;

            // Determine icon and color based on call type and status
            IconData callIcon;
            Color callIconColor;

            if (log.callType == CallType.incoming) {
              callIcon = Icons.call_received;
              callIconColor =
                  log.status == CallStatus.missed ? c.error : c.online;
            } else if (log.callType == CallType.outgoing) {
              callIcon = Icons.call_made;
              callIconColor =
                  log.status == CallStatus.cancelled ? c.error : c.online;
            } else {
              callIcon = Icons.call_missed;
              callIconColor = c.error;
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(
                  otherPersonPhotoUrl ??
                      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(otherPersonName)}&background=6C5CE7&color=fff&size=128',
                ),
                backgroundColor: c.primaryLt,
              ),
              title: Text(
                otherPersonName,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: c.textHigh),
              ),
              subtitle: Row(
                children: [
                  Icon(
                    callIcon,
                    size: 15,
                    color: callIconColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    log.status == CallStatus.answered
                        ? log.getFormattedDuration()
                        : log.status.toString().split('.').last.capitalize(),
                    style: GoogleFonts.poppins(color: c.textMid, fontSize: 13),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatTimestamp(log.timestamp),
                    style: GoogleFonts.poppins(color: c.textLow, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.videocam_rounded, color: c.primary),
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
    final c = AppThemeColors.of(context);
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: c.primaryLt,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: c.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: c.primary, strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 30,
                height: 30,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'GupShupGo',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: c.textHigh,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cell_tower_rounded),
            tooltip: 'Offline Chat — talk to people nearby',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NearbyPeersScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
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
            icon: _currentUser?.photoUrl != null
                ? CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(_currentUser!.photoUrl!),
                    backgroundColor: c.primaryLt,
                  )
                : const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'profile') {
                if (_currentUser != null) {
                  final updated = await Navigator.push<UserModel>(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ProfileScreen(currentUser: _currentUser!)),
                  );
                  if (updated != null) setState(() => _currentUser = updated);
                }
              } else if (value == 'settings') {
                if (_currentUser != null) {
                  final updated = await Navigator.push<UserModel>(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            SettingsScreen(currentUser: _currentUser!)),
                  );
                  if (updated != null) setState(() => _currentUser = updated);
                }
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
                      Icon(Icons.person_outline_rounded,
                          color: c.primary, size: 20),
                      const SizedBox(width: 12),
                      const Text('Profile'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings_outlined, color: c.textMid, size: 20),
                      const SizedBox(width: 12),
                      const Text('Settings'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded,
                          color: c.error, size: 20),
                      const SizedBox(width: 12),
                      Text('Log out', style: TextStyle(color: c.error)),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chats'),
            Tab(text: 'Status'),
            Tab(text: 'Calls'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (!_hasFirebaseSession) _buildReverifyBanner(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChatsTab(),
                _buildStatusTab(),
                _buildCallsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildFAB() {
    final c = AppThemeColors.of(context);
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
                backgroundColor: c.surface,
                elevation: 2,
                onPressed: () {
                  if (_currentUserId != null) {
                    _navigateToAddStatus();
                  }
                },
                child: Icon(Icons.edit_rounded, color: c.primary, size: 20),
              ),
              const SizedBox(height: 12),
              FloatingActionButton(
                heroTag: 'statusCameraBtn',
                backgroundColor: c.primary,
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
          backgroundColor: c.primary,
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
          child: const Icon(Icons.message_rounded, color: Colors.white),
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
