import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/utils/chat_scroll_controller.dart';

Widget _chatApp(ChatScrollController controller) {
  return MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: controller,
              reverse: true,
              itemExtent: 48,
              itemCount: 100,
              itemBuilder: (_, index) => Text('Message ${99 - index}'),
            ),
          ),
          SafeArea(
            top: false,
            child: TextField(onTap: controller.scrollToLatest),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('latest message stays above the opening and closing keyboard',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    tester.view.viewPadding = const FakeViewPadding(bottom: 24);
    addTearDown(tester.view.reset);
    final controller = ChatScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_chatApp(controller));
    await tester.tap(find.byType(TextField));
    await tester.pump();

    for (final inset in [0, 40, 80, 140, 200, 280, 200, 140, 80, 40, 0]) {
      tester.view.viewInsets = FakeViewPadding(bottom: inset.toDouble());
      await tester.pump(const Duration(milliseconds: 16));
      expect(controller.offset, 0);
      expect(controller.position.isScrollingNotifier.value, isFalse);
      expect(
        tester.getRect(find.text('Message 99')).bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(TextField)).top),
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('repeated requests during IME resize do not restart the scroll',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);
    final controller = ChatScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_chatApp(controller));
    controller.jumpTo(900);
    await tester.pump();
    controller.scrollToLatest();
    await tester.pump();

    for (var frame = 0; frame < 18; frame++) {
      tester.view.viewInsets = FakeViewPadding(bottom: frame * 14.0);
      // A tap, focus listener and viewport update can request the same target.
      controller.scrollToLatest();
      controller.scrollToLatest();
      controller.scrollToLatest();
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(controller.offset, closeTo(0, 1));
    expect(controller.position.isScrollingNotifier.value, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving chat safely cancels a pending scroll request',
      (tester) async {
    final controller = ChatScrollController();
    await tester.pumpWidget(_chatApp(controller));
    controller.jumpTo(500);
    await tester.pump();
    controller.scrollToLatest();
    controller.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('requests before attachment and after disposal are harmless',
      (tester) async {
    final controller = ChatScrollController();
    controller.scrollToLatest();
    await tester.pump();
    controller.dispose();
    controller.scrollToLatest();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
