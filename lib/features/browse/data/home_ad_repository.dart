import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/home_ad.dart';

class HomeAdRepository {
  HomeAdRepository._();
  static final HomeAdRepository instance = HomeAdRepository._();

  Stream<List<HomeAd>> watchEnabled({HomeAdPlacement? placement}) {
    return FirebaseFirestore.instance
        .collection('home_ads')
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) {
      var list = snap.docs
          .map(HomeAd.fromDoc)
          .where((a) => a.isEnabled && a.imageUrl.isNotEmpty)
          .toList();
      if (placement != null) {
        list = list.where((a) => a.placement == placement).toList();
      }
      return list;
    });
  }
}
