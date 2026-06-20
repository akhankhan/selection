import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/favorites_store.dart';
import '../../features/lists/models/persisted_list_data.dart';
import '../../features/lists/models/shopping_list_manager.dart';

class AccountSyncService {
  AccountSyncService._();

  static final AccountSyncService instance = AccountSyncService._();

  static const _shoppingListUpdatedKey = 'shopping_list_local_updated_ms';
  static const _favoritesUpdatedKey = 'favorites_local_updated_ms';

  bool _syncing = false;

  Future<void> syncForUser(User user) async {
    if (_syncing) return;
    _syncing = true;
    try {
      await Future.wait([
        _syncFavorites(user.uid),
        _syncShoppingList(user.uid),
      ]);
    } finally {
      _syncing = false;
    }
  }

  Future<void> pushShoppingListNow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _uploadShoppingList(user.uid);
  }

  Future<void> pushFavoritesNow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _uploadFavorites(user.uid);
  }

  Future<void> _syncFavorites(String uid) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(uid);
    final snap = await ref.get();
    final localUpdated = await _readLocalTimestamp(_favoritesUpdatedKey);
    final remoteUpdated = _timestampMillis(
      snap.data()?['favoritesUpdatedAt'],
    );

    if (snap.exists &&
        remoteUpdated > localUpdated &&
        snap.data()?['favoriteStoreIds'] is List) {
      final ids = (snap.data()!['favoriteStoreIds'] as List)
          .map((value) => value.toString())
          .toList();
      await FavoritesStore.instance.setOrdered(ids);
      await _writeLocalTimestamp(_favoritesUpdatedKey, remoteUpdated);
      return;
    }

    await _uploadFavorites(uid);
  }

  Future<void> _uploadFavorites(String uid) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'favoriteStoreIds': FavoritesStore.instance.orderedIds,
        'favoritesUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await _writeLocalTimestamp(_favoritesUpdatedKey, now);
  }

  Future<void> _syncShoppingList(String uid) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(uid);
    final snap = await ref.get();
    final localUpdated = await _readLocalTimestamp(_shoppingListUpdatedKey);
    final remoteData = snap.data()?['shoppingList'];
    final remoteUpdated = remoteData is Map<String, dynamic>
        ? _timestampMillis(remoteData['updatedAt'])
        : 0;

    if (snap.exists &&
        remoteUpdated > localUpdated &&
        remoteData is Map<String, dynamic>) {
      final itemsRaw = remoteData['items'];
      if (itemsRaw is List) {
        final items = itemsRaw
            .whereType<Map>()
            .map(
              (item) => PersistedListItem.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
        await ShoppingListManager.instance.importPersisted(
          PersistedShoppingList(items: items),
        );
        await _writeLocalTimestamp(_shoppingListUpdatedKey, remoteUpdated);
        return;
      }
    }

    await _uploadShoppingList(uid);
  }

  Future<void> _uploadShoppingList(String uid) async {
    final manager = ShoppingListManager.instance;
    final items = <Map<String, dynamic>>[];
    for (final section in manager.sections) {
      for (final item in section.items) {
        items.add(
          PersistedListItem(
            id: item.id,
            name: item.name,
            sectionTitle: section.title,
            qty: item.qty,
            checked: item.checked,
            saveText: item.saveText,
            salePrefix: item.salePrefix,
            priceText: item.priceText,
            subtitle: item.subtitle,
            flyerItemId: item.flyerItemId,
            expiresAtIso: item.expiresAt?.toIso8601String(),
            pageImageUrl: item.flyerPageImageUrl,
            cropLeft: item.flyerCropRect?.left,
            cropTop: item.flyerCropRect?.top,
            cropRight: item.flyerCropRect?.right,
            cropBottom: item.flyerCropRect?.bottom,
          ).toJson(),
        );
      }
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'shoppingList': {
          'items': items,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      },
      SetOptions(merge: true),
    );
    await _writeLocalTimestamp(_shoppingListUpdatedKey, now);
  }

  Future<void> markShoppingListChangedLocally() async {
    await _writeLocalTimestamp(
      _shoppingListUpdatedKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    await pushShoppingListNow();
  }

  Future<void> markFavoritesChangedLocally() async {
    await _writeLocalTimestamp(
      _favoritesUpdatedKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    await pushFavoritesNow();
  }

  int _timestampMillis(dynamic value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is int) return value;
    return 0;
  }

  Future<int> _readLocalTimestamp(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? 0;
  }

  Future<void> _writeLocalTimestamp(String key, int millis) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, millis);
  }
}
