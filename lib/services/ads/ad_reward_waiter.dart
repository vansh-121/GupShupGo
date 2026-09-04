/// GupShupGo — waiting for a rewarded-ad payout to land.
///
/// A rewarded ad is not paid by the app. When the view qualifies, Google calls
/// the `admobSsv` Cloud Function, which verifies the signature and writes the
/// reward to `users/{uid}`. That round-trip is reliable but *not* instant — it is
/// usually well under a second and occasionally several seconds.
///
/// So the UI can't credit optimistically (the client isn't allowed to be right
/// about this) and can't assume the reward is already there. It watches the user
/// document until the server's write shows up, with a deadline so a genuinely
/// lost callback ends in an explanation rather than a spinner forever.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// How long to wait for the SSV write before telling the user to check back.
/// The reward is not lost when this expires — it just hasn't arrived yet, and
/// the wording in the UI has to reflect that.
const Duration kAdRewardWaitTimeout = Duration(seconds: 30);

class AdRewardWaiter {
  AdRewardWaiter._();

  /// Resolves `true` once [satisfied] holds for the `users/[uid]` document,
  /// `false` if [timeout] elapses first.
  ///
  /// [satisfied] is given the raw user data and should compare against a value
  /// captured *before* the ad was shown — e.g. `(u) => points(u) > before`.
  /// Comparing against a baseline rather than testing for a fixed amount keeps
  /// this correct if the server's payout changes, and avoids resolving on the
  /// first snapshot (which fires immediately with the pre-reward state).
  static Future<bool> awaitCredit({
    required String uid,
    required bool Function(Map<String, dynamic> user) satisfied,
    Duration timeout = kAdRewardWaitTimeout,
  }) async {
    final arrived = Completer<bool>();
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? sub;
    Timer? deadline;

    void finish(bool value) {
      if (arrived.isCompleted) return;
      arrived.complete(value);
      deadline?.cancel();
      sub?.cancel();
    }

    try {
      sub = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots()
          .listen(
            (snap) {
              final data = snap.data();
              if (data != null && satisfied(data)) finish(true);
            },
            onError: (Object e) {
              debugPrint('[AdReward] ⚠️ watch failed: $e');
              finish(false);
            },
          );
      deadline = Timer(timeout, () => finish(false));
      return await arrived.future;
    } catch (e) {
      debugPrint('[AdReward] ⚠️ watch threw: $e');
      finish(false);
      return false;
    } finally {
      deadline?.cancel();
      unawaited(sub?.cancel());
    }
  }

  /// `users/{uid}.gupPoints`, read defensively — the field is written by several
  /// paths and has been an int and a num at different times.
  static int points(Map<String, dynamic> user) {
    final v = user['gupPoints'];
    return v is num ? v.toInt() : 0;
  }

  /// `users/{uid}.adRestoreCredits` — unspent ad-earned Bond Restores.
  static int restoreCredits(Map<String, dynamic> user) {
    final v = user['adRestoreCredits'];
    return v is num ? v.toInt() : 0;
  }
}
