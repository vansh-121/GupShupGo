import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/provider/subscription_provider.dart';
import 'package:video_chat_app/services/chat_cache_service.dart';
import 'package:video_chat_app/services/mesh_network_service.dart';
import 'package:video_chat_app/services/voice_recorder_service.dart';
import 'package:video_chat_app/screens/plaintext_view_once_viewer.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/widgets/document_bubble.dart';
import 'package:video_chat_app/widgets/linkified_text.dart';
import 'package:video_chat_app/widgets/location_bubble.dart';
import 'package:video_chat_app/widgets/location_share_sheet.dart';
import 'package:video_chat_app/widgets/video_message_widgets.dart';
import 'package:video_chat_app/widgets/voice_message_bubble.dart';

/// Direct peer-to-peer chat over the mesh network.
///
/// Unlike [ChatScreen] this screen has no Firestore dependency — it talks
/// only to a single discovered nearby peer via [MeshNetworkService] and
/// persists the conversation locally via [ChatCacheService].
class MeshChatScreen extends StatefulWidget {
  final MeshPeer peer;

  const MeshChatScreen({super.key, required this.peer});

  @override
  State<MeshChatScreen> createState() => _MeshChatScreenState();
}

class _MeshChatScreenState extends State<MeshChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatCacheService _cache = ChatCacheService();
  final ImagePicker _imagePicker = ImagePicker();
  final VoiceRecorderService _voiceRecorder = VoiceRecorderService();

  // Stored during initState so dispose() never needs to call Provider.of(context).
  // Calling Provider.of in dispose() is unsafe — the context can be in an
  // invalid state during teardown, causing setActiveConversation(null) to be
  // silently skipped and permanently suppressing notifications for this peer.
  late MeshNetworkService _mesh;

  StreamSubscription<MessageModel>? _meshSub;
  final List<MessageModel> _messages = [];

  bool _isSending = false;
  bool _isUploadingImage = false;
  bool _isUploadingVideo = false;
  bool _isUploadingDocument = false;
  bool _hasText = false;

  /// Whether the attach sheet's "View once" toggle is on. Reset to false every
  /// time the sheet opens, so it is a per-send opt-in and never sticky.
  bool _viewOnceArmed = false;

  /// View-once message ids the user has already opened this session. Local and
  /// State-scoped: mesh messages are peer-to-peer with no shared server to write
  /// "opened" back to, so this is the same in-session model the anonymous chat
  /// uses. Opening flips the bubble to "Opened" and blocks a second view.
  final Set<String> _consumedViewOnce = {};

  @override
  void initState() {
    super.initState();
    _mesh = Provider.of<MeshNetworkService>(context, listen: false);
    _mesh.setActiveConversation(widget.peer.userId);
    _loadPersistedMessages();
    _listenToMesh();
    _messageController.addListener(_onTextChanged);
  }

  void _loadPersistedMessages() {
    final pending = _cache.getPendingMeshMessages();
    final peerId = widget.peer.userId;
    final mine = pending.where((m) =>
        (m.senderId == peerId) || (m.receiverId == peerId));
    setState(() => _messages.addAll(mine));
    _scrollToBottom();
  }

  void _listenToMesh() {
    _meshSub = _mesh.meshMessageStream.listen((msg) {
      // Only show messages exchanged with this peer.
      final peerId = widget.peer.userId;
      final isForThisPeer = (msg.senderId == peerId) ||
          (msg.receiverId == peerId);
      if (!isForThisPeer) return;
      if (_messages.any((m) => m.id == msg.id)) return;
      setState(() => _messages.add(msg));
      _scrollToBottom();
    });
  }

  void _onTextChanged() {
    final has = _messageController.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  Future<void> _sendText() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      _messageController.clear();
      final msg = await _mesh.sendViaMesh(
        receiverId: widget.peer.userId,
        text: text,
      );
      setState(() => _messages.add(msg));
      _scrollToBottom();
    } catch (e) {
      _showError('Failed to send: $e');
      _messageController.text = text;
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickAndSendImage({bool viewOnce = false}) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked == null) return;
      setState(() => _isUploadingImage = true);
      final msg = await _mesh.sendImageViaMesh(
        receiverId: widget.peer.userId,
        filePath: picked.path,
        viewOnce: viewOnce,
      );
      setState(() => _messages.add(msg));
      _scrollToBottom();
    } catch (e) {
      _showError('Failed to send image: $e');
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _pickAndSendVideo({bool viewOnce = false}) async {
    try {
      final picked = await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (picked == null) return;

      // Mesh videos are streamed peer-to-peer with no server compression and no
      // progress bar, so they get a tighter cap than an online chat video.
      // Checked before the poster/duration probes so a huge pick is rejected
      // without spinning up a decoder.
      final bytes = await File(picked.path).length();
      if (bytes > kMaxMeshVideoBytes) {
        _showError(
          'This video is too large to send nearby — the limit is '
          '${(kMaxMeshVideoBytes / (1024 * 1024)).round()} MB. Try a shorter clip.',
        );
        return;
      }

      setState(() => _isUploadingVideo = true);
      // Both optional — a probe failure just drops the preview, never the send.
      final poster = await generateMeshVideoPoster(picked.path);
      final durSec = await probeMeshVideoDurationSeconds(picked.path);
      final msg = await _mesh.sendVideoViaMesh(
        receiverId: widget.peer.userId,
        filePath: picked.path,
        durationSeconds: durSec,
        thumbnailBase64: poster,
        viewOnce: viewOnce,
      );
      setState(() => _messages.add(msg));
      _scrollToBottom();
    } catch (e) {
      _showError('Failed to send video: $e');
    } finally {
      if (mounted) setState(() => _isUploadingVideo = false);
    }
  }

  /// Pick any file and hand it to the peer over the mesh.
  ///
  /// Mirrors [_pickAndSendVideo]: size-check on a `stat` before anything else,
  /// then straight to the transport. Nothing is encrypted or uploaded — there is
  /// no network here. The message is left `syncPending` and [MeshNetworkService]
  /// seals it into `chat_documents/` when connectivity returns.
  Future<void> _pickAndSendDocument() async {
    try {
      // `withData: false` — we want the path, not the bytes in memory.
      final result = await FilePicker.platform.pickFiles(withData: false);
      final picked = result?.files.single;
      final path = picked?.path;
      if (picked == null || path == null) return;

      final bytes = await File(path).length();
      if (bytes > kMaxMeshDocumentBytes) {
        _showError(
          'This file is too large to send nearby — the limit is '
          '${(kMaxMeshDocumentBytes / (1024 * 1024)).round()} MB.',
        );
        return;
      }
      if (bytes == 0) {
        _showError('That file is empty.');
        return;
      }

      setState(() => _isUploadingDocument = true);
      final msg = await _mesh.sendDocumentViaMesh(
        receiverId: widget.peer.userId,
        filePath: path,
        fileName: picked.name,
      );
      setState(() => _messages.add(msg));
      _scrollToBottom();
    } catch (e) {
      _showError('Failed to send file: $e');
    } finally {
      if (mounted) setState(() => _isUploadingDocument = false);
    }
  }

  /// Bottom-sheet chooser behind the composer's paperclip: photo or video.
  void _showAttachSheet(AppThemeColors c) {
    HapticFeedback.selectionClick();
    // A fresh sheet always opens with view-once off — it is a per-send choice.
    _viewOnceArmed = false;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_rounded, color: c.primary),
                title: Text('Photo',
                    style:
                        GoogleFonts.poppins(color: c.textHigh, fontSize: 15)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _pickAndSendImage(viewOnce: _viewOnceArmed);
                },
              ),
              ListTile(
                leading: Icon(Icons.videocam_rounded, color: c.primary),
                title: Text('Video',
                    style:
                        GoogleFonts.poppins(color: c.textHigh, fontSize: 15)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _pickAndSendVideo(viewOnce: _viewOnceArmed);
                },
              ),
              // View-once applies to the next photo or video only. Documents,
              // location and voice notes are unaffected — a view-once document
              // has no meaning offline, and a pin/voice note isn't visual.
              SwitchListTile(
                value: _viewOnceArmed,
                activeColor: c.primary,
                secondary: Icon(
                  _viewOnceArmed ? Icons.timer_rounded : Icons.timer_outlined,
                  color: _viewOnceArmed ? c.primary : c.textMid,
                ),
                title: Text('View once',
                    style:
                        GoogleFonts.poppins(color: c.textHigh, fontSize: 15)),
                subtitle: Text(
                  'Opens one time, and screenshots are blocked on Android.',
                  style: GoogleFonts.poppins(fontSize: 11, color: c.textLow),
                ),
                onChanged: (v) {
                  setSheetState(() => _viewOnceArmed = v);
                  HapticFeedback.selectionClick();
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.insert_drive_file_rounded, color: c.primary),
                title: Text('Document',
                    style:
                        GoogleFonts.poppins(color: c.textHigh, fontSize: 15)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _pickAndSendDocument();
                },
              ),
              ListTile(
                leading: Icon(Icons.location_on_rounded, color: c.primary),
                title: Text('Location',
                    style:
                        GoogleFonts.poppins(color: c.textHigh, fontSize: 15)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _pickAndSendLocation();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Paperclip → Location: acquire a pin through the shared confirm flow and
  /// broadcast it over the mesh. A pin carries no file, so it rides the same
  /// BYTES channel as a text message — see
  /// [MeshNetworkService.sendLocationViaMesh]. [pickLocationToShare] is the same
  /// helper the online chat uses, so the sensitive permission flow stays
  /// identical on both transports.
  Future<void> _pickAndSendLocation() async {
    final pos = await pickLocationToShare(context);
    if (pos == null || !mounted) return;
    try {
      final msg = await _mesh.sendLocationViaMesh(
        receiverId: widget.peer.userId,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      setState(() => _messages.add(msg));
      _scrollToBottom();
    } catch (e) {
      _showError('Failed to send location: $e');
    }
  }

  Future<void> _startVoiceRecording() async {
    HapticFeedback.mediumImpact();
    // Same cap as an online chat — a mesh voice note is the same feature over a
    // different transport, and leaving it uncapped would make the limit trivially
    // bypassable by turning off Wi-Fi. Read before the await: `startRecording`
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
    if (path == null || duration < 1) return;
    try {
      final msg = await _mesh.sendAudioViaMesh(
        receiverId: widget.peer.userId,
        filePath: path,
        durationSeconds: duration,
      );
      setState(() => _messages.add(msg));
      _scrollToBottom();
    } catch (e) {
      _showError('Failed to send voice note: $e');
    }
  }

  Future<void> _cancelVoiceRecording() async {
    HapticFeedback.heavyImpact();
    await _voiceRecorder.cancelRecording();
    if (mounted) setState(() {});
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    // Use stored _mesh reference — calling Provider.of(context) in dispose()
    // is unsafe because the context may already be partially detached,
    // causing setActiveConversation(null) to silently not run and permanently
    // suppressing notifications for this peer.
    _mesh.setActiveConversation(null);
    _meshSub?.cancel();
    _voiceRecorder.dispose();
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Scaffold(
      backgroundColor: c.chatBg,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: c.primaryLt,
              child: Text(
                widget.peer.displayName.isNotEmpty
                    ? widget.peer.displayName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: c.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.peer.displayName,
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: c.textHigh)),
                  Consumer<MeshNetworkService>(
                    builder: (_, mesh, __) {
                      final live = mesh.peers.firstWhere(
                        (p) => p.endpointId == widget.peer.endpointId,
                        orElse: () => widget.peer,
                      );
                      return Text(
                        live.isConnected
                            ? 'Offline chat · connected'
                            : 'Connecting…',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: live.isConnected ? c.online : c.textLow,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF2D2D2D),
            child: Row(
              children: [
                const Icon(Icons.sensors_rounded,
                    color: Color(0xFF4ADE80), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Offline chat — no internet, no servers',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildMessageList(c)),
          _buildInputBar(c),
        ],
      ),
    );
  }

  Widget _buildMessageList(AppThemeColors c) {
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sensors_rounded, size: 56, color: c.primary),
              const SizedBox(height: 16),
              Text('Say hi to ${widget.peer.displayName}',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: c.textHigh)),
              const SizedBox(height: 6),
              Text(
                'You\'re in offline chat. Messages stay between you and ${widget.peer.displayName}.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: c.textMid),
              ),
            ],
          ),
        ),
      );
    }

    final sorted = [..._messages]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: sorted.length,
      itemBuilder: (context, i) => _buildBubble(sorted[i], c),
    );
  }

  Widget _buildBubble(MessageModel msg, AppThemeColors c) {
    final isMe = msg.senderId != widget.peer.userId;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 2,
          bottom: 2,
          left: isMe ? 64 : 16,
          right: isMe ? 16 : 64,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isMe ? c.sent : c.received,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft:
                isMe ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight:
                isMe ? const Radius.circular(4) : const Radius.circular(18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.type == MessageType.audio)
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 200),
                child: VoiceMessageBubble(message: msg, isMe: isMe),
              )
            else if (msg.viewOnce &&
                (msg.type == MessageType.image ||
                    msg.type == MessageType.video))
              _buildViewOnceBubble(c, msg: msg, isMe: isMe)
            else if (msg.type == MessageType.image &&
                msg.localFilePath != null &&
                File(msg.localFilePath!).existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                      maxWidth: 220, maxHeight: 280),
                  child: Image.file(
                    File(msg.localFilePath!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else if (msg.type == MessageType.video)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ChatVideoPlayerScreen(
                      localPath: msg.localFilePath,
                      url: msg.mediaUrl,
                      thumbnailBase64: msg.videoThumbnailBase64,
                      caption: msg.text,
                    ),
                  ),
                ),
                child: VideoThumbnailTile(message: msg),
              )
            else if (msg.type == MessageType.location)
              LocationBubble(message: msg, isMe: isMe)
            else if (msg.type == MessageType.document)
              // The bubble opens straight from `localFilePath` and degrades on a
              // missing `mediaKey`, which is exactly a mesh document's shape: a
              // local file that has never been uploaded.
              DocumentBubble(message: msg, isMe: isMe)
            else
              LinkifiedText(
                msg.text,
                linkColor: isMe ? Colors.white : c.primary,
                style: GoogleFonts.poppins(
                  color: isMe ? Colors.white : c.textHigh,
                  fontSize: 14.5,
                ),
              ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(msg.timestamp),
                  style: GoogleFonts.poppins(
                    color: isMe ? Colors.white.withOpacity(0.75) : c.textLow,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.sensors_rounded,
                    size: 11,
                    color: isMe ? Colors.white.withOpacity(0.7) : c.textLow),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Placeholder bubble for a view-once photo/video. It never renders the media
  /// itself — that only happens once, full-screen, inside [PlaintextViewOnceViewer].
  ///
  ///  - Sender side: inert "sent" chip; there is nothing to open on your own end.
  ///  - Receiver, unopened: tappable, invites the one look.
  ///  - Receiver, opened (tracked for the session in [_consumedViewOnce]): "Opened",
  ///    can't be reopened.
  ///
  /// Like the anonymous surface this is UX-only: the mesh has no server and no
  /// Signal session, so there is no key to destroy. The honesty lives in the
  /// viewer's footer and in never re-showing the frame.
  Widget _buildViewOnceBubble(
    AppThemeColors c, {
    required MessageModel msg,
    required bool isMe,
  }) {
    final isVideo = msg.type == MessageType.video;
    final opened = _consumedViewOnce.contains(msg.id);
    final label = isVideo ? 'Video' : 'Photo';

    if (isMe) {
      return _viewOnceChip(
        c,
        isMe: true,
        icon: isVideo ? Icons.videocam_outlined : Icons.photo_camera_outlined,
        text: '$label · View once · sent',
        onTap: null,
      );
    }

    if (opened) {
      return _viewOnceChip(
        c,
        isMe: false,
        icon: Icons.check_circle_outline_rounded,
        text: 'Opened',
        onTap: null,
      );
    }

    return _viewOnceChip(
      c,
      isMe: false,
      icon: isVideo ? Icons.videocam_rounded : Icons.photo_camera_rounded,
      text: 'Tap to view · $label',
      onTap: () => _openViewOnce(msg),
    );
  }

  Widget _viewOnceChip(
    AppThemeColors c, {
    required bool isMe,
    required IconData icon,
    required String text,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18, color: isMe ? Colors.white : c.primary),
            const SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.poppins(
                color: isMe ? Colors.white : c.textHigh,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Confirm, mark consumed for the session, then open the media full-screen.
  /// The message is flipped to "Opened" the instant we push the route, so the
  /// bubble can't be tapped a second time even if the viewer is dismissed early.
  Future<void> _openViewOnce(MessageModel msg) async {
    final path = msg.localFilePath;
    if (path == null || path.isEmpty || !File(path).existsSync()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This media is no longer available.')),
      );
      return;
    }

    final c = AppThemeColors.of(context);
    final isVideo = msg.type == MessageType.video;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text('View once',
            style: GoogleFonts.poppins(
                color: c.textHigh, fontWeight: FontWeight.w600)),
        content: Text(
          "You can only open this ${isVideo ? 'video' : 'photo'} one time. "
          "It closes for good when you leave.",
          style: GoogleFonts.poppins(color: c.textMid, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: c.textMid)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text('Open',
                style: GoogleFonts.poppins(
                    color: c.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _consumedViewOnce.add(msg.id));

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PlaintextViewOnceViewer(
          isVideo: isVideo,
          localFilePath: path,
          thumbnailBase64: msg.videoThumbnailBase64,
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
  }

  Widget _buildInputBar(AppThemeColors c) {
    final isRecording = _voiceRecorder.isRecording;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.divider, width: 1)),
      ),
      child: SafeArea(
        child: isRecording ? _buildRecordingBar(c) : _buildNormalBar(c),
      ),
    );
  }

  Widget _buildNormalBar(AppThemeColors c) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        (_isUploadingImage || _isUploadingVideo || _isUploadingDocument)
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
                icon: Icon(Icons.attach_file_rounded,
                    color: c.textMid, size: 22),
                onPressed: () => _showAttachSheet(c),
              ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: c.surfaceAlt,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: c.border, width: 1),
            ),
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Message...',
                hintStyle:
                    GoogleFonts.poppins(color: c.textLow, fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
              style: GoogleFonts.poppins(fontSize: 14, color: c.textHigh),
              maxLines: 5,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendText(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (_hasText || _isSending)
          GestureDetector(
            onTap: _isSending ? null : _sendText,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isSending ? c.textLow : c.primary,
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded,
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
              child: const Icon(Icons.mic_rounded,
                  color: Colors.white, size: 22),
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
          decoration:
              BoxDecoration(color: c.error, shape: BoxShape.circle),
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
            child:
                Icon(Icons.delete_outline_rounded, color: c.error, size: 18),
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
