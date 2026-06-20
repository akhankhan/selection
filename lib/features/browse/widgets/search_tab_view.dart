import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_extension.dart';
import '../../flyer/models/flyer_item.dart';
import '../../flyer/models/store.dart';
import '../models/search_results.dart';
import '../services/deals_search_service.dart';
import '../services/search_history_service.dart';

class SearchTabView extends StatefulWidget {
  const SearchTabView({
    super.key,
    required this.stores,
    required this.searchController,
    required this.searchFocusNode,
    required this.onOpenStore,
    required this.onOpenDeal,
  });

  final List<Store> stores;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final void Function(List<Store> stores, int storeIndex) onOpenStore;
  final void Function(List<Store> stores, Store store, FlyerItem item)
  onOpenDeal;

  @override
  State<SearchTabView> createState() => _SearchTabViewState();
}

class _SearchTabViewState extends State<SearchTabView> {
  List<String> _recentSearches = [];
  SearchResults _results = SearchResults.empty;

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onQueryChanged);
    _loadRecentSearches();
    _runSearch(widget.searchController.text);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onQueryChanged);
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final recent = await SearchHistoryService.instance.getRecent();
    if (!mounted) return;
    setState(() => _recentSearches = recent);
  }

  void _onQueryChanged() {
    _runSearch(widget.searchController.text);
  }

  void _runSearch(String query) {
    setState(() {
      _results = DealsSearchService.search(widget.stores, query);
    });
  }

  Future<void> _applySearch(String query) async {
    widget.searchController.text = query;
    widget.searchController.selection = TextSelection.collapsed(
      offset: query.length,
    );
    await SearchHistoryService.instance.add(query);
    await _loadRecentSearches();
    _runSearch(query);
  }

  void _clearSearch() {
    widget.searchController.clear();
    _runSearch('');
  }

  int _storeIndex(Store store) {
    return widget.stores.indexWhere((s) => s.id == store.id);
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;
    final query = widget.searchController.text.trim();
    final hasQuery = query.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            controller: widget.searchController,
            focusNode: widget.searchFocusNode,
            textInputAction: TextInputAction.search,
            onSubmitted: _applySearch,
            decoration: InputDecoration(
              hintText: 'Search deals and stores',
              prefixIcon: Icon(Icons.search, color: appTheme.subtitle),
              suffixIcon: hasQuery
                  ? IconButton(
                      icon: Icon(Icons.close, color: appTheme.subtitle),
                      onPressed: _clearSearch,
                    )
                  : null,
              filled: true,
              fillColor: appTheme.searchFill,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: hasQuery ? _buildResults(query) : _buildRecentSearches(),
        ),
      ],
    );
  }

  Widget _buildRecentSearches() {
    final appTheme = context.appTheme;

    if (_recentSearches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 56, color: appTheme.subtitle),
              const SizedBox(height: 16),
              Text(
                'Search for stores or deals',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: appTheme.navyText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try a store name like Walmart or a product like milk.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: appTheme.subtitle,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text(
          'Recent Searches',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: appTheme.navyText,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _recentSearches.map((term) {
            return ActionChip(
              label: Text(term),
              backgroundColor: appTheme.searchFill,
              labelStyle: TextStyle(color: appTheme.navyText),
              side: BorderSide(color: appTheme.border),
              onPressed: () => _applySearch(term),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResults(String query) {
    if (_results.isEmpty) {
      return _buildEmptyResults(query);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      children: [
        if (_results.stores.isNotEmpty) ...[
          _sectionHeader('Stores (${_results.stores.length})'),
          ..._results.stores.map(_buildStoreTile),
        ],
        if (_results.deals.isNotEmpty) ...[
          _sectionHeader('Deals (${_results.deals.length})'),
          ..._results.deals.map(_buildDealTile),
        ],
      ],
    );
  }

  Widget _buildEmptyResults(String query) {
    final appTheme = context.appTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_outlined, size: 56, color: appTheme.subtitle),
            const SizedBox(height: 16),
            Text(
              'No results for "$query"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: appTheme.navyText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different store name or product keyword.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: appTheme.subtitle,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: context.appTheme.navyText,
        ),
      ),
    );
  }

  Widget _buildStoreTile(Store store) {
    final appTheme = context.appTheme;
    final index = _storeIndex(store);
    if (index < 0) return const SizedBox.shrink();

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: store.brandColor,
        child: Text(
          store.logoLetter,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        store.name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: appTheme.navyText,
        ),
      ),
      subtitle: Text(
        store.dateRange,
        style: TextStyle(color: appTheme.subtitle, fontSize: 13),
      ),
      trailing: Icon(Icons.chevron_right, color: appTheme.subtitle),
      onTap: () {
        SearchHistoryService.instance.add(widget.searchController.text.trim());
        widget.onOpenStore(widget.stores, index);
      },
    );
  }

  Widget _buildDealTile(DealSearchHit hit) {
    final appTheme = context.appTheme;
    final storeIndex = _storeIndex(hit.store);
    if (storeIndex < 0) return const SizedBox.shrink();

    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: appTheme.sectionBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: appTheme.border),
        ),
        child: Icon(Icons.local_offer_outlined, color: context.brandBlue),
      ),
      title: Text(
        hit.item.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: appTheme.navyText,
        ),
      ),
      subtitle: Text(
        '${hit.item.price} · ${hit.store.name}',
        style: TextStyle(color: appTheme.subtitle, fontSize: 13),
      ),
      trailing: Icon(Icons.chevron_right, color: appTheme.subtitle),
      onTap: () {
        SearchHistoryService.instance.add(widget.searchController.text.trim());
        widget.onOpenDeal(widget.stores, hit.store, hit.item);
      },
    );
  }
}
