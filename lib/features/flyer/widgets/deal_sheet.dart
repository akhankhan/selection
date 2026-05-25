import 'dart:ui' as ui;
import 'package:flutter/material.dart';
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

  /// Open already expanded to the full detail view instead of the peek.
  final bool startExpanded;

  const DealSheet({
    super.key,
    required this.item,
    required this.flyerImage,
    this.startExpanded = false,
  });

  @override
  State<DealSheet> createState() => _DealSheetState();
}

class _DealSheetState extends State<DealSheet> {
  static const Color _ink = Color(0xFF1A1A1A);
  static const Color _brandBlue = Color(0xFF0071CE);
  static const Color _grey = Color(0xFF7A7A7A);
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(blurRadius: 24, color: Colors.black26)],
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
              _buildButtons(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 24,
        child: Center(
          child: AnimatedRotation(
            turns: _expanded ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: const Icon(
              Icons.keyboard_arrow_up,
              size: 24,
              color: Color(0xFF5F6368),
            ),
          ),
        ),
      ),
    );
  }

  /// Compact peek: photo on the left, name + price on the right.
  Widget _buildCompact() {
    final FlyerItem item = widget.item;
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _ink,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.price,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _ink,
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.price,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: _brandBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      'W',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(fontSize: 14, color: _ink),
                        children: [
                          TextSpan(text: 'Sold and fulfilled by '),
                          TextSpan(
                            text: 'Walmart',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Valid from May 21, 2026 to May 28, 2026',
                style: TextStyle(fontSize: 13, color: _grey),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        _sectionHeader('Description'),
        _bodyText('Pack. Product of USA or Mexico.\n#$productCode.'),
        const Divider(height: 1, color: Color(0xFFEEEEEE), thickness: 1),
        _bodyText('SKU: $sku'),
        const SizedBox(height: 10),
        _sectionHeader('Terms and conditions'),
        _linkRow('Shipping policy'),
        const Divider(height: 1, color: Color(0xFFEEEEEE), thickness: 1),
        _linkRow('Return policy'),
        const Divider(height: 1, color: Color(0xFFEEEEEE), thickness: 1),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Text(
            'In the event of a disagreement between the flyer and this popup, '
            'the flyers shall take precedence',
            style: TextStyle(fontSize: 12.5, color: _grey, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF2F3F5),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: _ink,
        ),
      ),
    );
  }

  Widget _bodyText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: _ink, height: 1.4),
      ),
    );
  }

  Widget _linkRow(String label) {
    return InkWell(
      onTap: () {},
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

  Widget _buildButtons(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
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
              onPressed: () {},
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
              onPressed: () {},
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
