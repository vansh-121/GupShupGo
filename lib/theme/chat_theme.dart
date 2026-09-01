import 'dart:io';

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// A subtle repeating motif painted over a chat background.
///
/// Flat colour backgrounds read as a dead wall behind the bubbles, which is why
/// every messenger worth copying puts *something* back there — WhatsApp its
/// doodles, Telegram its patterns. These are drawn procedurally by
/// `ChatPatternPainter` rather than shipped as images: an asset per theme would
/// add megabytes to the APK and still be the wrong resolution on half the
/// devices, and at 5-8% opacity a vector motif is indistinguishable from a
/// bitmap one.
enum ChatPattern {
  /// No overlay — the background is exactly its colour or gradient.
  none,

  /// Fine dot matrix. The quietest option; reads as texture, not decoration.
  dots,

  /// Sparse outlined circles of varying size.
  bubbles,

  /// Rotating small motifs (chat bubble, heart, spark, ring), WhatsApp-style.
  doodles,
}

/// A per-conversation chat appearance: message-area background plus bubble
/// colours.
///
/// ## Why presets carry a fixed [brightness]
///
/// Bubble *text* colour is not stored here, and deliberately so. Across
/// `chat_screen`, `voice_message_bubble`, `reply_quote_card` and
/// `link_preview_card` the convention is already uniform and ~20 expressions
/// deep: sent bubbles draw white text, received bubbles draw
/// `AppThemeColors.textHigh / textMid / textLow`.
///
/// Rather than thread a text colour through all of those, a preset declares the
/// [brightness] its palette was designed for, and the message list is wrapped in
/// the matching [AppTheme] (see `_ChatThemedArea` in `chat_screen.dart`). Every
/// nested widget then resolves its text against the right palette for free, and
/// bubble fills still come from the preset.
///
/// The contract each preset must honour:
///   * [sentBubble] — and *every* stop of [sentGradient] — reads as
///     [Brightness.dark] to `ThemeData.estimateBrightnessForColor`, i.e. clears
///     4.5:1 against white. This is not a style preference: the sent-bubble
///     branch of `_buildMessage` hardcodes `Colors.white`, so a pale stop here
///     produces an unreadable message rather than a pale bubble. It is why the
///     vivid presets use deep saturated fills rather than the brighter mid-tones
///     the same palettes suggest — a bright coral or mint sits near 3:1 under
///     white, which is the level of "looks fine in the mockup, unreadable in
///     sunlight" this app should not ship. Asserted in
///     `test/provider/chat_theme_provider_test.dart`.
///   * [receivedBubble] matches [brightness] — light fill for
///     [Brightness.light], dark fill for [Brightness.dark].
///
/// A [brightness] of `null` means "follow the app theme"; such a preset must
/// leave the colour overrides null too so it inherits the app palette wholesale.
@immutable
class ChatTheme {
  const ChatTheme({
    required this.id,
    required this.name,
    this.isPro = false,
    this.brightness,
    this.background,
    this.backgroundGradient,
    this.sentBubble,
    this.sentGradient,
    this.receivedBubble,
    this.pattern = ChatPattern.none,
    this.patternColor,
    this.patternOpacity = 0.06,
    this.imagePath,
  });

  /// Stable key persisted in SharedPreferences. Never rename an existing id —
  /// a saved preference pointing at an unknown id falls back to [defaultTheme].
  /// [name] is free to change; only the id is the contract.
  final String id;
  final String name;
  final bool isPro;

  /// Palette this preset was designed against, or `null` to follow the app's
  /// light/dark setting.
  final Brightness? brightness;

  /// Flat background colour. `null` falls back to `AppThemeColors.chatBg`.
  ///
  /// Always set this even when [backgroundGradient] is, because the `Scaffold`
  /// behind the message list paints the flat colour: without it the area under
  /// the app bar and above the composer would fall back to the app palette and
  /// bracket the theme in two stripes of the wrong colour.
  final Color? background;

  /// Optional vertical gradient, drawn instead of [background] behind the
  /// message list.
  final List<Color>? backgroundGradient;

  final Color? sentBubble;

  /// Diagonal gradient for sent bubbles, drawn instead of [sentBubble].
  ///
  /// A flat fill is what made the first pass at these presets look cheap; two
  /// stops across a 44px bubble is most of the difference between this and the
  /// bubbles in Instagram or Telegram. [sentBubble] must still be set as the
  /// fallback for surfaces that can only take a single colour (the picker
  /// preview's smallest elements, and anything reading the palette rather than
  /// the decoration).
  final List<Color>? sentGradient;

  final Color? receivedBubble;

  final ChatPattern pattern;

  /// Hue of the [pattern] overlay. `null` uses the palette's `textHigh`, which
  /// keeps a pattern legible on both a light and a dark preset without needing a
  /// second constant.
  final Color? patternColor;

  /// Alpha of the pattern overlay. Kept in the 0.04-0.09 band by every preset:
  /// above that it competes with the bubbles instead of sitting behind them.
  final double patternOpacity;

  /// Absolute path to a user-chosen background photo (the `custom` preset).
  /// Lives in the app documents directory so it survives OS temp cleanup.
  final String? imagePath;

  /// True when this preset defers to the app's light/dark palette entirely.
  bool get followsAppTheme => brightness == null;

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  ChatTheme withImagePath(String? path) => ChatTheme(
        id: id,
        name: name,
        isPro: isPro,
        brightness: brightness,
        background: background,
        backgroundGradient: backgroundGradient,
        sentBubble: sentBubble,
        sentGradient: sentGradient,
        receivedBubble: receivedBubble,
        pattern: pattern,
        patternColor: patternColor,
        patternOpacity: patternOpacity,
        imagePath: path,
      );

  Color backgroundOf(AppThemeColors c) => background ?? c.chatBg;
  Color sentOf(AppThemeColors c) => sentBubble ?? c.sent;
  Color receivedOf(AppThemeColors c) => receivedBubble ?? c.received;

  /// Sent-bubble gradient, or `null` when the flat [sentOf] colour should be
  /// used. Diagonal rather than vertical: on a bubble only ~40px tall a
  /// top-to-bottom ramp is invisible, while corner-to-corner catches the wide
  /// axis too.
  Gradient? sentGradientOf(AppThemeColors c) {
    final stops = sentGradient;
    if (stops == null || stops.length < 2) return null;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: stops,
    );
  }

  /// Colour the pattern overlay is stroked in, opacity already applied.
  Color patternInk(AppThemeColors c) =>
      (patternColor ?? c.textHigh).withOpacity(patternOpacity);

  /// Decoration for the message area, or `null` when a plain
  /// `Scaffold.backgroundColor` is enough (the common case — avoids an extra
  /// layer for the default theme).
  Decoration? decorationOf(AppThemeColors c) {
    if (hasImage) {
      final file = File(imagePath!);
      // A picked file can vanish (user cleared storage, restored a backup onto a
      // new device). Fall through to the flat colour rather than throwing inside
      // build.
      if (file.existsSync()) {
        return BoxDecoration(
          color: backgroundOf(c),
          image: DecorationImage(
            image: FileImage(file),
            fit: BoxFit.cover,
            // Wash the photo toward the app background rather than dimming it
            // to black. A gallery pick is arbitrary — a bright beach shot under
            // a light theme's dark text is unreadable, and darkening would only
            // fix that for the dark theme. Pulling it toward `chatBg` keeps
            // whichever text colour the app is already using legible.
            colorFilter: ColorFilter.mode(
              backgroundOf(c).withOpacity(0.34),
              BlendMode.srcOver,
            ),
          ),
        );
      }
    }
    if (backgroundGradient != null && backgroundGradient!.length > 1) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: backgroundGradient!,
        ),
      );
    }
    return null;
  }
}

/// The built-in chat themes.
///
/// ## Why six of them are free
///
/// The Pro perk is *choice plus your own photo*, not the existence of the
/// feature. A picker holding one usable preset is not a feature anyone will find
/// twice, and `pro_enabled` defaults to false — with the Pro rows hidden in that
/// state (see `ChatThemeSheet`), a two-entry catalogue meant production users saw
/// exactly one theme next to "Default". Six free presets, spanning light and
/// dark, make the picker worth opening on its own; the remaining six plus the
/// gallery background are what the subscription buys.
///
/// The free/Pro split is asserted in `test/provider/chat_theme_provider_test.dart`
/// against the counts printed on the Premium screen, so moving a preset between
/// tiers fails the build until that copy is updated too.
class ChatThemeCatalog {
  ChatThemeCatalog._();

  static const String customId = 'custom';

  // ── Free ────────────────────────────────────────────────────────────

  static const ChatTheme defaultTheme = ChatTheme(
    id: 'default',
    name: 'Default',
    // No overrides at all: follows the app's light/dark theme, which is what
    // every existing chat looks like today. Deliberately un-patterned — this is
    // the baseline a user returns to, so it must stay identical to the app's own
    // chat surface.
  );

  static const ChatTheme _violet = ChatTheme(
    id: 'violet',
    name: 'Violet',
    brightness: Brightness.light,
    background: Color(0xFFF4F2FE),
    sentBubble: Color(0xFF6C5CE7),
    sentGradient: [Color(0xFF7355EE), Color(0xFF5138C4)],
    receivedBubble: Color(0xFFFFFFFF),
    pattern: ChatPattern.dots,
    patternColor: Color(0xFF6C5CE7),
    patternOpacity: 0.07,
  );

  static const ChatTheme _midnight = ChatTheme(
    id: 'midnight',
    name: 'Midnight',
    brightness: Brightness.dark,
    background: Color(0xFF0A0D18),
    backgroundGradient: [Color(0xFF11162A), Color(0xFF070911)],
    sentBubble: Color(0xFF5B4BE0),
    sentGradient: [Color(0xFF6656E8), Color(0xFF3B2FA8)],
    receivedBubble: Color(0xFF171B2B),
    pattern: ChatPattern.dots,
    patternColor: Color(0xFF9C8CFF),
    patternOpacity: 0.08,
  );

  /// Kept under the `slate` id — it is the one preset that shipped, so anyone
  /// already on it inherits this rebuilt palette instead of being reset. The
  /// original was a flat grey-blue on grey and was the reason this whole pass
  /// happened.
  static const ChatTheme _graphite = ChatTheme(
    id: 'slate',
    name: 'Graphite',
    brightness: Brightness.light,
    background: Color(0xFFEDF1F7),
    sentBubble: Color(0xFF3E4C5E),
    sentGradient: [Color(0xFF4C5D72), Color(0xFF2B3644)],
    receivedBubble: Color(0xFFFFFFFF),
    pattern: ChatPattern.dots,
    patternColor: Color(0xFF475569),
    patternOpacity: 0.07,
  );

  static const ChatTheme _blush = ChatTheme(
    id: 'blush',
    name: 'Blush',
    brightness: Brightness.light,
    background: Color(0xFFFDF2F7),
    sentBubble: Color(0xFFDB2777),
    sentGradient: [Color(0xFFD62575), Color(0xFF9D174D)],
    receivedBubble: Color(0xFFFFFFFF),
    pattern: ChatPattern.bubbles,
    patternColor: Color(0xFFDB2777),
    patternOpacity: 0.07,
  );

  /// A deep green bubble on a pale mint field — the name describes the
  /// background, not the fill. A mid-tone mint bubble is the obvious reading of
  /// the name and sits around 2.5:1 under white text, so it is not an option
  /// here.
  static const ChatTheme _mint = ChatTheme(
    id: 'mint',
    name: 'Mint',
    brightness: Brightness.light,
    background: Color(0xFFEFF8F3),
    sentBubble: Color(0xFF0A7454),
    sentGradient: [Color(0xFF0B7E5B), Color(0xFF03543B)],
    receivedBubble: Color(0xFFFFFFFF),
    pattern: ChatPattern.doodles,
    patternColor: Color(0xFF047857),
    patternOpacity: 0.06,
  );

  // ── Pro ─────────────────────────────────────────────────────────────

  static const ChatTheme _amoled = ChatTheme(
    id: 'amoled',
    name: 'AMOLED',
    isPro: true,
    brightness: Brightness.dark,
    background: Color(0xFF000000),
    sentBubble: Color(0xFF2F2568),
    sentGradient: [Color(0xFF3B2FA8), Color(0xFF201A50)],
    receivedBubble: Color(0xFF0E0F14),
    // No pattern: the entire point of this preset is pixels that are genuinely
    // off on an OLED panel, and a 7% overlay would light every one of them.
  );

  static const ChatTheme _ocean = ChatTheme(
    id: 'ocean',
    name: 'Ocean',
    isPro: true,
    brightness: Brightness.dark,
    background: Color(0xFF07243A),
    backgroundGradient: [Color(0xFF0B3350), Color(0xFF04141F)],
    sentBubble: Color(0xFF14618F),
    sentGradient: [Color(0xFF1C769F), Color(0xFF0B3F5E)],
    receivedBubble: Color(0xFF0E3350),
    pattern: ChatPattern.bubbles,
    patternColor: Color(0xFF7FD4FF),
    patternOpacity: 0.06,
  );

  static const ChatTheme _sunset = ChatTheme(
    id: 'sunset',
    name: 'Sunset',
    isPro: true,
    brightness: Brightness.light,
    background: Color(0xFFFFF3EA),
    backgroundGradient: [Color(0xFFFFE3CE), Color(0xFFFFF8F2)],
    sentBubble: Color(0xFFBE3820),
    sentGradient: [Color(0xFFC93E24), Color(0xFF97260F)],
    receivedBubble: Color(0xFFFFFFFF),
    pattern: ChatPattern.doodles,
    patternColor: Color(0xFFD2542E),
    patternOpacity: 0.08,
  );

  static const ChatTheme _emerald = ChatTheme(
    id: 'emerald',
    name: 'Emerald',
    isPro: true,
    brightness: Brightness.dark,
    background: Color(0xFF062420),
    backgroundGradient: [Color(0xFF093029), Color(0xFF03130F)],
    sentBubble: Color(0xFF0A7550),
    sentGradient: [Color(0xFF0C8259), Color(0xFF045238)],
    receivedBubble: Color(0xFF0C332B),
    pattern: ChatPattern.doodles,
    patternColor: Color(0xFF34D399),
    patternOpacity: 0.06,
  );

  static const ChatTheme _nebula = ChatTheme(
    id: 'nebula',
    name: 'Nebula',
    isPro: true,
    brightness: Brightness.dark,
    background: Color(0xFF120826),
    backgroundGradient: [Color(0xFF200D47), Color(0xFF090315)],
    sentBubble: Color(0xFF6D3BDE),
    sentGradient: [Color(0xFF7C4DF0), Color(0xFF4C1D95)],
    receivedBubble: Color(0xFF221142),
    pattern: ChatPattern.bubbles,
    patternColor: Color(0xFFC4B5FD),
    patternOpacity: 0.08,
  );

  static const ChatTheme _latte = ChatTheme(
    id: 'latte',
    name: 'Latte',
    isPro: true,
    brightness: Brightness.light,
    background: Color(0xFFF8F2E9),
    sentBubble: Color(0xFF77593C),
    sentGradient: [Color(0xFF876848), Color(0xFF57402A)],
    receivedBubble: Color(0xFFFFFFFF),
    pattern: ChatPattern.dots,
    patternColor: Color(0xFF7A5C3E),
    patternOpacity: 0.08,
  );

  /// Photo background from the user's gallery. Bubbles stay on the app palette,
  /// so it reads correctly over both light and dark photos.
  static const ChatTheme custom = ChatTheme(
    id: customId,
    name: 'My photo',
    isPro: true,
  );

  /// Display order for the picker. Free presets first, so the sheet reads as a
  /// usable list with extras below rather than a wall of locks.
  static const List<ChatTheme> presets = [
    defaultTheme,
    _violet,
    _midnight,
    _graphite,
    _blush,
    _mint,
    _amoled,
    _ocean,
    _sunset,
    _emerald,
    _nebula,
    _latte,
    custom,
  ];

  /// Presets available without a subscription.
  static List<ChatTheme> get freePresets =>
      presets.where((t) => !t.isPro).toList();

  /// Presets the subscription unlocks, gallery background included.
  static List<ChatTheme> get proPresets =>
      presets.where((t) => t.isPro).toList();

  /// Looks up a preset by persisted id, falling back to [defaultTheme] for an
  /// id written by a newer build or a preset that has since been removed.
  static ChatTheme byId(String? id) {
    if (id == null) return defaultTheme;
    for (final t in presets) {
      if (t.id == id) return t;
    }
    return defaultTheme;
  }
}
