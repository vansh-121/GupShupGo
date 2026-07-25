import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/models/anonymous_room_model.dart';
import 'package:video_chat_app/services/anonymous_chat_service.dart';
import 'package:video_chat_app/screens/anonymous/anonymous_lobby_screen.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// Dedicated 1-on-1 anonymous chat screen between two strangers.
class AnonymousChatScreen extends StatefulWidget {
  final String roomId;
  final String currentUserId;

  const AnonymousChatScreen({
    super.key,
    required this.roomId,
    required this.currentUserId,
  });

  @override
  State<AnonymousChatScreen> createState() => _AnonymousChatScreenState();
}

class _AnonymousChatScreenState extends State<AnonymousChatScreen> {
  final _service = AnonymousChatService.instance;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  AnonymousRoomModel? _room;
  StreamSubscription<DocumentSnapshot>? _roomSub;
  bool _strangerDisconnected = false;
  bool _isEnding = false;

  @override
  void initState() {
    super.initState();
    _loadRoom();
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadRoom() async {
    final room = await _service.getRoom(widget.roomId);
    if (mounted) {
      setState(() => _room = room);
    }

    // Listen for room status changes (stranger leaving)
    _roomSub = _service.listenToRoom(widget.roomId).listen((snapshot) {
      if (!snapshot.exists || !mounted) return;
      final updatedRoom = AnonymousRoomModel.fromFirestore(snapshot);
      setState(() {
        _room = updatedRoom;
        if (!updatedRoom.isActive &&
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

    // Scroll to bottom after sending
    _scrollToBottom();
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
    // End current session
    if (_room != null && _room!.isActive) {
      await _service.endSession(widget.roomId, widget.currentUserId);
    }
    if (!mounted) return;
    // Navigate to lobby to find a new stranger
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AnonymousLobbyScreen(currentUserId: widget.currentUserId),
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

                // Auto-scroll to bottom on new messages
                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg =
                        messages[index].data() as Map<String, dynamic>;
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

                    // Regular text messages
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
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
                        child: Text(
                          text,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: isMe ? Colors.white : c.textHigh,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ── Stranger Disconnected Banner ──────────────────────
          if (_strangerDisconnected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
          if (!_strangerDisconnected && _room!.isActive)
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
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: c.textHigh,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a message…',
                        hintStyle: GoogleFonts.poppins(
                          color: c.textLow,
                          fontSize: 15,
                        ),
                        filled: true,
                        fillColor: c.surfaceAlt,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: c.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
