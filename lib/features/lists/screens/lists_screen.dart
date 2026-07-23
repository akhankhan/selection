import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../core/theme/app_theme_extension.dart';
import '../../../core/utils/phone_launcher.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../flyer/data/flyer_repository.dart';
import '../../flyer/models/store.dart';
import '../../settings/widgets/sign_in_required_gate.dart';
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
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<List<Store>>? _storesSubscription;
  /// Lowercased store name → phone
  Map<String, String> _phonesByStoreName = {};
  bool _showAddItemBar = false;

  static const String _myListTitle = 'My List';

  @override
  void initState() {
    super.initState();
    _manager.addListener(_onManagerUpdate);
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppNavigator.handlePendingInviteIfAny();
        });
      }
      if (mounted) setState(() {});
    });
    _storesSubscription =
        FlyerRepository.instance.watchStores().listen((stores) {
      if (!mounted) return;
      setState(() {
        _phonesByStoreName = {
          for (final s in stores)
            if (s.phone != null && s.phone!.trim().isNotEmpty)
              s.name.trim().toLowerCase(): s.phone!.trim(),
        };
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _storesSubscription?.cancel();
    _manager.removeListener(_onManagerUpdate);
    super.dispose();
  }

  void _onManagerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _openAddItem([String? initialListTitle]) {
    setState(() => _showAddItemBar = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addItemKey.currentState?.focusWithList(initialListTitle);
    });
  }

  void _closeAddItem() {
    if (!_showAddItemBar) return;
    _addItemKey.currentState?.dismiss();
    setState(() => _showAddItemBar = false);
  }

  void _handleAddItem(String item, String listTitle) {
    _manager.addItem(item, listTitle);
    _showSnack('Added "$item" to $listTitle');
  }

  Future<void> _renameItem(ListItem item) async {
    final controller = TextEditingController(text: item.name);
    final appTheme = context.appTheme;
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: appTheme.cardSurface,
          title: Text(
            'Rename item',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: appTheme.navyText,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Item name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: appTheme.subtitle)),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: Text(
                'Save',
                style: TextStyle(
                  color: context.brandBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (newName == null || newName.isEmpty || !mounted) return;
    _manager.renameItem(item, newName);
    _showSnack('Renamed to "$newName"');
  }

  Future<void> _confirmRemoveItem(ListItem item) async {
    final confirmed = await _confirmDelete(
      title: 'Remove item?',
      message: 'Remove "${item.name}" from your list?',
      confirmLabel: 'Remove',
    );
    if (!confirmed || !mounted) return;
    _manager.removeItem(item);
    _showSnack('Removed "${item.name}"');
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

  void _openShareSheet() async {
    if (!await ensureSignedIn(context)) return;
    if (!mounted) return;
    ShareListSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Lists')),
        body: const SignInRequiredGate(
          title: 'Sign in to use your lists',
          message:
              'Your shopping lists, sync, and sharing are available after you sign in.',
        ),
      );
    }

    return _buildSignedInScaffold(context);
  }

  Widget _buildSignedInScaffold(BuildContext context) {
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
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeAddItem,
              child: _manager.totalItemCount == 0
                  ? EmptyStateView(
                      icon: Icons.checklist_rtl_outlined,
                      title: 'Your list is empty',
                      message:
                          'Circle menu items or tap Add Item. Then call the restaurant to place a pickup order.',
                      actionLabel: 'Add first item',
                      onAction: () => _openAddItem(),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 8),
                      children: [
                        for (final section in _manager.sections)
                          ..._buildSection(section),
                      ],
                    ),
            ),
          ),
          if (_showAddItemBar)
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
    final isMyList = section.title == _myListTitle;
    final phone = isMyList
        ? null
        : _phonesByStoreName[section.title.trim().toLowerCase()];
    return [
      _SectionHeader(
        title: section.title,
        phone: phone,
        showCall: !isMyList,
        onAdd: () => _openAddItem(section.title),
        onCall: () => PhoneLauncher.callForPickup(
          context,
          phone: phone,
          restaurantName: section.title,
        ),
      ),
      if (section.items.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'No items in this list yet.',
            style: TextStyle(color: context.appTheme.subtitle),
          ),
        )
      else
        ...section.items.map(
          (item) => _ItemRow(
            key: ValueKey(item.id),
            item: item,
            onCheckChanged: (v) => _manager.setChecked(item, v),
            onQtyChanged: (v) => _manager.setQty(item, v),
            onRename: () => _renameItem(item),
            onDelete: () => _confirmRemoveItem(item),
          ),
        ),
    ];
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.onAdd,
    required this.onCall,
    required this.showCall,
    this.phone,
  });

  final String title;
  final VoidCallback onAdd;
  final VoidCallback onCall;
  final bool showCall;
  final String? phone;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
          if (showCall) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCall,
                icon: const Icon(Icons.phone, size: 18),
                label: Text(
                  phone == null || phone!.isEmpty
                      ? 'Call for pickup'
                      : 'Call for pickup · $phone',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: context.brandBlue,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    super.key,
    required this.item,
    required this.onCheckChanged,
    required this.onQtyChanged,
    required this.onRename,
    required this.onDelete,
  });

  final ListItem item;
  final ValueChanged<bool> onCheckChanged;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey('dismiss_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Column(
        children: [
          Material(
            color: theme.cardSurface,
            child: InkWell(
              onLongPress: onRename,
              child: Padding(
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
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.error,
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
            ),
          ),
          Divider(height: 1, color: theme.border, thickness: 1),
        ],
      ),
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
