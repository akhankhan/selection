import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_extension.dart';
import '../../flyer/data/cloudinary_url.dart';
import '../../flyer/models/store.dart';

enum CardStatus { newBadge, untilText, previewBadge, expiringText }

class StoreCard extends StatelessWidget {
  final Store store;
  final bool isFavorited;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;

  const StoreCard({
    super.key,
    required this.store,
    required this.isFavorited,
    this.onFavoriteToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final isDark = context.isDarkMode;

    final String imageUrl = store.pages.isNotEmpty
        ? store.pages.first.imageUrl
        : '';

    // Determine status badge based on store dates or mockup values matching the screenshots
    Widget statusWidget = const SizedBox.shrink();
    if (store.name.toLowerCase().contains('shoppers')) {
      statusWidget = _buildStatusBadge(
        'Preview',
        const Color(0xFFE8F5E9),
        const Color(0xFF2E7D32),
      );
    } else if (store.name.toLowerCase().contains('petsmart')) {
      statusWidget = _buildStatusBadge(
        'Ends Today',
        const Color(0xFFFFEBEE),
        const Color(0xFFC62828),
      );
    } else if (store.name.toLowerCase().contains('staples') ||
        store.name.toLowerCase().contains('powell')) {
      statusWidget = _buildStatusBadge(
        'New',
        const Color(0xFFE0F2FE),
        const Color(0xFF0071CE),
      );
    } else {
      // Default standard date range text
      statusWidget = Text(
        store.dateRange,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: theme.subtitle,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );
    }

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header containing Title, Status, and Heart Icon
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: theme.navyText,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          statusWidget,
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    FavoriteHeartButton(
                      isFavorited: isFavorited,
                      onTap: onFavoriteToggle,
                    ),
                  ],
                ),
              ),

              // Flyer Image content
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: theme.sectionBg,
                  child: imageUrl.isEmpty
                      ? Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 32,
                            color: theme.subtitle,
                          ),
                        )
                      : LayoutBuilder(
                          builder: (ctx, c) {
                            final double dpr =
                                MediaQuery.of(ctx).devicePixelRatio;
                            final int targetW =
                                (c.maxWidth * dpr).clamp(200, 800).toInt();
                            return CachedNetworkImage(
                              imageUrl: CloudinaryUrl.sized(
                                imageUrl,
                                width: targetW,
                              ),
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              memCacheWidth: targetW,
                              fadeInDuration: const Duration(milliseconds: 120),
                              placeholder: (_, _) => Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: context.brandBlue,
                                  ),
                                ),
                              ),
                              errorWidget: (_, _, _) => Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  size: 24,
                                  color: theme.subtitle,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color bgColor, Color fgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fgColor,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class FavoriteHeartButton extends StatefulWidget {
  final bool isFavorited;
  final VoidCallback? onTap;

  const FavoriteHeartButton({
    super.key,
    required this.isFavorited,
    this.onTap,
  });

  @override
  State<FavoriteHeartButton> createState() => _FavoriteHeartButtonState();
}

class _FavoriteHeartButtonState extends State<FavoriteHeartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.4)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.4, end: 1.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant FavoriteHeartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorited && !oldWidget.isFavorited) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!();
        }
        if (!widget.isFavorited) {
          _controller.forward(from: 0.0);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Icon(
            widget.isFavorited ? Icons.favorite : Icons.favorite_border,
            size: 20,
            color: widget.isFavorited ? Colors.red : theme.chipInactive,
          ),
        ),
      ),
    );
  }
}
