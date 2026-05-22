import 'dart:ui';
import '../models/flyer_item.dart';

// Bounding boxes are normalised (0..1) to the flyer image and were measured
// from the real artwork: page 1 has a header ending at 0.112 and footer
// starting at 0.922 (5 equal rows of 0.1621); page 2 header ends at 0.089
// and footer starts at 0.952 (5 equal rows of 0.1725). Two equal columns.

const double _p1Top = 0.112;
const double _p1RowH = 0.1621;
const double _p2Top = 0.0894;
const double _p2RowH = 0.1725;

Rect _cell(double top, double rowH, int row, int col) =>
    Rect.fromLTWH(col * 0.5, top + rowH * row, 0.5, rowH);

final List<FlyerItem> page1Items = [
  FlyerItem(
    id: 'p1_1',
    name: 'Raspberries 170g',
    price: '\$2.97',
    oldPrice: null,
    isRollback: false,
    pageIndex: 0,
    boundingBox: _cell(_p1Top, _p1RowH, 0, 0),
  ),
  FlyerItem(
    id: 'p1_2',
    name: 'Blueberries 170g',
    price: '\$2.97',
    oldPrice: null,
    isRollback: false,
    pageIndex: 0,
    boundingBox: _cell(_p1Top, _p1RowH, 0, 1),
  ),
  FlyerItem(
    id: 'p1_3',
    name: 'Mango 1 each',
    price: '\$1.27',
    oldPrice: null,
    isRollback: false,
    pageIndex: 0,
    boundingBox: _cell(_p1Top, _p1RowH, 1, 0),
  ),
  FlyerItem(
    id: 'p1_4',
    name: 'English Cucumber 1 each',
    price: '\$1.27',
    oldPrice: '\$1.47',
    isRollback: true,
    pageIndex: 0,
    boundingBox: _cell(_p1Top, _p1RowH, 1, 1),
  ),
  FlyerItem(
    id: 'p1_5',
    name: 'Bi-Colour Corn Pkg of 4',
    price: '\$2.47',
    oldPrice: '\$2.97',
    isRollback: true,
    pageIndex: 0,
    boundingBox: _cell(_p1Top, _p1RowH, 2, 0),
  ),
  FlyerItem(
    id: 'p1_6',
    name: 'Lean Ground Beef 450g',
    price: '\$6.97',
    oldPrice: null,
    isRollback: false,
    pageIndex: 0,
    boundingBox: _cell(_p1Top, _p1RowH, 2, 1),
  ),
  FlyerItem(
    id: 'p1_7',
    name: 'Johnsonville Sausages 375g',
    price: '\$4.97',
    oldPrice: null,
    isRollback: false,
    pageIndex: 0,
    boundingBox: _cell(_p1Top, _p1RowH, 3, 0),
  ),
  FlyerItem(
    id: 'p1_8',
    name: 'Friskies Cat Food 156g',
    price: '\$1.08',
    oldPrice: null,
    isRollback: false,
    pageIndex: 0,
    boundingBox: _cell(_p1Top, _p1RowH, 3, 1),
  ),
  FlyerItem(
    id: 'p1_9',
    name: 'iogo Yogurt Vanilla 650g',
    price: '\$2.47',
    oldPrice: null,
    isRollback: false,
    pageIndex: 0,
    boundingBox: _cell(_p1Top, _p1RowH, 4, 0),
  ),
  FlyerItem(
    id: 'p1_10',
    name: 'Haagen-Dazs Ice Cream 500ml',
    price: '\$4.97',
    oldPrice: '\$6.47',
    isRollback: true,
    pageIndex: 0,
    boundingBox: _cell(_p1Top, _p1RowH, 4, 1),
  ),
];

final List<FlyerItem> page2Items = [
  FlyerItem(
    id: 'p2_1',
    name: 'Clover Leaf Tuna 170g',
    price: '\$1.14',
    oldPrice: '\$1.92',
    isRollback: true,
    pageIndex: 1,
    boundingBox: _cell(_p2Top, _p2RowH, 0, 0),
  ),
  FlyerItem(
    id: 'p2_2',
    name: 'Black Diamond Cheese 400g',
    price: '\$4.92',
    oldPrice: '\$5.48',
    isRollback: true,
    pageIndex: 1,
    boundingBox: _cell(_p2Top, _p2RowH, 0, 1),
  ),
  FlyerItem(
    id: 'p2_3',
    name: 'Terra Delyssa Olive Oil 1L',
    price: '\$9.97',
    oldPrice: null,
    isRollback: false,
    pageIndex: 1,
    boundingBox: _cell(_p2Top, _p2RowH, 1, 0),
  ),
  FlyerItem(
    id: 'p2_4',
    name: 'Great Value Butter 454g',
    price: '\$4.97',
    oldPrice: '\$5.96',
    isRollback: true,
    pageIndex: 1,
    boundingBox: _cell(_p2Top, _p2RowH, 1, 1),
  ),
  FlyerItem(
    id: 'p2_5',
    name: 'Doritos Tortilla Chips 235g',
    price: '\$3.27',
    oldPrice: '\$3.97',
    isRollback: true,
    pageIndex: 1,
    boundingBox: _cell(_p2Top, _p2RowH, 2, 0),
  ),
  FlyerItem(
    id: 'p2_6',
    name: 'Pepsi 6-Pack Cans 710mL',
    price: '\$3.97',
    oldPrice: '\$5.28',
    isRollback: true,
    pageIndex: 1,
    boundingBox: _cell(_p2Top, _p2RowH, 2, 1),
  ),
  FlyerItem(
    id: 'p2_7',
    name: 'Sunlight Laundry 100 loads',
    price: '\$9.47',
    oldPrice: null,
    isRollback: false,
    pageIndex: 1,
    boundingBox: _cell(_p2Top, _p2RowH, 3, 0),
  ),
  FlyerItem(
    id: 'p2_8',
    name: 'Dempsters Hot Dog Buns 8pk',
    price: '\$2.98',
    oldPrice: '\$3.48',
    isRollback: true,
    pageIndex: 1,
    boundingBox: _cell(_p2Top, _p2RowH, 3, 1),
  ),
  FlyerItem(
    id: 'p2_9',
    name: 'Vachon Jos Louis 324g',
    price: '\$2.98',
    oldPrice: '\$4.28',
    isRollback: true,
    pageIndex: 1,
    boundingBox: _cell(_p2Top, _p2RowH, 4, 0),
  ),
  FlyerItem(
    id: 'p2_10',
    name: 'Miss Vickies Chips 200g',
    price: '\$3.97',
    oldPrice: null,
    isRollback: false,
    pageIndex: 1,
    boundingBox: _cell(_p2Top, _p2RowH, 4, 1),
  ),
];

final List<FlyerItem> allFlyerItems = [...page1Items, ...page2Items];
