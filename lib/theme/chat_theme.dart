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

/// One light-or-dark face of a [ChatTheme]: the parts that have to be re-tinted
/// when the app switches mode.
///
/// A theme's identity — its hue, its sent bubble, its pattern — is the same in
/// both modes. What cannot be shared is everything that has to sit *behind* text
/// the app palette chose: the field, and the received bubble drawn on it. In
/// light mode those must be pale enough for the app's near-black text; in dark
/// mode deep enough for its near-white text. One set of values cannot do both,
/// which is the whole reason this class exists.
///
/// [patternColor] is per-face for the same reason: the pale lilac that reads as
/// texture on a near-black field is invisible at 7% over a near-white one, so
/// each face names its own ink.
@immutable
class ChatFace {
  const ChatFace({
    required this.background,
    required this.receivedBubble,
    this.backgroundGradient,
    this.patternColor,
    this.patternOpacity = 0.06,
  });

  /// Flat background colour for the message area.
  ///
  /// Always set, even when [backgroundGradient] is, because the `Scaffold`
  /// behind the message list paints the flat colour: without it the area under
  /// the app bar and above the composer would fall back to the app palette and
  /// bracket the theme in two stripes of the wrong colour.
  final Color background;

  /// Fill for incoming bubbles. Must contrast with the app palette's text for
  /// this face's mode — asserted in `test/provider/chat_theme_provider_test.dart`.
  final Color receivedBubble;

  /// Optional vertical gradient, drawn instead of [background] behind the
  /// message list. Every stop has to sit on the same side of the light/dark line
  /// as [background].
  final List<Color>? backgroundGradient;

  /// Hue of the pattern overlay. `null` uses the palette's `textHigh`.
  final Color? patternColor;

  /// Alpha of the pattern overlay. Kept in the 0.04-0.09 band by every face:
  /// above that it competes with the bubbles instead of sitting behind them.
  final double patternOpacity;
}

/// A per-conversation chat appearance: message-area background plus bubble
/// colours, in a light and a dark face.
///
/// ## Why every preset has both faces
///
/// The presets originally fixed one [Brightness] each and the message list was
/// re-rooted on the matching [AppTheme], so a light preset stayed light inside a
/// dark app. That is defensible in isolation and looked wrong in practice: half
/// the picker glared in dark mode, and choosing a theme could invert the mode the
/// user had deliberately set for the rest of the app.
///
/// The obvious alternative — hide the presets that don't match the current mode —
/// is worse. It halves a catalogue that is already the thing users complained was
/// too small, and it makes themes *disappear* on toggling dark mode, including
/// the one currently applied.
///
/// So each preset carries a [light] and a [dark] face instead. All twelve are
/// offered in both modes, the chat area always agrees with the app's mode, and
/// flipping dark mode re-tints the current theme rather than replacing it.
///
/// ## Why bubble text colour still isn't stored here
///
/// Across `chat_screen`, `voice_message_bubble`, `reply_quote_card` and
/// `link_preview_card` the convention is already uniform and ~20 expressions
/// deep: sent bubbles draw white text, received bubbles draw
/// `AppThemeColors.textHigh / textMid / textLow`. Because a face is chosen *by*
/// the app's brightness, those resolve correctly on their own — no [Theme]
/// override around the message list, no colour threaded through every
/// constructor.
///
/// The contract each preset must honour (all of it asserted in
/// `test/provider/chat_theme_provider_test.dart`):
///   * [sentBubble] — and *every* stop of [sentGradient] — reads as
///     [Brightness.dark] to `ThemeData.estimateBrightnessForColor`, i.e. clears
///     4.5:1 against white. This is not a style preference: the sent-bubble
///     branch of `_buildMessage` hardcodes `Colors.white`, so a pale stop here
///     produces an unreadable message rather than a pale bubble. It is why the
///     vivid presets use deep saturated fills rather than the brighter mid-tones
///     the same palettes suggest — a bright coral or mint sits near 3:1 under
///     white, which is the level of "looks fine in the mockup, unreadable in
///     sunlight" this app should not ship. The fill is shared across both faces
///     precisely because this bar doesn't move with the mode.
///   * [light]'s background, gradient stops and received bubble are all light
///     enough for dark text; [dark]'s are all dark enough for light text.
///   * A preset either declares both faces or neither. Neither means "follow the
///     app palette wholesale" — see [defaultTheme] and [custom].
@immutable
class ChatTheme {
  const ChatTheme({
    required this.id,
    required this.name,
    this.isPro = false,
    this.light,
    this.dark,
    this.sentBubble,
    this.sentGradient,
    this.pattern = ChatPattern.none,
    this.imagePath,
  });

  /// Stable key persisted in SharedPreferences. Never rename an existing id —
  /// a saved preference pointing at an unknown id falls back to [defaultTheme].
  /// [name] is free to change; only the id is the contract.
  final String id;
  final String name;
  final bool isPro;

  /// Palette used while the app is in light mode, or `null` to inherit the app's
  /// own chat surface.
  final ChatFace? light;

  /// Palette used while the app is in dark mode. Null exactly when [light] is.
  final ChatFace? dark;

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

  final ChatPattern pattern;

  /// Absolute path to a user-chosen background photo (the `custom` preset).
  /// Lives in the app documents directory so it survives OS temp cleanup.
  final String? imagePath;

  /// True when this preset defers to the app's light/dark palette entirely.
  bool get followsAppTheme => light == null && dark == null;

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  ChatTheme withImagePath(String? path) => ChatTheme(
        id: id,
        name: name,
        isPro: isPro,
        light: light,
        dark: dark,
        sentBubble: sentBubble,
        sentGradient: sentGradient,
        pattern: pattern,
        imagePath: path,
      );

  /// The face matching the palette being drawn against, or `null` for a preset
  /// that follows the app theme.
  ///
  /// Taking the whole [AppThemeColors] rather than a [Brightness] is what keeps
  /// every call site below — and every caller in `chat_screen` and
  /// `chat_theme_sheet` — mode-aware without passing a second argument around.
  ChatFace? faceOf(AppThemeColors c) => c.isDark ? dark : light;

  Color backgroundOf(AppThemeColors c) => faceOf(c)?.background ?? c.chatBg;
  Color sentOf(AppThemeColors c) => sentBubble ?? c.sent;
  Color receivedOf(AppThemeColors c) =>
      faceOf(c)?.receivedBubble ?? c.received;

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
  Color patternInk(AppThemeColors c) {
    final face = faceOf(c);
    return (face?.patternColor ?? c.textHigh)
        .withOpacity(face?.patternOpacity ?? 0.06);
  }

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
    final gradient = faceOf(c)?.backgroundGradient;
    if (gradient != null && gradient.length > 1) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradient,
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
/// exactly one theme next to "Default". Six free presets, each with a light and a
/// dark face, make the picker worth opening on its own; the remaining six plus
/// the gallery background are what the subscription buys.
///
/// The free/Pro split is asserted in `test/provider/chat_theme_provider_test.dart`
/// against the counts printed on the Premium screen, so moving a preset between
/// tiers fails the build until that copy is updated too.
///
/// ## Naming
///
/// Every preset is named for a *hue*, never for a brightness, because each one
/// now appears in both modes: a preset called "Midnight" showing a pale field in
/// light mode is a small lie the catalogue can simply not tell. Two ids therefore
/// carry names that no longer match them — `midnight` renders as "Indigo" and
/// `amoled` as "Pure" — and the ids stay put so nobody's saved choice resets.
class ChatThemeCatalog {
  ChatThemeCatalog._();

  static const String customId = 'custom';

  // ── Free ────────────────────────────────────────────────────────────

  static const ChatTheme defaultTheme = ChatTheme(
    id: 'default',
    name: 'Default',
    // No faces at all: follows the app's light/dark theme, which is what every
    // existing chat looks like today. Deliberately un-patterned — this is the
    // baseline a user returns to, so it must stay identical to the app's own
    // chat surface.
  );

  static const ChatTheme _violet = ChatTheme(
    id: 'violet',
    name: 'Violet',
    light: ChatFace(
      background: Color(0xFFF4F2FE),
      receivedBubble: Color(0xFFFFFFFF),
      patternColor: Color(0xFF6C5CE7),
      patternOpacity: 0.07,
    ),
    dark: ChatFace(
      background: Color(0xFF14112A),
      backgroundGradient: [Color(0xFF1A1538), Color(0xFF0C0A1B)],
      receivedBubble: Color(0xFF221D40),
      patternColor: Color(0xFFA593FF),
      patternOpacity: 0.08,
    ),
    sentBubble: Color(0xFF6C5CE7),
    sentGradient: [Color(0xFF7355EE), Color(0xFF5138C4)],
    pattern: ChatPattern.dots,
  );

  /// Kept under the `midnight` id — renaming it would reset everyone already on
  /// it — but presented as "Indigo", because it now has a daylight face and
  /// "Midnight" would be describing only half of it.
  static const ChatTheme _indigo = ChatTheme(
    id: 'midnight',
    name: 'Indigo',
    light: ChatFace(
      background: Color(0xFFEEF1FC),
      backgroundGradient: [Color(0xFFE7ECFB), Color(0xFFF7F9FF)],
      receivedBubble: Color(0xFFFFFFFF),
      patternColor: Color(0xFF4B4FC4),
      patternOpacity: 0.07,
    ),
    dark: ChatFace(
      background: Color(0xFF0A0D18),
      backgroundGradient: [Color(0xFF11162A), Color(0xFF070911)],
      receivedBubble: Color(0xFF171B2B),
      patternColor: Color(0xFF9C8CFF),
      patternOpacity: 0.08,
    ),
    sentBubble: Color(0xFF5B4BE0),
    sentGradient: [Color(0xFF6656E8), Color(0xFF3B2FA8)],
    // Circles rather than Violet's dots: the two are neighbours on the colour
    // wheel, and with both now showing in both modes the pattern is what keeps
    // their tiles from reading as duplicates.
    pattern: ChatPattern.bubbles,
  );

  /// Kept under the `slate` id — it is the one preset that shipped, so anyone
  /// already on it inherits this rebuilt palette instead of being reset. The
  /// original was a flat grey-blue on grey and was the reason this whole pass
  /// happened.
  static const ChatTheme _graphite = ChatTheme(
    id: 'slate',
    name: 'Graphite',
    light: ChatFace(
      background: Color(0xFFEDF1F7),
      receivedBubble: Color(0xFFFFFFFF),
      patternColor: Color(0xFF475569),
      patternOpacity: 0.07,
    ),
    dark: ChatFace(
      // Pushed deeper than the other dark faces on purpose. Graphite's sent
      // bubble *is* a mid slate, so on a merely dark-grey field the two bubbles
      // would differ by a few percent of luminance and the conversation would
      // read as one continuous smudge. The shared fill can't be lightened — it
      // has to clear 4.5:1 against white on the light face too — so the field
      // moves instead.
      background: Color(0xFF0B0E12),
      backgroundGradient: [Color(0xFF12161B), Color(0xFF07090C)],
      receivedBubble: Color(0xFF171B22),
      patternColor: Color(0xFF94A3B8),
      patternOpacity: 0.07,
    ),
    sentBubble: Color(0xFF3E4C5E),
    sentGradient: [Color(0xFF4C5D72), Color(0xFF2B3644)],
    pattern: ChatPattern.dots,
  );

  static const ChatTheme _blush = ChatTheme(
    id: 'blush',
    name: 'Blush',
    light: ChatFace(
      background: Color(0xFFFDF2F7),
      receivedBubble: Color(0xFFFFFFFF),
      patternColor: Color(0xFFDB2777),
      patternOpacity: 0.07,
    ),
    dark: ChatFace(
      background: Color(0xFF1C0E17),
      backgroundGradient: [Color(0xFF2A1220), Color(0xFF120810)],
      receivedBubble: Color(0xFF2B1622),
      patternColor: Color(0xFFF9A8D4),
      patternOpacity: 0.07,
    ),
    sentBubble: Color(0xFFDB2777),
    sentGradient: [Color(0xFFD62575), Color(0xFF9D174D)],
    pattern: ChatPattern.bubbles,
  );

  /// A deep teal bubble on a pale mint field — the name describes the
  /// background, not the fill. A mid-tone mint bubble is the obvious reading of
  /// the name and sits around 2.5:1 under white text, so it is not an option
  /// here.
  ///
  /// The fill is cyan-teal rather than the green it used to be. Mint was the
  /// light green preset and [_emerald] the dark one, which was a real difference
  /// only while each existed in a single mode; with both faces present they were
  /// two near-identical tiles, one of them locked. Teal keeps Mint's pale field
  /// and gives it a hue of its own.
  static const ChatTheme _mint = ChatTheme(
    id: 'mint',
    name: 'Mint',
    light: ChatFace(
      background: Color(0xFFEFF8F5),
      receivedBubble: Color(0xFFFFFFFF),
      patternColor: Color(0xFF0E7692),
      patternOpacity: 0.06,
    ),
    dark: ChatFace(
      background: Color(0xFF07171C),
      backgroundGradient: [Color(0xFF0B2028), Color(0xFF041014)],
      receivedBubble: Color(0xFF0F2630),
      patternColor: Color(0xFF67E8F9),
      patternOpacity: 0.07,
    ),
    sentBubble: Color(0xFF0E7490),
    sentGradient: [Color(0xFF0E7692), Color(0xFF07485A)],
    pattern: ChatPattern.doodles,
  );

  // ── Pro ─────────────────────────────────────────────────────────────

  /// True black on an OLED panel, pure paper in light mode.
  ///
  /// Filed under the `amoled` id, but "AMOLED" only ever described the dark
  /// half. What both faces share is the absence of a tint — the display perk in
  /// dark mode, and the cleanest possible field in light mode — so it is
  /// presented as "Pure".
  static const ChatTheme _pure = ChatTheme(
    id: 'amoled',
    name: 'Pure',
    isPro: true,
    light: ChatFace(
      background: Color(0xFFFFFFFF),
      // A white bubble on a white field is invisible, and received bubbles carry
      // no border in `_buildMessage`, so this face is the one place the incoming
      // fill has to step away from pure white.
      receivedBubble: Color(0xFFF1F1F5),
    ),
    dark: ChatFace(
      background: Color(0xFF000000),
      receivedBubble: Color(0xFF0E0F14),
    ),
    sentBubble: Color(0xFF2F2568),
    sentGradient: [Color(0xFF3B2FA8), Color(0xFF201A50)],
    // No pattern: the entire point of the dark face is pixels that are genuinely
    // off on an OLED panel, and a 7% overlay would light every one of them.
  );

  static const ChatTheme _ocean = ChatTheme(
    id: 'ocean',
    name: 'Ocean',
    isPro: true,
    light: ChatFace(
      background: Color(0xFFEDF6FC),
      backgroundGradient: [Color(0xFFDDEEFA), Color(0xFFF6FBFE)],
      receivedBubble: Color(0xFFFFFFFF),
      patternColor: Color(0xFF1C769F),
      patternOpacity: 0.07,
    ),
    dark: ChatFace(
      background: Color(0xFF07243A),
      backgroundGradient: [Color(0xFF0B3350), Color(0xFF04141F)],
      receivedBubble: Color(0xFF0E3350),
      patternColor: Color(0xFF7FD4FF),
      patternOpacity: 0.06,
    ),
    sentBubble: Color(0xFF14618F),
    sentGradient: [Color(0xFF1C769F), Color(0xFF0B3F5E)],
    pattern: ChatPattern.bubbles,
  );

  static const ChatTheme _sunset = ChatTheme(
    id: 'sunset',
    name: 'Sunset',
    isPro: true,
    light: ChatFace(
      background: Color(0xFFFFF3EA),
      backgroundGradient: [Color(0xFFFFE3CE), Color(0xFFFFF8F2)],
      receivedBubble: Color(0xFFFFFFFF),
      patternColor: Color(0xFFD2542E),
      patternOpacity: 0.08,
    ),
    dark: ChatFace(
      background: Color(0xFF1E0F0A),
      backgroundGradient: [Color(0xFF2E140C), Color(0xFF140807)],
      receivedBubble: Color(0xFF2C1710),
      patternColor: Color(0xFFFDBA74),
      patternOpacity: 0.07,
    ),
    sentBubble: Color(0xFFBE3820),
    sentGradient: [Color(0xFFC93E24), Color(0xFF97260F)],
    pattern: ChatPattern.doodles,
  );

  static const ChatTheme _emerald = ChatTheme(
    id: 'emerald',
    name: 'Emerald',
    isPro: true,
    light: ChatFace(
      background: Color(0xFFECF8F1),
      backgroundGradient: [Color(0xFFDFF3E7), Color(0xFFF6FCF8)],
      receivedBubble: Color(0xFFFFFFFF),
      patternColor: Color(0xFF047857),
      patternOpacity: 0.07,
    ),
    dark: ChatFace(
      background: Color(0xFF062420),
      backgroundGradient: [Color(0xFF093029), Color(0xFF03130F)],
      receivedBubble: Color(0xFF0C332B),
      patternColor: Color(0xFF34D399),
      patternOpacity: 0.06,
    ),
    sentBubble: Color(0xFF0A7550),
    sentGradient: [Color(0xFF0C8259), Color(0xFF045238)],
    // Dots rather than the doodles this used to share with [_mint], for the same
    // reason Mint moved to teal: the pair have to be told apart at tile size.
    pattern: ChatPattern.dots,
  );

  static const ChatTheme _nebula = ChatTheme(
    id: 'nebula',
    name: 'Nebula',
    isPro: true,
    light: ChatFace(
      background: Color(0xFFF6F1FE),
      backgroundGradient: [Color(0xFFEDE3FD), Color(0xFFFCFAFF)],
      receivedBubble: Color(0xFFFFFFFF),
      patternColor: Color(0xFF7C4DF0),
      patternOpacity: 0.07,
    ),
    dark: ChatFace(
      background: Color(0xFF120826),
      backgroundGradient: [Color(0xFF200D47), Color(0xFF090315)],
      receivedBubble: Color(0xFF221142),
      patternColor: Color(0xFFC4B5FD),
      patternOpacity: 0.08,
    ),
    sentBubble: Color(0xFF6D3BDE),
    sentGradient: [Color(0xFF7C4DF0), Color(0xFF4C1D95)],
    pattern: ChatPattern.bubbles,
  );

  static const ChatTheme _latte = ChatTheme(
    id: 'latte',
    name: 'Latte',
    isPro: true,
    light: ChatFace(
      background: Color(0xFFF8F2E9),
      receivedBubble: Color(0xFFFFFFFF),
      patternColor: Color(0xFF7A5C3E),
      patternOpacity: 0.08,
    ),
    dark: ChatFace(
      background: Color(0xFF17110C),
      backgroundGradient: [Color(0xFF201811), Color(0xFF0F0B08)],
      receivedBubble: Color(0xFF241B13),
      patternColor: Color(0xFFD6BFA3),
      patternOpacity: 0.07,
    ),
    sentBubble: Color(0xFF77593C),
    sentGradient: [Color(0xFF876848), Color(0xFF57402A)],
    pattern: ChatPattern.dots,
  );

  /// Photo background from the user's gallery. Bubbles stay on the app palette,
  /// so it reads correctly over both light and dark photos — and the wash in
  /// [ChatTheme.decorationOf] pulls the photo toward whichever `chatBg` the app
  /// is currently on, so this preset is mode-aware without declaring faces.
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
    _indigo,
    _graphite,
    _blush,
    _mint,
    _pure,
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
