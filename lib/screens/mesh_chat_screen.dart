import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/services/chat_cache_service.dart';
import 'package:video_chat_app/services/mesh_network_service.dart';
import 'package:video_chat_app/services/voice_recorder_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/widgets/voice_message_bubble.dart';

/// Direct peer-to-peer chat over the mesh network.
///
/// Unlike [ChatScreen] this screen has no Firestore dependency — it talks
/// only to a single discovered nearby peer via [MeshNetworkService] and
/// persists the conversation locally via [ChatCacheService].
class MeshChatScreen extends StatefulWidget {
  final MeshPeer peer;

  const MeshChatScreen({Key? key, required this.peer}) : super(key: key);

  @override
  State<MeshChatScreen> createState() => _MeshChatScreenState();
}

class _MeshChatScreenState extends State<MeshChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatCacheService _cache = ChatCacheService();
  final ImagePicker _imagePicker = ImagePicker();
  final VoiceRecorderService _voiceRecorder = VoiceRecorderService();

  StreamSubscription<MessageModel>? _meshSub;
  final List<MessageModel> _messages = [];

  bool _isSending = false;
  bool _isUploadingImage = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    final mesh = Provider.of<MeshNetworkService>(context, listen: false);
    mesh.setActiveConversation(widget.peer.userId);
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
    final mesh = Provider.of<MeshNetworkService>(context, listen: false);
    _meshSub = mesh.meshMessageStream.listen((msg) {
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
      final mesh = Provider.of<MeshNetworkService>(context, listen: false);
      final msg = await mesh.sendViaMesh(
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

  Future<void> _pickAndSendImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked == null) return;
      setState(() => _isUploadingImage = true);
      final mesh = Provider.of<MeshNetworkService>(context, listen: false);
      final msg = await mesh.sendImageViaMesh(
        receiverId: widget.peer.userId,
        filePath: picked.path,
      );
      setState(() => _messages.add(msg));
      _scrollToBottom();
    } catch (e) {
      _showError('Failed to send image: $e');
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _startVoiceRecording() async {
    HapticFeedback.mediumImpact();
    await _voiceRecorder.startRecording();
    if (mounted) setState(() {});
  }

  Future<void> _stopVoiceRecording() async {
    if (!_voiceRecorder.isRecording) return;
    final duration = _voiceRecorder.elapsed.inSeconds;
    final path = await _voiceRecorder.stopRecording();
    if (mounted) setState(() {});
    if (path == null || duration < 1) return;
    try {
      final mesh = Provider.of<MeshNetworkService>(context, listen: false);
      final msg = await mesh.sendAudioViaMesh(
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
    // Clear before stream/state teardown so any late notifications fire
    // through the global banner instead of into a disposed screen.
    Provider.of<MeshNetworkService>(context, listen: false)
        .setActiveConversation(null);
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
                const Icon(Icons.cell_tower_rounded,
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
              Icon(Icons.cell_tower_rounded, size: 56, color: c.primary),
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
            else
              Text(
                msg.text,
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
                Icon(Icons.cell_tower_rounded,
                    size: 11,
                    color: isMe ? Colors.white.withOpacity(0.7) : c.textLow),
              ],
            ),
          ],
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
        _isUploadingImage
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
                onPressed: _pickAndSendImage,
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
