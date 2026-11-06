import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryLight = Color(0xFF4338CA);
  static const Color primaryDark = Color(0xFF818CF8);
  static const Color secondaryLight = Color(0xFF059669);
  static const Color secondaryDark = Color(0xFF34D399);

  static ThemeData lightTheme() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primaryLight,
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFEEF2FF),
      onPrimaryContainer: Color(0xFF312E81),
      secondary: secondaryLight,
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFECFDF5),
      onSecondaryContainer: Color(0xFF064E3B),
      tertiary: Color(0xFF0284C7),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFE0F2FE),
      onTertiaryContainer: Color(0xFF0C4A6E),
      error: Color(0xFFDC2626),
      onError: Color(0xFFFFFFFF),
      surface: Color(0xFFF8FAFC),
      onSurface: Color(0xFF0F172A),
      surfaceContainer: Color(0xFFF1F5F9),
      surfaceContainerHighest: Color(0xFFE2E8F0),
      onSurfaceVariant: Color(0xFF475569),
      outline: Color(0xFF94A3B8),
      outlineVariant: Color(0xFFCBD5E1),
      shadow: Color(0x1A0F172A),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData darkTheme() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primaryDark,
      onPrimary: Color(0xFF1E1B4B),
      primaryContainer: Color(0xFF312E81),
      onPrimaryContainer: Color(0xFFE0E7FF),
      secondary: secondaryDark,
      onSecondary: Color(0xFF064E3B),
      secondaryContainer: Color(0xFF065F46),
      onSecondaryContainer: Color(0xFFA7F3D0),
      tertiary: Color(0xFF38BDF8),
      onTertiary: Color(0xFF082F49),
      tertiaryContainer: Color(0xFF075985),
      onTertiaryContainer: Color(0xFFBAE6FD),
      error: Color(0xFFEF4444),
      onError: Color(0xFFFFFFFF),
      surface: Color(0xFF0B0F19),
      onSurface: Color(0xFFF8FAFC),
      surfaceContainer: Color(0xFF151D2F),
      surfaceContainerHighest: Color(0xFF1E293B),
      onSurfaceVariant: Color(0xFF94A3B8),
      outline: Color(0xFF475569),
      outlineVariant: Color(0xFF334155),
      shadow: Color(0x40000000),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
