// VaultSettingsScreen — single screen that surfaces every vault control:
//   • About the vault — what it is and what it holds, in plain language.
//   • Auto-delete window (rolling retention).
//   • Change PIN.
//   • Unlock with fingerprint (opt in / out on this device).
//   • Delete vault data (keeps PIN).
//   • Reset vault (forgets PIN, destroys data).
//
// Reachable from SettingsScreen → "End-to-end encryption" → "Vault".

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:video_chat_app/l10n/app_localizations.dart';
import 'package:video_chat_app/services/chat_service.dart';
import 'package:video_chat_app/services/crypto/vault_cipher.dart';
import 'package:video_chat_app/services/crypto/vault_pin_custody.dart';
import 'package:video_chat_app/services/status_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/widgets/pin_keyboard_toggle.dart';

class VaultSettingsScreen extends StatefulWidget {
  const VaultSettingsScreen({super.key, required this.uid});

  final String uid;

  @override
  State<VaultSettingsScreen> createState() => _VaultSettingsScreenState();
}

class _VaultSettingsScreenState extends State<VaultSettingsScreen> {
  VaultSettings? _settings;
  bool _loading = true;

  /// Device has usable biometric hardware. When false the fingerprint row is
  /// hidden entirely rather than shown disabled — there is nothing to explain.
  bool _bioAvailable = false;

  /// Fingerprint unlock is on for this device. The presence of the stored PIN
  /// *is* the setting; there is no separate flag that could disagree with it.
  bool _bioEnabled = false;

  final LocalAuthentication _auth = LocalAuthentication();
  final _storage = biometricPinStorage;

  static const List<({int? days, String label})> _retentionOptions = [
    (days: 7, label: '7 days'),
    (days: 30, label: '30 days'),
    (days: 90, label: '90 days'),
    (days: 180, label: '6 months'),
    (days: null, label: 'Keep forever'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await VaultCipher.instance.getSettings(widget.uid);
    var canBio = false;
    var hasPin = false;
    try {
      canBio = await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
      final stored = await _storage.read(key: biometricPinKey(widget.uid));
      hasPin = stored != null && stored.isNotEmpty;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _settings = s;
      _bioAvailable = canBio;
      _bioEnabled = hasPin;
      _loading = false;
    });
  }

  Future<void> _pickRetention() async {
    final l10n = AppLocalizations.of(context);
    final c = AppThemeColors.of(context);
    final current = _settings?.retentionDays;
    final picked = await showModalBottomSheet<int?>(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.vaultSettingsAutoDelete,
                    style: TextStyle(
                        color: c.textHigh,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            for (final opt in _retentionOptions)
              ListTile(
                title: Text(opt.days == null ? l10n.vaultSettingsKeepForever : opt.label, style: TextStyle(color: c.textHigh)),
                trailing: opt.days == current
                    ? Icon(Icons.check_rounded, color: c.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, opt.days),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    // The sheet returns null both when dismissed and when the user picks
    // "Keep forever". Distinguish via the sentinel return path:
    // showModalBottomSheet returns the popped value verbatim. We accept the
    // tap-to-dismiss case by short-circuiting if nothing changed.
    if (!mounted) return;
    final dismissed = picked == null &&
        !_retentionOptions.any((o) => o.days == null);
    if (dismissed) return;
    if (picked == _settings?.retentionDays) return;

    await VaultCipher.instance.setRetention(widget.uid, picked);
    final pruned = await VaultCipher.instance.applyRetention(widget.uid);
    if (pruned > 0) {
      ChatService.invalidatePreWarm(widget.uid);
      StatusService.invalidatePreWarm(widget.uid);
    }
    if (!mounted) return;
    setState(() {
      _settings = VaultSettings(
        retentionDays: picked,
        createdAt: _settings?.createdAt,
        pinIsUserChosen: _settings?.pinIsUserChosen ?? false,
        pinIsNumeric: _settings?.pinIsNumeric ?? false,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(pruned > 0
          ? 'Saved. Pruned $pruned old entr${pruned == 1 ? "y" : "ies"}.'
          : 'Retention updated.'),
    ));
  }

  Future<void> _changePin() async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ChangePinDialog(
        uid: widget.uid,
        numericPinHint: _settings?.pinIsNumeric ?? false,
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.vaultSettingsPinChanged),
      ));
      await _load();
    }
  }

  Future<void> _toggleFingerprint() async {
    final l10n = AppLocalizations.of(context);
    final pinKey = biometricPinKey(widget.uid);
    final dismissedKey = biometricOfferDismissedKey(widget.uid);

    if (_bioEnabled) {
      await _storage.delete(key: pinKey);
      await _storage.write(key: dismissedKey, value: 'true');
      if (!mounted) return;
      setState(() => _bioEnabled = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.vaultSettingsBioTurnedOff),
      ));
      return;
    }

    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FingerprintPinDialog(
        uid: widget.uid,
        numericPinHint: _settings?.pinIsNumeric ?? false,
      ),
    );
    if (pin == null || !mounted) return;

    // Confirm it is really them before binding the PIN to a scan.
    try {
      final authed = await _auth.authenticate(
        localizedReason: l10n.vaultBioReasonEnrol,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (!authed) return;
    } catch (_) {
      return;
    }

    await _storage.write(key: pinKey, value: pin);
    await _storage.delete(key: dismissedKey);
    if (!mounted) return;
    setState(() => _bioEnabled = true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l10n.vaultSettingsBioTurnedOn),
    ));
  }

  Future<void> _confirmClearData() async {
    final l10n = AppLocalizations.of(context);
    final c = AppThemeColors.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.vaultSettingsClearDataTitle,
            style: TextStyle(
                color: c.textHigh, fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text(
          l10n.vaultSettingsClearDataDesc,
          style: TextStyle(color: c.textMid, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.vaultSettingsClearDataCancel, style: TextStyle(color: c.textMid)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.vaultSettingsClearDataConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    await VaultCipher.instance.clearVaultData(widget.uid);
    ChatService.invalidatePreWarm(widget.uid);
    StatusService.invalidatePreWarm(widget.uid);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.vaultSettingsDataDeleted)),
    );
  }

  Future<void> _confirmReset() async {
    final l10n = AppLocalizations.of(context);
    final c = AppThemeColors.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.vaultSettingsResetTitle,
            style: TextStyle(
                color: c.textHigh, fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text(
          l10n.vaultSettingsResetDesc,
          style: TextStyle(color: c.textMid, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.vaultSettingsClearDataCancel, style: TextStyle(color: c.textMid)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.vaultSettingsResetConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await VaultCipher.instance.reset(widget.uid);
    await _storage.delete(key: biometricPinKey(widget.uid));
    await _storage.delete(key: biometricOfferDismissedKey(widget.uid));
    ChatService.invalidatePreWarm(widget.uid);
    StatusService.invalidatePreWarm(widget.uid);
    if (!mounted) return;
    setState(() {
      _settings = null;
      _bioEnabled = false;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: c.chatBg,
      appBar: AppBar(
        backgroundColor: c.surface,
        title: Text(l10n.vaultSettingsTitle,
            style: TextStyle(
                color: c.textHigh, fontSize: 18, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: c.textHigh),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _aboutCard(c, l10n),
                const SizedBox(height: 8),
                _sectionHeader(c, l10n.vaultSettingsSectionPrivacy),
                _card(c, [
                  _tile(c,
                      icon: Icons.timer_outlined,
                      iconColor: c.primary,
                      title: l10n.vaultSettingsAutoDelete,
                      subtitle: _retentionLabel(l10n),
                      onTap: _settings == null ? null : _pickRetention),
                ]),
                const SizedBox(height: 8),
                _sectionHeader(c, l10n.vaultSettingsSectionPin),
                _card(c, [
                  _tile(c,
                      icon: Icons.password_rounded,
                      iconColor: Colors.blue,
                      title: l10n.vaultSettingsChangePin,
                      subtitle: l10n.vaultSettingsChangePinSubtitle,
                      onTap: _settings == null ? null : _changePin),
                  // Hidden outright on devices without biometric hardware —
                  // a permanently-off switch explains nothing.
                  if (_bioAvailable) ...[
                    Divider(color: c.surfaceAlt, height: 1),
                    _tile(c,
                        icon: Icons.fingerprint_rounded,
                        iconColor: Colors.teal,
                        title: l10n.vaultSettingsBioTitle,
                        subtitle: _bioEnabled
                            ? l10n.vaultSettingsBioSubOn
                            : l10n.vaultSettingsBioSubOff,
                        onTap: _settings == null ? null : _toggleFingerprint,
                        // No colour overrides here: the app's switchTheme
                        // already paints a white thumb on a primary track.
                        // Forcing the thumb to primary made it the same colour
                        // as its own track, so "on" rendered as a plain purple
                        // pill with no thumb to see.
                        trailing: Switch(
                          value: _bioEnabled,
                          onChanged: _settings == null
                              ? null
                              : (_) => _toggleFingerprint(),
                        )),
                  ],
                ]),
                const SizedBox(height: 8),
                _sectionHeader(c, l10n.vaultSettingsSectionDanger),
                _card(c, [
                  _tile(c,
                      icon: Icons.delete_sweep_outlined,
                      iconColor: Colors.orange,
                      title: l10n.vaultSettingsDeleteData,
                      subtitle: l10n.vaultSettingsDeleteDataSubtitle,
                      onTap: _settings == null ? null : _confirmClearData),
                  Divider(color: c.surfaceAlt, height: 1),
                  _tile(c,
                      icon: Icons.lock_reset_rounded,
                      iconColor: Colors.red,
                      title: l10n.vaultSettingsResetVault,
                      subtitle: l10n.vaultSettingsResetVaultSubtitle,
                      onTap: _settings == null ? null : _confirmReset),
                ]),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  String _retentionLabel(AppLocalizations l10n) {
    final d = _settings?.retentionDays;
    if (d == null) return l10n.vaultSettingsKeepForever;
    final label = _retentionOptions.firstWhere((o) => o.days == d, orElse: () => (days: d, label: '$d days')).label;
    return l10n.vaultSettingsDeleteAfter(label);
  }

  Widget _aboutCard(AppThemeColors c, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.surfaceAlt),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.shield_outlined, color: c.primary, size: 22),
          const SizedBox(width: 8),
          Text(l10n.vaultSettingsAboutTitle,
              style: TextStyle(
                  color: c.textHigh,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        Text(
          l10n.vaultSettingsAboutDesc,
          style: TextStyle(color: c.textMid, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 10),
        _bullet(c, l10n.vaultSettingsBulletMessages),
        _bullet(c, l10n.vaultSettingsBulletStatuses),
        const SizedBox(height: 10),
        Text(
          l10n.vaultSettingsNeverKept,
          style: TextStyle(color: c.textLow, fontSize: 12, height: 1.4),
        ),
      ]),
    );
  }

  Widget _bullet(AppThemeColors c, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('• ', style: TextStyle(color: c.textMid, fontSize: 13)),
        Expanded(
            child: Text(text,
                style: TextStyle(
                    color: c.textMid, fontSize: 13, height: 1.4))),
      ]),
    );
  }

  Widget _sectionHeader(AppThemeColors c, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(text,
          style: TextStyle(
              color: c.textLow,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2)),
    );
  }

  Widget _card(AppThemeColors c, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _tile(
    AppThemeColors c, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      enabled: onTap != null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title,
          style: TextStyle(
              color: c.textHigh, fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: TextStyle(color: c.textMid, fontSize: 12.5)),
      trailing: trailing ??
          (onTap == null
              ? null
              : Icon(Icons.chevron_right_rounded, color: c.textLow)),
    );
  }
}

// ─── Change PIN dialog ─────────────────────────────────────────────────────

class _ChangePinDialog extends StatefulWidget {
  const _ChangePinDialog({required this.uid, this.numericPinHint = false});
  final String uid;

  /// Which keyboard all three fields open with — see
  /// [VaultSettings.pinIsNumeric].
  ///
  /// Taken from the *current* PIN even though two of the three fields are
  /// choosing a new one, because the current-PIN field is the one that has to
  /// be filled first and the only one that can be entered wrong. The single
  /// toggle below the fields switches all three, so someone replacing a
  /// passphrase with digits types the old one, taps once, and carries on.
  final bool numericPinHint;

  @override
  State<_ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends State<_ChangePinDialog> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  final _oldFocus = FocusNode();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();
  bool _obscure = true;
  bool _busy = false;
  String? _error;
  int _done = 0;
  int _total = 0;

  /// Number pad vs full keyboard. A default only — nothing here filters input.
  late bool _numeric = widget.numericPinHint;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    _oldFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  /// Flips all three fields, preserving anything already typed.
  Future<void> _toggleKeyboard() async {
    setState(() => _numeric = !_numeric);
    final target = _confirmFocus.hasFocus
        ? _confirmFocus
        : (_newFocus.hasFocus ? _newFocus : _oldFocus);
    await reopenKeyboardFor(context, target);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_old.text.isEmpty) {
      setState(() => _error = l10n.vaultSettingsEnterCurrentPin);
      return;
    }
    if (_new.text.length < 6) {
      setState(() => _error = l10n.vaultSettingsNewPinMinLength);
      return;
    }
    if (_new.text != _confirm.text) {
      setState(() => _error = l10n.vaultSettingsNewPinMismatch);
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
      _old.text,
      _new.text,
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
      setState(() {
        _busy = false;
        _error = l10n.vaultSettingsCurrentPinIncorrect;
        _old.clear();
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.vaultSettingsChangePin,
            style: TextStyle(
                color: c.textHigh, fontSize: 17, fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 320,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              l10n.vaultSettingsChangeDialogDesc,
              style: TextStyle(color: c.textMid, fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            _field(c, _old, l10n.vaultSettingsCurrentPin,
                focusNode: _oldFocus, autofocus: true),
            const SizedBox(height: 10),
            _field(c, _new, l10n.vaultSettingsNewPin, focusNode: _newFocus),
            const SizedBox(height: 10),
            _field(c, _confirm, l10n.vaultSettingsConfirmNewPin, focusNode: _confirmFocus),
            PinKeyboardToggle(
              numeric: _numeric,
              onToggle: _toggleKeyboard,
              enabled: !_busy,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
            if (_busy && _total > 0) ...[
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: _done / _total,
                backgroundColor: c.surfaceAlt,
                color: c.primary,
              ),
              const SizedBox(height: 6),
              Text(l10n.vaultSettingsReencryptingCount(_done, _total),
                  style: TextStyle(color: c.textLow, fontSize: 11)),
            ],
          ]),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel, style: TextStyle(color: c.textMid)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: c.primary),
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(l10n.vaultSettingsChangeBtn),
          ),
        ],
      ),
    );
  }

  Widget _field(AppThemeColors c, TextEditingController ctrl, String hint,
      {required FocusNode focusNode, bool autofocus = false}) {
    return TextField(
      controller: ctrl,
      focusNode: focusNode,
      obscureText: _obscure,
      autofocus: autofocus,
      keyboardType:
          _numeric ? TextInputType.number : TextInputType.visiblePassword,
      // Length-limited only — no digitsOnly filter. The current-PIN field has
      // to accept whatever the existing PIN is, letters included.
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

// ─── Enable-fingerprint PIN check ──────────────────────────────────────────

/// Asks for the vault PIN and verifies it, so the caller has a PIN it can put
/// behind biometrics. Pops the verified PIN, or null if the user backed out.
///
/// Verification goes through `unlock`, which returns false *before* touching
/// the cached key, so a wrong guess here cannot disturb the open vault.
class _FingerprintPinDialog extends StatefulWidget {
  const _FingerprintPinDialog({required this.uid, this.numericPinHint = false});
  final String uid;

  /// Which keyboard the field opens with — see [VaultSettings.pinIsNumeric].
  final bool numericPinHint;

  @override
  State<_FingerprintPinDialog> createState() => _FingerprintPinDialogState();
}

class _FingerprintPinDialogState extends State<_FingerprintPinDialog> {
  final _pin = TextEditingController();
  final _pinFocus = FocusNode();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  /// Number pad vs full keyboard. A default only — nothing here filters input.
  late bool _numeric = widget.numericPinHint;

  @override
  void dispose() {
    _pin.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  Future<void> _toggleKeyboard() async {
    setState(() => _numeric = !_numeric);
    await reopenKeyboardFor(context, _pinFocus);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_pin.text.isEmpty) {
      setState(() => _error = l10n.vaultSettingsEnterCurrentPin);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await VaultCipher.instance.unlock(widget.uid, _pin.text);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _error = l10n.vaultIncorrectPin;
        _pin.clear();
      });
      return;
    }
    // A typed PIN that verifies is proof of custody.
    await VaultCipher.instance.markPinUserChosen(widget.uid);
    if (mounted) Navigator.of(context).pop(_pin.text);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.vaultSettingsBioPinDialogTitle,
            style: TextStyle(
                color: c.textHigh, fontSize: 17, fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 320,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              l10n.vaultSettingsBioPinDialogDesc,
              style: TextStyle(color: c.textMid, fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pin,
              focusNode: _pinFocus,
              obscureText: _obscure,
              autofocus: true,
              enabled: !_busy,
              keyboardType: _numeric
                  ? TextInputType.number
                  : TextInputType.visiblePassword,
              // Length-limited only — this field recalls an existing PIN, so
              // it has to accept letters.
              inputFormatters: [LengthLimitingTextInputFormatter(64)],
              style: TextStyle(color: c.textHigh, letterSpacing: 2),
              decoration: InputDecoration(
                hintText: l10n.vaultSettingsCurrentPin,
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
            ),
            PinKeyboardToggle(
              numeric: _numeric,
              onToggle: _toggleKeyboard,
              enabled: !_busy,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ]),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(l10n.commonCancel, style: TextStyle(color: c.textMid)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: c.primary),
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(l10n.vaultSettingsContinueBtn),
          ),
        ],
      ),
    );
  }
}

