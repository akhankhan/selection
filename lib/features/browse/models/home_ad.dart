import 'package:cloud_firestore/cloud_firestore.dart';

/// Image-only home banner ad managed from the admin panel.
enum HomeAdPlacement { homeTop, homeMid }

extension HomeAdPlacementX on HomeAdPlacement {
  String get firestoreValue =>
      this == HomeAdPlacement.homeTop ? 'home_top' : 'home_mid';

  static HomeAdPlacement fromFirestore(String? value) {
    if (value == 'home_mid') return HomeAdPlacement.homeMid;
    return HomeAdPlacement.homeTop;
  }
}

class HomeAd {
  const HomeAd({
    required this.id,
    required this.imageUrl,
    required this.placement,
    this.linkUrl,
    this.title,
    this.categoryId,
    this.sortOrder = 0,
    this.isEnabled = true,
  });

  final String id;
  final String imageUrl;
  final HomeAdPlacement placement;
  final String? linkUrl;
  final String? title;

  /// When set, tapping the ad switches to this food category tab.
  final String? categoryId;
  final int sortOrder;
  final bool isEnabled;

  factory HomeAd.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final rawCat = (d['categoryId'] as String?)?.trim();
    return HomeAd(
      id: doc.id,
      imageUrl: (d['imageUrl'] as String?)?.trim() ?? '',
      placement: HomeAdPlacementX.fromFirestore(d['placement'] as String?),
      linkUrl: (d['linkUrl'] as String?)?.trim(),
      title: (d['title'] as String?)?.trim(),
      categoryId: rawCat == null || rawCat.isEmpty ? null : rawCat,
      sortOrder: (d['sortOrder'] as num?)?.toInt() ?? 0,
      isEnabled: d['isEnabled'] is bool ? d['isEnabled'] as bool : true,
    );
  }
}
