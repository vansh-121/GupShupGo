import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_chat_app/services/home_prompt_preferences.dart';

void main() {
  final now = DateTime.utc(2026, 10, 21);
  late HomePromptPreferences budget;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    budget = HomePromptPreferences(await SharedPreferences.getInstance());
  });

  test('first visit may ask; dismissal survives a fresh preferences wrapper',
      () async {
    await budget.recordVisit();
    expect(budget.canAskNotifications(now), isTrue);
    await budget.deferNotifications(now);
    budget = HomePromptPreferences(await SharedPreferences.getInstance());
    expect(budget.canAskNotifications(now), isFalse);
  });

  test('five visits alone cannot bypass the seven-day cooldown', () async {
    await budget.deferNotifications(now);
    for (var i = 0; i < 5; i++) {
      await budget.recordVisit();
    }
    expect(
        budget.canAskNotifications(now.add(const Duration(days: 6, hours: 23))),
        isFalse);
    expect(
        budget.canAskNotifications(now.add(const Duration(days: 7))), isTrue);
  });

  test('seven days alone cannot bypass the five-visit cooldown', () async {
    await budget.deferNotifications(now);
    for (var i = 0; i < 4; i++) {
      await budget.recordVisit();
    }
    expect(
        budget.canAskNotifications(now.add(const Duration(days: 30))), isFalse);
    await budget.recordVisit();
    expect(
        budget.canAskNotifications(now.add(const Duration(days: 30))), isTrue);
    await budget.deferNotifications(now.add(const Duration(days: 30)));
    expect(
        budget.canAskNotifications(now.add(const Duration(days: 31))), isFalse);
  });

  test('clock rollback keeps the prompt suppressed', () async {
    await budget.deferNotifications(now);
    for (var i = 0; i < 5; i++) {
      await budget.recordVisit();
    }
    expect(budget.canAskNotifications(now.subtract(const Duration(days: 1))),
        isFalse);
  });

  test('invite prompt is consumed once and survives reconstruction', () async {
    expect(budget.hasShownInvite, isFalse);
    await budget.markInviteShown();
    expect(
        HomePromptPreferences(await SharedPreferences.getInstance())
            .hasShownInvite,
        isTrue);
  });

  for (final legacyKey in [
    'invite_prompt_shown_v1',
    'has_shown_enjoying_gupshupgo'
  ]) {
    test('upgrades preserve invite budget from $legacyKey', () async {
      SharedPreferences.setMockInitialValues({legacyKey: true});
      final old = HomePromptPreferences(await SharedPreferences.getInstance());
      expect(old.hasShownInvite, isTrue);
    });
  }
}
