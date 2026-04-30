import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/provider/call_state_provider.dart';
import 'package:video_chat_app/provider/connectivity_provider.dart';
import 'package:video_chat_app/screens/call_screen.dart';
import 'package:video_chat_app/services/chat_service.dart';
import 'package:video_chat_app/services/fcm_service.dart';
import 'package:video_chat_app/services/mesh_network_service.dart';
import 'package:video_chat_app/services/settings_service.dart';
import 'package:video_chat_app/services/user_service.dart';
import 'package:video_chat_app/services/voice_recorder_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/widgets/voice_message_bubble.dart';

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
  final UserService _userService = UserService();

  bool _isLoading = true;
  bool _isSending = false;
  int _lastMessageCount = 0;

  // ─── Search state ─────────────────────────────────────────────────
  bool _isSearchMode = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // ─── Mute state ───────────────────────────────────────────────────
  final SettingsService _settingsService = SettingsService();
  late bool _isMuted;

  // ── Image picker ─────────────────────────────────────────────────
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingImage = false;

  // ── Voice recording ───────────────────────────────────────────────
  final VoiceRecorderService _voiceRecorder = VoiceRecorderService();
  bool _isSendingVoice = false;
  bool _hasText = false; // tracks if text field has content for mic/send toggle

  // ─── Block state ──────────────────────────────────────────────────
  bool _isBlocked = false;      // current user blocked the contact
  bool _isBlockedByContact = false; // contact blocked the current user

  // ─── Online status state (real-time from Firestore) ───────────────
  late bool _isContactOnline;
  StreamSubscription? _onlineStatusSubscription;

  // ─── Typing indicator state ───────────────────────────────────────
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _isOtherUserTyping = false;
  StreamSubscription<bool>? _typingSubscription;

  // ─── Mesh messaging state ─────────────────────────────────────────
  StreamSubscription<MessageModel>? _meshMessageSubscription;
  final List<MessageModel> _meshMessages = [];

  @override
  void initState() {
    super.initState();
    _isContactOnline = widget.contact.isOnline; // seed from passed-in value
    final chatRoomId = _chatService.getChatRoomId(
        widget.currentUserId, widget.contact.id);
    _isMuted = _settingsService.isChatMuted(chatRoomId);
    _initializeChat();
    _messageController.addListener(_onTextChanged);
  }

  Future<void> _initializeChat() async {
    try {
      // ── Check block status first ───────────────────────────────────
      await _checkBlockStatus();

      // Ensure chat room exists
      await _chatService.getOrCreateChatRoom(
        widget.currentUserId,
        widget.contact.id,
      );

      // Mark messages as delivered first (in case they were sent)
      if (!_isBlockedByContact) {
        await _chatService.markMessagesAsDelivered(
          widget.currentUserId,
          widget.contact.id,
        );
      }

      // Mark messages as read when opening chat (user is viewing them)
      if (_settingsService.showReadReceipts && !_isBlocked) {
        await _chatService.markMessagesAsRead(
          widget.currentUserId,
          widget.contact.id,
        );
      }

      setState(() {
        _isLoading = false;
      });

      // Start listening for new messages and mark them as read immediately
      _startReadReceiptListener();

      // Start listening for the other user's typing status (skip if blocked)
      if (!_isBlocked && !_isBlockedByContact) {
        _listenToTypingStatus();
      }

      // Start listening for real-time online/offline status changes
      _listenToOnlineStatus();

      // Start listening for mesh messages (offline messaging)
      _listenToMeshMessages();
    } catch (e) {
      print('Error initializing chat: $e');
      setState(() {
        _isLoading = false;
      });
    }
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
      final myDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .get();
      final theirDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.contact.id)
          .get();

      final myBlocked =
          List<String>.from(myDoc.data()?['blockedUsers'] ?? []);
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
    _onlineStatusSubscription = _userService
        .getUserStream(widget.contact.id)
        .listen((user) {
      if (mounted && user != null) {
        final effectiveOnline =
            (_isBlocked || _isBlockedByContact) ? false : user.isOnline;
        if (_isContactOnline != effectiveOnline) {
          setState(() {
            _isContactOnline = effectiveOnline;
          });
        }
      }
    });
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
    // Only send read receipts if the user has enabled them
    if (!_settingsService.showReadReceipts) return;
    await _chatService.markMessagesAsRead(
      widget.currentUserId,
      widget.contact.id,
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
    if (_isBlocked || _isBlockedByContact) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot call this contact')),
      );
      return;
    }
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
    if (_isBlocked || _isBlockedByContact) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send messages to this contact')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      _messageController.clear();
      // User sent the message — stop typing indicator immediately
      _stopTyping();

      // Check connectivity — send via mesh if offline
      final connectivity =
          Provider.of<ConnectivityProvider>(context, listen: false);

      if (!connectivity.isOnline) {
        // ── Offline: send via mesh network ──────────────────────────
        try {
          final meshService =
              Provider.of<MeshNetworkService>(context, listen: false);
          final meshMsg = await meshService.sendViaMesh(
            receiverId: widget.contact.id,
            text: text,
            senderName: widget.currentUserName,
          );
          setState(() => _meshMessages.add(meshMsg));
          _scrollToBottom();
        } catch (_) {
          // Mesh not available — show error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'No internet & mesh unavailable. Message not sent.')),
          );
          _messageController.text = text;
        }
      } else {
        // ── Online: send via Firestore as usual ─────────────────────
        await _chatService.sendMessage(
          senderId: widget.currentUserId,
          receiverId: widget.contact.id,
          text: text,
          senderName: widget.currentUserName,
        );
        _scrollToBottom();
      }
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
    final c = AppThemeColors.of(context);
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
    final c = AppThemeColors.of(context);
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
          color: isMe ? c.sent : c.received,
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
            // ── Audio / voice message ─────────────────────────────
            if (message.type == MessageType.audio) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 200),
                child: VoiceMessageBubble(
                  message: message,
                  isMe: isMe,
                ),
              ),
            ]
            // ── Image message ─────────────────────────────────────
            else if (message.type == MessageType.image &&
                (message.mediaUrl != null ||
                    message.localFilePath != null)) ...[
              GestureDetector(
                onTap: () => _showFullScreenImage(
                    message.mediaUrl, message.localFilePath, message.text),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 220,
                      maxHeight: 280,
                    ),
                    child: _buildImageWidget(message, c),
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ] else
              Text(
                message.text,
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
                  _formatTime(message.timestamp),
                  style: GoogleFonts.poppins(
                    color: isMe
                        ? Colors.white.withOpacity(0.75)
                        : c.textLow,
                    fontSize: 10,
                  ),
                ),
                if (message.isOfflineMesh) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.cell_tower_rounded,
                    size: 11,
                    color: isMe
                        ? Colors.white.withOpacity(0.7)
                        : c.textLow,
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
      ),
    );
  }

  /// Build the correct image widget for a message (network URL or local file).
  Widget _buildImageWidget(MessageModel message, dynamic c) {
    // Prefer local file if available (mesh images)
    if (message.localFilePath != null &&
        File(message.localFilePath!).existsSync()) {
      return Image.file(
        File(message.localFilePath!),
        fit: BoxFit.cover,
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
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            width: 200,
            height: 150,
            color: c.surfaceAlt,
            child: Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: c.primary),
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

  Widget _buildMessageStatusIcon(MessageModel message) {
    switch (message.status) {
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
    final c = AppThemeColors.of(context);
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
          ],
        ),
      );
    }

    // ── Filter by search query when in search mode ────────────────────
    final displayMessages = _isSearchMode && _searchQuery.isNotEmpty
        ? messages
            .where((m) => m.text.toLowerCase().contains(_searchQuery))
            .toList()
        : messages;

    if (_isSearchMode && _searchQuery.isNotEmpty && displayMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 48, color: c.textLow),
            const SizedBox(height: 12),
            Text(
              'No messages found',
              style: GoogleFonts.poppins(
                  color: c.textMid, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Group messages by date
    List<Widget> messageWidgets = [];
    String? lastDate;

    for (int i = 0; i < displayMessages.length; i++) {
      final message = displayMessages[i];
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
    final c = AppThemeColors.of(context);
    return Scaffold(
      backgroundColor: c.chatBg,
      appBar: AppBar(
        foregroundColor: c.textHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: c.border,
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
                  backgroundColor: c.primaryLt,
                  child: widget.contact.avatarUrl.isEmpty
                      ? Text(
                          widget.contact.name.isNotEmpty
                              ? widget.contact.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 16,
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
                      color: c.textHigh,
                    ),
                  ),
                  if (_isOtherUserTyping)
                    Text(
                      'typing...',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: c.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else if (_isContactOnline)
                    Text(
                      'Online',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: c.online,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
                    hintStyle: GoogleFonts.poppins(
                        color: c.textLow, fontSize: 14),
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () {
                        setState(() {
                          _isSearchMode = false;
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    ),
                  ),
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: c.textHigh),
                  onChanged: (query) {
                    setState(() => _searchQuery = query.trim().toLowerCase());
                  },
                ),
              ),
            )
          else ...[
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
              onSelected: _onMenuItemSelected,
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem(
                      value: 'contact info',
                      child:
                          Text('Contact info', style: GoogleFonts.poppins())),
                  PopupMenuItem(
                      value: 'search',
                      child: Text('Search', style: GoogleFonts.poppins())),
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
                          style:
                              GoogleFonts.poppins(color: c.error))),
                ];
              },
            ),
          ],
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: c.primary))
          : Column(
              children: [
                // ── Offline / Mesh mode banner ──────────────────────
                Consumer<ConnectivityProvider>(
                  builder: (_, connectivity, __) {
                    if (connectivity.isOnline) return const SizedBox.shrink();
                    return Consumer<MeshNetworkService>(
                      builder: (_, mesh, __) => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        color: const Color(0xFF2D2D2D),
                        child: Row(
                          children: [
                            Icon(
                              mesh.isActive
                                  ? Icons.cell_tower_rounded
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
                                    ? 'Mesh Mode  ·  ${mesh.connectedPeers} peer${mesh.connectedPeers == 1 ? '' : 's'} nearby'
                                    : 'No internet  ·  Tap to enable Mesh',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
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
                  child: StreamBuilder<List<MessageModel>>(
                    stream: _chatService.getMessages(
                      widget.currentUserId,
                      widget.contact.id,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return Center(
                            child: CircularProgressIndicator(
                                color: c.primary));
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
                                  style: GoogleFonts.poppins(
                                      color: c.textMid)),
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
                      ]..sort(
                          (a, b) => a.timestamp.compareTo(b.timestamp));

                      final hasUnreadMessages = messages.any((m) =>
                          m.receiverId == widget.currentUserId &&
                          m.status != MessageStatus.read);
                      if (hasUnreadMessages) {
                        _markNewMessagesAsRead();
                      }

                      // Only auto-scroll when genuinely new messages arrive,
                      // not on status updates (sent→delivered→read).
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (messages.length > _lastMessageCount) {
                          _scrollToBottom();
                        }
                        _lastMessageCount = messages.length;
                      });

                      return _buildMessagesList(messages);
                    },
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
                        top: BorderSide(
                            color: c.divider, width: 1),
                      ),
                    ),
                    child: SafeArea(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.block_rounded,
                              color: c.textLow, size: 18),
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
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(
          top: BorderSide(color: c.divider, width: 1),
        ),
      ),
      child: SafeArea(
        child: isRecording
            ? _buildRecordingBar(c)
            : _buildNormalInputBar(c),
      ),
    );
  }

  /// Normal input: attach + text field + send/mic.
  Widget _buildNormalInputBar(AppThemeColors c) {
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
                      strokeWidth: 2,
                      color: c.primary),
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
              border:
                  Border.all(color: c.border, width: 1),
            ),
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Message...',
                hintStyle: GoogleFonts.poppins(
                    color: c.textLow, fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
              style: GoogleFonts.poppins(
                  fontSize: 14, color: c.textHigh),
              maxLines: 5,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // ── Send or Mic button ─────────────────────────────────
        if (_hasText || _isSending)
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isSending
                    ? c.textLow
                    : c.primary,
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
          )
        else
          GestureDetector(
            onLongPressStart: (_) => _startVoiceRecording(),
            onLongPressMoveUpdate: (details) {
              // Could track slide-to-cancel offset here
            },
            onLongPressEnd: (_) => _stopVoiceRecording(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mic_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
      ],
    );
  }

  /// Recording-active bar: pulsing dot, timer, slide-to-cancel, stop button.
  Widget _buildRecordingBar(AppThemeColors c) {
    return Row(
      children: [
        // Pulsing red dot
        _buildPulsingDot(c),
        const SizedBox(width: 8),
        // Duration counter
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
            child: Icon(Icons.delete_outline_rounded,
                color: c.error, size: 18),
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
    await _voiceRecorder.startRecording();
    if (mounted) setState(() {});
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
        final chatRoomId = _chatService.getChatRoomId(
            widget.currentUserId, widget.contact.id);
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_voice.m4a';
        final ref = FirebaseStorage.instance
            .ref()
            .child('chat_audio/$chatRoomId/$fileName');

        final metadata = SettableMetadata(contentType: 'audio/m4a');
        await ref.putFile(File(filePath), metadata);
        final audioUrl = await ref.getDownloadURL();

        await _chatService.sendMessage(
          senderId: widget.currentUserId,
          receiverId: widget.contact.id,
          text: '🎤 Voice message',
          senderName: widget.currentUserName,
          type: MessageType.audio,
          mediaUrl: audioUrl,
          audioDuration: durationSeconds,
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
      if (mounted) setState(() => _isSendingVoice = false);
    }
  }

  Widget _buildTypingBubble() {
    final c = AppThemeColors.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 16, bottom: 4, top: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: c.received,
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
        setState(() => _isSearchMode = true);
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
        builder: (_) => Padding(
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
                backgroundImage: NetworkImage(avatarUrl),
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
                style: GoogleFonts.poppins(
                    fontSize: 13, color: c.textMid),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Divider(),
              if (user.phoneNumber != null)
                ListTile(
                  leading: Icon(Icons.phone_outlined,
                      color: c.primary),
                  title: Text(user.phoneNumber!,
                      style: GoogleFonts.poppins(fontSize: 14)),
                  subtitle: Text('Phone',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: c.textMid)),
                ),
              if (user.email != null)
                ListTile(
                  leading: const Icon(Icons.email_outlined,
                      color: Colors.orange),
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
                subtitle: Text('Status',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: c.textMid)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    });
  }

  // ─── Mute / Unmute ─────────────────────────────────────────────────
  void _toggleMute() {
    final chatRoomId = _chatService.getChatRoomId(
        widget.currentUserId, widget.contact.id);
    _settingsService.toggleMuteChat(chatRoomId);
    setState(() => _isMuted = !_isMuted);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            _isMuted ? 'Notifications muted' : 'Notifications unmuted'),
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
        content: Text(
          'Blocked contacts cannot send you messages or call you. '
          'You can unblock them from Settings → Privacy → Blocked contacts.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Block', style: TextStyle(color: Colors.red))),
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

  // ─── Image attachment ──────────────────────────────────────────────
  Future<void> _pickAndSendImage() async {
    if (_isBlocked || _isBlockedByContact) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send images to this contact')),
      );
      return;
    }

    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked == null) return;

      setState(() => _isUploadingImage = true);

      final connectivity =
          Provider.of<ConnectivityProvider>(context, listen: false);

      if (!connectivity.isOnline) {
        // ── Offline: send via mesh network ──────────────────────────
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
              SnackBar(
                  content: Text(
                      'No internet & mesh unavailable. Image not sent.')),
            );
          }
        }
      } else {
        // ── Online: upload to Firebase Storage ──────────────────────
        final chatRoomId = _chatService.getChatRoomId(
            widget.currentUserId, widget.contact.id);
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
        final ref = FirebaseStorage.instance
            .ref()
            .child('chat_images/$chatRoomId/$fileName');

        await ref.putFile(File(picked.path));
        final imageUrl = await ref.getDownloadURL();

        await _chatService.sendMessage(
          senderId: widget.currentUserId,
          receiverId: widget.contact.id,
          text: '📷 Photo',
          senderName: widget.currentUserName,
          type: MessageType.image,
          mediaUrl: imageUrl,
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
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  @override
  void dispose() {
    // Clear typing status so the other user doesn't see a stale indicator
    _stopTyping();
    _typingTimer?.cancel();
    _typingSubscription?.cancel();
    _onlineStatusSubscription?.cancel();
    _meshMessageSubscription?.cancel();
    _voiceRecorder.dispose();
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _searchController.dispose();
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
