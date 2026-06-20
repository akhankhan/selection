import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../features/lists/screens/lists_screen.dart';
import '../../features/lists/widgets/join_shared_list_sheet.dart';
import '../services/invite_deep_link_service.dart';

class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  static Future<void> openInviteJoin(String code) async {
    final nav = key.currentState;
    if (nav == null) return;

    if (FirebaseAuth.instance.currentUser == null) {
      await nav.push(
        MaterialPageRoute<void>(builder: (_) => const ListsScreen()),
      );
      return;
    }

    await nav.push(
      MaterialPageRoute<void>(builder: (_) => const ListsScreen()),
    );

    final context = key.currentContext;
    if (context == null || !context.mounted) return;

    await JoinSharedListSheet.show(
      context,
      initialCode: code,
    );
  }

  static void handlePendingInviteIfAny() {
    final code = InviteDeepLinkService.instance.consumePendingCode();
    if (code == null) return;
    openInviteJoin(code);
  }
}
