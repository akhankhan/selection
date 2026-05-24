import 'package:flutter/material.dart';
import '../../flyer/data/flyer_mock_data.dart';
import '../../flyer/screens/flyer_viewer_screen.dart';
import '../../lists/screens/lists_screen.dart';
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

  void _openStore(int storeIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FlyerViewerScreen(initialStoreIndex: storeIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildSearchBar(),
            _buildCategoryTabs(),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Expanded(child: _buildBody()),
          ],
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
      title: Row(
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
              const Text(
                'A1A 1A1',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: _brandBlue,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: const [
        IconButton(
          icon: Icon(Icons.settings_outlined, color: Colors.black54),
          onPressed: null,
        ),
        SizedBox(width: 4),
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
            onTap: () => setState(() => _selectedCategory = 0),
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
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount:
                  _categories.length - 1, // Exclude Favorites from scroll list
              itemBuilder: (context, index) {
                final int categoryIndex =
                    index + 1; // Map to Explore (1), Latest (2), etc.
                final bool active = _selectedCategory == categoryIndex;

                return InkWell(
                  onTap: () =>
                      setState(() => _selectedCategory = categoryIndex),
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
                                    ? FontWeight.bold
                                    : FontWeight.normal,
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

  Widget _buildBody() {
    switch (_selectedCategory) {
      case 2: // Latest
        return _buildLatest();
      case 1: // Explore
      case 3: // A-Z
        return _buildStoreGrid('New This Week');
      default:
        return _buildEmpty('Nothing here yet');
    }
  }

  Widget _buildLatest() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Upcoming'),
          _inlineEmpty('No upcoming flyers'),
          const SizedBox(height: 16),
          _sectionHeader('New Today'),
          _inlineEmpty('Nothing new today'),
          const SizedBox(height: 16),
          _sectionHeader('New This Week'),
          const SizedBox(height: 4),
          _storeGridView(),
        ],
      ),
    );
  }

  Widget _buildStoreGrid(String headerLabel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(headerLabel),
          const SizedBox(height: 4),
          Expanded(child: _storeGridView()),
        ],
      ),
    );
  }

  Widget _storeGridView() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 0.78,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        for (int i = 0; i < stores.length; i++)
          StoreCard(
            store: stores[i],
            statusLabel: _statusLabelFor(stores[i].id),
            statusType: _statusTypeFor(stores[i].id),
            onTap: () => _openStore(i),
          ),
      ],
    );
  }

  String _statusLabelFor(String storeId) {
    // Today is May 24; both stores end May 27 (Wednesday).
    if (storeId == 'walmart') return 'Until Wednesday';
    return 'New';
  }

  CardStatus _statusTypeFor(String storeId) {
    if (storeId == 'walmart') return CardStatus.untilText;
    return CardStatus.newBadge;
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Color(0xFF1A1A1A),
        ),
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

  Widget _buildEmpty(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _bottomNavIndex,
      onTap: (i) {
        if (i == 2) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ListsScreen()),
          );
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
