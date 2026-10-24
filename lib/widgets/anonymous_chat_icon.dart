import 'package:flutter/material.dart';

/// Shared incognito symbol for Anonymous Chat entry points.
class AnonymousChatIcon extends StatelessWidget {
  const AnonymousChatIcon({super.key, this.size, this.color});

  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final iconSize = size ?? theme.size ?? 24;
    final iconColor = color ?? theme.color ?? Colors.black;
    final opacity = theme.opacity ?? 1;

    return SizedBox.square(
      dimension: iconSize,
      child: Center(
        child: CustomPaint(
          size: Size.square(iconSize),
          painter: _IncognitoPainter(
            iconColor.withValues(alpha: iconColor.a * opacity),
          ),
        ),
      ),
    );
  }
}

class _IncognitoPainter extends CustomPainter {
  const _IncognitoPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);

    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final hat = Path()
      ..moveTo(6.5, 12)
      ..lineTo(8.4, 5.5)
      ..quadraticBezierTo(8.7, 4.5, 9.8, 4.9)
      ..lineTo(12, 5.7)
      ..lineTo(14.2, 4.9)
      ..quadraticBezierTo(15.3, 4.5, 15.6, 5.5)
      ..lineTo(17.5, 12)
      ..close();
    canvas.drawPath(hat, fill);
    canvas.drawLine(const Offset(3, 12), const Offset(21, 12), stroke);

    canvas.drawCircle(const Offset(7.5, 18), 3, stroke);
    canvas.drawCircle(const Offset(16.5, 18), 3, stroke);
    canvas.drawPath(
      Path()
        ..moveTo(10.5, 18)
        ..quadraticBezierTo(12, 16.5, 13.5, 18),
      stroke,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IncognitoPainter oldDelegate) =>
      color != oldDelegate.color;
}
