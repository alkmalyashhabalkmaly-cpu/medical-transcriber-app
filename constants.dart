import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ── Brand palette ────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  static const midnight    = Color(0xFF0D1B2A);   // deep navy background
  static const ink         = Color(0xFF1A2E40);   // card/surface
  static const teal        = Color(0xFF007A8A);   // primary accent – medical teal
  static const tealLight   = Color(0xFF00B4CC);   // hover / active
  static const amber       = Color(0xFFD4A843);   // secondary accent – gold
  static const textPrimary = Color(0xFFEAF0F6);   // near-white text
  static const textMuted   = Color(0xFF8BA3B8);   // secondary text
  static const success     = Color(0xFF2ECC71);
  static const error       = Color(0xFFE74C3C);
  static const warning     = Color(0xFFF39C12);
  static const enTerm      = Color(0xFF00D4E8);   // English medical term highlight
}

/// ── App-wide theme ───────────────────────────────────────────────────────────
ThemeData buildTheme() {
  final base = ThemeData.dark();
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.midnight,
    colorScheme: const ColorScheme.dark(
      primary:   AppColors.teal,
      secondary: AppColors.amber,
      surface:   AppColors.ink,
      error:     AppColors.error,
    ),
    textTheme: GoogleFonts.notoSansArabicTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.notoSansArabic(
        fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.notoSansArabic(
        fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.notoSansArabic(
        fontSize: 16, height: 2.0, color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.notoSansArabic(
        fontSize: 14, color: AppColors.textMuted,
      ),
    ),
    cardTheme: CardTheme(
      color: AppColors.ink,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF243447), width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.notoSansArabic(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.ink,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF243447)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF243447)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.teal, width: 2),
      ),
    ),
  );
}

/// ── API settings (override in flavours / env) ─────────────────────────────
class ApiConfig {
  ApiConfig._();
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );
}
