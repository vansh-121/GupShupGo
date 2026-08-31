import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/models/anonymous_room_model.dart';
import 'package:video_chat_app/provider/call_state_provider.dart';
import 'package:video_chat_app/provider/subscription_provider.dart';
import 'package:video_chat_app/services/anonymous_chat_service.dart';
import 'package:video_chat_app/screens/anonymous/anonymous_lobby_screen.dart';
import 'package:video_chat_app/screens/chat_screen.dart';
import 'package:video_chat_app/services/ads/interstitial_ad_service.dart';
import 'package:video_chat_app/services/user_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/widgets/linkified_text.dart';

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

  AnonymousRoomModel? _room;
  StreamSubscription<DocumentSnapshot>? _roomSub;
  bool _strangerDisconnected = false;
  bool _isEnding = false;
  bool _sendingFriendRequest = false;
  bool _respondingToRequest = false;
  bool _transitioningToE2EE = false;

  @override
  void initState() {
    super.initState();
    _loadRoom();
    // Only warms one when the next skip is the one that would show it, so the
    // user isn't left staring at the chat they just left while an ad loads.
    unawaited(InterstitialAdService.instance.preloadForNextSkip());
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
}
