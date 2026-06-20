import '../../flyer/models/store.dart';
import '../models/search_results.dart';

class DealsSearchService {
  DealsSearchService._();

  static SearchResults search(List<Store> stores, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return SearchResults.empty;

    final storeMatches = <Store>[];
    final dealMatches = <DealSearchHit>[];

    for (final store in stores) {
      if (_matchesStore(store, normalized)) {
        storeMatches.add(store);
      }

      for (final page in store.pages) {
        for (final item in page.items) {
          if (_matchesItem(item.name, item.price, normalized)) {
            dealMatches.add(DealSearchHit(store: store, item: item));
          }
        }
      }
    }

    dealMatches.sort(
      (a, b) => a.item.name.toLowerCase().compareTo(b.item.name.toLowerCase()),
    );

    return SearchResults(stores: storeMatches, deals: dealMatches);
  }

  static bool _matchesStore(Store store, String query) {
    return store.name.toLowerCase().contains(query) ||
        store.dateRange.toLowerCase().contains(query);
  }

  static bool _matchesItem(String name, String price, String query) {
    return name.toLowerCase().contains(query) ||
        price.toLowerCase().contains(query);
  }
}
