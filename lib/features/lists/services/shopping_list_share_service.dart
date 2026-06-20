import 'package:share_plus/share_plus.dart';

import '../models/shopping_list_manager.dart';

class ShoppingListShareService {
  ShoppingListShareService._();

  static String formatList(ShoppingListManager manager) {
    if (manager.totalItemCount == 0) {
      return 'My MENU2GO shopping list is empty.';
    }

    final buffer = StringBuffer('My MENU2GO shopping list\n\n');
    for (final section in manager.sections) {
      if (section.items.isEmpty) continue;
      buffer.writeln('${section.title}:');
      for (final item in section.items) {
        final marker = item.checked ? '[x]' : '[ ]';
        final qty = item.qty > 1 ? ' (x${item.qty})' : '';
        final price = item.priceText != null ? ' — ${item.priceText}' : '';
        buffer.writeln('$marker ${item.name}$qty$price');
      }
      buffer.writeln();
    }
    buffer.writeln('Shared from MENU2GO');
    return buffer.toString().trim();
  }

  static Future<void> shareCurrentList() async {
    final manager = ShoppingListManager.instance;
    if (manager.totalItemCount == 0) {
      throw StateError('Add items to your list before sharing.');
    }
    await SharePlus.instance.share(
      ShareParams(text: formatList(manager)),
    );
  }
}
