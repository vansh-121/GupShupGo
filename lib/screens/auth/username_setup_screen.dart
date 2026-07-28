import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/services/auth_service.dart';
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
  final AuthService _authService = AuthService();
  final TextEditingController _usernameController = TextEditingController();

  Timer? _debounce;
  bool _isChecking = false;
  bool? _isAvailable;
  String? _errorMessage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Fire-and-forget — updates the field once a suggestion resolves.
    // ignore: discarded_futures
    _suggestInitialUsername();
  }

  /// Derives a starting suggestion from the user's email/name and, if that
  /// base handle is already taken, appends a random 3-digit suffix (retried
  /// a few times) so the user isn't stuck staring at a taken handle with no
  /// clear next step.
  Future<void> _suggestInitialUsername() async {
    String base = '';
    if (widget.user.email != null && widget.user.email!.contains('@')) {
      base = widget.user.email!.split('@').first;
    } else if (widget.user.name.isNotEmpty) {
      base = widget.user.name;
    }
    base = base.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (base.length > 16) {
      base = base.substring(0, 16);
    }
    if (base.isEmpty) return;
    if (base.length < 3) {
      base = base.padRight(3, '0');
    }

    String candidate = base;
    final rng = Random();
    for (int attempt = 0; attempt < 5; attempt++) {
      if (!mounted) return;
      bool available = false;
      try {
        available = await _userService.isUsernameAvailable(
          candidate,
          currentUserId: widget.user.id,
        );
      } catch (_) {
        break; // Network hiccup — leave the field for manual entry.
      }
      if (available) break;
      candidate = '$base${100 + rng.nextInt(900)}';
      if (candidate.length > 20) {
        candidate = candidate.substring(0, 20);
      }
    }

    if (!mounted) return;
    _usernameController.text = candidate;
    _onUsernameChanged(candidate);
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
      final updatedUser = widget.user.copyWith(username: clean);

      // Update the local SharedPreferences cache immediately. Without this,
      // HomeScreen's mandatory-username check reads the stale cached user
      // (still username == null) on the very next build and bounces the
      // user straight back to this screen.
      await _authService.cacheUser(updatedUser);

      if (!mounted) return;

      if (Navigator.canPop(context)) {
        // Voluntary "Change handle" flow from Profile — just return the
        // updated user to the caller instead of tearing down the whole
        // navigation stack.
        Navigator.pop(context, updatedUser);
      } else {
        // Mandatory first-run onboarding — there's nothing to pop back to.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
        );
      }
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

    // Mandatory first-run onboarding has nothing to pop back to (pushed via
    // pushReplacement), so there's no back button in that case. Voluntary
    // "Change" from Profile can always be cancelled.
    final canCancel = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        title: const Text('Choose Your Handle'),
        elevation: 0,
        automaticallyImplyLeading: canCancel,
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
