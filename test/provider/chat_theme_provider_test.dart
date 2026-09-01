// The rules a chat theme has to follow when a subscription is not in the room.
//
// [ChatThemeProvider] is a thin wrapper over SharedPreferences, so the parts
// worth pinning are the resolution rules rather than the storage:
//
//   • A per-chat pick beats the global default, and does not leak into any other
//     conversation. This is the whole reason the feature is per-chat.
//   • A Pro theme resolves to Default when `unlocked` is false, but the stored
//     id survives — a lapsed subscriber loses the look, not their choice.
//   • "Apply to all" genuinely applies to all, rather than being shadowed by
//     older per-chat overrides.
//   • A `custom` selection with no image behind it is treated as unset, because
//     rendering an empty background would look like a bug in the app.
//   • Every preset presents a light face in light mode and a dark one in dark
//     mode. That is asserted structurally rather than by eye, because the colours
//     are the feature and a stop copied from the wrong face is invisible in the
//     source and glaring on a phone.
//
// `resolve` takes `unlocked` as a parameter instead of reaching for
// SubscriptionProvider, which is what makes all of this testable with no widget
// tree, no Firebase and no billing client. Note it is *not* `isPro`: with
// `pro_enabled` off nobody is Pro and every preset is unlocked, so the two
// answers differ in the state production actually ships in.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_chat_app/main.dart' show sharedPrefs;
import 'package:video_chat_app/provider/chat_theme_provider.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/theme/chat_theme.dart';

const _roomA = 'alice_bob';
const _roomB = 'alice_carol';

ChatTheme _preset(String id) =>
    ChatThemeCatalog.presets.firstWhere((t) => t.id == id);

/// A free preset that is not the default, so "the override took effect" and
/// "nothing happened" are distinguishable.
final _slate = _preset('slate');

/// Any Pro preset; `ocean` also carries a gradient, so a downgrade that returned
/// the wrong object would be visible in more than the id.
final _ocean = _preset('ocean');

void main() {
  late ChatThemeProvider provider;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    // `sharedPrefs` is a `late final` global assigned once during app startup,
    // so it is assigned once here too; per-test isolation comes from clear()
    // below rather than from a fresh instance.
    sharedPrefs = await SharedPreferences.getInstance();
  });

  setUp(() async {
    await sharedPrefs.clear();
    provider = ChatThemeProvider();
  });

  group('a fresh install', () {
    test('every chat resolves to Default', () {
      expect(provider.resolve(null, unlocked: false).id, ChatThemeCatalog.defaultTheme.id);
      expect(provider.resolve(_roomA, unlocked: false).id, ChatThemeCatalog.defaultTheme.id);
      expect(provider.resolve(_roomA, unlocked: true).id, ChatThemeCatalog.defaultTheme.id);
    });

    test('Default follows the app light/dark palette rather than fixing one', () {
      // The sentinel property of the default preset: it declares no faces at
      // all, so an existing chat looks exactly as it did before chat themes
      // existed.
      expect(ChatThemeCatalog.defaultTheme.followsAppTheme, isTrue);
      expect(ChatThemeCatalog.defaultTheme.light, isNull);
      expect(ChatThemeCatalog.defaultTheme.dark, isNull);
      expect(ChatThemeCatalog.defaultTheme.sentBubble, isNull);
    });

    test('no chat reports an override', () {
      expect(provider.hasOverride(_roomA), isFalse);
    });
  });

  group('per-chat versus global', () {
    test('the global default applies to a chat with no override', () async {
      await provider.apply(null, _slate);

      expect(provider.resolve(_roomA, unlocked: false).id, 'slate');
    });

    test('a per-chat pick beats the global default', () async {
      await provider.apply(null, _slate);
      await provider.apply(_roomA, _ocean);

      expect(provider.resolve(_roomA, unlocked: true).id, 'ocean');
    });

    test('an override does not leak into another chat', () async {
      // The assertion the feature exists for. Keying the write wrongly — or
      // reading the global slot on the way out — would repaint every
      // conversation from one pick.
      await provider.apply(null, _slate);
      await provider.apply(_roomA, _ocean);

      expect(provider.resolve(_roomB, unlocked: true).id, 'slate');
      expect(provider.hasOverride(_roomA), isTrue);
      expect(provider.hasOverride(_roomB), isFalse);
    });

    test('clearing an override returns the chat to the global default', () async {
      await provider.apply(null, _slate);
      await provider.apply(_roomA, _ocean);
      await provider.clearOverride(_roomA);

      expect(provider.hasOverride(_roomA), isFalse);
      expect(provider.resolve(_roomA, unlocked: true).id, 'slate');
    });

    test('apply to all clears older per-chat picks instead of being shadowed',
        () async {
      // Without the sweep, "apply to all chats" would visibly do nothing in
      // exactly the conversations the user had already customised — the ones
      // they are most likely to check.
      await provider.apply(_roomA, _ocean);
      await provider.apply(_roomB, _ocean);

      await provider.applyToAll(_slate);

      expect(provider.resolve(_roomA, unlocked: true).id, 'slate');
      expect(provider.resolve(_roomB, unlocked: true).id, 'slate');
      expect(provider.hasOverride(_roomA), isFalse);
    });

    test('choices survive a new provider instance', () async {
      // Stands in for an app restart: the provider holds no state of its own,
      // so a rebuilt one must read the same answer back out of prefs.
      await provider.apply(_roomA, _slate);

      expect(ChatThemeProvider().resolve(_roomA, unlocked: false).id, 'slate');
    });
  });

  group('the Pro downgrade', () {
    test('a Pro theme resolves to Default for a free user', () async {
      await provider.apply(_roomA, _ocean);

      expect(provider.resolve(_roomA, unlocked: false).id,
          ChatThemeCatalog.defaultTheme.id);
    });

    test('every Pro preset downgrades, not just the one we tested', () async {
      for (final pro in ChatThemeCatalog.presets.where((t) => t.isPro)) {
        await provider.apply(_roomA, pro, imagePath: '/tmp/bg.jpg');

        expect(
          provider.resolve(_roomA, unlocked: false).id,
          ChatThemeCatalog.defaultTheme.id,
          reason: '${pro.id} should not survive a lapsed subscription',
        );
      }
    });

    test('the stored choice survives the downgrade', () async {
      // So resubscribing restores the look instead of silently having reset it
      // while the subscription was lapsed.
      await provider.apply(_roomA, _ocean);

      expect(provider.resolve(_roomA, unlocked: false).id, 'default');
      expect(provider.selectedId(_roomA), 'ocean');
      expect(provider.resolve(_roomA, unlocked: true).id, 'ocean');
    });

    test('a free theme is untouched by the Pro flag', () async {
      await provider.apply(_roomA, _slate);

      expect(provider.resolve(_roomA, unlocked: false).id, 'slate');
      expect(provider.resolve(_roomA, unlocked: true).id, 'slate');
    });

    test('the free tier matches the Premium screen copy exactly', () async {
      // The Premium card says "6 themes" free and "All 12 + your own photo" for
      // Pro. Adding a preset without deciding its tier would make that copy
      // false again, which is the bug this whole change was fixing — so the
      // counts are asserted, not just the ids.
      expect(
        ChatThemeCatalog.freePresets.map((t) => t.id),
        ['default', 'violet', 'midnight', 'slate', 'blush', 'mint'],
      );

      // "All 12" counts the fixed presets on both tiers; the gallery background
      // is the "+ your own photo" half of the sentence, so it is excluded here
      // and asserted to be Pro separately.
      final fixed = ChatThemeCatalog.presets
          .where((t) => t.id != ChatThemeCatalog.customId);
      expect(fixed, hasLength(12));
      expect(ChatThemeCatalog.custom.isPro, isTrue);
    });
  });

  group('the custom photo background', () {
    test('a photo pick is resolved with its path', () async {
      await provider.apply(_roomA, ChatThemeCatalog.custom,
          imagePath: '/data/app/documents/bg_a.jpg');

      final t = provider.resolve(_roomA, unlocked: true);

      expect(t.id, ChatThemeCatalog.customId);
      expect(t.imagePath, '/data/app/documents/bg_a.jpg');
      expect(t.hasImage, isTrue);
    });

    test('custom with no image behind it is treated as unset', () async {
      // Reachable: the sheet writes the id and the path in one call, but a
      // restored backup can carry the id with the file long gone. Rendering an
      // empty background would read as a broken app rather than an unset one.
      await provider.apply(_roomA, ChatThemeCatalog.custom);

      expect(provider.resolve(_roomA, unlocked: true).id,
          ChatThemeCatalog.defaultTheme.id);
    });

    test('a per-chat photo does not become the global one', () async {
      await provider.apply(null, ChatThemeCatalog.custom,
          imagePath: '/data/app/documents/global.jpg');
      await provider.apply(_roomA, ChatThemeCatalog.custom,
          imagePath: '/data/app/documents/room_a.jpg');

      expect(provider.resolve(_roomA, unlocked: true).imagePath,
          '/data/app/documents/room_a.jpg');
      // Room B inherits the global default, so it must get the global photo —
      // not room A's, and not nothing.
      expect(provider.resolve(_roomB, unlocked: true).imagePath,
          '/data/app/documents/global.jpg');
    });

    test('a chat inheriting the global custom theme reads the global photo',
        () async {
      await provider.apply(null, ChatThemeCatalog.custom,
          imagePath: '/data/app/documents/global.jpg');

      expect(provider.resolve(_roomA, unlocked: true).hasImage, isTrue);
    });
  });

  group('byId', () {
    test('an unknown id falls back to Default', () {
      // A preference written by a newer build, or pointing at a preset since
      // removed. Throwing or returning null here would break the chat screen on
      // a downgrade.
      expect(ChatThemeCatalog.byId('neon_from_a_future_build').id, 'default');
      expect(ChatThemeCatalog.byId(null).id, 'default');
      expect(ChatThemeCatalog.byId('').id, 'default');
    });

    test('every preset id round-trips', () {
      // Ids are the persistence format; renaming one silently resets every user
      // who had picked it.
      for (final preset in ChatThemeCatalog.presets) {
        expect(ChatThemeCatalog.byId(preset.id).id, preset.id);
      }
    });

    test('preset ids are unique', () {
      final ids = ChatThemeCatalog.presets.map((t) => t.id).toList();

      expect(ids.toSet(), hasLength(ids.length));
    });
  });

  group('bubble legibility', () {
    test('the app palette picks the face, not the preset', () {
      // The mechanism behind "dark mode shows dark themes": a preset no longer
      // fixes a brightness, so every colour getter reads the face matching the
      // palette it is handed. Nothing else in the app has to know.
      final light = AppThemeColors.forBrightness(Brightness.light);
      final dark = AppThemeColors.forBrightness(Brightness.dark);
      final indigo = _preset('midnight');

      expect(indigo.backgroundOf(light), indigo.light!.background);
      expect(indigo.backgroundOf(dark), indigo.dark!.background);
      expect(indigo.receivedOf(light), indigo.light!.receivedBubble);
      expect(indigo.receivedOf(dark), indigo.dark!.receivedBubble);

      // The sent fill is deliberately *not* per-face: it is the theme's identity
      // and clears the same white-text bar in either mode.
      expect(indigo.sentOf(light), indigo.sentOf(dark));

      // Default declares no faces, so it falls through to the app palette — a
      // different one per mode, which is what makes it "Default".
      const fallback = ChatThemeCatalog.defaultTheme;
      expect(fallback.backgroundOf(light), light.chatBg);
      expect(fallback.backgroundOf(dark), dark.chatBg);
      expect(light.chatBg, isNot(dark.chatBg));
    });

    test('a preset offers both faces or neither', () {
      // Half a pair is the failure mode this structure exists to prevent: a
      // preset with only a light face would fall back to the app's plain chat
      // surface in dark mode, so the picker would show it as a themed tile and
      // the chat would open untinted.
      for (final preset in ChatThemeCatalog.presets) {
        expect(
          preset.light == null,
          preset.dark == null,
          reason: '${preset.id} declares one face but not the other',
        );
        if (preset.followsAppTheme) {
          expect(preset.sentBubble, isNull,
              reason: '${preset.id} sets no faces, so it must follow the app '
                  'palette wholesale');
        }
      }
    });

    test('each face sits on the side of the light/dark line it is used on', () {
      // The assertion behind "dark mode shows dark themes". Bubble *text* colour
      // comes from the app palette, not the preset, so a light-ish fill on the
      // dark face draws near-white text onto a near-white bubble — and a dark
      // fill on the light face does the mirror image. Every surface the app
      // writes text over is checked: the field, its gradient stops, and the
      // received bubble.
      //
      // `estimateBrightnessForColor` returning `Brightness.dark` means "this
      // colour needs light text on it", which is what a dark face must be.
      for (final preset in ChatThemeCatalog.presets) {
        for (final (face, side) in [
          if (preset.light != null) (preset.light!, Brightness.light),
          if (preset.dark != null) (preset.dark!, Brightness.dark),
        ]) {
          final label = '${preset.id} ${side.name} face';
          for (final fill in [
            face.background,
            face.receivedBubble,
            ...?face.backgroundGradient,
          ]) {
            expect(
              ThemeData.estimateBrightnessForColor(fill),
              side,
              reason: '$label: '
                  '#${fill.toARGB32().toRadixString(16).padLeft(8, '0')} is on '
                  'the wrong side of the line (luminance '
                  '${fill.computeLuminance().toStringAsFixed(3)})',
            );
          }
        }
      }
    });

    test('every sent-bubble fill is dark enough for the white text on it', () {
      // The single assertion this file exists for. `_buildMessage` hardcodes
      // `Colors.white` on the sent bubble, so a preset is free to pick any hue
      // but not any *lightness* — and the tempting mid-tone of a vivid palette
      // (bright coral, mint, sky) lands near 3:1, which reads fine on a desk and
      // not at all outdoors. `estimateBrightnessForColor` is Flutter's own
      // 4.5:1-against-white test, so this is the same bar the framework uses.
      //
      // The fill is shared by both faces, which is only sound because this bar
      // does not move with the mode: white text needs the same contrast on a
      // pale field as on a deep one.
      //
      // Both the gradient stops and the flat fill are checked: the flat one is
      // the fallback for the picker preview and for any surface that takes a
      // single colour.
      for (final preset in ChatThemeCatalog.presets) {
        for (final fill in [
          if (preset.sentBubble != null) preset.sentBubble!,
          ...?preset.sentGradient,
        ]) {
          expect(
            ThemeData.estimateBrightnessForColor(fill),
            Brightness.dark,
            reason: '${preset.id}: '
                '#${fill.toARGB32().toRadixString(16).padLeft(8, '0')} is too light '
                'for white text (luminance ${fill.computeLuminance().toStringAsFixed(3)})',
          );
        }
      }
    });

    test('a gradient has both a fallback fill and enough stops to be one', () {
      // `sentGradientOf` returns null below two stops, which would silently drop
      // a one-stop "gradient" back to the flat colour — a preset that looks
      // right in the source and flat on screen. `decorationOf` does the same for
      // the background gradient, quietly leaving the flat colour behind.
      for (final preset in ChatThemeCatalog.presets) {
        final stops = preset.sentGradient;
        if (stops != null) {
          expect(stops.length, greaterThanOrEqualTo(2),
              reason: '${preset.id} would render flat');
          expect(preset.sentBubble, isNotNull,
              reason: '${preset.id} needs a single-colour fallback');
        }

        for (final (face, name) in [
          if (preset.light != null) (preset.light!, 'light'),
          if (preset.dark != null) (preset.dark!, 'dark'),
        ]) {
          final bg = face.backgroundGradient;
          if (bg == null) continue;
          expect(bg.length, greaterThanOrEqualTo(2),
              reason: '${preset.id} $name background would render flat');
        }
      }
    });

    test('a patterned preset stays in the band where it reads as texture', () {
      // Above ~9% the motifs stop being a surface and start being content the
      // eye tries to read behind the bubbles. Below ~4% they are invisible on a
      // dim screen and the preset is just a flat colour with extra painting.
      for (final preset in ChatThemeCatalog.presets) {
        if (preset.pattern == ChatPattern.none) continue;

        for (final (face, name) in [
          if (preset.light != null) (preset.light!, 'light'),
          if (preset.dark != null) (preset.dark!, 'dark'),
        ]) {
          expect(face.patternOpacity, inInclusiveRange(0.04, 0.09),
              reason: '${preset.id} $name pattern opacity is outside the '
                  'readable band');

          // At 6-8% alpha an ink close to its own field is not a quiet pattern,
          // it is no pattern — and the mode-specific ink is exactly the value
          // most likely to be copied from the other face and left there.
          final ink = face.patternColor;
          if (ink == null) continue;
          expect(
            (ink.computeLuminance() - face.background.computeLuminance()).abs(),
            greaterThan(0.15),
            reason: '${preset.id} $name pattern ink is too close to its '
                'background to show at ${face.patternOpacity}',
          );
        }
      }
    });

    test('the free and Pro lists partition the catalogue', () {
      // The picker renders these two lists and nothing else, so a preset in
      // neither — or in both — is either invisible or duplicated on screen.
      expect(
        ChatThemeCatalog.freePresets.length + ChatThemeCatalog.proPresets.length,
        ChatThemeCatalog.presets.length,
      );
      expect(
        ChatThemeCatalog.freePresets.map((t) => t.id).toSet().intersection(
            ChatThemeCatalog.proPresets.map((t) => t.id).toSet()),
        isEmpty,
      );
    });
  });
}
