import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_chat_app/provider/call_state_provider.dart';
import 'package:video_chat_app/screens/call_screen.dart';
import 'package:video_chat_app/services/fcm_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _currentUser;
  String _calleeId = '';
  final List<String> _users = ['user_a', 'user_b'];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _setupCallListener();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUser = prefs.getString('user_id') ?? _users[0];
    });
  }

  Future<void> _saveUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    setState(() {
      _currentUser = userId;
    });
  }

  void _setupCallListener() {
    final callState = Provider.of<CallStateNotifier>(context, listen: false);
    FCMService().onCallReceived((callerId, channelId) {
      callState.updateState(CallState.Ringing);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(channelId: channelId, isCaller: false),
        ),
      );
    });
  }

  Future<void> _initiateCall(String calleeId) async {
    if (_currentUser == null || _currentUser == calleeId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Select a different user to call')),
      );
      return;
    }
    final channelId = '${_currentUser}_to_$calleeId';
    final callState = Provider.of<CallStateNotifier>(context, listen: false);
    callState.updateState(CallState.Calling);
    await FCMService().sendCallNotification(calleeId, _currentUser!, channelId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(channelId: channelId, isCaller: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Video Call App')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _currentUser,
              hint: Text('Select User'),
              items: _users.map((user) {
                return DropdownMenuItem(value: user, child: Text(user));
              }).toList(),
              onChanged: (value) {
                if (value != null) _saveUser(value);
              },
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(labelText: 'Callee ID'),
              onChanged: (value) => _calleeId = value,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _initiateCall(_calleeId),
              child: Text('Start Call'),
            ),
          ],
        ),
      ),
    );
  }
}
