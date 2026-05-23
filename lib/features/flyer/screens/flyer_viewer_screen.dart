import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/flyer_item.dart';
import '../data/flyer_mock_data.dart';
import '../widgets/hand_drawn_circle_painter.dart';
import '../widgets/deal_sheet.dart';

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

  /// Decoded flyer images, used to crop real product photos for the deal sheet.
  final List<ui.Image?> _flyerImages = [null, null];

  @override
  void initState() {
    super.initState();
    _loadFlyerImages();
  }

  Future<void> _loadFlyerImages() async {
    for (int i = 0; i < _flyerPages.length; i++) {
      final data = await rootBundle.load(_flyerPages[i]);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (!mounted) return;
      setState(() => _flyerImages[i] = frame.image);
    }
  }

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
    return _highlights.where((item) => item.pageIndex == pageIndex).map((item) {
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
      isScrollControlled: true,
      // The sheet drags itself (DraggableScrollableSheet), so the modal must
      // not also handle drags.
      enableDrag: false,

      backgroundColor: Colors.transparent,
      // Transparent barrier: the flyer (and the yellow circle) stay in full
      // colour behind the sheet instead of being greyed out.
      barrierColor: Colors.transparent,
      builder: (ctx) =>
          DealSheet(item: item, flyerImage: _flyerImages[item.pageIndex]),
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
