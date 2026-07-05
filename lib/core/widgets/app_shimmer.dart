import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shared shimmer wrapper tuned for light/dark app surfaces.
class AppShimmer extends StatelessWidget {
  const AppShimmer({super.key, required this.child});

  final Widget child;

  static Color fillColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF2B2B2B) : const Color(0xFFE4E7EB);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2B2B2B) : const Color(0xFFE4E7EB),
      highlightColor: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F7FA),
      period: const Duration(milliseconds: 1300),
      child: child,
    );
  }
}

/// Rectangular shimmer placeholder block.
class AppShimmerBox extends StatelessWidget {
  const AppShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppShimmer.fillColor(context),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
