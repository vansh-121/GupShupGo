/// GupShupGo — GupShup AI assistant chat screen.
///
/// A self-contained you↔AI conversation. Deliberately NOT built on `ChatScreen`
/// or `ChatService`: those are ~70 imports deep and welded to Signal, call
/// signalling, streaks and notifications. This surface talks only to
/// [AiAssistantService], whose transcript lives in the local [PlaintextStore]
/// under [kAiRoomId] — no Firestore message docs, no E2EE session, no streak
/// side effects, and it clears on sign-out with the rest of the local cache.
///
/// Cost is enforced server-side (`askGupShupAi` + `config/ai`), never here. When
/// the daily allowance is spent the server answers 429 and this screen offers a
/// rewarded-ad top-up (and an upgrade path when Pro surfaces are visible); the
/// ad is paid out by `admobSsv`, exactly like the Gup Points card, so the client
/// still can't grant itself anything.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/provider/subscription_provider.dart';
import 'package:video_chat_app/screens/premium_screen.dart';
import 'package:video_chat_app/services/ads/ad_reward_waiter.dart';
import 'package:video_chat_app/services/ads/ads_service.dart';
import 'package:video_chat_app/services/ads/rewarded_ad_service.dart';
import 'package:video_chat_app/services/ai/ai_assistant_service.dart';
import 'package:video_chat_app/services/feature_flag_service.dart';
import 'package:video_chat_app/services/streak/server_clock.dart';
import 'package:video_chat_app/services/streak/streak_day.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// SharedPreferences flag for the one-time GupAI introduction notice. Versioned so
/// the notice can be re-shown if the wording materially changes.
const String _kAiNoticeSeenKey = 'ai_first_run_notice_seen_v1';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _service = AiAssistantService.instance;
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  final _composerFocus = FocusNode();

  /// A reply is in flight — drives the typing-dots bubble and locks the sender.
  bool _sending = false;

  /// Tracks the rendered item count so we only auto-scroll when the transcript
  /// actually grows (not on every unrelated stream re-emit).
  int _lastItemCount = 0;

  /// Today's remaining / total AI message allowance, surfaced as the app-bar
  /// chip. Both null until the first read lands, so the chip stays hidden until
  /// there is a real number to show. Computed on open and after a top-up from
  /// the Remote Config caps + the server-written `aiDaily` / `aiRewardDaily`
  /// counters, and refreshed from the server's authoritative `remaining` after
  /// every reply. See [_refreshQuota].
  int? _remaining;
  int? _allocated;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    // Warm a rewarded ad up front so the quota top-up — if the user hits the
    // cap — is an instant watch rather than a spinner. This is a full screen,
    // so (like the Arcade) it's a fair place to resolve ad consent too.
    unawaited(AdsService.instance.ensureConsent());
    unawaited(RewardedAdService.instance.preload());
    unawaited(_refreshQuota());
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowNotice());
  }

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    _composerFocus.dispose();
    // Drop the warmed ad so an unwatched one doesn't go stale behind us.
    RewardedAdService.instance.disposeAd();
    super.dispose();
  }

  // ── First-run privacy notice ───────────────────────────────────────────────

  Future<void> _maybeShowNotice() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kAiNoticeSeenKey) == true) return;
    if (!mounted) return;

    final c = AppThemeColors.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: c.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Meet GupAI',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: c.textHigh,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Ask GupAI to draft replies, translate, summarise, brainstorm, '
          'or answer questions.\n\n'
          'Messages you send here are processed by GupAI to generate replies. This '
          'is separate from your chats with people, which stay end-to-end '
          'encrypted and are never shared.',
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            height: 1.5,
            color: c.textMid,
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: c.primary),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Got it',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    await prefs.setBool(_kAiNoticeSeenKey, true);
  }

  // ── Sending ─────────────────────────────────────────────────────────────────

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty || _sending) return;

    _composer.clear();
    setState(() => _sending = true);
    _scrollToBottom();

    final result = await _service.sendMessage(text);
    if (!mounted) return;
    setState(() => _sending = false);
    _handleResult(result);
  }

  void _handleResult(AiSendResult result) {
    switch (result) {
      case AiReplyReceived(:final remaining):
        // The server's post-send remaining is authoritative — adopt it, and
        // nudge the cached allocation up if it somehow trails (e.g. the on-open
        // estimate under-counted a Pro cap or a top-up).
        setState(() {
          _remaining = remaining;
          if (_allocated == null || remaining > _allocated!) {
            _allocated = remaining;
          }
        });
        _scrollToBottom();
        if (remaining >= 0 && remaining <= 3) {
          _toast(
            remaining == 0
                ? 'That was your last message for today.'
                : '$remaining message${remaining == 1 ? '' : 's'} left today.',
          );
        }
      case AiQuotaExceeded(:final isPro, :final canEarn):
        setState(() => _remaining = 0);
        _showQuotaSheet(isPro: isPro, canEarn: canEarn);
      case AiBusy():
        _toast('GupAI is busy right now. Please try again in a moment.');
      case AiSendFailed(:final message):
        _toast(
          message == 'not-signed-in'
              ? 'Please sign in to use GupAI.'
              : 'Couldn\'t reach GupAI. Check your connection and retry.',
        );
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
      ));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ── Quota top-up sheet ───────────────────────────────────────────────────────

  void _showQuotaSheet({required bool isPro, required bool canEarn}) {
    final c = AppThemeColors.of(context);
    final flags = FeatureFlagService.instance;
    final reward = flags.aiRewardCredits;
    final canWatch = canEarn && AdsService.instance.canShowRewarded;
    // `isProFeatureVisible` is `pro_enabled`: with it off there is nothing to
    // sell, so the upgrade affordance stays hidden rather than leading to a
    // dead end. A genuine Pro holder who somehow hit this never sees it either.
    final showUpgrade =
        !isPro && context.read<SubscriptionProvider>().isProFeatureVisible;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        var adBusy = false;
        var statusLine = isPro
            ? 'You\'ve used all of today\'s messages. They reset tomorrow.'
            : 'You\'ve used today\'s free messages.';

        return StatefulBuilder(
          builder: (sheetCtx, setSheet) {
            Future<void> watchAd() async {
              final uid = _uid;
              if (uid == null || adBusy) return;
              setSheet(() {
                adBusy = true;
                statusLine = 'Loading an ad…';
              });

              final todayKey = StreakDay.fromInstant(ServerClock.now()).key;
              var baseline = 0;
              try {
                final snap = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .get();
                baseline = _aiRewardCountToday(snap.data(), todayKey);
              } catch (_) {}

              final outcome = await RewardedAdService.instance.show(
                uid: uid,
                type: AdRewardType.aiCredit,
              );

              if (outcome != RewardedAdOutcome.earned) {
                setSheet(() {
                  adBusy = false;
                  statusLine = switch (outcome) {
                    RewardedAdOutcome.dismissedEarly =>
                      'Watch the full ad to unlock more messages.',
                    RewardedAdOutcome.unavailable =>
                      'Ads aren\'t available right now.',
                    _ => 'Couldn\'t load an ad. Please try again shortly.',
                  };
                });
                return;
              }

              setSheet(() => statusLine = 'Unlocking your messages…');
              final credited = await AdRewardWaiter.awaitCredit(
                uid: uid,
                satisfied: (u) => _aiRewardCountToday(u, todayKey) > baseline,
              );

              if (!credited) {
                setSheet(() {
                  adBusy = false;
                  statusLine =
                      'Your reward is taking a moment — try again shortly.';
                });
                return;
              }

              // Credit landed. Close the sheet and answer the pending question
              // automatically (retryLast re-asks it without a duplicate bubble).
              if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
              await _retryAfterTopUp();
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: 20 + MediaQuery.of(sheetCtx).viewInsets.bottom,
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
                    statusLine,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.45,
                      color: c.textMid,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (canWatch)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: c.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: adBusy ? null : watchAd,
                      icon: adBusy
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
                        adBusy ? 'Please wait…' : 'Watch an ad for +$reward',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  if (canWatch && showUpgrade) const SizedBox(height: 10),
                  if (showUpgrade)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.primary,
                        side: BorderSide(
                          color: c.primary.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: adBusy
                          ? null
                          : () {
                              Navigator.of(sheetCtx).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const PremiumScreen(),
                                ),
                              );
                            },
                      icon: const Icon(Icons.workspace_premium_rounded),
                      label: Text(
                        'Upgrade to Pro for more',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  if (!canWatch && !showUpgrade) const SizedBox(height: 2),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed:
                        adBusy ? null : () => Navigator.of(sheetCtx).pop(),
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
          },
        );
      },
    );
  }

  /// Re-ask the pending question after a successful top-up, with the typing
  /// bubble showing again.
  Future<void> _retryAfterTopUp() async {
    if (!mounted) return;
    setState(() => _sending = true);
    _scrollToBottom();
    final result = await _service.retryLast();
    if (!mounted) return;
    setState(() => _sending = false);
    _handleResult(result);
    // The top-up raised today's allocation; re-read so the chip's total (not
    // just its remaining, which _handleResult already took from the reply)
    // reflects the extra credits.
    unawaited(_refreshQuota());
  }

  /// Reads today's AI usage from the user doc and recomputes the app-bar chip's
  /// remaining / allocated. Fire-and-forget: a failed read just leaves the last
  /// known values (or keeps the chip hidden if we never had any).
  ///
  /// Allocation mirrors the server's `aiAllowance`: a Pro-or-free base plus the
  /// rewarded top-ups earned today. The base uses [SubscriptionProvider.hasActiveProEntitlement]
  /// — the real paid entitlement, which is what the server's `isProUser` keys
  /// off — not `isPro`, which `pro_enabled` deliberately inverts. The caps are
  /// the Remote Config "advertised" mirrors of `config/ai`; they are meant to
  /// match it, and any drift self-corrects from the server's `remaining` on the
  /// next reply.
  Future<void> _refreshQuota() async {
    final uid = _uid;
    if (uid == null) return;
    final isPro = context.read<SubscriptionProvider>().hasActiveProEntitlement;
    final flags = FeatureFlagService.instance;
    final todayKey = StreakDay.fromInstant(ServerClock.now()).key;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = snap.data();
      final base = isPro ? flags.aiProDailyCap : flags.aiFreeDailyCap;
      final topUps = _aiRewardCountToday(data, todayKey);
      final used = _aiDailyCountToday(data, todayKey);
      final allocated = base + topUps * flags.aiRewardCredits;
      final remaining = (allocated - used).clamp(0, allocated);
      if (mounted) {
        setState(() {
          _allocated = allocated;
          _remaining = remaining;
        });
      }
    } catch (_) {
      // Keep whatever we last showed.
    }
  }

  /// Today's charged AI message count from the server-written `aiDaily` counter,
  /// read with the same canonical day key `askGupShupAi` stamps so a device in
  /// another timezone doesn't disagree. A bucket from any other day reads as 0.
  int _aiDailyCountToday(Map<String, dynamic>? user, String todayKey) {
    final daily = user?['aiDaily'];
    if (daily is! Map) return 0;
    if (daily['dayKey'] != todayKey) return 0;
    final count = daily['count'];
    return count is num ? count.toInt() : 0;
  }

  /// Today's rewarded-AI top-up count from the server-written counter, read with
  /// the same canonical day key `admobSsv` uses so a device in another timezone
  /// doesn't disagree. A bucket from any other day reads as 0.
  int _aiRewardCountToday(Map<String, dynamic>? user, String todayKey) {
    final daily = user?['aiRewardDaily'];
    if (daily is! Map) return 0;
    if (daily['dayKey'] != todayKey) return 0;
    final count = daily['count'];
    return count is num ? count.toInt() : 0;
  }

  /// The app-bar "N left today" pill. Hidden until the first quota read lands,
  /// so it never flashes a wrong number. Colour tracks urgency: brand normally,
  /// [AppThemeColors.warning] at ≤3, [AppThemeColors.error] at 0. Tapping opens
  /// [_showQuotaInfo] with the full breakdown.
  Widget _buildQuotaChip(AppThemeColors c) {
    final remaining = _remaining;
    if (remaining == null) return const SizedBox.shrink();
    final color =
        remaining == 0 ? c.error : (remaining <= 3 ? c.warning : c.primary);
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: _showQuotaInfo,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withValues(alpha: 0.30)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 14, color: color),
                const SizedBox(width: 3),
                Text(
                  '$remaining left',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Icon(Icons.expand_more_rounded, size: 15, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A compact breakdown of today's allowance: how many are left of the day's
  /// total, a used/total bar, and the reset note. Reached from the app-bar chip.
  void _showQuotaInfo() {
    final remaining = _remaining;
    if (remaining == null) return;
    // Never render "N of <M<N>>": if the client cap estimate trails the
    // server's remaining, show the remaining as the total instead.
    final allocated = (_allocated == null || _allocated! < remaining)
        ? remaining
        : _allocated!;
    final used = (allocated - remaining).clamp(0, allocated);
    final c = AppThemeColors.of(context);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.bolt_rounded, color: c.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'GupAI messages',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: c.textHigh,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$remaining of $allocated left today',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.textHigh,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: allocated == 0 ? 0 : used / allocated,
                minHeight: 7,
                backgroundColor: c.surfaceAlt,
                valueColor: AlwaysStoppedAnimation<Color>(
                  remaining == 0 ? c.error : c.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Used $used today · resets tomorrow. Watch an ad or go Pro for more.',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                height: 1.4,
                color: c.textMid,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Got it',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: c.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);

    return Scaffold(
      backgroundColor: c.chatBg,
      appBar: AppBar(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [c.primary, c.primaryDk],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'GupAI',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: c.textHigh,
                  ),
                ),
                Text(
                  'Your in-app assistant',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: c.textMid,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [_buildQuotaChip(c)],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _service.watchTranscript(),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? const <MessageModel>[];
                final itemCount = messages.length + (_sending ? 1 : 0);

                if (itemCount != _lastItemCount) {
                  _lastItemCount = itemCount;
                  _scrollToBottom();
                }

                if (messages.isEmpty && !_sending) {
                  return _EmptyState(
                    onPickPrompt: (prompt) {
                      _composer.text = prompt;
                      _composer.selection = TextSelection.collapsed(
                        offset: prompt.length,
                      );
                      _composerFocus.requestFocus();
                    },
                  );
                }

                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  itemCount: itemCount,
                  itemBuilder: (context, i) {
                    if (_sending && i == messages.length) {
                      return const _TypingBubble();
                    }
                    final m = messages[i];
                    return _MessageBubble(
                      message: m,
                      isUser: m.senderId == _uid,
                    );
                  },
                );
              },
            ),
          ),
          _Composer(
            controller: _composer,
            focusNode: _composerFocus,
            enabled: !_sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Composer
// ─────────────────────────────────────────────────────────────────────────────

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.divider)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 140),
                decoration: BoxDecoration(
                  color: c.surfaceAlt,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: c.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  style: GoogleFonts.poppins(fontSize: 14, color: c.textHigh),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Ask GupAI anything…',
                    hintStyle:
                        GoogleFonts.poppins(fontSize: 14, color: c.textLow),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: enabled ? onSend : null,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: enabled ? c.primary : c.primary.withValues(alpha: 0.4),
                ),
                child: const Icon(Icons.arrow_upward_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bubbles
// ─────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isUser});

  final MessageModel message;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final bg = isUser ? c.sent : c.received;
    final fg = isUser ? Colors.white : c.textHigh;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
        ),
        child: SelectableText.rich(
          TextSpan(
            children: _inlineSpans(
              _normalizeMarkdown(message.text),
              GoogleFonts.poppins(fontSize: 14, height: 1.42, color: fg),
            ),
          ),
        ),
      ),
    );
  }
}

/// A compact light-Markdown renderer — no package dependency, no `RegExp`.
/// Handles the two things Gemini emits most: `**bold**` inline, and `-`/`*`
/// bullet lines (which are normalised to `•`). Everything else renders
/// verbatim, which is the safe direction: an unparsed marker is readable, a
/// mis-parsed one is not.
String _normalizeMarkdown(String raw) {
  final lines = raw.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    var j = 0;
    while (j < line.length && (line[j] == ' ' || line[j] == '\t')) {
      j++;
    }
    // A bullet is '-' or '*' followed by a space. Requiring the space is what
    // keeps `**bold**` or `*italic*` at the start of a line from being eaten.
    final isBullet = j < line.length &&
        (line[j] == '-' || line[j] == '*') &&
        j + 1 < line.length &&
        line[j + 1] == ' ';
    if (isBullet) {
      final indent = line.substring(0, j);
      final rest = line.substring(j + 2).trimLeft();
      lines[i] = '$indent•  $rest';
    }
  }
  return lines.join('\n');
}

List<InlineSpan> _inlineSpans(String text, TextStyle base) {
  final spans = <InlineSpan>[];
  final bold = base.copyWith(fontWeight: FontWeight.w700);
  var i = 0;
  while (i < text.length) {
    final open = text.indexOf('**', i);
    if (open < 0) {
      spans.add(TextSpan(text: text.substring(i), style: base));
      break;
    }
    final close = text.indexOf('**', open + 2);
    if (close < 0) {
      // No closing delimiter — the rest is plain text.
      spans.add(TextSpan(text: text.substring(i), style: base));
      break;
    }
    if (open > i) {
      spans.add(TextSpan(text: text.substring(i, open), style: base));
    }
    final inner = text.substring(open + 2, close);
    // '****' with nothing between renders literally rather than as an empty
    // bold run.
    spans.add(inner.isEmpty
        ? TextSpan(text: '****', style: base)
        : TextSpan(text: inner, style: bold));
    i = close + 2;
  }
  if (spans.isEmpty) spans.add(TextSpan(text: text, style: base));
  return spans;
}

/// The "AI is typing" bubble: three dots that fade in sequence.
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.received,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                // Stagger each dot a third of a cycle apart.
                final t = (_ctrl.value + i * 0.33) % 1.0;
                final opacity = 0.3 + 0.7 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
                return Padding(
                  padding: EdgeInsets.only(right: i == 2 ? 0 : 5),
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: c.textMid,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPickPrompt});

  final ValueChanged<String> onPickPrompt;

  static const _prompts = <(String, String)>[
    ('✍️', 'Help me reply to a message politely'),
    ('🌍', 'Translate "How are you?" to Spanish'),
    ('💡', 'Give me 3 fun weekend plan ideas'),
    ('📝', 'Summarise this text for me:'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [c.primary, c.primaryDk],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'How can I help?',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: c.textHigh,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Draft replies, translate, summarise, brainstorm, or just ask a '
          'question. Tap an idea to start.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 13,
            height: 1.5,
            color: c.textMid,
          ),
        ),
        const SizedBox(height: 24),
        ..._prompts.map((p) {
          final (emoji, text) = p;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onPickPrompt(text),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: c.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        text,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          color: c.textHigh,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 13, color: c.textLow),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
