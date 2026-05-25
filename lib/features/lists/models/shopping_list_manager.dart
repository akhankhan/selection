import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../flyer/models/flyer_item.dart';
import '../../flyer/widgets/product_thumbnail.dart';
import '../widgets/mock_thumbnails.dart';
import 'list_item.dart';

class ShoppingListManager extends ChangeNotifier {
  static final ShoppingListManager _instance = ShoppingListManager._internal();
  factory ShoppingListManager() => _instance;

  ShoppingListManager._internal() {
    _sections = [ListSection(title: 'My List', items: [])];
  }

  late final List<ListSection> _sections;
  List<ListSection> get sections => _sections;

  int get totalItemCount {
    int count = 0;
    for (final section in _sections) {
      count += section.items.length;
    }
    return count;
  }

  // Checks if a flyer item exists in the list
  bool hasFlyerItem(String flyerItemId, String storeName) {
    final section = _findSection(storeName);
    if (section == null) return false;
    return section.items.any((item) => item.flyerItemId == flyerItemId);
  }

  // Adds an item selected from the flyer
  void addFlyerItem(FlyerItem item, String storeName, ui.Image? flyerImage) {
    // 1. Find or create the section
    var section = _findSection(storeName);
    if (section == null) {
      section = ListSection(title: storeName, items: []);
      _sections.add(section);
    }

    // 2. Prevent duplicate additions
    if (section.items.any((li) => li.flyerItemId == item.id)) {
      return;
    }

    // 3. Compute crop rectangle for the flyer item (matches DealSheet)
    final Rect b = item.boundingBox;
    final Rect photoCrop = Rect.fromLTRB(
      b.left + b.width * 0.03,
      b.top + b.height * 0.07,
      b.left + b.width * 0.52,
      b.bottom - b.height * 0.07,
    );

    // 4. Safely calculate the price savings if oldPrice exists
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

    // 5. Create new ListItem
    final listItem = ListItem(
      name: item.name,
      thumbnail: SizedBox(
        width: 64,
        height: 56,
        child: ProductThumbnail(
          flyerImage: flyerImage,
          cropRect: photoCrop,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      saveText: saveText,
      salePrefix: item.isRollback ? 'SALE' : null,
      priceText: item.price,
      subtitle: item.isRollback ? 'Rollback' : 'Special Deal',
      flyerItemId: item.id,
    );

    section.items.add(listItem);
    notifyListeners();
  }

  // Removes an item selected from the flyer
  void removeFlyerItem(String flyerItemId, String storeName) {
    final section = _findSection(storeName);
    if (section == null) return;

    final initialLength = section.items.length;
    section.items.removeWhere((item) => item.flyerItemId == flyerItemId);

    if (section.items.length != initialLength) {
      if (section.items.isEmpty && storeName != 'My List') {
        _sections.remove(section);
      }
      notifyListeners();
    }
  }

  // Adds a custom item to a section
  void addItem(String name, String storeName) {
    var section = _findSection(storeName);
    if (section == null) {
      section = ListSection(title: storeName, items: []);
      _sections.add(section);
    }

    final listItem = ListItem(name: name, thumbnail: const GenericThumbnail());

    section.items.add(listItem);
    notifyListeners();
  }

  // Toggles checked status of an item
  void setChecked(ListItem item, bool checked) {
    item.checked = checked;
    notifyListeners();
  }

  // Changes quantity of an item
  void setQty(ListItem item, int qty) {
    item.qty = qty;
    notifyListeners();
  }

  // Deletes all checked items
  void deleteChecked() {
    for (final section in _sections) {
      section.items.removeWhere((item) => item.checked);
    }
    // Clean up empty store sections (except My List)
    _sections.removeWhere((s) => s.items.isEmpty && s.title != 'My List');

    notifyListeners();
  }

  // Deletes all items
  void deleteAll() {
    for (final section in _sections) {
      section.items.clear();
    }
    // Clean up all empty store sections (except My List)
    _sections.removeWhere((s) => s.items.isEmpty && s.title != 'My List');

    notifyListeners();
  }

  ListSection? _findSection(String title) {
    for (final section in _sections) {
      if (section.title == title) return section;
    }
    return null;
  }
}
