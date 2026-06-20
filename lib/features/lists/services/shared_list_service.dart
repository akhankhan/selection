import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

import '../models/persisted_list_data.dart';
import '../models/shopping_list_manager.dart';

class SharedListService {
  SharedListService._();

  static final SharedListService instance = SharedListService._();

  static const inviteBaseUrl = 'https://selection-admin.web.app/join';

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<SharedListInvite> createOrUpdateInvite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Sign in to share your list with friends.');
    }

    final manager = ShoppingListManager.instance;
    if (manager.totalItemCount == 0) {
      throw StateError('Add items to your list before sharing.');
    }

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userSnap = await userRef.get();
    final existingListId = userSnap.data()?['activeSharedListId'] as String?;

    final items = _itemsFromManager(manager);
    final now = FieldValue.serverTimestamp();

    if (existingListId != null) {
      final listRef =
          FirebaseFirestore.instance.collection('shared_lists').doc(existingListId);
      final listSnap = await listRef.get();
      if (listSnap.exists) {
        await listRef.set(
          {
            'items': items,
            'updatedAt': now,
            'title': 'Shared shopping list',
          },
          SetOptions(merge: true),
        );
        final code = listSnap.data()?['inviteCode'] as String? ?? existingListId;
        return SharedListInvite(
          listId: existingListId,
          inviteCode: code,
          inviteUrl: '$inviteBaseUrl/$code',
        );
      }
    }

    final inviteCode = _generateInviteCode();
    final listRef = FirebaseFirestore.instance.collection('shared_lists').doc();
    final batch = FirebaseFirestore.instance.batch();

    batch.set(listRef, {
      'ownerId': user.uid,
      'memberIds': [user.uid],
      'inviteCode': inviteCode,
      'title': 'Shared shopping list',
      'items': items,
      'createdAt': now,
      'updatedAt': now,
    });
    batch.set(
      FirebaseFirestore.instance.collection('shared_list_codes').doc(inviteCode),
      {
        'listId': listRef.id,
        'ownerId': user.uid,
        'createdAt': now,
      },
    );
    batch.set(
      userRef,
      {'activeSharedListId': listRef.id},
      SetOptions(merge: true),
    );
    await batch.commit();

    return SharedListInvite(
      listId: listRef.id,
      inviteCode: inviteCode,
      inviteUrl: '$inviteBaseUrl/$inviteCode',
    );
  }

  Future<void> joinWithInviteCode(String rawCode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Sign in to join a shared list.');
    }

    final code = rawCode.trim().toUpperCase();
    if (code.length < 6) {
      throw StateError('Enter a valid invite code.');
    }

    final codeRef =
        FirebaseFirestore.instance.collection('shared_list_codes').doc(code);
    final codeSnap = await codeRef.get();
    if (!codeSnap.exists) {
      throw StateError('Invite code not found.');
    }

    final listId = codeSnap.data()?['listId'] as String?;
    if (listId == null || listId.isEmpty) {
      throw StateError('Invite code is invalid.');
    }

    final listRef = FirebaseFirestore.instance.collection('shared_lists').doc(listId);
    final listSnap = await listRef.get();
    if (!listSnap.exists) {
      throw StateError('Shared list no longer exists.');
    }

    final memberIds = (listSnap.data()?['memberIds'] as List?)
            ?.map((value) => value.toString())
            .toList() ??
        <String>[];
    if (!memberIds.contains(user.uid)) {
      memberIds.add(user.uid);
    }

    await listRef.set(
      {
        'memberIds': memberIds,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final itemsRaw = listSnap.data()?['items'];
    if (itemsRaw is List) {
      final items = itemsRaw
          .whereType<Map>()
          .map(
            (item) => PersistedListItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
      await ShoppingListManager.instance.mergeSharedItems(items);
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {'joinedSharedListId': listId},
      SetOptions(merge: true),
    );
  }

  Future<void> shareInviteLink() async {
    final invite = await createOrUpdateInvite();
    final message =
        'Join my MENU2GO shopping list!\n\nCode: ${invite.inviteCode}\nLink: ${invite.inviteUrl}\n\nTap the link to open the app with this code ready.';
    await SharePlus.instance.share(ShareParams(text: message));
  }

  List<Map<String, dynamic>> _itemsFromManager(ShoppingListManager manager) {
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
    return items;
  }
}

class SharedListInvite {
  const SharedListInvite({
    required this.listId,
    required this.inviteCode,
    required this.inviteUrl,
  });

  final String listId;
  final String inviteCode;
  final String inviteUrl;
}
