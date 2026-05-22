import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Paints a hand-drawn marker "circle" around a flyer item: a slightly wobbly
/// ellipse whose stroke overshoots a full loop and finishes with an arrowhead,
/// matching the deal-highlight style in the reference video.
class HandDrawnCirclePainter extends CustomPainter {
  /// Normalized rect (values 0..1 on both axes) of the item to encircle.
  final Rect normalizedRect;

  /// Stroke draw progress, 0..1.
  final double progress;

  /// Per-item seed so every circle gets its own unique wobble.
  final int seed;

  /// Marker colour.
  final Color color;

  HandDrawnCirclePainter({
    required this.normalizedRect,
    required this.progress,
    required this.seed,
    this.color = const Color(0xFFFFC400),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    // Item rectangle in pixels.
    final Rect itemRect = Rect.fromLTWH(
      normalizedRect.left * size.width,
      normalizedRect.top * size.height,
      normalizedRect.width * size.width,
      normalizedRect.height * size.height,
    );

    // Inset so the circle hugs the product from inside the cell.
    final Rect bounds = Rect.fromLTRB(
      itemRect.left + itemRect.width * 0.05,
      itemRect.top + itemRect.height * 0.09,
      itemRect.right - itemRect.width * 0.05,
      itemRect.bottom - itemRect.height * 0.09,
    );
    if (bounds.width <= 0 || bounds.height <= 0) return;

    final rnd = math.Random(seed);
    final double rx = bounds.width / 2;
    final double ry = bounds.height / 2;

    // Small whole-shape tilt + centre jitter -> looks sketched by hand.
    final double tilt = (rnd.nextDouble() - 0.5) * 0.16;
    final Offset center = bounds.center +
        Offset(
          (rnd.nextDouble() - 0.5) * bounds.width * 0.05,
          (rnd.nextDouble() - 0.5) * bounds.height * 0.05,
        );

    // Sweep a little past a full turn so the stroke crosses itself near the
    // top, like a real doodle. The loop is drawn counter-clockwise so it ends
    // at the top-left with the arrowhead pointing down into the product.
    final double startAngle = math.pi * 1.56;
    final double overshoot = 0.40 + rnd.nextDouble() * 0.24;
    final double totalSweep = 2 * math.pi + overshoot;

    // Low-frequency radius wobble.
    final double wobA = 0.045 + rnd.nextDouble() * 0.04;
    final double wobB = 0.025 + rnd.nextDouble() * 0.03;
    final double phaseA = rnd.nextDouble() * math.pi * 2;
    final double phaseB = rnd.nextDouble() * math.pi * 2;
    final double cosT = math.cos(tilt);
    final double sinT = math.sin(tilt);

    Offset pointAt(double t) {
      final double a = startAngle - totalSweep * t; // minus -> counter-clockwise
      final double wobble = 1 +
          wobA * math.sin(a * 2 + phaseA) +
          wobB * math.sin(a * 3 + phaseB);
      final double x = math.cos(a) * rx * wobble;
      final double y = math.sin(a) * ry * wobble;
      return center + Offset(x * cosT - y * sinT, x * sinT + y * cosT);
    }

    // Build the full wobbly loop.
    const int samples = 150;
    final Path loop = Path();
    for (int i = 0; i <= samples; i++) {
      final Offset p = pointAt(i / samples);
      if (i == 0) {
        loop.moveTo(p.dx, p.dy);
      } else {
        loop.lineTo(p.dx, p.dy);
      }
    }

    final double strokeW =
        (math.min(rx, ry) * 0.17).clamp(4.5, 12.0).toDouble();

    // Reveal the stroke up to `progress`; reserve the tail for the arrowhead.
    final double strokeFrac = (progress / 0.85).clamp(0.0, 1.0);
    final metric = loop.computeMetrics().first;
    final Path drawn = metric.extractPath(0, metric.length * strokeFrac);

    final Paint strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    canvas.drawPath(drawn, strokePaint);

    // Arrowhead at the end of the stroke.
    final double headT = ((progress - 0.80) / 0.20).clamp(0.0, 1.0);
    if (headT > 0) {
      final Offset tip = pointAt(1.0);
      final Offset back = pointAt(0.955);
      final Offset dir = tip - back;
      final double dist = dir.distance;
      if (dist > 0.001) {
        final double ux = dir.dx / dist;
        final double uy = dir.dy / dist;
        final double px = -uy;
        final double py = ux;
        final double headLen = strokeW * 2.9 * headT;
        final double headW = strokeW * 1.9 * headT;
        final double bx = tip.dx - ux * headLen;
        final double by = tip.dy - uy * headLen;
        final Path arrow = Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(bx + px * headW, by + py * headW)
          ..lineTo(bx - px * headW, by - py * headW)
          ..close();
        canvas.drawPath(
          arrow,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill
            ..isAntiAlias = true,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant HandDrawnCirclePainter old) =>
      old.progress != progress ||
      old.normalizedRect != normalizedRect ||
      old.seed != seed ||
      old.color != color;
}
