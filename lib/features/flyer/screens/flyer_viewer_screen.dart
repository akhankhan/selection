import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../data/cloudinary_url.dart';
import '../models/flyer_item.dart';
import '../models/store.dart';
import '../widgets/hand_drawn_circle_painter.dart';
import '../widgets/deal_sheet.dart';
import '../../../core/storage/favorites_store.dart';
import '../../../core/theme/app_theme_extension.dart';
import '../../lists/screens/lists_screen.dart';
import '../../lists/models/shopping_list_manager.dart';
import '../../browse/widgets/store_logo_avatar.dart';

/// Render width (in CSS pixels) we ask Cloudinary to serve for a full-size
/// flyer page. Anything below this is upscaled at decode time by the GPU;
/// anything above wastes bandwidth and memory for a phone display.
const int _kFlyerPageWidth = 1100;

class FlyerViewerScreen extends StatefulWidget {
  final List<Store> stores;
  final int initialStoreIndex;
  final FlyerItem? initialFlyerItem;
  final int? initialFlyerPageIndex;

  const FlyerViewerScreen({
    super.key,
    required this.stores,
    this.initialStoreIndex = 0,
    this.initialFlyerItem,
    this.initialFlyerPageIndex,
  });

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

  /// Decoded flyer images keyed by the sized Cloudinary URL, used to crop
  /// real product photos for the deal sheet. Lives behind a ValueNotifier so
  /// only widgets that actually need pixel data (the deal sheet, list
  /// thumbnails) rebuild when a new image finishes decoding.
  final ValueNotifier<Map<String, ui.Image>> _flyerImages =
      ValueNotifier<Map<String, ui.Image>>({});

  /// Pending decodes so swiping back to a store doesn't re-trigger work.
  final Set<String> _pendingImageUrls = {};

  String _renderUrlForPage(FlyerPage page) =>
      CloudinaryUrl.sized(page.imageUrl, width: _kFlyerPageWidth);

  // Height of the in-scroll tab bar; used to offset page calculations.
  static const double _tabBarHeight = 48;
  static const double _tabBarBottomSpace = 12;

  List<Store> get _stores => widget.stores;
  Store get _activeStore => _stores[_currentStore];

  @override
  void initState() {
    super.initState();
    _currentStore = widget.initialStoreIndex
        .clamp(0, _stores.length - 1)
        .toInt();
    _storeController = PageController(initialPage: _currentStore);
    _scrollControllers = List.generate(
      _stores.length,
      (_) => ScrollController(),
    );
    _warmImagesAround(_currentStore);

    FavoritesStore.instance.addListener(_onFavoritesChanged);
    ShoppingListManager().addListener(_onShoppingListChanged);
    _syncHighlights();

    if (widget.initialFlyerItem != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openInitialDealTarget();
      });
    }
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
  }

  /// Decode flyer pages for the current store and its immediate neighbours,
  /// so swiping reveals them without a black frame, but distant stores never
  /// chew RAM unless visited.
  void _warmImagesAround(int storeIdx) {
    final List<int> targets = [
      storeIdx - 1,
      storeIdx,
      storeIdx + 1,
    ];
    for (final i in targets) {
      if (i < 0 || i >= _stores.length) continue;
      _loadStoreImages(_stores[i]);
    }
  }

  void _onShoppingListChanged() {
    if (mounted) {
      setState(() {
        _syncHighlights();
      });
    }
  }

  void _syncHighlights() {
    final store = _stores[_currentStore];
    final manager = ShoppingListManager();

    final Set<String> activeIds = {};
    for (final page in store.pages) {
      for (final item in page.items) {
        if (manager.hasFlyerItem(item.id, store.name)) {
          activeIds.add(item.id);
        }
      }
    }

    // Add missing highlights
    for (final page in store.pages) {
      for (final item in page.items) {
        if (activeIds.contains(item.id) &&
            !_highlights.any((h) => h.id == item.id)) {
          _highlights.add(item);
          final controller = AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 600),
          );
          controller.addStatusListener((status) {
            if (status == AnimationStatus.dismissed && mounted) {
              controller.dispose();
              _highlightControllers.remove(item.id);
              setState(() => _highlights.removeWhere((h) => h.id == item.id));
              manager.removeFlyerItem(item.id, store.name);
            }
          });
          _highlightControllers[item.id] = controller;
          controller.value = 1.0; // fully drawn circle
        }
      }
    }

    // Remove obsolete highlights
    final List<String> toRemove = [];
    for (final h in _highlights) {
      if (!activeIds.contains(h.id)) {
        toRemove.add(h.id);
      }
    }

    for (final id in toRemove) {
      final controller = _highlightControllers[id];
      if (controller != null) {
        controller.dispose();
        _highlightControllers.remove(id);
      }
      _highlights.removeWhere((h) => h.id == id);
    }
  }

  void _loadStoreImages(Store store) {
    for (final page in store.pages) {
      if (page.imageUrl.isEmpty) continue;
      final String url = _renderUrlForPage(page);
      if (_flyerImages.value.containsKey(url) ||
          _pendingImageUrls.contains(url)) {
        continue;
      }
      _pendingImageUrls.add(url);
      try {
        final imageProvider = CachedNetworkImageProvider(url);
        final stream = imageProvider.resolve(ImageConfiguration.empty);
        late final ImageStreamListener listener;
        listener = ImageStreamListener(
          (ImageInfo info, bool _) {
            if (!mounted) return;
            // Replace map identity so listeners notice the change.
            final next = Map<String, ui.Image>.from(_flyerImages.value);
            next[url] = info.image;
            _flyerImages.value = next;
            _pendingImageUrls.remove(url);
            stream.removeListener(listener);
          },
          onError: (exception, stackTrace) {
            _pendingImageUrls.remove(url);
            stream.removeListener(listener);
            debugPrint('Failed to cache flyer image: $exception');
          },
        );
        stream.addListener(listener);
      } catch (_) {
        _pendingImageUrls.remove(url);
        // Tap-handling and the deal sheet both tolerate a missing image.
      }
    }
  }

  @override
  void dispose() {
    FavoritesStore.instance.removeListener(_onFavoritesChanged);
    ShoppingListManager().removeListener(_onShoppingListChanged);
    _storeController.dispose();
    for (final c in _scrollControllers) {
      c.dispose();
    }
    for (final c in _highlightControllers.values) {
      c.dispose();
    }
    _flyerImages.dispose();
    super.dispose();
  }

  List<Store> _relatedStoresFor(int storeIdx) {
    return [
      for (int i = 0; i < _stores.length; i++)
        if (i != storeIdx) _stores[i],
    ];
  }

  Future<void> _openInitialDealTarget() async {
    final item = widget.initialFlyerItem;
    if (item == null || !mounted) return;
    final pageIdx = widget.initialFlyerPageIndex ?? item.pageIndex;
    await _scrollToPageAndShowDeal(item, pageIdx);
  }

  Future<void> _scrollToPageAndShowDeal(FlyerItem item, int pageIdx) async {
    final store = _activeStore;
    if (pageIdx < 0 || pageIdx >= store.pages.length) return;

    _setTab(_Tab.weeklyAd);

    final width = MediaQuery.of(context).size.width;
    final pageHeights =
        store.pages.map((p) => width / p.aspectRatio).toList();
    double offset = _tabBarHeight + _tabBarBottomSpace;
    for (int i = 0; i < pageIdx; i++) {
      offset += pageHeights[i];
    }

    final ctrl = _scrollControllers[_currentStore];
    for (int attempt = 0; attempt < 12; attempt++) {
      if (ctrl.hasClients) break;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    if (ctrl.hasClients) {
      await ctrl.animateTo(
        offset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }

    if (!mounted) return;
    setState(() => _currentPage = pageIdx);

    final page = store.pages[pageIdx];
    final renderUrl = _renderUrlForPage(page);
    await _ensureImageLoaded(renderUrl);

    if (mounted) {
      _showItemBottomSheet(item, renderUrl, store: store);
    }
  }

  Future<void> _ensureImageLoaded(String renderUrl) async {
    if (_flyerImages.value.containsKey(renderUrl)) return;
    _loadStoreImages(_activeStore);
    for (int attempt = 0; attempt < 30; attempt++) {
      if (_flyerImages.value.containsKey(renderUrl)) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _shareStore() async {
    final store = _activeStore;
    final trimmedDates = store.dateRange.trim();
    final buffer = StringBuffer()..write('${store.name} weekly ad');
    if (trimmedDates.isNotEmpty) {
      buffer.write(' ($trimmedDates)');
    }
    buffer.write('\nBrowse deals in MENU2GO.');
    await SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  void _toggleFavorite() {
    FavoritesStore.instance.toggle(_activeStore.id);
  }

  void _showStoreInfo() {
    final store = _activeStore;
    final appTheme = context.appTheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(store.name),
        content: Text(
          'Weekly ad valid ${store.dateRange}.\n\n'
          '${store.pages.length} page${store.pages.length == 1 ? '' : 's'} available.',
          style: TextStyle(color: appTheme.navyText, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openRelatedStore(int storeIdx) {
    if (storeIdx == _currentStore) {
      _setTab(_Tab.weeklyAd);
      return;
    }
    if (_storeController.hasClients) {
      _storeController.animateToPage(
        storeIdx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      setState(() => _currentStore = storeIdx);
    }
    _setTab(_Tab.weeklyAd);
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

    final FlyerPage page = _stores[storeIdx].pages[pageIdx];
    final FlyerItem? tapped = page.items.cast<FlyerItem?>().firstWhere(
      (item) => item!.boundingBox.contains(Offset(nx, ny)),
      orElse: () => null,
    );
    if (tapped == null) return;

    final store = _stores[storeIdx];
    final manager = ShoppingListManager();

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
          manager.removeFlyerItem(tapped.id, store.name);
        }
      });
      _highlightControllers[tapped.id] = controller;
      setState(() => _highlights.add(tapped));
      controller.forward();

      final String renderUrl = _renderUrlForPage(page);
      // Add to shopping list
      manager.addFlyerItem(
        tapped,
        store.name,
        _flyerImages.value[renderUrl],
        storeDateRange: store.dateRange,
        pageImageUrl: page.imageUrl,
      );

      _showItemBottomSheet(tapped, renderUrl);
    } else if (existing.status == AnimationStatus.reverse) {
      final String renderUrl = _renderUrlForPage(page);
      existing.forward();
      manager.addFlyerItem(
        tapped,
        store.name,
        _flyerImages.value[renderUrl],
        storeDateRange: store.dateRange,
        pageImageUrl: page.imageUrl,
      );
      _showItemBottomSheet(tapped, renderUrl);
    } else {
      existing.reverse();
    }
  }

  // Constants for the highlight RepaintBoundary sizing. We pad each side by
  // [_highlightPad] so the wobbly stroke can poke outside the bbox without
  // being clipped, and pass the painter a normalized rect that locates the
  // item back inside that padded canvas.
  static const double _highlightPad = 0.05;
  static final Rect _itemRectInPaddedCanvas = Rect.fromLTWH(
    _highlightPad / (1 + 2 * _highlightPad),
    _highlightPad / (1 + 2 * _highlightPad),
    1 / (1 + 2 * _highlightPad),
    1 / (1 + 2 * _highlightPad),
  );

  /// Builds the hand-drawn circle overlays for one page, each positioned
  /// over just the item's bounding box (plus a small pad so the wobbly
  /// stroke isn't clipped). This keeps each circle's RepaintBoundary
  /// region tiny — Flutter only repaints that rectangle on each animation
  /// frame, not the full flyer page.
  List<Widget> _buildHighlights(
    int storeIdx,
    int pageIdx,
    double pageWidth,
    double pageHeight,
  ) {
    final Set<FlyerItem> pageItems = _stores[storeIdx].pages[pageIdx].items
        .toSet();
    return _highlights.where(pageItems.contains).map((item) {
      final controller = _highlightControllers[item.id]!;
      final Rect bbox = item.boundingBox;
      final double padW = bbox.width * _highlightPad;
      final double padH = bbox.height * _highlightPad;
      return Positioned(
        left: (bbox.left * pageWidth) - padW * pageWidth,
        top: (bbox.top * pageHeight) - padH * pageHeight,
        width: bbox.width * pageWidth + 2 * padW * pageWidth,
        height: bbox.height * pageHeight + 2 * padH * pageHeight,
        child: IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: HandDrawnCirclePainter(
                normalizedRect: _itemRectInPaddedCanvas,
                animation: controller,
                seed: item.id.hashCode,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildStoreScroll(int storeIdx) {
    final Store store = _stores[storeIdx];
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double viewportHeight = constraints.maxHeight;
        final bool showWeekly = _activeTab == _Tab.weeklyAd;
        final List<double> pageHeights = showWeekly
            ? store.pages.map((p) => width / p.aspectRatio).toList()
            : const <double>[];
        final relatedStores = _relatedStoresFor(storeIdx);
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (showWeekly &&
                storeIdx == _currentStore &&
                notification is ScrollUpdateNotification) {
              _updateCurrentPage(notification.metrics.pixels, pageHeights);
            }
            return false;
          },
          child: ListView.builder(
            controller: _scrollControllers[storeIdx],
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            itemCount: showWeekly
                ? (store.pages.isEmpty ? 2 : store.pages.length + 1)
                : (relatedStores.isEmpty ? 2 : relatedStores.length + 1),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTabBar(store),
                    const SizedBox(height: _tabBarBottomSpace),
                  ],
                );
              }

              if (showWeekly) {
                if (store.pages.isEmpty) {
                  return _buildEmptyState(
                    viewportHeight - _tabBarHeight - _tabBarBottomSpace,
                    message: 'No pages yet for ${store.name}',
                  );
                }
                final pageIdx = index - 1;
                return _buildFlyerImage(storeIdx, pageIdx, width, pageHeights[pageIdx]);
              } else {
                if (relatedStores.isEmpty) {
                  return _buildEmptyState(
                    viewportHeight - _tabBarHeight - _tabBarBottomSpace,
                    message: 'No related ads from other stores',
                  );
                }
                final relatedStore = relatedStores[index - 1];
                final targetIdx =
                    _stores.indexWhere((s) => s.id == relatedStore.id);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _buildRelatedAdTile(relatedStore, targetIdx),
                );
              }
            },
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

  Widget _buildEmptyState(
    double height, {
    String message = 'No related ads yet',
  }) {
    final appTheme = context.appTheme;
    return SizedBox(
      height: height > 200 ? height : 320,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: appTheme.subtitle),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: appTheme.subtitle,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedAdTile(Store store, int storeIdx) {
    final appTheme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final thumbUrl = store.pages.isNotEmpty
        ? CloudinaryUrl.sized(store.pages.first.imageUrl, width: 400)
        : null;

    return Material(
      color: appTheme.cardSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _openRelatedStore(storeIdx),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              StoreLogoAvatar(store: store, radius: 22, fontSize: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: appTheme.navyText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      store.dateRange,
                      style: TextStyle(fontSize: 13, color: appTheme.subtitle),
                    ),
                    if (store.pages.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${store.pages.length} page${store.pages.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (thumbUrl != null && thumbUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    width: 52,
                    height: 68,
                    fit: BoxFit.cover,
                    imageUrl: thumbUrl,
                    placeholder: (_, _) => Container(
                      width: 52,
                      height: 68,
                      color: appTheme.sectionBg,
                    ),
                    errorWidget: (_, _, _) => Container(
                      width: 52,
                      height: 68,
                      color: appTheme.sectionBg,
                      child: Icon(Icons.image_outlined, color: appTheme.subtitle),
                    ),
                  ),
                ),
            ],
          ),
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
    final FlyerPage page = _stores[storeIdx].pages[pageIdx];
    final double dpr = MediaQuery.of(context).devicePixelRatio;
    final int targetW = (width * dpr).clamp(400, _kFlyerPageWidth).toInt();
    final String renderUrl = _renderUrlForPage(page);
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
              child: page.imageUrl.isEmpty
                  ? ColoredBox(color: context.appTheme.sectionBg)
                  : RepaintBoundary(
                      child: CachedNetworkImage(
                        imageUrl: renderUrl,
                        fit: BoxFit.fill,
                        memCacheWidth: targetW,
                        fadeInDuration: const Duration(milliseconds: 120),
                        placeholder: (_, _) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (_, _, _) => const Center(
                          child: Icon(Icons.broken_image_outlined, size: 48),
                        ),
                      ),
                    ),
            ),
            ..._buildHighlights(storeIdx, pageIdx, width, height),
          ],
        ),
      ),
    );
  }

  Widget _buildFlyerView() {
    return PageView.builder(
      controller: _storeController,
      itemCount: _stores.length,
      onPageChanged: (index) {
        setState(() {
          _currentStore = index;
          // Fresh store scroll always starts at the top, so reset the
          // page indicator. The scroll listener will update as the user
          // scrolls within the new store.
          _currentPage = 0;
          _syncHighlights();
        });
        _warmImagesAround(index);
      },
      itemBuilder: (context, storeIdx) => _buildStoreScroll(storeIdx),
    );
  }

  Widget _buildDotPill() {
    final int storeCount = _stores.length;
    if (storeCount <= 1) return const SizedBox.shrink();

    final appTheme = context.appTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: appTheme.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: context.isDarkMode
            ? Border.all(color: appTheme.border.withValues(alpha: 0.6))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkMode ? 0.45 : 0.12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(storeCount, (i) {
          final bool active = i == _currentStore;
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

  void _showItemBottomSheet(
    FlyerItem item,
    String renderUrl, {
    Store? store,
  }) {
    final activeStore = store ?? _activeStore;
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
      builder: (ctx) => ValueListenableBuilder<Map<String, ui.Image>>(
        valueListenable: _flyerImages,
        builder: (_, images, _) => DealSheet(
          item: item,
          flyerImage: images[renderUrl],
          storeName: activeStore.name,
          storeDateRange: activeStore.dateRange,
          storeLogoLetter: activeStore.logoLetter,
          storeBrandColor: activeStore.brandColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Store store = _activeStore;
    final int listCount = ShoppingListManager().totalItemCount;
    final appTheme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final appBarTheme = Theme.of(context).appBarTheme;
    final iconColor = appBarTheme.foregroundColor ?? colorScheme.onSurface;

    final bool isFavorite = FavoritesStore.instance.contains(store.id);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: appBarTheme.backgroundColor,
        foregroundColor: appBarTheme.foregroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 52,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: iconColor),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: iconColor.withValues(alpha: 0.7)),
            onPressed: _shareStore,
          ),
          if (listCount > 0)
            Badge(
              label: Text('$listCount'),
              backgroundColor: Colors.red,
              offset: const Offset(-4, 4),
              child: IconButton(
                icon: Icon(
                  Icons.calendar_today_outlined,
                  color: iconColor.withValues(alpha: 0.7),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ListsScreen()),
                  );
                },
              ),
            )
          else
            IconButton(
              icon: Icon(
                Icons.calendar_today_outlined,
                color: iconColor.withValues(alpha: 0.7),
              ),
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const ListsScreen()));
              },
            ),
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
            ),
            onPressed: _toggleFavorite,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: iconColor.withValues(alpha: 0.7)),
            onSelected: (value) {
              switch (value) {
                case 'share':
                  _shareStore();
                case 'favorite':
                  _toggleFavorite();
                case 'info':
                  _showStoreInfo();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Text('Share flyer'),
              ),
              PopupMenuItem(
                value: 'favorite',
                child: Text(isFavorite ? 'Remove favorite' : 'Add to favorites'),
              ),
              const PopupMenuItem(
                value: 'info',
                child: Text('Store info'),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                StoreLogoAvatar(store: store, radius: 20, fontSize: 18),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: appTheme.navyText,
                      ),
                    ),
                    Text(
                      store.dateRange,
                      style: TextStyle(fontSize: 13, color: appTheme.subtitle),
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
