import 'package:flutter/material.dart';

class PanelColors {
  static const background = Color(0xFF1A1D23);
  static const cardBg = Color(0xFF23272F);
  static const cardBorder = Color(0xFF2E3340);
  static const accent = Color(0xFF6C63FF);
  static const accentGlow = Color(0xFF8B83FF);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0B8C8);
  static const textMuted = Color(0xFF6B7280);
  static const divider = Color(0xFF2E3340);
  static const success = Color(0xFF34D399);
  static const warning = Color(0xFFFBBF24);
  static const error = Color(0xFFEF4444);
  static const searchBg = Color(0xFF2A2E37);
}

class PanelStyle {
  static const double panelWidth = 350;
  static const double cardRadius = 14;
  static const double sectionSpacing = 12;
  static const double cardPadding = 16;

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: PanelColors.cardBg,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: PanelColors.cardBorder, width: 0.5),
      );
}
