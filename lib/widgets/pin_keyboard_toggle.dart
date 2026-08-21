// PinKeyboardToggle — switches a vault PIN field between the number pad and
// the full keyboard.
//
// Why this exists: PIN fields default to a number pad, because virtually every
// PIN is digits. But nothing about the vault enforces that — the key is derived
// from the PIN string via Argon2id, which accepts any characters, and users who
// set a passphrase on an older build still need to type it to reach their
// history. So no PIN field filters input; the keyboard is a default, and this
// is the way out of a wrong default.
//
// It matters most on the unlock screen. `TextInputType.number` opens Gboard's
// number pad, which on some Android keyboards has no ABC key at all — without
// this button, a user whose PIN contains a letter could be shown a keyboard
// that physically cannot type it, with only a vault-destroying "Forgot PIN?"
// next to it. The full keyboard is always the capable superset: it can type
// digits, so this toggle can never make a PIN unenterable in either direction.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// Re-opens the soft keyboard so a changed `keyboardType` takes effect.
///
/// Android keeps showing the keyboard it already has until the field is
/// re-focused, so flipping the type alone appears to do nothing until the user
/// taps the field again. Dropping focus and restoring it forces the IME to be
/// re-requested with the new type.
Future<void> reopenKeyboardFor(BuildContext context, FocusNode node) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await Future<void>.delayed(const Duration(milliseconds: 60));
  if (context.mounted) node.requestFocus();
}

class PinKeyboardToggle extends StatelessWidget {
  const PinKeyboardToggle({
    super.key,
    required this.numeric,
    required this.onToggle,
    this.enabled = true,
  });

  /// Current state of the field(s) this toggle controls.
  final bool numeric;

  /// Flips the mode and re-opens the keyboard — see [reopenKeyboardFor].
  final VoidCallback onToggle;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);

    return Padding(
      // Breathing room on both sides, owned here rather than at the call sites.
      // Above: this widget always follows a bordered PIN field, and a compact
      // TextButton has almost no margin of its own, so without it the label
      // sits flush against the field's border and reads as part of it.
      //
      // Below: what follows is another small text button — "Restore later",
      // "I don't know my PIN" — and both targets are shrink-wrapped to their
      // text, so they end up two undersized tap areas a few pixels apart. The
      // mis-tap is not symmetric: hitting this by accident flips a keyboard,
      // while hitting the one below dismisses the dialog with the vault still
      // locked. The call sites add their own gap on top of this.
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: enabled ? onToggle : null,
          style: TextButton.styleFrom(
            // No horizontal padding: every other left-aligned element in these
            // dialogs — heading, info box, the field's own border, and the
            // secondary action directly below — sits flush on the content
            // edge, and the toggle has to join that column rather than float
            // between it and the field's inset text.
            padding: const EdgeInsets.symmetric(vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          icon: Icon(
            numeric ? Icons.keyboard_rounded : Icons.dialpad_rounded,
            size: 15,
            color: c.textMid,
          ),
          // Named for what it switches to, not what is active — a label that
          // states the current mode reads as a status and gets ignored by
          // exactly the user who needs to press it.
          label: Text(
            numeric ? 'Use letters instead' : 'Use numbers instead',
            style: GoogleFonts.poppins(
              color: c.textMid,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
