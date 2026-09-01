// The numbers behind the Premium screen.
//
// Every card on that screen is a promise, and for a long stretch four of them
// were promises nothing in the code kept. These assertions exist to make the
// copy and the code fail together rather than drift apart again:
//
//   • "Voice messages: 2 minutes / Unlimited" — 120 s versus `null`, where
//     `null` is the sentinel the recorder reads as uncapped. A 0 or a very large
//     int here would silently become a cap.
//   • "Higher Quality Media" — the free numbers are pinned to exactly what
//     shipped before the tier existed, because the perk is that Pro downscales
//     less, not that free downscales more than it used to.
//   • "90s videos" — the status recorder's `maxDuration`.
//   • The boolean gates that back Chat Export and Chat Themes, which were both
//     declared and never read before this change.

import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/models/subscription_model.dart';

void main() {
  group('maxVoiceDurationSec', () {
    test('free is capped at two minutes', () {
      expect(PlanLimits.maxVoiceDurationSec(false), 120);
    });

    test('Pro is null, which the recorder reads as uncapped', () {
      // Not 0 and not a large sentinel: `VoiceRecorderService` branches on
      // `cap != null` and would auto-stop instantly on 0, turning the headline
      // Pro perk into a broken recorder.
      expect(PlanLimits.maxVoiceDurationSec(true), isNull);
    });
  });

  group('maxStatusVideoSec', () {
    test('free keeps the 30 s limit it always had', () {
      expect(PlanLimits.maxStatusVideoSec(false), 30);
    });

    test('Pro gets the 90 s the Premium card advertises', () {
      expect(PlanLimits.maxStatusVideoSec(true), 90);
    });
  });

  group('image quality tiers', () {
    test('free chat images keep their pre-tier numbers', () {
      // The trade this feature was designed around: nobody loses capability
      // when a paid tier appears above them. Lowering either of these would be
      // a regression dressed up as an upsell.
      expect(PlanLimits.chatImageMaxEdge(false), 1280);
      expect(PlanLimits.chatImageQuality(false), 70);
    });

    test('free status images keep their pre-tier numbers', () {
      expect(PlanLimits.statusImageMaxEdge(false), 1600);
      expect(PlanLimits.statusImageQuality(false), 75);
    });

    test('Pro is strictly better on both axes, for both surfaces', () {
      expect(PlanLimits.chatImageMaxEdge(true),
          greaterThan(PlanLimits.chatImageMaxEdge(false)));
      expect(PlanLimits.chatImageQuality(true),
          greaterThan(PlanLimits.chatImageQuality(false)));
      expect(PlanLimits.statusImageMaxEdge(true),
          greaterThan(PlanLimits.statusImageMaxEdge(false)));
      expect(PlanLimits.statusImageQuality(true),
          greaterThan(PlanLimits.statusImageQuality(false)));
    });

    test('quality stays inside the encoder range', () {
      // flutter_image_compress takes 1-100; a value outside it is not clamped,
      // it fails.
      for (final q in [
        PlanLimits.chatImageQuality(false),
        PlanLimits.chatImageQuality(true),
        PlanLimits.statusImageQuality(false),
        PlanLimits.statusImageQuality(true),
      ]) {
        expect(q, inInclusiveRange(1, 100));
      }
    });

    test('statuses start from a higher baseline than chat images', () {
      // Deliberate asymmetry: a chat image renders as a thumbnail, a status
      // fills the screen in the viewer.
      expect(PlanLimits.statusImageMaxEdge(false),
          greaterThan(PlanLimits.chatImageMaxEdge(false)));
    });
  });

  group('boolean gates', () {
    test('chat export is Pro-only', () {
      expect(PlanLimits.canExportChat(true), isTrue);
      expect(PlanLimits.canExportChat(false), isFalse);
    });

    test('custom chat wallpaper is Pro-only', () {
      // Backs the "Choose from gallery" tile in the chat theme sheet — the gate
      // that was declared and never read until chat themes shipped.
      expect(PlanLimits.canCustomWallpaper(true), isTrue);
      expect(PlanLimits.canCustomWallpaper(false), isFalse);
    });

    test('media statuses and screen sharing stay Pro-only', () {
      expect(PlanLimits.canPostMediaStatus(true), isTrue);
      expect(PlanLimits.canPostMediaStatus(false), isFalse);
      expect(PlanLimits.canScreenShare(true), isTrue);
      expect(PlanLimits.canScreenShare(false), isFalse);
    });

    test('free accounts get no streak restores', () {
      expect(PlanLimits.freeStreakRestoresPerWeek(true), 1);
      expect(PlanLimits.freeStreakRestoresPerWeek(false), 0);
    });
  });
}
