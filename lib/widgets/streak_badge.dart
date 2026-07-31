import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/streak/streak_repository.dart';
import '../services/streak/streak_state.dart';

export '../services/streak/streak_state.dart' show StreakRiskLevel;

/// Formats a remaining duration as a compact string:
///  - "12h" if > 6 hours remaining
///  - "2:05" (H:MM) if between 1-6 hours
///  - "45m" if < 1 hour remaining
String formatTimeRemaining(Duration d) {
  if (d.inHours >= 6) return '${d.inHours}h';
  if (d.inHours >= 1) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '$h:$m';
  }
  return '${d.inMinutes}m';
}

/// A bond badge that displays:
///  - 🔥 N  for normal bonds
///  - ⚠️ N · Xh left  for at-risk bonds (amber pulsing border)
///  - ⏳ N · X:MM  for critical bonds (red aggressive pulsing glow)
///  - 💔 N  for a lapsed bond still inside its restore window
///
/// Every number and every instant comes from the [StreakView]: the countdown is
/// `deadlineAt - view.evaluatedAt`, never `DateTime.now()`. `StreakRepository`
/// re-derives the view once a minute, which is what makes the countdown tick.
/// When [StreakView.canShowCountdown] is false (untrusted clock or a stale
/// observation) the countdown text is suppressed, while the server-stamped
/// count and risk level still render.
///
/// Usage:
/// ```dart
/// StreakBadge(view: streakView, compact: false)
/// ```
class StreakBadge extends StatefulWidget {
  final StreakView view;

  /// Whether to show the full "N day bond" label or just the count.
  final bool compact;

  const StreakBadge({
    super.key,
    required this.view,
    this.compact = true,
  });

  @override
  State<StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends State<StreakBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(StreakBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.view.riskLevel != widget.view.riskLevel) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    switch (widget.view.riskLevel) {
      case StreakRiskLevel.normal:
      case StreakRiskLevel.broken:
        _pulseController.stop();
        _pulseController.value = 1.0;
      case StreakRiskLevel.atRisk:
        _pulseController.duration = const Duration(milliseconds: 1400);
        _pulseController.repeat(reverse: true);
      case StreakRiskLevel.critical:
        // Critical: faster pulse
        _pulseController.duration = const Duration(milliseconds: 650);
        _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.view.hasBadge) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return _buildBadge(context, widget.view.riskLevel);
      },
    );
  }

  Widget _buildBadge(BuildContext context, StreakRiskLevel risk) {
    final emoji = switch (risk) {
      StreakRiskLevel.normal => '🔥',
      StreakRiskLevel.atRisk => '⚠️',
      StreakRiskLevel.critical => '⏳',
      StreakRiskLevel.broken => '💔',
    };

    final textColor = switch (risk) {
      StreakRiskLevel.normal => Colors.orange[400]!,
      StreakRiskLevel.atRisk => Colors.amber[600]!,
      StreakRiskLevel.critical => Colors.red[400]!,
      StreakRiskLevel.broken => Colors.red[400]!,
    };

    final bgColor = switch (risk) {
      StreakRiskLevel.normal => Colors.orange.withOpacity(0.12),
      StreakRiskLevel.atRisk => Colors.amber.withOpacity(0.12),
      StreakRiskLevel.critical =>
        Colors.red.withOpacity(0.12 * _pulseAnim.value),
      StreakRiskLevel.broken => Colors.red.withOpacity(0.12),
    };

    final borderColor = switch (risk) {
      StreakRiskLevel.normal => Colors.orange.withOpacity(0.25),
      StreakRiskLevel.atRisk =>
        Colors.amber.withOpacity(0.4 * _pulseAnim.value),
      StreakRiskLevel.critical =>
        Colors.red.withOpacity(0.5 * _pulseAnim.value),
      StreakRiskLevel.broken => Colors.red.withOpacity(0.25),
    };

    final glowColor = switch (risk) {
      StreakRiskLevel.normal => null,
      StreakRiskLevel.atRisk =>
        Colors.amber.withOpacity(0.12 * _pulseAnim.value),
      StreakRiskLevel.critical =>
        Colors.red.withOpacity(0.25 * _pulseAnim.value),
      StreakRiskLevel.broken => null,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: glowColor != null
            ? [
                BoxShadow(
                  color: glowColor,
                  blurRadius: 6 * _pulseAnim.value,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 2),
          Text(
            _label(risk),
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// The badge text. The countdown is appended only for a bond that is both
  /// at risk and safe to count down (trusted clock, fresh observation).
  String _label(StreakRiskLevel risk) {
    final view = widget.view;
    if (risk == StreakRiskLevel.broken) return '${view.restorableCount}';
    if (risk == StreakRiskLevel.normal) {
      return widget.compact ? '${view.count}' : '${view.count} day bond';
    }
    if (view.canShowCountdown) {
      final remaining = view.timeRemaining;
      if (remaining != null && remaining > Duration.zero) {
        return '${view.count} · ${formatTimeRemaining(remaining)}';
      }
    }
    return '${view.count}';
  }
}

// ─── Arcade Card Variant ─────────────────────────────────────────────────────────────
// Larger badge used in the Gup Arcade bond cards (overlaid on avatar)

/// A larger arc-style badge overlay for the Gup Arcade bond cards.
class StreakArcadeBadge extends StatefulWidget {
  final StreakView view;

  const StreakArcadeBadge({
    super.key,
    required this.view,
  });

  @override
  State<StreakArcadeBadge> createState() => _StreakArcadeBadgeState();
}

class _StreakArcadeBadgeState extends State<StreakArcadeBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(StreakArcadeBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.view.riskLevel != widget.view.riskLevel) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    switch (widget.view.riskLevel) {
      case StreakRiskLevel.normal:
      case StreakRiskLevel.broken:
        _pulseController.stop();
        _pulseController.value = 1.0;
      case StreakRiskLevel.atRisk:
        _pulseController.duration = const Duration(milliseconds: 1400);
        _pulseController.repeat(reverse: true);
      case StreakRiskLevel.critical:
        _pulseController.duration = const Duration(milliseconds: 600);
        _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final risk = widget.view.riskLevel;
    final pulsing = risk == StreakRiskLevel.atRisk ||
        risk == StreakRiskLevel.critical;

    final emoji = switch (risk) {
      StreakRiskLevel.normal => '🔥',
      StreakRiskLevel.atRisk => '⚠️',
      StreakRiskLevel.critical => '⏳',
      StreakRiskLevel.broken => '💔',
    };

    final gradientColors = switch (risk) {
      StreakRiskLevel.normal => [
          const Color(0xFFFF8008),
          const Color(0xFFFFC837)
        ],
      StreakRiskLevel.atRisk => [
          const Color(0xFFFFB300),
          const Color(0xFFFFD54F)
        ],
      StreakRiskLevel.critical => [
          const Color(0xFFFF6B6B),
          const Color(0xFFEE5A5A)
        ],
      StreakRiskLevel.broken => [
          const Color(0xFFFF6B6B),
          const Color(0xFFEE5A5A)
        ],
    };

    final glowColor = switch (risk) {
      StreakRiskLevel.normal => Colors.orange,
      StreakRiskLevel.atRisk => Colors.amber,
      StreakRiskLevel.critical => Colors.red,
      StreakRiskLevel.broken => Colors.red,
    };

    final subtitle = switch (risk) {
      StreakRiskLevel.normal => null,
      StreakRiskLevel.atRisk => 'At risk!',
      StreakRiskLevel.critical => 'Send now!',
      StreakRiskLevel.broken => 'Restore?',
    };

    final count = widget.view.count > 0
        ? widget.view.count
        : widget.view.restorableCount;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, _) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withOpacity(
                      pulsing ? 0.35 + 0.3 * _pulseAnim.value : 0.35,
                    ),
                    blurRadius: pulsing ? 6 + 8 * _pulseAnim.value : 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 10)),
                  const SizedBox(width: 1),
                  Text(
                    '$count',
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: risk == StreakRiskLevel.atRisk
                      ? Colors.amber[700]
                      : Colors.red[400],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
