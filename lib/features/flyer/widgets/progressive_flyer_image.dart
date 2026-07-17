import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_extension.dart';

/// Loads a flyer page: full menu visible immediately as a blurred low-res
/// preview, then sharpens into the full-quality image.
///
/// Blur is applied only to the tiny decoded preview texture (not the full-res
/// image), so scrolling stays smooth while the effect still reads clearly.
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
  static const Duration _revealDuration = Duration(milliseconds: 520);
  static const double _initialBlurSigma = 14;

  late final AnimationController _revealController;
  late final Animation<double> _sharpOpacity;
  late final Animation<double> _blurSigma;

  ImageProvider? _fullProvider;
  bool _revealStarted = false;
  bool _revealComplete = false;
  bool _readyNotified = false;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: _revealDuration,
    );
    final curve = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOutCubic,
    );
    _sharpOpacity = curve;
    _blurSigma = Tween<double>(begin: _initialBlurSigma, end: 0).animate(curve);
    _revealController.addStatusListener(_onRevealStatus);
  }

  void _onRevealStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _revealComplete = true);
    }
  }

  @override
  void didUpdateWidget(ProgressiveFlyerImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.previewImageUrl != widget.previewImageUrl ||
        oldWidget.renderWidth != widget.renderWidth) {
      _resetForNewSource();
    }
  }

  void _resetForNewSource() {
    _revealStarted = false;
    _revealComplete = false;
    _readyNotified = false;
    _fullProvider = null;
    _revealController.reset();
  }

  @override
  void dispose() {
    _revealController.removeStatusListener(_onRevealStatus);
    _revealController.dispose();
    super.dispose();
  }

  void _onFullImageDecoded(ImageProvider provider) {
    if (_revealStarted || !mounted) return;
    setState(() {
      _fullProvider = provider;
      _revealStarted = true;
    });
    _revealController.forward();
    if (!_readyNotified) {
      _readyNotified = true;
      widget.onImageReady?.call();
    }
  }

  int get _lowResWidth => math.min(200, widget.renderWidth);

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.isEmpty) {
      return _basePlaceholder(context);
    }

    if (_revealComplete && _fullProvider != null) {
      return Image(
        image: _fullProvider!,
        fit: widget.fit,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      );
    }

    return AnimatedBuilder(
      animation: _revealController,
      builder: (context, _) {
        final blurSigma =
            _revealStarted ? _blurSigma.value : _initialBlurSigma;
        final sharpOpacity = _revealStarted ? _sharpOpacity.value : 0.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: blurSigma,
                sigmaY: blurSigma,
              ),
              child: _buildLowResLayer(context),
            ),
            if (_fullProvider != null)
              Opacity(
                opacity: sharpOpacity,
                child: Image(
                  image: _fullProvider!,
                  fit: widget.fit,
                  width: double.infinity,
                  height: double.infinity,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            if (!_revealStarted)
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    fit: widget.fit,
                    memCacheWidth: widget.renderWidth,
                    fadeInDuration: Duration.zero,
                    placeholder: (_, _) => const SizedBox.shrink(),
                    imageBuilder: (context, imageProvider) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _onFullImageDecoded(imageProvider);
                      });
                      return const SizedBox.shrink();
                    },
                    errorWidget: (_, _, _) => _errorState(context),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLowResLayer(BuildContext context) {
    final previewUrl = widget.previewImageUrl?.trim();
    if (previewUrl != null && previewUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: previewUrl,
        fit: widget.fit,
        width: double.infinity,
        height: double.infinity,
        memCacheWidth: _lowResWidth,
        fadeInDuration: Duration.zero,
        filterQuality: FilterQuality.low,
        placeholder: (_, _) => _basePlaceholder(context),
        errorWidget: (_, _, _) => _lowResFromFullUrl(context),
      );
    }
    return _lowResFromFullUrl(context);
  }

  Widget _lowResFromFullUrl(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      fit: widget.fit,
      width: double.infinity,
      height: double.infinity,
      memCacheWidth: _lowResWidth,
      fadeInDuration: Duration.zero,
      filterQuality: FilterQuality.low,
      placeholder: (_, _) => _basePlaceholder(context),
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
