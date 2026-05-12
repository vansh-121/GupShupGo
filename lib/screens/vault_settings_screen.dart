// VaultSettingsScreen — single screen that surfaces every vault control:
//   • What the vault stores (transparency for the user).
//   • Auto-delete window (rolling retention).
//   • Change PIN.
//   • Delete vault data (keeps PIN).
//   • Reset vault (forgets PIN, destroys data).
//
// Reachable from SettingsScreen → "End-to-end encryption" → "Vault".

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_chat_app/services/chat_service.dart';
import 'package:video_chat_app/services/crypto/vault_cipher.dart';
import 'package:video_chat_app/services/status_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';

class VaultSettingsScreen extends StatefulWidget {
  const VaultSettingsScreen({super.key, required this.uid});

  final String uid;

  @override
  State<VaultSettingsScreen> createState() => _VaultSettingsScreenState();
}

class _VaultSettingsScreenState extends State<VaultSettingsScreen> {
  VaultSettings? _settings;
  bool _loading = true;

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
    if (!mounted) return;
    setState(() {
      _settings = s;
      _loading = false;
    });
  }

  Future<void> _pickRetention() async {
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
                child: Text('Auto-delete old messages',
                    style: TextStyle(
                        color: c.textHigh,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            for (final opt in _retentionOptions)
              ListTile(
                title: Text(opt.label, style: TextStyle(color: c.textHigh)),
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
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(pruned > 0
          ? 'Saved. Pruned $pruned old entr${pruned == 1 ? "y" : "ies"}.'
          : 'Retention updated.'),
    ));
  }

  Future<void> _changePin() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ChangePinDialog(uid: widget.uid),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('PIN changed.'),
      ));
    }
  }

  Future<void> _confirmClearData() async {
    final c = AppThemeColors.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete vault data?',
            style: TextStyle(
                color: c.textHigh, fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text(
          'Removes every encrypted message and status from the cloud vault. '
          'Your PIN stays the same — new messages will encrypt under it as '
          'before. Cannot be undone.',
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
            child: const Text('Delete data'),
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
      const SnackBar(content: Text('Vault data deleted.')),
    );
  }

  Future<void> _confirmReset() async {
    final c = AppThemeColors.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reset vault?',
            style: TextStyle(
                color: c.textHigh, fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text(
          'Removes your PIN, deletes every encrypted entry, and clears the '
          'local cache. You will be asked to set a fresh PIN. Cannot be '
          'undone.',
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
    if (ok != true || !mounted) return;
    await VaultCipher.instance.reset(widget.uid);
    ChatService.invalidatePreWarm(widget.uid);
    StatusService.invalidatePreWarm(widget.uid);
    if (!mounted) return;
    setState(() => _settings = null);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Scaffold(
      backgroundColor: c.chatBg,
      appBar: AppBar(
        backgroundColor: c.surface,
        title: Text('Vault',
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
                _aboutCard(c),
                const SizedBox(height: 8),
                _sectionHeader(c, 'PRIVACY'),
                _card(c, [
                  _tile(c,
                      icon: Icons.timer_outlined,
                      iconColor: c.primary,
                      title: 'Auto-delete old messages',
                      subtitle: _retentionLabel(),
                      onTap: _settings == null ? null : _pickRetention),
                ]),
                const SizedBox(height: 8),
                _sectionHeader(c, 'PIN'),
                _card(c, [
                  _tile(c,
                      icon: Icons.password_rounded,
                      iconColor: Colors.blue,
                      title: 'Change PIN',
                      subtitle: 'Re-encrypts every vault entry',
                      onTap: _settings == null ? null : _changePin),
                ]),
                const SizedBox(height: 8),
                _sectionHeader(c, 'DANGER ZONE'),
                _card(c, [
                  _tile(c,
                      icon: Icons.delete_sweep_outlined,
                      iconColor: Colors.orange,
                      title: 'Delete vault data',
                      subtitle: 'Wipes encrypted history, keeps PIN',
                      onTap: _settings == null ? null : _confirmClearData),
                  Divider(color: c.surfaceAlt, height: 1),
                  _tile(c,
                      icon: Icons.lock_reset_rounded,
                      iconColor: Colors.red,
                      title: 'Reset vault',
                      subtitle: 'Forgets PIN and deletes everything',
                      onTap: _settings == null ? null : _confirmReset),
                ]),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  String _retentionLabel() {
    final d = _settings?.retentionDays;
    if (d == null) return 'Keep forever';
    return 'Delete after ${_retentionOptions.firstWhere((o) => o.days == d, orElse: () => (days: d, label: '$d days')).label}';
  }

  Widget _aboutCard(AppThemeColors c) {
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
          Text('What the vault stores',
              style: TextStyle(
                  color: c.textHigh,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        Text(
          'The vault holds an end-to-end-encrypted copy of your message '
          'history so it can survive a reinstall. Every entry is encrypted '
          'on this device with a key derived from your PIN (Argon2id → '
          'AES-256-GCM). Firebase never sees your PIN, your key, or any '
          'plaintext.',
          style: TextStyle(color: c.textMid, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 10),
        _bullet(c, 'Decrypted text and metadata of your messages'),
        _bullet(c, 'Text statuses you can read'),
        _bullet(c, 'AES content keys for status media (the media blobs '
            'themselves live in Storage, also encrypted)'),
        const SizedBox(height: 10),
        Text(
          'The vault does NOT store your call history, contacts, photos in '
          'chat, or anyone else\'s messages — only yours.',
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
      trailing: onTap == null
          ? null
          : Icon(Icons.chevron_right_rounded, color: c.textLow),
    );
  }
}

// ─── Change PIN dialog ─────────────────────────────────────────────────────

class _ChangePinDialog extends StatefulWidget {
  const _ChangePinDialog({required this.uid});
  final String uid;

  @override
  State<_ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends State<_ChangePinDialog> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;
  int _done = 0;
  int _total = 0;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_old.text.isEmpty) {
      setState(() => _error = 'Enter your current PIN.');
      return;
    }
    if (_new.text.length < 6) {
      setState(() => _error = 'New PIN must be at least 6 characters.');
      return;
    }
    if (_new.text != _confirm.text) {
      setState(() => _error = 'New PINs do not match.');
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
        _error = 'Current PIN is incorrect.';
        _old.clear();
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Change PIN',
            style: TextStyle(
                color: c.textHigh, fontSize: 17, fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 320,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              'Every encrypted entry will be re-encrypted under the new PIN. '
              'Keep the app open until this finishes.',
              style: TextStyle(color: c.textMid, fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            _field(c, _old, 'Current PIN', autofocus: true),
            const SizedBox(height: 10),
            _field(c, _new, 'New PIN'),
            const SizedBox(height: 10),
            _field(c, _confirm, 'Confirm new PIN'),
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
              Text('Re-encrypting $_done of $_total…',
                  style: TextStyle(color: c.textLow, fontSize: 11)),
            ],
          ]),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: c.textMid)),
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
                : const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _field(AppThemeColors c, TextEditingController ctrl, String hint,
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
