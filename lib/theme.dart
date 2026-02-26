import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color brandOrange = Color(0xFFD94A09);
  static const Color _bgDark = Color(0xFF1A1210);
  static const Color _surfaceDark = Color(0xFF2A1F1A);
  static const Color _cardDark = Color(0xFF352820);
  static const Color _textPrimary = Color(0xFFF5F0EB);
  static const Color _textSecondary = Color(0xFFAA9E94);

  static ThemeData light() {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: brandOrange,
    );
    return _buildTheme(colorScheme);
  }

  static ThemeData dark() {
    final ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: brandOrange,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF4A2000),
      onPrimaryContainer: const Color(0xFFFFDBC9),
      secondary: const Color(0xFFD4896A),
      onSecondary: const Color(0xFF3E1D04),
      secondaryContainer: const Color(0xFF5A3520),
      onSecondaryContainer: const Color(0xFFFFDBC9),
      tertiary: const Color(0xFFB0A060),
      onTertiary: const Color(0xFF2E2A00),
      tertiaryContainer: const Color(0xFF45400A),
      onTertiaryContainer: const Color(0xFFECE27C),
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFDAD6),
      surface: _bgDark,
      onSurface: _textPrimary,
      onSurfaceVariant: _textSecondary,
      outline: const Color(0xFF5C4F46),
      outlineVariant: const Color(0xFF3D3530),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: _textPrimary,
      onInverseSurface: _bgDark,
      inversePrimary: const Color(0xFF8B3500),
      surfaceContainerHighest: _cardDark,
      surfaceContainerHigh: _cardDark,
      surfaceContainer: _surfaceDark,
      surfaceContainerLow: const Color(0xFF221915),
      surfaceContainerLowest: const Color(0xFF110E0C),
      surfaceDim: _bgDark,
      surfaceBright: const Color(0xFF3F3430),
    );
    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final bool isDark = colorScheme.brightness == Brightness.dark;
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: brandOrange,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 6,
      ),
      cardTheme: CardThemeData(
        color: isDark ? _cardDark : colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
          if (s.contains(WidgetState.selected)) return brandOrange;
          return isDark ? const Color(0xFF7A6E66) : null;
        }),
        trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
          if (s.contains(WidgetState.selected)) {
            return brandOrange.withAlpha(80);
          }
          return isDark ? const Color(0xFF3D3530) : null;
        }),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? _surfaceDark : colorScheme.surface,
        indicatorColor: brandOrange.withAlpha(40),
        iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
          if (s.contains(WidgetState.selected)) {
            return IconThemeData(color: brandOrange, size: 24);
          }
          return IconThemeData(
            color: isDark ? _textSecondary : colorScheme.onSurfaceVariant,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
          if (s.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: brandOrange,
            );
          }
          return TextStyle(
            fontSize: 12,
            color: isDark ? _textSecondary : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: isDark,
        fillColor: isDark ? _surfaceDark : null,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? _surfaceDark : colorScheme.surface,
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? const Color(0xFF3D3530) : null,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? _cardDark : null,
        contentTextStyle: TextStyle(color: isDark ? _textPrimary : null),
      ),
    );
  }
}
