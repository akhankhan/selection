import 'package:flutter/material.dart';
import 'flyer_item.dart';

class FlyerPage {
  final String imagePath;
  final double aspectRatio;
  final List<FlyerItem> items;

  const FlyerPage({
    required this.imagePath,
    required this.aspectRatio,
    this.items = const [],
  });
}

class Store {
  final String id;
  final String name;
  final String dateRange;
  final String logoLetter;
  final Color brandColor;
  final List<FlyerPage> pages;

  const Store({
    required this.id,
    required this.name,
    required this.dateRange,
    required this.logoLetter,
    required this.brandColor,
    required this.pages,
  });
}
