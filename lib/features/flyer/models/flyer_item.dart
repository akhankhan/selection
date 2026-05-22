import 'dart:ui';

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
}
