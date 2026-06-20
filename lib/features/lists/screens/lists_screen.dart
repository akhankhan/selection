import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_extension.dart';
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
  final GlobalKey<AddItemInputState> _addItemKey = GlobalKey();

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
    _addItemKey.currentState?.focusWithList(initialListTitle);
  }

  void _handleAddItem(String item, String listTitle) {
    _manager.addItem(item, listTitle);
    _showSnack('Added "$item" to $listTitle');
  }

  void _openDeleteOptions() {
    DeleteOptionsSheet.show(
      context,
      expiredCount: _manager.expiredCount,
      checkedCount: _manager.checkedCount,
      totalCount: _manager.totalItemCount,
      onDeleteExpired: () => _handleDeleteExpired(),
      onDeleteChecked: () => _handleDeleteChecked(),
      onDeleteAll: () => _handleDeleteAll(),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.brandBlue,
      ),
    );
  }

  Future<bool> _confirmDelete({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final appTheme = context.appTheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: appTheme.cardSurface,
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: appTheme.navyText,
            ),
          ),
          content: Text(message, style: TextStyle(color: appTheme.subtitle)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('Cancel', style: TextStyle(color: appTheme.subtitle)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                confirmLabel,
                style: const TextStyle(
                  color: Color(0xFFD23A28),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<void> _handleDeleteExpired() async {
    final count = _manager.expiredCount;
    if (count == 0) {
      _showSnack('No expired items to delete.');
      return;
    }

    final confirmed = await _confirmDelete(
      title: 'Delete expired items?',
      message:
          'Remove $count expired deal${count == 1 ? '' : 's'} from your lists?',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !mounted) return;

    final removed = _manager.deleteExpired();
    _showSnack(
      removed == 0
          ? 'No expired items to delete.'
          : 'Removed $removed expired item${removed == 1 ? '' : 's'}.',
    );
  }

  Future<void> _handleDeleteChecked() async {
    final count = _manager.checkedCount;
    if (count == 0) {
      _showSnack('No checked items to delete.');
      return;
    }

    final confirmed = await _confirmDelete(
      title: 'Delete checked items?',
      message: 'Remove $count checked item${count == 1 ? '' : 's'}?',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !mounted) return;

    final removed = _manager.deleteChecked();
    _showSnack('Removed $removed checked item${removed == 1 ? '' : 's'}.');
  }

  Future<void> _handleDeleteAll() async {
    final count = _manager.totalItemCount;
    if (count == 0) {
      _showSnack('Your lists are already empty.');
      return;
    }

    final confirmed = await _confirmDelete(
      title: 'Delete all items?',
      message:
          'This will remove all $count items from every list. This cannot be undone.',
      confirmLabel: 'Delete all',
    );
    if (!confirmed || !mounted) return;

    final removed = _manager.deleteAll();
    _showSnack('Removed $removed item${removed == 1 ? '' : 's'}.');
  }

  void _openShareSheet() {
    ShareListSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Lists'),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: context.brandBlue, size: 28),
            onPressed: _openAddItem,
          ),
          IconButton(
            icon: Icon(Icons.delete, color: context.brandBlue, size: 26),
            onPressed: _openDeleteOptions,
          ),
          IconButton(
            icon: Icon(
              Icons.person_add_alt_1,
              color: context.brandBlue,
              size: 26,
            ),
            onPressed: _openShareSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 8),
              children: [
                for (final section in _manager.sections)
                  ..._buildSection(section),
              ],
            ),
          ),
          AddItemInput(
            key: _addItemKey,
            embedded: true,
            lists: _manager.sections.map((s) => s.title).toList(),
            onSubmit: _handleAddItem,
          ),
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
    final theme = context.appTheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.listSectionBg,
        border: Border(
          top: BorderSide(color: theme.listSectionBorder, width: 1.0),
          bottom: BorderSide(color: theme.listSectionBorder, width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.navyText,
              ),
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: Text(
              'Add Item',
              style: TextStyle(
                color: context.brandBlue,
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
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          color: theme.cardSurface,
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
                        color: item.checked
                            ? colorScheme.onSurface.withValues(alpha: 0.38)
                            : colorScheme.onSurface,
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
                                style: TextStyle(
                                  fontSize: 15,
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: item.priceText!,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: colorScheme.onSurface,
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
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        item.subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.subtitle,
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
        Divider(height: 1, color: theme.border, thickness: 1),
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
    final theme = context.appTheme;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: theme.cardSurface,
          border: Border.all(color: theme.chipInactive, width: 1.2),
          borderRadius: BorderRadius.circular(2),
        ),
        child: value
            ? Icon(Icons.check, size: 16, color: context.brandBlue)
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
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => _showQtyPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.sectionBg,
          border: Border.all(color: theme.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Qty.',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.subtitle,
                  fontWeight: FontWeight.normal,
                ),
              ),
              TextSpan(
                text: '$qty',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface,
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
    final theme = context.appTheme;

    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: context.appTheme.cardSurface,
      builder: (_) => SafeArea(
        top: false,
        child: SizedBox(
          height: 280,
          child: ListView.separated(
            itemCount: 20,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: theme.border),
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
