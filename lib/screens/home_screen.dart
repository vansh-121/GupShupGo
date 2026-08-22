import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_chat_app/services/crypto/signal_service.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/main.dart';
import 'package:video_chat_app/models/call_log_model.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/models/status_model.dart';
import 'package:video_chat_app/models/gamification_data.dart';
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
import 'package:video_chat_app/screens/gup_arcade_screen.dart';
import 'package:video_chat_app/services/auth_service.dart';
import 'package:video_chat_app/services/user_service.dart';
import 'package:video_chat_app/services/presence_service.dart';
import 'package:video_chat_app/services/review_prompt_service.dart';
import 'package:video_chat_app/services/chat_service.dart';
import 'package:video_chat_app/services/sync_service.dart';
import 'package:video_chat_app/services/chat_cache_service.dart';
import 'package:video_chat_app/services/call_log_service.dart';
import 'package:video_chat_app/services/status_service.dart';
import 'package:video_chat_app/services/streak/streak_repository.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/services/mesh_network_service.dart';
import 'package:video_chat_app/services/crypto/plaintext_store.dart';
import 'package:video_chat_app/services/crypto/vault_cipher.dart';
import 'package:video_chat_app/services/crypto/vault_pin_custody.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/services/notification_service.dart';
import 'package:video_chat_app/widgets/vault_pin_custody_dialog.dart';
import 'package:video_chat_app/widgets/vault_pin_dialog.dart';
import 'package:video_chat_app/widgets/vault_locked_banner.dart';
import 'package:video_chat_app/widgets/feature_coach_marks.dart';
import 'package:video_chat_app/widgets/starter_checklist_card.dart';
import 'package:video_chat_app/widgets/whats_new_dialog.dart';
import 'package:video_chat_app/widgets/streak_badge.dart';
import 'package:video_chat_app/provider/subscription_provider.dart';
import 'package:video_chat_app/widgets/premium_gate.dart';
import 'package:video_chat_app/screens/anonymous/anonymous_lobby_screen.dart';
import 'package:video_chat_app/screens/auth/username_setup_screen.dart';
import 'package:video_chat_app/screens/public_profile_screen.dart';
import 'package:video_chat_app/services/deep_link_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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

  // ignore: unused_field
  List<UserModel> _recentContacts = [];
  StreamSubscription? _recentContactsSub;
  bool _isRefreshingUsers = false; // debounce for background user refresh
  List<ChatRoom>? _lastCachedRooms; // guard against redundant cache writes

  // Cached chat-list stream. Created lazily on the first build of the
  // Gup tab and reused for the rest of the screen's lifetime. Without
  // this, getChatRooms() was being re-invoked on every rebuild (e.g.
  // when the user switched to Moments/Calls and back), producing a fresh
  // single-subscription StreamController each time — and the
  // StreamBuilder occasionally tried to re-listen on the same instance
  // during the rebuild handoff, throwing "Stream has already been
  // listened to".
  Stream<List<ChatRoom>>? _chatRoomsStream;

  // Tracks Firebase Auth presence so we can show a non-blocking re-verify
  // banner when the local session exists but Firebase has no user (typical
  // for phone-auth users on MIUI/HyperOS Redmi devices that wiped Firebase's
  // internal store, where there is no silent re-auth path).
  StreamSubscription<User?>? _authSub;
  bool _hasFirebaseSession = FirebaseAuth.instance.currentUser != null;

  // ─── Gamification real-time listener ─────────────────────────────────
  StreamSubscription<DocumentSnapshot>? _currentUserSubscription;
  List<String>? _previousBadges;

  // ─── Bond badges ─────────────────────────────────────────────────────
  // One `watchMany` subscription for the whole visible chat list, so a change
  // to any bond rebuilds the list once rather than once per row. The views are
  // derived by StreakRepository — the list does no streak arithmetic.
  StreamSubscription<Map<String, StreakView>>? _streakViewsSub;
  Map<String, StreakView> _streakViews = const <String, StreakView>{};
  List<String> _watchedStreakRoomIds = const <String>[];

  // ─── Presence decay ──────────────────────────────────────────────────
  // The chat-list dot is rendered from ChatCacheService, whose presence check
  // is against the clock — so the verdict changes with time, not just with new
  // data. Without a tick, a contact who stopped heartbeating would keep a green
  // dot until something else happened to rebuild the list.
  Timer? _presenceDecayTimer;
  static const _presenceDecayInterval = Duration(seconds: 20);

  // ─── First-run coaching ──────────────────────────────────────────────
  // Attached to the two entry points that give no hint of what they do, so
  // the spotlight can be measured from their real laid-out position rather
  // than hardcoded offsets. See widgets/feature_coach_marks.dart.
  final GlobalKey _meshIconKey = GlobalKey();
  final GlobalKey _arcadeChipKey = GlobalKey();

  // ─── Locked vault ────────────────────────────────────────────────────
  // True only when the vault holds history this install cannot read and the
  // user declined the unlock prompt ("Restore later"). Drives the chats-tab
  // banner, which is the sole visible route back: the automatic re-prompt
  // fires from initState only, so backgrounding and returning does not
  // re-ask, and the alternative is buried in Settings. Never set for a
  // needsSetup account — it has no older messages to restore.
  bool _vaultLockedWithHistory = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addObserver(this);
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      final has = user != null;
      if (mounted && has != _hasFirebaseSession) {
        setState(() => _hasFirebaseSession = has);
      }
    });
    _startPresenceDecayTimer();
    _initializeApp();
  }

  /// Rebuilds the list on an interval so cached presence can go stale on
  /// screen, and pulls fresh profiles so it can also come back online.
  /// Paused while backgrounded — nobody is looking at the dots then.
  void _startPresenceDecayTimer() {
    _presenceDecayTimer?.cancel();
    _presenceDecayTimer = Timer.periodic(_presenceDecayInterval, (_) {
      if (!mounted) return;
      setState(() {}); // re-evaluates getCachedUser against the clock
      final rooms = _lastCachedRooms;
      if (rooms != null && rooms.isNotEmpty) {
        // Debounced internally by _isRefreshingUsers.
        _refreshChatUsersInBackground(rooms);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _recentContactsSub?.cancel();
    _currentUserSubscription?.cancel();
    _streakViewsSub?.cancel();
    _presenceDecayTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    // No manual Firestore presence write needed here — PresenceService owns
    // those fields, and the RTDB onDisconnect handler fires server-side when
    // the connection drops, marking the user offline even on force-kill.
    if (_currentUserId != null) {
      // Best-effort explicit offline write; non-critical if it fails.
      PresenceService.instance
          .onAppPaused(_currentUserId!)
          .catchError((e) => debugPrint('Presence dispose cleanup error: $e'));
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Presence decay only matters while someone can see the list.
    switch (state) {
      case AppLifecycleState.resumed:
        _startPresenceDecayTimer();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _presenceDecayTimer?.cancel();
        _presenceDecayTimer = null;
        break;
    }
    if (_currentUserId != null) {
      switch (state) {
        case AppLifecycleState.resumed:
          PresenceService.instance.onAppResumed(_currentUserId!);
          // Mark all messages as delivered when app comes to foreground
          _chatService.markAllMessagesAsDeliveredOnAppOpen(_currentUserId!);
          // Keep this device's FCM token fresh after reinstall, data clear,
          // Play Services recovery, or token rotation.
          unawaited(_fcmService.setupFCM(userId: _currentUserId!));
          break;
        case AppLifecycleState.paused:
        case AppLifecycleState.inactive:
        case AppLifecycleState.detached:
          PresenceService.instance.onAppPaused(_currentUserId!);
          // Force-flush Signal Protocol state to secure storage when the
          // app goes to background. The debounced flush (3000ms) may not
          // have fired yet, and without this the latest session ratchet
          // state (updated during message decrypt) would be lost if the
          // app is killed. Lost session state = "🔒 can't decrypt" on
          // the next incoming message from that peer.
          try {
            SignalService.instance.stores.flush();
          } catch (_) {}
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

      // ── Sync subscription userId for IAP ──
      Provider.of<SubscriptionProvider>(context, listen: false)
          .setUserId(_currentUserId!);

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

        // ── Check if user needs to choose a unique @username handle ─────
        // Push it ON TOP of HomeScreen (push, not pushReplacement) so that when
        // the user saves or skips and the screen pops, it returns HERE to Home.
        //
        // Why this matters: the root route (_AuthGate) was still rendering
        // LoginScreen at launch and is never removed after sign-in, so the auth
        // screen sits at the base of the stack beneath Home. pushReplacement
        // would drop Home and leave UsernameSetupScreen directly over that stale
        // LoginScreen — so its Navigator.pop() (canPop == true) would land the
        // user back on the auth screen. Keeping Home underneath fixes that and
        // matches how ProfileScreen already launches this same screen.
        if (_currentUser != null &&
            (_currentUser!.username == null ||
                _currentUser!.username!.trim().isEmpty) &&
            !UsernameSetupScreen.skippedThisSession &&
            mounted) {
          final updated = await Navigator.push<UserModel?>(
            context,
            MaterialPageRoute(
              builder: (_) => UsernameSetupScreen(user: _currentUser!),
            ),
          );
          if (!mounted) return;
          if (updated != null) {
            setState(() => _currentUser = updated);
          }
          return;
        }

        // ── Consume pending deep links from notification taps ──────────
        final pendingTab = NotificationService.consumePendingTabDeepLink();
        if (pendingTab != null && mounted) {
          _tabController.animateTo(pendingTab);
        }

        // Friend-request sent/accepted notification tap → open Contacts
        // directly on the Requests tab.
        final pendingContactsTab =
            NotificationService.consumePendingContactsTabDeepLink();
        if (pendingContactsTab != null && mounted && _currentUserId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ContactsScreen(
                currentUserId: _currentUserId!,
                currentUserName: _currentUser?.name,
                initialTabIndex: pendingContactsTab,
              ),
            ),
          );
        }

        // ── Profile deep link tapped before this user was signed in ──────
        // (e.g. cold start via a QR scan / shared link). Open it now that
        // we have an authenticated _currentUserId.
        final pendingUsername = DeepLinkService.consumePendingUsername();
        if (pendingUsername != null &&
            pendingUsername.isNotEmpty &&
            mounted &&
            _currentUserId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PublicProfileScreen(
                username: pendingUsername,
                currentUserId: _currentUserId!,
                currentUserName: _currentUser?.name,
              ),
            ),
          );
        }

        final pendingChatContactId =
            NotificationService.consumePendingChatDeepLink();
        if (pendingChatContactId != null &&
            pendingChatContactId.isNotEmpty &&
            mounted) {
          try {
            final user = await _userService.getUserById(pendingChatContactId);
            if (user != null && mounted) {
              final contact = Contact(
                id: user.id,
                name: user.name,
                lastMessage: '',
                time: '',
                avatarUrl: user.photoUrl ??
                    'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}&background=6C5CE7&color=fff&size=128',
                isOnline: user.isOnline,
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    contact: contact,
                    currentUserId: _currentUserId!,
                    currentUserName: _currentUser?.name,
                  ),
                ),
              );
            }
          } catch (e) {
            debugPrint('[DeepLink] failed to open chat: $e');
          }
        }

        // ── First-run coaching — must be last ──────────────────────────
        // Everything above can push a route or open a blocking dialog, and a
        // spotlight over a screen the user has already left is worse than no
        // spotlight. Deferring keeps the ordering rule in one place instead of
        // threading a "did anything navigate?" flag through every branch above.
        await _maybeShowFeatureCoaching();

        // ── Review nudge — after coaching, for the same reason ─────────
        // Covers users who never make calls (the call screen has its own
        // trigger). Play's sheet is a system overlay rather than a Flutter
        // dialog, so it cannot stack with What's New or a badge unlock — but
        // arriving after coaching means it lands on a settled screen instead of
        // over a tooltip. Silently no-ops on every launch except the rare one
        // where a forty-day window has reopened; see ReviewPromptService.
        unawaited(ReviewPromptService.instance.maybeRequest(
          trigger: 'sustained_use',
          accountCreatedAt: _currentUser?.createdAt,
        ));
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

      // ── Pre-warm Signal sessions + Cloud Function cold start ──
      // The first send to a peer historically paid for: (a) a Firebase
      // Functions cold-start to consume a one-time prekey (~3-8s), and
      // (b) building a Signal session from the prekey bundle. Doing both
      // here at app open makes the first send feel as instant as the
      // tenth. Fire-and-forget; never blocks the UI.
      // ignore: discarded_futures
      _prewarmEncryption(_currentUserId!);

      // ── Listen to user document in real-time to detect badge unlocks ──
      _currentUserSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .snapshots()
          .listen((snap) {
        if (snap.exists && mounted) {
          final user = UserModel.fromFirestore(snap);
          if (_previousBadges != null) {
            final newBadges = user.badges
                .where((b) => !_previousBadges!.contains(b))
                .toList();
            if (newBadges.isNotEmpty) {
              for (final badgeId in newBadges) {
                final navContext = navigatorKey.currentContext;
                if (navContext != null) {
                  _showBadgeUnlockDialog(navContext, badgeId);
                }
              }
            }
          }
          _previousBadges = user.badges;
        }
      });

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

  /// Pre-warms the Cloud Function and pre-establishes Signal sessions for
  /// every contact this user has a chat with, so the first message of the
  /// session is a pure local encrypt with no network round-trips.
  Future<void> _prewarmEncryption(String userId) async {
    // Delay slightly to let initial UI rendering and Firestore connection settle
    await Future.delayed(const Duration(seconds: 3));
    // Warm the Functions cold-start in parallel with the peer query.
    final warmFn = SignalService.warmConsumeOneTimePreKey();
    List<String> peerUids = const [];
    try {
      final snap = await FirebaseFirestore.instance
          .collection('chatRooms')
          .where('participants', arrayContains: userId)
          .get();
      // Sort chat rooms in memory by lastMessageTime descending
      final docs = snap.docs.toList()
        ..sort((a, b) {
          final aTime = (a.data()['lastMessageTime'] as Timestamp?)?.toDate() ??
              DateTime(0);
          final bTime = (b.data()['lastMessageTime'] as Timestamp?)?.toDate() ??
              DateTime(0);
          return bTime.compareTo(aTime);
        });

      final peers = <String>{};
      // Only prewarm the top 5 most recent chats to prevent startup saturation
      for (final d in docs.take(5)) {
        final parts = List<String>.from(d.data()['participants'] ?? const []);
        for (final p in parts) {
          if (p != userId) peers.add(p);
        }
      }
      peerUids = peers.toList();
    } catch (e) {
      debugPrint('[Prewarm] peer fetch failed: $e');
    }
    try {
      await SignalService.instance.prewarmSessions([userId, ...peerUids]);
    } catch (e) {
      debugPrint('[Prewarm] session prewarm failed: $e');
    }
    await warmFn;
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

  /// Shows the one-time spotlight tips for Home's least discoverable entry
  /// points (offline mesh chat, Gup Arcade).
  ///
  /// Bails out unless Home is the visible route: the caller runs this at the
  /// end of a startup chain that may have pushed a chat, profile, or username
  /// screen, and [showCoachMarks] measures its targets from live render boxes.
  /// Skipped marks keep their unseen flag, so they simply arrive on a later
  /// launch instead of being spent on an off-screen widget.
  Future<void> _maybeShowFeatureCoaching() async {
    // Let the freshly-drawn Home settle first — a spotlight in the same frame
    // as the first paint reads as a glitch rather than a tip.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;

    await showCoachMarks(context, [
      CoachMark(
        prefKey: kCoachMeshKey,
        targetKey: _meshIconKey,
        icon: Icons.sensors_rounded,
        title: 'Chat with no internet',
        body: 'Tap here to find people nearby over Bluetooth and Wi-Fi — '
            'works with no signal, no data, no Wi-Fi network.',
      ),
      CoachMark(
        prefKey: kCoachArcadeKey,
        targetKey: _arcadeChipKey,
        icon: Icons.bolt_rounded,
        title: 'These points are tappable',
        body: 'Your Gup Points open the Arcade, where streaks with friends '
            'and daily challenges live.',
      ),
    ]);
  }

  /// Bootstraps the E2EE vault key.
  ///
  /// • Auto-unlocks from the cached key in secure storage when possible
  ///   (warm path on every cold start after the first).
  /// • If the user has a vault config in Firestore but no local key
  ///   (reinstall, or first run after this feature shipped on an
  ///   already-onboarded account) → show the unlock dialog. Declining it with
  ///   "Restore later" is supported and non-destructive, but leaves history
  ///   unreadable, so it raises [_vaultLockedWithHistory] to put a standing
  ///   [VaultLockedBanner] on the chats tab — otherwise the state is
  ///   indistinguishable from lost messages and has no visible way back.
  /// • If no vault config exists yet → show the setup dialog so the user picks
  ///   a PIN before any vault writes happen. Until they finish, vault writes
  ///   silently skip — we never leak plaintext to Firestore.
  /// • After the vault is ready, drop in-memory pre-warm caches so the
  ///   next chat / status open re-reads the vault, and kick off a
  ///   background backfill of any local messages that aren't in the
  ///   vault yet (e.g. messages sent while the vault was still locked).
  ///   See [_afterVaultUnlocked].
  /// • Finally, check PIN custody — see [_ensurePinCustody].
  Future<void> _ensureVaultReady(String uid) async {
    final state = await VaultCipher.instance.bootstrap(uid);
    if (state == VaultState.ready) {
      _migrateAndBackfillInBackground(uid);
      SyncService.instance.init(uid, force: true);
      await _ensurePinCustody(uid);
      return;
    }
    if (!mounted) return;
    final isSetup = state == VaultState.needsSetup;

    final ok = await VaultPinDialog.show(
      context: context,
      uid: uid,
      mode: isSetup ? VaultPinMode.setup : VaultPinMode.unlock,
      // Populated by the bootstrap above from the config doc it already read,
      // so the right keyboard opens without a second round-trip.
      numericPinHint: VaultCipher.instance.pinIsNumericHint,
    );
    if (!ok) {
      // Declining unlock (not setup) means the vault holds history this
      // install cannot read. Raise the banner so there is a visible way back —
      // without it this state looks identical to "my messages are gone".
      if (!isSetup && mounted) {
        setState(() => _vaultLockedWithHistory = true);
      }
      return;
    }
    await _afterVaultUnlocked(uid);
  }

  /// Everything that must follow a successful unlock, shared by
  /// [_ensureVaultReady] and [_unlockVaultFromBanner] so a PIN entered from
  /// either place repairs exactly the same amount.
  Future<void> _afterVaultUnlocked(String uid) async {
    ChatService.invalidatePreWarm(uid);
    StatusService.invalidatePreWarm(uid);
    SyncService.instance.init(uid, force: true);
    _migrateAndBackfillInBackground(uid, full: true);
    await _ensurePinCustody(uid);
  }

  /// Re-opens the unlock prompt from the chats-tab banner.
  ///
  /// The banner clears on success only. A failed or dismissed attempt leaves
  /// it standing, which is the point: the route back must not be spendable.
  Future<void> _unlockVaultFromBanner() async {
    final uid = _currentUserId;
    if (uid == null) return;
    final ok = await VaultPinDialog.show(
      context: context,
      uid: uid,
      mode: VaultPinMode.unlock,
      numericPinHint: VaultCipher.instance.pinIsNumericHint,
    );
    if (!ok || !mounted) return;
    setState(() => _vaultLockedWithHistory = false);
    await _afterVaultUnlocked(uid);
  }

  /// One-time repair for vaults created by an older build's "Setup with
  /// Fingerprint" button, which generated a random PIN and never showed it to
  /// the user — leaving history that only this install can decrypt.
  ///
  /// Reached from both of [_ensureVaultReady]'s success paths, because either
  /// can land on an affected account: the warm path when the cached key is
  /// still present, and the post-dialog path when biometrics replayed the
  /// stored PIN (which is why that path does not count as proof of custody).
  ///
  /// Only [VaultPinCustody.rescueAvailable] prompts — see [classifyPinCustody]
  /// for why the other three states must stay silent. Best-effort throughout:
  /// if Firestore or secure storage is unreachable we skip the prompt and try
  /// again next launch rather than blocking the app behind a failed read.
  Future<void> _ensurePinCustody(String uid) async {
    try {
      final settings = await VaultCipher.instance.getSettings(uid);
      // Cheap short-circuit for the overwhelmingly common case: the flag is
      // already set, so skip the secure-storage read entirely.
      if (settings?.pinIsUserChosen ?? false) return;
      final storedPin =
          await biometricPinStorage.read(key: biometricPinKey(uid));
      final custody = classifyPinCustody(
        configExists: settings != null,
        pinIsUserChosen: settings?.pinIsUserChosen ?? false,
        hasStoredPin: storedPin != null && storedPin.isNotEmpty,
      );
      if (custody != VaultPinCustody.rescueAvailable) return;
      if (!mounted) return;
      await VaultPinCustodyDialog.show(
        context: context,
        uid: uid,
        storedPin: storedPin!,
        // From the settings read above — no extra round-trip.
        numericPinHint: settings?.pinIsNumeric ?? false,
      );
    } catch (_) {}
  }

  /// Background sweep that (a) re-encrypts any legacy plaintext vault docs
  /// produced by older app versions and (b) pushes anything in the local
  /// PlaintextStore that hasn't made it to the vault yet. Both passes are
  /// idempotent so a partial run on a previous launch heals on the next.
  void _migrateAndBackfillInBackground(String uid, {bool full = false}) {
    unawaited(() async {
      // Delay heavy sync operations to avoid network/CPU contention during cold start
      if (!full) {
        await Future.delayed(const Duration(seconds: 8));
      }
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
      _backfillVaultInBackground(uid, full: full);
    }());
  }

  /// Walks the local PlaintextStore and pushes any message not yet in
  /// the encrypted msgVault. Fire-and-forget — failures are non-fatal
  /// and retried opportunistically by future sends/receives.
  void _backfillVaultInBackground(String uid, {bool full = false}) {
    unawaited(() async {
      try {
        if (!VaultCipher.instance.isReady) return;
        final store = await PlaintextStore.instance();
        // Limit backfill check to the 20 most recent messages on regular startup,
        // or check all messages on manual PIN setup/unlock.
        final local =
            await store.getAllMessagePayloads(limit: full ? null : 20);
        if (local.isEmpty) return;
        final col = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('msgVault');

        final ids = local.keys.toList();
        final present = <String>{};

        // Chunk Firestore documentId queries (whereIn limit is 30 items)
        for (var i = 0; i < ids.length; i += 30) {
          final chunk =
              ids.sublist(i, (i + 30 < ids.length) ? i + 30 : ids.length);
          final snap =
              await col.where(FieldPath.documentId, whereIn: chunk).get();
          present.addAll(snap.docs.map((d) => d.id));
        }

        final missing =
            local.entries.where((e) => !present.contains(e.key)).toList();

        for (final entry in missing) {
          final enc = await VaultCipher.instance.encryptPayload(entry.value);
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
        MaterialPageRoute(builder: (_) => const LoginScreen()),
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

  /// Empty Gup tab for a user who still has setup steps left — the checklist
  /// plus the same "New chat" call to action the plain state offers.
  Widget _buildStarterState({required bool hasPhoto}) {
    final c = AppThemeColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Text(
                'Welcome to GupShupGo',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: c.textHigh,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Three quick things and you are set up.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: c.textMid),
              ),
            ],
          ),
        ),
        StarterChecklistCard(
          hasPhoto: hasPhoto,
          onAddPhoto: () async {
            if (_currentUser == null) return;
            final updated = await Navigator.push<UserModel>(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(currentUser: _currentUser!),
              ),
            );
            // Refreshes the chat tab too, so the photo step ticks itself.
            if (updated != null && mounted) {
              setState(() => _currentUser = updated);
            }
          },
          onFindPeople: () async {
            if (_currentUserId == null) return;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ContactsScreen(
                  currentUserId: _currentUserId!,
                  currentUserName: _currentUser?.name,
                ),
              ),
            );
          },
          onTryOffline: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NearbyPeersScreen()),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: Center(
            child: ElevatedButton.icon(
              onPressed: () {
                if (_currentUserId == null) return;
                markStarterContactsVisited();
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
          ),
        ),
      ],
    );
  }

  /// Empty Gup tab once the starter steps are all done — the original state,
  /// for users who have set themselves up but have no conversations open.
  Widget _buildPlainEmptyState() {
    final c = AppThemeColors.of(context);

    return SizedBox(
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
                  if (_currentUserId == null) return;
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
    );
  }

  /// Prepends [VaultLockedBanner] to [content] while the vault holds history
  /// this install cannot read.
  ///
  /// Wrapped around the whole chats tab rather than around its individual
  /// return paths, so the banner also covers the loading and empty states — a
  /// reinstall that declined the PIN can land on any of them, and one wrap
  /// point means it can never render twice.
  ///
  /// Both conditions are required. The flag records that the user declined;
  /// [VaultCipher.isReady] is the live truth. Checking the latter too means an
  /// unlock performed anywhere else — vault settings, the custody dialog —
  /// retires the banner on the next rebuild instead of leaving it claiming a
  /// lock that no longer exists.
  Widget _withVaultBanner(Widget content) {
    if (!_vaultLockedWithHistory || VaultCipher.instance.isReady) {
      return content;
    }
    return Column(
      children: [
        VaultLockedBanner(onUnlock: _unlockVaultFromBanner),
        Expanded(child: content),
      ],
    );
  }

  Widget _buildChatsTab() {
    if (_currentUserId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    _chatRoomsStream ??=
        _chatService.getChatRooms(_currentUserId!).asBroadcastStream();
    return StreamBuilder<List<ChatRoom>>(
      stream: _chatRoomsStream,
      builder: (context, chatSnapshot) {
        // ── Use cached data while Firestore stream is still connecting ──
        List<ChatRoom> chatRooms;
        if (chatSnapshot.connectionState == ConnectionState.waiting &&
            !chatSnapshot.hasData) {
          chatRooms = _chatCacheService.getCachedChatRooms();
          if (chatRooms.isEmpty) {
            // No cache yet — show a brief loading indicator
            return const Center(child: CircularProgressIndicator());
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
            // ── Pre-cache profile images for smoother scrolling ─────
            // Warms the Flutter image cache with contact avatars so they
            // render instantly when the user scrolls through the chat list
            // — no loading flicker, no layout shift.
            _precacheChatAvatars(chatRooms, context);
          }
        }

        // Prime + watch the bonds for whatever set we are about to render.
        // Only ever schedules an async setState (stream events), never one
        // during this build.
        _syncStreakWatch(chatRooms);

        if (chatRooms.isEmpty) {
          // A user with nothing to show is the one moment we can teach without
          // interrupting anything. The checklist retires itself once every step
          // is done, falling back to the plain empty state.
          final hasPhoto = (_currentUser?.photoUrl ?? '').isNotEmpty;
          final showChecklist =
              !StarterChecklistCard.isComplete(hasPhoto: hasPhoto);

          return RefreshIndicator(
            onRefresh: () => _manualRefresh(chatRooms),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: showChecklist
                  ? _buildStarterState(hasPhoto: hasPhoto)
                  : _buildPlainEmptyState(),
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

              if (otherUserId.isEmpty) return const SizedBox.shrink();

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

  /// Warms the Flutter image cache with contact avatars so profile pictures
  /// render instantly when scrolling through the chat list.
  void _precacheChatAvatars(List<ChatRoom> chatRooms, BuildContext context) {
    final userIds = <String>{};
    for (final room in chatRooms) {
      for (final id in room.participants) {
        if (id != _currentUserId) userIds.add(id);
      }
    }
    for (final uid in userIds) {
      final cached = _chatCacheService.getCachedUser(uid);
      if (cached?.photoUrl != null && cached!.photoUrl!.isNotEmpty) {
        unawaited(precacheImage(
          NetworkImage(cached.photoUrl!),
          context,
          onError: (_, __) {}, // Silently ignore broken URLs
        ));
      }
    }
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

  /// Feeds the room list into [StreakRepository] and keeps one `watchMany`
  /// subscription open for exactly the rooms currently on screen.
  ///
  /// [primeRoom] hands over the room document we already have, so the legacy
  /// dual-read fallback and the participant list cost no extra Firestore read;
  /// [primeCachedState] hands over the state the disk cache rehydrated, so the
  /// first frame after a cold start shows a count instead of a blank.
  void _syncStreakWatch(List<ChatRoom> chatRooms) {
    final repo = StreakRepository.instance;
    for (final room in chatRooms) {
      if (room.id.isEmpty) continue;
      repo.primeRoom(room.id, room.toMap());
      final cached = room.streakState;
      if (cached != null) repo.primeCachedState(room.id, cached);
    }

    final ids = <String>[
      for (final room in chatRooms)
        if (room.id.isNotEmpty) room.id,
    ];
    if (listEquals(ids, _watchedStreakRoomIds)) return;
    _watchedStreakRoomIds = ids;
    _streakViewsSub?.cancel();
    if (ids.isEmpty) {
      _streakViews = const <String, StreakView>{};
      return;
    }
    _streakViewsSub = repo.watchMany(ids).listen((views) {
      if (!mounted) return;
      setState(() => _streakViews = views);
    });
  }

  /// The derived view for a room: the live one, else the last one the
  /// repository derived (so a scroll or a rebuild never blanks a badge).
  StreakView? _streakViewFor(String roomId) =>
      _streakViews[roomId] ?? StreakRepository.instance.latest(roomId);

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
    final streakView = _streakViewFor(chatRoom.id);
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
                        child: Row(
                          children: [
                            Flexible(
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
                            if (streakView != null && streakView.count > 0) ...[
                              const SizedBox(width: 6),
                              StreakBadge(view: streakView, compact: true),
                            ] else if (streakView != null &&
                                streakView.isRestorable) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.red.withOpacity(0.25),
                                      width: 0.5),
                                ),
                                child: const Text('💔',
                                    style: TextStyle(fontSize: 10)),
                              ),
                            ],
                          ],
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
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
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
      return const Center(child: CircularProgressIndicator());
    }

    return Consumer<StatusProvider>(
      builder: (context, statusProvider, child) {
        final c = AppThemeColors.of(context);
        final myStatus = statusProvider.myStatus;
        final otherStatuses = statusProvider.otherStatuses;
        final hasMyStatus = statusProvider.hasMyStatus;

        return ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          children: [
            // "My Status" Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'My Moment',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.textHigh,
                  letterSpacing: -0.2,
                ),
              ),
            ),

            // My Status Tile
            _buildMyStatusTile(myStatus, hasMyStatus),

            const SizedBox(height: 12),

            // "Recent Updates" Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'Recent Moments',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.textHigh,
                  letterSpacing: -0.2,
                ),
              ),
            ),

            // Other users' statuses
            if (otherStatuses.isNotEmpty)
              ...otherStatuses.map((status) => _buildStatusTile(status)),

            // Empty state (Stitch Tactical Moments style)
            if (otherStatuses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: c.surfaceAlt,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: c.border,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.camera_alt_outlined,
                          size: 44,
                          color: c.textMid,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No updates yet.',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: c.textHigh,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap the camera to share.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: c.textMid,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: hasMyStatus ? c.primary : c.border,
                width: 2.5,
              ),
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundImage: NetworkImage(avatarUrl),
              backgroundColor: c.primaryLt,
            ),
          ),
          if (!hasMyStatus)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: c.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.surface, width: 2),
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 12),
              ),
            ),
        ],
      ),
      title: Text(
        _currentUser?.name ?? 'My Status',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: c.textHigh,
        ),
      ),
      subtitle: Text(
        hasMyStatus
            ? '${myStatus!.activeStatusItems.length} update${myStatus.activeStatusItems.length > 1 ? "s" : ""} · Tap to view'
            : 'Tap to add an update',
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
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: allViewed ? c.textLow.withOpacity(0.4) : c.primary,
                width: 2.5,
              ),
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundImage: NetworkImage(avatarUrl),
              backgroundColor: c.primaryLt,
            ),
          ),
          title: Row(
            children: [
              Text(
                status.userName,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: c.textHigh,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '•  ${_formatStatusTime(status.lastUpdated)}',
                style: GoogleFonts.poppins(
                  color: c.textMid,
                  fontSize: 13,
                ),
              ),
            ],
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
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
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
    // Media statuses (photo/video) are a Pro feature
    if (!PremiumGate.checkAndPrompt(
      context,
      featureName: 'Media Moments',
      featureIcon: Icons.camera_alt_rounded,
      description:
          'Share photos and videos as status updates with GupShupGo Pro. '
          'Free users can still post text moments.',
    )) {
      return;
    }

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
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<CallLogModel>>(
      stream: _callLogService.getCallLogs(_currentUserId!),
      builder: (context, snapshot) {
        final c = AppThemeColors.of(context);
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
            const SizedBox(width: 6),
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
            key: _meshIconKey,
            icon: const Icon(Icons.sensors_rounded),
            tooltip: 'Offline Chat — talk to people nearby',
            onPressed: () {
              markStarterMeshVisited();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NearbyPeersScreen()),
              );
            },
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
            icon: (_currentUser?.photoUrl?.isNotEmpty ?? false)
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
              } else if (value == 'review') {
                // openStoreListing, not the review sheet: Play's sheet is
                // quota-limited and may show nothing at all, which is the wrong
                // thing to hang a tap on.
                unawaited(ReviewPromptService.instance
                    .openStoreListing(context: context));
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
                  value: 'review',
                  child: Row(
                    children: [
                      Icon(Icons.star_rate_rounded, color: c.warning, size: 20),
                      const SizedBox(width: 12),
                      const Text('Leave a review'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: c.error, size: 20),
                      const SizedBox(width: 12),
                      Text('Log out', style: TextStyle(color: c.error)),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_hasFirebaseSession) _buildReverifyBanner(),
          // ── Anonymous Match Banner — only on Gup tab ──────────────
          if (_tabController.index == 0 && _currentUserId != null)
            _AnonymousMatchBanner(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AnonymousLobbyScreen(
                      currentUserId: _currentUserId!,
                      currentUserName: _currentUser?.name,
                    ),
                  ),
                );
              },
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _withVaultBanner(_buildChatsTab()),
                _buildStatusTab(),
                _buildCallsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavDock(),
      floatingActionButton: _buildFABRow(),
    );
  }

  /// Custom bottom navigation dock matching the ultra-sleek obsidian aesthetic.
  Widget _buildBottomNavDock() {
    final c = AppThemeColors.of(context);
    final selectedIndex = _tabController.index;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(
          top: BorderSide(color: c.border, width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                label: 'Gup',
                icon: Icons.chat_bubble_rounded,
                selectedIcon: Icons.chat_bubble_rounded,
                isSelected: selectedIndex == 0,
                onTap: () => setState(() => _tabController.animateTo(0)),
              ),
              _buildNavItem(
                index: 1,
                label: 'Moments',
                icon: Icons.camera_alt_outlined,
                selectedIcon: Icons.camera_alt_rounded,
                isSelected: selectedIndex == 1,
                onTap: () => setState(() => _tabController.animateTo(1)),
              ),
              _buildNavItem(
                index: 2,
                label: 'Calls',
                icon: Icons.call_outlined,
                selectedIcon: Icons.call_rounded,
                isSelected: selectedIndex == 2,
                onTap: () => setState(() => _tabController.animateTo(2)),
              ),
              // Profile Tab (Avatar on far right)
              GestureDetector(
                onTap: () async {
                  if (_currentUser != null) {
                    final updated = await Navigator.push<UserModel>(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ProfileScreen(currentUser: _currentUser!)),
                    );
                    if (updated != null) setState(() => _currentUser = updated);
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: c.border,
                          width: 1.5,
                        ),
                      ),
                      child: Builder(
                        builder: (_) {
                          final hasPhoto =
                              _currentUser?.photoUrl?.isNotEmpty ?? false;
                          return CircleAvatar(
                            radius: 13,
                            backgroundImage: hasPhoto
                                ? NetworkImage(_currentUser!.photoUrl!)
                                : null,
                            backgroundColor: c.primaryLt,
                            child: hasPhoto
                                ? null
                                : Icon(Icons.person,
                                    size: 14, color: c.textMid),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: c.textMid,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData selectedIcon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final c = AppThemeColors.of(context);
    final color = isSelected ? c.primary : c.textMid;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFABRow() {
    final c = AppThemeColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ── Gup Arcade mini-FAB (bottom-left) ──────────────────────
        if (_currentUserId != null)
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_currentUserId)
                  .snapshots(),
              builder: (context, snap) {
                int pts = _currentUser?.gupPoints ?? 0;
                if (snap.hasData && snap.data!.exists) {
                  final data = snap.data!.data() as Map<String, dynamic>?;
                  pts = data?['gupPoints'] as int? ?? 0;
                }
                return GestureDetector(
                  key: _arcadeChipKey,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GupArcadeScreen(
                        currentUserId: _currentUserId!,
                      ),
                    ),
                  ),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: c.isDark ? const Color(0xFF2A2040) : c.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: c.primary.withOpacity(0.25),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: c.primary.withOpacity(0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⚡', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 3),
                        Text(
                          '$pts',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: c.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        else
          const SizedBox.shrink(),

        // ── Original FAB (bottom-right) ────────────────────────────
        _buildFAB(),
      ],
    );
  }

  Widget _buildFAB() {
    final c = AppThemeColors.of(context);
    return AnimatedBuilder2(
      animation: _tabController.animation!,
      builder: (context, child) {
        final index = _tabController.index;
        if (index == 1) {
          // Moments tab - show add moment FABs
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
                child: const Icon(Icons.camera_alt, color: Colors.white),
              ),
            ],
          );
        }
        // Gup & Calls tabs - show message FAB
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

  void _showBadgeUnlockDialog(BuildContext context, String badgeId) {
    final badge = BadgeDefinition.fromId(badgeId);
    final title = badge?.title ?? 'New Achievement';
    final icon = badge?.icon ?? '🎉';
    final colors = badge?.gradientColors ?? [Colors.blue, Colors.purple];
    final desc = badge?.description ?? 'You unlocked a new badge!';

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (BuildContext context) {
        final c = AppThemeColors.of(context);
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: c.surface.withOpacity(0.95),
              borderRadius: BorderRadius.circular(28),
              border:
                  Border.all(color: Colors.yellow.withOpacity(0.4), width: 2),
              boxShadow: [
                BoxShadow(
                  color: colors[0].withOpacity(0.35),
                  blurRadius: 25,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CONGRATULATIONS!',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.amber,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Badge Unlocked!',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: c.textHigh,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.5), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: colors[0].withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        icon,
                        style: const TextStyle(fontSize: 54),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: c.textHigh,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    desc,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: c.textMid,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: c.border),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Awesome',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: c.textHigh,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GupArcadeScreen(
                                  currentUserId: _currentUserId!,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 2,
                          ),
                          child: Text(
                            'View Arcade',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ─── Full-width Anonymous Match Banner with animated gradient shimmer ───────
class _AnonymousMatchBanner extends StatefulWidget {
  final VoidCallback onTap;

  const _AnonymousMatchBanner({required this.onTap});

  @override
  State<_AnonymousMatchBanner> createState() => _AnonymousMatchBannerState();
}

class _AnonymousMatchBannerState extends State<_AnonymousMatchBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return AnimatedBuilder2(
      animation: _shimmerController,
      builder: (context, child) {
        final v = _shimmerController.value;
        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 6, 14, 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: c.isDark
                    ? const [
                        Color(0xFF2A1F4E),
                        Color(0xFF3D2068),
                        Color(0xFF4A1A6B),
                        Color(0xFF3D2068),
                        Color(0xFF2A1F4E),
                      ]
                    : const [
                        Color(0xFF6C5CE7),
                        Color(0xFF845EC2),
                        Color(0xFFD65DB1),
                        Color(0xFF845EC2),
                        Color(0xFF6C5CE7),
                      ],
                begin: Alignment(-1.5 + v * 3.0, 0),
                end: Alignment(1.5 + v * 3.0, 0),
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (c.isDark
                          ? const Color(0xFF7C5CFC)
                          : const Color(0xFF6C5CE7))
                      .withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // ── Icon circle ──
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shuffle_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // ── Text ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connect with a Stranger',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Anonymous chat — tap to match!',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Arrow ──
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
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
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

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
