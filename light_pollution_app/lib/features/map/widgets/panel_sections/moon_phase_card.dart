import 'package:flutter/material.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import 'package:light_pollution_app/core/l10n/bortle_l10n.dart';
import '../../../../core/theme/panel_theme.dart';
import '../../../../core/models/moon_data.dart';

class MoonPhaseCard extends StatelessWidget {
  const MoonPhaseCard({super.key, required this.moonData});

  final MoonData moonData;

  String get _moonEmoji {
    final age = moonData.age;
    if (age < 1.85) return '\u{1F311}';
    if (age < 5.53) return '\u{1F312}';
    if (age < 9.22) return '\u{1F313}';
    if (age < 12.91) return '\u{1F314}';
    if (age < 16.61) return '\u{1F315}';
    if (age < 20.30) return '\u{1F316}';
    if (age < 23.99) return '\u{1F317}';
    if (age < 27.68) return '\u{1F318}';
    return '\u{1F311}';
  }

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
            l10n.moonPhase,
            style: font(
              color: PanelColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(_moonEmoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moonData.phaseName,
                      style: font(
                        color: PanelColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      l10n.illuminated(moonData.illuminationPercent),
                      style: font(
                        color: PanelColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _InfoChip(label: l10n.impact, value: moonData.localizedImpact(l10n)),
              _InfoChip(label: l10n.ageLabel, value: l10n.daysValue(moonData.age.toStringAsFixed(1))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            moonData.localizedImpactDescription(l10n),
            style: font(
              color: PanelColors.textMuted,
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: PanelColors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: font(
              color: PanelColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: font(
              color: PanelColors.textMuted,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
