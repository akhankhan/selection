import 'package:flutter/material.dart';

import '../models/list_item.dart';
import '../widgets/add_item_input.dart';
import '../widgets/delete_options_sheet.dart';
import '../widgets/share_list_sheet.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  late final List<ListSection> _sections;

  @override
  void initState() {
    super.initState();
    _sections = [
      ListSection(title: 'My List', items: []),
      ListSection(
        title: "Cohen's Home Furnishings",
        items: [
          ListItem(
            name: 'DANTENTON 5PC QUEEN SET',
            thumbnail: const _BedThumbnail(),
            saveText: 'SAVE \$500',
            salePrefix: 'SALE',
            priceText: '\$2,699.99',
            subtitle: 'Until Thursday',
          ),
        ],
      ),
      ListSection(
        title: "President's Choice",
        items: [
          ListItem(
            name: 'PC® The Sizzle Wheel Chili\nCrisp Shrimp',
            thumbnail: const _PackageThumbnail(
              boxColor: Color(0xFFD23A28),
              plateColor: Color(0xFFEC6A3A),
            ),
            priceText: '\$13.00',
            subtitle: '1 month left',
          ),
          ListItem(
            name: 'PC® The Sizzle Wheel Garlic &\nHerb Shrimp',
            thumbnail: const _PackageThumbnail(
              boxColor: Color(0xFF9CC34D),
              plateColor: Color(0xFFD8E394),
            ),
            priceText: '\$13.00',
            subtitle: '1 month left',
          ),
        ],
      ),
    ];
  }

  void _openAddItem() {
    showAddItemInput(
      context,
      lists: _sections.map((s) => s.title).toList(),
      onSubmit: (item, listTitle) {
        setState(() {
          final section = _sections.firstWhere((s) => s.title == listTitle);
          section.items.add(
            ListItem(
              name: item,
              thumbnail: const _GenericThumbnail(),
            ),
          );
        });
      },
    );
  }

  void _openDeleteOptions() {
    DeleteOptionsSheet.show(
      context,
      onDeleteExpired: () {},
      onDeleteChecked: () {
        setState(() {
          for (final section in _sections) {
            section.items.removeWhere((item) => item.checked);
          }
        });
      },
      onDeleteAll: () {
        setState(() {
          for (final section in _sections) {
            section.items.clear();
          }
        });
      },
    );
  }

  void _openShareSheet() {
    ShareListSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Lists',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF0071CE), size: 28),
            onPressed: _openAddItem,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Color(0xFF0071CE), size: 26),
            onPressed: _openDeleteOptions,
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: Color(0xFF0071CE), size: 26),
            onPressed: _openShareSheet,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          for (final section in _sections) ..._buildSection(section),
        ],
      ),
    );
  }

  List<Widget> _buildSection(ListSection section) {
    return [
      _SectionHeader(title: section.title, onAdd: _openAddItem),
      for (final item in section.items)
        _ItemRow(
          item: item,
          onCheckChanged: (v) => setState(() => item.checked = v),
          onQtyChanged: (v) => setState(() => item.qty = v),
        ),
    ];
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onAdd});

  final String title;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF2F5F9),
        border: Border(
          top: BorderSide(color: Color(0xFFE2E7ED), width: 1.0),
          bottom: BorderSide(color: Color(0xFFE2E7ED), width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: const Text(
              'Add Item',
              style: TextStyle(
                color: Color(0xFF0071CE),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.onCheckChanged,
    required this.onQtyChanged,
  });

  final ListItem item;
  final ValueChanged<bool> onCheckChanged;
  final ValueChanged<int> onQtyChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _CustomCheckbox(value: item.checked, onChanged: onCheckChanged),
              ),
              const SizedBox(width: 12),
              item.thumbnail,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.25,
                      ),
                    ),
                    if (item.saveText != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.saveText!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFD23A28),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    if (item.priceText != null) ...[
                      const SizedBox(height: 1),
                      if (item.salePrefix != null)
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${item.salePrefix!} ',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: item.priceText!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          item.priceText!,
                          style: TextStyle(
                            fontSize: 15,
                            color: item.priceColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        item.subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _QtyButton(qty: item.qty, onChanged: onQtyChanged),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE), thickness: 1),
      ],
    );
  }
}

class _CustomCheckbox extends StatelessWidget {
  const _CustomCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF8C96A3), width: 1.2),
          borderRadius: BorderRadius.circular(2),
        ),
        child: value
            ? const Icon(Icons.check, size: 16, color: Color(0xFF0071CE))
            : null,
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.qty, required this.onChanged});

  final int qty;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showQtyPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          border: Border.all(color: const Color(0xFFD2D6DC)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: 'Qty.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  fontWeight: FontWeight.normal,
                ),
              ),
              TextSpan(
                text: '$qty',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQtyPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      builder: (_) => SafeArea(
        top: false,
        child: SizedBox(
          height: 280,
          child: ListView.separated(
            itemCount: 20,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (_, i) => ListTile(
              title: Text('Qty.${i + 1}'),
              onTap: () => Navigator.of(context).pop(i + 1),
            ),
          ),
        ),
      ),
    );
    if (selected != null) onChanged(selected);
  }
}

class _BedThumbnail extends StatelessWidget {
  const _BedThumbnail();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        width: 64,
        height: 56,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF8B7458), Color(0xFF4A3829)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 18,
                height: 56,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF6B5239), Color(0xFF2E2317)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 3,
              top: 18,
              child: Container(
                width: 12,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8D9BA),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 18,
                height: 56,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF6B5239), Color(0xFF2E2317)],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 3,
              top: 18,
              child: Container(
                width: 12,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8D9BA),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 6,
              right: 18,
              child: Container(
                height: 22,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE8DAC2), Color(0xFFB8A78A)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 26,
              right: 18,
              child: Container(
                height: 6,
                color: const Color(0xFFEEE3D0),
              ),
            ),
            Positioned(
              left: 18,
              top: 32,
              right: 18,
              child: Container(
                height: 24,
                color: const Color(0xFF382B1E),
              ),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                color: const Color(0xFFD32F2F),
                child: const Text(
                  'SALE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageThumbnail extends StatelessWidget {
  const _PackageThumbnail({required this.boxColor, required this.plateColor});

  final Color boxColor;
  final Color plateColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        width: 64,
        height: 56,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      boxColor,
                      Color.lerp(boxColor, Colors.black, 0.25)!,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 3,
              left: 4,
              child: Container(
                width: 14,
                height: 7,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(1),
                ),
                child: const Center(
                  child: Text(
                    'PC',
                    style: TextStyle(
                      fontSize: 5,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -6,
              bottom: -6,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2118),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: plateColor,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 6,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE07A4A),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 6,
                      child: Container(
                        width: 7,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE89A6E),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      bottom: 6,
                      child: Container(
                        width: 9,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD66838),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 4,
              bottom: 16,
              child: Container(
                width: 22,
                height: 3,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
            Positioned(
              left: 4,
              bottom: 10,
              child: Container(
                width: 16,
                height: 3,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                width: 12,
                height: 2,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenericThumbnail extends StatelessWidget {
  const _GenericThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFE3E8EE),
        borderRadius: BorderRadius.circular(2),
      ),
      child: const Icon(
        Icons.shopping_bag_outlined,
        color: Colors.black45,
        size: 28,
      ),
    );
  }
}
