// VaultPinDialog — modal that drives the vault setup / unlock / reset flow.
// Returned future resolves once the vault is in a usable state, the user
// explicitly chose to reset (history wiped), or they deferred unlocking.
//
// Invariant: the vault key is always derived from a PIN the user typed. Setup
// therefore *always* asks for one. Biometrics is an opt-in convenience layered
// on top — it unwraps a stored copy of that same PIN on this device, and never
// substitutes for knowing it. An earlier build generated a random PIN behind
// the fingerprint button and never showed it, which made reinstall an
// unrecoverable data loss; see lib/services/crypto/vault_pin_custody.dart.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:video_chat_app/services/chat_service.dart';
import 'package:video_chat_app/services/crypto/vault_cipher.dart';
import 'package:video_chat_app/services/crypto/vault_pin_custody.dart';
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
  final _storage = biometricPinStorage;

  bool _obscure = true;
  bool _busy = false;

  /// Device has usable biometric hardware.
  bool _canCheckBiometrics = false;

  /// A PIN is stored on this device for biometrics to unwrap. Without it a
  /// fingerprint scan has nothing to release, so the affordance must not be
  /// shown — that is exactly the dead end this dialog used to present after a
  /// reinstall.
  bool _hasStoredPin = false;

  String? _error;

  /// Neutral, non-error guidance (e.g. "fingerprint was set up on your
  /// previous install"). Kept separate from [_error] so an informational
  /// state doesn't render in the red error banner.
  String? _hint;

  static const _minLen = 6;

  /// Fingerprint may only be offered as an unlock method when the hardware
  /// exists AND there is a stored PIN to unwrap.
  bool get _biometricUnlockReady => _canCheckBiometrics && _hasStoredPin;

  String get _pinKey => biometricPinKey(widget.uid);
  String get _dismissedKey => biometricOfferDismissedKey(widget.uid);

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
      // Read the stored PIN up front: whether one exists decides whether a
      // fingerprint affordance can do anything at all.
      final storedPin = await _storage.read(key: _pinKey);
      if (!mounted) return;

      setState(() {
        _canCheckBiometrics = canCheck && isSupported;
        _hasStoredPin = storedPin != null && storedPin.isNotEmpty;
        // Reinstall case: the hardware is there, the user did enable
        // fingerprint before, but the stored PIN went with the old install.
        // Say so plainly instead of presenting a button that cannot work.
        if (!_isSetup && _canCheckBiometrics && !_hasStoredPin) {
          _hint = 'Enter your PIN to restore your history on this device. '
              'You can turn fingerprint unlock back on afterwards.';
        }
      });

      // Unlock mode with a stored PIN — go straight to the scanner.
      if (!_isSetup && _biometricUnlockReady) {
        _authenticateWithBiometrics(savedPin: storedPin);
      }
    } catch (e) {
      debugPrint('[Biometrics] check failed: $e');
    }
  }

  /// Unwraps the stored PIN behind a biometric scan and unlocks with it.
  ///
  /// Unlock-mode only. Setup never comes through here: a vault must always be
  /// created from a PIN the user typed, so there is nothing for a scan to
  /// unwrap yet.
  Future<void> _authenticateWithBiometrics({String? savedPin}) async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Authenticate using biometrics to unlock your vault',
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

      final pinToUse = savedPin ?? await _storage.read(key: _pinKey);
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
          // The scan succeeded but the PIN behind it no longer opens the
          // vault — e.g. the PIN was changed on another device.
          _hasStoredPin = false;
          _error = 'Fingerprint unlock is out of date. Enter your PIN.';
        });
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
    if (!ok) {
      setState(() {
        _busy = false;
        _error = _isSetup
            ? 'Setup failed. Check connection.'
            : 'Incorrect PIN. Try again.';
        _pinCtrl.clear();
        if (_isSetup) _confirmCtrl.clear();
      });
      return;
    }

    // Reaching here means the user typed this PIN and it worked, which is the
    // proof of custody the rescue flow keys off. setup() records the flag
    // itself; an unlock has to say so explicitly.
    if (!_isSetup) {
      await VaultCipher.instance.markPinUserChosen(widget.uid);
    }

    // Keep the stored copy current for users who have fingerprint unlock on —
    // otherwise a changed PIN would leave a stale one behind biometrics.
    // Users who have not opted in get nothing written.
    if (_hasStoredPin) {
      await _storage.write(key: _pinKey, value: pin);
    } else {
      await _maybeOfferBiometricUnlock(pin);
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  /// Offers fingerprint unlock as an explicit opt-in once the vault is open.
  ///
  /// Only reached when nothing is stored yet. Declining is remembered so this
  /// does not reappear on every unlock — Vault settings is the way back in.
  Future<void> _maybeOfferBiometricUnlock(String pin) async {
    if (!_canCheckBiometrics) return;
    final dismissed = await _storage.read(key: _dismissedKey);
    if (dismissed == 'true') return;
    if (!mounted) return;

    final accepted = await _askEnableBiometrics();
    if (!mounted) return;
    if (accepted != true) {
      await _storage.write(key: _dismissedKey, value: 'true');
      return;
    }

    // Confirm it's really them before binding the PIN to a scan.
    try {
      final authed = await _auth.authenticate(
        localizedReason: 'Confirm your fingerprint to enable quick unlock',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (!authed) return;
    } on PlatformException catch (e) {
      debugPrint('[Biometrics] enrol failed: $e');
      return;
    }
    await _storage.write(key: _pinKey, value: pin);
    if (mounted) setState(() => _hasStoredPin = true);
  }

  Future<bool?> _askEnableBiometrics() {
    final c = AppThemeColors.of(context);
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.border, width: 1),
        ),
        title: Row(
          children: [
            Icon(Icons.fingerprint_rounded, color: c.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Unlock with fingerprint?',
                style: GoogleFonts.poppins(
                  color: c.textHigh,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Skip typing your PIN on this phone. Your PIN is still what protects '
          'the vault — keep it somewhere safe, because you will need it on a '
          'new phone or after reinstalling.',
          style:
              GoogleFonts.poppins(color: c.textMid, fontSize: 13, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Not now',
              style: GoogleFonts.poppins(
                  color: c.textMid, fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: c.primary,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Enable',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
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
          'Delete all messages?',
          style: GoogleFonts.poppins(
            color: c.textHigh,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Without your PIN your history cannot be decrypted, so resetting '
          'deletes all of it — the encrypted cloud copy and the copy on this '
          'phone. Your chats will be empty.\n\n'
          'Your account and contacts are not affected, and you can keep '
          'messaging normally afterwards. This cannot be undone.',
          style:
              GoogleFonts.poppins(color: c.textMid, fontSize: 13, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                  color: c.textMid, fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete everything',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    await VaultCipher.instance.reset(widget.uid);
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _dismissedKey);
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
                    if (_biometricUnlockReady)
                      IconButton(
                        tooltip: 'Use Fingerprint',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.fingerprint_rounded,
                            color: c.primary, size: 28),
                        onPressed:
                            _busy ? null : () => _authenticateWithBiometrics(),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Subtitle Description ────────────────────────────────
                Text(
                  _isSetup
                      ? 'Choose a PIN to encrypt your message history. You '
                          'will need it to read your messages on a new phone, '
                          'so pick something you can remember.'
                      : _biometricUnlockReady
                          ? 'Enter your PIN or tap fingerprint to decrypt '
                              'history.'
                          : 'Enter your PIN to decrypt your history.',
                  style: GoogleFonts.poppins(
                    color: c.textMid,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),

                // ── Neutral guidance (not an error) ───────────────────────
                if (_hint != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: c.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: c.primary.withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: c.primary, size: 15),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _hint!,
                            style: GoogleFonts.poppins(
                              color: c.textMid,
                              fontSize: 11.5,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Fingerprint Banner (unlock, only when it can work) ────
                if (_biometricUnlockReady) ...[
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
                            'Unlock with Fingerprint',
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
                  autofocus: !_biometricUnlockReady,
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

                // ── Secondary actions (Unlock Mode) ────────────────────
                // "Restore later" exists so a forgotten PIN is not a choice
                // between destroying all history and being stuck in a modal.
                // A locked vault is a supported state: vault writes are
                // skipped and a later unlock backfills what was missed.
                //
                // Named for what it postpones, not for a decision. "Decide
                // later" read as deferring the choice *between* this button
                // and "Forgot PIN?" next to it, and said nothing about what
                // happens meanwhile — so the 🔒 previews that follow looked
                // like loss. "Restore later" both names the postponed action
                // and implies it is still available; VaultLockedBanner is
                // what then makes that promise reachable.
                if (!_isSetup) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Restore later',
                          style: GoogleFonts.poppins(
                            color: c.textMid,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
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
                    ],
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
