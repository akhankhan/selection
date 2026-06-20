import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/persisted_list_data.dart';

class ShoppingListStorage {
  ShoppingListStorage._();

  static const _key = 'shopping_list_v1';

  static Future<PersistedShoppingList?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return PersistedShoppingList.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(PersistedShoppingList data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data.toJson()));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
