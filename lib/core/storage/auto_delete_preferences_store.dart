import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AutoDeleteExpiredPolicy {
  never,
  after7Days,
  after30Days;

  String get label => switch (this) {
        AutoDeleteExpiredPolicy.never => 'Never (Default)',
        AutoDeleteExpiredPolicy.after7Days => 'After 7 days',
        AutoDeleteExpiredPolicy.after30Days => 'After 30 days',
      };

  Duration? get graceAfterExpiry => switch (this) {
        AutoDeleteExpiredPolicy.never => null,
        AutoDeleteExpiredPolicy.after7Days => const Duration(days: 7),
        AutoDeleteExpiredPolicy.after30Days => const Duration(days: 30),
      };

  static AutoDeleteExpiredPolicy fromLabel(String label) {
    for (final policy in AutoDeleteExpiredPolicy.values) {
      if (policy.label == label) return policy;
    }
    return AutoDeleteExpiredPolicy.never;
  }

  static AutoDeleteExpiredPolicy fromStorage(String? value) {
    return switch (value) {
      'after7Days' => AutoDeleteExpiredPolicy.after7Days,
      'after30Days' => AutoDeleteExpiredPolicy.after30Days,
      _ => AutoDeleteExpiredPolicy.never,
    };
  }

  String get storageValue => switch (this) {
        AutoDeleteExpiredPolicy.never => 'never',
        AutoDeleteExpiredPolicy.after7Days => 'after7Days',
        AutoDeleteExpiredPolicy.after30Days => 'after30Days',
      };
}

class AutoDeletePreferencesStore extends ChangeNotifier {
  AutoDeletePreferencesStore._();

  static final AutoDeletePreferencesStore instance =
      AutoDeletePreferencesStore._();

  static const _key = 'auto_delete_expired_policy';

  AutoDeleteExpiredPolicy _policy = AutoDeleteExpiredPolicy.never;
  AutoDeleteExpiredPolicy get policy => _policy;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _policy = AutoDeleteExpiredPolicy.fromStorage(prefs.getString(_key));
    notifyListeners();
  }

  Future<void> setPolicy(AutoDeleteExpiredPolicy policy) async {
    _policy = policy;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, policy.storageValue);
  }
}
