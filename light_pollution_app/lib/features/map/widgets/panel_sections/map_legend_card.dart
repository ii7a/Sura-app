import 'package:flutter/material.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../../core/theme/panel_theme.dart';

class MapLegendCard extends StatelessWidget {
  const MapLegendCard({super.key});

  static const _gradientColors = [
    Color(0xFF000000),
    Color(0xFF0A0A2E),
    Color(0xFF16213E),
    Color(0xFF0F3460),
    Color(0xFF533483),
    Color(0xFFE94560),
    Color(0xFFFF6B35),
    Color(0xFFFF9F1C),
    Color(0xFFFFFFFF),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PanelStyle.cardPadding),
      decoration: PanelStyle.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.mapLegendRadiance,
            style: font(
              color: PanelColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: const LinearGradient(colors: _gradientColors),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.low, style: font(color: PanelColors.textMuted, fontSize: 9)),
              Text(l10n.high, style: font(color: PanelColors.textMuted, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}
