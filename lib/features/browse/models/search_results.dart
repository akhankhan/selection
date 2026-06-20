import '../../flyer/models/flyer_item.dart';
import '../../flyer/models/store.dart';

class DealSearchHit {
  const DealSearchHit({required this.store, required this.item});

  final Store store;
  final FlyerItem item;
}

class SearchResults {
  const SearchResults({required this.stores, required this.deals});

  final List<Store> stores;
  final List<DealSearchHit> deals;

  static const empty = SearchResults(stores: [], deals: []);

  bool get isEmpty => stores.isEmpty && deals.isEmpty;
  bool get isNotEmpty => !isEmpty;
}
