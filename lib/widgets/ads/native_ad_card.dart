/// GupShupGo — a native ad rendered as an unmistakable sponsored card.
///
/// Uses the plugin's *template* renderer ([NativeTemplateStyle]) rather than a
/// platform ad factory, so there is no Android layout XML and no iOS view class
/// to keep in sync — the template is themed from [AppThemeColors] and follows
/// dark mode for free.
///
/// The card is deliberately card-shaped and labelled. It does **not** imitate a
/// message bubble, a status tile or a call log row, even where it sits directly
/// among them: an ad that mimics app content is a distinct AdMob violation
/// (deceptive implementation), and unlike an accidental-click problem it is the
/// kind that disables an account rather than warning it.
///
/// Like [AdBanner], this reserves **zero** height until an ad has actually
/// loaded, so a no-fill never shifts a list under the user's thumb.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/provider/call_state_provider.dart';
import 'package:video_chat_app/provider/subscription_provider.dart';
import 'package:video_chat_app/services/ads/ad_ids.dart';
import 'package:video_chat_app/services/ads/ads_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// Height given to the rendered template.
///
/// Google's small template documents a 90dp minimum; below it the creative is
/// clipped, and a clipped ad counts as an obscured one. The few dp above the
/// minimum absorb the text-scale settings of users who run large fonts.
const double _kTemplateHeight = 104;

/// Google's small template also documents a 320dp minimum *width*. Rather than
/// render a squeezed, possibly clipped card on a very narrow window, the card
/// simply doesn't appear — a missing ad costs one impression, a distorted one
/// risks the account.
const double _kMinTemplateWidth = 320;

/// Native cards live inside lists the user is scrolling, so a retry loop here is
/// even less welcome than in the banner. Two attempts, then leave the slot empty.
const int _kMaxLoadAttempts = 2;

/// A load budget that outlives the card that spends it.
///
/// A `ListView.builder` rebuilds any element whose index now holds a different
/// kind of widget, and in a `reverse: true` chat list *every* index shifts when a
/// message arrives or the typing bubble appears. So the card is torn down and
/// rebuilt through no fault of its own — and its own attempt counter is reborn
/// with it. Handing it a budget owned by the enclosing screen is what keeps that
/// from becoming one ad request per message: requests that never become
/// impressions count against the account, and the user pays for them in battery
/// and data either way.
///
/// The ad object itself deliberately does **not** live here. Two `AdWidget`s over
/// one ad coexist for part of a frame during such a rebuild, and on Android that
/// means attaching one native view to two parents.
///
/// Once the budget is spent the slot stays empty for the rest of the visit. One
/// lost impression is the right side of that trade.
class NativeAdBudget {
  NativeAdBudget({this.maxAttempts = _kMaxLoadAttempts});

  final int maxAttempts;
  int _spent = 0;

  bool get exhausted => _spent >= maxAttempts;
  void spend() => _spent++;
}

/// Width of the card's own outline, taken off the width available to the
/// template when checking [_kMinTemplateWidth].
const double _kBorder = 1;

class NativeAdCard extends StatefulWidget {
  const NativeAdCard({
    super.key,
    required this.placement,
    this.inChat = false,
    this.budget,
    this.margin = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  /// Only used in debug logging, so a no-fill can be traced to a surface.
  final String placement;

  /// Selects the chat-specific Remote Config switch — see
  /// [AdsService.canShowNative].
  final bool inChat;

  /// Supply one from a [State] that outlives this card whenever the card sits at
  /// an index that can shift — see [NativeAdBudget]. Omitted, the card keeps its
  /// own budget, which is correct only where a rebuild means the surface itself
  /// went away.
  final NativeAdBudget? budget;

  final EdgeInsets margin;

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  NativeAd? _ad;
  bool _loaded = false;
  bool _loading = false;

  /// The caller's budget where one was given, otherwise a private one that dies
  /// with this card.
  late final NativeAdBudget _budget = widget.budget ?? NativeAdBudget();

  // Snapshots of the reactive inputs, refreshed in didChangeDependencies so
  // _reconcile() can also run from AdsService's listener, where reading a
  // provider with listen:true would be illegal.
  bool _hasPro = false;
  CallState _callState = CallState.Idle;
  double _available = 0;
  bool? _loadedDark;

  @override
  void initState() {
    super.initState();
    AdsService.instance.addListener(_reconcile);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // hasActiveProEntitlement, deliberately, not isPro — see the getter's doc.
    _hasPro = Provider.of<SubscriptionProvider>(context).hasActiveProEntitlement;
    _callState = Provider.of<CallStateNotifier>(context).state;
    _available =
        MediaQuery.sizeOf(context).width - widget.margin.horizontal - _kBorder * 2;

    // The template's colours are baked in at request time, so a theme flip after
    // the ad loaded would leave a light card sitting in a dark list. Reload it
    // rather than let it clash — out of the same budget, so a user toggling the
    // theme repeatedly cannot turn that into a request loop.
    final isDark = AppThemeColors.of(context).isDark;
    if (_ad != null && _loadedDark != null && _loadedDark != isDark) {
      _release();
    }

    _reconcile();
  }

  bool get _allowed =>
      AdsService.instance.canShowNative(
        hasProEntitlement: _hasPro,
        callState: _callState,
        inChat: widget.inChat,
      ) &&
      _available >= _kMinTemplateWidth;

  void _reconcile() {
    if (!mounted) return;

    if (!_allowed) {
      _release();
      return;
    }

    if (_ad == null && !_loading && !_budget.exhausted) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    _loading = true;
    _budget.spend();

    try {
      final c = AppThemeColors.of(context);

      final ad = NativeAd(
        adUnitId: AdIds.nativeAd,
        request: const AdRequest(),
        // Themed to the app's own surface so the card doesn't glare in dark
        // mode. Note this styles the *chrome*, not the creative — the advertiser
        // still supplies the image and copy, and Google's own "Ad" badge is
        // rendered by the template and cannot be styled away.
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.small,
          mainBackgroundColor: c.surface,
          cornerRadius: 12,
          primaryTextStyle: NativeTemplateTextStyle(
            textColor: c.textHigh,
            backgroundColor: c.surface,
            size: 14,
          ),
          secondaryTextStyle: NativeTemplateTextStyle(
            textColor: c.textMid,
            backgroundColor: c.surface,
            size: 12,
          ),
          tertiaryTextStyle: NativeTemplateTextStyle(
            textColor: c.textLow,
            backgroundColor: c.surface,
            size: 11,
          ),
          callToActionTextStyle: NativeTemplateTextStyle(
            textColor: Colors.white,
            backgroundColor: c.primary,
            size: 13,
          ),
        ),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            if (!mounted) {
              ad.dispose();
              return;
            }
            setState(() {
              _loaded = true;
              _loadedDark = c.isDark;
            });
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('[NativeAd:${widget.placement}] ⚠️ load failed: $error');
            ad.dispose();
            if (!mounted) return;
            setState(() {
              _ad = null;
              _loaded = false;
            });
          },
        ),
      );

      _ad = ad;
      await ad.load();
    } catch (e) {
      debugPrint('[NativeAd:${widget.placement}] ⚠️ load threw: $e');
      _release();
    } finally {
      _loading = false;
    }
  }

  void _release() {
    if (_ad == null && !_loaded) return;
    _ad?.dispose();
    _ad = null;
    _loadedDark = null;
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
    if (!_loaded || ad == null) return const SizedBox.shrink();

    final c = AppThemeColors.of(context);

    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border, width: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The template renders Google's required "Ad" badge itself; this row is
          // the app's own, plainer-language version of the same statement. In a
          // message stream especially, the reader should never have to look for
          // the badge to work out that this isn't part of their conversation.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Text(
              'Sponsored',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: c.textLow,
              ),
            ),
          ),
          SizedBox(
            height: _kTemplateHeight,
            width: double.infinity,
            child: AdWidget(ad: ad),
          ),
        ],
      ),
    );
  }
}
