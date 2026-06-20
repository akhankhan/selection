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

  /// Canadian postal FSA prefixes (e.g. `A1A`, `M5V`). Empty = all areas.
  final List<String> serviceAreas;

  static String postalFsa(String postal) {
    final cleaned = postal.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    return cleaned.length >= 3 ? cleaned.substring(0, 3) : cleaned;
  }

  bool matchesPostal(String userPostal) {
    if (serviceAreas.isEmpty) return true;
    final userFsa = postalFsa(userPostal);
    if (userFsa.isEmpty) return true;
    return serviceAreas.any((area) => postalFsa(area) == userFsa);
  }

  const Store({
    required this.id,
    required this.name,
    required this.dateRange,
    required this.logoLetter,
    required this.brandColor,
    required this.pages,
    this.serviceAreas = const [],
  });

  factory Store.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    List<FlyerPage> pages = const [],
  }) {
    final d = doc.data() ?? const <String, dynamic>{};
    final rawAreas = (d['postalCodes'] as List?) ?? (d['serviceAreas'] as List?);
    final serviceAreas = rawAreas == null
        ? const <String>[]
        : rawAreas.map((value) => value.toString()).toList();

    return Store(
      id: doc.id,
      name: (d['name'] as String?) ?? '',
      dateRange: (d['dateRange'] as String?) ?? '',
      logoLetter: (d['logoLetter'] as String?) ?? '?',
      brandColor: Color((d['brandColor'] as int?) ?? 0xFF0071CE),
      pages: pages,
      serviceAreas: serviceAreas,
    );
  }
}
