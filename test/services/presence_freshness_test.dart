// Whether a user reads as "online" to everyone else.
//
// The bug this covers: a user showed as online with their phone locked, the app
// backgrounded, or the app killed. `isOnline` in Firestore is a *claim* — RTDB's
// `onDisconnect` is what's supposed to retract it, and in production it has been
// observed failing outright, leaving records stuck `online: true` for weeks. So
// the flag is never believed on its own; a live session must also prove itself
// with a recent `lastSeen` heartbeat.
//
// Two seams carry that rule, and both are asserted here without a Firestore
// connection:
//   • withFreshPresence — the rule itself, applied at the service boundary so
//     no screen can forget it.
//   • decayingPresence — the rule re-applied on a timer. This is the half that
//     is easy to get wrong: a Firestore document only re-emits when it is
//     *written*, so a session that dies leaves its last `isOnline: true`
//     snapshot as the newest thing the UI will ever receive. Without a tick of
//     its own, "Online" stays on screen forever no matter how correct the rule
//     is.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/services/presence_service.dart';
import 'package:video_chat_app/services/user_service.dart';

UserModel _user({required bool isOnline, DateTime? lastSeen}) => UserModel(
      id: 'u1',
      name: 'Test User',
      isOnline: isOnline,
      lastSeen: lastSeen,
    );

void main() {
  group('withFreshPresence', () {
    test('a heartbeat from moments ago keeps an online user online', () {
      // The ordinary case: app foregrounded, heartbeat every 25s. Anything
      // stricter here would make active users flicker offline between beats.
      final user = _user(isOnline: true, lastSeen: DateTime.now());

      expect(UserService.withFreshPresence(user).isOnline, isTrue);
    });

    test('a stale heartbeat overrides the flag', () {
      // The ghost record: three of these were found in production RTDB with
      // `online: true` and a lastSeen 19, 22 and 46 days old. `onDisconnect`
      // never fired for them, so nothing was ever going to retract the claim.
      final user = _user(
        isOnline: true,
        lastSeen: DateTime.now().subtract(const Duration(days: 22)),
      );

      expect(UserService.withFreshPresence(user).isOnline, isFalse);
    });

    test('a heartbeat just past the threshold is already too old', () {
      // Bounds the whole fix: this is the longest a dead session can keep
      // claiming to be online.
      final user = _user(
        isOnline: true,
        lastSeen: DateTime.now().subtract(
          PresenceService.staleThreshold + const Duration(seconds: 1),
        ),
      );

      expect(UserService.withFreshPresence(user).isOnline, isFalse);
    });

    test('no lastSeen at all is not evidence of a live session', () {
      // Reachable for accounts that predate the heartbeat, and for any doc
      // written without the field. Absence must not read as "just now".
      final user = _user(isOnline: true, lastSeen: null);

      expect(UserService.withFreshPresence(user).isOnline, isFalse);
    });

    test('an offline user passes through untouched', () {
      // The rule only ever removes a claim; it must never manufacture one,
      // however recent the timestamp.
      final user = _user(isOnline: false, lastSeen: DateTime.now());
      final result = UserService.withFreshPresence(user);

      expect(result.isOnline, isFalse);
      expect(result, same(user), reason: 'no needless copy on the common path');
    });
  });

  group('decayingPresence', () {
    // Short enough to keep the suite fast, and the assertions below only
    // depend on the tick being well under the margin, not on its exact value.
    const tick = Duration(milliseconds: 20);

    test('decays to offline with no second event from upstream', () async {
      // The frozen chat-screen header, reproduced: one snapshot arrives saying
      // "online", the session then dies, and Firestore never writes the doc
      // again. Only the ticker can move this off "Online".
      final source = StreamController<UserModel?>();
      final seen = <bool>[];

      final sub = UserService.decayingPresence(source.stream, tick: tick)
          .listen((u) => seen.add(u!.isOnline));

      // Fresh when it arrives, stale ~150ms later — the threshold crossing is
      // what the ticker has to notice on its own.
      source.add(_user(
        isOnline: true,
        lastSeen: DateTime.now().subtract(
          PresenceService.staleThreshold - const Duration(milliseconds: 150),
        ),
      ));

      await Future<void>.delayed(const Duration(milliseconds: 500));
      await sub.cancel();
      await source.close();

      expect(seen.first, isTrue, reason: 'was genuinely online on arrival');
      expect(seen.last, isFalse, reason: 'decayed with no new snapshot');
    });

    test('an unchanged verdict does not wake listeners on every tick', () async {
      // A rebuild of every presence-bearing widget several times a minute for
      // no state change would be a real cost — the tick must be silent unless
      // the verdict actually flips.
      final source = StreamController<UserModel?>();
      var emissions = 0;

      final sub = UserService.decayingPresence(source.stream, tick: tick)
          .listen((_) => emissions++);

      source.add(_user(isOnline: true, lastSeen: DateTime.now()));
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await sub.cancel();
      await source.close();

      expect(emissions, 1, reason: '~15 ticks passed, verdict never changed');
    });

    test('upstream events always pass through', () async {
      // The decay filter guards ticks only. A real write must reach the UI even
      // when it leaves the online/offline verdict where it was — it may carry a
      // new name, photo or about line.
      final source = StreamController<UserModel?>();
      final names = <String?>[];

      final sub = UserService.decayingPresence(source.stream, tick: tick)
          .listen((u) => names.add(u?.name));

      source.add(_user(isOnline: true, lastSeen: DateTime.now()));
      await Future<void>.delayed(Duration.zero);
      source.add(UserModel(
        id: 'u1',
        name: 'Renamed',
        isOnline: true,
        lastSeen: DateTime.now(),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await sub.cancel();
      await source.close();

      expect(names, ['Test User', 'Renamed']);
    });

    test('a deleted user is forwarded as null', () async {
      final source = StreamController<UserModel?>();
      final seen = <UserModel?>[];

      final sub = UserService.decayingPresence(source.stream, tick: tick)
          .listen(seen.add);

      source.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await sub.cancel();
      await source.close();

      expect(seen, [null]);
    });

    test('cancelling stops the ticker', () async {
      // The ticker is a periodic timer owned by the stream. If cancel() leaked
      // it, every closed chat screen would keep one alive for the life of the
      // process — and this test would fail with a pending-timer error.
      final source = StreamController<UserModel?>();
      final sub =
          UserService.decayingPresence(source.stream, tick: tick).listen((_) {});

      source.add(_user(isOnline: true, lastSeen: DateTime.now()));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      await sub.cancel();
      await source.close();

      expect(source.hasListener, isFalse, reason: 'upstream released too');
    });
  });
  group('toWritableMap', () {
    test('bulk profile writes carry no presence fields', () {
      // The leak this closes was live: sign-in built models with
      // `isOnline: true` and a client-clock `lastSeen`, and a profile save
      // carried whatever presence the model was *read* with. Neither arms an
      // RTDB onDisconnect, so the claim had nothing to retract it — the user
      // showed online to everyone with no path back to offline but the sweeper.
      //
      // Presence belongs to PresenceService and presenceMirror alone. Under
      // SetOptions(merge: true) omitting the keys leaves the live values alone.
      final map = UserModel(
        id: 'u1',
        name: 'Test User',
        isOnline: true,
        lastSeen: DateTime.now(),
      ).toWritableMap();

      expect(map.containsKey('isOnline'), isFalse);
      expect(map.containsKey('lastSeen'), isFalse);
      expect(map['name'], 'Test User', reason: 'the profile itself still writes');
    });

    test('absence reads back as offline, not as a live session', () {
      // The safe default matters: a brand-new account has no presence fields
      // until PresenceService writes them, and until then it must not appear
      // online.
      final restored = UserModel.fromMap(
        UserModel(id: 'u1', name: 'Test User', isOnline: true).toWritableMap(),
        'u1',
      );

      expect(restored.isOnline, isFalse);
      expect(restored.lastSeen, isNull);
    });
  });
}
