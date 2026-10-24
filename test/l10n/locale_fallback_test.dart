import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/l10n/app_localizations.dart';

void main() {
  test('unsupported device languages fall back to English', () {
    final resolved = basicLocaleListResolution(
      const <Locale>[Locale('ko')],
      AppLocalizations.supportedLocales,
    );

    expect(resolved, const Locale('en'));
  });
}
