import 'package:flutter/material.dart';

import '../models/list_item.dart';
import '../models/shopping_list_manager.dart';
import '../widgets/add_item_input.dart';
import '../widgets/delete_options_sheet.dart';
import '../widgets/share_list_sheet.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  final ShoppingListManager _manager = ShoppingListManager();

  @override
  void initState() {
    super.initState();
    _manager.addListener(_onManagerUpdate);
  }

  @override
  void dispose() {
    _manager.removeListener(_onManagerUpdate);
    super.dispose();
  }

  void _onManagerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _openAddItem([String? initialListTitle]) {
    showAddItemInput(
      context,
      lists: _manager.sections.map((s) => s.title).toList(),
      initialList: initialListTitle,
      onSubmit: (item, listTitle) {
        _manager.addItem(item, listTitle);
      },
    );
  }

  void _openDeleteOptions() {
    DeleteOptionsSheet.show(
      context,
      onDeleteExpired: () {},
      onDeleteChecked: () {
        _manager.deleteChecked();
      },
      onDeleteAll: () {
        _manager.deleteAll();
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
            icon: const Icon(
              Icons.person_add_alt_1,
              color: Color(0xFF0071CE),
              size: 26,
            ),
            onPressed: _openShareSheet,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          for (final section in _manager.sections) ..._buildSection(section),
        ],
      ),
    );
  }

  List<Widget> _buildSection(ListSection section) {
    return [
      _SectionHeader(
        title: section.title,
        onAdd: () => _openAddItem(section.title),
      ),
      for (final item in section.items)
        _ItemRow(
          item: item,
          onCheckChanged: (v) => _manager.setChecked(item, v),
          onQtyChanged: (v) => _manager.setQty(item, v),
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
                child: _CustomCheckbox(
                  value: item.checked,
                  onChanged: onCheckChanged,
                ),
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: item.checked ? Colors.black38 : Colors.black,
                        decoration: item.checked
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
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
