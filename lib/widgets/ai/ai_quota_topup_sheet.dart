import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/provider/subscription_provider.dart';
import 'package:video_chat_app/screens/premium_screen.dart';
import 'package:video_chat_app/services/ads/ad_reward_waiter.dart';
import 'package:video_chat_app/services/ads/ads_service.dart';
import 'package:video_chat_app/services/ads/rewarded_ad_service.dart';
import 'package:video_chat_app/services/feature_flag_service.dart';
import 'package:video_chat_app/services/streak/server_clock.dart';
import 'package:video_chat_app/services/streak/streak_day.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// Today's rewarded-AI top-up count from the server-written `aiRewardDaily`
/// counter, read with the same canonical day key `admobSsv` stamps so a device
/// in another timezone doesn't disagree. A bucket from any other day reads as 0.
///
/// Shared so the GupAI screen's allowance chip and this sheet's credit-waiter
/// compute "top-ups earned today" the same way.
int aiRewardCountToday(Map<String, dynamic>? user, String todayKey) {
  final daily = user?['aiRewardDaily'];
  if (daily is! Map) return 0;
  if (daily['dayKey'] != todayKey) return 0;
  final count = daily['count'];
  return count is num ? count.toInt() : 0;
}

/// The shared "Daily limit reached" sheet: watch a rewarded ad to top up today's
/// GupAI allowance, or upgrade to Pro. Used by BOTH the dedicated GupAI screen
/// and the in-chat actions, so the ad-watch → credit-wait → resume flow lives in
/// one place instead of being copied per surface.
///
/// [onCredited] runs once a rewarded credit has landed (the sheet is already
/// popped): the dedicated screen re-asks the pending turn, an in-chat action
/// re-runs itself. [isPro]/[canEarn] come straight from the server's 429 body.
Future<void> showAiQuotaTopUpSheet({
  required BuildContext context,
  required bool isPro,
  required bool canEarn,
  required Future<void> Function() onCredited,
}) {
  final c = AppThemeColors.of(context);
  final reward = FeatureFlagService.instance.aiRewardCredits;
  final canWatch = canEarn && AdsService.instance.canShowRewarded;
  // `isProFeatureVisible` is `pro_enabled`: with it off there is nothing to
  // sell, so the upgrade affordance stays hidden rather than leading to a dead
  // end. A genuine Pro holder who somehow hit this never sees it either.
  final showUpgrade =
      !isPro && context.read<SubscriptionProvider>().isProFeatureVisible;

  // Capture the presenting navigator so the Upgrade button can pop the sheet and
  // push PremiumScreen without touching the (soon-defunct) sheet context.
  final navigator = Navigator.of(context);

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: c.cardBg,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _AiTopUpSheet(
      colors: c,
      isPro: isPro,
      reward: reward,
      canWatch: canWatch,
      showUpgrade: showUpgrade,
      onCredited: onCredited,
      onUpgrade: () {
        navigator.pop();
        navigator.push(
          MaterialPageRoute<void>(builder: (_) => const PremiumScreen()),
        );
      },
    ),
  );
}

class _AiTopUpSheet extends StatefulWidget {
  const _AiTopUpSheet({
    required this.colors,
    required this.isPro,
    required this.reward,
    required this.canWatch,
    required this.showUpgrade,
    required this.onCredited,
    required this.onUpgrade,
  });

  final AppThemeColors colors;
  final bool isPro;
  final int reward;
  final bool canWatch;
  final bool showUpgrade;
  final Future<void> Function() onCredited;
  final VoidCallback onUpgrade;

  @override
  State<_AiTopUpSheet> createState() => _AiTopUpSheetState();
}

class _AiTopUpSheetState extends State<_AiTopUpSheet> {
  late String _statusLine = widget.isPro
      ? "You've used all of today's messages. They reset tomorrow."
      : "You've used today's free messages.";
  bool _adBusy = false;

  Future<void> _watchAd() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _adBusy) return;
    setState(() {
      _adBusy = true;
      _statusLine = 'Loading an ad…';
    });

    final todayKey = StreakDay.fromInstant(ServerClock.now()).key;
    var baseline = 0;
    try {
      final snap =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      baseline = aiRewardCountToday(snap.data(), todayKey);
    } catch (_) {}

    final outcome = await RewardedAdService.instance.show(
      uid: uid,
      type: AdRewardType.aiCredit,
    );

    if (outcome != RewardedAdOutcome.earned) {
      if (!mounted) return;
      setState(() {
        _adBusy = false;
        _statusLine = switch (outcome) {
          RewardedAdOutcome.dismissedEarly =>
            'Watch the full ad to unlock more messages.',
          RewardedAdOutcome.unavailable => 'Ads aren\'t available right now.',
          _ => 'Couldn\'t load an ad. Please try again shortly.',
        };
      });
      return;
    }

    if (mounted) setState(() => _statusLine = 'Unlocking your messages…');
    final credited = await AdRewardWaiter.awaitCredit(
      uid: uid,
      satisfied: (u) => aiRewardCountToday(u, todayKey) > baseline,
    );

    if (!credited) {
      if (!mounted) return;
      setState(() {
        _adBusy = false;
        _statusLine = 'Your reward is taking a moment — try again shortly.';
      });
      return;
    }

    // Credit landed. Close the sheet, then let the caller resume its action.
    if (mounted) Navigator.of(context).pop();
    await widget.onCredited();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('🎯', style: GoogleFonts.poppins(fontSize: 26)),
          const SizedBox(height: 8),
          Text(
            'Daily limit reached',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: c.textHigh,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _statusLine,
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.45,
              color: c.textMid,
            ),
          ),
          const SizedBox(height: 18),
          if (widget.canWatch)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: c.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _adBusy ? null : _watchAd,
              icon: _adBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_circle_outline_rounded),
              label: Text(
                _adBusy ? 'Please wait…' : 'Watch an ad for +${widget.reward}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          if (widget.canWatch && widget.showUpgrade) const SizedBox(height: 10),
          if (widget.showUpgrade)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: c.primary,
                side: BorderSide(color: c.primary.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _adBusy ? null : widget.onUpgrade,
              icon: const Icon(Icons.workspace_premium_rounded),
              label: Text(
                'Upgrade to Pro for more',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          if (!widget.canWatch && !widget.showUpgrade) const SizedBox(height: 2),
          const SizedBox(height: 6),
          TextButton(
            onPressed: _adBusy ? null : () => Navigator.of(context).pop(),
            child: Text(
              'Maybe later',
              style: GoogleFonts.poppins(
                color: c.textMid,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
