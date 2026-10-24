import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/l10n/app_localizations.dart';
import 'package:video_chat_app/widgets/attachment_sheet.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final size in [const Size(360, 640), const Size(640, 360)]) {
    testWidgets(
        'View Once remains reachable on $size with keyboard and nav bar',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.view.viewPadding = const FakeViewPadding(bottom: 24);
      tester.view.viewInsets = const FakeViewPadding(bottom: 120);
      addTearDown(tester.view.reset);
      var selected = false;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                      onPressed: () => showAttachmentSheet(
                        context: context,
                        actions: [
                          for (final kind in AttachmentKind.values)
                            AttachmentAction(
                                kind: kind,
                                onTap: (viewOnce) => selected = viewOnce)
                        ],
                        viewOnce: const AttachmentViewOnce(
                            subtitleOff: 'Send normally',
                            subtitleOn: 'Open once'),
                      ),
                      child: const Text('Attach'),
                    ))),
      ));
      await tester.tap(find.text('Attach'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      final toggleRect = tester.getRect(find.byType(SwitchListTile));
      expect(toggleRect.bottom, lessThanOrEqualTo(size.height - 120));
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      await tester.ensureVisible(find.text('Photo'));
      await tester.tap(find.text('Photo'));
      await tester.pumpAndSettle();
      expect(selected, isTrue);
      expect(find.byType(SwitchListTile), findsNothing);
    });
  }
}
