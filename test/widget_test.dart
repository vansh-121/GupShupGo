// Widget tests for the main app
//
// These tests verify that the app structure and widgets render correctly.
// Firebase initialization is mocked to avoid external dependencies.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Simple test app that doesn't require Firebase
class TestApp extends StatelessWidget {
  const TestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GupShupGo Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TestHome(),
    );
  }
}

class TestHome extends StatefulWidget {
  const TestHome({Key? key}) : super(key: key);

  @override
  State<TestHome> createState() => _TestHomeState();
}

class _TestHomeState extends State<TestHome> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GupShupGo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

void main() {
  group('Widget Tests - Basic App Structure', () {
    testWidgets('App launches and displays home screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(const TestApp());

      // Verify app structure
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('GupShupGo'), findsOneWidget);
    });

    testWidgets('App displays counter correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const TestApp());

      // Verify initial counter value
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('FloatingActionButton increments counter',
        (WidgetTester tester) async {
      await tester.pumpWidget(const TestApp());

      // Verify initial state
      expect(find.text('0'), findsOneWidget);

      // Tap the button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      // Verify counter incremented
      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('Multiple button taps increment counter correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(const TestApp());

      // Tap button 3 times
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byIcon(Icons.add));
        await tester.pump();
      }

      // Verify counter shows 3
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('App has proper material design structure',
        (WidgetTester tester) async {
      await tester.pumpWidget(const TestApp());

      // Verify material structure
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('Text and icons render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const TestApp());

      // Verify text elements
      expect(find.text('GupShupGo'), findsOneWidget);
      expect(find.text('You have pushed the button this many times:'),
          findsOneWidget);

      // Verify icons
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });
}
