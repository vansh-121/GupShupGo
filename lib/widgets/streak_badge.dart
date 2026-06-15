import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The risk level of a streak based on how long ago the last mutual message was.
enum StreakRiskLevel {
  /// 0–21 hours: Streak is healthy. Show 🔥 with normal orange glow.
  normal,

  /// 22–35 hours: Streak is at risk. Show ⚠️ with amber pulse.
  atRisk,

  /// 36–47 hours: Streak is critical. Show ⏳ with aggressive red pulse.
  critical,
}

/// Computes the [StreakRiskLevel] from the last mutual interaction date.
StreakRiskLevel computeStreakRisk(DateTime? lastInteractionDate) {
  if (lastInteractionDate == null) return StreakRiskLevel.normal;
  final hoursSince = DateTime.now().difference(lastInteractionDate).inHours;
  if (hoursSince >= 36) return StreakRiskLevel.critical;
  if (hoursSince >= 22) return StreakRiskLevel.atRisk;
  return StreakRiskLevel.normal;
}

/// A self-animating streak badge that displays:
///  - 🔥 N  for normal streaks
///  - ⚠️ N  for at-risk streaks (amber pulsing border)
///  - ⏳ N  for critical streaks (red aggressive pulsing glow)
///
/// Usage:
/// ```dart
/// StreakBadge(streakCount: room.streakCount, lastInteractionDate: room.lastInteractionDate)
/// ```
class StreakBadge extends StatefulWidget {
  final int streakCount;
  final DateTime? lastInteractionDate;

  /// Whether to show the full "N day streak" label or just the count.
  final bool compact;

  const StreakBadge({
    super.key,
    required this.streakCount,
    required this.lastInteractionDate,
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
    if (oldWidget.lastInteractionDate != widget.lastInteractionDate) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    final risk = computeStreakRisk(widget.lastInteractionDate);
    if (risk == StreakRiskLevel.normal) {
      _pulseController.stop();
      _pulseController.value = 1.0;
    } else if (risk == StreakRiskLevel.atRisk) {
      _pulseController.duration = const Duration(milliseconds: 1400);
      _pulseController.repeat(reverse: true);
    } else {
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
    if (widget.streakCount <= 0) return const SizedBox.shrink();

    final risk = computeStreakRisk(widget.lastInteractionDate);

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return _buildBadge(context, risk);
      },
    );
  }

  Widget _buildBadge(BuildContext context, StreakRiskLevel risk) {
    final emoji = switch (risk) {
      StreakRiskLevel.normal => '🔥',
      StreakRiskLevel.atRisk => '⚠️',
      StreakRiskLevel.critical => '⏳',
    };

    final textColor = switch (risk) {
      StreakRiskLevel.normal => Colors.orange[400]!,
      StreakRiskLevel.atRisk => Colors.amber[600]!,
      StreakRiskLevel.critical => Colors.red[400]!,
    };

    final bgColor = switch (risk) {
      StreakRiskLevel.normal => Colors.orange.withOpacity(0.12),
      StreakRiskLevel.atRisk => Colors.amber.withOpacity(0.12),
      StreakRiskLevel.critical => Colors.red.withOpacity(0.12 * _pulseAnim.value),
    };

    final borderColor = switch (risk) {
      StreakRiskLevel.normal => Colors.orange.withOpacity(0.25),
      StreakRiskLevel.atRisk => Colors.amber.withOpacity(0.4 * _pulseAnim.value),
      StreakRiskLevel.critical => Colors.red.withOpacity(0.5 * _pulseAnim.value),
    };

    final glowColor = switch (risk) {
      StreakRiskLevel.normal => null,
      StreakRiskLevel.atRisk =>
        Colors.amber.withOpacity(0.12 * _pulseAnim.value),
      StreakRiskLevel.critical =>
        Colors.red.withOpacity(0.25 * _pulseAnim.value),
    };

    final label = widget.compact
        ? '${widget.streakCount}'
        : '${widget.streakCount} day streak';

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
            label,
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
}

// ─── Arcade Card Variant ─────────────────────────────────────────────────────
// Larger badge used in the Gup Arcade streak cards (overlaid on avatar)

/// A larger arc-style badge overlay for the Gup Arcade streak cards.
class StreakArcadeBadge extends StatefulWidget {
  final int streakCount;
  final DateTime? lastInteractionDate;

  const StreakArcadeBadge({
    super.key,
    required this.streakCount,
    required this.lastInteractionDate,
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
    if (oldWidget.lastInteractionDate != widget.lastInteractionDate) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    final risk = computeStreakRisk(widget.lastInteractionDate);
    if (risk == StreakRiskLevel.normal) {
      _pulseController.stop();
      _pulseController.value = 1.0;
    } else if (risk == StreakRiskLevel.atRisk) {
      _pulseController.duration = const Duration(milliseconds: 1400);
      _pulseController.repeat(reverse: true);
    } else {
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
    final risk = computeStreakRisk(widget.lastInteractionDate);

    final emoji = switch (risk) {
      StreakRiskLevel.normal => '🔥',
      StreakRiskLevel.atRisk => '⚠️',
      StreakRiskLevel.critical => '⏳',
    };

    final gradientColors = switch (risk) {
      StreakRiskLevel.normal => [const Color(0xFFFF8008), const Color(0xFFFFC837)],
      StreakRiskLevel.atRisk => [const Color(0xFFFFB300), const Color(0xFFFFD54F)],
      StreakRiskLevel.critical => [const Color(0xFFFF6B6B), const Color(0xFFEE5A5A)],
    };

    final glowColor = switch (risk) {
      StreakRiskLevel.normal => Colors.orange,
      StreakRiskLevel.atRisk => Colors.amber,
      StreakRiskLevel.critical => Colors.red,
    };

    final subtitle = switch (risk) {
      StreakRiskLevel.normal => null,
      StreakRiskLevel.atRisk => 'At risk!',
      StreakRiskLevel.critical => 'Send now!',
    };

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
                      risk == StreakRiskLevel.normal
                          ? 0.35
                          : 0.35 + 0.3 * _pulseAnim.value,
                    ),
                    blurRadius: risk == StreakRiskLevel.normal
                        ? 6
                        : 6 + 8 * _pulseAnim.value,
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
                    '${widget.streakCount}',
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
                  color: risk == StreakRiskLevel.critical
                      ? Colors.red[400]
                      : Colors.amber[700],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
