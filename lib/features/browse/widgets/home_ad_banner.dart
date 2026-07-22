import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme_extension.dart';
import '../data/home_ad_repository.dart';
import '../models/home_ad.dart';

/// Horizontal image ad strip for the home feed (admin-managed).
class HomeAdBanner extends StatelessWidget {
  const HomeAdBanner({
    super.key,
    required this.placement,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 8),
    this.onOpenCategory,
  });

  final HomeAdPlacement placement;
  final EdgeInsets padding;

  /// Called when the ad has a [HomeAd.categoryId] — parent should switch tabs.
  final void Function(String categoryId)? onOpenCategory;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HomeAd>>(
      stream: HomeAdRepository.instance.watchEnabled(placement: placement),
      builder: (context, snap) {
        final ads = snap.data ?? const <HomeAd>[];
        if (ads.isEmpty) return const SizedBox.shrink();
        final ad = ads.first;
        return Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 2),
                child: Text(
                  'Ad',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: context.appTheme.subtitle,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _onTap(ad),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 16 / 5,
                      child: CachedNetworkImage(
                        imageUrl: ad.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        memCacheWidth: 900,
                        placeholder: (_, _) => ColoredBox(
                          color: context.appTheme.sectionBg,
                        ),
                        errorWidget: (_, _, _) => ColoredBox(
                          color: context.appTheme.sectionBg,
                          child: Icon(
                            Icons.image_outlined,
                            color: context.appTheme.subtitle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onTap(HomeAd ad) {
    final categoryId = ad.categoryId?.trim();
    if (categoryId != null &&
        categoryId.isNotEmpty &&
        onOpenCategory != null) {
      onOpenCategory!(categoryId);
      return;
    }
    _openLink(ad.linkUrl);
  }

  Future<void> _openLink(String? linkUrl) async {
    final raw = linkUrl?.trim();
    if (raw == null || raw.isEmpty) return;
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
