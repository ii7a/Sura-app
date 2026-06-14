import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_fonts.dart';

class AppColors {
  // Brand colors from brand guideline
  static const navy = Color(0xFF133354);
  static const white = Color(0xFFFFFFFF);
  static const dark = Color(0xFF0E1720);

  // Derived colors (light mode defaults)
  static const background = white;
  static const cardBg = Color(0xFFF5F5F5);
  static const divider = Color(0xFFE8E8E8);
  static const textPrimary = dark;
  static const textSecondary = Color(0xFF6B7280);
  static const textHint = Color(0xFF9CA3AF);

  // Dark mode colors
  static const darkBg = Color(0xFF0E1720);
  static const darkCard = Color(0xFF1A2530);
  static const darkDivider = Color(0xFF2A3540);

  /// Get background color based on current theme brightness
  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBg : white;

  /// Get card/surface color based on current theme
  static Color card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkCard : cardBg;

  /// Get primary text color
  static Color text(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? white : dark;

  /// Get secondary text color
  static Color textSub(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF9CA3AF) : textSecondary;

  /// Get hint text color
  static Color hint(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF6B7280) : textHint;

  /// Get divider color
  static Color div(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkDivider : divider;

  /// Get icon color (nav, actions)
  static Color icon(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? white : navy;
}

class AppTheme {
  static ThemeData lightTheme(Locale locale) {
    final textTheme = AppFonts.textTheme(locale);
    final isArabic = locale.languageCode == 'ar';
    final fontFn = isArabic ? GoogleFonts.notoSansArabic : GoogleFonts.montserrat;

    return ThemeData(
      brightness: Brightness.light,
      colorSchemeSeed: AppColors.navy,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: fontFn(
          color: AppColors.navy,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: AppColors.navy),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        height: 64,
        elevation: 0,
        indicatorColor: AppColors.navy.withValues(alpha: 0.1),
        labelTextStyle: WidgetStatePropertyAll(
          fontFn(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        iconTheme: const WidgetStatePropertyAll(
          IconThemeData(color: AppColors.textSecondary, size: 24),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: fontFn(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          side: const BorderSide(color: AppColors.navy),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 0.5,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.navy.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.navy.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
        ),
        labelStyle: fontFn(color: AppColors.textSecondary),
        hintStyle: fontFn(color: AppColors.textHint),
      ),
    );
  }

  /// Full dark theme for the entire app
  static ThemeData darkTheme(Locale locale) {
    final textTheme = AppFonts.textTheme(locale);
    final isArabic = locale.languageCode == 'ar';
    final fontFn = isArabic ? GoogleFonts.notoSansArabic : GoogleFonts.montserrat;

    return ThemeData(
      brightness: Brightness.dark,
      colorSchemeSeed: AppColors.navy,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0E1720),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: const Color(0xFF1A2530),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0E1720),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: fontFn(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w700),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0E1720),
        height: 64,
        elevation: 0,
        indicatorColor: AppColors.navy.withValues(alpha: 0.3),
        labelTextStyle: WidgetStatePropertyAll(
          fontFn(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.white),
        ),
        iconTheme: const WidgetStatePropertyAll(
          IconThemeData(color: AppColors.white, size: 24),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: fontFn(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.white,
          side: const BorderSide(color: AppColors.navy),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF2A3540), thickness: 0.5),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.navy.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.navy.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
        ),
        labelStyle: fontFn(color: const Color(0xFF9CA3AF)),
        hintStyle: fontFn(color: const Color(0xFF6B7280)),
      ),
    );
  }
}
