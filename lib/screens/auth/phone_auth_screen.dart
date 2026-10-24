import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/l10n/app_localizations.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/services/auth_service.dart';
import 'package:video_chat_app/services/phone_verification_service.dart';
import 'package:video_chat_app/screens/auth/link_accounts_screen.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/utils/input_focus.dart';

/// Two honest stages: collect name + phone, then verify the SMS code.
/// Auto-retrieval can complete the sign-in from either stage and simply
/// navigates — there is no "carrier verifying" stage because nothing about
/// this flow is carrier-verified; a real SMS OTP is always what proves the
/// number.
enum PhoneAuthStage { entry, otpSent }

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _otpFocus = FocusNode();

  PhoneAuthStage _stage = PhoneAuthStage.entry;
  bool _busy = false; // a send/verify call is in flight (button spinner)
  bool _completing = false; // UI single-flight for OTP verify
  bool _navigated = false; // one-push guard so we navigate at most once

  String? _verificationId;
  String? _pendingPhone;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(focusInputWhenReady(context, _nameFocus,
        shouldFocus: () => !_navigated && _stage == PhoneAuthStage.entry));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────

  /// Normalize to E.164: strip spaces/dashes/parens and prepend +91 when no
  /// country code is given (India-first). Returns null if it can't be made to
  /// look like a valid E.164 number.
  String? _normalizePhone(String raw) {
    var s = raw.replaceAll(RegExp(r'[\s\-()]'), '').trim();
    if (s.isEmpty) return null;
    if (!s.startsWith('+')) {
      s = '+91$s';
    }
    if (!RegExp(r'^\+\d{8,15}$').hasMatch(s)) return null;
    return s;
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    final l10n = AppLocalizations.of(context);
    switch (e.code) {
      case 'invalid-verification-code':
        return l10n.phoneAuthErrCodeIncorrect;
      case 'session-expired':
        return l10n.phoneAuthErrCodeExpired;
      case 'too-many-requests':
        return l10n.phoneAuthErrTooManyRequests;
      case 'invalid-phone-number':
        return l10n.phoneAuthErrInvalidPhone;
      case 'quota-exceeded':
        return l10n.phoneAuthErrQuotaExceeded;
      default:
        return e.message ?? l10n.phoneAuthErrFailed;
    }
  }

  /// Single navigation sink. Both auto-verify and manual OTP success route
  /// through here; [_navigated] guarantees at most one push even if they race.
  void _handleSignedIn(UserModel user) {
    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LinkAccountsScreen(user: user)),
    );
  }

  // ─── Optional SIM-number autofill (NOT verification) ──────────────────────
  /// Prefills the phone field from the SIM picker. Cancel / unavailable /
  /// false-cancel is a harmless no-op: the field stays editable and the user
  /// can just type their number.
  Future<void> _autofillFromSim() async {
    try {
      final number = await _authService.requestPhoneNumberHint();
      if (!mounted) return;
      setState(() {
        _phoneController.text = number;
        _errorMessage = null;
      });
    } on PhoneVerificationException {
      // No-op — see doc comment above.
    } catch (_) {
      // Any unexpected failure is likewise non-blocking.
    }
  }

  // ─── Send OTP ─────────────────────────────────────────────────────────────
  Future<void> _sendOTP() async {
    if (_busy || _completing || _navigated) return;
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = l10n.phoneAuthEnterName);
      return;
    }
    final phone = _normalizePhone(_phoneController.text);
    if (phone == null) {
      setState(() => _errorMessage = l10n.phoneAuthEnterValidPhone);
      return;
    }

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    await _authService.verifyPhoneNumber(
      phoneNumber: phone,
      name: name,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _pendingPhone = phone;
          _stage = PhoneAuthStage.otpSent;
          _busy = false;
        });
        unawaited(focusInputWhenReady(context, _otpFocus,
            preserveUserFocus: false,
            shouldFocus: () =>
                !_busy && !_navigated && _stage == PhoneAuthStage.otpSent));
      },
      onAutoVerified: (user) {
        if (!mounted) return;
        _handleSignedIn(user);
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _errorMessage = error;
          _busy = false;
        });
      },
    );
  }

  // ─── Verify OTP ───────────────────────────────────────────────────────────
  Future<void> _verifyOTP() async {
    final l10n = AppLocalizations.of(context);
    if (_completing) return;
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = l10n.phoneAuthEnterCode);
      return;
    }
    if (_verificationId == null) {
      setState(() => _errorMessage = l10n.phoneAuthRequestNewCode);
      return;
    }

    _completing = true;
    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.signInWithPhoneOTP(
        verificationId: _verificationId!,
        otp: code,
        name: _nameController.text.trim(),
      );
      if (!mounted) return;
      if (user != null) {
        _handleSignedIn(user);
      } else {
        _completing = false;
        setState(() {
          _busy = false;
          _errorMessage = l10n.phoneAuthCodeIncorrect;
        });
      }
    } on FirebaseAuthException catch (e) {
      _completing = false;
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorMessage = _friendlyAuthError(e);
      });
    } catch (_) {
      _completing = false;
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorMessage = l10n.phoneAuthErrFailed;
      });
    }
  }

  // ─── Resend / go back ─────────────────────────────────────────────────────
  Future<void> _resendCode() async {
    _otpController.clear();
    _completing = false;
    setState(() {
      _errorMessage = null;
      _verificationId = null;
    });
    await _sendOTP();
  }

  void _backToEntry() {
    _otpController.clear();
    _completing = false;
    setState(() {
      _stage = PhoneAuthStage.entry;
      _verificationId = null;
      _pendingPhone = null;
      _errorMessage = null;
    });
    unawaited(focusInputWhenReady(context, _phoneFocus,
        preserveUserFocus: false,
        shouldFocus: () => !_navigated && _stage == PhoneAuthStage.entry));
  }

  // ─── UI ───────────────────────────────────────────────────────────────────

  InputDecoration _fieldDecoration(
    AppThemeColors c, {
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: c.textLow),
      prefixIcon: Icon(icon, color: c.textMid),
      suffixIcon: suffix,
      filled: true,
      fillColor: c.surfaceAlt,
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: c.textHigh, size: 20),
          onPressed: () {
            if (_stage == PhoneAuthStage.otpSent) {
              _backToEntry();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              // ── Header logo ──
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: c.primary.withOpacity(0.3),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'GupShupGo',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: c.textHigh,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _stage == PhoneAuthStage.entry
                    ? AppLocalizations.of(context).phoneAuthTitleEntry
                    : AppLocalizations.of(context).phoneAuthTitleOtp,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 15, color: c.textMid),
              ),
              const SizedBox(height: 32),

              if (_stage == PhoneAuthStage.entry)
                ..._buildEntryStage(c)
              else
                ..._buildOtpStage(c),

              // ── Error banner ──
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: c.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: c.error.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: c.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: c.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Entry stage: name + phone + Send OTP ──
  List<Widget> _buildEntryStage(AppThemeColors c) {
    final l10n = AppLocalizations.of(context);
    return [
      TextField(
        controller: _nameController,
        focusNode: _nameFocus,
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => _phoneFocus.requestFocus(),
        style: TextStyle(color: c.textHigh),
        textCapitalization: TextCapitalization.words,
        decoration: _fieldDecoration(
          c,
          hint: l10n.phoneAuthNameHint,
          icon: Icons.person_outline_rounded,
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _phoneController,
        focusNode: _phoneFocus,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => unawaited(_sendOTP()),
        style: TextStyle(color: c.textHigh),
        keyboardType: TextInputType.phone,
        decoration: _fieldDecoration(
          c,
          hint: l10n.phoneAuthPhoneHint,
          icon: Icons.phone_outlined,
          suffix: TextButton(
            onPressed: _busy ? null : _autofillFromSim,
            child: Text(
              l10n.phoneAuthUseSim,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.primary,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _busy ? null : _sendOTP,
          style: ElevatedButton.styleFrom(
            backgroundColor: c.primary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _busy
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  l10n.phoneAuthSendOtp,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    ];
  }

  // ── OTP stage: code + Verify + Resend + Go Back ──
  List<Widget> _buildOtpStage(AppThemeColors c) {
    final l10n = AppLocalizations.of(context);
    return [
      Text(
        _pendingPhone != null
            ? l10n.phoneAuthOtpPrompt(_pendingPhone!)
            : l10n.phoneAuthOtpPromptGeneric,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(fontSize: 14, color: c.textMid, height: 1.4),
      ),
      const SizedBox(height: 20),
      TextField(
        controller: _otpController,
        focusNode: _otpFocus,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) {
          if (!_busy && !_navigated) unawaited(_verifyOTP());
        },
        autofillHints: const [AutofillHints.oneTimeCode],
        style: TextStyle(color: c.textHigh, letterSpacing: 4),
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        decoration: _fieldDecoration(
          c,
          hint: l10n.phoneAuthOtpHint,
          icon: Icons.lock_outline_rounded,
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _busy ? null : _verifyOTP,
          style: ElevatedButton.styleFrom(
            backgroundColor: c.primary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _busy
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  l10n.phoneAuthVerify,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: _busy ? null : _backToEntry,
            child: Text(
              l10n.phoneAuthGoBack,
              style: GoogleFonts.poppins(
                  color: c.textMid, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: _busy ? null : _resendCode,
            child: Text(
              l10n.phoneAuthResendCode,
              style: GoogleFonts.poppins(
                  color: c.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ];
  }
}
