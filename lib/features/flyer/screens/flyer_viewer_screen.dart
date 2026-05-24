import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/flyer_item.dart';
import '../models/store.dart';
import '../data/flyer_mock_data.dart';
import '../widgets/hand_drawn_circle_painter.dart';
import '../widgets/deal_sheet.dart';

class FlyerViewerScreen extends StatefulWidget {
  const FlyerViewerScreen({super.key});

  @override
  State<FlyerViewerScreen> createState() => _FlyerViewerScreenState();
}

enum _Tab { weeklyAd, relatedAds }

class _FlyerViewerScreenState extends State<FlyerViewerScreen>
    with TickerProviderStateMixin {
  late final PageController _storeController;
  late final List<ScrollController> _scrollControllers;
  int _currentStore = 0;
  int _currentPage = 0;
  _Tab _activeTab = _Tab.weeklyAd;

  /// Items that currently have a hand-drawn circle, in tap order.
  final List<FlyerItem> _highlights = [];

  /// One draw-on animation controller per highlighted item.
  final Map<String, AnimationController> _highlightControllers = {};

  /// Decoded flyer images keyed by asset path, used to crop real product
  /// photos for the deal sheet.
  final Map<String, ui.Image> _flyerImages = {};

  // Height of the in-scroll tab bar; used to offset page calculations.
  static const double _tabBarHeight = 48;
  static const double _tabBarBottomSpace = 12;

  Store get _activeStore => stores[_currentStore];

  @override
  void initState() {
    super.initState();
    _storeController = PageController();
    _scrollControllers =
        List.generate(stores.length, (_) => ScrollController());
    _loadFlyerImages();
  }

  Future<void> _loadFlyerImages() async {
    for (final store in stores) {
      for (final page in store.pages) {
        final data = await rootBundle.load(page.imagePath);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        if (!mounted) return;
        setState(() => _flyerImages[page.imagePath] = frame.image);
      }
    }
  }

  @override
  void dispose() {
    _storeController.dispose();
    for (final c in _scrollControllers) {
      c.dispose();
    }
    for (final c in _highlightControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _handleTap(
    Offset localPosition,
    int storeIdx,
    int pageIdx,
    Size imageSize,
  ) {
    if (imageSize.width == 0 || imageSize.height == 0) return;
    final double nx = localPosition.dx / imageSize.width;
    final double ny = localPosition.dy / imageSize.height;

    final FlyerPage page = stores[storeIdx].pages[pageIdx];
    final FlyerItem? tapped = page.items.cast<FlyerItem?>().firstWhere(
      (item) => item!.boundingBox.contains(Offset(nx, ny)),
      orElse: () => null,
    );
    if (tapped == null) return;

    final AnimationController? existing = _highlightControllers[tapped.id];
    if (existing == null) {
      // Not circled yet: draw the circle and open the deal sheet.
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      controller.addStatusListener((status) {
        // Once the circle has fully un-drawn, drop it entirely.
        if (status == AnimationStatus.dismissed && mounted) {
          controller.dispose();
          _highlightControllers.remove(tapped.id);
          setState(() => _highlights.removeWhere((h) => h.id == tapped.id));
        }
      });
      _highlightControllers[tapped.id] = controller;
      setState(() => _highlights.add(tapped));
      controller.forward();
      _showItemBottomSheet(tapped, page.imagePath);
    } else if (existing.status == AnimationStatus.reverse) {
      existing.forward();
      _showItemBottomSheet(tapped, page.imagePath);
    } else {
      existing.reverse();
    }
  }

  /// Builds the hand-drawn circle overlays for one page.
  List<Widget> _buildHighlights(int storeIdx, int pageIdx) {
    final Set<FlyerItem> pageItems =
        stores[storeIdx].pages[pageIdx].items.toSet();
    return _highlights.where(pageItems.contains).map((item) {
      final controller = _highlightControllers[item.id]!;
      return Positioned.fill(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: controller,
            builder: (_, _) => CustomPaint(
              painter: HandDrawnCirclePainter(
                normalizedRect: item.boundingBox,
                progress: Curves.easeOutCubic.transform(controller.value),
                seed: item.id.hashCode,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildStoreScroll(int storeIdx) {
    final Store store = stores[storeIdx];
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double viewportHeight = constraints.maxHeight;
        final bool showWeekly = _activeTab == _Tab.weeklyAd;
        final List<double> pageHeights = showWeekly
            ? store.pages.map((p) => width / p.aspectRatio).toList()
            : const <double>[];
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (showWeekly &&
                storeIdx == _currentStore &&
                notification is ScrollUpdateNotification) {
              _updateCurrentPage(notification.metrics.pixels, pageHeights);
            }
            return false;
          },
          child: SingleChildScrollView(
            controller: _scrollControllers[storeIdx],
            child: Column(
              children: [
                _buildTabBar(store),
                const SizedBox(height: _tabBarBottomSpace),
                if (showWeekly)
                  for (int i = 0; i < store.pages.length; i++)
                    _buildFlyerImage(storeIdx, i, width, pageHeights[i])
                else
                  _buildEmptyState(
                    viewportHeight - _tabBarHeight - _tabBarBottomSpace,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateCurrentPage(double pixels, List<double> pageHeights) {
    double cumulative = _tabBarHeight + _tabBarBottomSpace;
    int newPage = 0;
    for (int i = 0; i < pageHeights.length; i++) {
      // A page is "current" once it crosses the mid-point of the viewport.
      if (pixels < cumulative + pageHeights[i] / 2) {
        newPage = i;
        break;
      }
      cumulative += pageHeights[i];
      newPage = i;
    }
    if (newPage != _currentPage) {
      setState(() => _currentPage = newPage);
    }
  }

  void _setTab(_Tab tab) {
    if (_activeTab == tab) return;
    setState(() {
      _activeTab = tab;
      _currentPage = 0;
    });
    final ctrl = _scrollControllers[_currentStore];
    if (ctrl.hasClients) {
      ctrl.jumpTo(0);
    }
  }

  Widget _buildEmptyState(double height) {
    return SizedBox(
      height: height > 200 ? height : 320,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No related ads yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(Store store) {
    return SizedBox(
      height: _tabBarHeight,
      child: Row(
        children: [
          Expanded(child: _buildTab('Weekly Ad', _Tab.weeklyAd, store)),
          Expanded(child: _buildTab('Related Ads', _Tab.relatedAds, store)),
        ],
      ),
    );
  }

  Widget _buildTab(String label, _Tab tab, Store store) {
    final bool active = _activeTab == tab;
    return InkWell(
      onTap: () => _setTab(tab),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: active ? store.brandColor : Colors.grey,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          Container(
            height: 3,
            color: active ? store.brandColor : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildFlyerImage(
    int storeIdx,
    int pageIdx,
    double width,
    double height,
  ) {
    final FlyerPage page = stores[storeIdx].pages[pageIdx];
    return SizedBox(
      width: width,
      height: height,
      child: GestureDetector(
        onTapUp: (details) => _handleTap(
          details.localPosition,
          storeIdx,
          pageIdx,
          Size(width, height),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(page.imagePath, fit: BoxFit.fill),
            ),
            ..._buildHighlights(storeIdx, pageIdx),
          ],
        ),
      ),
    );
  }

  Widget _buildFlyerView() {
    return PageView.builder(
      controller: _storeController,
      itemCount: stores.length,
      onPageChanged: (index) {
        setState(() {
          _currentStore = index;
          // Fresh store scroll always starts at the top, so reset the
          // page indicator. The scroll listener will update as the user
          // scrolls within the new store.
          _currentPage = 0;
        });
      },
      itemBuilder: (context, storeIdx) => _buildStoreScroll(storeIdx),
    );
  }

  Widget _buildDotPill() {
    if (_activeTab != _Tab.weeklyAd) return const SizedBox.shrink();
    final int pageCount = _activeStore.pages.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(pageCount, (i) {
          final bool active = i == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? _activeStore.brandColor : const Color(0xFFD0D5DC),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }

  void _showItemBottomSheet(FlyerItem item, String imagePath) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // The sheet drags itself (DraggableScrollableSheet), so the modal must
      // not also handle drags.
      enableDrag: false,
      backgroundColor: Colors.transparent,
      // Transparent barrier: the flyer (and the yellow circle) stay in full
      // colour behind the sheet instead of being greyed out.
      barrierColor: Colors.transparent,
      builder: (ctx) =>
          DealSheet(item: item, flyerImage: _flyerImages[imagePath]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Store store = _activeStore;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 52,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black54),
            onPressed: null,
          ),
          Badge(
            label: const Text('3'),
            backgroundColor: Colors.red,
            offset: const Offset(-4, 4),
            child: IconButton(
              icon: const Icon(
                Icons.calendar_today_outlined,
                color: Colors.black54,
              ),
              onPressed: null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.red),
            onPressed: null,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            onPressed: null,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: store.brandColor,
                  radius: 20,
                  child: Text(
                    store.logoLetter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      store.dateRange,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildFlyerView(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Center(child: _buildDotPill()),
          ),
        ],
      ),
    );
  }
}
