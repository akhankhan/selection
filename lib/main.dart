import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'core/config/google_sign_in_config.dart';
import 'core/navigation/app_navigator.dart';
import 'core/services/account_sync_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/invite_deep_link_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/storage/auto_delete_preferences_store.dart';
import 'core/storage/favorites_store.dart';
import 'core/storage/location_store.dart';
import 'core/storage/loyalty_cards_store.dart';
import 'core/storage/notification_preferences_store.dart';
import 'core/storage/onboarding_store.dart';
import 'features/lists/models/shopping_list_manager.dart';
import 'features/onboarding/screens/app_launch_screen.dart';
import 'features/settings/services/push_notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);

  await AnalyticsService.instance.initialize();
  await ThemeController.instance.load();
  await OnboardingStore.instance.load();
  await FavoritesStore.instance.load();
  await LocationStore.instance.load();
  await AutoDeletePreferencesStore.instance.load();
  await LoyaltyCardsStore.instance.load();
  await NotificationPreferencesStore.instance.load();
  await ShoppingListManager.instance.load();
  await PushNotificationService.instance.initialize();
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  await GoogleSignIn.instance.initialize(
    serverClientId: GoogleSignInConfig.serverClientId,
  );
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    if (user == null) return;
    await _syncUserToFirestore(user);
    await AccountSyncService.instance.syncForUser(user);
    unawaited(PushNotificationService.instance.syncTokenIfPermitted());
    if (!await PushNotificationService.instance.isNotificationPermissionGranted()) {
      PushNotificationService.instance.resetPromptSession();
      unawaited(
        PushNotificationService.instance.schedulePermissionPromptWhenReady(),
      );
    }
  });
  runApp(const MyApp());
}

Future<void> _syncUserToFirestore(User? user) async {
  if (user == null) return;
  final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
  try {
    final snap = await ref.get();
    final profile = <String, dynamic>{
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoURL,
      'lastSignInAt': FieldValue.serverTimestamp(),
    };
    if (!snap.exists) {
      profile['createdAt'] = FieldValue.serverTimestamp();
      profile['notificationsEnabled'] =
          NotificationPreferencesStore.instance.enabled;
      await ref.set(profile);
    } else {
      await ref.update(profile);
    }
    if (NotificationPreferencesStore.instance.enabled) {
      unawaited(PushNotificationService.instance.syncTokenIfPermitted());
    }
  } catch (e, stack) {
    debugPrint('[Firestore] user sync failed: $e');
    unawaited(
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'user_sync'),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    InviteDeepLinkService.instance.initialize(
      onCode: AppNavigator.openInviteJoin,
    );
  }

  @override
  void dispose() {
    InviteDeepLinkService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: AppNavigator.key,
          title: 'MENU2GO',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeController.instance.themeMode,
          themeAnimationDuration: const Duration(milliseconds: 250),
          themeAnimationCurve: Curves.easeInOut,
          builder: (context, child) {
            SystemChrome.setSystemUIOverlayStyle(
              AppTheme.systemOverlayFor(Theme.of(context).brightness),
            );
            return child ?? const SizedBox.shrink();
          },
          home: const AppLaunchScreen(),
        );
      },
    );
  }
}
