/// GupShupGo — anchored adaptive banner.
///
/// Reserves **zero** height until an ad has actually loaded, so a slow or empty
/// fill never shifts the layout under the user's thumb — which in a chat app
/// means never moving a list item out from under a tap.
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
      // The non-deprecated anchored-adaptive call. It returns a taller slot than
      // the old fixed 320×50 banner (capped at 15% of screen height), which is
      // real screen space on a chat list — but it is what Google optimises fill
      // and eCPM for, and the alternative is a deprecated API scheduled for
      // removal. The height is used as-is: shrinking the container to claw back
      // pixels would clip the ad, which is an obscured-ad policy violation.
      final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
      if (size == null || !mounted) return;

      final ad = BannerAd(
        size: size,
        adUnitId: AdIds.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (!mounted) return;
            setState(() {
              _loaded = true;
              _attempts = 0;
            });
          },
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
      _size = size;
      _loadedWidth = width;
      await ad.load();
    } catch (e) {
      debugPrint('[AdBanner] ⚠️ load threw: $e');
      _release();
    } finally {
      _loading = false;
    }
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
    // distinguishable from app content, and this band sits directly under a
    // scrolling list.
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border, width: 1.0)),
      ),
      width: size.width.toDouble(),
      height: size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
