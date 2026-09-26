import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/provider/call_state_provider.dart';
import 'package:video_chat_app/provider/connectivity_provider.dart';
import 'package:video_chat_app/screens/call_screen.dart';
import 'package:video_chat_app/screens/connecting_call_screen.dart';
import 'package:video_chat_app/screens/screen_share_screen.dart';
import 'package:video_chat_app/services/screen_share_session.dart';
import 'package:video_chat_app/screens/status_viewer_screen.dart';
import 'package:video_chat_app/services/chat_service.dart';
import 'package:video_chat_app/services/call_signaling_service.dart';
import 'package:video_chat_app/services/chat_export_service.dart';
import 'package:video_chat_app/services/crypto/safety_number_service.dart';
import 'package:video_chat_app/services/crypto/encrypted_media_service.dart';
import 'package:video_chat_app/services/crypto/plaintext_store.dart';
import 'package:video_chat_app/services/crypto/signal_service.dart';
import 'package:video_chat_app/services/crypto/vault_cipher.dart';
import 'package:video_chat_app/services/fcm_service.dart';
import 'package:video_chat_app/services/image_compressor.dart';
import 'package:video_chat_app/services/link_preview_service.dart';
import 'package:video_chat_app/services/mesh_network_service.dart';
import 'package:video_chat_app/services/settings_service.dart';
import 'package:video_chat_app/services/status_service.dart';
import 'package:video_chat_app/services/streak/streak_repository.dart';
import 'package:video_chat_app/services/streak/streak_state.dart';
import 'package:video_chat_app/services/user_service.dart';
import 'package:video_chat_app/services/voice_recorder_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/theme/chat_pattern_painter.dart';
import 'package:video_chat_app/theme/chat_theme.dart';
import 'package:video_chat_app/provider/chat_theme_provider.dart';
import 'package:video_chat_app/widgets/chat_theme_sheet.dart';
import 'package:video_chat_app/utils/link_extractor.dart';
import 'package:video_chat_app/widgets/ads/native_ad_card.dart';
import 'package:video_chat_app/widgets/e2ee_banner.dart';
import 'package:video_chat_app/widgets/document_bubble.dart';
import 'package:video_chat_app/widgets/location_bubble.dart';
import 'package:video_chat_app/widgets/location_share_sheet.dart';
import 'package:video_chat_app/widgets/export_format_sheet.dart';
import 'package:video_chat_app/widgets/link_preview_card.dart';
import 'package:video_chat_app/widgets/linkified_text.dart';
import 'package:video_chat_app/widgets/new_feature_badge.dart';
import 'package:video_chat_app/widgets/reply_quote_card.dart';
import 'package:video_chat_app/widgets/streak_restore_dialog.dart';
import 'package:video_chat_app/widgets/streak_badge.dart';
import 'package:video_chat_app/widgets/swipe_to_reply.dart';
import 'package:video_chat_app/widgets/voice_message_bubble.dart';
import 'package:video_chat_app/widgets/video_message_widgets.dart';
import 'package:video_chat_app/widgets/view_once_bubble.dart';
import 'package:video_chat_app/services/notification_service.dart';
import 'package:video_chat_app/provider/subscription_provider.dart';
import 'package:video_chat_app/widgets/premium_gate.dart';
import 'package:video_chat_app/utils/avatar_image.dart';
import 'package:video_chat_app/utils/haptics.dart';
import 'package:video_chat_app/utils/upload_progress.dart';
import 'package:video_chat_app/widgets/common/async_button.dart';
import 'package:video_chat_app/widgets/common/loading_overlay.dart';

class Contact {
  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final String avatarUrl;
  final bool isOnline;

  Contact({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.avatarUrl,
    this.isOnline = false,
  });
}

class ChatScreen extends StatefulWidget {
  final Contact contact;
  final String currentUserId;
  final String? currentUserName;

  const ChatScreen({super.key, 
    required this.contact,
    required this.currentUserId,
    this.currentUserName,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

/// How much history a conversation needs before it carries a native ad card.
///
/// The card is only acceptable in a chat because it lands in *scrollback* — old
/// messages the user has already read. In a short thread there is no scrollback
/// to land in, so there is no card.
const int _kChatAdMinMessages = 25;

/// How many messages sit between the card and the newest message.
///
/// The chat list is `reverse: true`, so the newest message is at the bottom next
/// to the composer and the send button. This gap is what keeps the card out of
/// reach of a mis-tap while typing.
const int _kChatAdGapFromComposer = 8;

/// Largest chat video accepted client-side.
///
/// Chat video is picked with `image_picker` and uploaded raw — there is no
/// video compressor anywhere in this app — so this is the real ceiling, not a
/// plan limit. `storage.rules` (`chat_videos/`) sits above it at 100 MB as pure
/// headroom. The number matches status video, which caps the same raw capture
/// the same way. Unlike a status, a chat video has no *duration* cap: it isn't
/// ephemeral, so the only bound that matters is bytes — upload time and storage.
const int _kMaxChatVideoBytes = 64 * 1024 * 1024;

/// Human-readable MB for the "video too large" notice. One decimal below 10 MB,
/// whole numbers above, so the message reads naturally at both ends.
String _formatMb(int bytes) =>
    '${(bytes / (1024 * 1024)).toStringAsFixed(bytes < 10 * 1024 * 1024 ? 1 : 0)} MB';

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final StatusService _statusService = StatusService();
  final UserService _userService = UserService();

  bool _isLoading = true;
  final bool _isSending = false;
  int _lastMessageCount = 0;

  // ─── Search state ─────────────────────────────────────────────────
  bool _isSearchMode = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  /// FTS5 hits for [_searchQuery], newest first, or null while the first
  /// query for the current text is still running.
  ///
  /// Search used to be `messages.where((m) => m.text.contains(q))` over
  /// whatever the list had paged in, which quietly answered "no results" for
  /// anything older than the scroll window. It now goes through
  /// `PlaintextStore.searchMessages`, which indexes the whole local history —
  /// so the results are no longer a subset of what's on screen and have to be
  /// held separately rather than filtered out of the stream.
  List<MessageModel>? _searchResults;

  /// Debounce for the box. 250 ms is long enough that a normal typing cadence
  /// issues one query per word rather than one per keystroke, and short enough
  /// that results feel like they arrive as you type.
  Timer? _searchDebounce;

  /// Guards against an out-of-order reply: a slow query for "inv" must not
  /// overwrite the results for "invoice" typed after it.
  int _searchSeq = 0;

  // ─── Mute state ───────────────────────────────────────────────────
  final SettingsService _settingsService = SettingsService();
  late bool _isMuted;

  // ─── Chat theme ───────────────────────────────────────────────────
  /// Deterministic room id, used to key this conversation's chat theme.
  late final String _chatRoomId;

  /// Chat theme in force, re-resolved at the top of every [build].
  ///
  /// Cached in a field rather than read from the tree because the bubble
  /// builders (`_buildMessage`, `_buildTypingBubble`, `_buildDateDivider`, …)
  /// are called from `State.context` rather than from a builder inside the
  /// message area.
  ChatTheme _chatTheme = ChatThemeCatalog.defaultTheme;

  /// Palette the message area is drawn against: always the app's own light/dark
  /// palette.
  ///
  /// It used to be the chat theme's, because a preset fixed one brightness and
  /// the message list was re-rooted on the matching [AppTheme]. Every preset now
  /// carries both a light and a dark face (see [ChatTheme]), so the theme follows
  /// the app instead of overriding it and this is a plain read. Kept as a named
  /// getter because that agreement is the thing worth stating once at the seven
  /// call sites that draw bubble content.
  AppThemeColors get _messageColors => AppThemeColors.of(context);

  // ─── Chat export ──────────────────────────────────────────────────
  /// True while an export is in flight. The overflow menu stays tappable for the
  /// whole read — the entire local history plus a Firestore round-trip — so
  /// without this a double tap runs two exports and opens two share sheets.
  bool _isExporting = false;

  // ── Image picker ─────────────────────────────────────────────────
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingImage = false;

  /// Real upload completion (0.0–1.0) for the in-flight image, or null when no
  /// image is uploading. Drives the determinate ring at the paperclip. See the
  /// upload-progress convention in [_pickAndSendImage].
  double? _imageUploadProgress;
  StreamSubscription<double>? _imageUploadSub;

  // ── Video attachment ──────────────────────────────────────────────
  bool _isUploadingVideo = false;

  /// Real upload completion (0.0–1.0) for the in-flight video, or null when no
  /// video is uploading. Same paperclip-ring convention as [_pickAndSendImage];
  /// image and video never upload at once (both share the one attach button),
  /// so the composer reads whichever of the two is non-null.
  double? _videoUploadProgress;
  StreamSubscription<double>? _videoUploadSub;

  // ── Document attachment ───────────────────────────────────────────
  bool _isUploadingDocument = false;

  /// Real upload completion (0.0–1.0) for the in-flight document, or null.
  ///
  /// Stays null through the encrypt that precedes the upload — AES-GCM over a
  /// large file is a meaningful slice of the wall-clock but reports no
  /// progress, so the paperclip shows an indeterminate spinner until
  /// `EncryptedMediaService`'s first `onProgress` callback arrives. Unlike the
  /// image and video paths this is a plain field, not a stream subscription:
  /// the service owns the `UploadTask` and hands us a callback instead.
  double? _documentUploadProgress;

  // ── Voice recording ───────────────────────────────────────────────
  final VoiceRecorderService _voiceRecorder = VoiceRecorderService();
  bool _isSendingVoice = false;

  /// Real upload completion (0.0–1.0) for the in-flight voice note, or null.
  double? _voiceUploadProgress;
  StreamSubscription<double>? _voiceUploadSub;

  /// True from the moment the screen-share button is tapped until the Agora
  /// session is up (or the attempt fails). A real re-entry guard: the old
  /// `ScreenShareSession.instance.active` check doesn't engage during the
  /// Firestore-write + FCM + engine-init gap, so a second tap slipped through.
  bool _startingScreenShare = false;
  bool _hasText = false; // tracks if text field has content for mic/send toggle

  // ─── Block state ──────────────────────────────────────────────────
  bool _isBlocked = false; // current user blocked the contact
  bool _isBlockedByContact = false; // contact blocked the current user

  // ─── Cached user profile futures (avoids re-fetching on rebuild) ───
  final Map<String, Future<DocumentSnapshot>> _userProfileFutures = {};

  // ─── Online status state (real-time from Firestore) ───────────────
  late bool _isContactOnline;
  DateTime? _contactLastSeen;
  StreamSubscription? _onlineStatusSubscription;
  // Alternates subtitle between "Last seen" and bond badge when offline
  bool _showBondInSubtitle = false;
  Timer? _subtitleToggleTimer;

  // ─── Streaks state ──────────────────────────────────────────────────
  // Read-only, derived by StreakRepository (engine + ServerClock). The screen
  // owns no streak arithmetic of its own — not the deadline, not the
  // restore-window expiry (engine step 9 owns that).
  StreakView? _streakView;
  StreamSubscription<StreakView>? _streakSubscription;

  // ─── Typing indicator state ───────────────────────────────────────
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _isOtherUserTyping = false;
  StreamSubscription<bool>? _typingSubscription;

  // Tracks which message ids have already been rendered at least once so we
  // only run the slide-in animation on newly-inserted bubbles. Without this,
  // every message would animate on the first build of the chat screen.
  final Set<String> _seenMessageIds = <String>{};
  bool _didInitialMessageBuild = false;

  /// Id of the message the chat's single native ad card sits above, chosen once
  /// per chat open.
  ///
  /// Anchored to a message rather than to an offset from the end of the list: an
  /// offset would walk the card up through scrollback every time a message
  /// arrived, and each move would rebuild it into a fresh ad request. Null until
  /// the thread is long enough — see [_kChatAdMinMessages].
  String? _chatAdAnchorId;

  /// Load budget for that card, owned here rather than by the card.
  ///
  /// The message list is `reverse: true`, so a new message — or the typing bubble
  /// blinking on and off — shifts every index and rebuilds the card from scratch.
  /// Its own counter would reset each time; this one doesn't. See
  /// [NativeAdBudget].
  final NativeAdBudget _chatAdBudget = NativeAdBudget();

  // ─── Mesh messaging state ─────────────────────────────────────────
  StreamSubscription<MessageModel>? _meshMessageSubscription;
  final List<MessageModel> _meshMessages = [];
  late MeshNetworkService _meshService;

  // Cached messages stream. MUST NOT be re-created on every build — every
  // setState() (typing toggle, mic/send swap, optimistic outbox tick) would
  // otherwise spin up a fresh subscription whose initial frame is just the
  // outbox, causing the prior history to vanish for 2–3s until Firestore
  // re-emits and decryption completes. Initialized once in initState.
  late final Stream<List<MessageModel>> _messagesStream;
  bool _isLoadingOlder = false;
  bool _hasMoreOlder = true;
  List<MessageModel> _currentMessages = [];

  // ─── Reply state ──────────────────────────────────────────────────
  // The message the composer is currently answering, set by a swipe. Cleared
  // synchronously in _sendMessage, before any crypto runs.
  MessageModel? _replyTo;

  // ─── Edit state ───────────────────────────────────────────────────
  // The message the composer is currently rewriting. Mutually exclusive with
  // [_replyTo]: the composer can only mean one thing at a time, and a send
  // while this is non-null commits an edit instead of a new message.
  MessageModel? _editing;

  /// Focus for the composer field, so a swipe-to-reply can raise the keyboard.
  final FocusNode _composerFocus = FocusNode();

  // Per-message keys, so tapping a quote can scroll to the original. Populated
  // as bubbles build, so it only ever holds what is in the loaded window —
  // which is exactly the set we can scroll to.
  final Map<String, GlobalKey> _messageKeys = {};
  String? _highlightedMessageId;
  Timer? _highlightTimer;

  // ─── Link preview state ───────────────────────────────────────────
  // Resolved while the user types (debounced), never on send: attaching only
  // what is already cached keeps send latency at zero. A message whose preview
  // hasn't landed yet just goes without a card — its text is still linkified.
  Timer? _previewDebounce;
  String? _previewUrl;
  LinkPreview? _pendingPreview;

  /// Set when the user dismisses the composer card, so the debounce doesn't
  /// helpfully put it straight back.
  bool _linkPreviewSuppressed = false;

  @override
  void initState() {
    super.initState();
    _isContactOnline = widget.contact.isOnline; // seed from passed-in value
    final chatRoomId =
        _chatService.getChatRoomId(widget.currentUserId, widget.contact.id);
    _chatRoomId = chatRoomId;
    _isMuted = _settingsService.isChatMuted(chatRoomId);
    _messagesStream = _chatService
        .getMessages(widget.currentUserId, widget.contact.id)
        .asBroadcastStream();
    // Suppress global mesh banners for this conversation while it's open.
    _meshService = Provider.of<MeshNetworkService>(context, listen: false);
    _meshService.setActiveConversation(widget.contact.id);
    // Suppress foreground chat notifications for this conversation.
    NotificationService.activeChatRoomId = chatRoomId;
    _initializeChat();
    _messageController.addListener(_onTextChanged);

    // Bond badge: one derived view per room, re-derived every minute by the
    // repository so the countdown ticks and a lapse shows up without a write.
    _streakSubscription =
        StreakRepository.instance.watch(chatRoomId).listen((view) {
      if (!mounted) return;
      if (view == _streakView) return;
      final hadBadge = _hasBondBadge;
      setState(() => _streakView = view);
      if (hadBadge != _hasBondBadge) {
        // Re-evaluate alternating timer now that bond state changed
        _updateSubtitleTimer(_isContactOnline);
      }
    });

    // Pre-establish the Signal session for this peer in the background
    // the moment the chat screen opens. By the time the user finishes
    // typing their first message, the session is already built, and the
    // send path becomes a pure local CPU encrypt — no Firestore prekey
    // fetch, no consumeOneTimePreKey HTTP round-trip. This is what
    // collapses the "first message to a new contact takes 15+ seconds"
    // into 1-2 seconds.
    //
    // We also trigger a non-blocking device-list refresh so that if the
    // peer reinstalled (new deviceId), we detect the change immediately
    // and clean up stale sessions instead of waiting for the 5-min
    // stale-while-revalidate window.
    SignalService.refreshDeviceCache(widget.contact.id);
    // ignore: discarded_futures
    SignalService.instance
        .prewarmSessions([widget.currentUserId, widget.contact.id]);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _stopTyping();
    _scrollController.removeListener(_onScroll);
    _onlineStatusSubscription?.cancel();
    _typingSubscription?.cancel();
    _meshMessageSubscription?.cancel();
    _imageUploadSub?.cancel();
    _videoUploadSub?.cancel();
    _voiceUploadSub?.cancel();
    _messageController.removeListener(_onTextChanged);
    _typingTimer?.cancel();
    _previewDebounce?.cancel();
    _highlightTimer?.cancel();
    _voiceRecorder.dispose();
    _scrollController.dispose();
    _messageController.dispose();
    _composerFocus.dispose();
    _searchController.dispose();
    _searchQuery = '';
    _searchDebounce?.cancel();
    // Re-enable global mesh banners when leaving this conversation.
    _meshService.setActiveConversation(null);
    // Re-enable foreground chat notifications.
    NotificationService.activeChatRoomId = null;
    _streakSubscription?.cancel();
    _subtitleToggleTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    // Trigger when user scrolls within 200px of the top (which is maxScrollExtent in a reversed list)
    if (currentScroll >= maxScroll - 200) {
      _loadOlderMessages();
    }
  }

  /// Shows the streak-restore dialog when the user taps the broken-streak badge.
  Future<void> _showStreakRestoreDialog() async {
    final view = _streakView;
    if (view == null || !view.isRestorable) return;
    final restoreDeadline = view.restoreDeadlineAt;
    if (restoreDeadline == null) return;
    // The dialog counts down from `brokenAt + kStreakRestoreWindow`; the
    // derived view carries the far end of that window.
    final brokenAt = restoreDeadline.subtract(kStreakRestoreWindow);
    final chatRoomId =
        _chatService.getChatRoomId(widget.currentUserId, widget.contact.id);
    // Fetch current user's Gup Points
    int gupPoints = 0;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .get();
      gupPoints = (userDoc.data()?['gupPoints'] as int?) ?? 0;
    } catch (_) {}

    if (!mounted) return;
    await StreakRestoreDialog.show(
      context,
      previousStreakCount: view.restorableCount,
      streakBrokenAt: brokenAt,
      userGupPoints: gupPoints,
      contactName: widget.contact.name,
      userId: widget.currentUserId,
      chatRoomId: chatRoomId,
    );
  }

  Future<void> _loadOlderMessages() async {
    if (_isLoadingOlder || !_hasMoreOlder) return;

    // Filter out mesh messages to get the oldest actual message from SQLite
    final dbMessages =
        _currentMessages.where((m) => !m.id.startsWith('mesh_')).toList();
    if (dbMessages.isEmpty) return;

    if (mounted) {
      setState(() {
        _isLoadingOlder = true;
      });
    }

    try {
      final oldestMsg = dbMessages.first; // sorted ASC, so first is oldest
      final count = await _chatService.fetchOlderMessages(
        chatRoomId:
            _chatService.getChatRoomId(widget.currentUserId, widget.contact.id),
        beforeTimestamp: oldestMsg.timestamp,
        currentUserId: widget.currentUserId,
        limit: 50,
      );

      if (count < 50) {
        _hasMoreOlder = false;
      }
    } catch (e) {
      debugPrint('Error loading older messages: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOlder = false;
        });
      }
    }
  }

  Future<void> _initializeChat() async {
    // The chat screen now renders IMMEDIATELY — the StreamBuilder on
    // _messagesStream surfaces cached/decrypted messages as soon as the
    // local Firestore snapshot lands (sub-second). Block-status checks,
    // markDelivered / markRead, and listener setup all run in the
    // background. Previously these were four sequential Firestore
    // round-trips (~600ms-2s) that the spinner blocked on for no UX
    // reason — the user just wants to see their messages.
    if (mounted) setState(() => _isLoading = false);

    try {
      await _checkBlockStatus();
    } catch (e) {
      debugPrint('block check failed (non-fatal): $e');
    }

    // Fire the rest in parallel; none of them affect the visible message
    // list (they only update status indicators on previous messages).
    unawaited(_chatService
        .getOrCreateChatRoom(widget.currentUserId, widget.contact.id)
        .catchError((e) {
      debugPrint('getOrCreateChatRoom failed: $e');
      return null as dynamic;
    }));
    if (!_isBlockedByContact) {
      unawaited(_chatService
          .markMessagesAsDelivered(widget.currentUserId, widget.contact.id)
          .catchError((e) => debugPrint('markDelivered failed: $e')));
    }
    if (_settingsService.showReadReceipts && !_isBlocked) {
      unawaited(_chatService
          .markMessagesAsRead(widget.currentUserId, widget.contact.id)
          .catchError((e) => debugPrint('markRead failed: $e')));
    }

    if (!mounted) return;
    _startReadReceiptListener();
    if (!_isBlocked && !_isBlockedByContact) {
      _listenToTypingStatus();
    }
    _listenToOnlineStatus();
    _listenToMeshMessages();
  }

  void _listenToMeshMessages() {
    try {
      final meshService =
          Provider.of<MeshNetworkService>(context, listen: false);
      _meshMessageSubscription = meshService.meshMessageStream.listen((msg) {
        // Only show messages for this conversation
        if ((msg.senderId == widget.contact.id &&
                msg.receiverId == widget.currentUserId) ||
            (msg.senderId == widget.currentUserId &&
                msg.receiverId == widget.contact.id)) {
          if (mounted) {
            setState(() {
              _meshMessages.add(msg);
            });
            _scrollToBottom();
          }
        }
      });
    } catch (_) {
      // MeshNetworkService might not be in the tree yet
    }
  }

  /// Checks if either user has blocked the other.
  Future<void> _checkBlockStatus() async {
    try {
      // Run both Firestore reads in parallel — saves one round-trip compared
      // to the previous sequential pair of get() calls (~100-400ms on mobile).
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUserId)
            .get(),
        FirebaseFirestore.instance
            .collection('users')
            .doc(widget.contact.id)
            .get(),
      ]);
      final myDoc = results[0];
      final theirDoc = results[1];

      final myBlocked = List<String>.from(myDoc.data()?['blockedUsers'] ?? []);
      final theirBlocked =
          List<String>.from(theirDoc.data()?['blockedUsers'] ?? []);

      if (mounted) {
        setState(() {
          _isBlocked = myBlocked.contains(widget.contact.id);
          _isBlockedByContact = theirBlocked.contains(widget.currentUserId);
        });
      }
    } catch (e) {
      print('Error checking block status: $e');
    }
  }

  // Continuously mark new incoming messages as read while chat is open
  void _startReadReceiptListener() {
    // This will be called when new messages arrive via StreamBuilder
    // We'll mark them as read in the stream listener
  }

  // ─── Online status listener ────────────────────────────────────────

  void _listenToOnlineStatus() {
    _onlineStatusSubscription =
        _userService.getUserStream(widget.contact.id).listen((user) {
      if (mounted && user != null) {
        final effectiveOnline =
            (_isBlocked || _isBlockedByContact) ? false : user.isOnline;
        final newLastSeen = user.lastSeen;
        final statusChanged = _isContactOnline != effectiveOnline;
        final lastSeenChanged = _contactLastSeen != newLastSeen;
        if (statusChanged || lastSeenChanged) {
          setState(() {
            _isContactOnline = effectiveOnline;
            _contactLastSeen = newLastSeen;
          });
          // Start alternating timer when offline and there's a bond badge
          _updateSubtitleTimer(effectiveOnline);
        }
      }
    });
  }

  void _updateSubtitleTimer(bool isOnline) {
    _subtitleToggleTimer?.cancel();
    _subtitleToggleTimer = null;
    if (!isOnline && _hasBondBadge) {
      // Show last seen first, then after 2 s animate to bond badge, repeat
      _showBondInSubtitle = false;
      _subtitleToggleTimer = Timer.periodic(
        const Duration(milliseconds: 5200),
        (_) {
          if (mounted) {
            setState(() => _showBondInSubtitle = !_showBondInSubtitle);
          }
        },
      );
    } else {
      if (mounted) setState(() => _showBondInSubtitle = false);
    }
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final diff = now.difference(lastSeen);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
  }

  Widget _buildBondBadge(AppThemeColors c) {
    final view = _streakView;
    if (view == null) return const SizedBox.shrink();
    if (view.count > 0) {
      return StreakBadge(view: view, compact: false);
    }
    if (view.isRestorable) {
      return GestureDetector(
        onTap: () => _showStreakRestoreDialog(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withOpacity(0.25), width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💔', style: TextStyle(fontSize: 10)),
              const SizedBox(width: 2),
              Text(
                'Bond lost!',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[400],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  bool get _hasBondBadge => _streakView?.hasBadge ?? false;

  Widget _buildSubtitleRow(AppThemeColors c) {
    // ── Typing ──────────────────────────────────────────────────────
    if (_isOtherUserTyping) {
      return Row(children: [
        Text(
          'typing...',
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: c.primary,
            fontStyle: FontStyle.italic,
          ),
        ),
        if (_hasBondBadge) ...[
          const SizedBox(width: 8),
          _buildBondBadge(c),
        ],
      ]);
    }

    // ── Online ───────────────────────────────────────────────────────
    if (_isContactOnline) {
      return Row(children: [
        Text(
          'Online',
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: c.online,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (_hasBondBadge) ...[
          const SizedBox(width: 8),
          _buildBondBadge(c),
        ],
      ]);
    }

    // ── Offline ──────────────────────────────────────────────────────
    // If there's a bond badge, alternate between "Last seen" and the badge
    // with a smooth cross-fade. Two AnimatedOpacity widgets in a fixed-height
    // Stack avoids the layout jank that AnimatedSwitcher causes when the
    // entering and exiting children collide during the transition.
    if (_hasBondBadge) {
      final lastSeenText = _contactLastSeen != null
          ? 'Last seen ${_formatLastSeen(_contactLastSeen!)}'
          : 'Offline';
      return SizedBox(
        height: 16,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            IgnorePointer(
              ignoring: _showBondInSubtitle,
              child: AnimatedOpacity(
                opacity: _showBondInSubtitle ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                child: Text(
                  lastSeenText,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: c.textMid,
                  ),
                ),
              ),
            ),
            IgnorePointer(
              ignoring: !_showBondInSubtitle,
              child: AnimatedOpacity(
                opacity: _showBondInSubtitle ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                child: _buildBondBadge(c),
              ),
            ),
          ],
        ),
      );
    }

    // No bond badge — just show last seen
    if (_contactLastSeen != null) {
      return Text(
        'Last seen ${_formatLastSeen(_contactLastSeen!)}',
        style: GoogleFonts.poppins(fontSize: 11, color: c.textMid),
      );
    }

    return const SizedBox.shrink();
  }

  // ─── Typing indicator helpers ──────────────────────────────────────

  void _listenToTypingStatus() {
    _typingSubscription = _chatService
        .getTypingStatus(
      currentUserId: widget.currentUserId,
      otherUserId: widget.contact.id,
    )
        .listen((isTyping) {
      if (mounted && _isOtherUserTyping != isTyping) {
        setState(() {
          _isOtherUserTyping = isTyping;
        });
      }
    });
  }

  /// Called every time the text field value changes.
  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;

    // Update the mic/send button toggle
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }

    // User started typing — notify Firestore once
    if (hasText && !_isTyping) {
      _isTyping = true;
      _chatService.setTypingStatus(
        currentUserId: widget.currentUserId,
        otherUserId: widget.contact.id,
        isTyping: true,
      );
    }

    // Reset the stop-typing debounce timer on every keystroke
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), _stopTyping);

    _scheduleLinkPreview();
  }

  /// Watches the composer for a URL and resolves its preview in the background.
  ///
  /// Debounced because this fires on every keystroke and a fetch is a network
  /// round-trip. Nothing here is on the send path — [_sendMessage] attaches
  /// whatever has already landed and never waits.
  void _scheduleLinkPreview() {
    final url = firstLinkIn(_messageController.text);

    if (url == null) {
      // The URL was edited away or the composer was emptied. Drop the card and
      // re-arm suppression so a *new* link gets a fresh chance.
      _previewDebounce?.cancel();
      if (_previewUrl != null || _pendingPreview != null) {
        setState(() {
          _previewUrl = null;
          _pendingPreview = null;
          _linkPreviewSuppressed = false;
        });
      }
      return;
    }

    if (url == _previewUrl) return; // same link, still typing around it

    _previewDebounce?.cancel();
    setState(() {
      _previewUrl = url;
      // A different link than the one that was dismissed deserves its own card.
      _linkPreviewSuppressed = false;
      _pendingPreview = LinkPreviewService.instance.cached(url);
    });
    if (_pendingPreview != null) return;

    _previewDebounce = Timer(const Duration(milliseconds: 600), () async {
      final preview = await LinkPreviewService.instance.fetch(url);
      // The user may have typed past this link while the fetch was in flight.
      if (!mounted || _previewUrl != url) return;
      setState(() => _pendingPreview = preview);
    });
  }

  /// True when there is a resolved preview the composer should be showing.
  bool get _showComposerPreview =>
      // Never while editing. An edit preserves the original's preview and does
      // not resolve a new one, so showing a card here would promise a change the
      // commit will not make.
      _editing == null &&
      !_linkPreviewSuppressed &&
      _pendingPreview != null &&
      _pendingPreview!.isRenderable;

  void _stopTyping() {
    if (_isTyping) {
      _isTyping = false;
      _chatService.setTypingStatus(
        currentUserId: widget.currentUserId,
        otherUserId: widget.contact.id,
        isTyping: false,
      );
    }
  }

  // Call this when new messages arrive while chat is open
  Future<void> _markNewMessagesAsRead() async {
    // Only send read receipts if the user has enabled them
    if (!_settingsService.showReadReceipts) return;
    await _chatService.markMessagesAsRead(
      widget.currentUserId,
      widget.contact.id,
    );
  }

  // ─── Safety number verification (from E2EE banner tap) ─────────────────
  Future<void> _showSafetyNumberForContact() async {
    final c = AppThemeColors.of(context);

    // Compute the 5200-round hash behind a blocking overlay. `during` tears the
    // overlay down in a finally, so a failure can't leave it stuck on screen.
    final n = await LoadingOverlay.during(
      context,
      () => SafetyNumberService().safetyNumberFor(
        selfUserId: widget.currentUserId,
        peerUserId: widget.contact.id,
      ),
      message: 'Computing safety number…',
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage:
                  avatarImage(widget.contact.avatarUrl, radius: 18),
              backgroundColor: c.surfaceAlt,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.contact.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: n == null
            ? const Text(
                'This contact hasn\'t published an encryption key bundle yet. '
                'They may be using an older version of GupShupGo.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'If the number below matches on '
                    '${widget.contact.name}\'s device, your end-to-end '
                    'encryption is verified.',
                    style: TextStyle(fontSize: 13, color: c.textMid),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      n,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        height: 1.8,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: c.textLow),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Compare this number in person or over a trusted call.',
                          style: TextStyle(fontSize: 11, color: c.textLow),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _initiateVideoCall() async {
    if (_isBlocked || _isBlockedByContact) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot call this contact')),
      );
      return;
    }
    if (widget.currentUserId == widget.contact.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot call yourself')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConnectingCallScreen(
          currentUserId: widget.currentUserId,
          calleeId: widget.contact.id,
          calleeName: widget.contact.name,
          calleePhotoUrl: widget.contact.avatarUrl,
        ),
      ),
    );
  }

  Future<void> _initiateAudioCall() async {
    if (_isBlocked || _isBlockedByContact) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot call this contact')),
      );
      return;
    }
    if (widget.currentUserId == widget.contact.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot call yourself')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConnectingCallScreen(
          currentUserId: widget.currentUserId,
          calleeId: widget.contact.id,
          calleeName: widget.contact.name,
          calleePhotoUrl: widget.contact.avatarUrl,
          isAudioOnly: true,
        ),
      ),
    );
  }

  Future<void> _initiateScreenShare() async {
    if (_isBlocked || _isBlockedByContact) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot share screen with this contact')),
      );
      return;
    }
    if (widget.currentUserId == widget.contact.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot share screen with yourself')),
      );
      return;
    }

    if (ScreenShareSession.instance.active) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A screen share is already in progress')),
      );
      return;
    }

    // Re-entry guard. The `active` check above doesn't engage during the
    // Firestore-write → FCM → Agora-init gap (the session isn't active yet),
    // so without this a second tap could start a duplicate share.
    if (_startingScreenShare) return;

    AppHaptics.tap();
    setState(() => _startingScreenShare = true);

    try {
      final channelId = CallSignalingService.generateChannelId();

      print(
          'Initiating screen share to ${widget.contact.name} on channel $channelId');

      // The signaling write + push run behind a brief blocking overlay so the
      // tap has immediate feedback. No screen-capture consent happens here any
      // more — it fires later, only if the viewer accepts. Navigation stays
      // OUTSIDE `during` (see its doc): we push the share screen after teardown.
      await LoadingOverlay.during(
        context,
        () async {
          // Create the Firestore signaling document BEFORE notifying the
          // viewer, so both sides can listen for accept/decline/end signals.
          await CallSignalingService.createCallDocument(
            channelId: channelId,
            callerId: widget.currentUserId,
            calleeId: widget.contact.id,
          );

          // Notify the other user — they get an accept/reject request.
          await FCMService().sendScreenShareNotification(
              widget.contact.id, widget.currentUserId, channelId);

          // Start the long-lived session in "requesting" mode (owns the Agora
          // engine so it survives navigation). NOTHING is captured yet — the
          // Android screen-capture consent dialog only fires once the viewer
          // accepts and the session goes live.
          await ScreenShareSession.instance.requestAsSharer(
            channelId: channelId,
            viewerName: widget.contact.name,
          );
        },
        message: 'Sending request…',
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ScreenShareScreen(),
        ),
      );
    } catch (e) {
      print('Error initiating screen share: $e');
      // Tear down a half-started session so nothing is left dangling.
      await ScreenShareSession.instance.end();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start screen sharing: $e')),
      );
    } finally {
      if (mounted) setState(() => _startingScreenShare = false);
    }
  }

  Future<void> _sendMessage() async {
    // The composer is in edit mode — same button, different commit. Checked
    // before the empty-text guard below so an emptied edit gets its own
    // explanation instead of silently doing nothing.
    if (_editing != null) return _commitEdit();

    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    if (_isBlocked || _isBlockedByContact) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send messages to this contact')),
      );
      return;
    }

    // Snapshot the reply target and the preview *now*, in the same synchronous
    // block that clears the composer below. Reading them after the clear would
    // race a fast second send: the user can start typing the next message
    // immediately, and this send's crypto runs long after.
    final replyTo = _replyTo;
    final preview = _showComposerPreview ? _pendingPreview : null;

    // ── Optimistic UI: WhatsApp-style ────────────────────────────────────
    // Clear the input field, stop the typing indicator, and scroll to the
    // bottom IMMEDIATELY — before encryption or any Firestore work runs.
    // Previously the send button was disabled (`_isSending = true`) for the
    // entire encrypt + Firestore commit (~150–800ms depending on cache
    // state and network), which is what made sends feel "sometimes slow".
    // The user can now type and queue the next message while this one is
    // still going through; the Firestore stream resolves the message into
    // the chat list whenever the commit lands.
    _messageController.clear();
    _stopTyping();
    _scrollToBottom();
    _clearReplyAndPreview();

    final connectivity =
        Provider.of<ConnectivityProvider>(context, listen: false);

    if (!connectivity.isOnline) {
      // ── Offline path stays awaited so we can fall back to mesh and
      //    restore the text if mesh is also unavailable. Offline send is a
      //    user-noticeable error case — surfacing it sync is the right call.
      try {
        final meshService =
            Provider.of<MeshNetworkService>(context, listen: false);
        final meshMsg = await meshService.sendViaMesh(
          receiverId: widget.contact.id,
          text: text,
          senderName: widget.currentUserName,
          linkPreviewUrl: preview?.url,
          linkPreviewTitle: preview?.title,
          linkPreviewDescription: preview?.description,
          linkPreviewSiteName: preview?.siteName,
          linkPreviewImageBase64: preview?.imageBase64,
          replyToMessageId: replyTo?.id,
          replyToSenderId: replyTo?.senderId,
          replyToSenderName: _replyDisplayName(replyTo),
          replyToType: replyTo?.type.name,
          replyToText: _replySnippet(replyTo),
        );
        if (mounted) setState(() => _meshMessages.add(meshMsg));
        _scrollToBottom();
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('No internet & mesh unavailable. Message not sent.')),
        );
        _messageController.text = text;
      }
      return;
    }

    // ── Online: fire-and-forget. The encrypt + Firestore batch happens
    //    in the background; the chat stream brings the message into view
    //    the moment the commit lands. On failure we restore the text only
    //    if the user hasn't started typing something new.
    unawaited(() async {
      try {
        await _chatService.sendMessage(
          senderId: widget.currentUserId,
          receiverId: widget.contact.id,
          text: text,
          senderName: widget.currentUserName,
          linkPreviewUrl: preview?.url,
          linkPreviewTitle: preview?.title,
          linkPreviewDescription: preview?.description,
          linkPreviewSiteName: preview?.siteName,
          linkPreviewImageBase64: preview?.imageBase64,
          replyToMessageId: replyTo?.id,
          replyToSenderId: replyTo?.senderId,
          replyToSenderName: _replyDisplayName(replyTo),
          replyToType: replyTo?.type.name,
          replyToText: _replySnippet(replyTo),
        );
      } catch (e) {
        print('Error sending message: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
        if (_messageController.text.isEmpty) {
          _messageController.text = text;
        }
      }
    }());
  }

  // ─── Reply plumbing ──────────────────────────────────────────────────

  /// The name stored *in* the reply, so the quote reads correctly on both ends.
  ///
  /// Deliberately the author's real name rather than "You": the receiver would
  /// otherwise see their own message quoted as "You" when it was in fact
  /// attributed to the sender. Rendering resolves "You" locally instead, by
  /// comparing `replyToSenderId` against the current user.
  String? _replyDisplayName(MessageModel? original) {
    if (original == null) return null;
    return original.senderId == widget.currentUserId
        ? (widget.currentUserName ?? 'You')
        : widget.contact.name;
  }

  /// The snapshot snippet, capped so a quoted essay doesn't bloat every reply
  /// in the thread (and, ×9 envelopes, the Firestore document).
  String? _replySnippet(MessageModel? original) {
    if (original == null) return null;
    final raw = original.text.trim();
    if (raw.isEmpty) return '';
    return raw.length <= kReplySnippetMaxLength
        ? raw
        : '${raw.substring(0, kReplySnippetMaxLength).trimRight()}…';
  }

  void _startReply(MessageModel message) {
    setState(() => _replyTo = message);
    // Bring the keyboard up: a swipe that shows a strip but doesn't let you
    // type is a half-finished gesture.
    _composerFocus.requestFocus();
  }

  void _clearReplyAndPreview() {
    _previewDebounce?.cancel();
    setState(() {
      _replyTo = null;
      _previewUrl = null;
      _pendingPreview = null;
      _linkPreviewSuppressed = false;
    });
  }

  /// Scrolls to the message a quote points at, and flashes it.
  ///
  /// Only works within the loaded window — `_messageKeys` holds exactly the
  /// bubbles that have been built, which is the honest bound on where we can
  /// scroll. Older than that and we say so rather than silently doing nothing.
  Future<void> _jumpToMessage(String messageId) async {
    final key = _messageKeys[messageId];
    final ctx = key?.currentContext;
    if (ctx == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Original message not loaded')),
      );
      return;
    }

    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0.35,
    );
    if (!mounted) return;

    _highlightTimer?.cancel();
    setState(() => _highlightedMessageId = messageId);
    _highlightTimer = Timer(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _highlightedMessageId = null);
    });
  }

  // ─── In-chat search ────────────────────────────────────────────────
  /// Debounced FTS5 query against the local message index.
  ///
  /// Replaces an in-memory `contains` over the loaded page window, which meant
  /// search could only ever find what the user had already scrolled past. The
  /// index covers the whole local history, so a hit may well be a message the
  /// list hasn't built — see [_jumpToMessage], which reports that honestly.
  void _onSearchChanged(String query) {
    final trimmed = query.trim();
    _searchDebounce?.cancel();

    if (trimmed.isEmpty) {
      setState(() {
        _searchQuery = '';
        _searchResults = null;
      });
      return;
    }

    // Null results render the spinner, so the list doesn't flash "No messages
    // found" for the quarter-second before the first query returns.
    setState(() {
      _searchQuery = trimmed;
      _searchResults = null;
    });

    final seq = ++_searchSeq;
    _searchDebounce = Timer(const Duration(milliseconds: 250), () async {
      try {
        final store = await PlaintextStore.instance();
        final hits = await store.searchMessages(_chatRoomId, trimmed);
        // A slower query for a shorter prefix must not land on top of a newer
        // one; the sequence check is the only ordering guarantee here.
        if (!mounted || seq != _searchSeq) return;
        setState(() => _searchResults = hits);
      } catch (_) {
        if (!mounted || seq != _searchSeq) return;
        setState(() => _searchResults = const []);
      }
    });
  }

  String _formatTime(DateTime dateTime) {
    String hour = dateTime.hour > 12
        ? (dateTime.hour - 12).toString()
        : dateTime.hour == 0
            ? '12'
            : dateTime.hour.toString();
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatMessageDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _scrollToBottom() {
    // The list is built with `reverse: true` (WhatsApp-style, anchored to
    // the input). In a reversed list the visual bottom corresponds to
    // offset 0.0, so "scroll to bottom" = "scroll to start of the scroll
    // axis". A small delay lets the new bubble lay out first.
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Wraps a freshly-inserted message bubble in a one-shot fade+rise
  // animation. Existing bubbles (already in `_seenMessageIds`) are returned
  // unchanged so scrolling through history doesn't re-animate every item.
  //
  // GPU-friendly: uses Transform.translate + transparent color channel
  // instead of the Opacity widget, which forces an expensive offscreen
  // compositing layer per bubble on low-end GPUs.
  Widget _animatedBubble(Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, t, c) {
        return Transform.translate(
          offset: Offset(0, (1 - t) * 14),
          child: c,
        );
      },
      child: child,
    );
  }

  Widget _buildDateDivider(String date) {
    final c = _messageColors;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: c.primaryLt,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          date,
          style: GoogleFonts.poppins(
            color: c.primaryDk,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(MessageModel message) {
    final c = _messageColors;
    final isMe = message.senderId == widget.currentUserId;
    final sentGradient = _chatTheme.sentGradientOf(c);
    final isTombstone = message.deletedForEveryone;
    // A deleted message has nothing left to react to, and its reactions left
    // the document along with its ciphertext. Belt-and-braces: a row written by
    // an older build could still be carrying them locally.
    final hasReactions = !isTombstone &&
        message.reactions != null &&
        message.reactions!.isNotEmpty;

    Widget bubble = Container(
      margin: EdgeInsets.only(
        top: 2,
        bottom: hasReactions ? 12 : 2,
        left: isMe ? 64 : 16,
        right: isMe ? 16 : 64,
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        // A preset may carry a diagonal gradient for sent bubbles; `color` and
        // `gradient` are mutually exclusive in practice (BoxDecoration paints the
        // gradient and ignores the colour), so only one is set to keep that
        // explicit rather than relying on the precedence.
        color: isMe && sentGradient != null
            ? null
            : (isMe ? _chatTheme.sentOf(c) : _chatTheme.receivedOf(c)),
        gradient: isMe ? sentGradient : null,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft:
              isMe ? const Radius.circular(18) : const Radius.circular(4),
          bottomRight:
              isMe ? const Radius.circular(4) : const Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.hasStatusReply) _buildStatusReplyPreview(message, isMe),
          if (message.hasReplyQuote) _buildReplyQuote(message, isMe),
          // Above the text, WhatsApp-style — the card is the headline and the
          // message body is the comment on it.
          if (message.hasLinkPreview) _buildLinkPreviewCard(message, isMe),
          // ── Deleted for everyone ──────────────────────────────
          // First in the chain, and not merely an empty-text case: `type`
          // survives a tombstone, so a deleted voice note would otherwise reach
          // VoiceMessageBubble with nothing to play.
          if (isTombstone) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.block_rounded,
                  size: 14,
                  color: isMe ? Colors.white.withOpacity(0.7) : c.textLow,
                ),
                const SizedBox(width: 5),
                Text(
                  ChatService.deletedMessageText,
                  style: GoogleFonts.poppins(
                    color: isMe ? Colors.white.withOpacity(0.85) : c.textLow,
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ]
          // ── Audio / voice message ─────────────────────────────
          else if (message.type == MessageType.audio) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 200),
              child: VoiceMessageBubble(
                message: message,
                isMe: isMe,
              ),
            ),
          ]
          // ── View once photo / video ───────────────────────────
          // Must precede the image and video branches: a view-once message
          // reuses those two types, and falling into them would paint the
          // media inline — which is the one thing this feature exists to
          // prevent. Deliberately *not* guarded on `mediaKey`, unlike the
          // document and location branches: an unmerged or already-consumed
          // view-once message has none, and the placeholder is exactly what
          // should render in both cases (`ViewOnceBubble` tells them apart).
          else if (message.viewOnce &&
              (message.type == MessageType.image ||
                  message.type == MessageType.video)) ...[
            ViewOnceBubble(
              message: message,
              isMe: isMe,
              currentUserId: widget.currentUserId,
            ),
            const SizedBox(height: 4),
          ]
          // ── Image message ─────────────────────────────────────
          else if (message.type == MessageType.image &&
              (message.mediaUrl != null || message.localFilePath != null)) ...[
            GestureDetector(
              onTap: () => _showFullScreenImage(
                  message.mediaUrl, message.localFilePath, message.text),
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 220,
                  maxHeight: 280,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.hardEdge,
                child: _buildImageWidget(message, c),
              ),
            ),
            const SizedBox(height: 4),
          ]
          // ── Video message ─────────────────────────────────────
          else if (message.type == MessageType.video &&
              (message.mediaUrl != null || message.localFilePath != null)) ...[
            GestureDetector(
              onTap: () => _showFullScreenVideo(message),
              child: _buildVideoThumbnail(message),
            ),
            const SizedBox(height: 4),
          ]
          // ── Document message ──────────────────────────────────
          // Guarded on `mediaKey` rather than `mediaUrl`: a document's URL lives
          // *inside* the bundle, so a message whose payload hasn't been merged
          // yet (undecryptable, or awaiting a resend) has neither and correctly
          // falls through to the text branch, where `text` holds the filename.
          else if (message.type == MessageType.document &&
              message.mediaKey != null) ...[
            DocumentBubble(message: message, isMe: isMe),
            const SizedBox(height: 4),
          ]
          // ── Location message ──────────────────────────────────
          // Guarded on `latitude` for the same reason the document branch
          // guards on `mediaKey`: the coordinates live inside the encrypted
          // payload, so an unmerged/undecryptable pin has none and falls
          // through to the text branch, where `text` holds `📍 Location`.
          else if (message.type == MessageType.location &&
              message.latitude != null) ...[
            LocationBubble(message: message, isMe: isMe),
            const SizedBox(height: 4),
          ] else
            LinkifiedText(
              message.text,
              linkColor: isMe ? Colors.white : c.primary,
              style: GoogleFonts.poppins(
                color: isMe ? Colors.white : c.textHigh,
                fontSize: 14.5,
              ).copyWith(
                fontFamilyFallback: const [
                  '',
                  'Noto Color Emoji',
                  'Apple Color Emoji',
                  'Segoe UI Emoji',
                  'sans-serif',
                ],
              ),
            ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Before the time, as WhatsApp has it — the timestamp stays the
              // last thing before the tick marks.
              if (message.isEdited && !isTombstone) ...[
                Text(
                  'edited',
                  style: GoogleFonts.poppins(
                    color: isMe ? Colors.white.withOpacity(0.75) : c.textLow,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                _formatTime(message.timestamp),
                style: GoogleFonts.poppins(
                  color: isMe ? Colors.white.withOpacity(0.75) : c.textLow,
                  fontSize: 10,
                ),
              ),
              if (message.isOfflineMesh) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.sensors_rounded,
                  size: 11,
                  color: isMe ? Colors.white.withOpacity(0.7) : c.textLow,
                ),
              ],
              if (isMe) ...[
                const SizedBox(width: 4),
                _buildMessageStatusIcon(message),
              ],
            ],
          ),
        ],
      ),
    );

    if (hasReactions) {
      final reactionList = message.reactions!.values.toSet().toList();
      final reactionString = reactionList.take(3).join(' ');

      bubble = Stack(
        clipBehavior: Clip.none,
        children: [
          bubble,
          Positioned(
            bottom: 2,
            right: isMe ? 24 : null,
            left: !isMe ? 24 : null,
            child: GestureDetector(
              onTap: () => _showReactionsDetailDialog(message),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: c.border.withOpacity(0.5), width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      reactionString,
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (message.reactions!.length > 1) ...[
                      const SizedBox(width: 4),
                      Text(
                        '${message.reactions!.length}',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: c.textMid,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Flash when a quote tap scrolls here, so the eye can find the message it
    // just jumped to.
    if (_highlightedMessageId == message.id) {
      bubble = DecoratedBox(
        decoration: BoxDecoration(
          color: c.primary.withOpacity(0.16),
          borderRadius: BorderRadius.circular(18),
        ),
        child: bubble,
      );
    }

    // A GlobalKey per built bubble is what makes Scrollable.ensureVisible
    // possible without pulling in scrollable_positioned_list.
    final anchor =
        _messageKeys.putIfAbsent(message.id, () => GlobalKey(debugLabel: message.id));

    return Align(
      key: ValueKey('msg-${message.id}'),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      // Swipe sits OUTSIDE the long-press detector: long-press (the action
      // menu) and horizontal drag (reply) are different recognizers and share
      // the arena fine, but nesting the drag inside a detector that already owns
      // the pointer does not work.
      child: SwipeToReply(
        // Reactions are not messages you can answer, and a bubble we cannot
        // decrypt has no text to snapshot into the quote.
        enabled: message.type != MessageType.reaction &&
            !_isUndecryptable(message),
        onReply: () => _startReply(message),
        child: GestureDetector(
          key: anchor,
          onLongPress: () => _showMessageActions(message),
          child: bubble,
        ),
      ),
    );
  }

  /// True for a bubble whose payload never decrypted on this device.
  ///
  /// Uses [VaultCipher.isPlaceholderText] rather than an emptiness or prefix
  /// test — that predicate is the codebase's single agreed definition of "not
  /// real content", shared with SyncService and the chat-list preview, and it
  /// matches exactly so a message that legitimately opens with a lock emoji is
  /// never mistaken for one.
  bool _isUndecryptable(MessageModel message) =>
      VaultCipher.isPlaceholderText(message.text);

  Widget _buildReplyQuote(MessageModel message, bool isMe) {
    final previewWidth = (MediaQuery.of(context).size.width - 116)
        .clamp(188.0, 246.0)
        .toDouble();

    // "You" is resolved here rather than stored, so the same reply reads
    // correctly on both devices — see _replyDisplayName.
    final name = message.replyToSenderId == widget.currentUserId
        ? 'You'
        : (message.replyToSenderName ?? widget.contact.name);

    // Best-effort thumbnail: only from a file this device already has, because
    // the original's mediaUrl is ciphertext without the media key.
    final original = _findLoadedMessage(message.replyToMessageId);

    return ReplyQuoteCard(
      senderName: name,
      text: message.replyToText,
      type: message.replyToType,
      localThumbPath: original?.localFilePath,
      isMe: isMe,
      width: previewWidth,
      onTap: message.replyToMessageId == null
          ? null
          : () => _jumpToMessage(message.replyToMessageId!),
    );
  }

  MessageModel? _findLoadedMessage(String? id) {
    if (id == null) return null;
    for (final m in _currentMessages) {
      if (m.id == id) return m;
    }
    return null;
  }

  Widget _buildLinkPreviewCard(MessageModel message, bool isMe) {
    final previewWidth = (MediaQuery.of(context).size.width - 116)
        .clamp(188.0, 246.0)
        .toDouble();

    return LinkPreviewCard(
      url: message.linkPreviewUrl!,
      cacheKey: message.id,
      title: message.linkPreviewTitle,
      description: message.linkPreviewDescription,
      siteName: message.linkPreviewSiteName,
      imageBase64: message.linkPreviewImageBase64,
      isMe: isMe,
      width: previewWidth,
    );
  }

  /// Build the correct image widget for a message (network URL or local file).
  ///
  /// GPU-friendly: uses cacheWidth so Flutter decodes images at display
  /// resolution (2× the 220px maxWidth constraint = 440 logical pixels)
  /// instead of at source resolution. On a chat with 50 images this saves
  /// hundreds of MB of GPU texture memory on low-end devices.
  Widget _buildImageWidget(MessageModel message, dynamic c) {
    // 2× the maxWidth constraint for retina-quality without wasting memory.
    final cacheW = (220 * MediaQuery.of(context).devicePixelRatio).round();

    // Prefer local file if available (mesh images)
    if (message.localFilePath != null &&
        File(message.localFilePath!).existsSync()) {
      return Image.file(
        File(message.localFilePath!),
        fit: BoxFit.cover,
        cacheWidth: cacheW,
        errorBuilder: (_, __, ___) => Container(
          width: 200,
          height: 100,
          color: c.surfaceAlt,
          child: Center(
            child: Icon(Icons.broken_image_rounded, color: c.textLow),
          ),
        ),
      );
    }

    // Fall back to network URL
    if (message.mediaUrl != null) {
      return Image.network(
        message.mediaUrl!,
        fit: BoxFit.cover,
        cacheWidth: cacheW,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            width: 200,
            height: 150,
            color: c.surfaceAlt,
            child: Center(
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: c.primary),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          width: 200,
          height: 100,
          color: c.surfaceAlt,
          child: Center(
            child: Icon(Icons.broken_image_rounded, color: c.textLow),
          ),
        ),
      );
    }

    // No image source available
    return Container(
      width: 200,
      height: 100,
      color: c.surfaceAlt,
      child: Center(
        child: Icon(Icons.image_not_supported_rounded, color: c.textLow),
      ),
    );
  }

  void _showFullScreenImage(
      String? imageUrl, String? localFilePath, String caption) {
    Widget imageWidget;
    if (localFilePath != null && File(localFilePath).existsSync()) {
      imageWidget = Image.file(File(localFilePath));
    } else if (imageUrl != null) {
      // Deliberately NOT downsampled, unlike every other image in this file.
      // This is the pinch-to-zoom viewer, so the source pixels are the point —
      // a cacheWidth here would show as mush the moment the user zooms in. The
      // cost is bounded: one image, on a route that disposes it on pop, rather
      // than a list holding dozens resident at once.
      imageWidget = Image.network(imageUrl);
    } else {
      return; // nothing to show
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(caption,
                style: const TextStyle(fontSize: 14, color: Colors.white70)),
          ),
          body: Center(
            child: InteractiveViewer(
              child: imageWidget,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openStatusReply(MessageModel message) async {
    if (!message.hasStatusReply) return;

    try {
      final status =
          await _statusService.getStatusByUserId(message.statusReplyOwnerId!);
      final itemExists = status?.activeStatusItems
              .any((item) => item.id == message.statusReplyItemId) ??
          false;

      if (!mounted) return;

      if (status == null || !itemExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This status is no longer available')),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StatusViewerScreen(
            statusModel: status,
            currentUserId: widget.currentUserId,
            currentUserName: widget.currentUserName,
            isMyStatus: status.userId == widget.currentUserId,
            initialStatusItemId: message.statusReplyItemId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open status')),
      );
    }
  }

  Color _parseStatusColor(String? hex) {
    try {
      final value = (hex ?? '#075E54').replaceFirst('#', '');
      final normalized = value.length == 6 ? 'FF$value' : value;
      return Color(int.parse(normalized, radix: 16));
    } catch (_) {
      return const Color(0xFF075E54);
    }
  }

  String _statusReplyTitle(MessageModel message) {
    final type = message.statusReplyType;
    if (type == 'image') return 'Photo status';
    if (type == 'video') return 'Video status';
    return 'Text status';
  }

  String _statusReplyPreviewText(MessageModel message) {
    final text = (message.statusReplyText ?? '').trim();
    if (text.isNotEmpty) return text;
    final caption = (message.statusReplyCaption ?? '').trim();
    if (caption.isNotEmpty) return caption;
    return _statusReplyTitle(message);
  }

  Widget _buildStatusReplyPreview(MessageModel message, bool isMe) {
    final c = _messageColors;
    final type = message.statusReplyType;
    final mediaUrl = message.statusReplyMediaUrl;
    final previewText = _statusReplyPreviewText(message);
    final previewWidth = (MediaQuery.of(context).size.width - 116)
        .clamp(188.0, 246.0)
        .toDouble();

    Widget thumbnail;
    if ((type == 'image' || type == 'video') && mediaUrl != null) {
      thumbnail = Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            mediaUrl,
            fit: BoxFit.cover,
            // Painted into a 46×58 box (see the SizedBox below) but the source
            // is raw status media — a full camera frame. 174 = 58 logical px at
            // 3× DPR, which is the axis that has to cover for portrait media;
            // without it a 3000×4000 photo decodes to ~48 MB per thumbnail.
            cacheWidth: 174,
            errorBuilder: (_, __, ___) => Container(
              color: c.surfaceAlt,
              child: Icon(Icons.broken_image_rounded, color: c.textLow),
            ),
          ),
          if (type == 'video')
            const Center(
              child: Icon(
                Icons.play_circle_fill_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
        ],
      );
    } else {
      thumbnail = Container(
        color: _parseStatusColor(message.statusReplyBackgroundColor),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(5),
        child: Text(
          previewText,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _openStatusReply(message),
      child: Container(
        width: previewWidth,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.white.withOpacity(0.16)
              : c.surfaceAlt.withOpacity(0.92),
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(
              color: isMe ? Colors.white.withOpacity(0.75) : c.primary,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: SizedBox(width: 46, height: 58, child: thumbnail),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.statusReplyOwnerName ?? 'Moment',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: isMe ? Colors.white : c.textHigh,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        type == 'video'
                            ? Icons.videocam_rounded
                            : type == 'image'
                                ? Icons.image_rounded
                                : Icons.format_quote_rounded,
                        size: 13,
                        color:
                            isMe ? Colors.white.withOpacity(0.78) : c.textMid,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _statusReplyTitle(message),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: isMe
                                ? Colors.white.withOpacity(0.82)
                                : c.textMid,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    previewText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: isMe ? Colors.white.withOpacity(0.9) : c.textHigh,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageStatusIcon(MessageModel message) {
    switch (message.status) {
      case MessageStatus.sending:
        // Clock icon while the Firestore commit is still in flight. The
        // outbox layer holds the bubble on screen during this window so
        // the user never waits for the send to "feel" complete.
        return const Icon(Icons.access_time_rounded,
            size: 14, color: Colors.white70);
      case MessageStatus.failed:
        return const Icon(Icons.error_outline_rounded,
            size: 14, color: Color(0xFFFFB4A9));
      case MessageStatus.sent:
        return const Icon(Icons.done_rounded, size: 14, color: Colors.white70);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all_rounded,
            size: 14, color: Colors.white70);
      case MessageStatus.read:
        return const Icon(Icons.done_all_rounded,
            size: 14, color: Color(0xFFA5F3FC));
    }
  }

  Widget _buildMessagesList(List<MessageModel> messages) {
    final c = _messageColors;
    if (messages.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // E2EE notice is always visible — even on empty chats — so the
          // user sees the encryption guarantee before they send their
          // first message, matching WhatsApp's "🔒 Messages are end-to-
          // end encrypted" pill above the greeting.
          E2EEBanner.chat(context),
          const Spacer(),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: c.primaryLt,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.waving_hand_rounded,
              size: 40,
              color: c.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Say hello!',
            style: GoogleFonts.poppins(
              color: c.textHigh,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start the conversation',
            style: GoogleFonts.poppins(
              color: c.textMid,
              fontSize: 14,
            ),
          ),
          const Spacer(flex: 2),
        ],
      );
    }

    _currentMessages = messages;

    // Drop jump-anchors for messages that have left the loaded window. Without
    // this the map grows for the life of the screen, and a stale GlobalKey
    // whose element is gone would make _jumpToMessage look like it silently
    // failed instead of reporting "not loaded".
    if (_messageKeys.length > messages.length + 32) {
      final live = messages.map((m) => m.id).toSet();
      _messageKeys.removeWhere((id, _) => !live.contains(id));
    }

    // ── Search results ────────────────────────────────────────────────
    // Search no longer filters `messages`: the FTS5 index covers the whole
    // local history, so a hit is frequently a message the list hasn't paged in
    // and couldn't be filtered *to*. Results are their own list.
    final searching = _isSearchMode && _searchQuery.isNotEmpty;
    final displayMessages = searching ? (_searchResults ?? const []) : messages;

    if (searching && _searchResults == null) {
      return Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: c.primary),
        ),
      );
    }

    if (searching && displayMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: c.textLow),
            const SizedBox(height: 12),
            Text(
              'No messages found',
              style: GoogleFonts.poppins(color: c.textMid, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Group messages by date. On the very first build we treat every
    // message as "already seen" so we don't replay the entry animation for
    // history when the screen opens. Subsequent builds animate only ids we
    // haven't rendered before — i.e. new optimistic bubbles and freshly
    // arrived peer messages.
    final isInitial = !_didInitialMessageBuild;
    _didInitialMessageBuild = true;

    // ── Build a flat list of display items (date dividers + message bubbles
    //    + typing indicator) indexed for ListView.builder ─────────────────
    // Previously we eagerly built ALL widgets into a List<Widget> and fed
    // them to a plain ListView. On a 500-message chat, that meant 500+
    // widget builds per Firestore emission — even for items far off-screen.
    // ListView.builder only builds the ~15 visible items, saving massive
    // CPU on low-end devices.
    final displayItems = <_DisplayItem>[];
    if (_isLoadingOlder) {
      displayItems.add(const _DisplayItem.loadingOlder());
    }
    // E2EE pill at the very top of the conversation.
    displayItems.add(const _DisplayItem.banner());
    String? lastDate;

    // Pick the chat's single ad anchor, once, on the first build with enough
    // history. Counted back from the newest message because `reverse: true` puts
    // the composer at the bottom — the gap is what keeps the card away from the
    // send button, where a mis-tap would be an accidental click.
    if (_chatAdAnchorId == null &&
        displayMessages.length >= _kChatAdMinMessages) {
      _chatAdAnchorId =
          displayMessages[displayMessages.length - _kChatAdGapFromComposer].id;
    }

    for (int i = 0; i < displayMessages.length; i++) {
      final message = displayMessages[i];
      final messageDate = _formatMessageDate(message.timestamp);

      // Above the date divider rather than below it, so the card never reads as
      // the first thing that happened on a given day.
      if (message.id == _chatAdAnchorId) {
        displayItems.add(const _DisplayItem.nativeAd());
      }

      if (lastDate != messageDate) {
        displayItems.add(_DisplayItem.dateDivider(messageDate));
        lastDate = messageDate;
      }

      final isNew = _seenMessageIds.add(message.id);
      displayItems
          .add(_DisplayItem.message(message, animate: isNew && !isInitial));
    }

    // Append typing bubble as the last item — with reverse:true below this
    // ends up at the visual bottom, just above the input bar.
    if (_isOtherUserTyping) {
      displayItems.add(const _DisplayItem.typing());
    }

    // reverse:true anchors content to the bottom of the viewport (WhatsApp
    // behaviour). ListView.builder with reverse:true indexes from the bottom,
    // so index 0 = last item in displayItems (the newest message / typing).
    final itemCount = displayItems.length;
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // reverse:true means index 0 = visual bottom = last display item.
        final item = displayItems[itemCount - 1 - index];
        switch (item.type) {
          case _DisplayItemType.banner:
            return E2EEBanner.chat(context);
          case _DisplayItemType.dateDivider:
            return _buildDateDivider(item.dateLabel!);
          case _DisplayItemType.typing:
            return _buildTypingBubble();
          case _DisplayItemType.loadingOlder:
            return _buildLoadingOlderIndicator();
          case _DisplayItemType.nativeAd:
            // Self-hiding: renders nothing at all unless native ads are on for
            // chat, the user isn't Pro, and an ad actually filled. Never styled
            // as a bubble — see [NativeAdCard].
            return NativeAdCard(
              key: const ValueKey('native-ad-chat'),
              placement: 'chat',
              inChat: true,
              budget: _chatAdBudget,
            );
          case _DisplayItemType.message:
            final bubble = _buildMessage(item.message!);
            // RepaintBoundary isolates each message bubble into its own
            // compositing layer so that scrolling / setState rebuilds on the
            // parent chat screen don't repaint every bubble — only the ones
            // whose content actually changed. Critical for smooth scrolling
            // in chats with hundreds of messages on low-end devices.
            return RepaintBoundary(
              child: item.animate ? _animatedBubble(bubble) : bubble,
            );
        }
      },
    );
  }

  Widget _buildLoadingOlderIndicator() {
    final c = _messageColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: c.primary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    // Resolve the chat theme once per build and cache it for the bubble
    // builders. They read `State.context`, which sits *above* the themed area
    // inserted below, so they cannot pick the palette up from the tree — see
    // `_messageColors`.
    _chatTheme = context.watch<ChatThemeProvider>().resolve(
          _chatRoomId,
          unlocked: context.watch<SubscriptionProvider>().isProUnlocked,
        );
    return Scaffold(
      backgroundColor: _chatTheme.backgroundOf(c),
      appBar: AppBar(
        foregroundColor: c.textHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: c.border,
        scrolledUnderElevation: 0.8,
        titleSpacing: 0,
        // Collapse the default leading slot so the back button sits flush
        leadingWidth: 44,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundImage: widget.contact.avatarUrl.isNotEmpty
                      ? avatarImage(widget.contact.avatarUrl, radius: 19)
                      : null,
                  backgroundColor: c.primaryLt,
                  child: widget.contact.avatarUrl.isEmpty
                      ? Text(
                          widget.contact.name.isNotEmpty
                              ? widget.contact.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 15,
                            color: c.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
                if (_isContactOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: c.online,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.surface, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.contact.name,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: c.textHigh,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  // Subtitle row: typing / online / last seen / streak
                  _buildSubtitleRow(c),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_isSearchMode)
            // ── Search bar inline ─────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search messages...',
                    hintStyle:
                        GoogleFonts.poppins(color: c.textLow, fontSize: 14),
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () {
                        _searchDebounce?.cancel();
                        setState(() {
                          _isSearchMode = false;
                          _searchQuery = '';
                          _searchResults = null;
                          _searchController.clear();
                        });
                      },
                    ),
                  ),
                  style: GoogleFonts.poppins(fontSize: 14, color: c.textHigh),
                  onChanged: _onSearchChanged,
                ),
              ),
            )
          else ...[
            AsyncIconButton(
              icon: const Icon(Icons.phone_outlined),
              color: c.isDark ? Colors.white : c.textHigh,
              iconSize: 22,
              onPressed: _initiateAudioCall,
              tooltip: 'Audio Call',
            ),
            AsyncIconButton(
              icon: const Icon(Icons.videocam_outlined),
              color: c.isDark ? Colors.white : c.textHigh,
              iconSize: 24,
              onPressed: _initiateVideoCall,
              tooltip: 'Video Call',
            ),
            PopupMenuButton<String>(
              icon: const NewFeatureDot(
                anchor: NewFeatureAnchor.chatOverflow,
                offset: NewFeatureDot.narrowGlyph,
                child: Icon(Icons.more_vert),
              ),
              onSelected: _onMenuItemSelected,
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem(
                      value: 'contact info',
                      child:
                          Text('Contact info', style: GoogleFonts.poppins())),
                  PopupMenuItem(
                    value: 'search',
                    child: Row(
                      children: [
                        Text('Search', style: GoogleFonts.poppins()),
                        const NewFeatureChip(featureId: NewFeature.chatSearch),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'chat theme',
                    child: Row(
                      children: [
                        Text('Chat theme', style: GoogleFonts.poppins()),
                        const NewFeatureChip(featureId: NewFeature.chatThemes),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export chat',
                    child: Row(
                      children: [
                        Text('Export chat', style: GoogleFonts.poppins()),
                        const NewFeatureChip(featureId: NewFeature.chatExport),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                      value: 'mute notifications',
                      child: Text(
                          _isMuted
                              ? 'Unmute notifications'
                              : 'Mute notifications',
                          style: GoogleFonts.poppins())),
                  PopupMenuItem(
                      value: 'block contact',
                      child: Text('Block contact',
                          style: GoogleFonts.poppins(color: c.error))),
                ];
              },
            ),
          ],
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: c.primary))
          : Column(
              children: [
                // ── Smart banner: E2EE (online) / No-internet (offline) ──
                Consumer<ConnectivityProvider>(
                  builder: (_, connectivity, __) {
                    if (connectivity.isOnline) {
                      // ── Online: E2EE trust banner ─────────────────────
                      final c2 = AppThemeColors.of(context);
                      return GestureDetector(
                        onTap: () => _showSafetyNumberForContact(),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          color: c2.isDark
                              ? const Color(0xFF0B0C12)
                              : c2.surface,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_outline_rounded,
                                  size: 13,
                                  color: c2.isDark
                                      ? Colors.white54
                                      : c2.textLow),
                              const SizedBox(width: 6),
                              Text(
                                'End-to-end encrypted',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: c2.isDark
                                      ? Colors.white54
                                      : c2.textLow,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    // ── Offline: No-internet / mesh banner ──────────────
                    final c3 = AppThemeColors.of(context);
                    return Consumer<MeshNetworkService>(
                      builder: (_, mesh, __) => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        color: c3.isDark
                            ? const Color(0xFF1A1C28)
                            : const Color(0xFFF0EFF8),
                        child: Row(
                          children: [
                            Icon(
                              mesh.isActive
                                  ? Icons.sensors_rounded
                                  : Icons.wifi_off_rounded,
                              color: mesh.isActive
                                  ? const Color(0xFF4ADE80)
                                  : Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                mesh.isActive
                                    ? 'Offline Chat  ·  ${mesh.connectedPeers} device${mesh.connectedPeers == 1 ? '' : 's'} nearby'
                                    : 'No internet?\nChat offline with nearby devices',
                                style: GoogleFonts.poppins(
                                  color: c3.isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (!mesh.isActive)
                              GestureDetector(
                                onTap: () => mesh.start(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4ADE80),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Enable',
                                    style: GoogleFonts.poppins(
                                      color: Colors.black,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: _ChatThemedArea(
                    theme: _chatTheme,
                    colors: c,
                    child: StreamBuilder<List<MessageModel>>(
                      stream: _messagesStream,
                      builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return Center(
                            child: CircularProgressIndicator(color: c.primary));
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  size: 48, color: c.error),
                              const SizedBox(height: 16),
                              Text('Error loading messages',
                                  style: GoogleFonts.poppins(color: c.textMid)),
                              TextButton(
                                onPressed: () => setState(() {}),
                                child: const Text('Try again'),
                              ),
                            ],
                          ),
                        );
                      }

                      final firestoreMessages = snapshot.data ?? [];

                      // Merge Firestore messages with locally-stored
                      // mesh messages (dedup by id).
                      final firestoreIds =
                          firestoreMessages.map((m) => m.id).toSet();
                      final uniqueMesh = _meshMessages
                          .where((m) => !firestoreIds.contains(m.id))
                          .toList();
                      final messages = [
                        ...firestoreMessages,
                        ...uniqueMesh,
                      ]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

                      final nonReactionMessages = messages
                          .where((m) => m.type != MessageType.reaction)
                          .toList();

                      final hasUnreadMessages = nonReactionMessages.any((m) =>
                          m.receiverId == widget.currentUserId &&
                          m.status != MessageStatus.read);
                      if (hasUnreadMessages) {
                        _markNewMessagesAsRead();
                      }

                      // Only auto-scroll when genuinely new messages arrive,
                      // not on status updates (sent→delivered→read).
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (nonReactionMessages.length > _lastMessageCount) {
                          _scrollToBottom();
                        }
                        _lastMessageCount = nonReactionMessages.length;
                      });

                      return _buildMessagesList(nonReactionMessages);
                      },
                    ),
                  ),
                ),
                // ── Message input bar (or blocked banner) ───────────
                if (_isBlocked || _isBlockedByContact)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: c.surfaceAlt,
                      border: Border(
                        top: BorderSide(color: c.divider, width: 1),
                      ),
                    ),
                    child: SafeArea(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.block_rounded, color: c.textLow, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _isBlocked
                                ? 'You blocked this contact'
                                : 'You can\'t send messages to this contact',
                            style: GoogleFonts.poppins(
                              color: c.textMid,
                              fontSize: 13,
                            ),
                          ),
                          if (_isBlocked) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () async {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(widget.currentUserId)
                                    .update({
                                  'blockedUsers': FieldValue.arrayRemove(
                                      [widget.contact.id]),
                                });
                                await _checkBlockStatus();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${widget.contact.name} unblocked'),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                'Unblock',
                                style: GoogleFonts.poppins(
                                  color: c.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                  _buildMessageInputBar(c),
              ],
            ),
    );
  }

  /// The message input bar — text field + attachment + send/mic button.
  Widget _buildMessageInputBar(AppThemeColors c) {
    final isRecording = _voiceRecorder.isRecording;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(
          top: BorderSide(color: c.divider, width: 1),
        ),
      ),
      child: SafeArea(
        child: isRecording ? _buildRecordingBar(c) : _buildNormalInputBar(c),
      ),
    );
  }

  /// Normal input: attach + sleek pill text field with integrated mic/send (Stitch Design).
  Widget _buildNormalInputBar(AppThemeColors c) {
    const darkPillBg = Color(0xFF141624);
    const darkPillBorder = Color(0xFF24273D);

    // The bar was a bare Padding > Row with no slot for anything above it. The
    // Column adds one for the reply strip and the composer preview card, both
    // of which sit between the divider and the pill.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_editing != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, top: 6),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              decoration: BoxDecoration(
                color: c.primaryLt,
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  left: BorderSide(color: c.primary, width: 3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_rounded, size: 15, color: c.primaryDk),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Editing message',
                          style: GoogleFonts.poppins(
                            color: c.primaryDk,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          // The original, so they can see what they are
                          // changing it from once the field holds the new text.
                          _editing!.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: c.textMid,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 18, color: c.textMid),
                    onPressed: _cancelEdit,
                  ),
                ],
              ),
            ),
          ),
        if (_replyTo != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, top: 6),
            child: ReplyQuoteCard(
              senderName: _replyTo!.senderId == widget.currentUserId
                  ? 'You'
                  : widget.contact.name,
              text: _replySnippet(_replyTo),
              type: _replyTo!.type.name,
              localThumbPath: _replyTo!.localFilePath,
              isMe: false,
              onClose: () => setState(() => _replyTo = null),
            ),
          ),
        if (_showComposerPreview)
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, top: 6),
            child: LinkPreviewCard(
              url: _pendingPreview!.url,
              // Keyed by URL, not just "composer": the cache returns whatever
              // is stored under the key, so a fixed key would redraw the
              // previous link's thumbnail when the user edits the URL.
              cacheKey: 'composer:${_pendingPreview!.url}',
              title: _pendingPreview!.title,
              description: _pendingPreview!.description,
              siteName: _pendingPreview!.siteName,
              imageBase64: _pendingPreview!.imageBase64,
              isMe: false,
              onClose: () => setState(() => _linkPreviewSuppressed = true),
            ),
          ),
        if (_isSendingVoice)
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    // Determinate once real bytes flow; indeterminate before
                    // (recording hand-off / offline mesh, which has no %).
                    value: _voiceUploadProgress,
                    strokeWidth: 2,
                    color: c.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.mic_rounded, size: 16, color: c.primary),
                const SizedBox(width: 4),
                Text(
                  _voiceUploadProgress == null
                      ? 'Sending voice note…'
                      : 'Sending voice note… ${(_voiceUploadProgress! * 100).round()}%',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: c.textMid,
                  ),
                ),
              ],
            ),
          ),
        _buildComposerRow(c, darkPillBg, darkPillBorder),
      ],
    );
  }

  Widget _buildComposerRow(
      AppThemeColors c, Color darkPillBg, Color darkPillBorder) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Attachment Paperclip
          // Attachment Paperclip. One button for photo, video *and* document —
          // tapping it opens a chooser sheet; while any of them is uploading it
          // becomes the shared progress ring. Only one can ever be in flight
          // (the sheet is unreachable behind the ring), so the composer reads
          // whichever progress is non-null.
          (_isUploadingImage || _isUploadingVideo || _isUploadingDocument)
              ? Padding(
                  padding: const EdgeInsets.all(8),
                  child: (_imageUploadProgress ??
                              _videoUploadProgress ??
                              _documentUploadProgress) ==
                          null
                      // Compression, document encryption, and the offline mesh
                      // path have no byte progress — show an honest
                      // indeterminate spinner rather than a bogus "0%".
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: c.primary),
                        )
                      : UploadProgressRing(
                          progress: (_imageUploadProgress ??
                              _videoUploadProgress ??
                              _documentUploadProgress)!,
                          size: 24,
                          // Keep the spinner visible through the ring's reveal
                          // delay so a fast upload never flashes back to idle.
                          placeholder: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: c.primary),
                          ),
                        ),
                )
              : IconButton(
                  icon: NewFeatureDot(
                    anchor: NewFeatureAnchor.chatAttachment,
                    // The paperclip is a narrow glyph in a wide box, same as
                    // the overflow ⋮ — without the nudge the dot lands on the
                    // clip's head instead of beside it.
                    offset: NewFeatureDot.narrowGlyph,
                    child: Icon(Icons.attach_file_rounded,
                        color: c.isDark ? Colors.white70 : c.textMid, size: 24),
                  ),
                  onPressed: _showAttachmentSheet,
                ),
          const SizedBox(width: 4),

          // Integrated Input Pill Container (Stitch Design)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: c.isDark ? darkPillBg : c.surfaceAlt,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: c.isDark ? darkPillBorder : c.border,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _composerFocus,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: c.isDark ? Colors.white : c.textHigh,
                      ).copyWith(
                        fontFamilyFallback: const [
                          '',
                          'Noto Color Emoji',
                          'Apple Color Emoji',
                          'Segoe UI Emoji',
                          'sans-serif',
                        ],
                      ),
                      maxLines: 5,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        hintStyle: GoogleFonts.poppins(
                          color: c.isDark ? Colors.white38 : c.textLow,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),

                  // Mic / Send Icon inside the Pill
                  if (_hasText || _isSending)
                    GestureDetector(
                      onTap: _isSending ? null : _sendMessage,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                Icons.send_rounded,
                                color: c.primary,
                                size: 22,
                              ),
                      ),
                    )
                  else
                    GestureDetector(
                      onLongPressStart: (_) => _startVoiceRecording(),
                      onLongPressEnd: (_) => _stopVoiceRecording(),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Icon(
                          Icons.mic_none_rounded,
                          color: c.isDark ? Colors.white70 : c.textMid,
                          size: 22,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Optional Screen Share shortcut
          const SizedBox(width: 4),
          IconButton(
            icon: _startingScreenShare
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          c.isDark ? Colors.white54 : c.textMid),
                    ),
                  )
                : Icon(Icons.screen_share_rounded,
                    color: c.isDark ? Colors.white54 : c.textMid, size: 20),
            tooltip: 'Share screen',
            onPressed: _startingScreenShare
                ? null
                : () {
                    if (PremiumGate.checkAndPrompt(
                      context,
                      featureName: 'Screen Sharing',
                      featureIcon: Icons.screen_share_rounded,
                      description:
                          'Share your screen live during chats with GupShupGo Pro.',
                    )) {
                      _initiateScreenShare();
                    }
                  },
          ),
        ],
      ),
    );
  }

  /// Recording-active bar: pulsing dot, timer, slide-to-cancel, stop button.
  Widget _buildRecordingBar(AppThemeColors c) {
    return Row(
      children: [
        // Pulsing red dot
        _buildPulsingDot(c),
        const SizedBox(width: 8),
        // Duration counter. Capped recordings show `elapsed / cap` so the
        // auto-stop-and-send at the limit is never a surprise; uncapped ones
        // (Pro) show a plain stopwatch with nothing to count down to.
        ListenableBuilder(
          listenable: _voiceRecorder,
          builder: (context, _) {
            final cap = _voiceRecorder.maxDurationSec;
            final elapsed =
                VoiceRecorderService.formatDuration(_voiceRecorder.elapsed);
            return Text(
              cap == null
                  ? elapsed
                  : '$elapsed / '
                      '${VoiceRecorderService.formatDuration(Duration(seconds: cap))}',
              style: GoogleFonts.poppins(
                color: c.textHigh,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            );
          },
        ),
        const Spacer(),
        // Slide-to-cancel hint
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chevron_left_rounded, color: c.textLow, size: 18),
            Text(
              'Slide to cancel',
              style: GoogleFonts.poppins(color: c.textLow, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(width: 12),
        // Cancel button
        GestureDetector(
          onTap: _cancelVoiceRecording,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.error.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.delete_outline_rounded, color: c.error, size: 18),
          ),
        ),
        const SizedBox(width: 8),
        // Stop & send button
        GestureDetector(
          onTap: _stopVoiceRecording,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.send_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPulsingDot(AppThemeColors c) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: c.error,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        // Restart the animation by rebuilding
        if (_voiceRecorder.isRecording && mounted) setState(() {});
      },
    );
  }

  // ─── Voice recording handlers ─────────────────────────────────────

  Future<void> _startVoiceRecording() async {
    if (_isBlocked || _isBlockedByContact) return;
    HapticFeedback.mediumImpact();

    // Read the cap before the await: `_voiceRecorder.startRecording` awaits a
    // permission prompt, and touching `context` after that is exactly what
    // `use_build_context_synchronously` warns about.
    //
    // `maxVoiceDurationSec` is `null` for Pro — and also for everyone while
    // `pro_enabled` is off, because capping a feature that is unlimited today
    // while the upgrade path is hidden would strip a capability with no way to
    // buy it back. See `SubscriptionProvider.isProUnlocked`.
    final cap = context.read<SubscriptionProvider>().maxVoiceDurationSec;

    await _voiceRecorder.startRecording(
      maxDurationSec: cap,
      onLimitReached: cap == null ? null : () => _onVoiceLimitReached(cap),
    );
    if (mounted) setState(() {});
  }

  /// Fired once by the recorder's ticker when a capped recording hits its limit.
  ///
  /// Stops **and sends** rather than discarding: the user has just spoken for two
  /// minutes, and throwing that away to teach them about a limit would be the
  /// wrong trade. The snackbar explains why the recording ended on its own.
  void _onVoiceLimitReached(int capSeconds) {
    HapticFeedback.mediumImpact();
    _stopVoiceRecording();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Voice messages are limited to '
          '${VoiceRecorderService.formatDuration(Duration(seconds: capSeconds))}'
          ' — sent what you recorded.',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _stopVoiceRecording() async {
    if (!_voiceRecorder.isRecording) return;

    final durationSeconds = _voiceRecorder.elapsed.inSeconds;
    final path = await _voiceRecorder.stopRecording();
    if (mounted) setState(() {});

    if (path == null || durationSeconds < 1) return; // too short

    await _sendVoiceMessage(path, durationSeconds);
  }

  Future<void> _cancelVoiceRecording() async {
    HapticFeedback.heavyImpact();
    await _voiceRecorder.cancelRecording();
    if (mounted) setState(() {});
  }

  Future<void> _sendVoiceMessage(String filePath, int durationSeconds) async {
    setState(() => _isSendingVoice = true);

    try {
      final connectivity =
          Provider.of<ConnectivityProvider>(context, listen: false);

      if (!connectivity.isOnline) {
        // ── Offline: send via mesh network ──────────────────────────
        try {
          final meshService =
              Provider.of<MeshNetworkService>(context, listen: false);
          final meshMsg = await meshService.sendAudioViaMesh(
            receiverId: widget.contact.id,
            filePath: filePath,
            durationSeconds: durationSeconds,
            senderName: widget.currentUserName,
          );
          setState(() => _meshMessages.add(meshMsg));
          _scrollToBottom();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'No internet & mesh unavailable. Voice note not sent.')),
            );
          }
        }
      } else {
        // ── Online: upload to Firebase Storage ──────────────────────
        final chatRoomId =
            _chatService.getChatRoomId(widget.currentUserId, widget.contact.id);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_voice.m4a';
        final ref = FirebaseStorage.instance
            .ref()
            .child('chat_audio/$chatRoomId/$fileName');

        final metadata = SettableMetadata(contentType: 'audio/m4a');
        // Real byte progress in the "Sending voice note…" indicator. Stays
        // null (→ indeterminate spinner) until the first non-zero fraction, so
        // a short clip shows a spinner rather than a frozen "0%". The finally
        // resets to null, so a retry restarts here cleanly.
        final uploadTask = ref.putFile(File(filePath), metadata);
        _voiceUploadSub?.cancel();
        _voiceUploadSub = uploadProgress(uploadTask).listen(
          (p) {
            if (mounted) setState(() => _voiceUploadProgress = p);
          },
          // Handled by the awaited task + outer catch/finally; swallow the
          // duplicate stream error.
          onError: (Object _) {},
          cancelOnError: true,
        );
        await uploadTask;
        final audioUrl = await ref.getDownloadURL();

        await _chatService.sendMessage(
          senderId: widget.currentUserId,
          receiverId: widget.contact.id,
          text: '🎤 Voice message',
          senderName: widget.currentUserName,
          type: MessageType.audio,
          mediaUrl: audioUrl,
          audioDuration: durationSeconds,
          localFilePath: filePath,
        );

        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send voice message: $e')),
        );
      }
    } finally {
      // Reset progress to null so a failure/cancel/leave never leaves the
      // indicator stuck at a partial percentage.
      _voiceUploadSub?.cancel();
      _voiceUploadSub = null;
      if (mounted) {
        setState(() {
          _isSendingVoice = false;
          _voiceUploadProgress = null;
        });
      }
    }
  }

  Widget _buildTypingBubble() {
    final c = _messageColors;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 16, bottom: 4, top: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: _chatTheme.receivedOf(c),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const _TypingDotsIndicator(),
      ),
    );
  }

  // ─── Menu action handlers ──────────────────────────────────────────

  void _onMenuItemSelected(String value) {
    switch (value) {
      case 'contact info':
        _showContactInfo();
        break;
      case 'search':
        // The row is old; what it reaches is not. See the registry note on
        // [NewFeature.chatSearch].
        WhatsNewService.instance.markSeen(NewFeature.chatSearch);
        setState(() => _isSearchMode = true);
        break;
      case 'chat theme':
        // Visiting is what clears the badge — merely opening this menu does not.
        WhatsNewService.instance.markSeen(NewFeature.chatThemes);
        ChatThemeSheet.show(
          context,
          chatRoomId: _chatRoomId,
          contactName: widget.contact.name,
        );
        break;
      case 'export chat':
        WhatsNewService.instance.markSeen(NewFeature.chatExport);
        _exportChat();
        break;
      case 'mute notifications':
        _toggleMute();
        break;
      case 'block contact':
        _blockContact();
        break;
    }
  }

  // ─── Contact info bottom sheet ─────────────────────────────────────
  void _showContactInfo() {
    _userService.getUserById(widget.contact.id).then((user) {
      if (!mounted || user == null) return;

      final c = AppThemeColors.of(context);

      final avatarUrl = user.photoUrl ??
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}&background=4CAF50&color=fff&size=256';

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: c.textLow,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                CircleAvatar(
                  radius: 48,
                  backgroundImage: avatarImage(avatarUrl, radius: 48),
                  backgroundColor: c.primaryLt,
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: c.textHigh),
                ),
                const SizedBox(height: 4),
                Text(
                  user.about ?? 'Hey there! I am using GupShupGo.',
                  style: GoogleFonts.poppins(fontSize: 13, color: c.textMid),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Divider(),
                if (user.phoneNumber != null)
                  ListTile(
                    leading: Icon(Icons.phone_outlined, color: c.primary),
                    title: Text(user.phoneNumber!,
                        style: GoogleFonts.poppins(fontSize: 14)),
                    subtitle: Text('Phone',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: c.textMid)),
                  ),
                if (user.email != null)
                  ListTile(
                    leading:
                        const Icon(Icons.email_outlined, color: Colors.orange),
                    title: Text(user.email!,
                        style: GoogleFonts.poppins(fontSize: 14)),
                    subtitle: Text('Email',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: c.textMid)),
                  ),
                ListTile(
                  leading: Icon(
                    user.isOnline ? Icons.circle : Icons.circle_outlined,
                    color: user.isOnline ? c.online : c.textLow,
                    size: 16,
                  ),
                  title: Text(
                    user.isOnline ? 'Online' : 'Offline',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  subtitle: Text('Moment',
                      style:
                          GoogleFonts.poppins(fontSize: 11, color: c.textMid)),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ─── Mute / Unmute ─────────────────────────────────────────────────
  void _toggleMute() {
    final chatRoomId =
        _chatService.getChatRoomId(widget.currentUserId, widget.contact.id);
    _settingsService.toggleMuteChat(chatRoomId);
    setState(() => _isMuted = !_isMuted);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(_isMuted ? 'Notifications muted' : 'Notifications unmuted'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── Block contact ─────────────────────────────────────────────────
  Future<void> _blockContact() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Block ${widget.contact.name}?'),
        content: const Text(
          'Blocked contacts cannot send you messages or call you. '
          'You can unblock them from Settings → Privacy → Blocked contacts.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Block', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .update({
        'blockedUsers': FieldValue.arrayUnion([widget.contact.id]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.contact.name} blocked')),
        );
        Navigator.of(context).pop(); // Exit the chat
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to block: $e')),
        );
      }
    }
  }

  // ─── Chat export ───────────────────────────────────────────────────
  /// Renders this conversation to a file and hands it to the OS share sheet.
  ///
  /// The heavy lifting — and the reasoning about why the export is built from the
  /// local plaintext cache and never from a decrypt pass — lives in
  /// [ChatExportService]. This method is only the gate, the format choice, the
  /// progress feedback and the share.
  ///
  /// The share sheet is also the print path: Android's own print service appears
  /// in it for a PDF, so "print this chat" needs no dialog of our own.
  Future<void> _exportChat() async {
    if (_isExporting) return;
    if (!PremiumGate.checkAndPrompt(
      context,
      featureName: 'Chat Export',
      featureIcon: Icons.ios_share_rounded,
      description: 'Save this conversation as a PDF you can keep, print or '
          'share — or as a plain-text transcript.',
    )) {
      return;
    }

    final format = await ExportFormatSheet.show(context);
    if (format == null || !mounted) return;

    // Captured after the sheet closes but before the export await: the messenger
    // is needed again afterwards, and reaching back through `context` there is
    // what `use_build_context_synchronously` exists to catch.
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isExporting = true);
    messenger.showSnackBar(
      SnackBar(
        // A PDF with photos in it takes noticeably longer than writing a few KB
        // of text, so the two get different waits rather than one that is either
        // a lie or a flicker.
        content: Text(
          format == ExportFormat.pdf
              ? 'Building your PDF…'
              : 'Preparing export…',
        ),
        duration: Duration(seconds: format == ExportFormat.pdf ? 3 : 1),
      ),
    );

    try {
      final isPdf = format == ExportFormat.pdf;
      final file = isPdf
          ? await ChatExportService.exportChatPdf(
              chatRoomId: _chatRoomId,
              selfUserId: widget.currentUserId,
              contactName: widget.contact.name,
            )
          : await ChatExportService.exportChat(
              chatRoomId: _chatRoomId,
              selfUserId: widget.currentUserId,
              contactName: widget.contact.name,
            );
      if (!mounted) return;
      if (file == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Nothing to export in this chat yet')),
        );
        return;
      }
      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType: isPdf ? 'application/pdf' : 'text/plain',
          ),
        ],
        subject: 'GupShupGo chat with ${widget.contact.name}',
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Could not export chat: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ─── Image attachment ──────────────────────────────────────────────
  Future<void> _pickAndSendImage({bool viewOnce = false}) async {
    AppHaptics.tap();
    if (_isBlocked || _isBlockedByContact) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send images to this contact')),
      );
      return;
    }

    // Read before the picker await, both for the lint and because the picker's
    // own re-encode has to know the tier.
    final proMediaQuality =
        context.read<SubscriptionProvider>().hasProMediaQuality;

    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        // The picker re-encodes at this quality *before* ImageCompressor ever
        // sees the file, so it is a hard upstream ceiling: leaving it at 70
        // would make the Pro tier's quality-90 pass re-encode an
        // already-degraded image, spending bytes for no visible gain. Pro skips
        // the picker's pass (`null` = no re-encode) so `compressForChat` is the
        // only place quality is decided. Free keeps 70, exactly as before.
        imageQuality: proMediaQuality ? null : 70,
      );
      if (picked == null) return;

      setState(() => _isUploadingImage = true);

      final connectivity =
          Provider.of<ConnectivityProvider>(context, listen: false);

      if (!connectivity.isOnline) {
        // ── Offline: send via mesh network ──────────────────────────
        // ...unless this is a view-once send. Its deletion model is the
        // destruction of a key to a blob in Storage, and the mesh path has
        // neither: it streams the plaintext image peer-to-peer, so there would
        // be nothing to destroy and the promise on the switch would be a lie.
        if (viewOnce) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'View once needs a connection — it can\'t be sent over '
                      'a nearby link.')),
            );
          }
          return;
        }
        try {
          final meshService =
              Provider.of<MeshNetworkService>(context, listen: false);
          final meshMsg = await meshService.sendImageViaMesh(
            receiverId: widget.contact.id,
            filePath: picked.path,
            senderName: widget.currentUserName,
          );
          setState(() => _meshMessages.add(meshMsg));
          _scrollToBottom();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('No internet & mesh unavailable. Image not sent.')),
            );
          }
        }
      } else {
        // ── Online: upload to Firebase Storage ──────────────────────
        final chatRoomId =
            _chatService.getChatRoomId(widget.currentUserId, widget.contact.id);
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
        final ref = FirebaseStorage.instance
            .ref()
            .child('chat_images/$chatRoomId/$fileName');

        // Compress before upload — 5 MB → ~250 KB JPEG, cuts upload from
        // 10-20s on mobile data to ~1s with no visible quality loss.
        //
        // Pro gets a higher-resolution, higher-quality tier (the free numbers
        // are unchanged). `isPro` is masked by the `pro_enabled` flag, so with
        // the flag off everyone keeps today's compression and storage costs
        // don't move.
        final compressed = await ImageCompressor.compressForChat(
          File(picked.path),
          pro: proMediaQuality,
        );

        if (viewOnce) {
          // ── View once: encrypted upload, no plaintext URL ──────────
          // Routed through EncryptedMediaService instead of the plaintext
          // putFile the ordinary path uses, because **key destruction is the
          // deletion mechanism**: on open the receiver purges every copy of
          // `mediaKey`, and what's left in Storage is AES-GCM ciphertext nobody
          // holds a key for. A plaintext upload would leave a readable object
          // behind that any authenticated caller with the URL could still fetch.
          //
          // `chat_images/` is unchanged as the path — that rule block already
          // accepts `application/octet-stream`, so no storage-rules change is
          // needed — but the object name is opaque, like a document's.
          final bundle = await EncryptedMediaService().encryptAndUpload(
            file: compressed,
            storagePath: 'chat_images/$chatRoomId/${_opaqueObjectName()}',
            onProgress: (p) {
              if (mounted) setState(() => _imageUploadProgress = p);
            },
          );

          await _chatService.sendMessage(
            senderId: widget.currentUserId,
            receiverId: widget.contact.id,
            text: '📷 Photo',
            senderName: widget.currentUserName,
            type: MessageType.image,
            mediaKey: bundle.toMap(),
            viewOnce: true,
            // Deliberately no `mediaUrl` and no `localFilePath`. The URL lives
            // inside the bundle, and keeping a local plaintext copy would let
            // the *sender's* own bubble re-render the image forever — the one
            // thing "view once" is supposed to rule out on both ends.
          );

          _scrollToBottom();
          return;
        }

        // Kick off the upload and surface its real byte progress at the
        // paperclip (WhatsApp-style %). Progress stays null (→ indeterminate
        // spinner) until the first non-zero byte fraction arrives, so a small
        // one-chunk upload shows a brief spinner rather than a frozen "0%".
        // The finally resets it to null, so a retry cleanly restarts here.
        final uploadTask = ref.putFile(compressed);
        _imageUploadSub?.cancel();
        _imageUploadSub = uploadProgress(uploadTask).listen(
          (p) {
            if (mounted) setState(() => _imageUploadProgress = p);
          },
          // A failure/cancel is handled by the awaited task below and the
          // outer catch/finally; swallow the duplicate stream error so it
          // isn't an unhandled async exception.
          onError: (Object _) {},
          cancelOnError: true,
        );
        await uploadTask;
        final imageUrl = await ref.getDownloadURL();

        await _chatService.sendMessage(
          senderId: widget.currentUserId,
          receiverId: widget.contact.id,
          text: '📷 Photo',
          senderName: widget.currentUserName,
          type: MessageType.image,
          mediaUrl: imageUrl,
          localFilePath: compressed.path,
        );

        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send image: $e')),
        );
      }
    } finally {
      // Reset progress to null (not a stale %) so failure, cancel, or leaving
      // mid-upload never strands the paperclip at e.g. 37%.
      _imageUploadSub?.cancel();
      _imageUploadSub = null;
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
          _imageUploadProgress = null;
        });
      }
    }
  }

  // ─── Attachment chooser ────────────────────────────────────────────
  /// The paperclip's chooser: Photo, Video or Document. Mirrors the Status media
  /// picker so the two "attach media" surfaces feel like one app. Each tile pops
  /// the sheet before running its picker — the sheet has to be gone before the
  /// OS gallery UI takes over.
  void _showAttachmentSheet() {
    AppHaptics.tap();
    if (_isBlocked || _isBlockedByContact) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send media to this contact')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final c = AppThemeColors.of(sheetContext);
        // View once is **armed here, before the picker**, rather than confirmed
        // on a preview screen after it. There is no preview step for photo or
        // video in this app — both pick and send in one shot — and adding one
        // just to host this switch would put a confirmation in front of every
        // ordinary photo send to serve the rare case. Arming first keeps the
        // common path at its current zero taps and still makes the choice
        // explicit and reversible before any bytes are read.
        //
        // Local to the sheet, so it resets every time: a mode this destructive
        // must never be sticky across sends.
        bool viewOnce = false;
        return StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(sheetContext).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Share',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: c.online.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.photo_library_rounded, color: c.online),
                    ),
                    title: const Text('Photo',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(viewOnce
                        ? 'Opens once, then it\'s gone'
                        : 'Choose an image from your gallery'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _pickAndSendImage(viewOnce: viewOnce);
                    },
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.video_library_rounded,
                          color: Colors.orange),
                    ),
                    title: const Text('Video',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(viewOnce
                        ? 'Plays once, then it\'s gone'
                        : 'Choose a video from your gallery'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _pickAndSendVideo(viewOnce: viewOnce);
                    },
                  ),
                  // Documents and pins can't be view-once: the mechanism is the
                  // destruction of a media key, and neither has one to destroy
                  // (a pin carries no media at all). Disabled rather than hidden
                  // so the sheet doesn't reshuffle under the user's thumb.
                  ListTile(
                    enabled: !viewOnce,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.indigo
                            .withOpacity(viewOnce ? 0.04 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.insert_drive_file_rounded,
                          color: Colors.indigo
                              .withValues(alpha: viewOnce ? 0.4 : 1)),
                    ),
                    title: const Row(
                      children: [
                        Text('Document',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        NewFeatureChip(featureId: NewFeature.documents),
                      ],
                    ),
                    subtitle: Text(viewOnce
                        ? 'Not available for view once'
                        : 'PDF, Office file, archive — sent as-is'),
                    onTap: () {
                      WhatsNewService.instance.markSeen(NewFeature.documents);
                      Navigator.pop(sheetContext);
                      _pickAndSendDocument();
                    },
                  ),
                  ListTile(
                    enabled: !viewOnce,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent
                            .withOpacity(viewOnce ? 0.04 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.location_on_rounded,
                          color: Colors.redAccent
                              .withValues(alpha: viewOnce ? 0.4 : 1)),
                    ),
                    title: const Row(
                      children: [
                        Text('Location',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        NewFeatureChip(featureId: NewFeature.locationShare),
                      ],
                    ),
                    subtitle: Text(viewOnce
                        ? 'Not available for view once'
                        : 'Share your current location'),
                    onTap: () {
                      WhatsNewService.instance
                          .markSeen(NewFeature.locationShare);
                      Navigator.pop(sheetContext);
                      _pickAndSendLocation();
                    },
                  ),
                  const Divider(height: 20, indent: 16, endIndent: 16),
                  SwitchListTile(
                    value: viewOnce,
                    onChanged: (v) {
                      // Turning it *on* is visiting it; turning it back off is
                      // not, and would clear the badge for a user who only
                      // brushed the switch.
                      if (v) {
                        WhatsNewService.instance.markSeen(NewFeature.viewOnce);
                      }
                      setSheetState(() => viewOnce = v);
                    },
                    secondary: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: c.primary.withOpacity(viewOnce ? 0.16 : 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        viewOnce
                            ? Icons.lock_clock_rounded
                            : Icons.timer_outlined,
                        color: c.primary,
                      ),
                    ),
                    title: const Row(
                      children: [
                        Text('View once',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        NewFeatureChip(featureId: NewFeature.viewOnce),
                      ],
                    ),
                    // Worded to promise only what the mechanism delivers. The
                    // key really is destroyed on open — but a receiver can still
                    // point another camera at the screen, and on iOS they can
                    // screenshot (no FLAG_SECURE equivalent). Saying "can't be
                    // saved" would be a guarantee we cannot keep.
                    subtitle: Text(
                      viewOnce
                          ? 'Encrypted, and the key is destroyed when they open it'
                          : 'Photo or video disappears after it\'s opened',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Video attachment ──────────────────────────────────────────────
  /// Pick a gallery video and send it. Deliberately parallel to
  /// [_pickAndSendImage], with three differences that all follow from the
  /// design decisions for chat video:
  ///
  ///  * **Online only.** There is no `sendVideoViaMesh`, so a video needs a real
  ///    connection — checked *before* the picker so the user learns why up front.
  ///  * **No compression.** `image_picker` hands back the raw capture and nothing
  ///    in this app re-encodes video, so the only guard is a byte ceiling
  ///    ([_kMaxChatVideoBytes]); the clip uploads as-is to `chat_videos/`.
  ///  * **Duration on the bubble.** The clip length is probed locally and carried
  ///    in the (already end-to-end-encrypted, already-serialized) `audioDuration`
  ///    field so the receiver's placeholder can show mm:ss with no schema change.
  ///    A video message never reaches the voice-note UI, so nothing else reads it.
  Future<void> _pickAndSendVideo({bool viewOnce = false}) async {
    AppHaptics.tap();
    if (_isBlocked || _isBlockedByContact) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send videos to this contact')),
      );
      return;
    }

    // The mesh has a tighter cap than the online path — a P2P clip is streamed
    // peer-to-peer with no server compression and no progress bar — so the
    // connectivity read decides the ceiling, but either way we branch after the
    // pick rather than blocking the picker.
    final connectivity =
        Provider.of<ConnectivityProvider>(context, listen: false);
    final isOnline = connectivity.isOnline;

    try {
      final XFile? picked =
          await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (picked == null) return;

      final file = File(picked.path);

      // Size guard first: raw capture with no compressor, so bytes are the real
      // ceiling. Checked on a `stat` before the duration probe so a huge pick is
      // rejected without spinning up a decoder.
      final bytes = await file.length();
      final maxBytes = isOnline ? _kMaxChatVideoBytes : kMaxMeshVideoBytes;
      if (bytes > maxBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'This video is ${_formatMb(bytes)}. The most a '
                '${isOnline ? 'chat' : 'nearby'} video can carry is '
                '${_formatMb(maxBytes)} — try a shorter clip.',
              ),
            ),
          );
        }
        return;
      }

      setState(() => _isUploadingVideo = true);

      if (!isOnline) {
        // ── Offline: send via the mesh ──────────────────────────────
        // View once is online-only, for the reason given in
        // [_pickAndSendImage]: the mesh streams plaintext peer-to-peer, so
        // there would be no key to destroy.
        if (viewOnce) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'View once needs a connection — it can\'t be sent over '
                      'a nearby link.')),
            );
          }
          return;
        }
        // The clip streams on the P2P FILE channel; a small poster + duration
        // ride the metadata packet (both optional — failure just drops the
        // preview, never the send).
        try {
          final meshService =
              Provider.of<MeshNetworkService>(context, listen: false);
          final poster = await generateMeshVideoPoster(picked.path);
          final durSec = await probeMeshVideoDurationSeconds(picked.path);
          final meshMsg = await meshService.sendVideoViaMesh(
            receiverId: widget.contact.id,
            filePath: picked.path,
            durationSeconds: durSec,
            thumbnailBase64: poster,
            senderName: widget.currentUserName,
          );
          setState(() => _meshMessages.add(meshMsg));
          _scrollToBottom();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('No internet & mesh unavailable. Video not sent.')),
            );
          }
        }
        return;
      }

      // ── Online: upload to Firebase Storage ──────────────────────
      // Length for the bubble label. A probe failure just drops the duration
      // from the placeholder; it never blocks the send.
      final duration = await _probeVideoDuration(file);

      final chatRoomId =
          _chatService.getChatRoomId(widget.currentUserId, widget.contact.id);

      if (viewOnce) {
        // ── View once: encrypted upload, no plaintext URL ────────────
        // Same reasoning as the image path: the key is the deletion mechanism,
        // so the clip has to be ciphertext in Storage. `chat_videos/` already
        // accepts `application/octet-stream`, so the rule block is unchanged;
        // only the object name becomes opaque.
        //
        // No poster frame is generated, and that is the point — a thumbnail of
        // a view-once video is a still of the thing that's meant to vanish, and
        // it would ride the payload in the clear-to-the-receiver `videoThumbnailBase64`
        // field that [MessageModel.asViewOnceConsumed] deliberately drops.
        final bundle = await EncryptedMediaService().encryptAndUpload(
          file: file,
          storagePath: 'chat_videos/$chatRoomId/${_opaqueObjectName()}',
          onProgress: (p) {
            if (mounted) setState(() => _videoUploadProgress = p);
          },
        );

        await _chatService.sendMessage(
          senderId: widget.currentUserId,
          receiverId: widget.contact.id,
          text: '🎬 Video',
          senderName: widget.currentUserName,
          type: MessageType.video,
          mediaKey: bundle.toMap(),
          viewOnce: true,
          audioDuration: duration?.inSeconds,
        );

        _scrollToBottom();
        return;
      }

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      final ref = FirebaseStorage.instance
          .ref()
          .child('chat_videos/$chatRoomId/$fileName');

      // Upload raw and surface real byte progress at the paperclip — same
      // WhatsApp-style % convention as the image path (null → indeterminate
      // spinner until the first non-zero fraction; finally resets it).
      final uploadTask = ref.putFile(file);
      _videoUploadSub?.cancel();
      _videoUploadSub = uploadProgress(uploadTask).listen(
        (p) {
          if (mounted) setState(() => _videoUploadProgress = p);
        },
        onError: (Object _) {},
        cancelOnError: true,
      );

      // Extract the first-frame poster while the clip uploads — the two run
      // concurrently so the thumbnail costs no extra wall-clock. A failure just
      // yields null (the bubble falls back to the film-glyph placeholder); it
      // never blocks the send. Awaited below, after the upload, so both are done
      // before the message commits.
      final thumbFuture = _generateVideoThumbnail(file);

      await uploadTask;
      final videoUrl = await ref.getDownloadURL();
      final thumbB64 = await thumbFuture;

      await _chatService.sendMessage(
        senderId: widget.currentUserId,
        receiverId: widget.contact.id,
        text: '🎬 Video',
        senderName: widget.currentUserName,
        type: MessageType.video,
        mediaUrl: videoUrl,
        localFilePath: file.path,
        // Reused field — carries the clip length, not audio. See the doc above.
        audioDuration: duration?.inSeconds,
        // Base64 JPEG poster; rides inline in the encrypted envelope so the
        // receiver renders it before downloading the clip. See
        // _generateVideoThumbnail.
        videoThumbnailBase64: thumbB64,
      );

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send video: $e')),
        );
      }
    } finally {
      // Reset to null (not a stale %) so a failure or cancel never strands the
      // paperclip mid-percentage.
      _videoUploadSub?.cancel();
      _videoUploadSub = null;
      if (mounted) {
        setState(() {
          _isUploadingVideo = false;
          _videoUploadProgress = null;
        });
      }
    }
  }

  // ─── Document attachment ───────────────────────────────────────────
  /// Pick any file and send it, encrypted, as a [MessageType.document].
  ///
  /// This is the only chat attachment path that goes through
  /// [EncryptedMediaService] rather than a raw `putFile` to Storage. Chat
  /// images and videos upload in the clear (only the *URL* is inside the Signal
  /// envelope, and the read rule is `request.auth != null`, so any
  /// authenticated user holding a URL can fetch the bytes). Documents are
  /// resumes, tickets, bank statements and contracts; that trade-off isn't
  /// acceptable for them, so the bytes are AES-256-GCM sealed on-device and the
  /// key rides inside the encrypted payload as `mediaKey`.
  ///
  /// Four consequences follow from that choice, all of them deliberate:
  ///
  ///  * **Encryption happens where the network is.** Online, the file is sealed
  ///    here and uploaded before the message is sent. Offline it goes over the
  ///    mesh in the clear on a direct peer-to-peer link — there is no server in
  ///    the path to protect it from — and
  ///    [MeshNetworkService._uploadEncryptedLocalFile] seals it on the way to
  ///    Storage when connectivity returns. Either way the blob that lands in
  ///    `chat_documents/` is ciphertext.
  ///  * **No compression, ever.** Sending the original bytes *is* the feature —
  ///    it's also the workaround for sending a photo without gallery
  ///    re-encoding. The only guard is the [_kMaxChatVideoBytes] ceiling, shared
  ///    with video for the same reason: encrypt-then-upload holds roughly 3× the
  ///    file in heap.
  ///  * **The storage object is a UUID, not the filename.** The real name
  ///    travels only inside the encrypted `fileName` key, and the service forces
  ///    `application/octet-stream`, so the server can't tell a PDF from a ZIP.
  ///  * **`text` is set to the filename.** A v2 message's Firestore `text` is
  ///    `''` and an older build's `_parseMessageType` falls back to
  ///    [MessageType.text] on the unknown type — without this it would paint a
  ///    blank bubble. The same string doubles as the reply-quote snippet and the
  ///    notification preview.
  Future<void> _pickAndSendDocument() async {
    AppHaptics.tap();
    if (_isBlocked || _isBlockedByContact) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send files to this contact')),
      );
      return;
    }

    // The mesh carries documents too, on the same FILE channel the photo, voice
    // and video paths already use — so connectivity picks the ceiling and the
    // transport, rather than blocking the picker. The mesh cap is tighter for the
    // same reason the video one is: a P2P stream has no progress bar and no
    // resume.
    final connectivity =
        Provider.of<ConnectivityProvider>(context, listen: false);
    final isOnline = connectivity.isOnline;

    try {
      // `withData: false` keeps the picker from reading the whole file into
      // memory: we want the path and read it ourselves, once, inside the
      // service. On a 64 MB pick that difference is a copy we don't make.
      final result = await FilePicker.platform.pickFiles(withData: false);
      final picked = result?.files.single;
      final path = picked?.path;
      if (picked == null || path == null) return;

      final file = File(path);
      final bytes = await file.length();
      final maxBytes = isOnline ? _kMaxChatVideoBytes : kMaxMeshDocumentBytes;
      if (bytes > maxBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'This file is ${_formatMb(bytes)}. The most a '
                '${isOnline ? 'chat' : 'nearby'} file can '
                'carry is ${_formatMb(maxBytes)}.',
              ),
            ),
          );
        }
        return;
      }
      if (bytes == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('That file is empty.')),
          );
        }
        return;
      }

      setState(() {
        _isUploadingDocument = true;
        _documentUploadProgress = null;
      });

      if (!isOnline) {
        // ── Offline: hand it to the peer over the mesh ───────────────
        // Nothing is encrypted or uploaded here — there is no network to upload
        // to. The file streams plaintext on the P2P FILE channel and the message
        // is left `syncPending`; [MeshNetworkService] encrypts and uploads it to
        // `chat_documents/` when the connection returns.
        try {
          final meshService =
              Provider.of<MeshNetworkService>(context, listen: false);
          final meshMsg = await meshService.sendDocumentViaMesh(
            receiverId: widget.contact.id,
            filePath: path,
            fileName: picked.name,
            senderName: widget.currentUserName,
          );
          setState(() => _meshMessages.add(meshMsg));
          _scrollToBottom();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('No internet & mesh unavailable. File not sent.')),
            );
          }
        }
        return;
      }

      final chatRoomId =
          _chatService.getChatRoomId(widget.currentUserId, widget.contact.id);
      // Opaque object name. The real filename is payload-only; see the doc above.
      final objectName = _opaqueObjectName();

      final bundle = await EncryptedMediaService().encryptAndUpload(
        file: file,
        storagePath: 'chat_documents/$chatRoomId/$objectName',
        // Recorded inside the bundle for the receiver's benefit only — the
        // object itself is uploaded as application/octet-stream regardless.
        contentType: lookupMimeType(picked.name) ?? 'application/octet-stream',
        onProgress: (p) {
          if (mounted) setState(() => _documentUploadProgress = p);
        },
      );

      await _chatService.sendMessage(
        senderId: widget.currentUserId,
        receiverId: widget.contact.id,
        // Human-readable fallback for old clients; also the reply snippet and
        // the notification preview. See the doc above.
        text: picked.name,
        senderName: widget.currentUserName,
        type: MessageType.document,
        fileName: picked.name,
        mediaKey: bundle.toMap(),
        // Our own copy opens straight from the pick — no download, no decrypt.
        localFilePath: path,
      );

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send file: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingDocument = false;
          _documentUploadProgress = null;
        });
      }
    }
  }

  /// An opaque, unguessable Storage object name.
  ///
  /// Delegates to [EncryptedMediaService.opaqueObjectName] — the mesh service
  /// needs the same name for a document it reconciles after the fact, and two
  /// copies of a naming rule is two things to keep honest.
  static String _opaqueObjectName() => EncryptedMediaService.opaqueObjectName();

  // ─── Location attachment ───────────────────────────────────────────
  /// Fetch the current position and, after an explicit confirm, send it as a
  /// [MessageType.location] pin.
  ///
  /// A location message carries no media — just two doubles inside the
  /// encrypted payload — so it needs no Storage upload and rides the mesh
  /// transport for free, unlike a document. That also means no online guard.
  ///
  /// The acquire + confirm flow (permission, GPS fix, and the confirmation
  /// sheet that ensures the position is **never sent silently**) lives in the
  /// shared [pickLocationToShare] so the online and mesh transports can't drift
  /// apart. `text` is set to `📍 Location` so an older client that doesn't know
  /// the type renders that instead of a blank bubble, and it doubles as the
  /// reply snippet and notification preview.
  Future<void> _pickAndSendLocation() async {
    AppHaptics.tap();
    if (_isBlocked || _isBlockedByContact) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send location to this contact')),
      );
      return;
    }

    final pos = await pickLocationToShare(context);
    if (pos == null || !mounted) return;

    try {
      await _chatService.sendMessage(
        senderId: widget.currentUserId,
        receiverId: widget.contact.id,
        text: '📍 Location',
        senderName: widget.currentUserName,
        type: MessageType.location,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send location: $e')),
        );
      }
    }
  }

  /// Reads a video's duration for the bubble label, or null if it can't be
  /// determined. Mirrors the status screen's probe: an unreadable file yields
  /// null rather than blocking the send.
  Future<Duration?> _probeVideoDuration(File file) async {
    final probe = VideoPlayerController.file(file);
    try {
      await probe.initialize();
      final d = probe.value.duration;
      return d == Duration.zero ? null : d;
    } catch (_) {
      return null;
    } finally {
      await probe.dispose();
    }
  }

  /// Extracts the first-frame poster of [file] as a base64-encoded JPEG, or null
  /// if it can't be decoded. Runs on the SENDER only: the string rides inline in
  /// the encrypted message ([MessageModel.videoThumbnailBase64]), so the receiver
  /// paints the poster with no plugin call and before downloading the clip.
  ///
  /// Downscaled to 360 px wide at quality 60 — a bubble-sized still, kept small
  /// because it travels inside the envelope. Any failure returns null and the
  /// bubble falls back to the film-glyph placeholder; it never blocks the send.
  Future<String?> _generateVideoThumbnail(File file) async {
    try {
      final Uint8List? bytes = await VideoThumbnail.thumbnailData(
        video: file.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 360,
        quality: 60,
      );
      if (bytes == null || bytes.isEmpty) return null;
      return base64Encode(bytes);
    } catch (_) {
      return null;
    }
  }

  /// The video bubble tile — see [VideoThumbnailTile], shared with the mesh chat
  /// so both surfaces render a video the same way. Tapping it (at the call site)
  /// opens [ChatVideoPlayerScreen] via [_showFullScreenVideo].
  Widget _buildVideoThumbnail(MessageModel message) =>
      VideoThumbnailTile(message: message);

  void _showFullScreenVideo(MessageModel message) {
    final localPath = message.localFilePath;
    final url = message.mediaUrl;
    final hasLocal = localPath != null && File(localPath).existsSync();
    if (!hasLocal && (url == null || url.isEmpty)) return; // nothing to play

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatVideoPlayerScreen(
          localPath: localPath,
          url: url,
          thumbnailBase64: message.videoThumbnailBase64,
          caption: message.text,
        ),
      ),
    );
  }

  /// The long-press menu: the reaction pill on top, the action list beneath.
  ///
  /// One overlay and one gesture, so holding a message reveals everything it can
  /// do. Availability is decided once, here, from three questions — is it mine,
  /// can I actually read it, and is it still inside [ChatService.editWindow] —
  /// rather than each tile guessing for itself.
  void _showMessageActions(MessageModel message) {
    final c = AppThemeColors.of(context);

    final isMine = message.senderId == widget.currentUserId;
    final isTombstone = message.deletedForEveryone;
    final isReaction = message.type == MessageType.reaction;

    // A bubble we never decrypted has no text to copy, quote or forward, and a
    // tombstone has no content at all. Both are still deletable — for a message
    // you cannot read, removing it is the only thing left to want.
    final hasContent = !_isUndecryptable(message) && !isTombstone && !isReaction;
    final fresh = ChatService.withinEditWindow(message.timestamp);

    final canCopy = hasContent && message.text.trim().isNotEmpty;
    final canEdit = isMine && hasContent && message.type == MessageType.text && fresh;
    final canDeleteForEveryone = isMine && !isTombstone && fresh;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (BuildContext dialogContext) {
        // Scrollable because the pill plus six tiles is taller than a short
        // screen in landscape, and a menu you cannot reach the bottom of is
        // worse than one that scrolls.
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasContent) _buildReactionPill(message, c, dialogContext),
                if (hasContent) const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: c.surface.withOpacity(0.98),
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: c.border.withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasContent)
                          _buildActionTile(
                            icon: Icons.reply_rounded,
                            label: 'Reply',
                            colors: c,
                            onTap: () {
                              Navigator.pop(dialogContext);
                              _startReply(message);
                            },
                          ),
                        if (canCopy)
                          _buildActionTile(
                            icon: Icons.content_copy_rounded,
                            label: 'Copy',
                            colors: c,
                            onTap: () {
                              Navigator.pop(dialogContext);
                              _copyMessage(message);
                            },
                          ),
                        if (hasContent)
                          _buildActionTile(
                            icon: Icons.forward_rounded,
                            label: 'Forward',
                            colors: c,
                            onTap: () {
                              Navigator.pop(dialogContext);
                              _showForwardSheet(message);
                            },
                          ),
                        if (canEdit)
                          _buildActionTile(
                            icon: Icons.edit_rounded,
                            label: 'Edit',
                            colors: c,
                            onTap: () {
                              Navigator.pop(dialogContext);
                              _startEdit(message);
                            },
                          ),
                        _buildActionTile(
                          icon: Icons.delete_outline_rounded,
                          label: 'Delete',
                          colors: c,
                          destructive: true,
                          onTap: () {
                            Navigator.pop(dialogContext);
                            _confirmDelete(message,
                                forEveryone: canDeleteForEveryone);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// The six-emoji reaction row. Unchanged behaviour; lifted out of
  /// [_showMessageActions] so the overlay body stays readable.
  Widget _buildReactionPill(
      MessageModel message, AppThemeColors c, BuildContext dialogContext) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: c.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: c.border.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: ['👍', '❤️', '😂', '😮', '😢', '🙏'].map((emoji) {
            return InkWell(
              onTap: () {
                Navigator.pop(dialogContext);
                _sendReaction(message, emoji);
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required AppThemeColors colors,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final tint = destructive ? const Color(0xFFE5484D) : colors.textHigh;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: tint),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: tint,
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyMessage(MessageModel message) {
    // Already plaintext: bubbles render decrypted text, so there is nothing to
    // unwrap here.
    Clipboard.setData(ClipboardData(text: message.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied'),
        duration: Duration(milliseconds: 1200),
      ),
    );
  }

  /// Asks which kind of delete, then performs it.
  ///
  /// A confirmation step rather than two tiles in the menu: "delete for
  /// everyone" is irreversible and reaches someone else's device, which is not
  /// something a single mis-aimed tap should be able to do.
  Future<void> _confirmDelete(MessageModel message,
      {required bool forEveryone}) async {
    final c = AppThemeColors.of(context);

    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: c.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete message?',
          style: GoogleFonts.poppins(
            color: c.textHigh,
            fontSize: 16.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          forEveryone
              ? 'Delete it just for you, or for everyone in this chat?'
              // Shown when the 48h window has closed, or the message is not
              // ours. Saying why is better than an option that is simply absent.
              : 'This removes it from your devices only. '
                  '${widget.contact.name} will still see it.',
          style: GoogleFonts.poppins(color: c.textMid, fontSize: 13.5),
        ),
        actionsPadding: const EdgeInsets.only(right: 12, bottom: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: c.textMid, fontSize: 13.5),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'me'),
            child: Text(
              'Delete for me',
              style: GoogleFonts.poppins(
                color: const Color(0xFFE5484D),
                fontSize: 13.5,
              ),
            ),
          ),
          if (forEveryone)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'everyone'),
              child: Text(
                'Delete for everyone',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFE5484D),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );

    if (choice == null || !mounted) return;

    try {
      if (choice == 'everyone') {
        await _chatService.deleteMessageForEveryone(
          currentUserId: widget.currentUserId,
          otherUserId: widget.contact.id,
          messageId: message.id,
        );
      } else {
        await _chatService.deleteMessageForMe(
          currentUserId: widget.currentUserId,
          otherUserId: widget.contact.id,
          messageId: message.id,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete: $e')),
      );
    }
  }

  /// Picks a chat to forward [message] into.
  ///
  /// Deliberately a small sheet over the existing chat list rather than a picker
  /// mode threaded through ContactsScreen: that screen carries tabs, device
  /// contact matching and hardwired navigation, none of which a forward target
  /// needs.
  Future<void> _showForwardSheet(MessageModel message) async {
    final c = AppThemeColors.of(context);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.forward_rounded, size: 18, color: c.textMid),
                    const SizedBox(width: 10),
                    Text(
                      'Forward to',
                      style: GoogleFonts.poppins(
                        color: c.textHigh,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: c.border.withOpacity(0.4)),
              // Bounded so the sheet never grows past half the screen; the list
              // itself scrolls.
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sheetContext).size.height * 0.5,
                ),
                child: StreamBuilder<List<ChatRoom>>(
                  stream: _chatService.getChatRooms(widget.currentUserId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    // Forwarding into this same chat is a no-op the user never
                    // means, so the current contact is left out.
                    final peers = snapshot.data!
                        .map((room) => room.participants.firstWhere(
                              (p) => p != widget.currentUserId,
                              orElse: () => '',
                            ))
                        .where((id) => id.isNotEmpty && id != widget.contact.id)
                        .toList();

                    if (peers.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(28),
                        child: Text(
                          'No other chats to forward to',
                          style: GoogleFonts.poppins(
                              color: c.textMid, fontSize: 13.5),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: peers.length,
                      itemBuilder: (context, i) => _buildForwardTarget(
                          peers[i], message, sheetContext, c),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildForwardTarget(String peerId, MessageModel message,
      BuildContext sheetContext, AppThemeColors c) {
    return FutureBuilder<UserModel?>(
      future: _userService.getUserById(peerId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        // Rendered before the name resolves rather than after: the rows appear
        // at once and fill in, instead of the sheet sitting empty.
        final name = user?.name ?? '…';
        return ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: c.primaryLt,
            backgroundImage: (user?.photoUrl?.isNotEmpty ?? false)
                ? avatarImage(user!.photoUrl!, radius: 20)
                : null,
            child: (user?.photoUrl?.isNotEmpty ?? false)
                ? null
                : Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                      color: c.primaryDk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          title: Text(
            name,
            style: GoogleFonts.poppins(color: c.textHigh, fontSize: 14.5),
          ),
          onTap: user == null
              ? null
              : () {
                  Navigator.pop(sheetContext);
                  _forwardTo(user, message);
                },
        );
      },
    );
  }

  /// Sends [message]'s content on to [target] as a fresh message.
  ///
  /// A new send, not a copy of the document: `sendMessage` encrypts for the new
  /// recipient's devices, and the old envelopes are addressed to devices the
  /// target does not own. Media rides along by URL — `chat_images/` is readable
  /// by any authenticated user, so there is nothing to re-upload.
  ///
  /// The reply quote and link preview are deliberately dropped: a quote of a
  /// conversation the target cannot see is noise, and the preview will be
  /// re-resolved from the text.
  Future<void> _forwardTo(UserModel target, MessageModel message) async {
    try {
      await _chatService.sendMessage(
        senderId: widget.currentUserId,
        receiverId: target.id,
        text: message.text,
        senderName: widget.currentUserName,
        type: message.type,
        mediaUrl: message.mediaUrl,
        audioDuration: message.audioDuration,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Forwarded to ${target.name}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not forward: $e')),
      );
    }
  }

  void _startEdit(MessageModel message) {
    setState(() {
      _editing = message;
      // A reply and an edit are mutually exclusive composer modes — leaving a
      // stale reply strip above an edit would suggest the edit will carry a
      // quote, which it will not.
      _replyTo = null;
    });
    _messageController.text = message.text;
    _messageController.selection =
        TextSelection.collapsed(offset: _messageController.text.length);
    _composerFocus.requestFocus();
  }

  void _cancelEdit() {
    setState(() => _editing = null);
    _messageController.clear();
  }

  /// Commits the composer's text as an edit of [_editing].
  Future<void> _commitEdit() async {
    final target = _editing;
    if (target == null) return;
    final text = _messageController.text.trim();

    // An empty edit is a delete wearing the wrong hat. Say so rather than
    // silently blanking the bubble.
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Use Delete to remove a message')),
      );
      return;
    }
    if (text == target.text) {
      _cancelEdit();
      return;
    }

    // Cleared in the same synchronous block as the read, for the same reason
    // _sendMessage does it: re-encryption runs long after, and the user can
    // start typing the next message immediately.
    _cancelEdit();
    _stopTyping();

    try {
      await _chatService.editMessage(
        senderId: widget.currentUserId,
        receiverId: widget.contact.id,
        messageId: target.id,
        newText: text,
      );
    } catch (e) {
      if (!mounted) return;
      // Hand the text back — an edit that fails silently loses what they typed.
      _messageController.text = text;
      setState(() => _editing = target);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not edit: $e')),
      );
    }
  }

  Future<void> _sendReaction(MessageModel message, String emoji) async {
    if (_isBlocked || _isBlockedByContact) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send reactions to this contact')),
      );
      return;
    }
    try {
      await _chatService.sendMessage(
        senderId: widget.currentUserId,
        receiverId: widget.contact.id,
        text: emoji,
        senderName: widget.currentUserName,
        type: MessageType.reaction,
        reactionTargetMessageId: message.id,
      );
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error sending reaction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add reaction')),
        );
      }
    }
  }

  void _showReactionsDetailDialog(MessageModel message) {
    if (message.reactions == null || message.reactions!.isEmpty) return;
    final c = AppThemeColors.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: c.surface,
          title: Text(
            'Reactions',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: c.textHigh,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: message.reactions!.length,
              itemBuilder: (context, index) {
                final userId = message.reactions!.keys.elementAt(index);
                final emoji = message.reactions!.values.elementAt(index);
                final isSelf = userId == widget.currentUserId;

                return FutureBuilder<DocumentSnapshot>(
                  future: _userProfileFutures.putIfAbsent(
                    userId,
                    () => FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .get(),
                  ),
                  builder: (context, snapshot) {
                    final name = isSelf
                        ? 'You'
                        : (snapshot.data?.data()
                                as Map<String, dynamic>?)?['name'] as String? ??
                            'Someone';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: c.primaryLt,
                        backgroundImage: (snapshot.data?.data()
                                    as Map<String, dynamic>?)?['avatarUrl'] !=
                                null
                            ? avatarImage(
                                (snapshot.data!.data()
                                    as Map<String, dynamic>)['avatarUrl'],
                                radius: 16)
                            : null,
                        child: (snapshot.data?.data()
                                    as Map<String, dynamic>?)?['avatarUrl'] ==
                                null
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: TextStyle(
                                    color: c.primary,
                                    fontWeight: FontWeight.bold))
                            : null,
                      ),
                      title: Text(
                        name,
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: c.textHigh),
                      ),
                      trailing: Text(
                        emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close',
                  style: GoogleFonts.poppins(
                      color: c.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }
}

// ─── Animated typing dots (the 3 bouncing dots) ──────────────────────────

class _TypingDotsIndicator extends StatefulWidget {
  const _TypingDotsIndicator();

  @override
  State<_TypingDotsIndicator> createState() => _TypingDotsIndicatorState();
}

class _TypingDotsIndicatorState extends State<_TypingDotsIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(3, (i) {
      return AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
    });

    _animations = _controllers.map((c) {
      return Tween<double>(begin: 0, end: -6).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    // Stagger the animations
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.translate(
                offset: Offset(0, _animations[i].value),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: c.textLow,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// ─── Display item descriptors for ListView.builder ─────────────────────────
// Lightweight data objects that describe WHAT to render at each index in the
// chat list. The actual widget tree is built only for visible items inside
// ListView.builder's itemBuilder callback, saving massive CPU on chats with
// hundreds of messages.

enum _DisplayItemType {
  banner,
  dateDivider,
  message,
  typing,
  loadingOlder,
  nativeAd,
}

class _DisplayItem {
  final _DisplayItemType type;
  final MessageModel? message;
  final String? dateLabel;
  final bool animate;

  const _DisplayItem._({
    required this.type,
    this.message,
    this.dateLabel,
    this.animate = false,
  });

  const _DisplayItem.banner() : this._(type: _DisplayItemType.banner);

  const _DisplayItem.typing() : this._(type: _DisplayItemType.typing);

  const _DisplayItem.loadingOlder()
      : this._(type: _DisplayItemType.loadingOlder);

  const _DisplayItem.nativeAd() : this._(type: _DisplayItemType.nativeAd);

  _DisplayItem.dateDivider(String label)
      : this._(type: _DisplayItemType.dateDivider, dateLabel: label);

  _DisplayItem.message(MessageModel msg, {bool animate = false})
      : this._(type: _DisplayItemType.message, message: msg, animate: animate);
}

/// Paints the chat theme's background — colour or gradient or photo, plus its
/// pattern — behind the message list.
///
/// There is deliberately no [Theme] override here. An earlier version re-rooted
/// the subtree on `AppTheme.light`/`AppTheme.dark` to match a preset that fixed
/// its own brightness, which is what kept nested bubble content
/// ([VoiceMessageBubble], [ReplyQuoteCard], [LinkPreviewCard]) legible on a dark
/// preset inside a light app. Presets now carry a light *and* a dark face and are
/// resolved against the app's own palette (see [ChatTheme]), so those widgets are
/// already looking at the right colours and the chat can no longer disagree with
/// the mode the user picked for the rest of the app.
class _ChatThemedArea extends StatelessWidget {
  const _ChatThemedArea({
    required this.theme,
    required this.colors,
    required this.child,
  });

  final ChatTheme theme;

  /// The app palette. Selects the theme's face and fills in whatever it leaves
  /// unset.
  final AppThemeColors colors;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final decoration = theme.decorationOf(colors);

    Widget content = child;

    // The pattern sits between the background and the message list: above the
    // gradient or photo, below the bubbles. A photo background gets no pattern —
    // it has texture of its own, and overlaying motifs on someone's chosen image
    // is defacing it.
    if (theme.pattern != ChatPattern.none && !theme.hasImage) {
      content = Stack(
        children: [
          Positioned.fill(
            child: ChatPatternLayer(
              pattern: theme.pattern,
              ink: theme.patternInk(colors),
            ),
          ),
          content,
        ],
      );
    }

    // The Scaffold already paints `theme.backgroundOf(colors)`, so a plain
    // colour needs no extra layer here.
    if (decoration != null) {
      content = DecoratedBox(decoration: decoration, child: content);
    }

    return content;
  }
}

