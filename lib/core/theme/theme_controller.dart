import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreference {
  system('System'),
  light('Light'),
  dark('Dark');

  const AppThemePreference(this.label);

  final String label;

  static AppThemePreference fromLabel(String label) {
    return AppThemePreference.values.firstWhere(
      (value) => value.label == label,
      orElse: () => AppThemePreference.system,
    );
  }

  ThemeMode get themeMode => switch (this) {
        AppThemePreference.system => ThemeMode.system,
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
      };
}

class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const _prefKey = 'app_theme_preference';

  AppThemePreference _preference = AppThemePreference.system;
  bool _loaded = false;

  AppThemePreference get preference => _preference;
  String get label => _preference.label;
  ThemeMode get themeMode => _preference.themeMode;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _preference = AppThemePreference.fromLabel(
      prefs.getString(_prefKey) ?? AppThemePreference.dark.label,
    );
    _loaded = true;
    notifyListeners();
  }

  Future<void> setPreference(AppThemePreference preference) async {
    if (_preference == preference) return;

    _preference = preference;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, preference.label);
  }
}
