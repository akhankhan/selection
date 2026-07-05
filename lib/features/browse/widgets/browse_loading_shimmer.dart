import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_extension.dart';
import '../../../core/widgets/app_shimmer.dart';

/// Browse home loading placeholder that mirrors the real store grid layout.
class BrowseLoadingShimmer extends StatelessWidget {
  const BrowseLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final fill = AppShimmer.fillColor(context);

    return AppShimmer(
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 103)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: AppShimmerBox(width: 148, height: 22, borderRadius: 6),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            sliver: SliverToBoxAdapter(child: _featuredCard(fill, theme)),
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
                (_, _) => _storeCard(fill, theme),
                childCount: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featuredCard(Color fill, AppThemeExtension theme) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: theme.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 120,
                      decoration: BoxDecoration(
                        color: fill,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 84,
                      decoration: BoxDecoration(
                        color: fill,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: fill,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _storeCard(Color fill, AppThemeExtension theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.border.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: fill,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 11,
                      width: 72,
                      decoration: BoxDecoration(
                        color: fill,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: fill,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
