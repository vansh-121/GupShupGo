import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
// local_auth's platform contract is used only to simulate scanner responses.
// ignore: depend_on_referenced_packages
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';
import 'package:video_chat_app/l10n/app_localizations.dart';
import 'package:video_chat_app/widgets/pin_keyboard_toggle.dart';
import 'package:video_chat_app/widgets/vault_pin_dialog.dart';

class _Biometrics extends LocalAuthPlatform {
  bool supported = false;
  Completer<bool>? capability;
  Completer<bool>? authentication;
  int attempts = 0;

  @override
  Future<bool> deviceSupportsBiometrics() =>
      capability?.future ?? Future.value(supported);

  @override
  Future<bool> isDeviceSupported() async => supported;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    required Iterable<AuthMessages> authMessages,
    AuthenticationOptions options = const AuthenticationOptions(),
  }) {
    attempts++;
    return (authentication ??= Completer<bool>()).future;
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const storage = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  late LocalAuthPlatform originalBiometrics;
  late _Biometrics biometrics;
  String? storedPin;

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() {
    originalBiometrics = LocalAuthPlatform.instance;
    biometrics = _Biometrics();
    LocalAuthPlatform.instance = biometrics;
    storedPin = null;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
        storage, (call) async => call.method == 'read' ? storedPin : null);
  });
  tearDown(() {
    LocalAuthPlatform.instance = originalBiometrics;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(storage, null);
  });

  Future<void> openVault(WidgetTester tester, VaultPinMode mode) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 850);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Text('Home')),
    ));
    unawaited(VaultPinDialog.show(
      context: tester.element(find.byType(Scaffold)),
      uid: 'keyboard-test',
      mode: mode,
      numericPinHint: true,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
  }

  testWidgets('setup opens the number pad after the dialog settles',
      (tester) async {
    // Creating a PIN must not wait for a slow hardware capability query.
    biometrics.capability = Completer<bool>();
    await openVault(tester, VaultPinMode.setup);
    expect(tester.testTextInput.isVisible, isFalse);
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.focusNode!.hasFocus, isTrue);
    expect(field.keyboardType, TextInputType.number);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(biometrics.attempts, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PIN unlock automatically opens without biometric support',
      (tester) async {
    await openVault(tester, VaultPinMode.unlock);
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);

    final field = tester.widget<TextField>(find.byType(TextField));
    for (final inset in [40, 100, 180, 260, 320, 260, 160, 60, 0]) {
      tester.view.viewInsets = FakeViewPadding(bottom: inset.toDouble());
      await tester.pump(const Duration(milliseconds: 16));
      expect(field.focusNode!.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('fingerprint gets focus first and cancellation opens the PIN',
      (tester) async {
    biometrics.supported = true;
    storedPin = '123456';
    await openVault(tester, VaultPinMode.unlock);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump();

    expect(biometrics.attempts, 1);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(
        tester.testTextInput.log
            .where((call) => call.method == 'TextInput.show'),
        isEmpty);

    biometrics.authentication!.complete(false);
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);
    expect(tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a delayed biometric check does not interrupt PIN typing',
      (tester) async {
    biometrics.supported = true;
    biometrics.capability = Completer<bool>();
    storedPin = '123456';
    await openVault(tester, VaultPinMode.unlock);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123');
    biometrics.capability!.complete(true);
    await tester.pumpAndSettle();

    expect(biometrics.attempts, 0);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '123');
  });

  testWidgets('invalid setup PIN returns focus to the field needing correction',
      (tester) async {
    await openVault(tester, VaultPinMode.setup);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '123');
    await tester.enterText(find.byType(TextField).last, '123');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextField>(find.byType(TextField).first)
            .focusNode!
            .hasFocus,
        isTrue);
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.enterText(find.byType(TextField).last, '654321');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextField>(find.byType(TextField).last)
            .focusNode!
            .hasFocus,
        isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PIN keyboard mode and Next keep the IME open', (tester) async {
    await openVault(tester, VaultPinMode.setup);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '123456');
    final before = tester.widget<TextField>(find.byType(TextField).first);
    final selection = before.controller!.selection;
    tester.testTextInput.log.clear();

    await tester.tap(find.descendant(
        of: find.byType(PinKeyboardToggle),
        matching: find.byWidgetPredicate((widget) => widget is TextButton)));
    await tester.pumpAndSettle();

    final after = tester.widget<TextField>(find.byType(TextField).first);
    expect(after.keyboardType, TextInputType.visiblePassword);
    expect(after.focusNode!.hasFocus, isTrue);
    expect(after.controller!.selection, selection);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(
      tester.testTextInput.log.where((call) =>
          call.method == 'TextInput.hide' ||
          call.method == 'TextInput.clearClient'),
      isEmpty,
    );

    tester.testTextInput.log.clear();
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(
        tester
            .widget<TextField>(find.byType(TextField).last)
            .focusNode!
            .hasFocus,
        isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(
        tester.testTextInput.log
            .where((call) => call.method == 'TextInput.hide'),
        isEmpty);
  });
}
