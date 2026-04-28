import 'package:video_chat_app/main.dart';

/// Persists all user-facing settings to SharedPreferences so they survive
/// app restarts. Uses the globally initialised `sharedPrefs` instance from
/// main.dart.
class SettingsService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final SettingsService _instance = SettingsService._();
  factory SettingsService() => _instance;
  SettingsService._();

  // ── Keys ───────────────────────────────────────────────────────────────────
  static const _kMessageNotifications = 'pref_message_notifications';
  static const _kGroupNotifications = 'pref_group_notifications';
  static const _kCallNotifications = 'pref_call_notifications';
  static const _kShowReadReceipts = 'pref_show_read_receipts';
  static const _kShowLastSeen = 'pref_show_last_seen';
  static const _kMutedChats = 'pref_muted_chats';

  // ── Notification prefs ─────────────────────────────────────────────────────

  bool get messageNotifications =>
      sharedPrefs.getBool(_kMessageNotifications) ?? true;
  set messageNotifications(bool v) =>
      sharedPrefs.setBool(_kMessageNotifications, v);

  bool get groupNotifications =>
      sharedPrefs.getBool(_kGroupNotifications) ?? true;
  set groupNotifications(bool v) =>
      sharedPrefs.setBool(_kGroupNotifications, v);

  bool get callNotifications =>
      sharedPrefs.getBool(_kCallNotifications) ?? true;
  set callNotifications(bool v) =>
      sharedPrefs.setBool(_kCallNotifications, v);

  // ── Privacy prefs ──────────────────────────────────────────────────────────

  bool get showReadReceipts =>
      sharedPrefs.getBool(_kShowReadReceipts) ?? true;
  set showReadReceipts(bool v) =>
      sharedPrefs.setBool(_kShowReadReceipts, v);

  bool get showLastSeen => sharedPrefs.getBool(_kShowLastSeen) ?? true;
  set showLastSeen(bool v) => sharedPrefs.setBool(_kShowLastSeen, v);

  // ── Muted chats ────────────────────────────────────────────────────────────

  Set<String> get mutedChatIds =>
      (sharedPrefs.getStringList(_kMutedChats) ?? []).toSet();

  bool isChatMuted(String chatRoomId) => mutedChatIds.contains(chatRoomId);

  void muteChat(String chatRoomId) {
    final muted = mutedChatIds..add(chatRoomId);
    sharedPrefs.setStringList(_kMutedChats, muted.toList());
  }

  void unmuteChat(String chatRoomId) {
    final muted = mutedChatIds..remove(chatRoomId);
    sharedPrefs.setStringList(_kMutedChats, muted.toList());
  }

  void toggleMuteChat(String chatRoomId) {
    if (isChatMuted(chatRoomId)) {
      unmuteChat(chatRoomId);
    } else {
      muteChat(chatRoomId);
    }
  }
}
