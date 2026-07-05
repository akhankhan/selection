import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_extension.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../flyer/data/cloudinary_url.dart';
import '../../flyer/models/store.dart';

/// Flyer thumbnail for store cards — first menu page only.
class StoreCardPreviewImage extends StatelessWidget {
  const StoreCardPreviewImage({
    super.key,
    required this.store,
    this.alignment = Alignment.topCenter,
    this.maxCacheWidth = 800,
  });

  final Store store;
  final Alignment alignment;
  final int maxCacheWidth;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final imageUrl = store.previewImageUrl;

    if (imageUrl == null) {
      return ColoredBox(
        color: theme.sectionBg,
        child: Center(
          child: Icon(
            Icons.image_outlined,
            size: 32,
            color: theme.subtitle,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final dpr = MediaQuery.of(ctx).devicePixelRatio;
        final targetW =
            (constraints.maxWidth * dpr).clamp(200, maxCacheWidth).toInt();
        final sizedUrl = CloudinaryUrl.sized(imageUrl, width: targetW);

        return ColoredBox(
          color: theme.sectionBg,
          child: CachedNetworkImage(
            imageUrl: sizedUrl,
            fit: BoxFit.cover,
            alignment: alignment,
            width: double.infinity,
            height: double.infinity,
            memCacheWidth: targetW,
            fadeInDuration: const Duration(milliseconds: 120),
            placeholder: (ctx, _) => AppShimmer(
              child: ColoredBox(color: AppShimmer.fillColor(ctx)),
            ),
            errorWidget: (_, _, _) => Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 24,
                color: theme.subtitle,
              ),
            ),
          ),
        );
      },
    );
  }
}
