import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium Modern Medical Palette
  static const Color primary = Color(0xFF2563EB); // Calm blue
  static const Color primaryDark = Color(0xFF1E3A5F); // Deep navy
  static const Color primaryLight = Color(0xFFEFF6FF); // Soft blue background
  static const Color background = Color(0xFFF5F7FA); // Off-white base
  static const Color surface = Color(0xFFFFFFFF); // White cards
  
  static const Color critical = Color(0xFFDC2626); // Muted red
  static const Color criticalLight = Color(0xFFFEF2F2);
  static const Color urgent = Color(0xFFD97706); // Amber
  static const Color urgentLight = Color(0xFFFFFBEB);
  static const Color stable = Color(0xFF16A34A); // Forest green
  static const Color stableLight = Color(0xFFF0FDF4);
  
  static const Color textPrimary = Color(0xFF1E293B); // Dark slate
  static const Color textSecondary = Color(0xFF64748B); // Medium gray
  static const Color divider = Color(0xFFE2E8F0); // Very light
  static const Color accent = Color(0xFF0D9488); // Teal for staff

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary, error: critical, surface: surface),
      useMaterial3: true,
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 1,
        iconTheme: const IconThemeData(color: textPrimary),
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: divider, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: critical, width: 1.5)),
        hintStyle: GoogleFonts.inter(color: textSecondary, fontWeight: FontWeight.w300),
        labelStyle: GoogleFonts.inter(color: textSecondary),
      ),
    );
  }
}
