import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_extension.dart';
import '../../flyer/models/store.dart';
import 'store_card_preview_image.dart';
import 'store_card.dart';
import 'store_logo_avatar.dart';

/// Full-width hero card for featured stores (Flipp-style large banner).
class FeaturedStoreCard extends StatelessWidget {
  const FeaturedStoreCard({
    super.key,
    required this.store,
    required this.isFavorited,
    this.onFavoriteToggle,
    this.onTap,
  });

  final Store store;
  final bool isFavorited;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final isDark = context.isDarkMode;

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
                child: Row(
                  children: [
                    StoreLogoAvatar(store: store, radius: 22, fontSize: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: theme.navyText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          StoreCardStatusLine(store: store),
                        ],
                      ),
                    ),
                    FavoriteHeartButton(
                      isFavorited: isFavorited,
                      onTap: onFavoriteToggle,
                    ),
                  ],
                ),
              ),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: StoreCardPreviewImage(
                  store: store,
                  maxCacheWidth: 1200,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
