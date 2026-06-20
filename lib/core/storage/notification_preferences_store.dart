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

  Future<bool> setEnabled(bool value) async {
    _enabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);

    if (value) {
      final granted = await PushNotificationService.instance.registerForPush();
      if (!granted) {
        _enabled = false;
        notifyListeners();
        await prefs.setBool(_key, false);
        return false;
      }
    } else {
      await PushNotificationService.instance.unregister();
    }

    await PushNotificationService.instance.syncPreferenceToFirestore();
    return true;
  }
}
