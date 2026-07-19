import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFD97706); // Premium Amber (high contrast, accessible)
  static const Color secondaryColor = Color(0xFF1E3A8A); // Deep Navy Blue (excellent contrast pairing)
  static const Color backgroundColor = Color(0xFFF9FAFB); // Elegant off-white
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF111827); // Dark Charcoal (pure high contrast)
  static const Color secondaryTextColor = Color(0xFF4B5563); // Medium Grey
  static const Color errorColor = Color(0xFFDC2626); // Bright red error

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: backgroundColor,
        primary: primaryColor,
        secondary: secondaryColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        error: errorColor,
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.5),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor, letterSpacing: -0.5),
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
        bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textColor, height: 1.4),
        bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: secondaryTextColor, height: 1.4),
        labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          shadowColor: primaryColor.withAlpha(77),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 2.5),
        ),
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
        hintStyle: const TextStyle(fontSize: 16, color: secondaryTextColor),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textColor),
        iconTheme: IconThemeData(color: textColor, size: 28),
      ),
    );
  }
}
