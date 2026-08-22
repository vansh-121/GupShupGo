// VaultLockedBanner — the standing way back in after "Restore later".
//
// Why this exists: declining the unlock prompt on a reinstall is a supported,
// non-destructive state — the ciphertext is still in users/{uid}/msgVault and a
// later unlock backfills everything missed. But nothing in the UI said so. The
// user saw their history replaced by 🔒 previews with no explanation and no
// visible way to fix it: the only unlock entry point was buried in Settings
// under a "vault" heading (which nobody thinks to open when the complaint is
// "where did my messages go"), and the automatic re-prompt only fires from
// HomeScreen.initState, so backgrounding and returning re-prompts nothing —
// it takes a full app kill. That combination made a recoverable state feel
// permanent, which is the actual risk, not the encryption.
//
// Deliberately NOT dismissible. A dismissible banner would recreate the exact
// dead end it exists to remove. It needs no dismiss affordance because it is
// self-clearing: it only renders while the vault is locked *and* holds history,
// and disappears the moment a PIN unlocks it. Kept to a single compact row so
// a user who genuinely wants to stay locked is not shouted at.
//
// Only shown for VaultState.needsUnlock — never for needsSetup. A brand-new
// account that backed out of PIN setup has no older messages, so promising to
// "restore" them would be a lie.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/theme/app_theme.dart';

class VaultLockedBanner extends StatelessWidget {
  const VaultLockedBanner({super.key, required this.onUnlock});

  /// Opens the unlock prompt. Awaited by the caller so the banner can clear
  /// itself as soon as the PIN succeeds.
  final Future<void> Function() onUnlock;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        // The whole strip is tappable, not just the button — the button is
        // there to make the action obvious, not to be the only target.
        onTap: () => onUnlock(),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          decoration: BoxDecoration(
            color: c.warning.withOpacity(0.10),
            border: Border(
              bottom: BorderSide(color: c.warning.withOpacity(0.30), width: 1),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_clock_rounded, color: c.warning, size: 20),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Older messages are locked',
                      style: GoogleFonts.poppins(
                        color: c.textHigh,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    // Says "still here" on purpose: the fear this banner is
                    // answering is that the history is gone, not locked.
                    Text(
                      'Your history is still here. Enter your PIN to restore it.',
                      style: GoogleFonts.poppins(
                        color: c.textMid,
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              TextButton(
                onPressed: () => onUnlock(),
                style: TextButton.styleFrom(
                  backgroundColor: c.warning.withOpacity(0.16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Unlock',
                  style: GoogleFonts.poppins(
                    color: c.warning,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
