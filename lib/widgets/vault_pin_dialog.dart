// VaultPinDialog — modal that drives the vault setup / unlock / reset flow.
// Returned future resolves once the vault is in a usable state OR the user
// explicitly chose to reset (history wiped). Cannot be dismissed otherwise.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:video_chat_app/services/chat_service.dart';
import 'package:video_chat_app/services/crypto/vault_cipher.dart';
import 'package:video_chat_app/services/status_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';

class VaultPinDialog extends StatefulWidget {
  const VaultPinDialog({
    super.key,
    required this.uid,
    required this.mode,
  });

  final String uid;
  final VaultPinMode mode;

  @override
  State<VaultPinDialog> createState() => _VaultPinDialogState();

  /// Convenience entry point. Returns true on success (key in memory) or
  /// when the user opted into a vault reset; false if they backed out
  /// without completing.
  static Future<bool> show({
    required BuildContext context,
    required String uid,
    required VaultPinMode mode,
  }) async {
    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => VaultPinDialog(uid: uid, mode: mode),
    );
    return res ?? false;
  }
}

enum VaultPinMode { setup, unlock }

class _VaultPinDialogState extends State<VaultPinDialog> {
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  bool _obscure = true;
  bool _busy = false;
  bool _canCheckBiometrics = false;
  String? _error;

  static const _minLen = 6;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool get _isSetup => widget.mode == VaultPinMode.setup;

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      if (mounted) {
        setState(() {
          _canCheckBiometrics = canCheck && isSupported;
        });

        // In unlock mode, if biometric is available and a saved PIN exists, offer biometric unlock automatically
        if (!_isSetup && _canCheckBiometrics) {
          final savedPin = await _storage.read(key: 'vault_pin_${widget.uid}');
          if (savedPin != null && savedPin.isNotEmpty) {
            _authenticateWithBiometrics(savedPin: savedPin);
          }
        }
      }
    } catch (e) {
      debugPrint('[Biometrics] check failed: $e');
    }
  }

  Future<void> _authenticateWithBiometrics({String? savedPin}) async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: _isSetup
            ? 'Authenticate using biometrics to protect your vault'
            : 'Authenticate using biometrics to unlock your vault',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!authenticated || !mounted) return;

      setState(() {
        _busy = true;
        _error = null;
      });

      if (_isSetup) {
        // Generate a cryptographically secure random 6-digit PIN for fingerprint setup
        final rng = Random.secure();
        final generatedPin = (100000 + rng.nextInt(900000)).toString();

        final ok = await VaultCipher.instance.setup(widget.uid, generatedPin);
        if (ok) {
          await _storage.write(key: 'vault_pin_${widget.uid}', value: generatedPin);
          if (mounted) Navigator.of(context).pop(true);
        } else {
          if (mounted) {
            setState(() {
              _busy = false;
              _error = 'Biometric setup failed. Please enter a PIN.';
            });
          }
        }
      } else {
        // Unlock mode
        final pinToUse = savedPin ?? await _storage.read(key: 'vault_pin_${widget.uid}');
        if (pinToUse != null && pinToUse.isNotEmpty) {
          final ok = await VaultCipher.instance.unlock(widget.uid, pinToUse);
          if (ok && mounted) {
            Navigator.of(context).pop(true);
            return;
          }
        }
        if (VaultCipher.instance.isReady && mounted) {
          Navigator.of(context).pop(true);
          return;
        }
        if (mounted) {
          setState(() {
            _busy = false;
            _error = 'Enter your PIN once to enable Fingerprint unlock.';
          });
        }
      }
    } on PlatformException catch (e) {
      debugPrint('[Biometrics] error: $e');
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Biometric error. Enter PIN manually.';
        });
      }
    }
  }

  Future<void> _submit() async {
    final pin = _pinCtrl.text;
    if (pin.length < _minLen) {
      setState(() => _error = 'PIN must be at least $_minLen characters.');
      return;
    }
    if (_isSetup && pin != _confirmCtrl.text) {
      setState(() => _error = 'PINs do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = _isSetup
        ? await VaultCipher.instance.setup(widget.uid, pin)
        : await VaultCipher.instance.unlock(widget.uid, pin);
    if (!mounted) return;
    if (ok) {
      // Store PIN securely so biometric unlock works for future sessions
      await _storage.write(key: 'vault_pin_${widget.uid}', value: pin);
      if (mounted) Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _error =
            _isSetup ? 'Setup failed. Check connection.' : 'Incorrect PIN. Try again.';
        _pinCtrl.clear();
        if (_isSetup) _confirmCtrl.clear();
      });
    }
  }

  Future<void> _confirmReset() async {
    final c = AppThemeColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.border, width: 1),
        ),
        title: Text(
          'Reset vault?',
          style: GoogleFonts.poppins(
            color: c.textHigh,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This permanently deletes your encrypted message history. This cannot be undone.',
          style: GoogleFonts.poppins(color: c.textMid, fontSize: 13, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: c.textMid, fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Reset',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    await VaultCipher.instance.reset(widget.uid);
    await _storage.delete(key: 'vault_pin_${widget.uid}');
    ChatService.invalidatePreWarm(widget.uid);
    StatusService.invalidatePreWarm(widget.uid);
    if (!mounted) return;
    Navigator.of(context).pop(false);
    await VaultPinDialog.show(
      context: context,
      uid: widget.uid,
      mode: VaultPinMode.setup,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: c.surfaceAlt,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.primary.withOpacity(0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Icon & Title ─────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: c.primary.withOpacity(0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        color: c.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isSetup ? 'Protect Vault' : 'Unlock Vault',
                        style: GoogleFonts.poppins(
                          color: c.textHigh,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    if (_canCheckBiometrics)
                      IconButton(
                        tooltip: 'Use Fingerprint',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.fingerprint_rounded, color: c.primary, size: 28),
                        onPressed: _busy ? null : () => _authenticateWithBiometrics(),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Subtitle Description ────────────────────────────────
                Text(
                  _isSetup
                      ? 'Set a PIN to encrypt your message history.'
                      : 'Enter your PIN or tap fingerprint to decrypt history.',
                  style: GoogleFonts.poppins(
                    color: c.textMid,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),

                // ── Fingerprint Banner (if available) ─────────────────
                if (_canCheckBiometrics) ...[
                  InkWell(
                    onTap: _busy ? null : () => _authenticateWithBiometrics(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                      decoration: BoxDecoration(
                        color: c.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.primary.withOpacity(0.4), width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fingerprint_rounded, color: c.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _isSetup ? 'Setup with Fingerprint' : 'Unlock with Fingerprint',
                            style: GoogleFonts.poppins(
                              color: c.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: Divider(color: c.border.withOpacity(0.5))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'OR',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: c.textMid,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: c.border.withOpacity(0.5))),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                // ── PIN Input Fields ────────────────────────────────────
                _pinField(
                  c,
                  _pinCtrl,
                  _isSetup ? 'New PIN' : 'Enter PIN',
                  autofocus: !_canCheckBiometrics,
                ),
                if (_isSetup) ...[
                  const SizedBox(height: 10),
                  _pinField(
                    c,
                    _confirmCtrl,
                    'Confirm PIN',
                  ),
                ],

                // ── Error Message Banner ────────────────────────────────
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: c.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: c.error.withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: c.error, size: 15),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _error!,
                            style: GoogleFonts.poppins(
                              color: c.error,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Forgot PIN Button (Unlock Mode) ────────────────────
                if (!_isSetup) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _busy ? null : _confirmReset,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Forgot PIN?',
                        style: GoogleFonts.poppins(
                          color: c.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // ── Primary Full-Width Action Button ────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: c.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isSetup ? 'Set PIN' : 'Decrypt',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pinField(AppThemeColors c, TextEditingController ctrl, String hint,
      {bool autofocus = false}) {
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border, width: 1),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: _obscure,
        autofocus: autofocus,
        keyboardType: TextInputType.visiblePassword,
        inputFormatters: [LengthLimitingTextInputFormatter(64)],
        style: GoogleFonts.poppins(
          color: c.textHigh,
          fontSize: 14,
          letterSpacing: _obscure ? 3.0 : 0.8,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            color: c.textLow,
            fontSize: 13,
            letterSpacing: 0.0,
            fontWeight: FontWeight.w400,
          ),
          filled: false,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
          suffixIcon: IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
            icon: Icon(
              _obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              color: _obscure ? c.textMid : c.primary,
              size: 18,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      ),
    );
  }
}
