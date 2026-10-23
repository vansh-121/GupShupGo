import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/l10n/app_localizations.dart';
import 'package:video_chat_app/widgets/invite_share_sheet.dart';

void main() {
  testWidgets('share image passes a painted PNG and image MIME to the platform',
      (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.reset);
    final temporaryDirectory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('gup_invite_widget_')))!;
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        pathChannel, (_) async => temporaryDirectory.path);
    Map<dynamic, dynamic>? payload;
    messenger.setMockMethodCallHandler(shareChannel, (call) async {
      expect(call.method, 'shareFiles');
      payload = call.arguments as Map<dynamic, dynamic>;
      return 'com.whatsapp';
    });
    addTearDown(() async {
      messenger.setMockMethodCallHandler(pathChannel, null);
      messenger.setMockMethodCallHandler(shareChannel, null);
      await temporaryDirectory.delete(recursive: true);
    });
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
          body: Builder(
              builder: (context) => TextButton(
                    onPressed: () =>
                        showInviteShareSheet(context, handle: 'alice_123'),
                    child: const Text('Invite'),
                  ))),
    ));
    await tester.tap(find.text('Invite'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final shareButton = find.text('Share image');
    await tester.ensureVisible(shareButton);
    await tester.pumpAndSettle();
    await tester.tap(shareButton);
    await tester.pump();
    for (var i = 0; payload == null && i < 100; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    await tester.pump();
    expect(payload, isNotNull);
    expect(payload!['mimeTypes'], ['image/png']);
    final file = File((payload!['paths'] as List).single as String);
    expect(file.path.endsWith('.png'), isTrue);
    expect(file.path.startsWith(temporaryDirectory.path), isTrue);
    final bytes = await tester.runAsync(() => file.readAsBytes());
    expect(bytes!.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
    expect(payload!['text'], contains('https://gupshupgo.app/u/alice_123'));
    expect(payload!['originWidth'], greaterThan(0));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
