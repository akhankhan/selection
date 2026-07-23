import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme_extension.dart';
import '../../../core/utils/phone_launcher.dart';
import '../models/flyer_item.dart';
import 'product_thumbnail.dart';

/// Expandable bottom sheet for a flyer deal.
///
/// Opens as a compact peek (photo + name + price) and can be dragged up — or
/// the chevron tapped — to reveal pickup details. Action buttons stay pinned:
/// call the restaurant for pickup, or share the item.
class DealSheet extends StatefulWidget {
  final FlyerItem item;

  /// Decoded flyer page image the [item] lives on.
  final ui.Image? flyerImage;

  final String storeName;
  final String storeDateRange;
  final String storeLogoLetter;
  final Color storeBrandColor;
  final String? storePhone;

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
    this.storePhone,
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

  Future<void> _callForPickup() {
    return PhoneLauncher.callForPickup(
      context,
      phone: widget.storePhone,
      restaurantName: widget.storeName,
    );
  }

  Future<void> _shareDeal() async {
    final trimmedDates = widget.storeDateRange.trim();
    final buffer = StringBuffer()
      ..write('${widget.item.name} — ${widget.item.price} at ${widget.storeName}');
    if (trimmedDates.isNotEmpty) {
      buffer.write('\nValid $trimmedDates');
    }
    buffer.write('\nCall to place a pickup order in MENU2GO.');
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
                color: Colors.black.withValues(
                  alpha: context.isDarkMode ? 0.55 : 0.15,
                ),
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

  Widget _buildExpanded() {
    final FlyerItem item = widget.item;
    final appTheme = context.appTheme;
    final textColor = appTheme.navyText;
    final subtitleColor = appTheme.subtitle;
    final dividerColor = Theme.of(context).dividerColor;

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
                          const TextSpan(text: 'Pickup at '),
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
        _sectionHeader('How to order'),
        _bodyText(
          'No delivery or checkout in the app. Circle items into your list, '
          'then call ${widget.storeName} to place a pickup order.',
        ),
        Divider(height: 1, color: dividerColor, thickness: 1),
        _sectionHeader('Restaurant policies'),
        _linkRow(
          'Pickup info',
          onTap: () => _showPolicyDialog(
            'Pickup info',
            'Orders are placed by phone and picked up at ${widget.storeName}. '
            'Confirm item availability, pricing, and pickup time when you call.',
          ),
        ),
        Divider(height: 1, color: dividerColor, thickness: 1),
        _linkRow(
          'Return policy',
          onTap: () => _showPolicyDialog(
            'Return policy',
            'Returns follow ${widget.storeName} guidelines. '
            'Ask when you call or pick up.',
          ),
        ),
        Divider(height: 1, color: dividerColor, thickness: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Text(
            'Menu prices may change. Confirm with the restaurant when you call.',
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
          fontSize: 13,
          color: appTheme.navyText,
          letterSpacing: 0.2,
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
            child: ElevatedButton.icon(
              onPressed: _callForPickup,
              icon: const Icon(Icons.phone, color: Colors.white, size: 20),
              label: const Text(
                'Call for pickup',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
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
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _shareDeal,
              icon: const Icon(Icons.share, size: 20),
              label: const Text(
                'Share',
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
        ],
      ),
    );
  }
}
