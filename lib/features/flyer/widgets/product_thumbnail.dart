import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Shows a product's photo by cropping it straight out of the flyer image, so
/// the picture is the real item in full colour (no grey placeholder).
///
/// Fills whatever bounded box it is given — wrap it in a [SizedBox] or
/// [AspectRatio]. Supports [BoxFit.cover] (default) and [BoxFit.contain].
class ProductThumbnail extends StatelessWidget {
  /// The decoded flyer page image the product lives on.
  final ui.Image? flyerImage;

  /// Normalised (0..1) region of the flyer image to crop and show.
  final Rect cropRect;

  final BoxFit fit;
  final BorderRadiusGeometry borderRadius;

  const ProductThumbnail({
    super.key,
    required this.flyerImage,
    required this.cropRect,
    this.fit = BoxFit.cover,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: flyerImage == null
          ? const ColoredBox(
              color: Color(0xFFF2F2F2),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            )
          : RepaintBoundary(
              child: CustomPaint(
                size: Size.infinite,
                painter: _CropPainter(flyerImage!, cropRect, fit),
              ),
            ),
    );
  }
}

class _CropPainter extends CustomPainter {
  final ui.Image image;
  final Rect crop;
  final BoxFit fit;

  _CropPainter(this.image, this.crop, this.fit);

  @override
  void paint(Canvas canvas, Size size) {
    final double iw = image.width.toDouble();
    final double ih = image.height.toDouble();
    final Rect fullSrc = Rect.fromLTRB(
      crop.left * iw,
      crop.top * ih,
      crop.right * iw,
      crop.bottom * ih,
    );
    final Paint paint = Paint()..filterQuality = FilterQuality.high;
    final double dstAspect = size.width / size.height;
    final double srcAspect = fullSrc.width / fullSrc.height;

    if (fit == BoxFit.contain) {
      // Whole crop visible, letterboxed on white.
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
      Rect dst;
      if (srcAspect > dstAspect) {
        final double h = size.width / srcAspect;
        dst = Rect.fromLTWH(0, (size.height - h) / 2, size.width, h);
      } else {
        final double w = size.height * srcAspect;
        dst = Rect.fromLTWH((size.width - w) / 2, 0, w, size.height);
      }
      canvas.drawImageRect(image, fullSrc, dst, paint);
    } else {
      // Cover: crop the source to the destination aspect ratio.
      Rect src = fullSrc;
      if (srcAspect > dstAspect) {
        final double w = src.height * dstAspect;
        src = Rect.fromLTWH(
          src.left + (src.width - w) / 2,
          src.top,
          w,
          src.height,
        );
      } else {
        final double h = src.width / dstAspect;
        src = Rect.fromLTWH(
          src.left,
          src.top + (src.height - h) / 2,
          src.width,
          h,
        );
      }
      canvas.drawImageRect(image, src, Offset.zero & size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CropPainter old) =>
      old.image != image || old.crop != crop || old.fit != fit;
}
