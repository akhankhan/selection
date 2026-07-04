import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/flyer/models/store.dart';

class LocationStore extends ChangeNotifier {
  LocationStore._();

  static final LocationStore instance = LocationStore._();

  static const _key = 'user_postal_code';
  static const defaultPostal = 'A1A 1A1';

  String _postal = defaultPostal;
  String get postal => _postal;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _postal = prefs.getString(_key) ?? defaultPostal;
    notifyListeners();
  }

  Future<void> setPostal(String postal) async {
    final normalized = postal.trim().toUpperCase();
    if (normalized.isEmpty || normalized == _postal) return;

    _postal = normalized;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _postal);
  }

  List<Store> filterStores(List<Store> stores) {
    return stores.where((store) => store.isVisibleForUser(_postal)).toList();
  }

  /// Stores hidden only because of the current postal code (for location snackbar).
  int hiddenByLocationCount(List<Store> stores) {
    return stores
        .where((s) => s.isVisibleInApp)
        .where((s) => !s.matchesPostal(_postal))
        .length;
  }
}
