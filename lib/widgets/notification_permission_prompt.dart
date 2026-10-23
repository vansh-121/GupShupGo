import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/main.dart' show sharedPrefs;
import 'package:video_chat_app/services/fcm_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/services/home_prompt_preferences.dart';

/// Home's optional notification soft-ask, with a persistent deferral budget.
///
/// Notifications used to be requested at sign-in, stacked with the other
/// first-launch dialogs — a wall of OS prompts before the user knew what the
/// app did. Instead this fires on a settled Home screen, and as a
/// *soft* pre-prompt: only a "Turn on" tap triggers the real
/// OS request. That matters on Android, where once the system dialog is denied
/// it can't be shown again — the pre-prompt lets us ask without burning that
/// one shot. A decline suppresses it for five further visits and seven days.
class NotificationPermissionPrompt {
  NotificationPermissionPrompt._();

  static bool _asking = false;

  /// Shows the soft-ask when its cooldown allows and permission is absent.
  /// No-op otherwise. Never throws.
  static Future<void> maybeAsk(
    BuildContext context, {
    required String userId,
  }) async {
    if (_asking || !context.mounted) return;
    final budget = HomePromptPreferences(sharedPrefs);
    if (!budget.canAskNotifications(DateTime.now())) return;
    _asking = true;
    try {
      final fcm = FCMService();
      if (await fcm.hasNotificationPermission()) return;
      // The old flag conflated granting permission with "Not now". Give users
      // who declined that version a fresh cooldown instead of retiring access.
      if (sharedPrefs.getBool('notif_soft_ask_handled_v1') == true &&
          sharedPrefs.getInt(HomePromptPreferences.notificationTimeKey) ==
              null) {
        await budget.deferNotifications(DateTime.now());
        return;
      }
      if (!context.mounted || ModalRoute.of(context)?.isCurrent != true) return;
      await _show(context, userId: userId, fcm: fcm, budget: budget);
    } catch (e) {
      debugPrint('[Notifications] soft ask failed: $e');
    } finally {
      _asking = false;
    }
  }

  static Future<void> _show(
    BuildContext context, {
    required String userId,
    required FCMService fcm,
    required HomePromptPreferences budget,
  }) async {
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
            Icon(Icons.notifications_active_rounded,
                color: c.primary, size: 22),
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

    // Dismissal (including Back/barrier) and an OS denial both get a cooldown.
    await budget.deferNotifications(DateTime.now());

    if (accepted == true) {
      // Now fire the real OS request, then re-register so the token mints
      // (iOS needs the permission first).
      await fcm.setupFCM(userId: userId, requestPermissions: true);
    }
  }
}
