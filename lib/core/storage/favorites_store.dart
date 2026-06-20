import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/account_sync_service.dart';

class FavoritesStore extends ChangeNotifier {
  FavoritesStore._();

  static final FavoritesStore instance = FavoritesStore._();

  static const _key = 'favorite_store_ids';

  final List<String> _orderedIds = [];

  List<String> get orderedIds => List.unmodifiable(_orderedIds);
  Set<String> get ids => _orderedIds.toSet();

  bool contains(String storeId) => _orderedIds.contains(storeId);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _orderedIds
      ..clear()
      ..addAll(prefs.getStringList(_key) ?? const []);
    notifyListeners();
  }

  Future<void> toggle(String storeId) async {
    if (_orderedIds.contains(storeId)) {
      _orderedIds.remove(storeId);
    } else {
      _orderedIds.add(storeId);
    }
    notifyListeners();
    await _save();
  }

  Future<void> remove(String storeId) async {
    if (!_orderedIds.remove(storeId)) return;
    notifyListeners();
    await _save();
  }

  Future<void> setOrdered(List<String> storeIds) async {
    _orderedIds
      ..clear()
      ..addAll(storeIds);
    notifyListeners();
    await _save();
  }

  Future<void> setAll(Set<String> storeIds) async {
    final preserved = [
      for (final id in _orderedIds)
        if (storeIds.contains(id)) id,
    ];
    for (final id in storeIds) {
      if (!preserved.contains(id)) preserved.add(id);
    }
    await setOrdered(preserved);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _orderedIds);
    await AccountSyncService.instance.markFavoritesChangedLocally();
  }
}
