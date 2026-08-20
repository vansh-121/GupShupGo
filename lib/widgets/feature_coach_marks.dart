// FeatureCoachMarks — one-at-a-time spotlight tips for entry points that are
// invisible without them.
//
// Two features ship behind affordances that give no hint of what they do:
//   • the cell-tower icon in the Home app bar → offline mesh chat
//   • the "⚡ 0" chip at the bottom-left of Home → Gup Arcade / streaks
// The chip in particular reads as a decorative score badge rather than a
// button, so users do not discover the Arcade at all.
//
// Each mark carries its OWN SharedPreferences key rather than sharing one
// "coaching done" flag. That way a mark added in a later release shows up for
// existing users without re-showing the ones they have already dismissed.
// Keys are version-suffixed so a deliberate redesign can re-teach a feature.
//
// Targets are located from a GlobalKey attached to the real widget, so the
// spotlight tracks the actual laid-out position instead of hardcoded offsets —
// it stays correct across screen sizes, text scale, and notch/safe-area
// differences. If a target is not currently on screen its mark is skipped
// (left unseen) and retried on a later launch.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/main.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// Pref keys. Bump the version suffix to intentionally re-show a mark.
const String kCoachMeshKey = 'coach_v1_mesh';
const String kCoachArcadeKey = 'coach_v1_arcade';

class CoachMark {
  const CoachMark({
    required this.prefKey,
    required this.targetKey,
    required this.icon,
    required this.title,
    required this.body,
  });

  final String prefKey;
  final GlobalKey targetKey;
  final IconData icon;
  final String title;
  final String body;
}

/// Shows every not-yet-seen mark in order, waiting for each to be dismissed.
///
/// Safe to call unconditionally on every Home launch: marks already seen are
/// filtered out, and if none remain this returns without building anything.
/// Call it only once the Navigator is settled — after any blocking startup
/// dialog (vault PIN, What's New) and after any deep-link route has been
/// pushed, otherwise the spotlight would dim a screen the user is no longer
/// looking at.
Future<void> showCoachMarks(
  BuildContext context,
  List<CoachMark> marks,
) async {
  final pending =
      marks.where((m) => !(sharedPrefs.getBool(m.prefKey) ?? false)).toList();
  if (pending.isEmpty) return;

  for (var i = 0; i < pending.length; i++) {
    final mark = pending[i];
    if (!context.mounted) return;

    final rect = _targetRect(mark.targetKey);
    // Target is not mounted / not laid out (e.g. the Arcade chip before
    // _currentUserId resolves). Leave the flag unset so we try again next
    // launch rather than burning the tip on nothing.
    if (rect == null) continue;

    final keepGoing = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      // The scrim is painted by _SpotlightScrim so it can punch a hole; the
      // route's own barrier must stay clear or it would dim the cutout too.
      barrierColor: Colors.transparent,
      barrierLabel: mark.title,
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
      pageBuilder: (_, __, ___) => _CoachMarkOverlay(
        mark: mark,
        targetRect: rect,
        isLast: i == pending.length - 1,
      ),
    );

    await sharedPrefs.setBool(mark.prefKey, true);

    // "Skip tips" — retire the rest too, so declining once is respected
    // instead of resurfacing the remainder on the next launch.
    if (keepGoing == false) {
      for (final rest in pending.skip(i + 1)) {
        await sharedPrefs.setBool(rest.prefKey, true);
      }
      return;
    }
  }
}

/// Global (screen-space) bounds of a keyed widget, or null if it is not
/// currently laid out.
Rect? _targetRect(GlobalKey key) {
  final ctx = key.currentContext;
  if (ctx == null) return null;
  final box = ctx.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  final origin = box.localToGlobal(Offset.zero);
  return Rect.fromLTWH(origin.dx, origin.dy, box.size.width, box.size.height);
}

class _CoachMarkOverlay extends StatefulWidget {
  const _CoachMarkOverlay({
    required this.mark,
    required this.targetRect,
    required this.isLast,
  });

  final CoachMark mark;
  final Rect targetRect;
  final bool isLast;

  @override
  State<_CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<_CoachMarkOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _next() => Navigator.of(context).pop(true);
  void _skip() => Navigator.of(context).pop(false);

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final screen = MediaQuery.of(context).size;

    // Breathing room around the target so the widget is not flush with the
    // cutout edge.
    final hole = widget.targetRect.inflate(10);
    // Circle for square-ish targets (the app-bar icon), stadium for wide ones
    // (the Arcade chip) — falls out of using half the shortest side.
    final radius = Radius.circular(hole.shortestSide / 2);

    // Place the caption on whichever side of the target has more room. The
    // app-bar icon sits high (card below); the Arcade chip sits low (above).
    final below = hole.center.dy < screen.height / 2;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // ── Dimmed scrim with the target punched out ──────────────────
          // Tapping anywhere on the scrim advances, which is the gesture
          // people already expect from this pattern.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _next,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => CustomPaint(
                  painter: _SpotlightScrim(
                    hole: hole,
                    radius: radius,
                    ringColor: c.primary,
                    pulse: _pulse.value,
                  ),
                ),
              ),
            ),
          ),

          // ── Caption card ──────────────────────────────────────────────
          Positioned(
            left: 20,
            right: 20,
            top: below ? hole.bottom + 18 : null,
            bottom: below ? null : (screen.height - hole.top) + 18,
            child: _CaptionCard(
              mark: widget.mark,
              isLast: widget.isLast,
              onNext: _next,
              onSkip: _skip,
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptionCard extends StatelessWidget {
  const _CaptionCard({
    required this.mark,
    required this.isLast,
    required this.onNext,
    required this.onSkip,
  });

  final CoachMark mark;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.primary.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.primary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(mark.icon, color: c.primary, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mark.title,
                      style: GoogleFonts.poppins(
                        color: c.textHigh,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      mark.body,
                      style: GoogleFonts.poppins(
                        color: c.textMid,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Hidden on the final mark: there is nothing left to skip, and
              // offering both "Skip" and "Got it" for the same outcome reads
              // as a trick question.
              if (!isLast)
                TextButton(
                  onPressed: onSkip,
                  child: Text(
                    'Skip tips',
                    style: GoogleFonts.poppins(
                      color: c.textLow,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              TextButton(
                onPressed: onNext,
                child: Text(
                  isLast ? 'Got it' : 'Next',
                  style: GoogleFonts.poppins(
                    color: c.primary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Paints a full-screen dim with [hole] cut out of it, plus a pulsing ring
/// around the cutout.
class _SpotlightScrim extends CustomPainter {
  const _SpotlightScrim({
    required this.hole,
    required this.radius,
    required this.ringColor,
    required this.pulse,
  });

  final Rect hole;
  final Radius radius;
  final Color ringColor;

  /// 0→1, drives ring thickness/opacity so the target visibly breathes.
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(hole, radius);

    // Dim everything except the target. difference() keeps the cutout fully
    // transparent, so the real widget underneath shows at full fidelity.
    final scrim = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()..addRRect(rrect),
    );
    canvas.drawPath(scrim, Paint()..color = Colors.black.withOpacity(0.72));

    // Pulsing ring — the cutout alone can be hard to spot against a busy
    // app bar, and motion is what actually draws the eye.
    canvas.drawRRect(
      RRect.fromRectAndRadius(hole.inflate(pulse * 5), radius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 + pulse
        ..color = ringColor.withOpacity(0.85 - pulse * 0.45),
    );
  }

  @override
  bool shouldRepaint(_SpotlightScrim old) =>
      old.hole != hole || old.pulse != pulse || old.ringColor != ringColor;
}
