/// GupShupGo — "watch an ad for Gup Points" card.
///
/// Lives in the Arcade overview, where points are already the unit of account, so
/// the offer reads as part of the game rather than an interruption. Deliberately
/// **not** placed anywhere in the chat or call flow.
///
/// The card promises what Remote Config says (`ads_reward_points`,
/// `ads_rewarded_daily_cap`) but pays nothing: `admobSsv` credits the account
/// after Google's signed callback, and the server's own constants are what
/// actually decide the amount. If the two ever drift, the copy is wrong and the
/// payout is right — which is the safe direction for that bug to point.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/services/ads/ad_reward_waiter.dart';
import 'package:video_chat_app/services/ads/ads_service.dart';
import 'package:video_chat_app/services/ads/rewarded_ad_service.dart';
import 'package:video_chat_app/services/feature_flag_service.dart';
import 'package:video_chat_app/services/streak/server_clock.dart';
import 'package:video_chat_app/services/streak/streak_day.dart';
import 'package:video_chat_app/theme/app_theme.dart';

class WatchAdForPointsCard extends StatefulWidget {
  const WatchAdForPointsCard({super.key, required this.userId});

  final String userId;

  @override
  State<WatchAdForPointsCard> createState() => _WatchAdForPointsCardState();
}

class _WatchAdForPointsCardState extends State<WatchAdForPointsCard> {
  bool _watching = false;
  bool _awaiting = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    AdsService.instance.addListener(_onAdsChanged);
    // The Arcade is a full screen, so it is a reasonable place to resolve consent
    // if the home banner hasn't already — unlike a dialog, a form here isn't
    // stacked on top of something the user was mid-way through.
    unawaited(AdsService.instance.ensureConsent());
    unawaited(RewardedAdService.instance.preload());
  }

  void _onAdsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AdsService.instance.removeListener(_onAdsChanged);
    super.dispose();
  }

  /// Views already taken today, from the server-written counter. The day key is
  /// computed in the canonical zone — the same one `admobSsv` uses — so a device
  /// in another timezone doesn't disagree with the cap it's about to hit.
  int _usedToday(Map<String, dynamic>? user) {
    final daily = user?['adRewardDaily'];
    if (daily is! Map) return 0;
    final todayKey = StreakDay.fromInstant(ServerClock.now()).key;
    if (daily['dayKey'] != todayKey) return 0;
    final count = daily['count'];
    return count is num ? count.toInt() : 0;
  }

  Future<void> _watch(int pointsBefore) async {
    if (_watching || _awaiting) return;
    setState(() {
      _watching = true;
      _message = null;
    });

    final outcome = await RewardedAdService.instance.show(
      uid: widget.userId,
      type: AdRewardType.points,
    );
    if (!mounted) return;

    if (outcome != RewardedAdOutcome.earned) {
      setState(() {
        _watching = false;
        _message = switch (outcome) {
          RewardedAdOutcome.dismissedEarly =>
            'Watch the full ad to collect your points.',
          RewardedAdOutcome.unavailable => 'Rewards aren\'t available right now.',
          _ => 'Couldn\'t load an ad. Please try again in a moment.',
        };
      });
      return;
    }

    setState(() {
      _watching = false;
      _awaiting = true;
      _message = 'Reward on its way…';
    });

    final credited = await AdRewardWaiter.awaitCredit(
      uid: widget.userId,
      satisfied: (u) => AdRewardWaiter.points(u) > pointsBefore,
    );
    if (!mounted) return;

    setState(() {
      _awaiting = false;
      // Not a failure — the callback is usually just slow, and the points land on
      // the account whether or not this screen is still open.
      _message = credited
          ? 'Points added!'
          : 'Your points are taking a moment — they\'ll appear shortly.';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!AdsService.instance.canShowRewarded) return const SizedBox.shrink();

    final c = AppThemeColors.of(context);
    final flags = FeatureFlagService.instance;
    final reward = flags.adsRewardPoints;
    final cap = flags.adsRewardedDailyCap;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .snapshots(),
      builder: (context, snap) {
        final user = snap.data?.data();
        final used = _usedToday(user);
        final remaining = (cap - used).clamp(0, cap);
        final pointsNow = user == null ? 0 : AdRewardWaiter.points(user);
        final busy = _watching || _awaiting;
        final exhausted = remaining == 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: c.isDark
                  ? [const Color(0xFF1E2A3A), const Color(0xFF18202E)]
                  : [const Color(0xFFE8F4FF), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.primary.withValues(alpha: 0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🎁', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    'Free Points',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: c.textHigh,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    exhausted ? 'Back tomorrow' : '$remaining of $cap left today',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c.textLow,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                exhausted
                    ? 'You\'ve collected today\'s free points. The counter resets tomorrow.'
                    : 'Watch a short ad and collect ⚡$reward Gup Points.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: c.textMid,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (exhausted || busy) ? null : () => _watch(pointsNow),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: c.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: c.primary.withValues(alpha: 0.35),
                    disabledForegroundColor: Colors.white70,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_circle_outline_rounded,
                                size: 18),
                            const SizedBox(width: 6),
                            Text(
                              exhausted
                                  ? 'Daily limit reached'
                                  : 'Watch & earn ⚡$reward',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 8),
                Text(
                  _message!,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: c.textMid,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
