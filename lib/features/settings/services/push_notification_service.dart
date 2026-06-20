import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../core/storage/notification_preferences_store.dart';

enum PushRegistrationStatus {
  success,
  permissionDenied,
  apnsPending,
  failed,
}

class PushRegistrationResult {
  const PushRegistrationResult(this.status, {this.message});

  final PushRegistrationStatus status;
  final String? message;

  bool get isEnabledInApp =>
      status == PushRegistrationStatus.success ||
      status == PushRegistrationStatus.apnsPending;
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;
  bool _loggedApnsPending = false;

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
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    await registerForPush();
  }

  Future<PushRegistrationResult> registerForPush() async {
    if (kIsWeb) {
      return const PushRegistrationResult(
        PushRegistrationStatus.failed,
        message: 'Push notifications are not supported on web.',
      );
    }

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final status = settings.authorizationStatus;
      if (status == AuthorizationStatus.denied) {
        return const PushRegistrationResult(
          PushRegistrationStatus.permissionDenied,
          message:
              'Notification permission was denied. Turn on alerts in iPhone Settings → Selection → Notifications.',
        );
      }

      final authorized = status == AuthorizationStatus.authorized ||
          status == AuthorizationStatus.provisional;
      if (!authorized) {
        return const PushRegistrationResult(
          PushRegistrationStatus.permissionDenied,
          message:
              'Notification permission is off. Enable alerts in iPhone Settings.',
        );
      }

      final token = await _getFcmTokenSafely();
      if (token != null) {
        await _syncTokenToFirestore(token);
        return const PushRegistrationResult(PushRegistrationStatus.success);
      }

      await syncPreferenceToFirestore();
      unawaited(_retryTokenRegistration());

      return PushRegistrationResult(
        PushRegistrationStatus.apnsPending,
        message: defaultTargetPlatform == TargetPlatform.iOS
            ? 'Notifications are on. iOS Simulator often cannot get a push token — use a real iPhone to test alerts.'
            : 'Notifications are on. Finishing device registration…',
      );
    } catch (e, stack) {
      debugPrint('[FCM] registerForPush failed: $e\n$stack');
      return PushRegistrationResult(
        PushRegistrationStatus.failed,
        message: 'Could not enable push notifications. Try again.',
      );
    }
  }

  Future<void> unregister() async {
    if (kIsWeb) return;

    try {
      try {
        await _messaging.deleteToken();
      } on FirebaseException catch (e) {
        if (e.code != 'apns-token-not-set') rethrow;
      }
      await _clearTokenFromFirestore();
    } catch (e) {
      debugPrint('[FCM] unregister note: $e');
      await _clearTokenFromFirestore();
    }
  }

  Future<void> _retryTokenRegistration({int attempts = 8}) async {
    for (var i = 0; i < attempts; i++) {
      await Future<void>.delayed(Duration(seconds: 2 + i));
      if (!NotificationPreferencesStore.instance.enabled) return;

      final token = await _getFcmTokenSafely(logPending: false);
      if (token != null) {
        await _syncTokenToFirestore(token);
        debugPrint('[FCM] token registered after retry');
        return;
      }
    }
  }

  Future<String?> _getFcmTokenSafely({bool logPending = true}) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _waitForApnsToken(maxAttempts: logPending ? 8 : 3);
      }
      return await _messaging.getToken();
    } on FirebaseException catch (e) {
      if (e.code == 'apns-token-not-set') {
        if (logPending && !_loggedApnsPending) {
          _loggedApnsPending = true;
          debugPrint(
            '[FCM] APNS token not ready yet — will retry when available.',
          );
        }
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

  Future<void> _clearTokenFromFirestore() async {
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
