import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/provider/call_state_provider.dart';
import 'package:video_chat_app/services/ads/ads_service.dart';

class _InputModal extends StatefulWidget {
  const _InputModal();

  @override
  State<_InputModal> createState() => _InputModalState();
}

class _InputModalState extends State<_InputModal> {
  @override
  void initState() {
    super.initState();
    AdsService.instance.suppressBanner();
  }

  @override
  void dispose() {
    AdsService.instance.releaseBannerSuppression();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Dialog(child: Text('PIN entry'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final ads = AdsService.instance;

  test('nested input modals suppress native ads until both close', () {
    var notifications = 0;
    void onChange() => notifications++;
    ads.addListener(onChange);
    addTearDown(() {
      ads.releaseBannerSuppression();
      ads.releaseBannerSuppression();
      ads.removeListener(onChange);
    });

    ads.suppressBanner();
    ads.suppressBanner();
    expect(
        ads.canShowNative(hasProEntitlement: false, callState: CallState.Idle),
        isFalse);
    expect(
        ads.canShowNative(
            hasProEntitlement: false, callState: CallState.Idle, inChat: true),
        isFalse);
    expect(notifications, 1);

    ads.releaseBannerSuppression();
    expect(
        ads.canShowNative(hasProEntitlement: false, callState: CallState.Idle),
        isFalse);
    expect(notifications, 1);
    ads.releaseBannerSuppression();
    expect(notifications, 2);
  });

  testWidgets('dialog suppression updates ads after build', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    var notifications = 0;
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigator,
      home: Scaffold(
        body: ListenableBuilder(
          listenable: ads,
          builder: (_, __) {
            notifications++;
            return const Text('Ad placement');
          },
        ),
      ),
    ));
    final initial = notifications;

    final modal = showDialog<void>(
      context: tester.element(find.byType(Scaffold)),
      builder: (_) => const _InputModal(),
    );
    await tester.pumpAndSettle();
    expect(notifications, greaterThan(initial));
    expect(tester.takeException(), isNull);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    await modal;
    expect(tester.takeException(), isNull);
  });
}
