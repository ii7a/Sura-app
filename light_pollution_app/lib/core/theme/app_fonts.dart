import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFonts {
  /// Returns the appropriate font-styling function based on the current locale.
  /// Usage: `AppFonts.style(context)(fontSize: 16, fontWeight: FontWeight.w600)`
  static TextStyle Function({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) style(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? GoogleFonts.notoSansArabic : GoogleFonts.montserrat;
  }

  /// Returns a TextTheme using the appropriate font family for the locale.
  static TextTheme textTheme(Locale locale) {
    if (locale.languageCode == 'ar') {
      return GoogleFonts.notoSansArabicTextTheme();
    }
    return GoogleFonts.montserratTextTheme();
  }
}
