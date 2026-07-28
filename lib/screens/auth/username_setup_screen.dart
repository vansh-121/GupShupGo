import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/services/user_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/screens/home_screen.dart';

class UsernameSetupScreen extends StatefulWidget {
  final UserModel user;

  const UsernameSetupScreen({super.key, required this.user});

  @override
  State<UsernameSetupScreen> createState() => _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends State<UsernameSetupScreen> {
  final UserService _userService = UserService();
  final TextEditingController _usernameController = TextEditingController();

  Timer? _debounce;
  bool _isChecking = false;
  bool? _isAvailable;
  String? _errorMessage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _suggestInitialUsername();
  }

  void _suggestInitialUsername() {
    String suggestion = '';
    if (widget.user.email != null && widget.user.email!.contains('@')) {
      suggestion = widget.user.email!.split('@').first;
    } else if (widget.user.name.isNotEmpty) {
      suggestion = widget.user.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    }

    if (suggestion.length > 20) {
      suggestion = suggestion.substring(0, 20);
    }

    if (suggestion.isNotEmpty) {
      _usernameController.text = suggestion;
      _onUsernameChanged(suggestion);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _usernameController.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String text) {
    _debounce?.cancel();

    String clean = text.trim().toLowerCase();
    if (clean.startsWith('@')) {
      clean = clean.substring(1);
    }

    if (clean.length < 3) {
      setState(() {
        _isChecking = false;
        _isAvailable = false;
        _errorMessage = 'Username must be at least 3 characters long.';
      });
      return;
    }

    if (clean.length > 20) {
      setState(() {
        _isChecking = false;
        _isAvailable = false;
        _errorMessage = 'Username must be at most 20 characters long.';
      });
      return;
    }

    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(clean)) {
      setState(() {
        _isChecking = false;
        _isAvailable = false;
        _errorMessage = 'Only letters, numbers, and underscores are allowed.';
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _errorMessage = null;
      _isAvailable = null;
    });

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      bool available = await _userService.isUsernameAvailable(
        clean,
        currentUserId: widget.user.id,
      );

      if (!mounted) return;

      setState(() {
        _isChecking = false;
        _isAvailable = available;
        if (!available) {
          _errorMessage = '@$clean is already taken by another user.';
        }
      });
    });
  }

  Future<void> _saveUsername() async {
    String clean = _usernameController.text.trim().toLowerCase();
    if (clean.startsWith('@')) clean = clean.substring(1);

    if (_isAvailable != true || _isChecking || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _userService.updateUsername(widget.user.id, clean);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set username: $e')),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        title: const Text('Choose Your Handle'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.primaryLt,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.alternate_email_rounded, size: 36, color: c.primary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Unique Handle',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: c.textHigh,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Others can search and add you using your unique @username without exposing your phone or email.',
                            style: TextStyle(fontSize: 13, color: c.textMid),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Choose a @username',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.textHigh,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                onChanged: _onUsernameChanged,
                autofocus: true,
                decoration: InputDecoration(
                  prefixText: '@ ',
                  prefixStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: c.primary,
                  ),
                  hintText: 'your_handle',
                  filled: true,
                  fillColor: c.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _isChecking
                      ? UnconstrainedBox(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: c.primary,
                            ),
                          ),
                        )
                      : _isAvailable == true
                          ? const Icon(Icons.check_circle_rounded, color: Colors.green)
                          : _isAvailable == false
                              ? const Icon(Icons.cancel_rounded, color: Colors.red)
                              : null,
                ),
              ),
              const SizedBox(height: 12),
              if (_isAvailable == true)
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        size: 16, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(
                      '@${_usernameController.text.trim().toLowerCase().replaceAll('@', '')} is available!',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              if (_errorMessage != null)
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 16, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_isAvailable == true && !_isChecking && !_isSaving)
                      ? _saveUsername
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save & Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
