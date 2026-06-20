import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStore {
  OnboardingStore._();

  static final OnboardingStore instance = OnboardingStore._();

  static const _key = 'onboarding_completed_v1';

  bool _completed = false;

  bool get isCompleted => _completed;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _completed = prefs.getBool(_key) ?? false;
  }

  Future<void> complete() async {
    _completed = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
