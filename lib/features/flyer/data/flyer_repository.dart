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

  // Local cache memory map to memoize pages and items by store path reference
  final Map<String, List<FlyerPage>> _pagesCache = {};

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
    final futures = snap.docs.map((storeDoc) async {
      final pages = await _loadPages(storeDoc.reference);
      return Store.fromDoc(storeDoc, pages: pages);
    });
    return Future.wait(futures);
  }

  Future<List<FlyerPage>> _loadPages(
    DocumentReference<Map<String, dynamic>> storeRef,
  ) async {
    final String cacheKey = storeRef.path;
    if (_pagesCache.containsKey(cacheKey)) {
      return _pagesCache[cacheKey]!;
    }

    final pagesSnap = await storeRef
        .collection('pages')
        .orderBy('pageIndex')
        .get();

    final futures = pagesSnap.docs.map((pageDoc) async {
      final pageIndex = (pageDoc.data()['pageIndex'] as int?) ?? 0;
      final items = await _loadItems(pageDoc.reference, pageIndex);
      return FlyerPage.fromDoc(pageDoc, items: items);
    });

    final pages = await Future.wait(futures);
    _pagesCache[cacheKey] = pages;
    return pages;
  }

  Future<List<FlyerItem>> _loadItems(
    DocumentReference<Map<String, dynamic>> pageRef,
    int pageIndex,
  ) async {
    final itemsSnap = await pageRef.collection('items').get();
    return itemsSnap.docs.map((d) => FlyerItem.fromDoc(d, pageIndex)).toList();
  }

  /// Clears the memoized cache (e.g. on manual pull-to-refresh).
  void clearCache() {
    _pagesCache.clear();
  }
}
