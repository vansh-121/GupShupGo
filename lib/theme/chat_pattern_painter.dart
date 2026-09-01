import 'package:flutter/material.dart';

import 'chat_theme.dart';

/// Paints a [ChatPattern] behind the message list.
///
/// ## Why procedural rather than an asset
///
/// WhatsApp's doodle background is a bitmap. Shipping one per theme would add
/// megabytes to the APK, need three densities each, and still be a fixed hue —
/// so a themed variant would mean re-exporting the whole set. At the 6-8% opacity
/// these motifs are drawn at, nobody can tell a stroked path from a PNG, and the
/// colour becomes a parameter instead of an asset.
///
/// ## Why the layout is hashed rather than random
///
/// [_cellHash] is a fixed integer hash of the grid coordinate, so a motif's
/// jitter and rotation are a pure function of *where* it is. A `Random()` would
/// re-roll on every repaint and make the background crawl whenever the widget
/// rebuilt — during a keyboard open, a theme switch, or an incoming message.
/// This is also why the painter takes no size-derived offset: the pattern is
/// anchored to the top-left of the message area and stays put.
class ChatPatternPainter extends CustomPainter {
  const ChatPatternPainter({
    required this.pattern,
    required this.ink,
    this.scale = 1,
  });

  final ChatPattern pattern;

  /// Stroke/fill colour with its opacity already applied — see
  /// [ChatTheme.patternInk].
  final Color ink;

  /// Uniform shrink factor for pitch and motif size.
  ///
  /// Exists for the theme picker: its tiles are ~110px wide, so at full scale a
  /// `doodles` or `bubbles` preset would show one or two motifs and the preview
  /// would read as an un-patterned flat colour — the tile would be advertising
  /// the wrong theme. Scaling both the grid and the shapes keeps the preview a
  /// faithful miniature rather than a crop.
  final double scale;

  /// Grid pitch per pattern. Dots are texture and want to be dense; doodles are
  /// recognisable shapes and want room, or the background turns into wallpaper
  /// that competes with the conversation.
  static const Map<ChatPattern, double> _pitch = {
    ChatPattern.dots: 26,
    ChatPattern.bubbles: 92,
    ChatPattern.doodles: 78,
  };

  @override
  void paint(Canvas canvas, Size size) {
    if (pattern == ChatPattern.none || size.isEmpty) return;
    final pitch = (_pitch[pattern] ?? 64) * scale;

    final cols = (size.width / pitch).ceil() + 1;
    final rows = (size.height / pitch).ceil() + 1;

    final fill = Paint()
      ..color = ink
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // The doodle branch shrinks via `canvas.scale`, which scales stroke width
    // too — so its paint carries the unscaled width and comes out the same
    // 1.6 * scale on screen as the others.
    final motifStroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final h = _cellHash(col, row);

        switch (pattern) {
          case ChatPattern.dots:
            // Two radii on a 4-cell cycle, so the matrix reads as texture
            // rather than as graph paper.
            canvas.drawCircle(
              Offset(col * pitch + pitch / 2, row * pitch + pitch / 2),
              ((h % 4 == 0) ? 2.1 : 1.3) * scale,
              fill,
            );

          case ChatPattern.bubbles:
            // A third of the cells stay empty: evenly filled circles look like
            // a template, gaps look designed.
            if (h % 3 == 0) continue;
            final centre = _jittered(col, row, pitch, h);
            final radius = (11 + (h % 5) * 4.5) * scale;
            canvas.drawCircle(centre, radius, stroke);
            if (h % 4 == 1) {
              canvas.drawCircle(centre, radius * 0.42, fill);
            }

          case ChatPattern.doodles:
            if (h % 5 == 0) continue;
            final centre = _jittered(col, row, pitch, h);
            canvas.save();
            canvas.translate(centre.dx, centre.dy);
            // ±0.35 rad. Enough to look hand-placed; more starts reading as
            // sloppy rather than casual.
            canvas.rotate(((h >> 3) % 21 - 10) / 30);
            // The motifs are drawn at a fixed size around the origin, so the
            // scale is applied here rather than threaded through every path.
            if (scale != 1) canvas.scale(scale);
            _drawMotif(canvas, h % 4, motifStroke, fill);
            canvas.restore();

          case ChatPattern.none:
            return;
        }
      }
    }
  }

  /// One of four motifs, chosen by [index]. Deliberately a small set: the eye
  /// picks up on repetition far less than on a motif that does not belong with
  /// the others.
  void _drawMotif(Canvas canvas, int index, Paint stroke, Paint fill) {
    switch (index) {
      case 0:
        // Speech bubble with a tail — the one motif that says "messenger".
        final r = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-9, -8, 18, 13),
          const Radius.circular(4.5),
        );
        canvas.drawRRect(r, stroke);
        canvas.drawPath(
          Path()
            ..moveTo(-4.5, 5)
            ..lineTo(-6.5, 9.5)
            ..lineTo(-1, 5),
          stroke,
        );

      case 1:
        // Heart, two arcs onto a point.
        final path = Path()
          ..moveTo(0, 7.5)
          ..cubicTo(-9.5, 1.5, -6.5, -8, 0, -3.4)
          ..cubicTo(6.5, -8, 9.5, 1.5, 0, 7.5)
          ..close();
        canvas.drawPath(path, stroke);

      case 2:
        // Four-point spark.
        canvas.drawPath(
          Path()
            ..moveTo(0, -8.5)
            ..quadraticBezierTo(1.4, -1.4, 8.5, 0)
            ..quadraticBezierTo(1.4, 1.4, 0, 8.5)
            ..quadraticBezierTo(-1.4, 1.4, -8.5, 0)
            ..quadraticBezierTo(-1.4, -1.4, 0, -8.5)
            ..close(),
          fill,
        );

      default:
        // Ring — the quiet one that gives the eye somewhere to rest.
        canvas.drawCircle(Offset.zero, 6.5, stroke);
    }
  }

  /// Cell centre nudged by up to a quarter of the pitch in each axis, so a
  /// motif sits off-grid without ever crossing into a neighbour's cell.
  Offset _jittered(int col, int row, double pitch, int h) => Offset(
        col * pitch + pitch / 2 + ((h % 11) - 5) * pitch / 44,
        row * pitch + pitch / 2 + (((h >> 5) % 11) - 5) * pitch / 44,
      );

  /// Stable per-cell hash. The multipliers are the usual large primes used for
  /// spatial hashing; the mask keeps it non-negative so `%` behaves.
  int _cellHash(int col, int row) =>
      ((col + 1) * 73856093 ^ (row + 1) * 19349663) & 0x7FFFFFFF;

  @override
  bool shouldRepaint(ChatPatternPainter oldDelegate) =>
      oldDelegate.pattern != pattern ||
      oldDelegate.ink != ink ||
      oldDelegate.scale != scale;
}

/// The pattern layer, sized to its parent and excluded from hit testing.
///
/// Wrapped in a [RepaintBoundary] because the layer above it is a scrolling
/// message list: without one, every frame of a scroll would repaint a few
/// hundred paths that never move.
class ChatPatternLayer extends StatelessWidget {
  const ChatPatternLayer({
    super.key,
    required this.pattern,
    required this.ink,
    this.scale = 1,
  });

  final ChatPattern pattern;
  final Color ink;

  /// See [ChatPatternPainter.scale] — below 1 for the theme picker's tiles.
  final double scale;

  @override
  Widget build(BuildContext context) {
    if (pattern == ChatPattern.none) return const SizedBox.shrink();
    return RepaintBoundary(
      child: IgnorePointer(
        child: CustomPaint(
          size: Size.infinite,
          painter: ChatPatternPainter(
            pattern: pattern,
            ink: ink,
            scale: scale,
          ),
        ),
      ),
    );
  }
}
