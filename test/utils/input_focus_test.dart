import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/utils/input_focus.dart';

class _EntryForm extends StatefulWidget {
  const _EntryForm({required this.first, required this.second});

  final FocusNode first;
  final FocusNode second;

  @override
  State<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<_EntryForm> {
  @override
  void initState() {
    super.initState();
    unawaited(focusInputWhenReady(context, widget.first));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          TextField(key: const ValueKey('first'), focusNode: widget.first),
          TextField(key: const ValueKey('second'), focusNode: widget.second),
        ]),
      );
}

void main() {
  late FocusNode first;
  late FocusNode second;
  late GlobalKey<NavigatorState> navigator;

  setUp(() {
    first = FocusNode();
    second = FocusNode();
    navigator = GlobalKey<NavigatorState>();
  });
  tearDown(() {
    first.dispose();
    second.dispose();
  });

  Future<void> openForm(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigator,
      home: const Scaffold(body: Text('Home')),
    ));
    unawaited(navigator.currentState!.push<void>(MaterialPageRoute(
      builder: (_) => _EntryForm(first: first, second: second),
    )));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
  }

  testWidgets('automatic keyboard waits for the route entrance',
      (tester) async {
    await openForm(tester);
    expect(first.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);

    await tester.pumpAndSettle();
    expect(first.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a manual field choice wins over pending automatic focus',
      (tester) async {
    await openForm(tester);
    await tester.showKeyboard(find.byKey(const ValueKey('second')));
    await tester.pumpAndSettle();

    expect(second.hasFocus, isTrue);
    expect(first.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('a focused field can reopen a keyboard dismissed by Android Back',
      (tester) async {
    await openForm(tester);
    await tester.pumpAndSettle();
    tester.testTextInput.hide();
    expect(first.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isFalse);

    final request = focusInputWhenReady(
        tester.element(find.byKey(const ValueKey('first'))), first);
    await tester.pumpAndSettle();
    await request;
    expect(first.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('dismissing an entering form cannot reopen its keyboard',
      (tester) async {
    await openForm(tester);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();

    expect(first.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a covered form cannot take focus from a newer route',
      (tester) async {
    await openForm(tester);
    unawaited(navigator.currentState!.push<void>(MaterialPageRoute(
      builder: (_) => const Scaffold(body: Text('Other screen')),
    )));
    await tester.pumpAndSettle();

    expect(first.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(find.text('Other screen'), findsOneWidget);
  });
}
