import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme_extension.dart';
import '../models/flyer_item.dart';
import 'product_thumbnail.dart';

/// Expandable bottom sheet for a flyer deal.
///
/// Opens as a compact peek (photo + name + price) and can be dragged up — or
/// the chevron tapped — to reveal the full detail view: large photo, who it is
/// sold by, validity, description, SKU and terms. The action buttons stay
/// pinned at the bottom in both states.
class DealSheet extends StatefulWidget {
  final FlyerItem item;

  /// Decoded flyer page image the [item] lives on.
  final ui.Image? flyerImage;

  final String storeName;
  final String storeDateRange;
  final String storeLogoLetter;
  final Color storeBrandColor;

  /// Open already expanded to the full detail view instead of the peek.
  final bool startExpanded;

  const DealSheet({
    super.key,
    required this.item,
    required this.flyerImage,
    required this.storeName,
    required this.storeDateRange,
    required this.storeLogoLetter,
    required this.storeBrandColor,
    this.startExpanded = false,
  });

  @override
  State<DealSheet> createState() => _DealSheetState();
}

class _DealSheetState extends State<DealSheet> {
  static const Color _brandBlue = Color(0xFF0071CE);
  static const double _expandedSize = 0.82;

  double get _collapsedSize {
    if (!mounted) return 0.23;
    final double screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight <= 0) return 0.23;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    // Standard compact content heights: 24 (handle) + 72 (image) + 16 (padding) + 60 (buttons) = 172
    // If the product title is long and wraps to 2 lines, we add a 16dp buffer.
    final double titleBuffer = widget.item.name.length > 20 ? 16.0 : 0.0;
    final double targetHeight = 172.0 + titleBuffer + bottomPadding;

    return (targetHeight / screenHeight).clamp(0.15, 0.4);
  }

  final DraggableScrollableController _controller =
      DraggableScrollableController();
  bool _expanded = false;
  bool _showComingSoonMessage = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.startExpanded;
    _controller.addListener(_onDrag);
  }

  @override
  void dispose() {
    _controller.removeListener(_onDrag);
    _controller.dispose();
    super.dispose();
  }

  void _onDrag() {
    if (!_controller.isAttached) return;
    final bool expanded = _controller.size > 0.6;
    if (expanded != _expanded) setState(() => _expanded = expanded);
  }

  void _toggle() {
    if (!_controller.isAttached) return;
    _controller.animateTo(
      _expanded ? _collapsedSize : _expandedSize,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _buyNow() {
    setState(() => _showComingSoonMessage = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showComingSoonMessage = false);
    });
  }

  Future<void> _shareDeal() async {
    final trimmedDates = widget.storeDateRange.trim();
    final buffer = StringBuffer()
      ..write('${widget.item.name} — ${widget.item.price} at ${widget.storeName}');
    if (trimmedDates.isNotEmpty) {
      buffer.write('\nValid $trimmedDates');
    }
    buffer.write('\nBrowse deals in MENU2GO.');
    await SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  void _showPolicyDialog(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Normalised region of the flyer holding just this item's product photo.
  Rect get _photoCrop {
    final Rect b = widget.item.boundingBox;
    return Rect.fromLTRB(
      b.left + b.width * 0.03,
      b.top + b.height * 0.07,
      b.left + b.width * 0.52,
      b.bottom - b.height * 0.07,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;

    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: widget.startExpanded ? _expandedSize : _collapsedSize,
      minChildSize: _collapsedSize,
      maxChildSize: _expandedSize,
      snap: true,
      snapSizes: [_collapsedSize, _expandedSize],
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: appTheme.cardSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                blurRadius: 24,
                color: Colors.black.withValues(alpha: context.isDarkMode ? 0.55 : 0.15),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHandle(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 250),
                      sizeCurve: Curves.easeOut,
                      firstCurve: Curves.easeOut,
                      secondCurve: Curves.easeOut,
                      crossFadeState: _expanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: _buildCompact(),
                      secondChild: _buildExpanded(),
                    ),
                  ],
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: _showComingSoonMessage
                    ? _buildComingSoonBanner()
                    : const SizedBox.shrink(),
              ),
              _buildButtons(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    final subtitle = context.appTheme.subtitle;

    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 24,
        child: Center(
          child: AnimatedRotation(
            turns: _expanded ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: Icon(
              Icons.keyboard_arrow_up,
              size: 24,
              color: subtitle,
            ),
          ),
        ),
      ),
    );
  }

  /// Compact peek: photo on the left, name + price on the right.
  Widget _buildCompact() {
    final FlyerItem item = widget.item;
    final textColor = context.appTheme.navyText;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: ProductThumbnail(
              flyerImage: widget.flyerImage,
              cropRect: _photoCrop,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: textColor,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.price,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Full detail view shown when the sheet is expanded.
  Widget _buildExpanded() {
    final FlyerItem item = widget.item;
    final appTheme = context.appTheme;
    final textColor = appTheme.navyText;
    final subtitleColor = appTheme.subtitle;
    final dividerColor = Theme.of(context).dividerColor;
    // Demo detail content matching the screenshot structure:
    final String sku = item.id.hashCode
        .abs()
        .toString()
        .padRight(13, '0')
        .substring(0, 13);
    final String productCode = (item.id.hashCode.abs() % 9000000 + 1000000)
        .toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            height: 220,
            width: double.infinity,
            child: ProductThumbnail(
              flyerImage: widget.flyerImage,
              cropRect: _photoCrop,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.price,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.storeBrandColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      widget.storeLogoLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(fontSize: 14, color: textColor),
                        children: [
                          const TextSpan(text: 'Sold and fulfilled by '),
                          TextSpan(
                            text: widget.storeName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (widget.storeDateRange.trim().isNotEmpty) ...[
                Text(
                  'Valid ${widget.storeDateRange.trim()}',
                  style: TextStyle(fontSize: 13, color: subtitleColor),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        _sectionHeader('Description'),
        _bodyText('Pack. Product of USA or Mexico.\n#$productCode.'),
        Divider(height: 1, color: dividerColor, thickness: 1),
        _bodyText('SKU: $sku'),
        const SizedBox(height: 10),
        _sectionHeader('Terms and conditions'),
        _linkRow(
          'Shipping policy',
          onTap: () => _showPolicyDialog(
            'Shipping policy',
            'Standard shipping rates apply for online orders from '
            '${widget.storeName}. Delivery times vary by location.',
          ),
        ),
        Divider(height: 1, color: dividerColor, thickness: 1),
        _linkRow(
          'Return policy',
          onTap: () => _showPolicyDialog(
            'Return policy',
            'Returns must be made within the store return window. '
            'Keep your receipt and follow ${widget.storeName} return guidelines.',
          ),
        ),
        Divider(height: 1, color: dividerColor, thickness: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Text(
            'In the event of a disagreement between the flyer and this popup, '
            'the flyers shall take precedence',
            style: TextStyle(fontSize: 12.5, color: subtitleColor, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    final appTheme = context.appTheme;

    return Container(
      width: double.infinity,
      color: appTheme.sectionBg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: appTheme.navyText,
        ),
      ),
    );
  }

  Widget _bodyText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: context.appTheme.navyText,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _linkRow(String label, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        child: Text(
          label,
          style: const TextStyle(
            color: _brandBlue,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _brandBlue.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _brandBlue.withValues(alpha: 0.35)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: _brandBlue, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'This feature is coming soon.',
                style: TextStyle(
                  color: _brandBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    final appTheme = context.appTheme;

    return Container(
      decoration: BoxDecoration(
        color: appTheme.cardSurface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        6,
        16,
        6 +
            (MediaQuery.of(context).padding.bottom > 0
                ? MediaQuery.of(context).padding.bottom
                : 0),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _buyNow,
              icon: const Icon(Icons.storefront_outlined, size: 20),
              label: const Text(
                'Buy Now',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _brandBlue,
                side: const BorderSide(color: _brandBlue, width: 1.8),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _shareDeal,
              icon: const Icon(Icons.share, color: Colors.white, size: 20),
              label: const Text(
                'Share deal',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandBlue,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
