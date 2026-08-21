// VaultPinCustodyDialog — one-time prompt that puts a PIN the user actually
// knows in charge of their vault.
//
// Shown only for VaultPinCustody.rescueAvailable: a vault exists, custody is
// unproven, and a PIN is still readable from secure storage. Two populations
// land here and are indistinguishable from the outside:
//
//   • Someone whose vault was created by tapping "Setup with Fingerprint" on an
//     older build, which generated a random PIN and never showed it. Their
//     history dies the next time they reinstall.
//   • Someone who chose a real PIN before the custody flag existed and simply
//     hasn't typed it since the upgrade.
//
// So the dialog serves both. It opens on the cheap, non-destructive path —
// confirm the PIN you know, which costs one key derivation and rewrites
// nothing — and offers re-keying as the escape for anyone who cannot. Both
// paths end with pinIsUserChosen set, so nobody is asked twice.
//
// Not dismissible: the rescue window closes permanently when an affected
// install is removed, taking the only copy of the generated PIN with it.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/services/crypto/vault_cipher.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/widgets/pin_keyboard_toggle.dart';

class VaultPinCustodyDialog extends StatefulWidget {
  const VaultPinCustodyDialog({
    super.key,
    required this.uid,
    required this.storedPin,
    this.numericPinHint = false,
  });

  final String uid;

  /// The PIN currently readable from secure storage. Used as the old PIN when
  /// re-keying, which is what makes the rescue lossless.
  final String storedPin;

  /// Which keyboard the confirm step opens with — see
  /// [VaultSettings.pinIsNumeric], which the caller has already read to decide
  /// whether to show this dialog at all.
  ///
  /// Defaults to false, and in practice it always is: the flag was added after
  /// every vault that lands here was created, so an absent field correctly
  /// reads as "assume a passphrase". That is the safe direction — the full
  /// keyboard can type digits, and this population is the one most likely to
  /// hold a PIN that is not digits at all.
  final bool numericPinHint;

  @override
  State<VaultPinCustodyDialog> createState() => _VaultPinCustodyDialogState();

  /// Shows the prompt and resolves when custody has been established (or the
  /// user exhausted the options available to them).
  static Future<void> show({
    required BuildContext context,
    required String uid,
    required String storedPin,
    bool numericPinHint = false,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => VaultPinCustodyDialog(
        uid: uid,
        storedPin: storedPin,
        numericPinHint: numericPinHint,
      ),
    );
  }
}

enum _Step { confirm, rekey }

class _VaultPinCustodyDialogState extends State<VaultPinCustodyDialog> {
  final _pinCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _pinFocus = FocusNode();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();

  _Step _step = _Step.confirm;
  bool _obscure = true;
  bool _busy = false;
  String? _error;
  int _done = 0;
  int _total = 0;

  /// Number pad vs full keyboard. A default only — no field here filters what
  /// can be typed, so this never decides what counts as a valid PIN.
  ///
  /// Starts on the hint because the first step recalls a PIN that already
  /// exists; [_Step.rekey] resets it, since that step is choosing a new one.
  late bool _numeric = widget.numericPinHint;

  static const _minLen = 6;

  @override
  void dispose() {
    _pinCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    _pinFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  /// Flips every field in the dialog between the number pad and the full
  /// keyboard, preserving anything already typed.
  Future<void> _toggleKeyboard() async {
    setState(() => _numeric = !_numeric);
    final target = _step == _Step.confirm
        ? _pinFocus
        : (_confirmFocus.hasFocus ? _confirmFocus : _newFocus);
    await reopenKeyboardFor(context, target);
  }

  /// Cheap path: they know the PIN. `unlock` returns false *before* caching
  /// anything on a mismatch, so a wrong guess here cannot disturb a vault that
  /// is already open.
  Future<void> _confirmExisting() async {
    final pin = _pinCtrl.text;
    if (pin.isEmpty) {
      setState(() => _error = 'Enter your PIN.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await VaultCipher.instance.unlock(widget.uid, pin);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _error = 'That PIN does not match. If you never chose one, '
            'tap "I don\'t know my PIN".';
        _pinCtrl.clear();
      });
      return;
    }
    await VaultCipher.instance.markPinUserChosen(widget.uid);
    if (mounted) Navigator.of(context).pop();
  }

  /// Rescue path: re-key the whole vault from the stored PIN onto one the user
  /// chooses. changePin flips the verifier last, so an interruption leaves the
  /// old PIN valid and the run can simply be repeated.
  Future<void> _rekey() async {
    if (_newCtrl.text.length < _minLen) {
      setState(() => _error = 'PIN must be at least $_minLen characters.');
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'PINs do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _done = 0;
      _total = 0;
    });
    final ok = await VaultCipher.instance.changePin(
      widget.uid,
      widget.storedPin,
      _newCtrl.text,
      onProgress: (done, total) {
        if (!mounted) return;
        setState(() {
          _done = done;
          _total = total;
        });
      },
    );
    if (!mounted) return;
    if (!ok) {
      // The stored PIN no longer validates — e.g. the PIN was changed on
      // another device. Nothing was rewritten; only the owner can proceed.
      setState(() {
        _busy = false;
        _step = _Step.confirm;
        // Back to recalling an existing PIN, so back to the hint's keyboard.
        _numeric = widget.numericPinHint;
        _error = 'Could not update the PIN automatically. '
            'Please enter your current PIN.';
      });
      return;
    }
    // changePin records custody itself.
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final isConfirm = _step == _Step.confirm;
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: c.primary.withOpacity(0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.key_rounded, color: c.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isConfirm ? 'Confirm your vault PIN' : 'Choose a PIN',
                        style: GoogleFonts.poppins(
                          color: c.textHigh,
                          fontSize: 17.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  isConfirm
                      ? 'Your message history is encrypted with a PIN. Confirm '
                          'it once so you can restore your messages on a new '
                          'phone or after reinstalling.\n\n'
                          'If your vault was set up with just your '
                          'fingerprint, you may never have been shown a PIN.'
                      : 'Pick a PIN you will remember. Every message you '
                          'already have is kept — it is re-encrypted under the '
                          'new PIN, nothing is deleted.',
                  style: GoogleFonts.poppins(
                    color: c.textMid,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                if (isConfirm)
                  _field(c, _pinCtrl, 'Enter PIN',
                      focusNode: _pinFocus, autofocus: true)
                else ...[
                  _field(c, _newCtrl, 'New PIN',
                      focusNode: _newFocus, autofocus: true),
                  const SizedBox(height: 10),
                  _field(c, _confirmCtrl, 'Confirm PIN',
                      focusNode: _confirmFocus),
                ],
                // Escape hatch from a wrong keyboard default, and load-bearing
                // on the confirm step: the number pad on some Android
                // keyboards has no ABC key, so a user whose PIN contains a
                // letter needs this to type it at all. The only other way out
                // of that step re-encrypts the entire vault.
                PinKeyboardToggle(
                  numeric: _numeric,
                  onToggle: _toggleKeyboard,
                  enabled: !_busy,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: c.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: c.error.withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            color: c.error, size: 15),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _error!,
                            style: GoogleFonts.poppins(
                              color: c.error,
                              fontSize: 11.5,
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_busy && !isConfirm) ...[
                  const SizedBox(height: 14),
                  LinearProgressIndicator(
                    value: _total > 0 ? _done / _total : null,
                    backgroundColor: c.surface,
                    color: c.primary,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _total > 0
                        ? 'Re-encrypting $_done of $_total… keep the app open.'
                        : 'Preparing… keep the app open.',
                    style: GoogleFonts.poppins(color: c.textLow, fontSize: 11),
                  ),
                ],
                if (isConfirm) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _step = _Step.rekey;
                                _error = null;
                                _pinCtrl.clear();
                                // Fresh fields, new heading, and this step
                                // *chooses* a PIN rather than recalling one —
                                // so the number-pad default applies again,
                                // even if the hint above said otherwise.
                                _numeric = true;
                              }),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        "I don't know my PIN",
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
                    onPressed:
                        _busy ? null : (isConfirm ? _confirmExisting : _rekey),
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
                            isConfirm ? 'Confirm' : 'Save PIN',
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

  Widget _field(AppThemeColors c, TextEditingController ctrl, String hint,
      {required FocusNode focusNode, bool autofocus = false}) {
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border, width: 1),
      ),
      child: TextField(
        controller: ctrl,
        focusNode: focusNode,
        obscureText: _obscure,
        autofocus: autofocus,
        enabled: !_busy,
        keyboardType:
            _numeric ? TextInputType.number : TextInputType.visiblePassword,
        // Length-limited only. Deliberately no digitsOnly filter even on the
        // number pad: the PIN is an Argon2id passphrase, and the confirm step
        // above is recalling one that may well contain letters.
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
          suffixIcon: IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
            icon: Icon(
              _obscure
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
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
