import 'dart:math' as math;
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_extension.dart';

/// Loads a flyer page with a blurred preview, then reveals the full image.
class ProgressiveFlyerImage extends StatefulWidget {
  const ProgressiveFlyerImage({
    super.key,
    required this.imageUrl,
    this.previewImageUrl,
    required this.renderWidth,
    this.fit = BoxFit.fill,
    this.onImageReady,
  });

  final String imageUrl;
  final String? previewImageUrl;
  final int renderWidth;
  final BoxFit fit;
  final VoidCallback? onImageReady;

  @override
  State<ProgressiveFlyerImage> createState() => _ProgressiveFlyerImageState();
}

class _ProgressiveFlyerImageState extends State<ProgressiveFlyerImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _revealController;
  late final Animation<double> _blur;
  late final Animation<double> _opacity;
  bool _revealStarted = false;
  bool _readyNotified = false;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    final curve = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOutCubic,
    );
    _blur = Tween<double>(begin: 16, end: 0).animate(curve);
    _opacity = Tween<double>(begin: 0.4, end: 1).animate(curve);
  }

  @override
  void didUpdateWidget(ProgressiveFlyerImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.previewImageUrl != widget.previewImageUrl ||
        oldWidget.renderWidth != widget.renderWidth) {
      _revealStarted = false;
      _readyNotified = false;
      _revealController.reset();
    }
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  void _startReveal() {
    if (_revealStarted) return;
    _revealStarted = true;
    _revealController.forward();
    if (!_readyNotified) {
      _readyNotified = true;
      widget.onImageReady?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewUrl = widget.previewImageUrl?.trim();
    final hasPreview = previewUrl != null && previewUrl.isNotEmpty;
    final previewWidth = math.min(120, widget.renderWidth);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasPreview)
          CachedNetworkImage(
            imageUrl: previewUrl,
            fit: widget.fit,
            width: double.infinity,
            height: double.infinity,
            memCacheWidth: 96,
            fadeInDuration: Duration.zero,
            errorWidget: (_, _, _) => _blurBackdrop(context, previewWidth),
          )
        else
          _blurBackdrop(context, previewWidth),
        CachedNetworkImage(
          imageUrl: widget.imageUrl,
          fit: widget.fit,
          width: double.infinity,
          height: double.infinity,
          memCacheWidth: widget.renderWidth,
          fadeInDuration: Duration.zero,
          placeholder: (_, _) => const SizedBox.shrink(),
          imageBuilder: (context, imageProvider) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _startReveal();
            });
            return AnimatedBuilder(
              animation: _revealController,
              builder: (context, _) {
                return Opacity(
                  opacity: _opacity.value.clamp(0.0, 1.0),
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: _blur.value,
                      sigmaY: _blur.value,
                    ),
                    child: Image(
                      image: imageProvider,
                      fit: widget.fit,
                      width: double.infinity,
                      height: double.infinity,
                      gaplessPlayback: true,
                    ),
                  ),
                );
              },
            );
          },
          errorWidget: (_, _, _) => _errorState(context),
        ),
      ],
    );
  }

  Widget _blurBackdrop(BuildContext context, int previewWidth) {
    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      fit: widget.fit,
      width: double.infinity,
      height: double.infinity,
      memCacheWidth: previewWidth,
      fadeInDuration: Duration.zero,
      placeholder: (_, _) => _basePlaceholder(context),
      imageBuilder: (context, imageProvider) => ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Image(
          image: imageProvider,
          fit: widget.fit,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
      errorWidget: (_, _, _) => _basePlaceholder(context),
    );
  }

  Widget _basePlaceholder(BuildContext context) {
    return ColoredBox(color: context.appTheme.sectionBg);
  }

  Widget _errorState(BuildContext context) {
    return ColoredBox(
      color: context.appTheme.sectionBg,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 40,
          color: context.appTheme.subtitle,
        ),
      ),
    );
  }
}
