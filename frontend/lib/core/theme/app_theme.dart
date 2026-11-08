import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Neo-Fintech Design System for Specto
abstract class AppColors {
  // ── Backgrounds ──────────────────────────────
  static const background = Color(0xFFF4F6F9);
  static const surface    = Color(0xFFFFFFFF);
  static const bento      = Color(0xFFF8FAFC);

  // ── Brand ────────────────────────────────────
  static const primary   = Color(0xFF2563EB);
  static const emerald   = Color(0xFF10B981); // money / bonus
  static const emeraldBg = Color(0xFFD1FAE5);
  static const amber     = Color(0xFFF59E0B); // warning
  static const amberBg   = Color(0xFFFEF3C7);
  static const danger    = Color(0xFFEF4444); // penalty / delete
  static const dangerBg  = Color(0xFFFEE2E2);

  // ── Text ─────────────────────────────────────
  static const textPrimary   = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
}

abstract class AppRadius {
  static const card   = 16.0;
  static const button = 14.0;
  static const bento  = 12.0;
  static const chip   = 20.0;
}

abstract class AppShadows {
  static const card = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}

abstract class AppPadding {
  static const screenH = 16.0;
  static const screenV = 12.0;
  static const card    = 16.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.manropeTextTheme(base.textTheme).apply(
      bodyColor:       AppColors.textPrimary,
      displayColor:    AppColors.textPrimary,
    );

    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary:   AppColors.primary,
        surface:   AppColors.surface,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
        error:     AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bento,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.bento),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.bento),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.bento),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.bento),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.bento),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        hintStyle: GoogleFonts.manrope(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        labelStyle: GoogleFonts.manrope(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
