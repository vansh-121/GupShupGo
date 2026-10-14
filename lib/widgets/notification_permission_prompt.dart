import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/main.dart' show sharedPrefs;
import 'package:video_chat_app/services/fcm_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// A one-time, contextual "turn on notifications?" soft-ask.
///
/// Notifications used to be requested at sign-in, stacked with the other
/// first-launch dialogs — a wall of OS prompts before the user knew what the
/// app did. Instead this fires at a natural moment (first time a chat is
/// opened), and as a *soft* pre-prompt: only a "Turn on" tap triggers the real
/// OS request. That matters on Android, where once the system dialog is denied
/// it can't be shown again — the pre-prompt lets us ask without burning that
/// one shot, and a decline just defers to Settings instead of nagging.
class NotificationPermissionPrompt {
  NotificationPermissionPrompt._();

  /// Persisted so the automatic ask happens at most once, ever.
  static const _kHandledKey = 'notif_soft_ask_handled_v1';

  /// Guards against two chats opening in the same frame both asking.
  static bool _askedThisSession = false;

  /// Shows the soft-ask if it hasn't been handled before and notifications
  /// aren't already granted. No-op otherwise. Never throws.
  static Future<void> maybeAsk(
    BuildContext context, {
    required String userId,
  }) async {
    if (_askedThisSession) return;
    if (sharedPrefs.getBool(_kHandledKey) == true) return;

    final fcm = FCMService();
    // Already granted (returning user, or granted elsewhere) — nothing to ask.
    if (await fcm.hasNotificationPermission()) {
      await sharedPrefs.setBool(_kHandledKey, true);
      return;
    }

    _askedThisSession = true;
    if (!context.mounted) return;

    final c = AppThemeColors.of(context);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.border, width: 1),
        ),
        title: Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: c.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Turn on notifications?',
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
          'Get notified when friends message or call you. You can change this '
          'anytime in Settings.',
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Turn on',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    // Either way, don't auto-ask again — a decline defers to Settings rather
    // than re-prompting on every chat open.
    await sharedPrefs.setBool(_kHandledKey, true);

    if (accepted == true) {
      // Now fire the real OS request, then re-register so the token mints
      // (iOS needs the permission first).
      await fcm.setupFCM(userId: userId, requestPermissions: true);
    }
  }
}
