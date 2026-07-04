import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/provider/subscription_provider.dart';
import 'package:video_chat_app/services/subscription_service.dart';
import 'package:video_chat_app/screens/premium_screen.dart';
import 'package:video_chat_app/services/gamification_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// A premium dialog for restoring a broken bond.
///
/// Shows the broken bond count, cost in Gup Points, a countdown timer
/// for the 24-hour restore window, and Restore / Dismiss actions.
class StreakRestoreDialog extends StatefulWidget {
  final int previousStreakCount;
  final DateTime streakBrokenAt;
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
  Duration _timeRemaining = Duration.zero;
  bool _isRestoring = false;
  bool _canRestoreFree = false;

  int get _cost => _canRestoreFree ? 0 : GamificationService.getRestoreCost(widget.previousStreakCount);
  bool get _canAfford => _canRestoreFree || widget.userGupPoints >= _cost;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scale = CurvedAnimation(parent: _anim, curve: Curves.elasticOut);
    _anim.forward();

    _updateTimeRemaining();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeRemaining();
    });
    _checkFreeRestore();
  }

  Future<void> _checkFreeRestore() async {
    final canFree = await SubscriptionService.instance.canRestoreStreakFree();
    if (mounted) setState(() => _canRestoreFree = canFree);
  }

  void _updateTimeRemaining() {
    final expiry = widget.streakBrokenAt.add(const Duration(hours: 24));
    final remaining = expiry.difference(DateTime.now());
    if (remaining.isNegative) {
      // Restore window expired
      if (mounted) Navigator.of(context).pop(false);
      return;
    }
    if (mounted) setState(() => _timeRemaining = remaining);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _handleRestore() async {
    if (_isRestoring || !_canAfford) return;
    setState(() => _isRestoring = true);

    final success = await GamificationService.instance.restoreStreak(
      userId: widget.userId,
      chatRoomId: widget.chatRoomId,
      cost: _cost,
    );

    if (success && _canRestoreFree) {
      await SubscriptionService.instance.recordStreakRestore();
    }

    if (mounted) {
      Navigator.of(context).pop(success);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🤝 Bond restored to ${widget.previousStreakCount} days!',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not restore bond. Please try again.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);

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

              // Description
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
                      text: '${widget.previousStreakCount}-day',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.orange[400],
                      ),
                    ),
                    TextSpan(text: ' bond with ${widget.contactName} was broken.\n'),
                    const TextSpan(text: 'Restore it before time runs out!'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Countdown timer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: c.isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _timeRemaining.inHours < 2
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
                      color: _timeRemaining.inHours < 2
                          ? Colors.red[400]
                          : Colors.orange[400],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Expires in  ',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: c.textMid,
                      ),
                    ),
                    Text(
                      _formatDuration(_timeRemaining),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _timeRemaining.inHours < 2
                            ? Colors.red[400]
                            : Colors.orange[400],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Restore button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canAfford && !_isRestoring ? _handleRestore : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: _canAfford
                        ? Colors.orange[600]
                        : Colors.grey[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: _canAfford ? 4 : 0,
                    shadowColor: Colors.orange.withOpacity(0.3),
                  ),
                  child: _isRestoring
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
                              Text(_canRestoreFree ? '✨' : '🔥', style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(
                                _canRestoreFree
                                    ? 'Restore Free (Pro Perk)'
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

              if (!_canAfford) ...[
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

              if (!context.watch<SubscriptionProvider>().isPro) ...[
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 16),
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
