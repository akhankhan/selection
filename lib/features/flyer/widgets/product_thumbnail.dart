import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Shows a product's photo by cropping it straight out of the flyer image, so
/// the thumbnail is the real item in full colour (no grey placeholder).
class ProductThumbnail extends StatelessWidget {
  /// The decoded flyer page image the product lives on.
  final ui.Image? flyerImage;

  /// Normalised (0..1) region of the flyer image to crop and show.
  final Rect cropRect;

  final double size;

  const ProductThumbnail({
    super.key,
    required this.flyerImage,
    required this.cropRect,
    this.size = 86,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: size,
        height: size,
        child: flyerImage == null
            ? const ColoredBox(
                color: Color(0xFFF2F2F2),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              )
            : CustomPaint(
                painter: _CropPainter(flyerImage!, cropRect),
              ),
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  final ui.Image image;
  final Rect crop;

  _CropPainter(this.image, this.crop);

  @override
  void paint(Canvas canvas, Size size) {
    final double iw = image.width.toDouble();
    final double ih = image.height.toDouble();

    Rect src = Rect.fromLTRB(
      crop.left * iw,
      crop.top * ih,
      crop.right * iw,
      crop.bottom * ih,
    );

    // Cover-crop the source region to the destination aspect ratio so the
    // photo fills the square thumbnail without distortion.
    final double dstAspect = size.width / size.height;
    final double srcAspect = src.width / src.height;
    if (srcAspect > dstAspect) {
      final double w = src.height * dstAspect;
      src = Rect.fromLTWH(
          src.left + (src.width - w) / 2, src.top, w, src.height);
    } else {
      final double h = src.width / dstAspect;
      src = Rect.fromLTWH(
          src.left, src.top + (src.height - h) / 2, src.width, h);
    }

    final Paint paint = Paint()..filterQuality = FilterQuality.high;
    canvas.drawImageRect(image, src, Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _CropPainter old) =>
      old.image != image || old.crop != crop;
}
