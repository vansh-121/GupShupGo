// Renders the "NEW" badges to a PNG so their placement can be looked at.
//
// `whats_new_service_test.dart` proves the *rules* — who gets a badge, when it
// clears, when it retires. It cannot prove the badge sits in the right place on
// an app-bar icon, or that the dot's ring separates it from the glyph underneath
// on a dark app bar. Those are pixel questions, and the only honest way to
// answer them without a device build is to render the thing and look.
//
// Skipped by default, because a test that writes files on every suite run is a
// side effect nobody asked for, and because `--update-goldens` is not something
// a normal suite run should be handed. To generate the images:
//
//   $env:BADGE_SAMPLE = '1'                                   # PowerShell
//   fvm flutter test test/tool/new_feature_badge_sample_test.dart --update-goldens
//
// then open `build/new_feature_badge_light.png` / `_dark.png`. They land in
// `build/` rather than a committed goldens folder on purpose: a skipped test
// never compares them, so a checked-in copy would be a reference image
// masquerading as a guard. Run it after touching `new_feature_badge.dart` —
// every placement bug so far (a badge covering the top dot of `⋮`, a dot landing
// on the last letter of a heading) was invisible in the code and obvious here.
//
// Real Poppins faces are loaded through a FontLoader, because the test renderer
// otherwise draws every glyph as a filled box and the output would say nothing
// about how the badge reads next to text.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_chat_app/main.dart' show sharedPrefs;
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/widgets/new_feature_badge.dart';

final _run = Platform.environment['BADGE_SAMPLE'] == '1';

Future<void> _loadPoppins() async {
  // Two sets of family names, because two things ask for Poppins by different
  // names. The chrome in this file asks for 'Poppins' (the pubspec family), and
  // `GoogleFonts.poppins()` inside the badge widgets asks for its own
  // per-variant family — 'Poppins_regular', 'Poppins_700' and so on. Only the
  // second set matters for judging the "NEW" pill; the first keeps the
  // surrounding labels readable. google_fonts will still try, and fail, to fetch
  // over HTTP in a test — the pre-registered family is what it falls back onto,
  // so its complaint in the log is noise rather than a problem.
  const faces = <String, List<String>>{
    'Poppins-Regular': ['Poppins', 'Poppins_regular'],
    'Poppins-Medium': ['Poppins_500'],
    'Poppins-SemiBold': ['Poppins_600'],
    'Poppins-Bold': ['Poppins_700'],
    'Poppins-ExtraBold': ['Poppins_800'],
  };

  for (final entry in faces.entries) {
    final bytes = await rootBundle.load('assets/fonts/poppins/${entry.key}.ttf');
    for (final family in entry.value) {
      final loader = FontLoader(family)..addFont(Future.value(bytes));
      await loader.load();
    }
  }
}

/// Without this every `Icon` draws as an empty square, which is exactly the
/// detail that matters here: the dot has to tuck against the *glyph*, and
/// `Icons.more_vert` is a narrow column of dots sitting in the middle of a wide
/// box. Judging the tuck against the box instead of the glyph would be judging
/// the wrong thing.
Future<void> _loadMaterialIcons() async {
  final loader = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await loader.load();
}

/// A stand-in for the surfaces the badges actually land on: an app-bar icon, a
/// card heading, a settings tile and two overflow-menu rows.
Widget _showcase(Brightness brightness) {
  final theme = brightness == Brightness.dark ? AppTheme.dark : AppTheme.light;
  final c = AppThemeColors.forBrightness(brightness);

  Widget label(String text) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 6),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 9,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
            color: c.textMid,
          ),
        ),
      );

  // The chat ⋮ menu puts the pill straight after a bare label; the home ⋮ menu's
  // Settings row leads with an icon. Both shapes are worth looking at.
  Widget menuRow(String text, String featureId, {IconData? icon}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: c.textMid),
              const SizedBox(width: 12),
            ],
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: c.textHigh,
              ),
            ),
            NewFeatureChip(featureId: featureId),
          ],
        ),
      );

  // The real hosts: `Icons.more_vert` sits in an AppBar `actions` slot, whose
  // actionsIconTheme is 22 px, and the avatar is a radius-16 CircleAvatar.
  Widget overflowIcon() => IconTheme(
        data: IconThemeData(color: c.textHigh, size: 22),
        child: const NewFeatureDot(
          anchor: NewFeatureAnchor.chatOverflow,
          offset: NewFeatureDot.narrowGlyph,
          child: Icon(Icons.more_vert),
        ),
      );

  Widget overflowAvatar() => NewFeatureDot(
        anchor: NewFeatureAnchor.homeOverflow,
        child: CircleAvatar(
          radius: 16,
          backgroundColor: c.primaryLt,
          child: Icon(Icons.person, size: 18, color: c.primary),
        ),
      );

  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    home: Scaffold(
      backgroundColor: c.surface,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label('app bar — overflow icon and avatar'),
            Container(
              color: c.surface,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Text(
                    'Bob Sharma',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: c.textHigh,
                    ),
                  ),
                  const Spacer(),
                  overflowIcon(),
                  const SizedBox(width: 20),
                  overflowAvatar(),
                ],
              ),
            ),
            label('same two, magnified 5× — is the dot tucked or floating?'),
            Container(
              color: c.surface,
              padding: const EdgeInsets.only(top: 34, bottom: 22, left: 40),
              child: Row(
                children: [
                  Transform.scale(scale: 5, child: overflowIcon()),
                  const SizedBox(width: 130),
                  Transform.scale(scale: 5, child: overflowAvatar()),
                ],
              ),
            ),
            label('chat ⋮ menu rows'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: c.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  menuRow('Chat theme', NewFeature.chatThemes),
                  menuRow('Export chat', NewFeature.chatExport),
                ],
              ),
            ),
            label('home ⋮ menu — settings row'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: c.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  menuRow('Settings', NewFeature.chatThemes,
                      icon: Icons.settings_outlined),
                ],
              ),
            ),
            label('settings card heading + tile'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.surfaceAlt,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.border, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const NewFeatureDot(
                    anchor: NewFeatureAnchor.settingsAppearance,
                    offset: NewFeatureDot.besideText,
                    child: Text(
                      'Appearance',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(Icons.palette_outlined, color: c.textMid, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Chat theme',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  color: c.textHigh,
                                ),
                              ),
                            ),
                            const NewFeatureChip(
                                featureId: NewFeature.chatThemes),
                          ],
                        ),
                      ),
                      Text(
                        'Default',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: c.textMid,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_right_rounded,
                          color: c.textMid, size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    sharedPrefs = await SharedPreferences.getInstance();
    // Pose as a user who just updated, so every badge is showing.
    await sharedPrefs.setString('pref_whats_new_version', '1.1.6');
    await _loadPoppins();
    await _loadMaterialIcons();
  });

  for (final brightness in Brightness.values) {
    testWidgets('badges — ${brightness.name}', (tester) async {
      tester.view.physicalSize = const Size(760, 880);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_showcase(brightness));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../../build/new_feature_badge_${brightness.name}.png'),
      );
    }, skip: !_run);
  }
}
