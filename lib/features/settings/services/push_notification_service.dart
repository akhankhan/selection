import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../core/storage/notification_preferences_store.dart';

enum PushRegistrationStatus {
  success,
  permissionDenied,
  apnsPending,
  failed,
  loginRequired,
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

  static const _androidChannelId = 'menu2go_alerts';
  static const _androidChannelName = 'Deal alerts';
  static const _androidSmallIcon = 'ic_stat_menu2go';
  static const _androidLargeIcon = 'ic_notification_large';
  static const _brandPink = Color(0xFFEC3090);

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _loggedApnsPending = false;
  bool _promptShownThisSession = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initLocalNotifications();

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    _messaging.onTokenRefresh.listen(_syncTokenToFirestore);

    // Only register when logged in — token is saved per user in Firestore.
    if (NotificationPreferencesStore.instance.enabled &&
        FirebaseAuth.instance.currentUser != null) {
      unawaited(_registerWhenReady());
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings(_androidSmallIcon);
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _androidChannelId,
              _androidChannelName,
              description: 'Promotions and deal alerts from MENU2GO',
              importance: Importance.high,
            ),
          );
    }
  }

  /// Lets us ask again after sign-in if the user skipped the first prompt.
  void resetPromptSession() {
    _promptShownThisSession = false;
  }

  /// Waits for the root navigator, then shows the in-app + OS permission flow.
  Future<void> schedulePermissionPromptWhenReady({
    Duration maxWait = const Duration(seconds: 6),
  }) async {
    final deadline = DateTime.now().add(maxWait);
    while (DateTime.now().isBefore(deadline)) {
      final context = AppNavigator.key.currentContext;
      if (context != null && context.mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (!context.mounted) {
          await Future<void>.delayed(const Duration(milliseconds: 150));
          continue;
        }
        await promptForPermissionIfNeeded(context);
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    debugPrint('[FCM] permission prompt skipped — navigator not ready');
  }

  /// Re-run after sign-in (browse may have loaded before the user was logged in).
  Future<void> promptAfterSignIn(BuildContext context) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!context.mounted) {
      await schedulePermissionPromptWhenReady();
      return;
    }
    await promptForPermissionIfNeeded(context);
    await syncTokenIfPermitted();
  }

  /// Saves FCM token when permission is already granted — no OS dialog.
  Future<void> syncTokenIfPermitted() async {
    if (kIsWeb || FirebaseAuth.instance.currentUser == null) return;
    if (!NotificationPreferencesStore.instance.enabled) return;
    if (!await _hasNotificationPermission()) return;

    final token = await _getFcmTokenSafely();
    if (token != null) {
      await _syncTokenToFirestore(token);
    }
  }

  Future<void> _registerWhenReady() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await syncTokenIfPermitted();
  }

  /// Call after login or from Settings to show the OS permission dialog.
  Future<PushRegistrationResult> registerForPush() async {
    if (kIsWeb) {
      return const PushRegistrationResult(
        PushRegistrationStatus.failed,
        message: 'Push notifications are not supported on web.',
      );
    }

    try {
      final permission = await _requestNotificationPermission();
      if (!permission) {
        return PushRegistrationResult(
          PushRegistrationStatus.permissionDenied,
          message: _permissionDeniedMessage(),
        );
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('[FCM] permission granted — token will save after sign-in');
        return const PushRegistrationResult(
          PushRegistrationStatus.success,
          message: 'Notifications allowed. Sign in to receive deal alerts.',
        );
      }

      final token = await _getFcmTokenSafely();
      if (token != null) {
        await _syncTokenToFirestore(token);
        debugPrint('[FCM] token registered for ${user.uid}');
        return const PushRegistrationResult(PushRegistrationStatus.success);
      }

      await syncPreferenceToFirestore();
      unawaited(_retryTokenRegistration());

      return PushRegistrationResult(
        PushRegistrationStatus.apnsPending,
        message: defaultTargetPlatform == TargetPlatform.iOS
            ? 'Notifications are on. iOS Simulator often cannot get a push token — use a real iPhone.'
            : 'Notifications allowed. Finishing device registration…',
      );
    } catch (e, stack) {
      debugPrint('[FCM] registerForPush failed: $e\n$stack');
      return PushRegistrationResult(
        PushRegistrationStatus.failed,
        message: 'Could not enable push notifications. Try again.',
      );
    }
  }

  /// Shows a one-time in-app prompt, then the system permission dialog.
  Future<void> promptForPermissionIfNeeded(BuildContext context) async {
    if (_promptShownThisSession) {
      debugPrint('[FCM] in-app prompt already shown this session');
      return;
    }
    if (!NotificationPreferencesStore.instance.enabled) {
      debugPrint('[FCM] notifications disabled in app preferences');
      return;
    }

    final alreadyGranted = await _hasNotificationPermission();
    if (alreadyGranted) {
      debugPrint('[FCM] notification permission already granted');
      unawaited(syncTokenIfPermitted());
      return;
    }

    if (!context.mounted) {
      debugPrint('[FCM] prompt aborted — context not mounted');
      return;
    }

    debugPrint('[FCM] showing in-app permission dialog');
    _promptShownThisSession = true;

    final allow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Allow deal alerts?'),
        content: const Text(
          'MENU2GO can notify you when new flyers and promotions '
          'are available in your area.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    if (allow != true || !context.mounted) return;

    final granted = await _requestNotificationPermission();
    if (!context.mounted) return;

    if (granted) {
      await syncTokenIfPermitted();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifications enabled. You\'ll receive deal alerts.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
        content: Text(
          _permissionDeniedMessage(),
        ),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: openAppSettings,
        ),
      ),
    );
  }

  Future<bool> isNotificationPermissionGranted() => _hasNotificationPermission();

  Future<bool> _requestNotificationPermission() async {
    if (kIsWeb) return false;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.status;
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) return false;

      final result = await Permission.notification.request();
      debugPrint('[FCM] Android notification permission: $result');
      return result.isGranted;
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final status = settings.authorizationStatus;
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  Future<bool> _hasNotificationPermission() async {
    if (kIsWeb) return false;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return Permission.notification.isGranted;
    }
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  String _permissionDeniedMessage() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'Notification permission is off. Enable MENU2GO notifications in '
          'Android Settings → Apps → MENU2GO → Notifications.';
    }
    return 'Notification permission is off. Enable alerts in iPhone Settings → '
        'MENU2GO → Notifications.';
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    debugPrint('[FCM] foreground: ${notification.title}');

    if (kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: 'Promotions and deal alerts from MENU2GO',
      importance: Importance.high,
      priority: Priority.high,
      icon: _androidSmallIcon,
      color: _brandPink,
      largeIcon: DrawableResourceAndroidBitmap(_androidLargeIcon),
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
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
      if (FirebaseAuth.instance.currentUser == null) return;

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
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        await _waitForApnsToken(maxAttempts: logPending ? 8 : 3);
      }
      return await _messaging.getToken();
    } on FirebaseException catch (e) {
      if (e.code == 'apns-token-not-set') {
        if (logPending && !_loggedApnsPending) {
          _loggedApnsPending = true;
          debugPrint('[FCM] APNS token not ready yet — will retry.');
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
