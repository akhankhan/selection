import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/flyer_item.dart';
import 'product_thumbnail.dart';

/// Bottom sheet shown when a flyer deal is selected: a chevron handle, the real
/// product photo (cropped from the flyer), the name + price, and two actions.
class DealSheet extends StatelessWidget {
  final FlyerItem item;

  /// Decoded flyer page image the [item] lives on.
  final ui.Image? flyerImage;

  const DealSheet({super.key, required this.item, required this.flyerImage});

  /// Normalised region of the flyer holding just this item's product photo
  /// (the left part of its cell).
  Rect get _photoCrop {
    final Rect b = item.boundingBox;
    return Rect.fromLTRB(
      b.left + b.width * 0.03,
      b.top + b.height * 0.07,
      b.left + b.width * 0.52,
      b.bottom - b.height * 0.07,
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color ink = Color(0xFF1A1A1A);
    const Color brandBlue = Color(0xFF0071CE);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(blurRadius: 24, color: Colors.black26)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),
          const Icon(
            Icons.keyboard_arrow_up,
            size: 28,
            color: Color(0xFF9E9E9E),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              children: [
                ProductThumbnail(
                  flyerImage: flyerImage,
                  cropRect: _photoCrop,
                  size: 88,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: ink,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.price,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.storefront_outlined, size: 20),
                    label: const Text(
                      'Buy Now',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: brandBlue,
                      side: const BorderSide(color: brandBlue, width: 1.6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share, color: Colors.white,
                        size: 20),
                    label: const Text(
                      'Share deal',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandBlue,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
