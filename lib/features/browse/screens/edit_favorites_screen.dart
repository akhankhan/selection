import 'package:flutter/material.dart';

import '../../../core/storage/favorites_store.dart';
import '../../../core/storage/location_store.dart';
import '../../../core/theme/app_theme_extension.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../flyer/data/flyer_repository.dart';
import '../../flyer/models/store.dart';

class EditFavoritesScreen extends StatefulWidget {
  const EditFavoritesScreen({super.key});

  @override
  State<EditFavoritesScreen> createState() => _EditFavoritesScreenState();
}

class _EditFavoritesScreenState extends State<EditFavoritesScreen> {
  List<String> _orderedIds = [];
  Object? _pruneSource;

  void _schedulePrune(List<Store> stores) {
    if (identical(_pruneSource, stores)) return;
    _pruneSource = stores;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FavoritesStore.instance.pruneForStores(stores);
    });
  }

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
            return const ErrorStateView(
              message: 'We could not load your favorite stores right now.',
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          _schedulePrune(snap.data!);

          final storesById = {
            for (final store in snap.data!) store.id: store,
          };
          final postal = LocationStore.instance.postal;
          final favorites = _orderedIds
              .where(storesById.containsKey)
              .map((id) => storesById[id]!)
              .where((store) => store.isVisibleForUser(postal))
              .toList();

          if (_orderedIds.isNotEmpty && favorites.isEmpty) {
            return EmptyStateView(
              icon: Icons.favorite_border,
              title: 'No active favorites',
              message:
                  'Your saved stores are hidden or no longer available. '
                  'Favorite stores again from Browse when they are live.',
            );
          }

          if (favorites.isEmpty) {
            return EmptyStateView(
              icon: Icons.favorite_border,
              title: 'No favorite stores yet',
              message:
                  'Tap the heart on any store in Browse to add it here.',
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
