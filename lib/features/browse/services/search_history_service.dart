import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  SearchHistoryService._();

  static final SearchHistoryService instance = SearchHistoryService._();

  static const _key = 'search_history';
  static const _maxItems = 10;

  Future<List<String>> getRecent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<void> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final recent = await getRecent();
    recent.removeWhere((term) => term.toLowerCase() == trimmed.toLowerCase());
    recent.insert(0, trimmed);
    if (recent.length > _maxItems) {
      recent.removeRange(_maxItems, recent.length);
    }
    await prefs.setStringList(_key, recent);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
