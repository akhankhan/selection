import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme_extension.dart';

class AppTheme {
  static const Color brandBlue = Color(0xFF0071CE);
  static const Color navyDark = Color(0xFF1E293B);

  static const Color _darkBackground = Color(0xFF121212);
  static const Color _darkSurface = Color(0xFF1E1E1E);
  static const Color _darkCard = Color(0xFF252525);
  static const Color _darkOnSurface = Color(0xFFE8EAED);

  static SystemUiOverlayStyle systemOverlayFor(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const SystemUiOverlayStyle(
        statusBarColor: _darkSurface,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _darkSurface,
        systemNavigationBarIconBrightness: Brightness.light,
      );
    }
    return const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    );
  }

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: brandBlue,
      primary: brandBlue,
      surface: Colors.white,
      brightness: Brightness.light,
    );

    return _baseTheme(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackground: const Color(0xFFF4F5F7),
      appBarBackground: Colors.white,
      appBarForeground: Colors.black,
      divider: const Color(0xFFEEEEEE),
      extension: AppThemeExtension.light,
      systemOverlay: systemOverlayFor(Brightness.light),
    );
  }

  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: brandBlue,
      onPrimary: Colors.white,
      secondary: brandBlue,
      onSecondary: Colors.white,
      surface: _darkCard,
      onSurface: _darkOnSurface,
      onSurfaceVariant: Color(0xFF9AA0A6),
      outline: Color(0xFF3C3C3C),
      error: Color(0xFFCF6679),
      onError: Colors.black,
    );

    return _baseTheme(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackground: _darkBackground,
      appBarBackground: _darkSurface,
      appBarForeground: _darkOnSurface,
      divider: const Color(0xFF3C3C3C),
      extension: AppThemeExtension.dark,
      systemOverlay: systemOverlayFor(Brightness.dark),
    );
  }

  static ThemeData _baseTheme({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
    required Color appBarBackground,
    required Color appBarForeground,
    required Color divider,
    required AppThemeExtension extension,
    required SystemUiOverlayStyle systemOverlay,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      dividerColor: divider,
      extensions: [extension],
      canvasColor: scaffoldBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackground,
        foregroundColor: appBarForeground,
        iconTheme: IconThemeData(color: appBarForeground),
        actionsIconTheme: IconThemeData(color: appBarForeground),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: systemOverlay,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: extension.headerSurface,
        selectedItemColor: brandBlue,
        unselectedItemColor: extension.subtitle,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: extension.headerSurface,
        indicatorColor: brandBlue.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? brandBlue : extension.subtitle,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: extension.cardSurface,
        elevation: isDark ? 0 : 1,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.5 : 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isDark
              ? BorderSide(color: extension.border.withValues(alpha: 0.6))
              : BorderSide.none,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: extension.cardSurface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: extension.cardSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: extension.cardSurface,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: colorScheme.onSurface),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : navyDark,
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: extension.searchFill,
        labelStyle: TextStyle(color: extension.subtitle),
        hintStyle: TextStyle(color: extension.subtitle.withValues(alpha: 0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: extension.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: extension.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: brandBlue, width: 1.5),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return brandBlue;
          return null;
        }),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: extension.cardSurface,
        textColor: colorScheme.onSurface,
        iconColor: extension.subtitle,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return brandBlue;
          return extension.subtitle;
        }),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: colorScheme.onSurface),
        bodyMedium: TextStyle(color: extension.subtitle),
        titleLarge: TextStyle(
          color: extension.navyText,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
