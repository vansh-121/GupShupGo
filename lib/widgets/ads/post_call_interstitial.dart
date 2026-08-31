/// GupShupGo — fires the post-call interstitial, from somewhere safe.
///
/// `CallScreen._cleanupAndPop` ends with `Navigator.pop`, so the call screen
/// cannot show an interstitial itself: the ad would land over call UI, on top of
/// a hangup button, which is an obscured-ad problem and an accidental-click one
/// at the same time. So the call screen only *arms* the ad
/// ([InterstitialAdService.armPostCall]) and this widget — mounted on the home
/// screen, the place a call returns to — fires it once the app is genuinely back
/// at [CallState.Idle].
///
/// That split is what makes "no ad over call UI" structural instead of a
/// convention someone has to remember. It renders nothing.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/provider/call_state_provider.dart';
import 'package:video_chat_app/provider/subscription_provider.dart';
import 'package:video_chat_app/services/ads/interstitial_ad_service.dart';

/// Breathing room between the call screen disappearing and the ad appearing.
///
/// Without it the ad arrives during the pop animation and reads as part of the
/// call ending — which is both worse UX and closer to the kind of unexpected
/// fullscreen ad AdMob's placement guidance is aimed at.
const Duration _kSettleDelay = Duration(milliseconds: 700);

class PostCallInterstitial extends StatefulWidget {
  const PostCallInterstitial({super.key});

  @override
  State<PostCallInterstitial> createState() => _PostCallInterstitialState();
}

class _PostCallInterstitialState extends State<PostCallInterstitial> {
  CallState _last = CallState.Idle;
  bool _firing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final callState = Provider.of<CallStateNotifier>(context).state;
    final hasPro =
        Provider.of<SubscriptionProvider>(context).hasActiveProEntitlement;

    final wasBusy = _last != CallState.Idle;
    _last = callState;

    // Only on the transition *into* idle. Reacting to idle itself would fire on
    // every unrelated rebuild of the home screen.
    if (wasBusy &&
        callState == CallState.Idle &&
        InterstitialAdService.instance.isPostCallArmed) {
      unawaited(_fire(hasPro));
    }
  }

  Future<void> _fire(bool hasPro) async {
    if (_firing) return;
    _firing = true;
    try {
      await Future<void>.delayed(_kSettleDelay);
      if (!mounted) {
        // The home screen went away — a chat opened, the app was backgrounded.
        // Drop the chance rather than showing an ad over wherever we ended up.
        InterstitialAdService.instance.disarmPostCall();
        return;
      }
      await InterstitialAdService.instance.showArmedPostCall(
        hasProEntitlement: hasPro,
        callState: CallState.Idle,
      );
    } finally {
      _firing = false;
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
