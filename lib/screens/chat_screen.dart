import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/provider/call_state_provider.dart';
import 'package:video_chat_app/screens/call_screen.dart';
import 'package:video_chat_app/services/chat_service.dart';
import 'package:video_chat_app/services/fcm_service.dart';

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

  ChatScreen({required this.contact, required this.currentUserId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      // Ensure chat room exists
      await _chatService.getOrCreateChatRoom(
        widget.currentUserId,
        widget.contact.id,
      );

      // Mark messages as read when opening chat
      await _chatService.markMessagesAsRead(
        widget.currentUserId,
        widget.contact.id,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing chat: $e');
      setState(() {
        _isLoading = false;
      });
    }
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
          builder: (_) => CallScreen(channelId: channelId, isCaller: true),
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
      final channelId = '${widget.currentUserId}_to_${widget.contact.id}_audio';
      final callState = Provider.of<CallStateNotifier>(context, listen: false);
      callState.updateState(CallState.Calling);

      print(
          'Initiating audio call to ${widget.contact.name} on channel $channelId');

      await FCMService().sendCallNotification(
          widget.contact.id, widget.currentUserId, channelId);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(channelId: channelId, isCaller: true),
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

      await _chatService.sendMessage(
        senderId: widget.currentUserId,
        receiverId: widget.contact.id,
        text: text,
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
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              date,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildMessage(MessageModel message) {
    final isMe = message.senderId == widget.currentUserId;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: isMe ? Radius.circular(20) : Radius.circular(4),
            bottomRight: isMe ? Radius.circular(4) : Radius.circular(20),
          ),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
                if (isMe) ...[
                  SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead
                        ? Colors.lightBlueAccent
                        : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(List<MessageModel> messages) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start the conversation by sending a message',
              style: TextStyle(
                color: Colors.grey[500],
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

    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(vertical: 8),
      children: messageWidgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
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
                  child: widget.contact.avatarUrl.isEmpty
                      ? Text(
                          widget.contact.name.isNotEmpty
                              ? widget.contact.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(fontSize: 18),
                        )
                      : null,
                ),
                if (widget.contact.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contact.name,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  if (widget.contact.isOnline)
                    Text(
                      'Online',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.call, color: Colors.black),
            onPressed: _initiateAudioCall,
            tooltip: 'Audio Call',
          ),
          IconButton(
            icon: Icon(Icons.videocam, color: Colors.black),
            onPressed: _initiateVideoCall,
            tooltip: 'Video Call',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) {
              // Handle menu actions
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(value: 'info', child: Text('Contact Info')),
                PopupMenuItem(
                    value: 'media', child: Text('Media, Links, and Docs')),
                PopupMenuItem(value: 'search', child: Text('Search')),
                PopupMenuItem(value: 'mute', child: Text('Mute Notifications')),
                PopupMenuItem(value: 'block', child: Text('Block Contact')),
              ];
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
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
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 48, color: Colors.red),
                              SizedBox(height: 16),
                              Text('Error loading messages'),
                              TextButton(
                                onPressed: () {
                                  setState(() {});
                                },
                                child: Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      final messages = snapshot.data ?? [];

                      // Auto-scroll when new messages arrive
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (messages.isNotEmpty) {
                          _scrollToBottom();
                        }
                      });

                      return _buildMessagesList(messages);
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        top: BorderSide(color: Colors.grey[300]!, width: 0.5)),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        IconButton(
                          icon:
                              Icon(Icons.attach_file, color: Colors.grey[600]),
                          onPressed: () {
                            // TODO: Handle attachment
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Attachments coming soon!')),
                            );
                          },
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: TextStyle(color: Colors.grey[600]),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                              ),
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: _isSending ? Colors.grey : Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: _isSending
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Icon(Icons.send, color: Colors.white),
                            onPressed: _isSending ? null : _sendMessage,
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
