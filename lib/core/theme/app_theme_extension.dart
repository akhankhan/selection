import 'package:flutter/material.dart';

@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.navyText,
    required this.subtitle,
    required this.border,
    required this.searchFill,
    required this.sectionBg,
    required this.chipInactive,
    required this.headerSurface,
    required this.cardSurface,
    required this.listSectionBg,
    required this.listSectionBorder,
  });

  final Color navyText;
  final Color subtitle;
  final Color border;
  final Color searchFill;
  final Color sectionBg;
  final Color chipInactive;
  final Color headerSurface;
  final Color cardSurface;
  final Color listSectionBg;
  final Color listSectionBorder;

  static const light = AppThemeExtension(
    navyText: Color(0xFF1E293B),
    subtitle: Color(0xFF757575),
    border: Color(0xFFEEEEEE),
    searchFill: Color(0xFFF2F3F5),
    sectionBg: Color(0xFFF7F8FA),
    chipInactive: Color(0xFF5F6368),
    headerSurface: Colors.white,
    cardSurface: Colors.white,
    listSectionBg: Color(0xFFF2F5F9),
    listSectionBorder: Color(0xFFE2E7ED),
  );

  static const dark = AppThemeExtension(
    navyText: Color(0xFFE8EAED),
    subtitle: Color(0xFF9AA0A6),
    border: Color(0xFF3C3C3C),
    searchFill: Color(0xFF2C2C2C),
    sectionBg: Color(0xFF1A1A1A),
    chipInactive: Color(0xFF9AA0A6),
    headerSurface: Color(0xFF1E1E1E),
    cardSurface: Color(0xFF252525),
    listSectionBg: Color(0xFF252525),
    listSectionBorder: Color(0xFF3C3C3C),
  );

  @override
  AppThemeExtension copyWith({
    Color? navyText,
    Color? subtitle,
    Color? border,
    Color? searchFill,
    Color? sectionBg,
    Color? chipInactive,
    Color? headerSurface,
    Color? cardSurface,
    Color? listSectionBg,
    Color? listSectionBorder,
  }) {
    return AppThemeExtension(
      navyText: navyText ?? this.navyText,
      subtitle: subtitle ?? this.subtitle,
      border: border ?? this.border,
      searchFill: searchFill ?? this.searchFill,
      sectionBg: sectionBg ?? this.sectionBg,
      chipInactive: chipInactive ?? this.chipInactive,
      headerSurface: headerSurface ?? this.headerSurface,
      cardSurface: cardSurface ?? this.cardSurface,
      listSectionBg: listSectionBg ?? this.listSectionBg,
      listSectionBorder: listSectionBorder ?? this.listSectionBorder,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      navyText: Color.lerp(navyText, other.navyText, t)!,
      subtitle: Color.lerp(subtitle, other.subtitle, t)!,
      border: Color.lerp(border, other.border, t)!,
      searchFill: Color.lerp(searchFill, other.searchFill, t)!,
      sectionBg: Color.lerp(sectionBg, other.sectionBg, t)!,
      chipInactive: Color.lerp(chipInactive, other.chipInactive, t)!,
      headerSurface: Color.lerp(headerSurface, other.headerSurface, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      listSectionBg: Color.lerp(listSectionBg, other.listSectionBg, t)!,
      listSectionBorder:
          Color.lerp(listSectionBorder, other.listSectionBorder, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemeExtension get appTheme =>
      Theme.of(this).extension<AppThemeExtension>() ?? AppThemeExtension.light;

  Color get brandBlue => Theme.of(this).colorScheme.primary;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
