import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/provider/call_state_provider.dart';
import 'package:video_chat_app/screens/call_screen.dart';
import 'package:video_chat_app/services/chat_service.dart';
import 'package:video_chat_app/services/fcm_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';

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

  ChatScreen({
    required this.contact,
    required this.currentUserId,
    this.currentUserName,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  bool _isLoading = true;
  bool _isSending = false;

  // ─── Typing indicator state ───────────────────────────────────────
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _isOtherUserTyping = false;
  StreamSubscription<bool>? _typingSubscription;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _messageController.addListener(_onTextChanged);
  }

  Future<void> _initializeChat() async {
    try {
      // Ensure chat room exists
      await _chatService.getOrCreateChatRoom(
        widget.currentUserId,
        widget.contact.id,
      );

      // Mark messages as delivered first (in case they were sent)
      await _chatService.markMessagesAsDelivered(
        widget.currentUserId,
        widget.contact.id,
      );

      // Mark messages as read when opening chat (user is viewing them)
      await _chatService.markMessagesAsRead(
        widget.currentUserId,
        widget.contact.id,
      );

      setState(() {
        _isLoading = false;
      });

      // Start listening for new messages and mark them as read immediately
      _startReadReceiptListener();

      // Start listening for the other user's typing status
      _listenToTypingStatus();
    } catch (e) {
      print('Error initializing chat: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Continuously mark new incoming messages as read while chat is open
  void _startReadReceiptListener() {
    // This will be called when new messages arrive via StreamBuilder
    // We'll mark them as read in the stream listener
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
  }

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
    await _chatService.markMessagesAsRead(
      widget.currentUserId,
      widget.contact.id,
    );
  }

  Future<void> _initiateVideoCall() async {
    if (widget.currentUserId == widget.contact.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot call yourself')),
      );
      return;
    }

    try {
      final channelId = '${widget.currentUserId}_to_${widget.contact.id}';
      final callState = Provider.of<CallStateNotifier>(context, listen: false);
      callState.updateState(CallState.Calling);

      print(
          'Initiating video call to ${widget.contact.name} on channel $channelId');

      await FCMService().sendCallNotification(
          widget.contact.id, widget.currentUserId, channelId);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            channelId: channelId,
            isCaller: true,
            calleeId: widget.contact.id,
            calleeName: widget.contact.name,
          ),
        ),
      );
    } catch (e) {
      print('Error initiating video call: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start video call: $e')),
      );
    }
  }

  Future<void> _initiateAudioCall() async {
    if (widget.currentUserId == widget.contact.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot call yourself')),
      );
      return;
    }

    try {
      final channelId = '${widget.currentUserId}_${widget.contact.id}_a';
      final callState = Provider.of<CallStateNotifier>(context, listen: false);
      callState.updateState(CallState.Calling);

      print(
          'Initiating audio call to ${widget.contact.name} on channel $channelId');

      await FCMService().sendCallNotification(
          widget.contact.id, widget.currentUserId, channelId,
          isAudioOnly: true);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            channelId: channelId,
            isCaller: true,
            calleeId: widget.contact.id,
            calleeName: widget.contact.name,
            isAudioOnly: true,
          ),
        ),
      );
    } catch (e) {
      print('Error initiating audio call: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start audio call: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      _messageController.clear();
      // User sent the message — stop typing indicator immediately
      _stopTyping();

      await _chatService.sendMessage(
        senderId: widget.currentUserId,
        receiverId: widget.contact.id,
        text: text,
        senderName: widget.currentUserName,
      );

      _scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message')),
      );
      // Restore the text if sending failed
      _messageController.text = text;
    } finally {
      setState(() {
        _isSending = false;
      });
    }
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
    } else if (messageDate == today.subtract(Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildDateDivider(String date) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primaryLt,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          date,
          style: GoogleFonts.poppins(
            color: AppColors.primaryDk,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(MessageModel message) {
    final isMe = message.senderId == widget.currentUserId;

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
          color: isMe ? AppColors.sent : AppColors.received,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
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
            Text(
              message.text,
              style: GoogleFonts.poppins(
                color: isMe ? Colors.white : AppColors.textHigh,
                fontSize: 14.5,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: GoogleFonts.poppins(
                    color: isMe
                        ? Colors.white.withOpacity(0.75)
                        : AppColors.textLow,
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _buildMessageStatusIcon(message),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageStatusIcon(MessageModel message) {
    switch (message.status) {
      case MessageStatus.sent:
        return const Icon(Icons.done_rounded, size: 14, color: Colors.white70);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all_rounded, size: 14, color: Colors.white70);
      case MessageStatus.read:
        return const Icon(Icons.done_all_rounded, size: 14,
            color: Color(0xFFA5F3FC));
    }
  }

  Widget _buildMessagesList(List<MessageModel> messages) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.primaryLt,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.waving_hand_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Say hello!',
              style: GoogleFonts.poppins(
                color: AppColors.textHigh,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Start the conversation',
              style: GoogleFonts.poppins(
                color: AppColors.textMid,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Group messages by date
    List<Widget> messageWidgets = [];
    String? lastDate;

    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      final messageDate = _formatMessageDate(message.timestamp);

      if (lastDate != messageDate) {
        messageWidgets.add(_buildDateDivider(messageDate));
        lastDate = messageDate;
      }

      messageWidgets.add(_buildMessage(message));
    }

    // Append typing bubble as the last item in the conversation
    if (_isOtherUserTyping) {
      messageWidgets.add(_buildTypingBubble());
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      children: messageWidgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.chatBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: AppColors.border,
        scrolledUnderElevation: 0.8,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: widget.contact.avatarUrl.isNotEmpty
                      ? NetworkImage(widget.contact.avatarUrl)
                      : null,
                  backgroundColor: AppColors.primaryLt,
                  child: widget.contact.avatarUrl.isEmpty
                      ? Text(
                          widget.contact.name.isNotEmpty
                              ? widget.contact.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
                if (widget.contact.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: AppColors.online,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contact.name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHigh,
                    ),
                  ),
                  if (_isOtherUserTyping)
                    Text(
                      'typing...',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else if (widget.contact.isOnline)
                    Text(
                      'Online',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.online,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_rounded),
            onPressed: _initiateAudioCall,
            tooltip: 'Audio Call',
          ),
          IconButton(
            icon: const Icon(Icons.videocam_rounded),
            onPressed: _initiateVideoCall,
            tooltip: 'Video Call',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {},
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(value: 'info', child: Text('Contact info', style: GoogleFonts.poppins())),
                PopupMenuItem(value: 'media', child: Text('Media & docs', style: GoogleFonts.poppins())),
                PopupMenuItem(value: 'search', child: Text('Search', style: GoogleFonts.poppins())),
                PopupMenuItem(value: 'mute', child: Text('Mute notifications', style: GoogleFonts.poppins())),
                PopupMenuItem(
                  value: 'block',
                  child: Text('Block contact',
                      style: GoogleFonts.poppins(color: AppColors.error))),
              ];
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<MessageModel>>(
                    stream: _chatService.getMessages(
                      widget.currentUserId,
                      widget.contact.id,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary));
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  size: 48, color: AppColors.error),
                              const SizedBox(height: 16),
                              Text('Error loading messages',
                                  style: GoogleFonts.poppins(
                                      color: AppColors.textMid)),
                              TextButton(
                                onPressed: () => setState(() {}),
                                child: const Text('Try again'),
                              ),
                            ],
                          ),
                        );
                      }

                      final messages = snapshot.data ?? [];

                      final hasUnreadMessages = messages.any((m) =>
                          m.receiverId == widget.currentUserId &&
                          m.status != MessageStatus.read);
                      if (hasUnreadMessages) {
                        _markNewMessagesAsRead();
                      }

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (messages.isNotEmpty) _scrollToBottom();
                      });

                      return _buildMessagesList(messages);
                    },
                  ),
                ),
                // ── Message input bar ────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                          color: AppColors.divider, width: 1),
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.attach_file_rounded,
                              color: AppColors.textMid, size: 22),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Attachments coming soon!')),
                            );
                          },
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color: AppColors.border, width: 1),
                            ),
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Message...',
                                hintStyle: GoogleFonts.poppins(
                                    color: AppColors.textLow, fontSize: 14),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                fillColor: Colors.transparent,
                                filled: false,
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                              ),
                              style: GoogleFonts.poppins(
                                  fontSize: 14, color: AppColors.textHigh),
                              maxLines: 5,
                              minLines: 1,
                              textCapitalization:
                                  TextCapitalization.sentences,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _isSending ? null : _sendMessage,
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 200),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _isSending
                                  ? AppColors.textLow
                                  : AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: _isSending
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// Animated typing dots bubble — appears at the bottom left of the chat.
  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 16, bottom: 4, top: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.received,
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

  @override
  void dispose() {
    // Clear typing status so the other user doesn't see a stale indicator
    _stopTyping();
    _typingTimer?.cancel();
    _typingSubscription?.cancel();
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
                    color: Colors.grey[500],
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
