import '../../flyer/models/flyer_item.dart';
import '../../flyer/models/store.dart';
import '../models/search_filters.dart';
import '../models/search_results.dart';
import '../utils/store_category_matcher.dart';

class DealsSearchService {
  DealsSearchService._();

  static SearchResults search(
    List<Store> stores,
    String query, {
    SearchFilters filters = SearchFilters.none,
  }) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty && !filters.hasActiveFilters) {
      return SearchResults.empty;
    }

    final storeMatches = <Store>[];
    final dealMatches = <DealSearchHit>[];

    for (final store in stores) {
      if (filters.category != null &&
          !StoreCategoryMatcher.matchesCategory(store, filters.category!)) {
        continue;
      }

      final storeMatchesQuery =
          normalized.isEmpty || _matchesStore(store, normalized);
      if (storeMatchesQuery) {
        storeMatches.add(store);
      }

      for (final page in store.pages) {
        for (final item in page.items) {
          if (!_matchesFilters(item, normalized, filters)) continue;
          dealMatches.add(DealSearchHit(store: store, item: item));
        }
      }
    }

    dealMatches.sort(
      (a, b) => a.item.name.toLowerCase().compareTo(b.item.name.toLowerCase()),
    );

    return SearchResults(stores: storeMatches, deals: dealMatches);
  }

  static bool _matchesFilters(
    FlyerItem item,
    String query,
    SearchFilters filters,
  ) {
    if (query.isNotEmpty && !_matchesItem(item.name, item.price, query)) {
      return false;
    }

    final price = _parsePrice(item.price);
    if (filters.minPrice != null &&
        (price == null || price < filters.minPrice!)) {
      return false;
    }
    if (filters.maxPrice != null &&
        (price == null || price > filters.maxPrice!)) {
      return false;
    }

    return query.isNotEmpty || filters.hasActiveFilters;
  }

  static double? _parsePrice(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
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
