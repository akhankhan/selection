import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../core/storage/notification_preferences_store.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
        '[FCM] foreground message: ${message.notification?.title ?? message.messageId}',
      );
    });

    _messaging.onTokenRefresh.listen(_syncTokenToFirestore);

    if (NotificationPreferencesStore.instance.enabled) {
      unawaited(_registerWhenReady());
    }
  }

  Future<void> _registerWhenReady() async {
    // APNS is often unavailable during cold start on iOS — defer briefly.
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    await registerForPush();
  }

  Future<bool> registerForPush() async {
    if (kIsWeb) return false;

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final authorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!authorized) return false;

      final token = await _getFcmTokenSafely();
      if (token != null) {
        await _syncTokenToFirestore(token);
      }
      return token != null;
    } catch (e, stack) {
      debugPrint('[FCM] registerForPush failed: $e\n$stack');
      return false;
    }
  }

  Future<void> unregister() async {
    if (kIsWeb) return;

    try {
      final token = await _getFcmTokenSafely();
      await _messaging.deleteToken();
      await _clearTokenFromFirestore(token);
    } catch (e) {
      debugPrint('[FCM] unregister failed: $e');
    }
  }

  Future<String?> _getFcmTokenSafely() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _waitForApnsToken();
      }
      return await _messaging.getToken();
    } on FirebaseException catch (e) {
      if (e.code == 'apns-token-not-set') {
        debugPrint(
          '[FCM] APNS token not ready — push will register when available.',
        );
        return null;
      }
      debugPrint('[FCM] getToken failed: ${e.code} ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[FCM] getToken failed: $e');
      return null;
    }
  }

  Future<void> _waitForApnsToken({int maxAttempts = 8}) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final apns = await _messaging.getAPNSToken();
      if (apns != null) return;
      await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
    }
  }

  Future<void> syncPreferenceToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {
        'notificationsEnabled': NotificationPreferencesStore.instance.enabled,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _syncTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {
        'fcmToken': token,
        'notificationsEnabled': NotificationPreferencesStore.instance.enabled,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _clearTokenFromFirestore(String? token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {
        'fcmToken': FieldValue.delete(),
        'notificationsEnabled': false,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
