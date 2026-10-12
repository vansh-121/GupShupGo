import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/services/ai/ai_assistant_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/widgets/ai/ai_quota_topup_sheet.dart';

/// Runs a GupAI one-shot action (translate / summarise / rewrite) in a bottom
/// sheet: fires it on open, then offers Copy / Insert / Regenerate. A spent
/// quota routes to the shared top-up sheet and re-runs on credit; transient
/// errors offer Retry. [onInsert] receives the final text when the user taps
/// Insert — the chat screen drops it into the composer.
Future<void> showAiActionSheet({
  required BuildContext context,
  required String title,
  required IconData icon,
  required String mode,
  required String input,
  Map<String, String>? params,
  required void Function(String text) onInsert,
}) {
  final c = AppThemeColors.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: c.cardBg,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _AiActionSheet(
      title: title,
      icon: icon,
      mode: mode,
      input: input,
      params: params,
      onInsert: onInsert,
    ),
  );
}

class _AiActionSheet extends StatefulWidget {
  const _AiActionSheet({
    required this.title,
    required this.icon,
    required this.mode,
    required this.input,
    required this.params,
    required this.onInsert,
  });

  final String title;
  final IconData icon;
  final String mode;
  final String input;
  final Map<String, String>? params;
  final void Function(String text) onInsert;

  @override
  State<_AiActionSheet> createState() => _AiActionSheetState();
}

class _AiActionSheetState extends State<_AiActionSheet> {
  final _service = AiAssistantService.instance;

  /// null while the request is in flight.
  AiActionResult? _result;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() => _result = null);
    final r = await _service.runAction(
      mode: widget.mode,
      input: widget.input,
      params: widget.params,
    );
    if (!mounted) return;
    setState(() => _result = r);
  }

  Future<void> _handleQuota(bool isPro, bool canEarn) async {
    await showAiQuotaTopUpSheet(
      context: context,
      isPro: isPro,
      canEarn: canEarn,
      onCredited: _run, // re-run the action once the top-up lands
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final result = _result;

    final Widget body;
    if (result == null) {
      body = _loading(c);
    } else {
      body = switch (result) {
        AiActionReply(:final text) => _resultView(c, text),
        AiActionQuota(:final isPro, :final canEarn) => _message(
            c,
            "You've used today's GupAI messages.",
            action: 'Get more',
            onAction: () => _handleQuota(isPro, canEarn),
          ),
        AiActionBusy() => _message(
            c,
            'GupAI is busy right now. Please try again in a moment.',
            action: 'Retry',
            onAction: _run,
          ),
        AiActionFailed(:final message) => _message(
            c,
            message == 'not-signed-in'
                ? 'Please sign in to use GupAI.'
                : "Couldn't reach GupAI. Check your connection and retry.",
            action: 'Retry',
            onAction: _run,
          ),
      };
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Icon(widget.icon, size: 18, color: c.primary),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.textHigh,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          body,
        ],
      ),
    );
  }

  Widget _loading(AppThemeColors c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: c.primary),
            ),
            const SizedBox(width: 12),
            Text(
              'GupAI is working…',
              style: GoogleFonts.poppins(fontSize: 13.5, color: c.textMid),
            ),
          ],
        ),
      );

  Widget _resultView(AppThemeColors c, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.42,
                color: c.textHigh,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: text));
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.content_copy_rounded, size: 16),
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.textHigh,
                  side: BorderSide(color: c.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                label: Text(
                  'Copy',
                  style:
                      GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  widget.onInsert(text);
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.north_east_rounded, size: 16),
                style: FilledButton.styleFrom(
                  backgroundColor: c.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                label: Text(
                  'Insert',
                  style:
                      GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: _run,
          icon: Icon(Icons.refresh_rounded, size: 16, color: c.textMid),
          label: Text(
            'Regenerate',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: c.textMid,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _message(
    AppThemeColors c,
    String msg, {
    required String action,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            msg,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13.5, height: 1.4, color: c.textMid),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              backgroundColor: c.primary,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            ),
            child: Text(
              action,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
