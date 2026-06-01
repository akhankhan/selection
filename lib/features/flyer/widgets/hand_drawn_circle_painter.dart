import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

/// Paints a hand-drawn marker "circle" around a flyer item: a slightly wobbly
/// ellipse whose stroke overshoots a full loop and finishes with an arrowhead,
/// matching the deal-highlight style in the reference video.
///
/// Hot path: the wobbly 150-point loop and its measured length are computed
/// **once** per painter instance + canvas size, then cached. Subsequent frames
/// only re-extract a sub-path based on the current animation value. Wired up
/// via `super(repaint: animation)` so each tick repaints just this painter,
/// not the surrounding widget tree.
class HandDrawnCirclePainter extends CustomPainter {
  HandDrawnCirclePainter({
    required this.normalizedRect,
    required this.animation,
    required this.seed,
    this.color = const Color(0xFFFFC400),
  }) : super(repaint: animation);

  /// Normalized rect (values 0..1 on both axes) of the item to encircle,
  /// relative to the canvas this painter draws into.
  final Rect normalizedRect;

  /// Underlying animation — also wired as the repaint trigger.
  final Animation<double> animation;

  /// Per-item seed so every circle gets its own unique wobble.
  final int seed;

  /// Marker colour.
  final Color color;

  // ----- Cached geometry, populated on the first paint at each canvas size.
  Size? _cachedSize;
  Path? _cachedLoop;
  PathMetric? _cachedMetric;
  double? _cachedLength;
  double? _cachedStrokeWidth;

  void _ensureLoop(Size size) {
    if (_cachedSize == size && _cachedLoop != null) return;
    _cachedSize = size;

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
    if (bounds.width <= 0 || bounds.height <= 0) {
      _cachedLoop = Path();
      _cachedMetric = null;
      _cachedLength = 0;
      _cachedStrokeWidth = 0;
      return;
    }

    final rnd = math.Random(seed);
    final double rx = bounds.width / 2;
    final double ry = bounds.height / 2;

    // Small whole-shape tilt + centre jitter -> looks sketched by hand.
    final double tilt = (rnd.nextDouble() - 0.5) * 0.16;
    final Offset center =
        bounds.center +
        Offset(
          (rnd.nextDouble() - 0.5) * bounds.width * 0.05,
          (rnd.nextDouble() - 0.5) * bounds.height * 0.05,
        );

    final double startAngle = math.pi * 1.56;
    final double overshoot = 0.40 + rnd.nextDouble() * 0.24;
    final double totalSweep = 2 * math.pi + overshoot;

    final double wobA = 0.045 + rnd.nextDouble() * 0.04;
    final double wobB = 0.025 + rnd.nextDouble() * 0.03;
    final double phaseA = rnd.nextDouble() * math.pi * 2;
    final double phaseB = rnd.nextDouble() * math.pi * 2;
    final double cosT = math.cos(tilt);
    final double sinT = math.sin(tilt);

    Offset pointAt(double t) {
      final double a = startAngle - totalSweep * t;
      final double wobble =
          1 + wobA * math.sin(a * 2 + phaseA) + wobB * math.sin(a * 3 + phaseB);
      final double x = math.cos(a) * rx * wobble;
      final double y = math.sin(a) * ry * wobble;
      return center + Offset(x * cosT - y * sinT, x * sinT + y * cosT);
    }

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

    _cachedLoop = loop;
    _cachedMetric = loop.computeMetrics().first;
    _cachedLength = _cachedMetric!.length;
    _cachedStrokeWidth = (math.min(rx, ry) * 0.17).clamp(4.5, 12.0).toDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double raw = animation.value;
    if (raw <= 0) return;
    _ensureLoop(size);
    final PathMetric? metric = _cachedMetric;
    final double? length = _cachedLength;
    if (metric == null || length == null || length <= 0) return;

    final double progress = Curves.easeOutCubic.transform(raw).clamp(0.0, 1.0);
    final Path drawn = metric.extractPath(0, length * progress);

    final Paint strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _cachedStrokeWidth!
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    canvas.drawPath(drawn, strokePaint);
  }

  @override
  bool shouldRepaint(covariant HandDrawnCirclePainter old) =>
      old.normalizedRect != normalizedRect ||
      old.seed != seed ||
      old.color != color;
}
