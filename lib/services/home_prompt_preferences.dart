import 'package:shared_preferences/shared_preferences.dart';

/// Persistent budgets for optional Home prompts, independent of OS permission.
class HomePromptPreferences {
  HomePromptPreferences(this.prefs);

  final SharedPreferences prefs;
  static const visitKey = 'home_app_visits_v1';
  static const notificationTimeKey = 'notif_soft_ask_last_ms_v2';
  static const notificationVisitKey = 'notif_soft_ask_last_visit_v2';
  static const inviteKey = 'has_shown_invite_prompt';

  int get visits => prefs.getInt(visitKey) ?? 0;

  Future<void> recordVisit() async {
    await prefs.setInt(visitKey, visits + 1);
  }

  Future<void> deferNotifications(DateTime now) async {
    await prefs.setInt(notificationTimeKey, now.millisecondsSinceEpoch);
    await prefs.setInt(notificationVisitKey, visits);
  }

  bool canAskNotifications(DateTime now) {
    final lastMs = prefs.getInt(notificationTimeKey);
    if (lastMs == null) return true;
    final lastVisit = prefs.getInt(notificationVisitKey) ?? visits;
    return visits - lastVisit >= 5 &&
        now.difference(DateTime.fromMillisecondsSinceEpoch(lastMs)) >=
            const Duration(days: 7);
  }

  /// Preserve the once-ever budget when upgrading from either historic key.
  bool get hasShownInvite =>
      prefs.getBool(inviteKey) == true ||
      prefs.getBool('invite_prompt_shown_v1') == true ||
      prefs.getBool('has_shown_enjoying_gupshupgo') == true;

  Future<void> markInviteShown() async {
    await prefs.setBool(inviteKey, true);
  }
}
