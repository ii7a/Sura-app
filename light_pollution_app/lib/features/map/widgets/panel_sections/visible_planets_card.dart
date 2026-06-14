import 'package:flutter/material.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import 'package:light_pollution_app/core/l10n/bortle_l10n.dart';
import '../../../../core/theme/panel_theme.dart';
import '../../../../core/models/planet_data.dart';

class VisiblePlanetsCard extends StatelessWidget {
  const VisiblePlanetsCard({super.key, required this.planets});

  final List<PlanetVisibility> planets;

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
            l10n.visiblePlanets,
            style: font(
              color: PanelColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...planets.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: p.isVisible
                            ? PanelColors.accent.withValues(alpha: 0.15)
                            : PanelColors.background,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        p.icon,
                        style: TextStyle(
                          fontSize: 14,
                          color: p.isVisible ? PanelColors.accent : PanelColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: font(
                              color: p.isVisible ? PanelColors.textPrimary : PanelColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'mag ${p.magnitude.toStringAsFixed(1)} \u00B7 ${p.localizedBrightnessLabel(l10n)}',
                            style: font(
                              color: PanelColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: p.isVisible
                            ? PanelColors.success.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        p.isVisible ? l10n.visible : l10n.hidden,
                        style: font(
                          color: p.isVisible ? PanelColors.success : PanelColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
