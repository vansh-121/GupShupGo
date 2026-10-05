import 'dart:async';
import 'dart:io';
// Narrowed: a bare `dart:ui` import collides with material's `Image`.
import 'dart:ui' show FontFeature, ImageFilter;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/models/anonymous_room_model.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/provider/call_state_provider.dart';
import 'package:video_chat_app/provider/subscription_provider.dart';
import 'package:video_chat_app/services/anonymous_chat_service.dart';
import 'package:video_chat_app/screens/anonymous/anonymous_lobby_screen.dart';
import 'package:video_chat_app/screens/plaintext_view_once_viewer.dart';
import 'package:video_chat_app/screens/chat_screen.dart';
import 'package:video_chat_app/services/ads/interstitial_ad_service.dart';
import 'package:video_chat_app/services/user_service.dart';
import 'package:video_chat_app/services/voice_recorder_service.dart';
import 'package:video_chat_app/services/whats_new_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/widgets/attachment_sheet.dart';
import 'package:video_chat_app/widgets/linkified_text.dart';
import 'package:video_chat_app/widgets/new_feature_badge.dart';
import 'package:video_chat_app/widgets/video_message_widgets.dart';
import 'package:video_chat_app/widgets/voice_message_bubble.dart';

/// Largest video an anonymous chat will upload, in bytes (64 MB).
///
/// The same ceiling the online chat uses (`_kMaxChatVideoBytes` in
/// `chat_screen.dart`, private to that file) — a stranger video is an ordinary
/// plaintext upload, so there is no reason for it to differ.
const int _kMaxAnonymousVideoBytes = 64 * 1024 * 1024;

/// Dedicated 1-on-1 anonymous chat screen between two strangers.
class AnonymousChatScreen extends StatefulWidget {
  final String roomId;
  final String currentUserId;
  final String? currentUserName;

  const AnonymousChatScreen({
    super.key,
    required this.roomId,
    required this.currentUserId,
    this.currentUserName,
  });

  @override
  State<AnonymousChatScreen> createState() => _AnonymousChatScreenState();
}

class _AnonymousChatScreenState extends State<AnonymousChatScreen> {
  final _service = AnonymousChatService.instance;
  final _userService = UserService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final _voiceRecorder = VoiceRecorderService();

  AnonymousRoomModel? _room;
  StreamSubscription<DocumentSnapshot>? _roomSub;
  bool _strangerDisconnected = false;
  bool _isEnding = false;
  bool _sendingFriendRequest = false;
  bool _respondingToRequest = false;
  bool _transitioningToE2EE = false;

  /// One flag for all three media paths — the composer only ever runs one at a
  /// time, and the paperclip is the only thing that reads it.
  bool _isUploadingMedia = false;

  /// True while the text field holds something, so the trailing circle can swap
  /// between send and mic. Kept as state rather than read off the controller in
  /// `build` because the controller doesn't rebuild the tree on its own.
  bool _hasText = false;

  /// Message ids the user has chosen to un-blur, see [_StrangerMediaGate].
  ///
  /// Deliberately State-local rather than persisted: leaving the chat re-blurs
  /// everything, and a new stranger is a new decision.
  final Set<String> _revealedMedia = {};

  /// View-once message ids the user has already opened this session.
  ///
  /// Local and State-scoped for the same reason as [_revealedMedia]: the
  /// anonymous message subcollection is immutable by security rule, so "opened"
  /// can't be persisted to the doc, and leaving the room ends the session
  /// anyway. Opening flips the bubble to "Opened" and blocks a second view for
  /// as long as this screen lives.
  final Set<String> _consumedViewOnce = {};

  @override
  void initState() {
    super.initState();
    _loadRoom();
    _messageController.addListener(_onTextChanged);
    // Only warms one when the next skip is the one that would show it, so the
    // user isn't left staring at the chat they just left while an ad loads.
    unawaited(InterstitialAdService.instance.preloadForNextSkip());
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _voiceRecorder.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final has = _messageController.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  Future<void> _loadRoom() async {
    final room = await _service.getRoom(widget.roomId);
    if (mounted) {
      setState(() => _room = room);
    }

    // Listen for room status changes (stranger leaving, friend request).
    _roomSub = _service.listenToRoom(widget.roomId).listen((snapshot) {
      if (!snapshot.exists || !mounted) return;
      final updatedRoom = AnonymousRoomModel.fromFirestore(snapshot);

      // ── Friend request accepted → transition to E2EE chat ──────────
      if (updatedRoom.isFriendRequestAccepted &&
          updatedRoom.e2eeChatRoomId != null &&
          !_transitioningToE2EE) {
        setState(() => _room = updatedRoom);
        _handleFriendRequestAccepted(updatedRoom);
        return;
      }

      setState(() {
        _room = updatedRoom;
        // Only show the "disconnected" banner when the room ended for a
        // reason OTHER than a friend request acceptance.
        if (!updatedRoom.isActive &&
            !updatedRoom.isFriendRequestAccepted &&
            updatedRoom.endedBy != widget.currentUserId) {
          _strangerDisconnected = true;
        }
      });
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _room == null || !_room!.isActive) return;

    _messageController.clear();
    await _service.sendMessage(
      roomId: widget.roomId,
      senderId: widget.currentUserId,
      text: text,
    );

    _scrollToBottom();
  }

  // ── Media ────────────────────────────────────────────────────────────
  //
  // All three paths share the same two steps: put the file in
  // `anonymous_media/` and then write a message document pointing at it. The
  // upload is plaintext — there is no Signal session with a stranger, so there
  // is no key to seal it with. That is stated in the UI, and everything the
  // stranger sends arrives behind [_StrangerMediaGate].

  void _showAttachSheet() {
    // Opening the sheet *is* the discovery — the tiles inside are the feature,
    // so there is nothing further to find and nothing to pill.
    WhatsNewService.instance.markSeen(NewFeature.anonymousMedia);
    // Photo and video only — no Document, no Location. An archive or an APK from
    // an unvetted stranger is a different risk class from a photo, and a pin is
    // the one attachment that identifies you. The footer states the trade-off
    // the transport makes: a stranger upload has no Signal session to seal it.
    showAttachmentSheet(
      context: context,
      actions: [
        AttachmentAction(
          kind: AttachmentKind.photo,
          onTap: (viewOnce) => _pickAndSendImage(viewOnce: viewOnce),
        ),
        AttachmentAction(
          kind: AttachmentKind.video,
          onTap: (viewOnce) => _pickAndSendVideo(viewOnce: viewOnce),
        ),
      ],
      viewOnce: const AttachmentViewOnce(
        subtitleOff: 'Opens one time, and screenshots are blocked on Android.',
        subtitleOn: 'Opens one time, and screenshots are blocked on Android.',
      ),
      footer: 'Anonymous media is not end-to-end encrypted.',
    );
  }

  Future<void> _pickAndSendImage({bool viewOnce = false}) async {
    try {
      // No `proMediaQuality` bump: anonymous chat isn't a Pro surface, and a
      // stranger photo has no reason to be the largest thing the app uploads.
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked == null) return;

      setState(() => _isUploadingMedia = true);
      final url = await _service.uploadAnonymousMedia(
        roomId: widget.roomId,
        senderId: widget.currentUserId,
        file: File(picked.path),
        contentType: 'image/jpeg',
        fallbackExt: 'jpg',
      );
      await _service.sendMediaMessage(
        roomId: widget.roomId,
        senderId: widget.currentUserId,
        type: AnonymousMediaType.image,
        mediaUrl: url,
        viewOnce: viewOnce,
      );
      _scrollToBottom();
    } catch (e) {
      _showError('Failed to send photo: $e');
    } finally {
      if (mounted) setState(() => _isUploadingMedia = false);
    }
  }

  Future<void> _pickAndSendVideo({bool viewOnce = false}) async {
    try {
      final picked = await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (picked == null) return;

      // Checked before the poster/duration probes so an oversized pick is
      // rejected without spinning up a decoder.
      final bytes = await File(picked.path).length();
      if (bytes > _kMaxAnonymousVideoBytes) {
        _showError(
          'This video is too large — the limit is '
          '${(_kMaxAnonymousVideoBytes / (1024 * 1024)).round()} MB. '
          'Try a shorter clip.',
        );
        return;
      }

      setState(() => _isUploadingMedia = true);
      // Both optional — a probe failure drops the preview, never the send.
      final poster = await generateMeshVideoPoster(picked.path);
      final durSec = await probeMeshVideoDurationSeconds(picked.path);
      final url = await _service.uploadAnonymousMedia(
        roomId: widget.roomId,
        senderId: widget.currentUserId,
        file: File(picked.path),
        contentType: 'video/mp4',
        fallbackExt: 'mp4',
      );
      await _service.sendMediaMessage(
        roomId: widget.roomId,
        senderId: widget.currentUserId,
        type: AnonymousMediaType.video,
        mediaUrl: url,
        audioDuration: durSec,
        videoThumbnailBase64: poster,
        viewOnce: viewOnce,
      );
      _scrollToBottom();
    } catch (e) {
      _showError('Failed to send video: $e');
    } finally {
      if (mounted) setState(() => _isUploadingMedia = false);
    }
  }

  Future<void> _startVoiceRecording() async {
    HapticFeedback.mediumImpact();
    // Same cap as every other surface — a stranger chat is the same feature over
    // a different audience, and leaving it uncapped here would make the limit
    // bypassable by switching screens. Read before the await: `startRecording`
    // awaits a permission prompt.
    final cap = context.read<SubscriptionProvider>().maxVoiceDurationSec;
    await _voiceRecorder.startRecording(
      maxDurationSec: cap,
      onLimitReached: cap == null
          ? null
          : () {
              _stopVoiceRecording();
              if (mounted) {
                _showError(
                  'Voice messages are limited to '
                  '${VoiceRecorderService.formatDuration(Duration(seconds: cap))}'
                  ' — sent what you recorded.',
                );
              }
            },
    );
    if (mounted) setState(() {});
  }

  Future<void> _stopVoiceRecording() async {
    if (!_voiceRecorder.isRecording) return;
    final duration = _voiceRecorder.elapsed.inSeconds;
    final path = await _voiceRecorder.stopRecording();
    if (mounted) setState(() {});
    // A sub-second press is a mis-tap, not a message.
    if (path == null || duration < 1) return;
    try {
      setState(() => _isUploadingMedia = true);
      final url = await _service.uploadAnonymousMedia(
        roomId: widget.roomId,
        senderId: widget.currentUserId,
        file: File(path),
        contentType: 'audio/mp4',
        fallbackExt: 'm4a',
      );
      await _service.sendMediaMessage(
        roomId: widget.roomId,
        senderId: widget.currentUserId,
        type: AnonymousMediaType.audio,
        mediaUrl: url,
        audioDuration: duration,
      );
      _scrollToBottom();
    } catch (e) {
      _showError('Failed to send voice note: $e');
    } finally {
      if (mounted) setState(() => _isUploadingMedia = false);
    }
  }

  Future<void> _cancelVoiceRecording() async {
    HapticFeedback.heavyImpact();
    await _voiceRecorder.cancelRecording();
    if (mounted) setState(() {});
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ── Bubbles ──────────────────────────────────────────────────────────

  Widget _buildTextBubble(AppThemeColors c, String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? c.primary : c.surfaceAlt,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: LinkifiedText(
          text,
          linkColor: isMe ? Colors.white : c.primary,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: isMe ? Colors.white : c.textHigh,
          ),
        ),
      ),
    );
  }

  /// A photo, video or voice note bubble, built from the raw Firestore map.
  ///
  /// The shared bubble widgets take a [MessageModel] and each reads only a
  /// handful of its fields — [VoiceMessageBubble] wants `audioDuration` and
  /// `mediaUrl`, [VideoThumbnailTile] wants `id`, `audioDuration` and
  /// `videoThumbnailBase64` — so a throwaway model is synthesized here rather
  /// than writing anonymous-specific copies of them that would then have to be
  /// kept in step. The id is the message document id, which is what both the
  /// poster cache and [_revealedMedia] key on.
  Widget _buildMediaBubble(
    AppThemeColors c, {
    required String docId,
    required Map<String, dynamic> msg,
    required String type,
    required bool isMe,
  }) {
    final mediaUrl = msg['mediaUrl'] as String?;
    final text = msg['text'] as String? ?? '';
    // A media document with no URL is a half-written send (the client died
    // between the upload and the write). The fallback label is more use than an
    // empty frame.
    if (mediaUrl == null || mediaUrl.isEmpty) {
      return _buildTextBubble(c, text, isMe);
    }

    // View-once photos and videos never render inline — not a thumbnail, not a
    // blurred preview, because a preview is a copy that survives the one view.
    // They get a placeholder bubble that opens the capture-blocked viewer.
    final isViewOnce =
        (msg['viewOnce'] == true) && (type == 'image' || type == 'video');
    if (isViewOnce) {
      return _buildViewOnceBubble(
        c,
        docId: docId,
        isMe: isMe,
        isVideo: type == 'video',
        mediaUrl: mediaUrl,
        thumbnailBase64: msg['videoThumbnailBase64'] as String?,
      );
    }

    final model = MessageModel(
      id: docId,
      senderId: msg['senderId'] as String? ?? '',
      receiverId: '',
      text: text,
      type: switch (type) {
        'image' => MessageType.image,
        'video' => MessageType.video,
        _ => MessageType.audio,
      },
      timestamp: (msg['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mediaUrl: mediaUrl,
      audioDuration: (msg['audioDuration'] as num?)?.toInt(),
      videoThumbnailBase64: msg['videoThumbnailBase64'] as String?,
    );

    final Widget content;
    switch (type) {
      case 'image':
        content = _gate(
          docId,
          isMe,
          GestureDetector(
            onTap: () => _openFullScreenImage(mediaUrl),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 220, maxHeight: 280),
                child: Image.network(
                  mediaUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const SizedBox(
                          width: 220,
                          height: 160,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                  errorBuilder: (_, __, ___) => SizedBox(
                    width: 220,
                    height: 160,
                    child: Center(
                      child: Icon(Icons.broken_image_rounded,
                          color: c.textLow, size: 32),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      case 'video':
        content = _gate(
          docId,
          isMe,
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ChatVideoPlayerScreen(
                  url: mediaUrl,
                  thumbnailBase64: model.videoThumbnailBase64,
                  caption: '',
                ),
              ),
            ),
            child: VideoThumbnailTile(message: model),
          ),
        );
      default:
        // Never gated: the bubble doesn't autoplay, so audio can't ambush the
        // eye the way an image can, and a blurred waveform communicates nothing.
        content = ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 200),
          child: VoiceMessageBubble(message: model, isMe: isMe),
        );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: isMe ? c.primary : c.surfaceAlt,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: content,
      ),
    );
  }

  /// Wraps received media in [_StrangerMediaGate]; leaves your own sends alone.
  Widget _gate(String docId, bool isMe, Widget child) {
    if (isMe || _revealedMedia.contains(docId)) return child;
    return _StrangerMediaGate(
      onReveal: () => setState(() => _revealedMedia.add(docId)),
      child: child,
    );
  }

  /// The placeholder bubble for a view-once photo or video. Mirrors the E2EE
  /// chat's `ViewOnceBubble` in spirit: it never shows the media, and the four
  /// states are derived from `isMe` and the local [_consumedViewOnce] set.
  ///
  ///  * sender — inert "View once", never tappable (they can't reopen either).
  ///  * receiver, unopened — tappable → confirm → capture-blocked viewer.
  ///  * receiver, opened — inert "Opened".
  Widget _buildViewOnceBubble(
    AppThemeColors c, {
    required String docId,
    required bool isMe,
    required bool isVideo,
    required String mediaUrl,
    String? thumbnailBase64,
  }) {
    final opened = _consumedViewOnce.contains(docId);
    final tappable = !isMe && !opened;
    final fg = isMe ? Colors.white : c.textHigh;
    final fgLow = isMe ? Colors.white.withOpacity(0.75) : c.textLow;
    final glyphColor = opened ? fgLow : fg;

    final String title = opened ? 'Opened' : (isVideo ? 'Video' : 'Photo');
    final String subtitle;
    if (opened) {
      subtitle = 'View once · no longer available';
    } else if (isMe) {
      subtitle = 'View once · sent';
    } else {
      subtitle = isVideo ? 'View once · tap to play' : 'View once · tap to view';
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? c.primary : c.surfaceAlt,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: InkWell(
          onTap: tappable
              ? () => _openViewOnce(
                    docId: docId,
                    isVideo: isVideo,
                    mediaUrl: mediaUrl,
                    thumbnailBase64: thumbnailBase64,
                  )
              : null,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 168, maxWidth: 240),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: glyphColor.withOpacity(0.55)),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    opened
                        ? Icons.visibility_off_rounded
                        : (isVideo
                            ? Icons.play_circle_outline_rounded
                            : Icons.looks_one_rounded),
                    size: 20,
                    color: glyphColor,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: opened ? fgLow : fg,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          fontStyle:
                              opened ? FontStyle.italic : FontStyle.normal,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            GoogleFonts.poppins(color: fgLow, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Confirms, marks the message consumed, then opens the capture-blocked
  /// viewer. Consuming *before* the push is deliberate: it flips the bubble to
  /// "Opened" the instant the user commits, so a back-swipe or a crash inside
  /// the viewer can't hand them a second look.
  Future<void> _openViewOnce({
    required String docId,
    required bool isVideo,
    required String mediaUrl,
    String? thumbnailBase64,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isVideo ? 'Play once?' : 'Open once?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          "You can only open this ${isVideo ? 'video' : 'photo'} one time. "
          "Once you close it, it's gone.",
          style: GoogleFonts.poppins(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Open',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _consumedViewOnce.add(docId));

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlaintextViewOnceViewer(
          isVideo: isVideo,
          mediaUrl: mediaUrl,
          thumbnailBase64: thumbnailBase64,
        ),
      ),
    );
  }

  /// Local copy of the chat screen's full-screen viewer — that one is private to
  /// `_ChatScreenState` and takes a caption and a local path this screen never
  /// has, so duplicating the twenty lines beats widening its signature.
  void _openFullScreenImage(String url) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                url,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_rounded,
                  color: Colors.white54,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _endAndLeave() async {
    if (_isEnding) return;
    _isEnding = true;
    await _service.endSession(widget.roomId, widget.currentUserId);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _nextStranger() async {
    if (_isEnding) return;
    _isEnding = true;

    // Read the providers before any await — after them this State may be gone
    // and its context unusable.
    final hasPro = Provider.of<SubscriptionProvider>(context, listen: false)
        .hasActiveProEntitlement;
    final callState =
        Provider.of<CallStateNotifier>(context, listen: false).state;

    if (_room != null && _room!.isActive) {
      await _service.endSession(widget.roomId, widget.currentUserId);
    }

    // Between one stranger and the next: the room is closed, no match is
    // running, and the user has explicitly asked for different content — the one
    // transition in this app where a fullscreen ad interrupts nothing.
    //
    // Awaited on purpose. Starting the search first would leave a matched
    // stranger waiting behind the ad, quite possibly long enough to leave.
    await InterstitialAdService.instance.maybeShowOnStrangerSkip(
      hasProEntitlement: hasPro,
      callState: callState,
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AnonymousLobbyScreen(currentUserId: widget.currentUserId),
      ),
    );
  }

  // ── Friend Request: Sender ──────────────────────────────────────────
  Future<void> _sendFriendRequest() async {
    if (_room == null || _sendingFriendRequest) return;
    setState(() => _sendingFriendRequest = true);

    final myAlias = _room!.getAlias(widget.currentUserId);
    final partnerId = _room!.getPartnerId(widget.currentUserId);

    try {
      await _service.sendFriendRequest(
        roomId: widget.roomId,
        fromUserId: widget.currentUserId,
        toUserId: partnerId,
        fromAlias: myAlias,
      );
    } finally {
      if (mounted) setState(() => _sendingFriendRequest = false);
    }
  }

  // ── Friend Request: Receiver accepts ────────────────────────────────
  Future<void> _acceptFriendRequest() async {
    if (_room == null || _respondingToRequest) return;
    setState(() => _respondingToRequest = true);
    try {
      // The accept path updates the room → e2eeChatRoomId → our room listener
      // handles the navigation for BOTH users.
      await _service.acceptFriendRequest(
        roomId: widget.roomId,
        currentUserId: widget.currentUserId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not accept request. Please try again.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _respondingToRequest = false);
    }
  }

  // ── Friend Request: Receiver declines ───────────────────────────────
  Future<void> _declineFriendRequest() async {
    if (_room == null || _respondingToRequest) return;
    setState(() => _respondingToRequest = true);
    try {
      await _service.declineFriendRequest(
        roomId: widget.roomId,
        currentUserId: widget.currentUserId,
      );
    } finally {
      if (mounted) setState(() => _respondingToRequest = false);
    }
  }

  /// When a friend request is accepted, reveal real profiles and navigate
  /// to the standard E2EE [ChatScreen] after a short celebratory delay.
  Future<void> _handleFriendRequestAccepted(AnonymousRoomModel room) async {
    if (_transitioningToE2EE) return;
    _transitioningToE2EE = true;

    final partnerId = room.getPartnerId(widget.currentUserId);

    // Fetch the partner's real profile — identities are now revealed.
    final partner = await _userService.getUserById(partnerId);

    // Brief pause so users see "You are now friends! 🎉".
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final contact = Contact(
      id: partnerId,
      name: partner?.name ?? 'New Friend',
      lastMessage: '',
      time: '',
      avatarUrl: partner?.photoUrl ??
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(partner?.name ?? 'Friend')}&background=4CAF50&color=fff&size=128',
      isOnline: partner?.isOnline ?? false,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          contact: contact,
          currentUserId: widget.currentUserId,
          currentUserName: widget.currentUserName,
        ),
      ),
    );
  }

  Future<void> _showReportDialog() async {
    if (_room == null) return;
    final partnerId = _room!.getPartnerId(widget.currentUserId);
    final c = AppThemeColors.of(context);

    String? selectedReason;
    final reasons = [
      'Inappropriate content',
      'Harassment or bullying',
      'Spam or scam',
      'Threatening behaviour',
      'Other',
    ];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: c.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Report Stranger',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: c.textHigh,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Why are you reporting this user?',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: c.textMid,
                ),
              ),
              const SizedBox(height: 12),
              ...reasons.map((reason) => RadioListTile<String>(
                    title: Text(
                      reason,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: c.textHigh,
                      ),
                    ),
                    value: reason,
                    groupValue: selectedReason,
                    activeColor: c.primary,
                    onChanged: (val) =>
                        setDialogState(() => selectedReason = val),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: c.textMid),
              ),
            ),
            TextButton(
              onPressed: selectedReason != null
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: Text(
                'Report & Leave',
                style: GoogleFonts.poppins(
                  color: selectedReason != null ? c.error : c.textLow,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selectedReason != null && mounted) {
      await _service.reportUser(
        roomId: widget.roomId,
        reporterId: widget.currentUserId,
        reportedId: partnerId,
        reason: selectedReason!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Report submitted. Thank you for keeping GupShupGo safe.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);

    if (_room == null) {
      return Scaffold(
        backgroundColor: c.surface,
        body: Center(
          child: CircularProgressIndicator(color: c.primary),
        ),
      );
    }

    final partnerAlias = _room!.getPartnerAlias(widget.currentUserId);
    final iSentRequest = _room!.didSendFriendRequest(widget.currentUserId);
    final shouldRespond =
        _room!.shouldRespondToFriendRequest(widget.currentUserId);
    final canSendRequest = _room!.isActive &&
        !_room!.hasPendingFriendRequest &&
        !_transitioningToE2EE;

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: c.textHigh),
          onPressed: _endAndLeave,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              partnerAlias,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: c.textHigh,
              ),
            ),
            Text(
              'Anonymous Chat',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: c.textMid,
              ),
            ),
          ],
        ),
        actions: [
          // Add Friend
          IconButton(
            icon: Icon(
              iSentRequest
                  ? Icons.hourglass_top_rounded
                  : Icons.person_add_alt_1_rounded,
              color: canSendRequest ? c.primary : c.textLow,
            ),
            tooltip: iSentRequest ? 'Request sent' : 'Add friend',
            onPressed: (canSendRequest && !_sendingFriendRequest)
                ? _sendFriendRequest
                : null,
          ),
          // Next stranger
          IconButton(
            icon: Icon(Icons.skip_next_rounded, color: c.primary),
            tooltip: 'Next stranger',
            onPressed: _nextStranger,
          ),
          // Report
          IconButton(
            icon: Icon(Icons.flag_outlined, color: c.error),
            tooltip: 'Report',
            onPressed: _showReportDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── "Not encrypted" subtle label ──────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: c.surfaceAlt,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_open_rounded, size: 14, color: c.textLow),
                const SizedBox(width: 4),
                Text(
                  'Messages are not end-to-end encrypted',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: c.textLow,
                  ),
                ),
              ],
            ),
          ),

          // ── Friend Request: Receiver banner (Accept / Decline) ─
          if (shouldRespond) _buildFriendRequestBanner(c),

          // ── Friend Request: Sender waiting banner ──────────────
          if (iSentRequest) _buildWaitingBanner(c),

          // ── Messages ─────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _service.messagesStream(widget.roomId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: Text(
                      'Say hi to the stranger! 👋',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: c.textMid,
                      ),
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Say hi to the stranger! 👋',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: c.textMid,
                      ),
                    ),
                  );
                }

                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == widget.currentUserId;
                    final text = msg['text'] as String? ?? '';
                    final type = msg['type'] as String? ?? 'text';

                    // System messages (centered, muted)
                    if (type == 'system') {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: c.surfaceAlt,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              text,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: c.textMid,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    // Media — photo, video, voice note.
                    if (type == 'image' ||
                        type == 'video' ||
                        type == 'audio') {
                      return _buildMediaBubble(
                        c,
                        docId: messages[index].id,
                        msg: msg,
                        type: type,
                        isMe: isMe,
                      );
                    }

                    // Regular text messages
                    return _buildTextBubble(c, text, isMe);
                  },
                );
              },
            ),
          ),

          // ── E2EE Transition Overlay Banner ────────────────────
          if (_transitioningToE2EE)
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewPadding.bottom + 16,
              ),
              color: c.primary.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: c.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'You are now friends! Opening secure chat…',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.primary,
                    ),
                  ),
                ],
              ),
            ),

          // ── Stranger Disconnected Banner ──────────────────────
          if (_strangerDisconnected && !_transitioningToE2EE)
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewPadding.bottom + 16,
              ),
              color: c.surfaceAlt,
              child: Column(
                children: [
                  Text(
                    'Stranger has disconnected 👋',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.textHigh,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _nextStranger,
                    icon: const Icon(Icons.shuffle_rounded, size: 18),
                    label: Text(
                      'Find Next Stranger',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Input Bar ─────────────────────────────────────────
          if (!_strangerDisconnected &&
              !_transitioningToE2EE &&
              _room!.isActive)
            Container(
              padding: EdgeInsets.only(
                left: 12,
                right: 8,
                top: 8,
                bottom: MediaQuery.of(context).viewPadding.bottom + 8,
              ),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(
                  top: BorderSide(color: c.border, width: 1),
                ),
              ),
              child: _voiceRecorder.isRecording
                  ? _buildRecordingBar(c)
                  : _buildNormalBar(c),
            ),
        ],
      ),
    );
  }

  // ── Receiver banner: "Stranger wants to connect!" ───────────────────
  Widget _buildFriendRequestBanner(AppThemeColors c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: c.primary.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: c.primary.withOpacity(0.3), width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('🤝', style: GoogleFonts.poppins(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Stranger wants to connect!',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.textHigh,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Accepting reveals your real profile and starts an encrypted chat.',
            style: GoogleFonts.poppins(fontSize: 11, color: c.textMid),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _respondingToRequest ? null : _declineFriendRequest,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: c.error.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Decline',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: c.error,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _respondingToRequest ? null : _acceptFriendRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _respondingToRequest
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Accept',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Sender waiting banner ───────────────────────────────────────────
  Widget _buildWaitingBanner(AppThemeColors c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        border: Border(
          bottom: BorderSide(color: c.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_top_rounded, size: 18, color: c.textMid),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Friend request sent! Waiting for response…',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: c.textMid,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Composer ─────────────────────────────────────────────────────────
  //
  // Same two-bar arrangement as the mesh chat: a paperclip that becomes a
  // spinner, a text field, and a trailing circle that is send-while-typing and
  // hold-to-record otherwise.

  Widget _buildNormalBar(AppThemeColors c) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _isUploadingMedia
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: c.primary),
                ),
              )
            : IconButton(
                icon: NewFeatureDot(
                  anchor: NewFeatureAnchor.anonymousAttachment,
                  // A narrow glyph in a wide box, same as the ordinary
                  // composer's — without the nudge the dot lands on the clip's
                  // head instead of beside it.
                  offset: NewFeatureDot.narrowGlyph,
                  child: Icon(Icons.attach_file_rounded,
                      color: c.textMid, size: 22),
                ),
                onPressed: _showAttachSheet,
              ),
        Expanded(
          child: TextField(
            controller: _messageController,
            style: GoogleFonts.poppins(fontSize: 15, color: c.textHigh),
            decoration: InputDecoration(
              hintText: 'Type a message…',
              hintStyle: GoogleFonts.poppins(color: c.textLow, fontSize: 15),
              filled: true,
              fillColor: c.surfaceAlt,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
            maxLines: 5,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendMessage(),
          ),
        ),
        const SizedBox(width: 6),
        if (_hasText)
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          )
        else
          GestureDetector(
            onLongPressStart: (_) => _startVoiceRecording(),
            onLongPressEnd: (_) => _stopVoiceRecording(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.primary,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
            ),
          ),
      ],
    );
  }

  Widget _buildRecordingBar(AppThemeColors c) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c.error, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        ListenableBuilder(
          listenable: _voiceRecorder,
          builder: (context, _) {
            return Text(
              VoiceRecorderService.formatDuration(_voiceRecorder.elapsed),
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
        GestureDetector(
          onTap: _stopVoiceRecording,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.primary,
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }
}

/// Blurs a stranger's photo or video until the user asks to see it.
///
/// Anonymous chat has no E2EE, no vetting and no history with the other party,
/// and an unsolicited explicit image is the known abuse vector for this product
/// category. The gate makes looking a deliberate act, which is also what makes
/// the Report button in the app bar usable: you can flag the sender without
/// having had to see what they sent.
///
/// The child is still built and still fetched — the blur is a presentation
/// layer, not a download gate. Deferring the fetch would mean a second network
/// round trip on reveal and a spinner where the blur was; the cost of the
/// current shape is that the bytes are on the device either way, which for an
/// already-plaintext upload changes nothing.
class _StrangerMediaGate extends StatelessWidget {
  const _StrangerMediaGate({required this.child, required this.onReveal});

  final Widget child;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onReveal,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // `ImageFiltered` blurs the composited child, so it works the same
            // for a network image and for a video poster tile without either
            // widget knowing about it.
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: child,
            ),
            // The blur alone leaves bright shapes readable; a scrim over it
            // flattens them and makes the label legible on any content.
            Positioned.fill(
              child: ColoredBox(color: Colors.black.withOpacity(0.28)),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.visibility_off_rounded,
                    color: Colors.white, size: 28),
                const SizedBox(height: 6),
                Text(
                  'Tap to view',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
