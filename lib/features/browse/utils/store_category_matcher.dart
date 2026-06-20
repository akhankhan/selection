import '../../flyer/models/store.dart';

class StoreCategoryMatcher {
  StoreCategoryMatcher._();

  static const searchCategories = [
    'Groceries',
    'Restaurants',
    'Home & Garden',
    'Pharmacy',
    'General Merchandise',
    'Electronics',
    'Automotive',
    'Pets',
    'Office',
    'Specialty',
  ];

  static bool matchesCategory(Store store, String category) {
    final name = store.name.toLowerCase();
    final key = category.toLowerCase();

    switch (key) {
      case 'groceries':
        return name.contains('grocer') ||
            name.contains('market') ||
            name.contains('supermarket') ||
            name.contains('food') ||
            name.contains('metro') ||
            name.contains('sobeys') ||
            name.contains('loblaw') ||
            name.contains('costco') ||
            name.contains('safeway') ||
            name.contains('freshco') ||
            name.contains('no frills') ||
            name.contains('real canadian superstore') ||
            name.contains('walmart') ||
            name.contains('iga');
      case 'restaurants':
        return name.contains('restaurant') ||
            name.contains('mcdonald') ||
            name.contains('burger') ||
            name.contains('pizza') ||
            name.contains('subway') ||
            name.contains('kfc') ||
            name.contains('tim hortons') ||
            name.contains('starbucks') ||
            name.contains('wendy') ||
            name.contains('taco');
      case 'home & garden':
        return name.contains('home') ||
            name.contains('garden') ||
            name.contains('depot') ||
            name.contains('lowe') ||
            name.contains('ikea') ||
            name.contains('canadian tire') ||
            name.contains('hardware') ||
            name.contains('bed bath') ||
            name.contains('renodepot') ||
            name.contains('rona');
      case 'pharmacy':
        return name.contains('pharmacy') ||
            name.contains('drug') ||
            name.contains('shoppers') ||
            name.contains('rexall') ||
            name.contains('pharma') ||
            name.contains('health') ||
            name.contains('london drugs');
      case 'general merchandise':
        return name.contains('walmart') ||
            name.contains('costco') ||
            name.contains('target') ||
            name.contains('dollarama') ||
            name.contains('giant tiger') ||
            name.contains('marshalls') ||
            name.contains('winners');
      case 'electronics':
        return name.contains('electronic') ||
            name.contains('best buy') ||
            name.contains('apple') ||
            name.contains('source') ||
            name.contains('staples') ||
            name.contains('cell') ||
            name.contains('tbooster');
      case 'automotive':
        return name.contains('auto') ||
            name.contains('tire') ||
            name.contains('canadian tire') ||
            name.contains('part') ||
            name.contains('garage') ||
            name.contains('napa');
      case 'pets':
        return name.contains('pet') ||
            name.contains('animal') ||
            name.contains('dog') ||
            name.contains('cat') ||
            name.contains('petsmart') ||
            name.contains('pet valu');
      case 'office':
        return name.contains('office') ||
            name.contains('staples') ||
            name.contains('depot') ||
            name.contains('ink') ||
            name.contains('paper');
      case 'specialty':
        return !matchesCategory(store, 'Groceries') &&
            !name.contains('walmart') &&
            !name.contains('restaurant');
      default:
        return true;
    }
  }
}
