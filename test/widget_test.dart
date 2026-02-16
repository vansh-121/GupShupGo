import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:video_chat_app/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify app launches
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
