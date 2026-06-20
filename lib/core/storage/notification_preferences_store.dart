import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/settings/services/push_notification_service.dart';

class NotificationPreferencesStore extends ChangeNotifier {
  NotificationPreferencesStore._();

  static final NotificationPreferencesStore instance =
      NotificationPreferencesStore._();

  static const _key = 'push_notifications_enabled';

  bool _enabled = true;
  bool get enabled => _enabled;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_key) ?? true;
    notifyListeners();
  }

  Future<PushRegistrationResult?> setEnabled(bool value) async {
    if (!value) {
      _enabled = false;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, false);
      await PushNotificationService.instance.unregister();
      await PushNotificationService.instance.syncPreferenceToFirestore();
      return null;
    }

    _enabled = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);

    final result = await PushNotificationService.instance.registerForPush();
    if (!result.isEnabledInApp) {
      _enabled = false;
      notifyListeners();
      await prefs.setBool(_key, false);
    } else {
      await PushNotificationService.instance.syncPreferenceToFirestore();
    }

    return result;
  }
}
