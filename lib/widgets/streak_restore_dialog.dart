import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/provider/subscription_provider.dart';
import 'package:video_chat_app/screens/premium_screen.dart';
import 'package:video_chat_app/services/ads/ad_reward_waiter.dart';
import 'package:video_chat_app/services/ads/ads_service.dart';
import 'package:video_chat_app/services/ads/rewarded_ad_service.dart';
import 'package:video_chat_app/services/streak/server_clock.dart';
import 'package:video_chat_app/services/streak/streak_api.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/widgets/ads/watch_ad_for_points_card.dart';

/// A premium dialog for restoring a broken bond (task 8.2).
///
/// Everything the dialog charges for or counts down to comes from
/// `GET /streakRestoreQuote`: the tiered Gup Point cost, the count that will be
/// restored, the contact name, whether the Pro weekly free perk is actually
/// available, and the server-stamped end of the restore window. The client no
/// longer computes the cost from `GamificationService`, no longer asks
/// `SubscriptionService` whether the perk is available, and no longer validates
/// the window against the device clock.
///
/// The countdown ticks off [ServerClock]; when the clock is not trusted this
/// session it is softened to an approximate figure anchored on the quote's
/// `serverNow` instead of showing false precision.
///
/// The visual design, the "Let it go" action and the non-Pro upsell are
/// unchanged from the pre-quote version.
class StreakRestoreDialog extends StatefulWidget {
  /// Locally known count, used only as a placeholder until the quote lands.
  final int previousStreakCount;

  /// Locally known break instant, used only as a fallback deadline hint.
  final DateTime streakBrokenAt;

  /// Locally known balance, used only for the "not enough points" hint. The
  /// server is the authority and answers with `insufficientPoints`.
  final int userGupPoints;
  final String contactName;
  final String userId;
  final String chatRoomId;

  const StreakRestoreDialog({
    super.key,
    required this.previousStreakCount,
    required this.streakBrokenAt,
    required this.userGupPoints,
    required this.contactName,
    required this.userId,
    required this.chatRoomId,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int previousStreakCount,
    required DateTime streakBrokenAt,
    required int userGupPoints,
    required String contactName,
    required String userId,
    required String chatRoomId,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => StreakRestoreDialog(
        previousStreakCount: previousStreakCount,
        streakBrokenAt: streakBrokenAt,
        userGupPoints: userGupPoints,
        contactName: contactName,
        userId: userId,
        chatRoomId: chatRoomId,
      ),
    );
  }

  @override
  State<StreakRestoreDialog> createState() => _StreakRestoreDialogState();
}

class _StreakRestoreDialogState extends State<StreakRestoreDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  Timer? _countdownTimer;

  /// Server quote. Null while loading, and null when the fetch failed.
  StreakRestoreQuote? _quote;
  bool _loadingQuote = true;
  bool _quoteUnavailable = false;

  /// Device instant at which [_quote] was received — the anchor for the
  /// fallback countdown when [ServerClock.trusted] is false.
  DateTime? _quoteReceivedAtDevice;

  Duration _timeRemaining = Duration.zero;
  bool _windowExpired = false;
  bool _isRestoring = false;

  /// A rewarded ad is on screen, or its SSV credit is still in flight.
  bool _watchingAd = false;
  bool _awaitingReward = false;

  /// Distinct, human-readable rendering of the last refusal, if any.
  String? _errorMessage;
  StreakRestoreStatus? _errorStatus;

  /// Neutral status line for the ad flow — not an error, so it isn't rendered
  /// in the red error style.
  String? _adMessage;

  // ── Quote-derived getters ────────────────────────────────────────────────

  int get _previousCount => _quote?.previousCount ?? widget.previousStreakCount;
  String get _contactName =>
      (_quote?.contactName?.isNotEmpty ?? false) ? _quote!.contactName! : widget.contactName;

  /// Server-verified Pro free perk. Never `SubscriptionService`.
  bool get _canRestoreFree => _quote?.canUseFreePerk ?? false;

  /// A restore already paid for by watching an ad, banked server-side by
  /// `admobSsv`. Spent only after the Pro perk, which the server enforces.
  bool get _hasAdCredit => (_quote?.adRestoreCredits ?? 0) > 0;

  /// Whether this restore costs no points, by either route.
  bool get _isFree => _canRestoreFree || _hasAdCredit;

  /// Whether to offer the ad at all: the server says another credit can be
  /// earned this week, ads are on and consented, and there is nothing free in
  /// hand already.
  bool get _canOfferAd =>
      !_isFree &&
      !_windowExpired &&
      (_quote?.canEarnAdRestore ?? false) &&
      AdsService.instance.canShowRewarded;

  /// Tiered Gup Point cost, straight from the quote.
  int get _cost => _isFree ? 0 : (_quote?.cost ?? 0);

  /// Local affordability hint only — the server makes the real call.
  bool get _canAfford =>
      _isFree || _cost == 0 || widget.userGupPoints >= _cost;

  bool get _clockTrusted => ServerClock.trusted;

  bool get _hasCountdown => _quote?.restoreDeadlineAt != null || !_quoteUnavailable;

  bool get _canConfirm =>
      _quote != null &&
      !_loadingQuote &&
      !_isRestoring &&
      !_watchingAd &&
      !_awaitingReward &&
      !_windowExpired &&
      _canAfford &&
      _errorStatus != StreakRestoreStatus.nothingToRestore &&
      _errorStatus != StreakRestoreStatus.notParticipant;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scale = CurvedAnimation(parent: _anim, curve: Curves.elasticOut);
    _anim.forward();

    _loadQuote();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeRemaining();
    });

    // Warm an ad while the quote is in flight, so the "watch an ad" tap is
    // instant if the quote turns out to offer it. No-op when ads are off,
    // unconsented, or already loaded.
    unawaited(RewardedAdService.instance.preload());
    // The SDK may still be initialising when this dialog opens, which would hide
    // the offer for the life of the dialog otherwise.
    AdsService.instance.addListener(_onAdsChanged);
  }

  void _onAdsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AdsService.instance.removeListener(_onAdsChanged);
    _countdownTimer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  Future<void> _loadQuote() async {
    final quote = await StreakApi.instance.streakRestoreQuote(widget.chatRoomId);
    if (!mounted) return;
    setState(() {
      _quote = quote;
      _quoteReceivedAtDevice = DateTime.now().toUtc();
      _loadingQuote = false;
      _quoteUnavailable = quote == null;
      if (quote == null) {
        _errorMessage =
            'Couldn\'t load the restore offer. Check your connection and try again.';
        _errorStatus = StreakRestoreStatus.transportFailure;
      }
    });
    _updateTimeRemaining();
  }

  /// The best available "now": [ServerClock] when it has a sample this
  /// session, otherwise the quote's `serverNow` advanced by device elapsed
  /// time (which is only used for the softened countdown).
  DateTime _now() {
    if (_clockTrusted) return ServerClock.now();
    final serverNow = _quote?.serverNow;
    final anchor = _quoteReceivedAtDevice;
    if (serverNow != null && anchor != null) {
      return serverNow.toUtc().add(DateTime.now().toUtc().difference(anchor));
    }
    return ServerClock.now();
  }

  void _updateTimeRemaining() {
    final deadline = _quote?.restoreDeadlineAt ??
        (_quoteUnavailable
            ? widget.streakBrokenAt.toUtc().add(const Duration(hours: 24))
            : null);
    if (deadline == null) return;

    final remaining = deadline.toUtc().difference(_now());
    if (!mounted) return;
    setState(() {
      _timeRemaining = remaining.isNegative ? Duration.zero : remaining;
      if (remaining.isNegative && !_windowExpired) {
        _windowExpired = true;
        _errorStatus = StreakRestoreStatus.windowExpired;
        _errorMessage = 'The restore window has closed.';
      }
    });
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Softened form used when the clock is not trusted: hours only, no ticking
  /// seconds, so we never imply precision we do not have.
  String _formatApproximate(Duration d) {
    if (d.inHours >= 1) return '~${d.inHours}h left';
    if (d.inMinutes >= 1) return '~${d.inMinutes}m left';
    return 'less than a minute';
  }

  Future<void> _handleRestore() async {
    if (!_canConfirm) return;
    setState(() {
      _isRestoring = true;
      _errorMessage = null;
      _errorStatus = null;
      _adMessage = null;
    });

    final result = await StreakApi.instance.streakRestore(
      widget.chatRoomId,
      // One flag covers both free routes. The server decides which is actually
      // spent — the Pro perk first, an ad credit only when the perk is gone —
      // so the client never has to know, and can't get it wrong.
      useFreePerk: _isFree,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      final restored = result.restoredCount ?? _previousCount;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🤝 Bond restored to $restored days!',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      _isRestoring = false;
      _errorStatus = result.status;
      _errorMessage = _messageFor(result.status);
      if (result.status == StreakRestoreStatus.windowExpired) {
        _windowExpired = true;
        _timeRemaining = Duration.zero;
      }
    });
  }

  /// Watches a rewarded ad to earn one free restore.
  ///
  /// Nothing here grants anything. The ad's only product is a signed callback to
  /// `admobSsv`, which credits `adRestoreCredits`; this method then waits for
  /// that write and re-fetches the quote so the button re-renders itself as free.
  Future<void> _watchAdForRestore() async {
    if (_watchingAd || _awaitingReward || _isRestoring) return;

    final creditsBefore = _quote?.adRestoreCredits ?? 0;
    setState(() {
      _watchingAd = true;
      _errorMessage = null;
      _errorStatus = null;
      _adMessage = null;
    });

    final outcome = await RewardedAdService.instance.show(
      uid: widget.userId,
      type: AdRewardType.restore,
      roomId: widget.chatRoomId,
    );

    if (!mounted) return;

    if (outcome != RewardedAdOutcome.earned) {
      setState(() {
        _watchingAd = false;
        _adMessage = switch (outcome) {
          RewardedAdOutcome.dismissedEarly =>
            'Watch the full ad to earn a free restore.',
          RewardedAdOutcome.unavailable =>
            'Free restores aren\'t available right now.',
          _ => 'Couldn\'t load an ad. Please try again in a moment.',
        };
      });
      return;
    }

    setState(() {
      _watchingAd = false;
      _awaitingReward = true;
      _adMessage = 'Reward on its way…';
    });

    final credited = await AdRewardWaiter.awaitCredit(
      uid: widget.userId,
      satisfied: (u) => AdRewardWaiter.restoreCredits(u) > creditsBefore,
    );
    if (!mounted) return;

    if (!credited) {
      setState(() {
        _awaitingReward = false;
        // Deliberately not phrased as a failure: the callback is almost always
        // just slow, and the credit is banked on the account rather than on this
        // dialog, so reopening it later will show it.
        _adMessage = 'Your reward is taking a moment. Reopen this in a minute.';
      });
      return;
    }

    // Re-quote rather than patching state locally: the fresh quote carries the
    // new credit, the recomputed cost, and a server-fresh deadline.
    setState(() {
      _awaitingReward = false;
      _adMessage = 'Free restore unlocked!';
      _loadingQuote = true;
    });
    await _loadQuote();
  }

  /// One distinct message per refusal the server can return.
  String _messageFor(StreakRestoreStatus status) {
    switch (status) {
      case StreakRestoreStatus.insufficientPoints:
        return 'Not enough Gup Points to restore this bond.';
      case StreakRestoreStatus.windowExpired:
        return 'The restore window has closed — this bond can no longer be restored.';
      case StreakRestoreStatus.nothingToRestore:
        return 'There\'s no broken bond to restore here.';
      case StreakRestoreStatus.notParticipant:
        return 'You\'re not part of this chat any more.';
      case StreakRestoreStatus.notSignedIn:
        return 'Please sign in again to restore this bond.';
      case StreakRestoreStatus.transportFailure:
        return 'Couldn\'t reach the server. Please try again.';
      case StreakRestoreStatus.success:
        return '';
    }
  }

  /// Retry is offered for the failures that can plausibly succeed next time.
  bool get _isRetryable =>
      _errorStatus == StreakRestoreStatus.transportFailure ||
      _errorStatus == StreakRestoreStatus.notSignedIn;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final urgent = _timeRemaining.inHours < 2;

    return ScaleTransition(
      scale: _scale,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: c.isDark
                  ? [const Color(0xFF2A1A1A), const Color(0xFF1A1020)]
                  : [const Color(0xFFFFF5F5), const Color(0xFFFFF0E0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.red.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Broken heart icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('💔', style: TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Bond Broken!',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.red[400],
                ),
              ),
              const SizedBox(height: 8),

              // Description — count and contact name from the quote
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: c.textMid,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'Your '),
                    TextSpan(
                      text: '$_previousCount-day',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.orange[400],
                      ),
                    ),
                    TextSpan(text: ' bond with $_contactName was broken.\n'),
                    TextSpan(
                      text: _windowExpired
                          ? 'The window to restore it has passed.'
                          : 'Restore it before time runs out!',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Countdown — anchored on the quote's deadline, ticked by ServerClock
              if (_hasCountdown && !_windowExpired)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: c.isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: urgent
                          ? Colors.red.withOpacity(0.3)
                          : Colors.orange.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 18,
                        color: urgent ? Colors.red[400] : Colors.orange[400],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Expires in  ',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: c.textMid,
                        ),
                      ),
                      if (_loadingQuote)
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.orange[400],
                          ),
                        )
                      else
                        Text(
                          _clockTrusted
                              ? _formatDuration(_timeRemaining)
                              : _formatApproximate(_timeRemaining),
                          style: GoogleFonts.poppins(
                            fontSize: _clockTrusted ? 16 : 13,
                            fontWeight: FontWeight.w700,
                            color: urgent ? Colors.red[400] : Colors.orange[400],
                          ),
                        ),
                    ],
                  ),
                ),
              if (_hasCountdown && !_windowExpired) const SizedBox(height: 24),
              if (_windowExpired) const SizedBox(height: 4),

              // Restore button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canConfirm ? _handleRestore : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor:
                        _canConfirm ? Colors.orange[600] : Colors.grey[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: _canConfirm ? 4 : 0,
                    shadowColor: Colors.orange.withOpacity(0.3),
                  ),
                  child: _isRestoring || _loadingQuote
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_isFree ? '✨' : '🔥',
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              _windowExpired
                                  ? 'Window closed'
                                  : _canRestoreFree
                                      ? 'Restore Free (Pro Perk)'
                                      : _hasAdCredit
                                          ? 'Restore Free (ad reward)'
                                          : 'Restore for ⚡$_cost points',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              // Earn the restore instead of paying for it. Offered only when the
              // server says a credit is still earnable this week — the cap is
              // one, so this disappears once used rather than teasing an ad that
              // would pay nothing.
              if (_canOfferAd) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed:
                        (_watchingAd || _awaitingReward) ? null : _watchAdForRestore,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: Colors.orange[400],
                      side: BorderSide(color: Colors.orange.withValues(alpha: 0.45)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: (_watchingAd || _awaitingReward)
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.orange[400],
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_circle_outline_rounded,
                                  size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Watch an ad to restore free',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],

              // Neutral ad status — "on its way", "watch the full ad". Kept out
              // of the red error style below: none of these is a failure the
              // user needs to worry about.
              if (_adMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _adMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: c.textMid,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              // Local affordability hint (server still has the final say)
              if (!_loadingQuote &&
                  !_canAfford &&
                  _errorStatus != StreakRestoreStatus.insufficientPoints) ...[
                const SizedBox(height: 6),
                Text(
                  'Not enough points (you have ⚡${widget.userGupPoints})',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.red[300],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              // One distinct line per server refusal
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.red[300],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_isRetryable) ...[
                  const SizedBox(height: 2),
                  TextButton(
                    onPressed: _isRestoring
                        ? null
                        : () {
                            setState(() {
                              _errorMessage = null;
                              _errorStatus = null;
                              _loadingQuote = true;
                              _quoteUnavailable = false;
                            });
                            _loadQuote();
                          },
                    child: Text(
                      'Try again',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[400],
                      ),
                    ),
                  ),
                ],
              ],

              // Short on points, with no free route left — the one place in the
              // dialog where an ad offer is help rather than an interruption.
              //
              // Suppressed while [_canOfferAd] holds, because that offer buys a
              // whole restore and this one buys ⚡50 towards it: showing both
              // would invite the user to take the worse deal. So this is strictly
              // the fallback for a week whose ad-restore credit is already spent.
              if (!_loadingQuote &&
                  !_canAfford &&
                  !_canOfferAd &&
                  !_windowExpired) ...[
                const SizedBox(height: 12),
                WatchAdForPointsCard(userId: widget.userId, dense: true),
              ],

              if (context.watch<SubscriptionProvider>().isProFeatureVisible &&
                  !context.watch<SubscriptionProvider>().isPro) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PremiumScreen()),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFFFD700).withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.workspace_premium_rounded,
                            color: Color(0xFFFFD700), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Pro members get 1 free restore/week!',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFFD700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),

              // Dismiss button
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Let it go',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: c.textLow,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
