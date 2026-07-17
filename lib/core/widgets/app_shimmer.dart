import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shared shimmer wrapper tuned for light/dark app surfaces.
class AppShimmer extends StatelessWidget {
  const AppShimmer({super.key, required this.child});

  final Widget child;

  static Color fillColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Slightly lighter than cardSurface so bones read clearly on the shell.
    return isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE8EBF0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF323232) : const Color(0xFFE0E4EA),
      highlightColor: isDark ? const Color(0xFF505050) : const Color(0xFFF8FAFC),
      period: const Duration(milliseconds: 1100),
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
