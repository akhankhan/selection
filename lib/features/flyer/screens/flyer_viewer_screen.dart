import 'package:flutter/material.dart';
import '../models/flyer_item.dart';
import '../data/flyer_mock_data.dart';
import '../widgets/hand_drawn_circle_painter.dart';

class FlyerViewerScreen extends StatefulWidget {
  const FlyerViewerScreen({super.key});

  @override
  State<FlyerViewerScreen> createState() => _FlyerViewerScreenState();
}

class _FlyerViewerScreenState extends State<FlyerViewerScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final GlobalKey _imageKey = GlobalKey();
  int _currentPage = 0;

  /// Items that currently have a hand-drawn circle, in tap order.
  final List<FlyerItem> _highlights = [];

  /// One draw-on animation controller per highlighted item.
  final Map<String, AnimationController> _highlightControllers = {};

  final List<String> _flyerPages = [
    'assets/flyers/flyer_page1.png',
    'assets/flyers/flyer_page2.png',
  ];

  /// width / height of each flyer image, so the overlay can be sized to match
  /// the displayed artwork exactly (1024x1536 and 1033x1522).
  final List<double> _flyerAspects = [1024 / 1536, 1033 / 1522];

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _highlightControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _handleTap(Offset localPosition, int pageIndex) {
    final ctx = _imageKey.currentContext;
    if (ctx == null) return;
    final RenderBox box = ctx.findRenderObject() as RenderBox;
    final Size imageSize = box.size;
    if (imageSize.width == 0 || imageSize.height == 0) return;

    final double nx = localPosition.dx / imageSize.width;
    final double ny = localPosition.dy / imageSize.height;

    final FlyerItem? tapped = allFlyerItems.cast<FlyerItem?>().firstWhere(
          (item) =>
              item!.pageIndex == pageIndex &&
              item.boundingBox.contains(Offset(nx, ny)),
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
      _showItemBottomSheet(tapped);
    } else if (existing.status == AnimationStatus.reverse) {
      // Mid-removal: tapping again brings the circle back.
      existing.forward();
      _showItemBottomSheet(tapped);
    } else {
      // Already circled: tapping again removes the circle.
      existing.reverse();
    }
  }

  /// Builds the hand-drawn circle overlays for one page.
  List<Widget> _buildHighlights(int pageIndex) {
    return _highlights
        .where((item) => item.pageIndex == pageIndex)
        .map((item) {
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

  Widget _buildFlyerPageView() {
    return PageView.builder(
      controller: _pageController,
      itemCount: _flyerPages.length,
      onPageChanged: (index) => setState(() => _currentPage = index),
      itemBuilder: (context, pageIndex) {
        return InteractiveViewer(
          minScale: 0.8,
          maxScale: 5.0,
          child: Center(
            child: AspectRatio(
              aspectRatio: _flyerAspects[pageIndex],
              child: GestureDetector(
                onTapUp: (details) =>
                    _handleTap(details.localPosition, pageIndex),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        _flyerPages[pageIndex],
                        key: pageIndex == _currentPage ? _imageKey : null,
                        fit: BoxFit.fill,
                      ),
                    ),
                    ..._buildHighlights(pageIndex),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageDots() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _flyerPages.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentPage == index ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentPage == index
                  ? const Color(0xFF0071CE)
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  void _showItemBottomSheet(FlyerItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [BoxShadow(blurRadius: 20, color: Colors.black26)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.shopping_basket,
                      color: Color(0xFF0071CE),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (item.oldPrice != null)
                          Text(
                            'Was ${item.oldPrice}',
                            style: const TextStyle(
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                              fontSize: 13,
                            ),
                          ),
                        Text(
                          item.price,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: item.isRollback
                                ? Colors.red
                                : const Color(0xFF0071CE),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.isRollback)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC220),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            size: 12,
                            color: Color(0xFF0071CE),
                          ),
                          SizedBox(width: 2),
                          Text(
                            'Rollback',
                            style: TextStyle(
                              color: Color(0xFF0071CE),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: const Text('Buy Now'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0071CE),
                        side: const BorderSide(color: Color(0xFF0071CE)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.share, color: Colors.white),
                      label: const Text(
                        'Share deal',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0071CE),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFF0071CE),
              radius: 18,
              child: Text(
                'W',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Walmart',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'May 21 to May 27',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black54),
            onPressed: null,
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
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(40),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: null,
                  child: Text(
                    'Weekly Ad',
                    style: TextStyle(
                      color: Color(0xFF0071CE),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: null,
                  child: Text(
                    'Related Ads',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildFlyerPageView()),
          _buildPageDots(),
        ],
      ),
    );
  }
}
