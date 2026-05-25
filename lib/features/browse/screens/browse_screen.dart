import 'package:flutter/material.dart';
import '../../flyer/data/flyer_repository.dart';
import '../../flyer/models/store.dart';
import '../../flyer/screens/flyer_viewer_screen.dart';
import '../../lists/screens/lists_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../settings/screens/help_support_screen.dart';
import '../../settings/screens/my_cards_screen.dart';
import '../../settings/screens/request_store_screen.dart';
import '../widgets/store_card.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  static const Color _brandBlue = Color(0xFF0071CE);

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

  int _selectedCategory = 1; // Default: Explore
  int _bottomNavIndex = 0;
  String _currentLocation = 'A1A 1A1';
  final Set<String> _favoritedStoreIds = {};

  late PageController _pageController;
  final ScrollController _tabsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedCategory);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabsScrollController.dispose();
    super.dispose();
  }

  double _getTabWidth(int categoryIndex) {
    if (categoryIndex == 0) return 56.0;
    final name = _categories[categoryIndex];
    // Approximate character width in pixels + horizontal padding of 24
    return name.length * 8.5 + 24.0;
  }

  void _scrollToCategoryTab(int index) {
    if (!_tabsScrollController.hasClients) return;

    double targetOffset = 0.0;
    if (index > 0) {
      final double screenWidth = MediaQuery.of(context).size.width;
      // Viewport width is screen width minus the pinned heart tab (56) and vertical divider (1)
      final double viewportWidth = screenWidth - 57.0;

      double tabStartOffset = 0.0;
      for (int i = 1; i < index; i++) {
        tabStartOffset += _getTabWidth(i);
      }
      final double targetTabWidth = _getTabWidth(index);
      final double tabCenter = tabStartOffset + (targetTabWidth / 2.0);

      // Center the tab inside the scrollable viewport
      targetOffset = tabCenter - (viewportWidth / 2.0);
    }

    _tabsScrollController.animateTo(
      targetOffset.clamp(0.0, _tabsScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  List<Store> _filterStoresByCategory(List<Store> stores, int index) {
    if (index == 0) {
      return stores.where((s) => _favoritedStoreIds.contains(s.id)).toList();
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

  void _showChangeLocationDialog() {
    final controller = TextEditingController(text: _currentLocation);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
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
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Change Location',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter a postal code to see flyers and deals in that area.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'e.g. M5V 2H1 or K1A 0B1',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
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
                  onPressed: () {
                    final newLoc = controller.text.trim();
                    if (newLoc.isNotEmpty) {
                      setState(() {
                        _currentLocation = newLoc.toUpperCase();
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Location updated to $_currentLocation!',
                          ),
                          backgroundColor: _brandBlue,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandBlue,
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
    return Scaffold(
      backgroundColor: const Color(
        0xFFF4F5F7,
      ), // Match the subtle background in screenshot
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<Store>>(
          stream: FlyerRepository.instance.watchStores(),
          builder: (context, snap) {
            if (snap.hasError) {
              return _buildErrorState('Could not load flyers: ${snap.error}');
            }
            if (!snap.hasData) {
              return Column(
                children: [
                  Container(
                    color: Colors.white,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSearchBar(),
                        _buildCategoryTabs(),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      ],
                    ),
                  ),
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            }
            final stores = snap.data!;
            return Column(
              children: [
                Container(
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSearchBar(),
                      _buildCategoryTabs(),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _categories.length,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedCategory = index;
                      });
                      _scrollToCategoryTab(index);
                    },
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Favorites heart tab
                        final favStores = _filterStoresByCategory(stores, 0);
                        if (favStores.isEmpty) {
                          return _buildEmptyFavorites();
                        }
                        return _buildStoreGrid(favStores, 'Your Favorites');
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
                        return _buildStoreGrid(filtered, title);
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
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
              CircleAvatar(
                radius: 16,
                backgroundColor: _brandBlue.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.local_offer_outlined,
                  size: 18,
                  color: _brandBlue,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Savings from:',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  Text(
                    _currentLocation,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _brandBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black54, size: 26),
          onPressed: () {
            setState(() {
              _bottomNavIndex = 1;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Search tab activated!')),
            );
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.settings_outlined,
            color: Colors.black54,
            size: 26,
          ),
          color: Colors.white,
          surfaceTintColor: Colors.white,
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
            const PopupMenuItem<String>(
              value: 'settings',
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'location',
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Text(
                  'Change Location',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'help',
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Text(
                  'Help & Support',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'cards',
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Text(
                  'My Cards',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'request',
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Text(
                  'Request a Store',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F3F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey[700], size: 22),
            const SizedBox(width: 8),
            Text(
              'Search deals and stores',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final bool isFavoriteActive = _selectedCategory == 0;

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          // 1. Pinned Favorites Heart Tab (Fixed on the far left)
          InkWell(
            onTap: () {
              _pageController.animateToPage(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              width: 56,
              height: double.infinity,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: Icon(
                        isFavoriteActive ? Icons.favorite : Icons.favorite,
                        color: isFavoriteActive
                            ? Colors.red
                            : const Color(0xFF5F6368),
                        size: 22,
                      ),
                    ),
                  ),
                  Container(
                    height: 3,
                    width: 24,
                    color: isFavoriteActive ? Colors.red : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),

          // 2. Vertical Divider
          Container(width: 1, height: 20, color: const Color(0xFFDDDDDD)),

          // 3. Scrollable List of Categories (Explore, Latest, etc.)
          Expanded(
            child: ListView.builder(
              controller: _tabsScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount:
                  _categories.length - 1, // Exclude Favorites from scroll list
              itemBuilder: (context, index) {
                final int categoryIndex =
                    index + 1; // Map to Explore (1), Latest (2), etc.
                final bool active = _selectedCategory == categoryIndex;

                return InkWell(
                  onTap: () {
                    _pageController.animateToPage(
                      categoryIndex,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              _categories[categoryIndex],
                              style: TextStyle(
                                color: active
                                    ? _brandBlue
                                    : const Color(0xFF5F6368),
                                fontWeight: active
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          height: 3,
                          width: 28,
                          color: active ? _brandBlue : Colors.transparent,
                        ),
                      ],
                    ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No Favorites Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the heart icon on any flyer to save it to your favorites list.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.35,
              ),
            ),
          ],
        ),
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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Upcoming'),
          if (upcoming.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _inlineEmpty('No upcoming flyers'),
            )
          else
            _storeGridView(upcoming),
          const SizedBox(height: 16),
          _sectionHeader('New This Week'),
          if (newThisWeek.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _inlineEmpty('Nothing new this week'),
            )
          else
            _storeGridView(newThisWeek),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStoreGrid(List<Store> stores, String headerLabel) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(headerLabel),
          const SizedBox(height: 4),
          _storeGridView(stores),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _storeGridView(List<Store> stores) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 0.74,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        for (int i = 0; i < stores.length; i++)
          StoreCard(
            store: stores[i],
            isFavorited: _favoritedStoreIds.contains(stores[i].id),
            onFavoriteToggle: () {
              setState(() {
                if (_favoritedStoreIds.contains(stores[i].id)) {
                  _favoritedStoreIds.remove(stores[i].id);
                } else {
                  _favoritedStoreIds.add(stores[i].id);
                }
              });
            },
            onTap: () => _openStore(stores, i),
          ),
      ],
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF1E293B),
            ),
          ),
          if (label == 'Your Favorites')
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit Favorites tapped!')),
                );
              },
              child: const Text(
                'EDIT',
                style: TextStyle(
                  color: _brandBlue,
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
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
    );
  }

  Widget _buildEmptyCategory(String categoryName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No $categoryName flyers found',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We update our flyers daily. Please check back later or try another category.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _bottomNavIndex,
      onTap: (i) {
        if (i == 2) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ListsScreen()));
        } else {
          setState(() => _bottomNavIndex = i);
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: _brandBlue,
      unselectedItemColor: Colors.grey[600],
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
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
    );
  }
}
