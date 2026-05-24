import 'package:flutter/material.dart';

class ListItem {
  ListItem({
    required this.name,
    required this.thumbnail,
    this.saveText,
    this.salePrefix,
    this.priceText,
    this.priceColor = Colors.black,
    this.subtitle,
    this.qty = 1,
    this.checked = false,
    this.flyerItemId,
  });

  final String name;
  final Widget thumbnail;
  final String? saveText;
  final String? salePrefix;
  final String? priceText;
  final Color priceColor;
  final String? subtitle;
  int qty;
  bool checked;
  final String? flyerItemId;
}

class ListSection {
  ListSection({required this.title, required this.items});

  final String title;
  final List<ListItem> items;
}
