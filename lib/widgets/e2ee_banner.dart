import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// Reusable end-to-end encryption notice, modelled after WhatsApp's
/// "Messages and calls are end-to-end encrypted" banner.
///
/// Three preset styles:
///   • [E2EEBanner.chat]  – yellow pill at the top of an empty chat
///   • [E2EEBanner.inline] – subtle one-liner under input fields
///   • [E2EEBanner.card]  – full-width informational card for settings
class E2EEBanner {
  E2EEBanner._();

  /// Centred pill shown as the first item in a chat conversation. Always
  /// visible, never dismissible — same as WhatsApp's behaviour.
  static Widget chat(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Center(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: c.isDark
              ? const Color(0xFF2A2D32)
              : const Color(0xFFFFF5C4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 14, color: c.isDark ? c.textMid : Colors.brown[700]),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Messages are end-to-end encrypted. No one outside this '
                'chat, not even GupShupGo, can read them.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  height: 1.4,
                  color: c.isDark ? c.textMid : Colors.brown[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One-line caption shown under composers (status, profile, etc.).
  static Widget inline(BuildContext context, {String? text}) {
    final c = AppThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, size: 12, color: c.textLow),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text ?? 'End-to-end encrypted',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: c.textLow,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Full informational card for settings / about screens.
  static Widget card(BuildContext context, {required String body}) {
    final c = AppThemeColors.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.primaryLt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_rounded, color: c.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'End-to-end encrypted',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.textHigh,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    height: 1.5,
                    color: c.textMid,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
