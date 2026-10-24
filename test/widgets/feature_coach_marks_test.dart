import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_chat_app/main.dart' show sharedPrefs;
import 'package:video_chat_app/widgets/feature_coach_marks.dart';

void main() {
  testWidgets('large-text walkthrough keeps its CTA above the bottom inset',
      (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    sharedPrefs = await SharedPreferences.getInstance();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 480);
    tester.view.viewPadding = const FakeViewPadding(bottom: 24);
    addTearDown(tester.view.reset);
    final target = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
            builder: (context) => Center(
                    child: TextButton(
                  onPressed: () => showCoachMarks(context, [
                    CoachMark(
                      prefKey: 'test_coach',
                      targetKey: target,
                      icon: Icons.bolt,
                      title: 'These points are tappable',
                      body:
                          'Your points open the Arcade, where streaks with friends and daily challenges live. Learn about each reward and keep chatting with friends.',
                    )
                  ]),
                  child: const Text('Show tips'),
                ))),
        bottomNavigationBar: SafeArea(
            top: false,
            child: SizedBox(
              height: 60,
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                      key: target,
                      width: 80,
                      height: 40,
                      child: const Text('Points'))),
            )),
      ),
    ));
    await tester.tap(find.text('Show tips'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Got it'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getRect(find.text('Got it')).bottom, lessThanOrEqualTo(456));
    await tester.tap(find.text('Got it'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(sharedPrefs.getBool('test_coach'), isTrue);
    await tester.pumpWidget(const SizedBox());
  });
}
