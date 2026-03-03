import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFFFFDD00); // Yellow
  static const Color primaryDark = Color(0xFFC4AB00); // Darker Yellow
  static const Color accent = Color(0xFF00503A); // Dark Green

  // Dark Theme Colors
  static const Color backgroundDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color dividerDark = Color(0xFF2C2C2C);

  // Light Theme Colors
  static const Color backgroundLight = Color(0xFFFFFFFF); // Pure white
  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure white card
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF6C757D);
  static const Color dividerLight = Color(0xFFE0E0E0);

  static const Color success = Color(0xFF2ECC71);
  static const Color error = Color(0xFFE74C3C);

  static ThemeData get darkTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      background: backgroundDark,
      surface: surfaceDark,
      textPrimary: textPrimaryDark,
      textSecondary: textSecondaryDark,
      divider: dividerDark,
    );
  }

  static ThemeData get lightTheme {
    return _buildTheme(
      brightness: Brightness.light,
      background: backgroundLight,
      surface: surfaceLight,
      textPrimary: textPrimaryLight,
      textSecondary: textSecondaryLight,
      divider: dividerLight,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required Color divider,
  }) {
    final baseTextTheme = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.black, // Always dark text on yellow
        secondary: accent,
        onSecondary: Colors.white,
        error: error,
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.latoTextTheme(baseTextTheme).copyWith(
        bodyLarge: GoogleFonts.lato(color: textPrimary),
        bodyMedium: GoogleFonts.lato(color: textPrimary),
        titleLarge: GoogleFonts.lato(color: textPrimary),
        titleMedium: GoogleFonts.lato(color: textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        hintStyle: GoogleFonts.lato(color: textSecondary, fontSize: 14),
        labelStyle: GoogleFonts.lato(color: textSecondary, fontSize: 14),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black, // Dark text on yellow button
          minimumSize: const Size(double.infinity, 56),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryDark,
          textStyle:
              GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
