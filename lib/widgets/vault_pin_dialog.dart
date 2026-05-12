// VaultPinDialog — modal that drives the vault setup / unlock / reset flow.
// Returned future resolves once the vault is in a usable state OR the user
// explicitly chose to reset (history wiped). Cannot be dismissed otherwise.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  static const _minLen = 6;

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool get _isSetup => widget.mode == VaultPinMode.setup;

  Future<void> _submit() async {
    final pin = _pinCtrl.text;
    if (pin.length < _minLen) {
      setState(() => _error = 'At least $_minLen characters.');
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
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _error =
            _isSetup ? 'Setup failed. Check connection.' : 'Incorrect PIN.';
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
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reset vault?',
            style: TextStyle(
                color: c.textHigh, fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text(
          'This permanently deletes your encrypted message history from the '
          'cloud. You will start with a fresh PIN. This cannot be undone.',
          style: TextStyle(color: c.textMid, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: c.textMid)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    await VaultCipher.instance.reset(widget.uid);
    // Drop in-memory pre-warm + payload caches so the freshly-emptied
    // vault doesn't keep replaying old messages from RAM.
    ChatService.invalidatePreWarm(widget.uid);
    StatusService.invalidatePreWarm(widget.uid);
    if (!mounted) return;
    // Re-open the dialog in setup mode so the user immediately picks a new
    // PIN. We pop with false so the parent caller knows the original
    // unlock didn't complete, then re-prompt fresh setup.
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
      child: AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.lock_outline_rounded, color: c.primary, size: 22),
          const SizedBox(width: 8),
          Text(_isSetup ? 'Protect your messages' : 'Unlock your vault',
              style: TextStyle(
                  color: c.textHigh,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
        ]),
        content: SizedBox(
          width: 320,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              _isSetup
                  ? 'Set a PIN to end-to-end encrypt your message history. '
                      'You\'ll need it again only when you reinstall. We '
                      'cannot recover it for you.'
                  : 'Enter the PIN you set on your previous install to '
                      'decrypt your message history.',
              style: TextStyle(color: c.textMid, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _pinField(c, _pinCtrl, _isSetup ? 'New PIN' : 'PIN', autofocus: true),
            if (_isSetup) ...[
              const SizedBox(height: 10),
              _pinField(c, _confirmCtrl, 'Confirm PIN'),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
            if (!_isSetup) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _busy ? null : _confirmReset,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: Text('Forgot PIN — reset vault',
                      style: TextStyle(color: c.primary, fontSize: 12)),
                ),
              ),
            ],
          ]),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: c.primary),
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(_isSetup ? 'Set PIN' : 'Unlock'),
          ),
        ],
      ),
    );
  }

  Widget _pinField(AppThemeColors c, TextEditingController ctrl, String hint,
      {bool autofocus = false}) {
    return TextField(
      controller: ctrl,
      obscureText: _obscure,
      autofocus: autofocus,
      keyboardType: TextInputType.visiblePassword,
      inputFormatters: [LengthLimitingTextInputFormatter(64)],
      style: TextStyle(color: c.textHigh, letterSpacing: 2),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.textLow),
        filled: true,
        fillColor: c.surfaceAlt,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off,
              color: c.textLow),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
