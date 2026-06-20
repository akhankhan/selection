class PersistedListItem {
  const PersistedListItem({
    required this.id,
    required this.name,
    required this.sectionTitle,
    this.qty = 1,
    this.checked = false,
    this.saveText,
    this.salePrefix,
    this.priceText,
    this.subtitle,
    this.flyerItemId,
    this.expiresAtIso,
    this.pageImageUrl,
    this.cropLeft,
    this.cropTop,
    this.cropRight,
    this.cropBottom,
  });

  final String id;
  final String name;
  final String sectionTitle;
  final int qty;
  final bool checked;
  final String? saveText;
  final String? salePrefix;
  final String? priceText;
  final String? subtitle;
  final String? flyerItemId;
  final String? expiresAtIso;
  final String? pageImageUrl;
  final double? cropLeft;
  final double? cropTop;
  final double? cropRight;
  final double? cropBottom;

  bool get isFlyerItem =>
      flyerItemId != null &&
      pageImageUrl != null &&
      cropLeft != null &&
      cropTop != null &&
      cropRight != null &&
      cropBottom != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sectionTitle': sectionTitle,
    'qty': qty,
    'checked': checked,
    if (saveText != null) 'saveText': saveText,
    if (salePrefix != null) 'salePrefix': salePrefix,
    if (priceText != null) 'priceText': priceText,
    if (subtitle != null) 'subtitle': subtitle,
    if (flyerItemId != null) 'flyerItemId': flyerItemId,
    if (expiresAtIso != null) 'expiresAtIso': expiresAtIso,
    if (pageImageUrl != null) 'pageImageUrl': pageImageUrl,
    if (cropLeft != null) 'cropLeft': cropLeft,
    if (cropTop != null) 'cropTop': cropTop,
    if (cropRight != null) 'cropRight': cropRight,
    if (cropBottom != null) 'cropBottom': cropBottom,
  };

  factory PersistedListItem.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] as String?;
    return PersistedListItem(
      id: rawId == null || rawId.isEmpty
          ? 'legacy_${json.hashCode}_${DateTime.now().microsecondsSinceEpoch}'
          : rawId,
      name: (json['name'] as String?) ?? '',
      sectionTitle: (json['sectionTitle'] as String?) ?? 'My List',
      qty: (json['qty'] as num?)?.toInt() ?? 1,
      checked: (json['checked'] as bool?) ?? false,
      saveText: json['saveText'] as String?,
      salePrefix: json['salePrefix'] as String?,
      priceText: json['priceText'] as String?,
      subtitle: json['subtitle'] as String?,
      flyerItemId: json['flyerItemId'] as String?,
      expiresAtIso: json['expiresAtIso'] as String?,
      pageImageUrl: json['pageImageUrl'] as String?,
      cropLeft: (json['cropLeft'] as num?)?.toDouble(),
      cropTop: (json['cropTop'] as num?)?.toDouble(),
      cropRight: (json['cropRight'] as num?)?.toDouble(),
      cropBottom: (json['cropBottom'] as num?)?.toDouble(),
    );
  }
}

class PersistedShoppingList {
  const PersistedShoppingList({required this.items});

  final List<PersistedListItem> items;

  Map<String, dynamic> toJson() => {
    'items': items.map((item) => item.toJson()).toList(),
  };

  factory PersistedShoppingList.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) return const PersistedShoppingList(items: []);

    return PersistedShoppingList(
      items: rawItems
          .whereType<Map>()
          .map((item) => PersistedListItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}
