import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/services/profile_link_router.dart';

void main() {
  final link = Uri.parse('https://gupshupgo.app/u/alice_123');
  late List<String> opened;
  late DateTime now;
  late ProfileLinkRouter router;
  setUp(() {
    opened = [];
    now = DateTime.utc(2026, 10, 21);
    router = ProfileLinkRouter(
        now: () => now,
        openProfile: (handle) {
          opened.add(handle);
          return true;
        });
  });

  test('cold start queues until auth and onboarding finish', () {
    router.receive(link);
    expect(opened, isEmpty);
    expect(router.hasPendingLink, isTrue);
    router.setReady(true);
    expect(opened, ['alice_123']);
    expect(router.hasPendingLink, isFalse);
  });

  test('warm link opens directly and initial/stream duplicate opens once', () {
    router.setReady(true);
    router.receive(link);
    router.receive(link);
    expect(opened, ['alice_123']);
    now = now.add(const Duration(seconds: 3));
    router.receive(link);
    expect(opened, ['alice_123', 'alice_123']);
  });

  test('warm link after sign-out queues for the next authenticated Home', () {
    router.setReady(true);
    router.setReady(false);
    router.receive(link);
    expect(opened, isEmpty);
    router.setReady(true);
    expect(opened, ['alice_123']);
  });

  test('navigator or auth unavailability does not lose the pending link', () {
    var mounted = false;
    router = ProfileLinkRouter(openProfile: (_) => mounted);
    router.setReady(true);
    router.receive(link);
    expect(router.hasPendingLink, isTrue);
    mounted = true;
    router.setReady(true);
    expect(router.hasPendingLink, isFalse);
  });

  test('accepts canonical profiles and normalizes handle case', () {
    expect(ProfileLinkRouter.extractUsername(link), 'alice_123');
    expect(
        ProfileLinkRouter.extractUsername(
            Uri.parse('https://www.gupshupgo.app/u/alice_123')),
        'alice_123');
    expect(
        ProfileLinkRouter.extractUsername(
            Uri.parse('videocallapp://u/alice_123')),
        'alice_123');
    expect(
        ProfileLinkRouter.extractUsername(
            Uri.parse('videocallapp://gupshupgo.app/u/Alice_123')),
        'alice_123');
    expect(
        ProfileLinkRouter.extractUsername(
            Uri.parse('https://gupshupgo.app/u/Alice_123?source=qr')),
        'alice_123');
  });

  for (final bad in [
    'https://example.com/u/alice',
    'https://gupshupgo.app.evil.com/u/alice',
    'ftp://gupshupgo.app/u/alice',
    'https://gupshupgo.app/a/u/alice',
    'https://gupshupgo.app/u/alice/more',
    'https://gupshupgo.app/u/',
    'https://gupshupgo.app/u/ab',
    'https://gupshupgo.app/u/alice%2Fbob',
    'https://gupshupgo.app/u/%20alice',
    'https://user@gupshupgo.app/u/alice',
  ]) {
    test('rejects malformed/untrusted link $bad', () {
      expect(ProfileLinkRouter.extractUsername(Uri.parse(bad)), isNull);
    });
  }
}
