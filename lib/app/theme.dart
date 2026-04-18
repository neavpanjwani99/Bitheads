import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium Modern Medical Palette
  static const Color primary = Color(0xFF1E88E5); // Apple-like bright blue
  static const Color primaryDark = Color(0xFF0D47A1); // Deep blue for gradients
  static const Color accent = Color(0xFF5AC8FA); // iOS Teal/Cyan
  static const Color background = Color(0xFFF2F2F7); // iOS standard grouped background
  static const Color surface = Color(0xFFFFFFFF);
  static const Color critical = Color(0xFFFF3B30); // iOS Red
  static const Color urgent = Color(0xFFFF9500); // iOS Orange
  static const Color stable = Color(0xFF34C759); // iOS Green
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color divider = Color(0xFFE5E5EA);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primaryDark,
        surface: surface,
        error: critical,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -1),
        headlineLarge: GoogleFonts.inter(fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.5),
        headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textPrimary),
        titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: GoogleFonts.inter(fontWeight: FontWeight.w500, color: textPrimary),
        bodyMedium: GoogleFonts.inter(fontWeight: FontWeight.normal, color: textPrimary),
        labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, color: primary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: divider.withValues(alpha: 0.5), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface.withValues(alpha: 0.8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: divider, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        elevation: 8,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }
}
