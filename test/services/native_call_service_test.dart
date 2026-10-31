import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/l10n/app_localizations.dart';
import 'package:video_chat_app/screens/incoming_call_screen.dart';
import 'package:video_chat_app/services/native_call_service.dart';

void main() {
  testWidgets('foreground native ringing opens the full incoming call screen',
      (tester) async {
    final h = await _Harness.open(tester);
    h.ringing = _call;
    await h.nativeChanged();
    await h.settleRoute();
    expect(find.byType(IncomingCallScreen), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);

    await h.service.checkPending();
    await h.settleRoute();
    expect(h.observer.incomingRoutes, 1);
    await h.close();
  });

  testWidgets('in-app Accept replaces ringing with the existing call route',
      (tester) async {
    final h = await _Harness.open(tester);
    h.ringing = _call;
    await h.service.checkPending();
    await h.settleRoute();
    await tester.tap(find.byIcon(Icons.call).hitTestable());
    await h.settleRoute();
    expect(h.methods.where((m) => m == 'accept'), hasLength(1));
    expect(h.observer.activeRoutes, 1);
    expect(find.text('Active call'), findsOneWidget);
    expect(find.byType(IncomingCallScreen), findsNothing);
    expect(find.text('Active call'), findsOneWidget);
    expect(h.methods, isNot(contains('acknowledge')));

    await h.service.checkPending();
    await h.settleRoute();
    expect(h.observer.activeRoutes, 1);
    await h.close();
  });

  testWidgets('notification Accept replaces an already visible incoming screen',
      (tester) async {
    final h = await _Harness.open(tester);
    h.ringing = _call;
    await h.service.checkPending();
    await h.settleRoute();
    h.acceptFromNotification();
    await h.service.checkPending();
    await h.settleRoute();
    expect(find.byType(IncomingCallScreen), findsNothing);
    expect(find.text('Active call'), findsOneWidget);
    await h.service.checkPending();
    expect(h.observer.activeRoutes, 1);
    await h.close();
  });

  testWidgets('a background Accept waits for resume then opens once',
      (tester) async {
    final h = await _Harness.open(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    h.pending = _call;
    await h.service.checkPending();
    await tester.pump();
    expect(find.text('Active call'), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await h.service.checkPending();
    await h.settleRoute();
    expect(find.text('Active call'), findsOneWidget);
    expect(h.observer.activeRoutes, 1);
    await h.close();
  });

  testWidgets('a cold-start inbox retries when the navigator is not ready',
      (tester) async {
    final h = await _Harness.open(tester);
    h.navigatorReady = false;
    h.pending = _call;
    await h.service.checkPending();
    expect(find.text('Active call'), findsNothing);
    h.navigatorReady = true;
    await tester.pump(const Duration(seconds: 1));
    await h.settleRoute();
    expect(find.text('Active call'), findsOneWidget);
    await h.close();
  });

  testWidgets(
      'cancellation removes the incoming route without popping another screen',
      (tester) async {
    final h = await _Harness.open(tester);
    h.ringing = _call;
    await h.service.checkPending();
    await h.settleRoute();
    unawaited(h.navigator.currentState!.push(MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('Other screen')),
    )));
    await h.settleRoute();
    h.ringing = null;
    await h.service.checkPending();
    await h.settleRoute();
    expect(find.text('Other screen'), findsOneWidget);
    h.navigator.currentState!.pop();
    await h.settleRoute();
    expect(find.text('Home'), findsOneWidget);
    expect(find.byType(IncomingCallScreen), findsNothing);
    await h.close();
  });

  testWidgets('a pending call for a previous account cannot open media',
      (tester) async {
    final h = await _Harness.open(tester);
    h.uid = 'another-user';
    h.pending = _call;
    await h.service.checkPending();
    await h.settleRoute();
    expect(h.methods, contains('finish'));
    expect(find.text('Active call'), findsNothing);
    await h.close();
  });

  testWidgets('Accept above another route removes only the old incoming call',
      (tester) async {
    final h = await _Harness.open(tester);
    h.ringing = _call;
    await h.nativeChanged();
    await h.settleRoute();
    unawaited(h.navigator.currentState!.push(MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('Other screen')),
    )));
    await h.settleRoute();
    h.acceptFromNotification();
    await h.nativeChanged();
    await h.settleRoute();
    expect(find.text('Active call'), findsOneWidget);
    h.navigator.currentState!.pop();
    await h.settleRoute();
    expect(find.text('Other screen'), findsOneWidget);
    expect(find.byType(IncomingCallScreen), findsNothing);
    await h.close();
  });
}

const _call = <String, dynamic>{
  'channelId': 'call-test',
  'callerId': 'alice',
  'calleeId': 'bob',
  'callerName': 'Alice',
  'isAudioOnly': 'true',
  'deviceId': 'phone',
};

class _Harness {
  _Harness(this.tester);
  final WidgetTester tester;
  final navigator = GlobalKey<NavigatorState>();
  final observer = _Observer();
  final methods = <String>[];
  Map<String, dynamic>? pending;
  Map<String, dynamic>? ringing;
  String? uid = 'bob';
  bool navigatorReady = true;
  late final service = NativeCallService.forTest(
    currentUserId: () => uid,
    navigator: () => navigatorReady ? navigator.currentState : null,
    // Media startup is covered by CallAcceptance tests. Here we exercise the
    // actual native inbox, lifecycle and Navigator behavior without an RTC SDK.
    callBuilder: (_, __) => const Scaffold(body: Text('Active call')),
  );

  static Future<_Harness> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final h = _Harness(tester);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      NativeCallService.channel,
      h.handle,
    );
    addTearDown(() {
      h.service.stop();
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(NativeCallService.channel, null);
    });
    await tester.pumpWidget(MaterialApp(
      navigatorKey: h.navigator,
      navigatorObservers: [h.observer],
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: Text('Home')),
    ));
    await tester.pumpAndSettle();
    h.service.start();
    await tester.pump();
    return h;
  }

  void acceptFromNotification() {
    pending = ringing ?? _call;
    ringing = null;
  }

  Future<dynamic> handle(MethodCall call) async {
    methods.add(call.method);
    switch (call.method) {
      case 'pending':
        return pending;
      case 'ringing':
        return ringing;
      case 'accept':
        acceptFromNotification();
        return true;
      case 'decline':
        ringing = null;
        return null;
      case 'finish':
        pending = null;
        return null;
      default:
        return null;
    }
  }

  Future<void> nativeChanged() async {
    final handled = Completer<void>();
    // Simulate the actual native-to-Dart event, not another Dart invocation.
    // ignore: deprecated_member_use
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      NativeCallService.channel.name,
      const StandardMethodCodec()
          .encodeMethodCall(const MethodCall('stateChanged')),
      (_) => handled.complete(),
    );
    await handled.future;
  }

  Future<void> settleRoute() async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  Future<void> close() async {
    pending = null;
    ringing = null;
    service.stop();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }
}

class _Observer extends NavigatorObserver {
  int incomingRoutes = 0;
  int activeRoutes = 0;
  void count(Route<dynamic>? route) {
    if (route?.settings.name?.endsWith('/incoming') == true) incomingRoutes++;
    if (route?.settings.name?.endsWith('/active') == true) activeRoutes++;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      count(route);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      count(newRoute);
}
