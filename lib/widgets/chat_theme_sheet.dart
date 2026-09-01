import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../provider/chat_theme_provider.dart';
import '../provider/subscription_provider.dart';
import '../services/image_compressor.dart';
import '../theme/app_theme.dart';
import '../theme/chat_pattern_painter.dart';
import '../theme/chat_theme.dart';
import 'premium_gate.dart';

/// Bottom sheet for picking a chat theme.
///
/// Two modes, distinguished by [chatRoomId]:
///   * non-null — sets the theme for one conversation.
///   * null — sets the global default (opened from Settings ▸ Appearance).
class ChatThemeSheet extends StatefulWidget {
  const ChatThemeSheet({super.key, this.chatRoomId, this.contactName});

  /// Chat to theme, or null for the global default.
  final String? chatRoomId;

  /// Shown in the subtitle so the user knows what they are changing.
  final String? contactName;

  static Future<void> show(
    BuildContext context, {
    String? chatRoomId,
    String? contactName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // The grid scrolls inside the sheet rather than the sheet growing to fit
      // it: thirteen presets is taller than a short phone, and a sheet that
      // fills the screen reads as a page that lost its app bar.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      builder: (_) => ChatThemeSheet(
        chatRoomId: chatRoomId,
        contactName: contactName,
      ),
    );
  }

  @override
  State<ChatThemeSheet> createState() => _ChatThemeSheetState();
}

class _ChatThemeSheetState extends State<ChatThemeSheet> {
  bool _busy = false;

  bool get _isGlobal => widget.chatRoomId == null;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final sub = context.watch<SubscriptionProvider>();
    final themes = context.watch<ChatThemeProvider>();
    final selectedId = themes.selectedId(widget.chatRoomId);

    // The photo behind a `custom` selection, so its tile previews the user's own
    // image instead of a generic placeholder. Read through `resolve` because
    // that is what knows which scope the path is stored under.
    final resolved =
        themes.resolve(widget.chatRoomId, unlocked: sub.isProUnlocked);
    final customPath =
        resolved.id == ChatThemeCatalog.customId ? resolved.imagePath : null;

    // With `pro_enabled` off the Pro programme is not live, so every preset is
    // simply available and the tier split is not drawn at all — a "Premium"
    // header over unlocked themes would be advertising something nobody can buy.
    // The split appears once Pro is live, where it is a distinction the user can
    // act on.
    final showTiers = sub.isProFeatureVisible;
    final unlocked = sub.isProUnlocked;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.textLow.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.palette_rounded,
                      size: 19,
                      color: c.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chat theme',
                          style: GoogleFonts.poppins(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: c.textHigh,
                          ),
                        ),
                        Text(
                          _isGlobal
                              ? 'Default for all chats'
                              : 'For your chat with ${widget.contactName ?? 'this contact'}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: c.textMid,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Sectioned grid ──────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Exactly three per row on any width, rather than a fixed
                    // tile size that leaves a ragged gap on wide screens.
                    const gap = 12.0;
                    final tileWidth = (constraints.maxWidth - gap * 2) / 3;

                    Widget grid(List<ChatTheme> list) => Wrap(
                          spacing: gap,
                          runSpacing: 14,
                          children: [
                            for (final theme in list)
                              _ThemeTile(
                                theme: theme,
                                appColors: c,
                                width: tileWidth,
                                selected: theme.id == selectedId,
                                locked: theme.isPro && !unlocked,
                                customPath: customPath,
                                onTap: () => _select(theme),
                              ),
                          ],
                        );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showTiers) ...[
                          _SectionLabel(text: 'Free', colors: c),
                          grid(ChatThemeCatalog.freePresets),
                          const SizedBox(height: 20),
                          _SectionLabel(
                            text: 'Premium',
                            colors: c,
                            showCrown: !unlocked,
                          ),
                          grid(ChatThemeCatalog.proPresets),
                        ] else
                          grid(ChatThemeCatalog.presets),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
              ),
            ),

            if (_busy)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.primary,
                  ),
                ),
              ),

            // ── Footer actions ──────────────────────────────────────
            if (!_isGlobal) ...[
              Divider(height: 20, thickness: 1, color: c.divider),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _FooterAction(
                      icon: Icons.done_all_rounded,
                      label: 'Apply this theme to all chats',
                      colors: c,
                      onTap: _busy ? null : _applyToAll,
                    ),
                    if (themes.hasOverride(widget.chatRoomId!))
                      _FooterAction(
                        icon: Icons.restart_alt_rounded,
                        label: 'Use my default theme',
                        colors: c,
                        onTap: _busy ? null : _clearOverride,
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _select(ChatTheme theme) async {
    final sub = context.read<SubscriptionProvider>();

    if (theme.isPro && !sub.isProUnlocked) {
      // Take the Navigator's own context before popping: this sheet's context is
      // deactivated by the pop, and the upgrade prompt needs a live one to open
      // its own route against.
      final navigator = Navigator.of(context);
      navigator.pop();
      await PremiumGate.showUpgradePrompt(
        navigator.context,
        featureName: 'Chat Themes',
        featureIcon: Icons.palette_rounded,
        description:
            'Unlock ${theme.name} and every other chat theme — plus set any '
            'photo from your gallery as a chat background.',
      );
      return;
    }

    final themes = context.read<ChatThemeProvider>();
    if (theme.id == ChatThemeCatalog.customId) {
      final path = await _pickBackgroundImage();
      if (path == null) return;
      await themes.apply(widget.chatRoomId, theme, imagePath: path);
    } else {
      await themes.apply(widget.chatRoomId, theme);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _clearOverride() async {
    final themes = context.read<ChatThemeProvider>();
    await themes.clearOverride(widget.chatRoomId!);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _applyToAll() async {
    final themes = context.read<ChatThemeProvider>();
    final sub = context.read<SubscriptionProvider>();
    final current =
        themes.resolve(widget.chatRoomId, unlocked: sub.isProUnlocked);

    // `resolve` strips the image path off a custom theme it can't back with a
    // file, so re-read the stored path rather than trusting the resolved object.
    await themes.applyToAll(
      ChatThemeCatalog.byId(current.id),
      imagePath: current.imagePath,
    );
    if (mounted) Navigator.pop(context);
  }

  /// Picks a gallery image, compresses it, and copies it somewhere durable.
  ///
  /// Returns the stored path, or null if the user cancelled.
  Future<String?> _pickBackgroundImage() async {
    setState(() => _busy = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (picked == null) return null;

      // Status settings rather than chat: a wallpaper is displayed full-screen,
      // so it needs the larger max edge.
      final compressed = await ImageCompressor.compressForStatus(
        File(picked.path),
        pro: true,
      );

      // Must be the documents directory, not temp. `ImagePicker` and the
      // compressor both hand back files in the cache dir, which Android is free
      // to purge at any time — the background would silently disappear.
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, 'chat_backgrounds'));
      if (!await dir.exists()) await dir.create(recursive: true);
      final dest = p.join(
        dir.path,
        'bg_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await compressed.copy(dest);
      return dest;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not set that image: $e')),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.text,
    required this.colors,
    this.showCrown = false,
  });

  final String text;
  final AppThemeColors colors;
  final bool showCrown;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: colors.textMid,
            ),
          ),
          if (showCrown) ...[
            const SizedBox(width: 7),
            const Icon(
              Icons.workspace_premium_rounded,
              size: 13,
              color: Color(0xFFD9A419),
            ),
          ],
        ],
      ),
    );
  }
}

/// One preset tile: a miniature conversation rendered in the theme's own
/// background, pattern and bubble colours.
///
/// The preview resolves the palette the same way `chat_screen` does — a preset
/// with a fixed [ChatTheme.brightness] previews against *that* palette, not the
/// app's — so the tile shows what the chat will actually look like rather than a
/// dark preset lit by the light theme.
class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.theme,
    required this.appColors,
    required this.width,
    required this.selected,
    required this.locked,
    required this.onTap,
    this.customPath,
  });

  final ChatTheme theme;

  /// The app palette, used for presets that follow the app theme.
  final AppThemeColors appColors;

  final double width;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  /// Stored photo for the `custom` preset, so its tile previews the real image.
  final String? customPath;

  @override
  Widget build(BuildContext context) {
    final c = theme.followsAppTheme
        ? appColors
        : AppThemeColors.forBrightness(theme.brightness!);

    final preview = theme.id == ChatThemeCatalog.customId && customPath != null
        ? theme.withImagePath(customPath)
        : theme;
    final decoration = preview.decorationOf(c);
    final sentGradient = theme.sentGradientOf(c);

    return SizedBox(
      width: width,
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: width * 0.92,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? appColors.primary : appColors.border,
                  width: selected ? 2.5 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: decoration ??
                        BoxDecoration(color: theme.backgroundOf(c)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (theme.pattern != ChatPattern.none &&
                            !preview.hasImage)
                          ChatPatternLayer(
                            pattern: theme.pattern,
                            ink: theme.patternInk(c),
                            // The tile is roughly a third of the phone's width,
                            // so the pattern is shrunk by about the same factor
                            // — otherwise a doodle preset would show one motif
                            // and preview as a flat colour.
                            scale: 0.42,
                          ),
                        Padding(
                          padding: const EdgeInsets.all(9),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _bubble(
                                color: theme.receivedOf(c),
                                widthFactor: 0.62,
                                incoming: true,
                                borderColor:
                                    Colors.black.withOpacity(c.isDark ? 0 : 0.05),
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: _bubble(
                                  color: theme.sentOf(c),
                                  gradient: sentGradient,
                                  widthFactor: 0.78,
                                  incoming: false,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (theme.id == ChatThemeCatalog.customId &&
                      !preview.hasImage)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: appColors.surface.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 18,
                          color: appColors.primary,
                        ),
                      ),
                    ),
                  if (locked)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFC93C),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          size: 10,
                          color: Color(0xFF3D2C00),
                        ),
                      ),
                    ),
                  if (selected && !locked)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          color: appColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            theme.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? appColors.primary : appColors.textMid,
            ),
          ),
        ],
      ),
    );
  }

  /// A miniature bubble. Corner radii mirror the real ones in `_buildMessage`
  /// (one squared-off corner on the sender's side), which is most of what makes
  /// the tile read as a chat rather than as two coloured bars.
  Widget _bubble({
    required Color color,
    required double widthFactor,
    required bool incoming,
    Gradient? gradient,
    Color? borderColor,
  }) =>
      FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: 13,
          decoration: BoxDecoration(
            color: gradient == null ? color : null,
            gradient: gradient,
            border: borderColor == null ? null : Border.all(color: borderColor),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(6),
              topRight: const Radius.circular(6),
              bottomLeft: Radius.circular(incoming ? 2 : 6),
              bottomRight: Radius.circular(incoming ? 6 : 2),
            ),
          ),
        ),
      );
}

class _FooterAction extends StatelessWidget {
  const _FooterAction({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final AppThemeColors colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 19, color: colors.primary),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: colors.textHigh,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
