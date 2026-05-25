import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';

class FlyerItem {
  final String id;
  final String name;
  final String price;
  final String? oldPrice;
  final bool isRollback;
  final int pageIndex;
  final Rect boundingBox;

  FlyerItem({
    required this.id,
    required this.name,
    required this.price,
    this.oldPrice,
    required this.isRollback,
    required this.pageIndex,
    required this.boundingBox,
  });

  factory FlyerItem.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
    int pageIndex,
  ) {
    final d = doc.data() ?? const <String, dynamic>{};
    final left = (d['bboxLeft'] as num?)?.toDouble() ?? 0;
    final top = (d['bboxTop'] as num?)?.toDouble() ?? 0;
    final width = (d['bboxWidth'] as num?)?.toDouble() ?? 0;
    final height = (d['bboxHeight'] as num?)?.toDouble() ?? 0;
    return FlyerItem(
      id: doc.id,
      name: (d['name'] as String?) ?? '',
      price: (d['price'] as String?) ?? '',
      oldPrice: d['oldPrice'] as String?,
      isRollback: (d['isRollback'] as bool?) ?? false,
      pageIndex: pageIndex,
      boundingBox: Rect.fromLTWH(left, top, width, height),
    );
  }
}
