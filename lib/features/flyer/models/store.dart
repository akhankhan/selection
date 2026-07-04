import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'flyer_item.dart';

enum StoreCardLayout { standard, featured }

enum StoreStatus { upcoming, active, expired, undated }

extension StoreCardLayoutParsing on StoreCardLayout {
  static StoreCardLayout fromFirestore(String? value) {
    if (value == 'featured') return StoreCardLayout.featured;
    return StoreCardLayout.standard;
  }

  String get firestoreValue =>
      this == StoreCardLayout.featured ? 'featured' : 'standard';
}

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
  final String? logoUrl;
  final DateTime? effectiveStart;
  final DateTime? effectiveEnd;
  final List<FlyerPage> pages;

  /// Canadian postal FSA prefixes (e.g. `A1A`, `M5V`). Empty = all areas.
  final List<String> serviceAreas;

  /// Browse grid size — `featured` shows a full-width hero card.
  final StoreCardLayout cardLayout;

  /// Admin toggle — disabled stores are hidden from the consumer app.
  final bool isEnabled;

  bool get isFeatured => cardLayout == StoreCardLayout.featured;

  /// At least one flyer page with an image — required to show in the app.
  bool get hasMenuContent =>
      pages.any((page) => page.imageUrl.trim().isNotEmpty);

  /// First flyer page image for browse cards (menu/flyer only — not store logo).
  String? get previewImageUrl {
    for (final page in pages) {
      final url = page.imageUrl.trim();
      if (url.isNotEmpty) return url;
    }
    return null;
  }

  StoreStatus statusAt(DateTime now) {
    if (effectiveStart == null && effectiveEnd == null) {
      return StoreStatus.undated;
    }
    if (effectiveStart != null && now.isBefore(effectiveStart!)) {
      return StoreStatus.upcoming;
    }
    if (effectiveEnd != null && now.isAfter(effectiveEnd!)) {
      return StoreStatus.expired;
    }
    return StoreStatus.active;
  }

  /// Shown in app when enabled, has menu, and within effective dates.
  bool get isVisibleInApp {
    if (!isEnabled) return false;
    if (!hasMenuContent) return false;
    final status = statusAt(DateTime.now());
    return status == StoreStatus.active || status == StoreStatus.undated;
  }

  bool isVisibleForUser(String userPostal) =>
      isVisibleInApp && matchesPostal(userPostal);

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
    this.logoUrl,
    this.effectiveStart,
    this.effectiveEnd,
    this.serviceAreas = const [],
    this.cardLayout = StoreCardLayout.standard,
    this.isEnabled = true,
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
    final rawLogo = d['logoUrl'] as String?;
    DateTime? toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    return Store(
      id: doc.id,
      name: (d['name'] as String?) ?? '',
      dateRange: (d['dateRange'] as String?) ?? '',
      logoLetter: (d['logoLetter'] as String?) ?? '?',
      brandColor: Color((d['brandColor'] as int?) ?? 0xFF0071CE),
      logoUrl: (rawLogo == null || rawLogo.isEmpty) ? null : rawLogo,
      effectiveStart: toDate(d['effectiveStart']),
      effectiveEnd: toDate(d['effectiveEnd']),
      pages: pages,
      serviceAreas: serviceAreas,
      cardLayout: StoreCardLayoutParsing.fromFirestore(
        d['cardLayout'] as String?,
      ),
      isEnabled: d['isEnabled'] is bool ? d['isEnabled'] as bool : true,
    );
  }
}
