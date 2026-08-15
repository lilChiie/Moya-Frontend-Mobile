import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary: #7D9240
  static const Color primary = Color(0xFF7D9240);
  // Secondary: #B4C876
  static const Color secondary = Color(0xFFB4C876);
  // Tertiary / Soft Green: #D7DEC6
  static const Color tertiary = Color(0xFFD7DEC6);
  // Application Background: #F8F9F4
  static const Color background = Color(0xFFF8F9F4);
  // Surface: #FFFFFF
  static const Color surface = Color(0xFFFFFFFF);
  // Text Primary: #2F3327
  static const Color textPrimary = Color(0xFF2F3327);
  // Text Secondary: #6F7466
  static const Color textSecondary = Color(0xFF6F7466);
  // Border: #E1E5D9
  static const Color border = Color(0xFFE1E5D9);
  // Success: #5F7A36
  static const Color success = Color(0xFF5F7A36);
  // Error: #C85C5C
  static const Color error = Color(0xFFC85C5C);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        surface: surface,
        error: error,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.w600),
        headlineMedium: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.w600),
        headlineSmall: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.w500),
        titleSmall: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.normal),
        bodyMedium: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.normal),
        bodySmall: GoogleFonts.poppins(color: textSecondary, fontWeight: FontWeight.normal),
        labelLarge: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.w500),
        labelMedium: GoogleFonts.poppins(color: textSecondary, fontWeight: FontWeight.w500),
        labelSmall: GoogleFonts.poppins(color: textSecondary, fontWeight: FontWeight.w500),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
