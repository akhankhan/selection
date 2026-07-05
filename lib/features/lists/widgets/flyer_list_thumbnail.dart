import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../flyer/widgets/product_thumbnail.dart';

/// Rebuilds a flyer product thumbnail from a remote page image URL after
/// the shopping list has been restored from local storage.
class FlyerListThumbnail extends StatefulWidget {
  const FlyerListThumbnail({
    super.key,
    required this.imageUrl,
    required this.cropRect,
  });

  final String imageUrl;
  final Rect cropRect;

  @override
  State<FlyerListThumbnail> createState() => _FlyerListThumbnailState();
}

class _FlyerListThumbnailState extends State<FlyerListThumbnail> {
  ui.Image? _image;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant FlyerListThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _image = null;
      _failed = false;
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.imageUrl.isEmpty) {
      if (mounted) setState(() => _failed = true);
      return;
    }

    try {
      final url = widget.imageUrl;
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');

      final codec = await ui.instantiateImageCodec(response.bodyBytes);
      final frame = await codec.getNextFrame();
      if (!mounted) return;
      setState(() => _image = frame.image);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return ColoredBox(
        color: Theme.of(context).dividerColor,
        child: const Icon(Icons.image_not_supported_outlined, size: 20),
      );
    }

    return ProductThumbnail(
      flyerImage: _image,
      cropRect: widget.cropRect,
      borderRadius: BorderRadius.circular(2),
    );
  }
}
