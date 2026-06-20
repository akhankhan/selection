import 'package:flutter/material.dart';

import '../../../core/storage/favorites_store.dart';
import '../../../core/theme/app_theme_extension.dart';
import '../../flyer/data/flyer_repository.dart';
import '../../flyer/models/store.dart';

class EditFavoritesScreen extends StatefulWidget {
  const EditFavoritesScreen({super.key});

  @override
  State<EditFavoritesScreen> createState() => _EditFavoritesScreenState();
}

class _EditFavoritesScreenState extends State<EditFavoritesScreen> {
  List<String> _orderedIds = [];

  @override
  void initState() {
    super.initState();
    _orderedIds = List<String>.from(FavoritesStore.instance.orderedIds);
    FavoritesStore.instance.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    FavoritesStore.instance.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (!mounted) return;
    setState(() {
      _orderedIds = List<String>.from(FavoritesStore.instance.orderedIds);
    });
  }

  Future<void> _remove(String storeId) async {
    await FavoritesStore.instance.remove(storeId);
  }

  Future<void> _saveOrder(List<String> orderedIds) async {
    await FavoritesStore.instance.setOrdered(orderedIds);
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Edit Favorites',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Theme.of(context).dividerColor),
        ),
      ),
      body: StreamBuilder<List<Store>>(
        stream: FlyerRepository.instance.watchStores(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Text(
                'Could not load stores.',
                style: TextStyle(color: appTheme.subtitle),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final storesById = {
            for (final store in snap.data!) store.id: store,
          };
          final favorites = _orderedIds
              .where(storesById.containsKey)
              .map((id) => storesById[id]!)
              .toList();

          if (favorites.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 56,
                      color: appTheme.subtitle,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No favorite stores yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: appTheme.navyText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the heart on any store in Browse to add it here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: appTheme.subtitle, height: 1.4),
                    ),
                  ],
                ),
              ),
            );
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: favorites.length,
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) newIndex -= 1;
              setState(() {
                final id = _orderedIds.removeAt(oldIndex);
                _orderedIds.insert(newIndex, id);
              });
              await _saveOrder(_orderedIds);
            },
            itemBuilder: (context, index) {
              final store = favorites[index];
              return _FavoriteRow(
                key: ValueKey(store.id),
                index: index,
                store: store,
                onRemove: () => _remove(store.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _FavoriteRow extends StatelessWidget {
  const _FavoriteRow({
    super.key,
    required this.index,
    required this.store,
    required this.onRemove,
  });

  final int index;
  final Store store;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: appTheme.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appTheme.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ReorderableDragStartListener(
          index: index,
          child: Icon(Icons.drag_handle, color: appTheme.subtitle),
        ),
        title: Text(
          store.name,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: appTheme.navyText,
          ),
        ),
        subtitle: store.dateRange.isEmpty
            ? null
            : Text(store.dateRange, style: TextStyle(color: appTheme.subtitle)),
        trailing: IconButton(
          tooltip: 'Remove favorite',
          onPressed: onRemove,
          icon: Icon(Icons.close, color: appTheme.subtitle),
        ),
      ),
    );
  }
}
