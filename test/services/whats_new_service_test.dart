// The rules the "NEW" dot has to follow.
//
// [WhatsNewService] is a thin wrapper over SharedPreferences, so what is worth
// pinning is the behaviour rather than the storage:
//
//   • A first install shows nothing. This is the case that would embarrass us in
//     production: every new user lighting up with badges for features that are,
//     to them, simply the app. It is decided once at bootstrap and is impossible
//     to observe later, so it is asserted here rather than trusted.
//   • An existing user who updates does get badges — the whole point.
//   • The cascade is driven by the anchor registry, so a container dot clears
//     exactly when the last unseen feature behind it is visited, and not before.
//   • A badge retires after three weeks untouched, because a permanent dot
//     teaches the user to ignore the next one.
//   • Bootstrap is idempotent: it runs on every launch and must not re-stamp a
//     countdown or resurrect something already seen.
//
// The `sharedPrefs` harness matches test/provider/chat_theme_provider_test.dart:
// the global is a `late final` assigned once at startup, so it is assigned once
// here too and isolation comes from clear() rather than a fresh instance.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_chat_app/main.dart' show sharedPrefs;
import 'package:video_chat_app/services/whats_new_service.dart';

/// Written by `maybeShowWhatsNew`. Its presence is what marks a device as having
/// run an earlier build, which is how bootstrap tells an update from a first
/// install. Duplicated as a literal on purpose: if the production constant is
/// ever renamed, this test should fail rather than silently agree with itself.
const _whatsNewVersionKey = 'pref_whats_new_version';

const _seenPrefix = 'pref_newfeat_seen_';
const _sincePrefix = 'pref_newfeat_since_';

/// Puts the store in the state an existing 1.1.6 user's device would be in.
Future<void> _asUpdatingUser() async {
  await sharedPrefs.setString(_whatsNewVersionKey, '1.1.6');
}

/// Backdates a feature's countdown by [days], as though it had been advertised
/// that long ago without ever being tapped.
Future<void> _age(String featureId, int days) async {
  await sharedPrefs.setInt(
    _sincePrefix + featureId,
    DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch,
  );
}

void main() {
  final service = WhatsNewService.instance;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    sharedPrefs = await SharedPreferences.getInstance();
  });

  setUp(() async {
    await sharedPrefs.clear();
  });

  group('a first install', () {
    // Nothing is "new" to someone who has never seen an older build, so the app
    // must open with no badges anywhere at all.
    test('shows no badge for any feature', () {
      WhatsNewService.bootstrap();

      for (final id in WhatsNewService.registeredIds) {
        expect(service.isNew(id), isFalse, reason: '$id should not be new');
      }
    });

    test('shows no dot on any anchor', () {
      WhatsNewService.bootstrap();

      expect(service.hasUnseenAt(NewFeatureAnchor.homeOverflow), isFalse);
      expect(service.hasUnseenAt(NewFeatureAnchor.settingsMenuItem), isFalse);
      expect(service.hasUnseenAt(NewFeatureAnchor.settingsAppearance), isFalse);
      expect(service.hasUnseenAt(NewFeatureAnchor.chatOverflow), isFalse);
    });

    // The suppression must survive the changelog dialog writing its version key
    // moments later — otherwise the second launch would look like an update and
    // badge a user who has never seen an older build.
    test('stays suppressed on later launches', () async {
      WhatsNewService.bootstrap();
      await sharedPrefs.setString(_whatsNewVersionKey, '1.1.7');

      WhatsNewService.bootstrap();

      expect(service.isNew(NewFeature.chatThemes), isFalse);
      expect(service.isNew(NewFeature.chatExport), isFalse);
    });
  });

  group('a user updating from an older build', () {
    setUp(() async {
      await _asUpdatingUser();
      WhatsNewService.bootstrap();
    });

    test('sees a badge on both new features', () {
      expect(service.isNew(NewFeature.chatThemes), isTrue);
      expect(service.isNew(NewFeature.chatExport), isTrue);
    });

    test('sees a dot on every anchor those features are reachable through', () {
      expect(service.hasUnseenAt(NewFeatureAnchor.homeOverflow), isTrue);
      expect(service.hasUnseenAt(NewFeatureAnchor.settingsMenuItem), isTrue);
      expect(service.hasUnseenAt(NewFeatureAnchor.settingsAppearance), isTrue);
      expect(service.hasUnseenAt(NewFeatureAnchor.chatOverflow), isTrue);
    });

    test('every unseen feature has its countdown started', () {
      for (final id in WhatsNewService.registeredIds) {
        expect(sharedPrefs.getInt(_sincePrefix + id), isNotNull);
      }
    });
  });

  group('visiting a feature', () {
    setUp(() async {
      await _asUpdatingUser();
      WhatsNewService.bootstrap();
    });

    test('clears that feature and leaves the other alone', () async {
      await service.markSeen(NewFeature.chatThemes);

      expect(service.isNew(NewFeature.chatThemes), isFalse);
      expect(service.isNew(NewFeature.chatExport), isTrue);
    });

    // The cascade's whole point: a dot on a container answers for everything
    // behind it, so it clears only once the last of them is visited.
    test('clears an anchor it was the only feature behind', () async {
      await service.markSeen(NewFeature.chatThemes);

      expect(service.hasUnseenAt(NewFeatureAnchor.settingsAppearance), isFalse);
      expect(service.hasUnseenAt(NewFeatureAnchor.homeOverflow), isFalse);
    });

    test('leaves a shared anchor lit while the other feature is unseen',
        () async {
      await service.markSeen(NewFeature.chatThemes);

      // Export still lives behind the chat overflow menu.
      expect(service.hasUnseenAt(NewFeatureAnchor.chatOverflow), isTrue);

      await service.markSeen(NewFeature.chatExport);
      expect(service.hasUnseenAt(NewFeatureAnchor.chatOverflow), isFalse);
    });

    test('notifies listeners exactly once, and not again when already seen',
        () async {
      var notifications = 0;
      void listener() => notifications++;
      service.addListener(listener);
      addTearDown(() => service.removeListener(listener));

      await service.markSeen(NewFeature.chatExport);
      expect(notifications, 1);

      await service.markSeen(NewFeature.chatExport);
      expect(notifications, 1, reason: 'a no-op must not rebuild every badge');
    });

    test('survives a relaunch', () async {
      await service.markSeen(NewFeature.chatExport);

      WhatsNewService.bootstrap();

      expect(service.isNew(NewFeature.chatExport), isFalse);
      expect(service.isNew(NewFeature.chatThemes), isTrue);
    });
  });

  group('shelf life', () {
    setUp(() async {
      await _asUpdatingUser();
      WhatsNewService.bootstrap();
    });

    test('a badge is still shown at 20 days', () async {
      await _age(NewFeature.chatThemes, 20);
      expect(service.isNew(NewFeature.chatThemes), isTrue);
    });

    test('a badge retires at 22 days without ever being tapped', () async {
      await _age(NewFeature.chatThemes, 22);

      expect(service.isNew(NewFeature.chatThemes), isFalse);
      expect(service.hasUnseenAt(NewFeatureAnchor.settingsAppearance), isFalse);
    });

    test('retiring one feature does not retire the other', () async {
      await _age(NewFeature.chatThemes, 22);

      expect(service.isNew(NewFeature.chatExport), isTrue);
      expect(service.hasUnseenAt(NewFeatureAnchor.chatOverflow), isTrue);
    });

    // A device whose clock jumps forward and back should not permanently retire
    // a badge it never showed; a negative age reads as "just stamped".
    test('a clock that moved backwards does not retire a badge', () async {
      await sharedPrefs.setInt(
        _sincePrefix + NewFeature.chatThemes,
        DateTime.now().add(const Duration(days: 5)).millisecondsSinceEpoch,
      );

      expect(service.isNew(NewFeature.chatThemes), isTrue);
    });
  });

  group('bootstrap', () {
    test('does not restart a countdown already in progress', () async {
      await _asUpdatingUser();
      WhatsNewService.bootstrap();
      await _age(NewFeature.chatThemes, 20);
      final stamped = sharedPrefs.getInt(_sincePrefix + NewFeature.chatThemes);

      WhatsNewService.bootstrap();

      expect(sharedPrefs.getInt(_sincePrefix + NewFeature.chatThemes), stamped,
          reason: 'a relaunch must not buy a badge another three weeks');
      expect(service.isNew(NewFeature.chatThemes), isTrue);
    });

    test('does not resurrect a feature already seen', () async {
      await _asUpdatingUser();
      WhatsNewService.bootstrap();
      await service.markSeen(NewFeature.chatThemes);

      WhatsNewService.bootstrap();
      WhatsNewService.bootstrap();

      expect(service.isNew(NewFeature.chatThemes), isFalse);
    });

    test('a feature added in a later release is stamped on the next launch',
        () async {
      await _asUpdatingUser();
      WhatsNewService.bootstrap();
      // Simulate a build where this id did not exist yet: its countdown was
      // never written, but the one-time bootstrap decision is already made.
      await sharedPrefs.remove(_sincePrefix + NewFeature.chatExport);

      WhatsNewService.bootstrap();

      expect(sharedPrefs.getInt(_sincePrefix + NewFeature.chatExport),
          isNotNull);
      expect(service.isNew(NewFeature.chatExport), isTrue);
    });

    // An unstamped, unseen feature errs towards being shown: the registry gained
    // an entry mid-session, and a missing badge is worse than an early one.
    test('an unstamped feature reads as new', () async {
      await sharedPrefs.setBool(_seenPrefix + NewFeature.chatThemes, false);

      expect(service.isNew(NewFeature.chatThemes), isTrue);
    });
  });
}
