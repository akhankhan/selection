import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'flyer_item.dart';

class FlyerPage {
  final String id;
  final String imageUrl;
  final double aspectRatio;
  final List<FlyerItem> items;

  const FlyerPage({
    required this.id,
    required this.imageUrl,
    required this.aspectRatio,
    this.items = const [],
  });

  factory FlyerPage.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    List<FlyerItem> items = const [],
  }) {
    final d = doc.data() ?? const <String, dynamic>{};
    final w = (d['imageWidth'] as num?)?.toDouble() ?? 1;
    final h = (d['imageHeight'] as num?)?.toDouble() ?? 1;
    return FlyerPage(
      id: doc.id,
      imageUrl: (d['imageUrl'] as String?) ?? '',
      aspectRatio: h == 0 ? 1.0 : w / h,
      items: items,
    );
  }
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

  factory Store.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    List<FlyerPage> pages = const [],
  }) {
    final d = doc.data() ?? const <String, dynamic>{};
    return Store(
      id: doc.id,
      name: (d['name'] as String?) ?? '',
      dateRange: (d['dateRange'] as String?) ?? '',
      logoLetter: (d['logoLetter'] as String?) ?? '?',
      brandColor: Color((d['brandColor'] as int?) ?? 0xFF0071CE),
      pages: pages,
    );
  }
}
