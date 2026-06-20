class SearchFilters {
  const SearchFilters({
    this.minPrice,
    this.maxPrice,
    this.category,
  });

  final double? minPrice;
  final double? maxPrice;
  final String? category;

  static const none = SearchFilters();

  bool get hasActiveFilters =>
      minPrice != null || maxPrice != null || (category != null && category!.isNotEmpty);

  SearchFilters copyWith({
    double? minPrice,
    double? maxPrice,
    String? category,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearCategory = false,
  }) {
    return SearchFilters(
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      category: clearCategory ? null : (category ?? this.category),
    );
  }
}
