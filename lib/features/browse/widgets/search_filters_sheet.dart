import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_extension.dart';
import '../models/search_filters.dart';
import '../utils/store_category_matcher.dart';

class SearchFiltersSheet extends StatefulWidget {
  const SearchFiltersSheet({
    super.key,
    required this.initialFilters,
  });

  final SearchFilters initialFilters;

  static Future<SearchFilters?> show(
    BuildContext context, {
    required SearchFilters initialFilters,
  }) {
    return showModalBottomSheet<SearchFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SearchFiltersSheet(initialFilters: initialFilters),
    );
  }

  @override
  State<SearchFiltersSheet> createState() => _SearchFiltersSheetState();
}

class _SearchFiltersSheetState extends State<SearchFiltersSheet> {
  late final TextEditingController _minPriceController;
  late final TextEditingController _maxPriceController;
  String? _category;

  @override
  void initState() {
    super.initState();
    _minPriceController = TextEditingController(
      text: widget.initialFilters.minPrice?.toStringAsFixed(2) ?? '',
    );
    _maxPriceController = TextEditingController(
      text: widget.initialFilters.maxPrice?.toStringAsFixed(2) ?? '',
    );
    _category = widget.initialFilters.category;
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  SearchFilters _buildFilters() {
    final min = double.tryParse(_minPriceController.text.trim());
    final max = double.tryParse(_maxPriceController.text.trim());
    return SearchFilters(
      minPrice: min,
      maxPrice: max,
      category: _category,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: appTheme.subtitle.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Search filters',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: appTheme.navyText,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Price range',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: appTheme.navyText,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPriceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Min',
                      prefixText: '\$ ',
                      filled: true,
                      fillColor: appTheme.searchFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxPriceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Max',
                      prefixText: '\$ ',
                      filled: true,
                      fillColor: appTheme.searchFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Category',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: appTheme.navyText,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _category,
              decoration: InputDecoration(
                filled: true,
                fillColor: appTheme.searchFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All categories'),
                ),
                ...StoreCategoryMatcher.searchCategories.map(
                  (category) => DropdownMenuItem<String?>(
                    value: category,
                    child: Text(category),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _category = value),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, SearchFilters.none),
                  child: Text('Clear', style: TextStyle(color: appTheme.subtitle)),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _buildFilters()),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.brandBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply filters'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
