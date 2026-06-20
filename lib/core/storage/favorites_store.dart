import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesStore extends ChangeNotifier {
  FavoritesStore._();

  static final FavoritesStore instance = FavoritesStore._();

  static const _key = 'favorite_store_ids';

  final Set<String> _ids = {};
  Set<String> get ids => Set.unmodifiable(_ids);

  bool contains(String storeId) => _ids.contains(storeId);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _ids
      ..clear()
      ..addAll(prefs.getStringList(_key) ?? const []);
    notifyListeners();
  }

  Future<void> toggle(String storeId) async {
    if (_ids.contains(storeId)) {
      _ids.remove(storeId);
    } else {
      _ids.add(storeId);
    }
    notifyListeners();
    await _save();
  }

  Future<void> setAll(Set<String> storeIds) async {
    _ids
      ..clear()
      ..addAll(storeIds);
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _ids.toList());
  }
}
