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

  List<String> _suggestions = [];

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
    if (base.isEmpty) base = 'user';
    if (base.length < 3) {
      base = base.padRight(3, '0');
    }

    // Build suggestion pills
    final rng = Random();
    final candidateList = <String>{
      base,
      '${base}_go',
      '${base}_${10 + rng.nextInt(89)}',
      '${base}official',
    }.where((s) => s.length >= 3 && s.length <= 20).toList();

    if (mounted) {
      setState(() {
        _suggestions = candidateList;
      });
    }

    String candidate = base;
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
        _errorMessage = 'Only letters, numbers, and underscores allowed.';
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

      // Update local SharedPreferences cache immediately.
      await _authService.cacheUser(updatedUser);

      if (!mounted) return;

      if (Navigator.canPop(context)) {
        Navigator.pop(context, updatedUser);
      } else {
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

  void _selectSuggestion(String suggestion) {
    _usernameController.text = suggestion;
    _onUsernameChanged(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final canCancel = Navigator.canPop(context);
    final rawText = _usernameController.text.trim().toLowerCase();
    final cleanHandle = rawText.startsWith('@') ? rawText.substring(1) : rawText;

    final canSubmit = _isAvailable == true && !_isChecking && !_isSaving;

    final accentGradient = LinearGradient(
      colors: isDark
          ? const [Color(0xFF7C5CFC), Color(0xFF9D8DF5)]
          : const [Color(0xFF6C5CE7), Color(0xFF8B5CF6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        title: Text(
          'Choose Your Handle',
          style: TextStyle(
            color: c.textHigh,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: c.surface,
        elevation: 0,
        automaticallyImplyLeading: canCancel,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    // ── Brand Avatar Header ───────────────────────────
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: accentGradient,
                        boxShadow: [
                          BoxShadow(
                            color: c.primary.withValues(alpha: isDark ? 0.35 : 0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.alternate_email_rounded,
                          size: 42,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Title & Description ───────────────────────────
                    Text(
                      'Secure Your Identity',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: c.textHigh,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Your @handle is your unique key on GupShupGo. Others can search and add you securely without sharing your phone or email.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: c.textMid,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Handle Input Glass/Clay Card ──────────────────
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: c.surfaceAlt,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isAvailable == true
                              ? Colors.green.withValues(alpha: 0.6)
                              : _errorMessage != null
                                  ? Colors.red.withValues(alpha: 0.6)
                                  : c.border,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: c.primary.withValues(alpha: isDark ? 0.06 : 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Prefix Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: c.primaryLt,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '@',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: c.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // TextField Input
                          Expanded(
                            child: TextField(
                              controller: _usernameController,
                              onChanged: _onUsernameChanged,
                              autofocus: true,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: c.textHigh,
                              ),
                              decoration: InputDecoration(
                                hintText: 'your_handle',
                                hintStyle: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.normal,
                                  color: c.textLow,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          // Dynamic Status Icon
                          if (_isChecking)
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: c.primary,
                              ),
                            )
                          else if (_isAvailable == true)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green,
                              size: 24,
                            )
                          else if (_isAvailable == false)
                            const Icon(
                              Icons.cancel_rounded,
                              color: Colors.red,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Live Validation & Character Count Bar ─────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _isChecking
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: c.textMid,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Checking availability...',
                                        style: TextStyle(
                                          color: c.textMid,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  )
                                : _isAvailable == true
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.check_circle_outline_rounded,
                                              size: 14,
                                              color: Colors.green,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '@$cleanHandle is available!',
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : _errorMessage != null
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.error_outline_rounded,
                                                  size: 14,
                                                  color: Colors.red,
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    _errorMessage!,
                                                    style: const TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : Text(
                                            '3–20 characters (a-z, 0-9, _)',
                                            style: TextStyle(
                                              color: c.textLow,
                                              fontSize: 12,
                                            ),
                                          ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${cleanHandle.length}/20',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                            color: cleanHandle.length > 20 ? Colors.red : c.textLow,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Recommended Suggestions Pills ──────────────────
                    if (_suggestions.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'RECOMMENDED FOR YOU',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: c.textLow,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.start,
                        children: _suggestions.map((sug) {
                          final isSelected = cleanHandle == sug;
                          return ChoiceChip(
                            label: Text(
                              '@$sug',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : c.textHigh,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: c.primary,
                            backgroundColor: c.surfaceAlt,
                            side: BorderSide(
                              color: isSelected ? c.primary : c.border,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onSelected: (_) => _selectSuggestion(sug),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Action Button Area ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: canSubmit ? accentGradient : null,
                  color: canSubmit ? null : c.surfaceAlt,
                  boxShadow: canSubmit
                      ? [
                          BoxShadow(
                            color: c.primary.withValues(alpha: isDark ? 0.4 : 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: ElevatedButton(
                  onPressed: canSubmit ? _saveUsername : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    disabledForegroundColor: c.textLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save & Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: canSubmit ? Colors.white : c.textLow,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
