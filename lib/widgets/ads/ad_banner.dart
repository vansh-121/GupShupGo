/// GupShupGo — bottom banner, sized to the ad that actually arrived.
///
/// Reserves **zero** height until an ad has actually loaded, so a slow or empty
/// fill never shifts the layout under the user's thumb — which in a chat app
/// means never moving a list item out from under a tap. Once loaded it takes
/// exactly the height the creative was served at and not a pixel more.
///
/// Placement rules live in [AdsService.canShowBanner], not here. This widget's
/// only jobs are to ask, to reconcile when the answer changes mid-session (a
/// call starts, Pro is purchased, the flag is flipped), and to dispose the
/// native ad properly.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/provider/call_state_provider.dart';
import 'package:video_chat_app/provider/subscription_provider.dart';
import 'package:video_chat_app/services/ads/ad_ids.dart';
import 'package:video_chat_app/services/ads/ads_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// A no-fill is routine, not an error, so a failed load just leaves the slot
/// empty. This caps how many times one mount will retry, because dependency
/// changes (tab switches, call state, subscription syncs) would otherwise drive
/// a request loop — and repeated requests with no impressions is itself
/// something AdMob penalises.
const int _kMaxLoadAttempts = 3;

/// Ceiling on the banner's height, in logical pixels.
///
/// The anchored-adaptive sizes Google steers you toward return roughly 100dp on
/// a phone — a band nearly twice the height of the 60dp nav dock, sitting under
/// the app's primary surface. This caps the ad at one standard banner row
/// instead. It costs nothing in fill: 320×50 is the best-filled banner format
/// there is.
const int _kMaxBannerHeight = 50;

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  AdSize? _size;
  bool _loaded = false;
  bool _loading = false;
  int _attempts = 0;

  // Snapshots of the reactive inputs, refreshed in didChangeDependencies so
  // that _reconcile() can also be driven by AdsService's own listener — where
  // reading a provider with listen:true would be illegal.
  bool _hasPro = false;
  CallState _callState = CallState.Idle;
  int _width = 0;
  int _loadedWidth = 0;

  @override
  void initState() {
    super.initState();
    AdsService.instance.addListener(_reconcile);
    // The home tabs are the app's only ad-bearing surface, so this is where the
    // UMP consent form belongs — not in main(), where it would land over the
    // login screen. No-op for users outside a regulated region and for anyone
    // who has already answered.
    unawaited(AdsService.instance.ensureConsent());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // hasActiveProEntitlement, deliberately, not isPro — see the getter's doc.
    _hasPro = Provider.of<SubscriptionProvider>(context).hasActiveProEntitlement;
    _callState = Provider.of<CallStateNotifier>(context).state;
    _width = MediaQuery.sizeOf(context).width.truncate();
    _reconcile();
  }

  void _reconcile() {
    if (!mounted) return;

    final allowed = AdsService.instance.canShowBanner(
      hasProEntitlement: _hasPro,
      callState: _callState,
    );

    if (!allowed) {
      _release();
      return;
    }

    // Rotation changes the adaptive height, and an AdWidget sized for the old
    // width would be letterboxed or clipped — either of which reads as an
    // obscured ad. Reload at the new width instead.
    if (_ad != null && _loadedWidth != _width) {
      _release();
      _attempts = 0;
    }

    if (_ad == null && !_loading && _attempts < _kMaxLoadAttempts) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    _loading = true;
    _attempts++;
    final width = _width;

    try {
      // Inline adaptive, not anchored adaptive, and deliberately so. An
      // anchored request returns one fixed slot per device and pads whatever
      // creative arrives out to fill it — so a 320×50 fill leaves a half-empty
      // band, which is exactly what the large anchored size was doing here.
      // Inline lets Google pick any height up to the cap, and
      // getPlatformAdSize() reports what actually came back, so the container
      // matches the ad. The anchored calls that return a *smaller* slot are all
      // deprecated in google_mobile_ads 9.x; this one is not.
      final requested = AdSize.getInlineAdaptiveBannerAdSize(
        width,
        _kMaxBannerHeight,
      );

      if (!mounted) return;

      final ad = BannerAd(
        size: requested,
        adUnitId: AdIds.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          // Not awaited inline: the callback signature is synchronous, and the
          // served height needs a platform round trip.
          onAdLoaded: (Ad ad) => unawaited(_applyServedSize(ad as BannerAd)),
          onAdFailedToLoad: (ad, error) {
            debugPrint('[AdBanner] ⚠️ load failed: $error');
            ad.dispose();
            if (!mounted) return;
            setState(() {
              _ad = null;
              _size = null;
              _loaded = false;
            });
          },
        ),
      );

      _ad = ad;
      _loadedWidth = width;
      await ad.load();
    } catch (e) {
      debugPrint('[AdBanner] ⚠️ load threw: $e');
      _release();
    } finally {
      _loading = false;
    }
  }

  /// Reads back the height the creative was actually served at.
  ///
  /// An inline adaptive request carries height 0 by design, so this round trip
  /// is the only way to know how tall the band should be — and it is the whole
  /// point of using inline here, because it is what stops the slot from
  /// reserving space the ad does not fill.
  Future<void> _applyServedSize(BannerAd ad) async {
    final served = await ad.getPlatformAdSize();
    // A rotation or a call starting mid-round-trip can retire this ad first.
    if (!mounted || ad != _ad) return;

    if (served == null) {
      // Guessing a height risks clipping the creative, which is an obscured-ad
      // violation, so treat it as a no-fill instead.
      debugPrint('[AdBanner] ⚠️ filled but reported no size — dropping');
      _release();
      return;
    }

    setState(() {
      _size = served;
      _loaded = true;
      _attempts = 0;
    });
  }

  /// Tears down the native ad. Safe to call when there is nothing to release.
  void _release() {
    if (_ad == null && !_loaded) return;
    _ad?.dispose();
    _ad = null;
    _size = null;
    if (mounted) {
      setState(() => _loaded = false);
    } else {
      _loaded = false;
    }
  }

  @override
  void dispose() {
    AdsService.instance.removeListener(_reconcile);
    _ad?.dispose();
    _ad = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    final size = _size;
    if (!_loaded || ad == null || size == null) return const SizedBox.shrink();

    final c = AppThemeColors.of(context);

    // The top border is not decoration: AdMob requires ads to be clearly
    // distinguishable from app content, and this band sits directly against the
    // nav dock's tap targets.
    //
    // The band spans the full width so that separator line does too, while the
    // AdWidget keeps the exact size it was served at — centred when the creative
    // is narrower than the screen. Stretching it to fill would scale the ad, and
    // a scaled ad is a distorted one.
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border, width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size.width.toDouble(),
            height: size.height.toDouble(),
            child: AdWidget(ad: ad),
          ),
        ],
      ),
    );
  }
}
