import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color primary = Color(0xFF1677D2);
  static const Color background = Color(0xFFF4F9FF);
  static const Color textPrimary = Color(0xFF16324F);
  static const Color textSecondary = Color(0xFF647B91);

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: textPrimary,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE5EFF8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD9E7F3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD9E7F3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: Color(0xFFBBD8F1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(color: textPrimary, fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(color: textSecondary, fontSize: 14, height: 1.5),
    ),
  );
}
