import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_extension.dart';
import '../../../core/widgets/app_shimmer.dart';

/// Browse loading skeleton — pixel-aligned with [BrowseScreen] Explore feed:
/// section header → one featured card → 2-column standard grid.
class BrowseLoadingShimmer extends StatelessWidget {
  const BrowseLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 103)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: _ShimmerBone(
              width: 156,
              height: 18,
              borderRadius: 4,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 4)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          sliver: SliverToBoxAdapter(
            child: _FeaturedCardSkeleton(theme: theme),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.74,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, _) => _GridCardSkeleton(theme: theme),
              childCount: 2,
            ),
          ),
        ),
      ],
    );
  }
}

/// Single shimmering placeholder shape.
class _ShimmerBone extends StatelessWidget {
  const _ShimmerBone({
    this.width,
    required this.height,
    this.borderRadius = 6,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppShimmer.fillColor(context),
          borderRadius:
              shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
          shape: shape,
        ),
      ),
    );
  }
}

/// Mirrors [FeaturedStoreCard] — static shell, shimmering bones inside.
class _FeaturedCardSkeleton extends StatelessWidget {
  const _FeaturedCardSkeleton({required this.theme});

  final AppThemeExtension theme;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: theme.border.withValues(alpha: 0.6))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
            child: Row(
              children: [
                const _ShimmerBone(
                  width: 44,
                  height: 44,
                  borderRadius: 22,
                  shape: BoxShape.circle,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBone(width: 148, height: 16, borderRadius: 4),
                      SizedBox(height: 8),
                      _ShimmerBone(width: 88, height: 12, borderRadius: 4),
                    ],
                  ),
                ),
                const _ShimmerBone(
                  width: 24,
                  height: 24,
                  borderRadius: 12,
                  shape: BoxShape.circle,
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: AppShimmer(
              child: ColoredBox(color: AppShimmer.fillColor(context)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mirrors [StoreCard] in the 2-column grid.
class _GridCardSkeleton extends StatelessWidget {
  const _GridCardSkeleton({required this.theme});

  final AppThemeExtension theme;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: isDark
            ? Border.all(color: theme.border.withValues(alpha: 0.6))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBone(
                        width: double.infinity,
                        height: 14,
                        borderRadius: 4,
                      ),
                      SizedBox(height: 8),
                      _ShimmerBone(width: 72, height: 11, borderRadius: 4),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const _ShimmerBone(
                  width: 22,
                  height: 22,
                  borderRadius: 11,
                  shape: BoxShape.circle,
                ),
              ],
            ),
          ),
          Expanded(
            child: AppShimmer(
              child: ColoredBox(color: AppShimmer.fillColor(context)),
            ),
          ),
        ],
      ),
    );
  }
}
