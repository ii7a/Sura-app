import 'package:flutter/material.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../models/analysis_result.dart';

class AnalysisResultCard extends StatelessWidget {
  const AnalysisResultCard({super.key, required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2633),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.details,
                style: font(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.bortleValue(result.bortleClass.value),
                  style: font(
                    color: const Color(0xFF4D759E),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (result.mlScore != null)
            _MetricRow(label: l10n.aiModelScore, value: '${result.mlScore}/100'),
          if (result.heuristicScore != null)
            _MetricRow(label: l10n.pixelAnalysisScore, value: '${result.heuristicScore}/100'),
          _MetricRow(label: l10n.meanBrightness, value: '${(result.metrics.meanBrightness * 100).toStringAsFixed(1)}%'),
          _MetricRow(label: l10n.brightPixels, value: '${(result.metrics.brightPixelRatio * 100).toStringAsFixed(1)}%'),
          _MetricRow(label: l10n.darkPixels, value: '${(result.metrics.darkPixelRatio * 100).toStringAsFixed(1)}%'),
          _MetricRow(label: l10n.blueRatio, value: result.metrics.blueRatio.toStringAsFixed(3)),
          _MetricRow(label: l10n.orangeRatio, value: result.metrics.orangeRatio.toStringAsFixed(3)),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: font(color: const Color(0xFF8899AA), fontSize: 13),
          ),
          Text(
            value,
            style: font(
              color: const Color(0xFFCCDDEE),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
