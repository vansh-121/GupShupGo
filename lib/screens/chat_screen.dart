import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/provider/call_state_provider.dart';
import 'package:video_chat_app/screens/call_screen.dart';
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

class Message {
  final String id;
  final String text;
  final bool isMe;
  final String time;
  final MessageType type;

  Message({
    required this.id,
    required this.text,
    required this.isMe,
    required this.time,
    this.type = MessageType.text,
  });
}

enum MessageType { text, image, audio, video }

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

  List<Message> _messages = [
    Message(
      id: '1',
      text: 'Hey there! How are you doing?',
      isMe: false,
      time: '10:30 AM',
    ),
    Message(
      id: '2',
      text: 'I\'m doing great! Thanks for asking. How about you?',
      isMe: true,
      time: '10:32 AM',
    ),
    Message(
      id: '3',
      text: 'All good here! Want to hop on a video call later?',
      isMe: false,
      time: '10:35 AM',
    ),
    Message(
      id: '4',
      text: 'Sure! That sounds perfect. What time works for you?',
      isMe: true,
      time: '10:37 AM',
    ),
    Message(
      id: '5',
      text: 'How about in 30 minutes?',
      isMe: false,
      time: '10:40 AM',
    ),
  ];

  Future<void> _initiateVideoCall() async {
    try {
      final channelId = '${widget.currentUserId}_to_${widget.contact.id}';
      final callState = Provider.of<CallStateNotifier>(context, listen: false);
      callState.updateState(CallState.Calling);

      print(
          'Initiating video call to ${widget.contact.name} on channel $channelId');

      // Send notification to callee
      await FCMService().sendCallNotification(
          widget.contact.id, widget.currentUserId, channelId);

      // Navigate to call screen
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
    try {
      final channelId = '${widget.currentUserId}_to_${widget.contact.id}_audio';
      final callState = Provider.of<CallStateNotifier>(context, listen: false);
      callState.updateState(CallState.Calling);

      print(
          'Initiating audio call to ${widget.contact.name} on channel $channelId');

      // Send notification to callee (you might want to add audio call type to FCM data)
      await FCMService().sendCallNotification(
          widget.contact.id, widget.currentUserId, channelId);

      // For now, navigate to the same call screen (you can create a separate audio call screen)
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

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: _messageController.text.trim(),
          isMe: true,
          time: _formatTime(DateTime.now()),
        ),
      );
    });

    _messageController.clear();
    _scrollToBottom();
  }

  String _formatTime(DateTime dateTime) {
    String hour = dateTime.hour > 12
        ? (dateTime.hour - 12).toString()
        : dateTime.hour.toString();
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
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

  Widget _buildMessage(Message message) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: message.isMe ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
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
                color: message.isMe ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Text(
              message.time,
              style: TextStyle(
                color: message.isMe ? Colors.white70 : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
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
                  backgroundImage: NetworkImage(widget.contact.avatarUrl),
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.contact.isOnline)
                    Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                      ),
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
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index]);
              },
            ),
          ),

          // Message input area
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!, width: 0.5),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.attach_file, color: Colors.grey[600]),
                    onPressed: () {
                      // Handle attachment
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
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        maxLines: null,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
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
}
