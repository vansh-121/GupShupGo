import 'package:flutter/material.dart';
import 'package:video_chat_app/main.dart';

import '../theme/chat_theme.dart';

/// Persists chat-theme choices: one global default plus optional per-chat
/// overrides.
///
/// Local-only by design. A chat theme is a device preference, like
/// [ThemeProvider]'s light/dark setting — it is not conversation data and does
/// not belong in Firestore where it would sync a phone's wallpaper onto a
/// tablet. Reads are synchronous against the globally initialised [sharedPrefs],
/// so there is no async init and no loading state for callers to handle.
class ChatThemeProvider extends ChangeNotifier {
  /// Global default, applied to any chat without an explicit override.
  static const _kDefault = 'pref_chat_theme_default';

  /// Per-chat override: `_kChatPrefix + chatRoomId`.
  static const _kChatPrefix = 'pref_chat_theme_room_';

  /// Gallery image backing the `custom` preset: `_kCustomPrefix + scope`.
  static const _kCustomPrefix = 'pref_chat_theme_custom_';

  /// Scope token standing in for "the global default" in the custom-image keys.
  static const _globalScope = '__global__';

  String _scopeKey(String? chatRoomId) =>
      (chatRoomId == null || chatRoomId.isEmpty) ? _globalScope : chatRoomId;

  // ── Reads ───────────────────────────────────────────────────────────

  /// The theme applied to [chatRoomId], or the global default when
  /// [chatRoomId] is null/unset.
  ///
  /// [unlocked] is passed in rather than read from `SubscriptionProvider` so this
  /// provider stays dependency-free and unit-testable. Callers pass
  /// `SubscriptionProvider.isProUnlocked` — **not** `isPro`, which is false for
  /// everybody while `pro_enabled` is off and would strip every Pro theme in the
  /// exact state where they are meant to be free. The parameter is named for the
  /// question it answers for that reason.
  ///
  /// A Pro theme resolves to [ChatThemeCatalog.defaultTheme] when [unlocked] is
  /// false, so a lapsed subscription degrades gracefully instead of leaving a
  /// paid look behind — and the stored id is left untouched, so it returns if
  /// they resubscribe.
  ChatTheme resolve(String? chatRoomId, {required bool unlocked}) {
    final scope = _scopeKey(chatRoomId);
    String? id;
    if (scope != _globalScope) {
      id = sharedPrefs.getString(_kChatPrefix + scope);
    }
    // Fall back to the global default when this chat has no override of its own.
    var effectiveScope = scope;
    if (id == null) {
      id = sharedPrefs.getString(_kDefault);
      effectiveScope = _globalScope;
    }

    var theme = ChatThemeCatalog.byId(id);
    if (theme.isPro && !unlocked) return ChatThemeCatalog.defaultTheme;

    if (theme.id == ChatThemeCatalog.customId) {
      final path = sharedPrefs.getString(_kCustomPrefix + effectiveScope);
      // A `custom` selection with no image behind it is meaningless — treat it
      // as unset rather than rendering an empty background.
      if (path == null || path.isEmpty) return ChatThemeCatalog.defaultTheme;
      theme = theme.withImagePath(path);
    }
    return theme;
  }

  /// The raw stored id for [chatRoomId] without the Pro downgrade, so the picker
  /// can show the user's actual selection while it is locked.
  String selectedId(String? chatRoomId) {
    final scope = _scopeKey(chatRoomId);
    if (scope != _globalScope) {
      final own = sharedPrefs.getString(_kChatPrefix + scope);
      if (own != null) return own;
    }
    return sharedPrefs.getString(_kDefault) ?? ChatThemeCatalog.defaultTheme.id;
  }

  /// True when this chat has its own override rather than inheriting the global
  /// default.
  bool hasOverride(String chatRoomId) =>
      sharedPrefs.containsKey(_kChatPrefix + chatRoomId);

  // ── Writes ──────────────────────────────────────────────────────────

  /// Applies [theme] to a single chat, or to the global default when
  /// [chatRoomId] is null.
  ///
  /// [imagePath] is required for [ChatThemeCatalog.customId] and must already
  /// point at a durable location (app documents, not temp).
  Future<void> apply(
    String? chatRoomId,
    ChatTheme theme, {
    String? imagePath,
  }) async {
    final scope = _scopeKey(chatRoomId);
    if (theme.id == ChatThemeCatalog.customId && imagePath != null) {
      await sharedPrefs.setString(_kCustomPrefix + scope, imagePath);
    }
    if (scope == _globalScope) {
      await sharedPrefs.setString(_kDefault, theme.id);
    } else {
      await sharedPrefs.setString(_kChatPrefix + scope, theme.id);
    }
    notifyListeners();
  }

  /// Sets the global default and drops every per-chat override, so "apply to all
  /// chats" actually changes all of them instead of being silently shadowed by
  /// older per-chat picks.
  Future<void> applyToAll(ChatTheme theme, {String? imagePath}) async {
    final overrides =
        sharedPrefs.getKeys().where((k) => k.startsWith(_kChatPrefix)).toList();
    for (final key in overrides) {
      await sharedPrefs.remove(key);
    }
    await apply(null, theme, imagePath: imagePath);
  }

  /// Removes this chat's override so it follows the global default again.
  Future<void> clearOverride(String chatRoomId) async {
    await sharedPrefs.remove(_kChatPrefix + chatRoomId);
    await sharedPrefs.remove(_kCustomPrefix + chatRoomId);
    notifyListeners();
  }
}
