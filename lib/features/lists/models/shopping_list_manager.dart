import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/services/account_sync_service.dart';
import '../../../core/storage/auto_delete_preferences_store.dart';
import '../../flyer/models/flyer_item.dart';
import '../../flyer/widgets/product_thumbnail.dart';
import '../models/list_item.dart';
import '../models/persisted_list_data.dart';
import '../services/shopping_list_storage.dart';
import '../utils/flyer_date_parser.dart';
import '../widgets/flyer_list_thumbnail.dart';
import '../widgets/mock_thumbnails.dart';

class ShoppingListManager extends ChangeNotifier {
  ShoppingListManager._();

  static final ShoppingListManager instance = ShoppingListManager._();
  factory ShoppingListManager() => instance;

  static const _myListTitle = 'My List';

  List<ListSection> _sections = [ListSection(title: _myListTitle, items: [])];
  bool _loaded = false;

  List<ListSection> get sections => _sections;
  bool get isLoaded => _loaded;

  int get totalItemCount {
    var count = 0;
    for (final section in _sections) {
      count += section.items.length;
    }
    return count;
  }

  int get checkedCount {
    var count = 0;
    for (final section in _sections) {
      count += section.items.where((item) => item.checked).length;
    }
    return count;
  }

  int get expiredCount {
    var count = 0;
    for (final section in _sections) {
      count += section.items.where((item) => isFlyerExpired(item.expiresAt)).length;
    }
    return count;
  }

  Future<void> load() async {
    final saved = await ShoppingListStorage.load();
    if (saved == null || saved.items.isEmpty) {
      _sections = [ListSection(title: _myListTitle, items: [])];
      _loaded = true;
      notifyListeners();
      return;
    }

    final sectionMap = <String, List<ListItem>>{};
    for (final persisted in saved.items) {
      sectionMap.putIfAbsent(persisted.sectionTitle, () => []);
      sectionMap[persisted.sectionTitle]!.add(_itemFromPersisted(persisted));
    }

    _sections = sectionMap.entries
        .map((entry) => ListSection(title: entry.key, items: entry.value))
        .toList();

    if (_findSection(_myListTitle) == null) {
      _sections.insert(0, ListSection(title: _myListTitle, items: []));
    }

    final removed = purgeExpiredByPolicy(AutoDeletePreferencesStore.instance.policy);
    if (removed > 0) {
      debugPrint('[ShoppingList] auto-removed $removed expired item(s)');
    }

    _loaded = true;
    notifyListeners();
  }

  bool hasFlyerItem(String flyerItemId, String storeName) {
    final section = _findSection(storeName);
    if (section == null) return false;
    return section.items.any((item) => item.flyerItemId == flyerItemId);
  }

  void addFlyerItem(
    FlyerItem item,
    String storeName,
    ui.Image? flyerImage, {
    String? storeDateRange,
    String? pageImageUrl,
  }) {
    var section = _findSection(storeName);
    if (section == null) {
      section = ListSection(title: storeName, items: []);
      _sections.add(section);
    }

    if (section.items.any((li) => li.flyerItemId == item.id)) {
      return;
    }

    final Rect b = item.boundingBox;
    final Rect photoCrop = Rect.fromLTRB(
      b.left + b.width * 0.03,
      b.top + b.height * 0.07,
      b.left + b.width * 0.52,
      b.bottom - b.height * 0.07,
    );

    String? saveText;
    if (item.oldPrice != null) {
      try {
        final double oldP = double.parse(
          item.oldPrice!.replaceAll('\$', '').trim(),
        );
        final double newP = double.parse(
          item.price.replaceAll('\$', '').trim(),
        );
        final double diff = oldP - newP;
        if (diff > 0) {
          saveText = 'SAVE \$${diff.toStringAsFixed(2)}';
        }
      } catch (_) {
        saveText = 'SALE';
      }
    }

    section.items.add(
      ListItem(
        name: item.name,
        thumbnail: _buildThumbnail(
          flyerImage: flyerImage,
          pageImageUrl: pageImageUrl,
          cropRect: photoCrop,
          manual: false,
        ),
        saveText: saveText,
        salePrefix: item.isRollback ? 'SALE' : null,
        priceText: item.price,
        subtitle: item.isRollback ? 'Rollback' : 'Special Deal',
        flyerItemId: item.id,
        expiresAt: parseFlyerExpiryDate(storeDateRange ?? ''),
        flyerPageImageUrl: pageImageUrl,
        flyerCropRect: photoCrop,
      ),
    );

    _notifyAndPersist();
  }

  void removeFlyerItem(String flyerItemId, String storeName) {
    final section = _findSection(storeName);
    if (section == null) return;

    final initialLength = section.items.length;
    section.items.removeWhere((item) => item.flyerItemId == flyerItemId);

    if (section.items.length != initialLength) {
      if (section.items.isEmpty && storeName != _myListTitle) {
        _sections.remove(section);
      }
      _notifyAndPersist();
    }
  }

  void addItem(String name, String storeName) {
    var section = _findSection(storeName);
    if (section == null) {
      section = ListSection(title: storeName, items: []);
      _sections.add(section);
    }

    section.items.add(
      ListItem(
        name: name,
        thumbnail: _buildThumbnail(manual: true),
      ),
    );

    _notifyAndPersist();
  }

  void setChecked(ListItem item, bool checked) {
    item.checked = checked;
    _notifyAndPersist();
  }

  void setQty(ListItem item, int qty) {
    item.qty = qty;
    _notifyAndPersist();
  }

  void removeItem(ListItem item) {
    for (final section in _sections) {
      final before = section.items.length;
      section.items.removeWhere((candidate) => candidate.id == item.id);
      if (section.items.length != before) {
        if (section.items.isEmpty && section.title != _myListTitle) {
          _sections.remove(section);
        }
        _notifyAndPersist();
        return;
      }
    }
  }

  void renameItem(ListItem item, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == item.name) return;
    item.name = trimmed;
    _notifyAndPersist();
  }

  void reorderItemsInSection(String sectionTitle, int oldIndex, int newIndex) {
    final section = _findSection(sectionTitle);
    if (section == null) return;
    if (oldIndex < 0 ||
        newIndex < 0 ||
        oldIndex >= section.items.length ||
        newIndex >= section.items.length) {
      return;
    }
    if (oldIndex == newIndex) return;
    final moved = section.items.removeAt(oldIndex);
    section.items.insert(newIndex, moved);
    _notifyAndPersist();
  }

  Future<void> importPersisted(PersistedShoppingList data) async {
    _applyPersistedItems(data.items);
    _loaded = true;
    notifyListeners();
    await _persist();
  }

  Future<void> mergeSharedItems(List<PersistedListItem> sharedItems) async {
    if (sharedItems.isEmpty) return;

    final existingIds = <String>{
      for (final section in _sections)
        for (final item in section.items) item.id,
    };

    for (final persisted in sharedItems) {
      if (existingIds.contains(persisted.id)) continue;
      var section = _findSection(persisted.sectionTitle);
      if (section == null) {
        section = ListSection(title: persisted.sectionTitle, items: []);
        _sections.add(section);
      }
      section.items.add(_itemFromPersisted(persisted));
      existingIds.add(persisted.id);
    }

    _notifyAndPersist();
  }

  int deleteChecked() {
    var removed = 0;
    for (final section in _sections) {
      final before = section.items.length;
      section.items.removeWhere((item) => item.checked);
      removed += before - section.items.length;
    }
    _sections.removeWhere((s) => s.items.isEmpty && s.title != _myListTitle);
    _notifyAndPersist();
    return removed;
  }

  int deleteExpired() {
    var removed = 0;
    for (final section in _sections) {
      final before = section.items.length;
      section.items.removeWhere((item) => isFlyerExpired(item.expiresAt));
      removed += before - section.items.length;
    }
    _sections.removeWhere((s) => s.items.isEmpty && s.title != _myListTitle);
    _notifyAndPersist();
    return removed;
  }

  int purgeExpiredByPolicy(AutoDeleteExpiredPolicy policy) {
    final grace = policy.graceAfterExpiry;
    if (grace == null) return 0;

    final now = DateTime.now();
    var removed = 0;
    for (final section in _sections) {
      final before = section.items.length;
      section.items.removeWhere((item) {
        final expiry = item.expiresAt;
        if (expiry == null || !isFlyerExpired(expiry)) return false;
        return now.difference(expiry) >= grace;
      });
      removed += before - section.items.length;
    }
    if (removed > 0) {
      _sections.removeWhere((s) => s.items.isEmpty && s.title != _myListTitle);
      _notifyAndPersist();
    }
    return removed;
  }

  int deleteAll() {
    final removed = totalItemCount;
    for (final section in _sections) {
      section.items.clear();
    }
    _sections.removeWhere((s) => s.items.isEmpty && s.title != _myListTitle);
    _notifyAndPersist();
    return removed;
  }

  Future<void> clearHistory() => ShoppingListStorage.clear();

  ListItem _itemFromPersisted(PersistedListItem persisted) {
    Rect? cropRect;
    if (persisted.cropLeft != null &&
        persisted.cropTop != null &&
        persisted.cropRight != null &&
        persisted.cropBottom != null) {
      cropRect = Rect.fromLTRB(
        persisted.cropLeft!,
        persisted.cropTop!,
        persisted.cropRight!,
        persisted.cropBottom!,
      );
    }

    return ListItem(
      id: persisted.id,
      name: persisted.name,
      thumbnail: _buildThumbnail(
        pageImageUrl: persisted.pageImageUrl,
        cropRect: cropRect,
        manual: !persisted.isFlyerItem,
      ),
      saveText: persisted.saveText,
      salePrefix: persisted.salePrefix,
      priceText: persisted.priceText,
      subtitle: persisted.subtitle,
      qty: persisted.qty,
      checked: persisted.checked,
      flyerItemId: persisted.flyerItemId,
      expiresAt: persisted.expiresAtIso == null
          ? null
          : DateTime.tryParse(persisted.expiresAtIso!),
      flyerPageImageUrl: persisted.pageImageUrl,
      flyerCropRect: cropRect,
    );
  }

  Widget _buildThumbnail({
    ui.Image? flyerImage,
    String? pageImageUrl,
    Rect? cropRect,
    required bool manual,
  }) {
    const size = Size(64, 56);

    if (manual) {
      return const SizedBox(width: 64, height: 56, child: GenericThumbnail());
    }

    if (flyerImage != null && cropRect != null) {
      return SizedBox(
        width: size.width,
        height: size.height,
        child: ProductThumbnail(
          flyerImage: flyerImage,
          cropRect: cropRect,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }

    if (pageImageUrl != null && cropRect != null) {
      return SizedBox(
        width: size.width,
        height: size.height,
        child: FlyerListThumbnail(
          imageUrl: pageImageUrl,
          cropRect: cropRect,
        ),
      );
    }

    return const SizedBox(width: 64, height: 56, child: GenericThumbnail());
  }

  Future<void> _persist() async {
    final items = <PersistedListItem>[];
    for (final section in _sections) {
      for (final item in section.items) {
        items.add(
          PersistedListItem(
            id: item.id,
            name: item.name,
            sectionTitle: section.title,
            qty: item.qty,
            checked: item.checked,
            saveText: item.saveText,
            salePrefix: item.salePrefix,
            priceText: item.priceText,
            subtitle: item.subtitle,
            flyerItemId: item.flyerItemId,
            expiresAtIso: item.expiresAt?.toIso8601String(),
            pageImageUrl: item.flyerPageImageUrl,
            cropLeft: item.flyerCropRect?.left,
            cropTop: item.flyerCropRect?.top,
            cropRight: item.flyerCropRect?.right,
            cropBottom: item.flyerCropRect?.bottom,
          ),
        );
      }
    }

    await ShoppingListStorage.save(PersistedShoppingList(items: items));
  }

  void _applyPersistedItems(List<PersistedListItem> items) {
    final sectionMap = <String, List<ListItem>>{};
    for (final persisted in items) {
      sectionMap.putIfAbsent(persisted.sectionTitle, () => []);
      sectionMap[persisted.sectionTitle]!.add(_itemFromPersisted(persisted));
    }

    _sections = sectionMap.entries
        .map((entry) => ListSection(title: entry.key, items: entry.value))
        .toList();

    if (_findSection(_myListTitle) == null) {
      _sections.insert(0, ListSection(title: _myListTitle, items: []));
    }
  }

  void _notifyAndPersist() {
    notifyListeners();
    unawaited(_persist());
    unawaited(AccountSyncService.instance.markShoppingListChangedLocally());
  }

  ListSection? _findSection(String title) {
    for (final section in _sections) {
      if (section.title == title) return section;
    }
    return null;
  }
}
