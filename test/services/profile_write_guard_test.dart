// Guards the two rules that stop a sign-in from destroying an existing account.
//
// Both exist because of a real incident: a reinstall-and-sign-in wiped a user's
// @handle and zeroed their whole gamification history. The chain was three
// links, and each of these tests pins one end of it.
//
//   1. `UserService.getUserById` swallowed every read error and returned null,
//      so "the read failed" and "no such user" were the same answer.
//   2. Sign-in read that null as "new account" and built a fresh UserModel.
//   3. That model was written with `SetOptions(merge: true)`, which protects
//      only keys ABSENT from the payload — so `username: null` and
//      `gupPoints: 0` overwrote the real values.
//
// Neither rule can be tested through Firestore here (no fake_cloud_firestore in
// dev_dependencies), which is exactly why both were written to be testable
// without it: `toWritableMap` is pure, and `resolveExistingProfile` takes its
// reader, token refresh and delay as parameters.

import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/services/auth_service.dart';

/// What sign-in builds when it believes the account is new.
UserModel _freshModel() => UserModel(
      id: 'uid1',
      name: 'Vansh',
      email: 'v@example.com',
      isOnline: true,
      createdAt: DateTime(2026, 9, 4),
      authProvider: 'google',
    );

/// What a real, established account looks like.
UserModel _establishedModel() => UserModel(
      id: 'uid1',
      name: 'Vansh',
      username: 'vansh',
      email: 'v@example.com',
      about: 'hey there',
      fcmToken: 'token-abc',
      phoneNumber: '+911234567890',
      createdAt: DateTime(2025, 1, 1),
      authProvider: 'google',
      gupPoints: 4820,
      badges: const ['night_owl', 'streak_7'],
      challengeProgress: const {'daily_msgs': 12},
      completedChallenges: const ['first_call'],
      reactionsGiven: 91,
      nightMessages: 40,
      longestStreak: 23,
    );

void main() {
  group('UserModel.toWritableMap — cannot erase what it does not know', () {
    test('a fresh model carries no username, so it cannot erase a handle', () {
      final map = _freshModel().toWritableMap();

      // The single field whose loss the user actually noticed first.
      expect(map.containsKey('username'), isFalse);
      expect(map.containsKey('username_lowercase'), isFalse);
    });

    test('a fresh model carries no gamification fields, so it cannot zero them',
        () {
      final map = _freshModel().toWritableMap();

      // These are the ones a null-drop alone would miss: a fresh model has
      // `gupPoints: 0` and `badges: []`, which are not null and would sail
      // through merge and overwrite thousands of points.
      for (final field in UserModel.gamificationFields) {
        expect(map.containsKey(field), isFalse,
            reason: '$field must never ride along on a profile write');
      }
    });

    test('an established model also withholds gamification totals', () {
      // Not just the fresh case: a profile save writes back whatever totals its
      // model was READ with, which silently rolls back anything earned since.
      final map = _establishedModel().toWritableMap();

      for (final field in UserModel.gamificationFields) {
        expect(map.containsKey(field), isFalse);
      }
    });

    test('nulls are dropped but empty strings survive, so clearing still works',
        () {
      final cleared = _establishedModel().copyWith(about: '');
      final map = cleared.toWritableMap();

      // '' is how the profile screen clears a field, and it must reach Firestore.
      expect(map['about'], '');

      // Whereas a model that simply has no value for a field says nothing.
      expect(_freshModel().toWritableMap().containsKey('about'), isFalse);
    });

    test('presence and subscription fields stay withheld', () {
      final map = _establishedModel().toWritableMap();

      for (final field in [
        'isOnline',
        'lastSeen',
        'isDiscoverable',
        'subscriptionPlan',
        'subscriptionExpiresAt',
      ]) {
        expect(map.containsKey(field), isFalse);
      }
    });

    test('the fields a sign-in legitimately owns still get written', () {
      // The guard must not be so broad that sign-in stops working.
      final map = _freshModel().toWritableMap();

      expect(map['id'], 'uid1');
      expect(map['name'], 'Vansh');
      expect(map['email'], 'v@example.com');
      expect(map['authProvider'], 'google');
    });

    test('an established model still writes its own identity fields', () {
      final map = _establishedModel().toWritableMap();

      expect(map['username'], 'vansh');
      expect(map['username_lowercase'], 'vansh');
      expect(map['fcmToken'], 'token-abc');
      expect(map['phoneNumber'], '+911234567890');
    });
  });

  group('AuthService.resolveExistingProfile — a failed read is not "new"', () {
    // Injected so the retry backoff does not really sleep.
    Future<void> noDelay(Duration _) async {}

    test('returns the profile when the first read succeeds', () async {
      var reads = 0;
      final result = await AuthService.resolveExistingProfile(
        userId: 'uid1',
        read: () async {
          reads++;
          return _establishedModel();
        },
        delay: noDelay,
      );

      expect(result?.username, 'vansh');
      expect(reads, 1, reason: 'a successful read must not be repeated');
    });

    test('returns null for a genuinely missing document, without throwing',
        () async {
      // This is the real new-user path and it must stay fast and quiet.
      var reads = 0;
      final result = await AuthService.resolveExistingProfile(
        userId: 'uid1',
        read: () async {
          reads++;
          return null;
        },
        delay: noDelay,
      );

      expect(result, isNull);
      expect(reads, 1, reason: 'absence is an answer, not a failure to retry');
    });

    test('retries a failing read and returns the profile when it recovers',
        () async {
      // The reinstall case: the first read hits a rules context that does not
      // have the freshly minted token yet.
      var reads = 0;
      final result = await AuthService.resolveExistingProfile(
        userId: 'uid1',
        read: () async {
          reads++;
          if (reads < 3) throw Exception('permission-denied');
          return _establishedModel();
        },
        delay: noDelay,
      );

      expect(result?.gupPoints, 4820);
      expect(reads, 3);
    });

    test('throws rather than reporting a persistently unreadable profile as new',
        () async {
      // The whole point. Returning null here is what destroyed the account.
      await expectLater(
        AuthService.resolveExistingProfile(
          userId: 'uid1',
          read: () async => throw Exception('permission-denied'),
          delay: noDelay,
        ),
        throwsA(isA<ProfileReadException>()),
      );
    });

    test('the thrown error names the uid and keeps the underlying cause',
        () async {
      try {
        await AuthService.resolveExistingProfile(
          userId: 'uid-42',
          read: () async => throw Exception('permission-denied'),
          delay: noDelay,
        );
        fail('should have thrown');
      } on ProfileReadException catch (e) {
        expect(e.userId, 'uid-42');
        expect(e.cause.toString(), contains('permission-denied'));
      }
    });

    test('refreshes the auth token between attempts', () async {
      // Forcing a token refresh is the thing that actually clears a stale rules
      // context, so a retry that skips it would just fail three times.
      var refreshes = 0;
      var reads = 0;
      await AuthService.resolveExistingProfile(
        userId: 'uid1',
        read: () async {
          reads++;
          if (reads < 2) throw Exception('permission-denied');
          return _establishedModel();
        },
        refreshToken: () async => refreshes++,
        delay: noDelay,
      );

      expect(refreshes, 1);
    });

    test('does not refresh the token after the final attempt', () async {
      var refreshes = 0;
      await expectLater(
        AuthService.resolveExistingProfile(
          userId: 'uid1',
          read: () async => throw Exception('nope'),
          refreshToken: () async => refreshes++,
          delay: noDelay,
          attempts: 3,
        ),
        throwsA(isA<ProfileReadException>()),
      );

      expect(refreshes, 2, reason: 'refresh happens between attempts, not after');
    });

    test('a token refresh that itself fails does not abort the retry', () async {
      // getIdToken can fail on a flaky network, and treating that as fatal would
      // turn a recoverable read into a failed sign-in.
      var reads = 0;
      final result = await AuthService.resolveExistingProfile(
        userId: 'uid1',
        read: () async {
          reads++;
          if (reads < 2) throw Exception('permission-denied');
          return _establishedModel();
        },
        refreshToken: () async => throw Exception('token refresh failed'),
        delay: noDelay,
      );

      expect(result, isNotNull);
    });
  });
}
