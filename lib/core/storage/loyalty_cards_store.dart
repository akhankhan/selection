import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/settings/models/loyalty_card.dart';

class LoyaltyCardsStore extends ChangeNotifier {
  LoyaltyCardsStore._();

  static final LoyaltyCardsStore instance = LoyaltyCardsStore._();

  static const _key = 'loyalty_cards_v1';

  final List<LoyaltyCard> _cards = [];
  List<LoyaltyCard> get cards => List.unmodifiable(_cards);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _cards.clear();
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _cards.addAll(
        decoded
            .whereType<Map<String, dynamic>>()
            .map(LoyaltyCard.fromJson),
      );
    }
    notifyListeners();
  }

  Future<void> add(LoyaltyCard card) async {
    _cards.add(card);
    notifyListeners();
    await _save();
  }

  Future<void> removeAt(int index) async {
    if (index < 0 || index >= _cards.length) return;
    _cards.removeAt(index);
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_cards.map((c) => c.toJson()).toList());
    await prefs.setString(_key, encoded);
  }
}
