import 'package:flutter/material.dart';

class ListItem {
  ListItem({
    String? id,
    required this.name,
    required this.thumbnail,
    this.saveText,
    this.salePrefix,
    this.priceText,
    this.priceColor,
    this.subtitle,
    this.qty = 1,
    this.checked = false,
    this.flyerItemId,
    this.expiresAt,
    this.flyerPageImageUrl,
    this.flyerCropRect,
  }) : id = id ?? _newId();

  static int _idCounter = 0;

  static String _newId() {
    _idCounter += 1;
    return 'item_${DateTime.now().microsecondsSinceEpoch}_$_idCounter';
  }

  final String id;
  String name;
  final Widget thumbnail;
  final String? saveText;
  final String? salePrefix;
  final String? priceText;
  final Color? priceColor;
  final String? subtitle;
  int qty;
  bool checked;
  final String? flyerItemId;
  final DateTime? expiresAt;
  final String? flyerPageImageUrl;
  final Rect? flyerCropRect;
}

class ListSection {
  ListSection({required this.title, required this.items});

  final String title;
  final List<ListItem> items;
}
