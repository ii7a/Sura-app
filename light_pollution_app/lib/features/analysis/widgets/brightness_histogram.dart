import 'dart:math';
import 'package:flutter/material.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';

class BrightnessHistogram extends StatelessWidget {
  const BrightnessHistogram({super.key, required this.histogram});

  final List<int> histogram;

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
          Text(
            l10n.brightnessDistribution,
            style: font(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: CustomPaint(
              size: const Size(double.infinity, 100),
              painter: _HistogramPainter(histogram),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.dark, style: font(color: const Color(0xFF8899AA), fontSize: 11)),
              Text(l10n.bright, style: font(color: const Color(0xFF8899AA), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistogramPainter extends CustomPainter {
  _HistogramPainter(this.histogram);

  final List<int> histogram;

  @override
  void paint(Canvas canvas, Size size) {
    if (histogram.isEmpty) return;

    final maxVal = histogram.reduce(max).toDouble();
    if (maxVal == 0) return;

    const binCount = 64;
    final binsPerGroup = histogram.length ~/ binCount;
    final grouped = <int>[];
    for (int i = 0; i < binCount; i++) {
      int sum = 0;
      for (int j = 0; j < binsPerGroup; j++) {
        final idx = i * binsPerGroup + j;
        if (idx < histogram.length) sum += histogram[idx];
      }
      grouped.add(sum);
    }

    final groupMax = grouped.reduce(max).toDouble();
    if (groupMax == 0) return;

    final barWidth = size.width / binCount;

    for (int i = 0; i < binCount; i++) {
      final ratio = grouped[i] / groupMax;
      final barHeight = ratio * size.height;
      final t = i / binCount;

      final color = Color.lerp(
        AppColors.navy,
        const Color(0xFF4D759E),
        t,
      )!;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            i * barWidth,
            size.height - barHeight,
            barWidth - 1,
            barHeight,
          ),
          const Radius.circular(1),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
