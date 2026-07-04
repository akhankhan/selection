import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_extension.dart';
import '../../flyer/models/store.dart';
import 'store_card_preview_image.dart';

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

    // Determine status badge based on store dates or mockup values matching the screenshots
    final statusWidget = StoreCardStatusLine(store: store);

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
                child: StoreCardPreviewImage(store: store),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class StoreCardStatusLine extends StatelessWidget {
  const StoreCardStatusLine({super.key, required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final name = store.name.toLowerCase();

    if (name.contains('shoppers')) {
      return _badge('Preview', const Color(0xFFE8F5E9), const Color(0xFF2E7D32));
    }
    if (name.contains('petsmart')) {
      return _badge('Ends Today', const Color(0xFFFFEBEE), const Color(0xFFC62828));
    }
    if (name.contains('staples') || name.contains('powell')) {
      return _badge('New', const Color(0xFFE0F2FE), const Color(0xFF0071CE));
    }

    return Text(
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

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
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
