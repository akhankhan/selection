import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/menu_category.dart';

class MenuCategoryRepository {
  MenuCategoryRepository._();
  static final MenuCategoryRepository instance = MenuCategoryRepository._();

  Stream<List<MenuCategory>> watchEnabled() {
    return FirebaseFirestore.instance
        .collection('menu_categories')
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map(MenuCategory.fromDoc)
          .where((c) => c.isEnabled && c.name.isNotEmpty)
          .toList();
      return list;
    });
  }
}
