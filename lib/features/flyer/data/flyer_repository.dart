import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/flyer_item.dart';
import '../models/store.dart';

/// Reads flyer content (stores -> pages -> items) from Firestore.
///
/// Admin panel writes to the same `stores/{id}/pages/{id}/items/{id}` tree.
class FlyerRepository {
  FlyerRepository._();
  static final FlyerRepository instance = FlyerRepository._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Streams the full store list with their pages and items nested in.
  /// Re-emits whenever the top-level stores collection changes.
  Stream<List<Store>> watchStores() {
    return _db
        .collection('stores')
        .orderBy('name')
        .snapshots()
        .asyncMap(_hydrateStores);
  }

  Future<List<Store>> _hydrateStores(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) async {
    final List<Store> stores = [];
    for (final storeDoc in snap.docs) {
      final pages = await _loadPages(storeDoc.reference);
      stores.add(Store.fromDoc(storeDoc, pages: pages));
    }
    return stores;
  }

  Future<List<FlyerPage>> _loadPages(
    DocumentReference<Map<String, dynamic>> storeRef,
  ) async {
    final pagesSnap = await storeRef
        .collection('pages')
        .orderBy('pageIndex')
        .get();
    final List<FlyerPage> pages = [];
    for (final pageDoc in pagesSnap.docs) {
      final items = await _loadItems(
        pageDoc.reference,
        (pageDoc.data()['pageIndex'] as int?) ?? 0,
      );
      pages.add(FlyerPage.fromDoc(pageDoc, items: items));
    }
    return pages;
  }

  Future<List<FlyerItem>> _loadItems(
    DocumentReference<Map<String, dynamic>> pageRef,
    int pageIndex,
  ) async {
    final itemsSnap = await pageRef.collection('items').get();
    return itemsSnap.docs.map((d) => FlyerItem.fromDoc(d, pageIndex)).toList();
  }
}
