import 'package:flutter/material.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../../core/theme/panel_theme.dart';
import '../../../../core/widgets/circular_gauge.dart';

class StargazingScoreCard extends StatelessWidget {
  const StargazingScoreCard({
    super.key,
    required this.score,
    this.cloudCover,
    this.moonIllumination,
    this.bortleClass,
  });

  final int score;
  final int? cloudCover;
  final double? moonIllumination;
  final int? bortleClass;

  String _label(AppLocalizations l10n) {
    if (score >= 80) return l10n.excellent;
    if (score >= 60) return l10n.good;
    if (score >= 40) return l10n.fair;
    if (score >= 20) return l10n.poor;
    return l10n.veryPoor;
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
        children: [
          Text(
            l10n.stargazingScore,
            style: font(
              color: PanelColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          CircularGauge(
            value: score.toDouble(),
            maxValue: 100,
            size: 130,
            strokeWidth: 12,
            label: _label(l10n),
            sublabel: l10n.outOf100,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (cloudCover != null)
                _MiniStat(
                  icon: Icons.cloud_outlined,
                  label: l10n.clouds,
                  value: '$cloudCover%',
                ),
              if (moonIllumination != null)
                _MiniStat(
                  icon: Icons.nightlight_round,
                  label: l10n.moon,
                  value: '${(moonIllumination! * 100).round()}%',
                ),
              if (bortleClass != null)
                _MiniStat(
                  icon: Icons.lightbulb_outline,
                  label: l10n.bortle,
                  value: '$bortleClass',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);

    return Column(
      children: [
        Icon(icon, color: PanelColors.textSecondary, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: font(
            color: PanelColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: font(
            color: PanelColors.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
