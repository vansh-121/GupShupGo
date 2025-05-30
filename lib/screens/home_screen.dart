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
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _loadUser();
    await _setupCallListener();
    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? _users[0];
      setState(() {
        _currentUser = userId;
      });

      // Setup FCM for this user immediately
      await FCMService().setupFCM();
      print('App initialized for user: $userId');
    } catch (e) {
      print('Error loading user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing app: $e')),
      );
    }
  }

  Future<void> _saveUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    setState(() {
      _currentUser = userId;
    });

    // Re-setup FCM for new user
    await FCMService().setupFCM();
    print('Switched to user: $userId');
  }

  Future<void> _setupCallListener() async {
    try {
      final callState = Provider.of<CallStateNotifier>(context, listen: false);
      FCMService().onCallReceived((callerId, channelId) {
        print('Incoming call from $callerId on channel $channelId');
        callState.updateState(CallState.Ringing);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CallScreen(channelId: channelId, isCaller: false),
          ),
        );
      });
    } catch (e) {
      print('Error setting up call listener: $e');
    }
  }

  Future<void> _initiateCall(String calleeId) async {
    if (_currentUser == null || _currentUser == calleeId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Select a different user to call')),
      );
      return;
    }

    if (calleeId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid callee ID')),
      );
      return;
    }

    try {
      final channelId = '${_currentUser}_to_$calleeId';
      final callState = Provider.of<CallStateNotifier>(context, listen: false);
      callState.updateState(CallState.Calling);

      print(
          'Initiating call from $_currentUser to $calleeId on channel $channelId');

      // Send notification to callee
      await FCMService()
          .sendCallNotification(calleeId, _currentUser!, channelId);

      // Navigate to call screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(channelId: channelId, isCaller: true),
        ),
      );
    } catch (e) {
      print('Error initiating call: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initiate call: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Initializing app...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Video Call App'),
            Text(
              'Current User: ${_currentUser ?? "None"}',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select Your User ID:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    DropdownButton<String>(
                      value: _currentUser,
                      hint: Text('Select User'),
                      isExpanded: true,
                      items: _users.map((user) {
                        return DropdownMenuItem(value: user, child: Text(user));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) _saveUser(value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Make a Call:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Enter Callee ID',
                        hintText: 'e.g., user_b',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => _calleeId = value.trim(),
                    ),
                    SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () => _initiateCall(_calleeId),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Start Video Call',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Instructions:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text('1. Make sure both users have the app installed'),
                    Text('2. Each user should select their respective user ID'),
                    Text('3. Both users need to be online to receive calls'),
                    Text('4. FCM notifications must be properly configured'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
