import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../flyer/models/store.dart';

/// Store avatar — uploaded logo when available, otherwise letter + brand color.
class StoreLogoAvatar extends StatelessWidget {
  const StoreLogoAvatar({
    super.key,
    required this.store,
    this.radius = 20,
    this.fontSize,
  });

  final Store store;
  final double radius;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final letterSize = fontSize ?? (radius * 0.9);
    final logoUrl = store.logoUrl;

    if (logoUrl != null && logoUrl.isNotEmpty) {
      final sized = logoUrl;
      return CircleAvatar(
        radius: radius,
        backgroundColor: store.brandColor.withValues(alpha: 0.12),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: sized,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            placeholder: (_, _) => _letterFallback(letterSize),
            errorWidget: (_, _, _) => _letterFallback(letterSize),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: store.brandColor,
      child: _letterFallback(letterSize),
    );
  }

  Widget _letterFallback(double size) {
    return Text(
      store.logoLetter,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: size,
      ),
    );
  }
}
