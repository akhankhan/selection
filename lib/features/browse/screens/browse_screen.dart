import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/storage/favorites_store.dart';
import '../../../core/storage/location_store.dart';
import '../../../core/storage/notification_inbox_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_theme_extension.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../flyer/data/flyer_repository.dart';
import '../../flyer/models/flyer_item.dart';
import '../../flyer/models/store.dart';
import '../../flyer/screens/flyer_viewer_screen.dart';
import '../../lists/screens/lists_screen.dart';
import '../../notifications/data/notification_repository.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../settings/screens/help_support_screen.dart';
import '../../settings/screens/my_cards_screen.dart';
import '../../settings/screens/request_store_screen.dart';
import '../../settings/services/push_notification_service.dart';
import 'edit_favorites_screen.dart';
import '../widgets/browse_loading_shimmer.dart';
import '../widgets/featured_store_card.dart';
import '../widgets/store_card.dart';
import '../widgets/search_tab_view.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  static const List<String> _categories = [
    'Favorites',
    'Explore',
    'Latest',
    'A-Z',
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

  final ValueNotifier<int> _selectedCategory = ValueNotifier<int>(1);
  int _bottomNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late PageController _pageController;
  final ScrollController _tabsScrollController = ScrollController();

  /// Memoized per-category filter result. Keyed by category index, valid as
  /// long as [_filterCacheStoresId] matches the current `stores` list
  /// identity. Toggling a favorite or receiving a new stores snapshot
  /// invalidates the cache.
  final Map<int, List<Store>> _filterCache = {};
  Object? _filterCacheStoresId;
  String? _filterCacheLocationId;
  List<Store> _allStores = const [];
  int _storeReloadToken = 0;
  Object? _favoritesPruneSource;

  void _scheduleFavoritesPrune(List<Store> stores) {
    if (identical(_favoritesPruneSource, stores)) return;
    _favoritesPruneSource = stores;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FavoritesStore.instance.pruneForStores(stores);
    });
  }

  void _retryStoreLoad() {
    FlyerRepository.instance.clearCache();
    setState(() => _storeReloadToken++);
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedCategory.value);
    _pageController.addListener(_onPageScroll);
    _searchController.addListener(_onSearchTextChanged);
    FavoritesStore.instance.addListener(_onBrowseDataChanged);
    LocationStore.instance.addListener(_onBrowseDataChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppNavigator.handlePendingInviteIfAny();
      unawaited(
        PushNotificationService.instance.schedulePermissionPromptWhenReady(),
      );
    });
  }

  void _onBrowseDataChanged() {
    if (mounted) setState(() {});
  }

  void _onSearchTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _searchController.removeListener(_onSearchTextChanged);
    FavoritesStore.instance.removeListener(_onBrowseDataChanged);
    LocationStore.instance.removeListener(_onBrowseDataChanged);
    _pageController.dispose();
    _tabsScrollController.dispose();
    _selectedCategory.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  double _getTabWidth(int categoryIndex) {
    if (categoryIndex == 0) return 56.0;
    final name = _categories[categoryIndex];
    // Approximate character width in pixels + horizontal padding of 24
    return name.length * 8.5 + 24.0;
  }

  void _onPageScroll() {
    if (!_pageController.hasClients) return;
    final double? page = _pageController.page;
    if (page == null) return;

    final int roundedIndex = page.round();
    if (roundedIndex != _selectedCategory.value) {
      _selectedCategory.value = roundedIndex;
      _scrollToCategoryTab(roundedIndex);
    }
  }

  void _selectCategory(int index) {
    if (_selectedCategory.value != index) {
      _selectedCategory.value = index;
    }
    _scrollToCategoryTab(index);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _syncPageControllerToCategory() {
    if (!mounted || !_pageController.hasClients) return;
    final target = _selectedCategory.value;
    final current = _pageController.page?.round() ?? target;
    if (current != target) {
      _pageController.jumpToPage(target);
    }
  }

  void _scrollToCategoryTab(int index) {
    if (!_tabsScrollController.hasClients) return;

    double targetOffset = 0.0;
    if (index > 0) {
      final double screenWidth = MediaQuery.of(context).size.width;
      final double viewportWidth = screenWidth - 57.0;

      double tabStartOffset = 0.0;
      for (int i = 1; i < index; i++) {
        tabStartOffset += _getTabWidth(i);
      }
      final double targetTabWidth = _getTabWidth(index);
      final double tabCenter = tabStartOffset + (targetTabWidth / 2.0);

      targetOffset = tabCenter - (viewportWidth / 2.0);
    }

    _tabsScrollController.animateTo(
      targetOffset.clamp(0.0, _tabsScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  List<Store> _filterStoresByCategory(List<Store> stores, int index) {
    final locationKey = LocationStore.instance.postal;
    if (!identical(stores, _filterCacheStoresId) ||
        locationKey != _filterCacheLocationId) {
      _filterCache.clear();
      _filterCacheStoresId = stores;
      _filterCacheLocationId = locationKey;
    }
    // Favorites is the one case the cache must skip — toggling a heart
    // doesn't change the stores list identity, but the filtered subset
    // changes. The other categories are pure functions of (stores, index).
    if (index != 0) {
      final cached = _filterCache[index];
      if (cached != null) return cached;
    }
    final result = _computeFilteredStores(stores, index);
    if (index != 0) _filterCache[index] = result;
    return result;
  }

  List<Store> _computeFilteredStores(List<Store> stores, int index) {
    if (index == 0) {
      return stores
          .where((s) => FavoritesStore.instance.contains(s.id))
          .toList();
    }
    if (index == 1) {
      return stores; // Explore: all stores
    }
    if (index == 2) {
      return stores; // Latest: handled separately with Upcoming & New
    }
    if (index == 3) {
      // A-Z: all stores sorted alphabetically by name
      final list = List<Store>.from(stores);
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    }

    final category = _categories[index].toLowerCase();
    return stores.where((store) {
      final name = store.name.toLowerCase();
      if (category == 'groceries') {
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
      } else if (category == 'restaurants') {
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
      } else if (category == 'home & garden') {
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
      } else if (category == 'pharmacy') {
        return name.contains('pharmacy') ||
            name.contains('drug') ||
            name.contains('shoppers') ||
            name.contains('rexall') ||
            name.contains('pharma') ||
            name.contains('health') ||
            name.contains('london drugs');
      } else if (category == 'general merchandise') {
        return name.contains('walmart') ||
            name.contains('costco') ||
            name.contains('target') ||
            name.contains('dollarama') ||
            name.contains('giant tiger') ||
            name.contains('marshalls') ||
            name.contains('winners');
      } else if (category == 'electronics') {
        return name.contains('electronic') ||
            name.contains('best buy') ||
            name.contains('apple') ||
            name.contains('source') ||
            name.contains('staples') ||
            name.contains('cell') ||
            name.contains('tbooster');
      } else if (category == 'automotive') {
        return name.contains('auto') ||
            name.contains('tire') ||
            name.contains('canadian tire') ||
            name.contains('part') ||
            name.contains('garage') ||
            name.contains('napa');
      } else if (category == 'pets') {
        return name.contains('pet') ||
            name.contains('animal') ||
            name.contains('dog') ||
            name.contains('cat') ||
            name.contains('petsmart') ||
            name.contains('pet valu');
      } else if (category == 'office') {
        return name.contains('office') ||
            name.contains('staples') ||
            name.contains('depot') ||
            name.contains('ink') ||
            name.contains('paper');
      } else if (category == 'specialty') {
        return !name.contains('grocer') &&
            !name.contains('walmart') &&
            !name.contains('sobeys') &&
            !name.contains('shoppers') &&
            !name.contains('home');
      }
      return false;
    }).toList();
  }

  void _openStore(List<Store> stores, int storeIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            FlyerViewerScreen(stores: stores, initialStoreIndex: storeIndex),
      ),
    );
  }

  void _openStoreEntry(Store store, List<Store> stores) {
    final index = stores.indexWhere((s) => s.id == store.id);
    if (index >= 0) _openStore(stores, index);
  }

  List<Widget> _mixedStoreSlivers({
    required List<Store> stores,
    required bool isPageActive,
  }) {
    final featured = stores.where((s) => s.isFeatured).toList();
    final standard = stores.where((s) => !s.isFeatured).toList();
    final slivers = <Widget>[];

    for (var i = 0; i < featured.length; i++) {
      final store = featured[i];
      slivers.add(
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, i == 0 ? 8 : 0, 16, 14),
          sliver: SliverToBoxAdapter(
            child: StaggeredGridEntry(
              key: ValueKey('${store.id}_feat_${isPageActive ? "on" : "off"}'),
              index: i,
              child: FeaturedStoreCard(
                store: store,
                isFavorited: FavoritesStore.instance.contains(store.id),
                onFavoriteToggle: () {
                  FavoritesStore.instance.toggle(store.id);
                },
                onTap: () => _openStoreEntry(store, stores),
              ),
            ),
          ),
        ),
      );
    }

    if (standard.isNotEmpty) {
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.74,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final store = standard[i];
                return StaggeredGridEntry(
                  key: ValueKey(
                    '${store.id}_std_${isPageActive ? "on" : "off"}',
                  ),
                  index: featured.length + i,
                  child: StoreCard(
                    store: store,
                    isFavorited: FavoritesStore.instance.contains(store.id),
                    onFavoriteToggle: () {
                      FavoritesStore.instance.toggle(store.id);
                    },
                    onTap: () => _openStoreEntry(store, stores),
                  ),
                );
              },
              childCount: standard.length,
            ),
          ),
        ),
      );
    }

    return slivers;
  }

  void _activateSearch() {
    setState(() => _bottomNavIndex = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _openDealFromSearch(List<Store> stores, Store store, FlyerItem item) {
    final allForViewer = LocationStore.instance.filterStores(_allStores);
    final storeIndex = allForViewer.indexWhere((s) => s.id == store.id);
    if (storeIndex < 0) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FlyerViewerScreen(
          stores: allForViewer,
          initialStoreIndex: storeIndex,
          initialFlyerItem: item,
          initialFlyerPageIndex: item.pageIndex,
        ),
      ),
    );
  }

  void _showChangeLocationDialog() {
    final controller = TextEditingController(text: LocationStore.instance.postal);
    final appTheme = context.appTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: appTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
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
              const SizedBox(height: 20),
              Text(
                'Change Location',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: appTheme.navyText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter a postal code to see flyers and deals in that area.',
                style: TextStyle(fontSize: 14, color: appTheme.subtitle),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'e.g. M5V 2H1 or K1A 0B1',
                  hintStyle: TextStyle(
                    color: appTheme.subtitle.withValues(alpha: 0.6),
                  ),
                  filled: true,
                  fillColor: appTheme.searchFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final newLoc = controller.text.trim();
                    if (newLoc.isEmpty) return;

                    final messenger = ScaffoldMessenger.of(context);
                    final snackColor = context.brandBlue;

                    await LocationStore.instance.setPostal(newLoc);
                    if (!sheetContext.mounted) return;
                    Navigator.pop(sheetContext);

                    final hidden =
                        LocationStore.instance.hiddenByLocationCount(_allStores);
                    final postal = LocationStore.instance.postal;
                    final message = hidden > 0
                        ? 'Location set to $postal. $hidden store${hidden == 1 ? '' : 's'} not in this area.'
                        : 'Location updated to $postal.';

                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: snackColor,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.brandBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Update Location',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayFor(Theme.of(context).brightness),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildAppBar(),
        body: SafeArea(
        top: false,
        child: StreamBuilder<List<Store>>(
          key: ValueKey(_storeReloadToken),
          stream: FlyerRepository.instance.watchStores(),
          builder: (context, snap) {
            if (snap.hasError) {
              return ErrorStateView(
                message:
                    'We could not load flyers right now. Check your connection and try again.',
                onRetry: _retryStoreLoad,
              );
            }
            if (!snap.hasData) {
              return Stack(
                children: [
                  const Positioned.fill(child: BrowseLoadingShimmer()),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildFloatingHeader(),
                  ),
                ],
              );
            }
            _allStores = snap.data!;
            _scheduleFavoritesPrune(_allStores);
            final stores = LocationStore.instance.filterStores(_allStores);
            if (_bottomNavIndex == 1) {
              return SearchTabView(
                stores: stores,
                searchController: _searchController,
                searchFocusNode: _searchFocusNode,
                onOpenStore: _openStore,
                onOpenDeal: _openDealFromSearch,
              );
            }
            return Stack(
              children: [
                // 1. Scrollable PageView content (rendered underneath)
                Positioned.fill(
                  child: Builder(
                    builder: (context) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _syncPageControllerToCategory();
                      });
                      return PageView.builder(
                        controller: _pageController,
                        itemCount: _categories.length,
                        onPageChanged: (index) {
                          _selectedCategory.value = index;
                        },
                        itemBuilder: (context, index) {
                      if (index == 0) {
                        // Favorites heart tab
                        final favStores = _filterStoresByCategory(stores, 0);
                        if (favStores.isEmpty) {
                          return _buildEmptyFavorites();
                        }
                        return _buildStoreGrid(favStores, 'Your Favorites', 0);
                      } else if (index == 2) {
                        // Latest
                        return _buildLatest(stores);
                      } else {
                        // Explore (index 1), A-Z (index 3), and general category filter
                        final filtered = _filterStoresByCategory(stores, index);
                        final String categoryName = _categories[index];
                        final String title = index == 1
                            ? 'New This Week'
                            : categoryName;
                        if (index > 3 && filtered.isEmpty) {
                          return _buildEmptyCategory(categoryName);
                        }
                        return _buildStoreGrid(filtered, title, index);
                      }
                    },
                      );
                    },
                  ),
                ),

                // 2. Premium frosted glassmorphic floating top header bar.
                // Sigma is kept modest (6, not 10) — Gaussian blur cost scales
                // with sigma², so 6 is roughly a third the per-frame work
                // while still reading as a frosted pane. The inner static
                // controls live behind a RepaintBoundary so they don't get
                // recomposited every time the blur re-evaluates.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildFloatingHeader(),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildFloatingHeader() {
    final appTheme = context.appTheme;
    final header = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSearchBar(),
        _buildCategoryTabs(),
        Divider(height: 1, color: Theme.of(context).dividerColor),
      ],
    );

    if (context.isDarkMode) {
      return Container(
        color: appTheme.headerSurface,
        child: header,
      );
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
        child: Container(
          color: appTheme.headerSurface.withValues(alpha: 0.92),
          child: RepaintBoundary(child: header),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final appTheme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final appBarTheme = Theme.of(context).appBarTheme;

    return AppBar(
      backgroundColor: appBarTheme.backgroundColor,
      foregroundColor: appBarTheme.foregroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: appBarTheme.systemOverlayStyle,
      toolbarHeight: 60,
      titleSpacing: 16,
      title: InkWell(
        onTap: _showChangeLocationDialog,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/branding/app_logo.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Savings from:',
                    style: TextStyle(fontSize: 12, color: appTheme.subtitle),
                  ),
                  Text(
                    LocationStore.instance.postal,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: context.brandBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        ListenableBuilder(
          listenable: NotificationInboxStore.instance,
          builder: (context, _) {
            return StreamBuilder(
              stream: NotificationRepository.instance.watchInbox(),
              builder: (context, snapshot) {
                final unread = NotificationInboxStore.instance.unreadCountFor(
                  snapshot.data ?? const [],
                );
                return Badge(
                  isLabelVisible: unread > 0,
                  offset: const Offset(2, -10),
                  label: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: const Color(0xFFEC3090),
                  child: IconButton(
                    icon: Icon(
                      unread > 0
                          ? Icons.notifications
                          : Icons.notifications_outlined,
                      color: colorScheme.onSurface,
                      size: 26,
                    ),
                    tooltip: 'Notifications',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.settings_outlined,
            color: colorScheme.onSurface,
            size: 26,
          ),
          color: appTheme.cardSurface,
          surfaceTintColor: Colors.transparent,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          offset: const Offset(0, 48),
          onSelected: (value) {
            switch (value) {
              case 'settings':
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
                break;
              case 'location':
                _showChangeLocationDialog();
                break;
              case 'help':
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                );
                break;
              case 'cards':
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyCardsScreen()),
                );
                break;
              case 'request':
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RequestStoreScreen()),
                );
                break;
            }
          },
          itemBuilder: (context) => [
            _popupItem('settings', 'Settings'),
            _popupItem('location', 'Change Location'),
            _popupItem('help', 'Help & Support'),
            _popupItem('cards', 'My Cards'),
            _popupItem('request', 'Request a Store'),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  PopupMenuItem<String> _popupItem(String value, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w400,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final appTheme = context.appTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _activateSearch,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: appTheme.searchFill,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: appTheme.subtitle, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _searchController.text.isEmpty
                        ? 'Search deals and stores'
                        : _searchController.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _searchController.text.isEmpty
                          ? appTheme.subtitle
                          : appTheme.navyText,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final appTheme = context.appTheme;

    return Container(
      height: 44,
      color: appTheme.headerSurface,
      child: Row(
        children: [
          // 1. Pinned Favorites Tab
          InkWell(
            onTap: () => _selectCategory(0),
            child: Container(
              width: 56,
              height: double.infinity,
              alignment: Alignment.center,
              child: ValueListenableBuilder<int>(
                valueListenable: _selectedCategory,
                builder: (context, activeIndex, _) {
                  final bool isFavoriteActive = activeIndex == 0;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Center(
                          child: Icon(
                            Icons.favorite,
                            color: isFavoriteActive
                                ? Colors.red
                                : appTheme.chipInactive,
                            size: 22,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        height: 3,
                        width: isFavoriteActive ? 24.0 : 0.0,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // 2. Vertical Divider
          Container(
            width: 1,
            height: 20,
            color: appTheme.border,
          ),

          // 3. Scrollable List of Categories (with horizontal expandable lines)
          Expanded(
            child: ListView.builder(
              controller: _tabsScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: _categories.length - 1,
              itemBuilder: (context, index) {
                final int categoryIndex = index + 1;
                return InkWell(
                  onTap: () => _selectCategory(categoryIndex),
                  child: ValueListenableBuilder<int>(
                    valueListenable: _selectedCategory,
                    builder: (context, activeIndex, _) {
                      final bool active = activeIndex == categoryIndex;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Center(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 250),
                                  style: TextStyle(
                                    color: active
                                        ? context.brandBlue
                                        : appTheme.chipInactive,
                                    fontWeight: active
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  child: Text(_categories[categoryIndex]),
                                ),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              height: 3,
                              width: active ? 28.0 : 0.0,
                              decoration: BoxDecoration(
                                color: context.brandBlue,
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFavorites() {
    return Padding(
      padding: const EdgeInsets.only(top: 103.0),
      child: EmptyStateView(
        icon: Icons.favorite_border,
        title: 'No Favorites Yet',
        message:
            'Tap the heart icon on any flyer to save it to your favorites list.',
        actionLabel: 'Browse stores',
        onAction: () {
          _selectCategory(1);
          _pageController.jumpToPage(1);
        },
      ),
    );
  }

  Widget _buildLatest(List<Store> stores) {
    // In "Latest" tab: we separate by "Upcoming" and "New This Week"
    // Let's filter Shoppers (which is Upcoming/Preview) and others
    final upcoming = stores
        .where((s) => s.name.toLowerCase().contains('shopper'))
        .toList();
    final newThisWeek = stores
        .where((s) => !s.name.toLowerCase().contains('shopper'))
        .toList();

    return ValueListenableBuilder<int>(
      valueListenable: _selectedCategory,
      builder: (context, activeCategory, _) {
        final bool isPageActive = 2 == activeCategory;
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 103.0)),
            SliverToBoxAdapter(child: _sectionHeader('Upcoming')),
            if (upcoming.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: _inlineEmpty('No upcoming flyers')),
              )
            else
              ..._mixedStoreSlivers(
                stores: upcoming,
                isPageActive: isPageActive,
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(child: _sectionHeader('New This Week')),
            if (newThisWeek.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: _inlineEmpty('Nothing new this week')),
              )
            else
              ..._mixedStoreSlivers(
                stores: newThisWeek,
                isPageActive: isPageActive,
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }

  Widget _buildStoreGrid(List<Store> stores, String headerLabel, int pageIndex) {
    return ValueListenableBuilder<int>(
      valueListenable: _selectedCategory,
      builder: (context, activeCategory, _) {
        final bool isPageActive = pageIndex == activeCategory;
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 103.0)),
            SliverToBoxAdapter(child: _sectionHeader(headerLabel)),
            const SliverToBoxAdapter(child: SizedBox(height: 4)),
            ..._mixedStoreSlivers(stores: stores, isPageActive: isPageActive),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: context.appTheme.navyText,
            ),
          ),
          if (label == 'Your Favorites')
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EditFavoritesScreen(),
                  ),
                );
              },
              child: Text(
                'EDIT',
                style: TextStyle(
                  color: context.brandBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _inlineEmpty(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.appTheme.sectionBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(color: context.appTheme.subtitle, fontSize: 13),
      ),
    );
  }

  Widget _buildEmptyCategory(String categoryName) {
    return Padding(
      padding: const EdgeInsets.only(top: 103.0),
      child: EmptyStateView(
        icon: Icons.storefront_outlined,
        title: 'No $categoryName flyers found',
        message:
            'We update our flyers daily. Please check back later or try another category.',
      ),
    );
  }

  Widget _buildBottomNav() {
    final navTheme = Theme.of(context).bottomNavigationBarTheme;

    return Container(
      decoration: BoxDecoration(
        color: navTheme.backgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: (i) {
          if (i == 2) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ListsScreen()));
          } else {
            setState(() => _bottomNavIndex = i);
            if (i == 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _syncPageControllerToCategory();
              });
            } else if (i == 1) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _searchFocusNode.requestFocus();
              });
            } else {
              _searchFocusNode.unfocus();
            }
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: navTheme.backgroundColor,
        selectedItemColor: navTheme.selectedItemColor,
        unselectedItemColor: navTheme.unselectedItemColor,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        elevation: 0,
        items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.local_offer_outlined),
          activeIcon: Icon(Icons.local_offer),
          label: 'Browse',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt_outlined),
          activeIcon: Icon(Icons.list_alt),
          label: 'Lists',
        ),
      ],
      ),
    );
  }
}

class StaggeredGridEntry extends StatelessWidget {
  final int index;
  final Widget child;

  const StaggeredGridEntry({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final int delayMs = (index % 6) * 50;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + delayMs),
      curve: Curves.easeOutQuad,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0.0, (1.0 - value) * 16.0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
