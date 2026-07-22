import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin-managed food category (icon + name) shown in the consumer browse tabs.
class MenuCategory {
  const MenuCategory({
    required this.id,
    required this.name,
    this.iconUrl,
    this.emoji,
    this.keywords = const [],
    this.sortOrder = 0,
    this.isEnabled = true,
  });

  final String id;
  final String name;

  /// Custom uploaded icon image (takes priority over [emoji]).
  final String? iconUrl;

  /// Preset icon the admin picked from the built-in gallery.
  final String? emoji;

  final List<String> keywords;
  final int sortOrder;
  final bool isEnabled;

  factory MenuCategory.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final rawKeywords = d['keywords'] as List?;
    final rawIcon = (d['iconUrl'] as String?)?.trim();
    final rawEmoji = (d['emoji'] as String?)?.trim();
    return MenuCategory(
      id: doc.id,
      name: (d['name'] as String?)?.trim() ?? '',
      iconUrl: rawIcon == null || rawIcon.isEmpty ? null : rawIcon,
      emoji: rawEmoji == null || rawEmoji.isEmpty ? null : rawEmoji,
      keywords: rawKeywords == null
          ? const []
          : rawKeywords.map((e) => e.toString().toLowerCase()).toList(),
      sortOrder: (d['sortOrder'] as num?)?.toInt() ?? 0,
      isEnabled: d['isEnabled'] is bool ? d['isEnabled'] as bool : true,
    );
  }
}
