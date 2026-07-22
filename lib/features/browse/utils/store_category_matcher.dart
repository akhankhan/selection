import '../../flyer/models/store.dart';

/// Food / restaurant category matching for browse + search filters.
class StoreCategoryMatcher {
  StoreCategoryMatcher._();

  /// Active food categories shown in search filters and as browse fallbacks.
  static const searchCategories = [
    'Burgers',
    'Pizza',
    'Asian',
    'Mexican',
    'Indian',
    'Cafe',
    'Chicken',
    'Desserts',
    'Seafood',
    'Healthy',
  ];

  // --- Legacy non-food categories (kept for reference; not shown in UI) ---
  // static const legacySearchCategories = [
  //   'Groceries',
  //   'Restaurants',
  //   'Home & Garden',
  //   'Pharmacy',
  //   'General Merchandise',
  //   'Electronics',
  //   'Automotive',
  //   'Pets',
  //   'Office',
  //   'Specialty',
  // ];

  /// Prefer Firestore [Store.categoryIds] when set; otherwise name keywords.
  static bool matchesCategory(
    Store store,
    String category, {
    String? categoryId,
  }) {
    if (categoryId != null &&
        categoryId.isNotEmpty &&
        store.categoryIds.isNotEmpty) {
      return store.categoryIds.contains(categoryId);
    }

    final name = store.name.toLowerCase();
    final key = category.toLowerCase();

    switch (key) {
      case 'burgers':
        return name.contains('burger') ||
            name.contains('mcdonald') ||
            name.contains('wendy') ||
            name.contains('a&w') ||
            name.contains('harvey') ||
            name.contains('five guys');
      case 'pizza':
        return name.contains('pizza') ||
            name.contains('domino') ||
            name.contains('papa john') ||
            name.contains('pizza hut') ||
            name.contains('pizzaiolo');
      case 'asian':
        return name.contains('asian') ||
            name.contains('chinese') ||
            name.contains('thai') ||
            name.contains('sushi') ||
            name.contains('japanese') ||
            name.contains('korean') ||
            name.contains('vietnamese') ||
            name.contains('pho') ||
            name.contains('ramen');
      case 'mexican':
        return name.contains('mexican') ||
            name.contains('taco') ||
            name.contains('burrito') ||
            name.contains('chipotle') ||
            name.contains('quesadilla');
      case 'indian':
        return name.contains('indian') ||
            name.contains('curry') ||
            name.contains('tandoor') ||
            name.contains('biryani') ||
            name.contains('naan');
      case 'cafe':
        return name.contains('cafe') ||
            name.contains('café') ||
            name.contains('coffee') ||
            name.contains('starbucks') ||
            name.contains('tim hortons') ||
            name.contains('bakery') ||
            name.contains('espresso');
      case 'chicken':
        return name.contains('chicken') ||
            name.contains('kfc') ||
            name.contains('popeye') ||
            name.contains('wing') ||
            name.contains('fried chicken');
      case 'desserts':
        return name.contains('dessert') ||
            name.contains('ice cream') ||
            name.contains('gelato') ||
            name.contains('donut') ||
            name.contains('doughnut') ||
            name.contains('cake') ||
            name.contains('sweet');
      case 'seafood':
        return name.contains('seafood') ||
            name.contains('fish') ||
            name.contains('sushi') ||
            name.contains('lobster') ||
            name.contains('shrimp') ||
            name.contains('oyster');
      case 'healthy':
        return name.contains('healthy') ||
            name.contains('salad') ||
            name.contains('vegan') ||
            name.contains('vegetarian') ||
            name.contains('juice') ||
            name.contains('bowl') ||
            name.contains('organic');
      // Legacy grocery/non-food matchers (commented — no longer used in UI):
      // case 'groceries': ...
      // case 'pharmacy': ...
      default:
        return true;
    }
  }
}
