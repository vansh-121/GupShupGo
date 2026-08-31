/// GupShupGo — AdMob unit IDs.
///
/// Debug builds always serve Google's public test units. That is not a
/// nice-to-have: requesting a *live* unit from a development build is an AdMob
/// policy violation (invalid traffic) and is the most common way accounts get
/// suspended, because every hot reload during UI work looks like a fresh
/// impression. The switch is on [kDebugMode] rather than a hand-set constant so
/// it cannot be left flipped the wrong way by accident.
///
/// A physical device running a *release* build hits live units, so register that
/// device in the AdMob console (Settings → Test devices) before testing there —
/// see [AdsService] for where the device ID is wired in.
///
/// The app ID (`ca-app-pub-8214980075451384~2552239193`, note the `~`) is not
/// here: it belongs to the native side and lives in AndroidManifest.xml and
/// ios/Runner/Info.plist. These are unit IDs (note the `/`).
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class AdIds {
  const AdIds._();

  // ── Live units (AdMob account ca-app-pub-8214980075451384) ───────────────
  //
  // iOS has no units of its own yet — ads are Android-first. Until they exist,
  // iOS release builds fall back to the test units rather than borrowing the
  // Android ones, which would be rejected by the SDK anyway (a unit belongs to
  // exactly one platform of one app).
  static const _androidBanner = 'ca-app-pub-8214980075451384/7389208840';
  static const _androidRewarded = 'ca-app-pub-8214980075451384/3145500055';

  // ── Google's public test units ───────────────────────────────────────────
  // Documented at https://developers.google.com/admob/flutter/test-ads —
  // these always fill, and always render the "Test Ad" label.
  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const _testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const _testRewardedIos = 'ca-app-pub-3940256099942544/1712485313';

  /// True when this build must not touch live inventory.
  static bool get useTestAds => kDebugMode || !Platform.isAndroid;

  static String get banner {
    if (useTestAds) {
      return Platform.isAndroid ? _testBannerAndroid : _testBannerIos;
    }
    return _androidBanner;
  }

  static String get rewarded {
    if (useTestAds) {
      return Platform.isAndroid ? _testRewardedAndroid : _testRewardedIos;
    }
    return _androidRewarded;
  }
}
