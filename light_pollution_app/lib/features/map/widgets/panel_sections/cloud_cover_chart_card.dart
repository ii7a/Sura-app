import 'package:flutter/material.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../../core/theme/panel_theme.dart';
import '../../../../core/models/weather_data.dart';

class CloudCoverChartCard extends StatelessWidget {
  const CloudCoverChartCard({super.key, required this.weather});

  final WeatherData weather;

  @override
  Widget build(BuildContext context) {
    final data = weather.hourlyCloudCover;
    final times = weather.hourlyTimes;
    if (data.isEmpty) return const SizedBox.shrink();

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
            l10n.cloudCover24h,
            style: font(
              color: PanelColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: CustomPaint(
              size: const Size(double.infinity, 80),
              painter: _CloudChartPainter(data: data, times: times),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('00:00', style: font(color: PanelColors.textMuted, fontSize: 9)),
              Text('06:00', style: font(color: PanelColors.textMuted, fontSize: 9)),
              Text('12:00', style: font(color: PanelColors.textMuted, fontSize: 9)),
              Text('18:00', style: font(color: PanelColors.textMuted, fontSize: 9)),
              Text('23:00', style: font(color: PanelColors.textMuted, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CloudChartPainter extends CustomPainter {
  _CloudChartPainter({required this.data, required this.times});

  final List<int> data;
  final List<String> times;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final barWidth = size.width / data.length - 1;
    final maxHeight = size.height;

    for (int i = 0; i < data.length; i++) {
      final value = data[i].clamp(0, 100);
      final barHeight = (value / 100.0) * maxHeight;
      final x = i * (size.width / data.length);

      // Color based on cloud cover
      Color color;
      if (value < 25) {
        color = const Color(0xFF34D399);
      } else if (value < 50) {
        color = const Color(0xFF8BC34A);
      } else if (value < 75) {
        color = const Color(0xFFFBBF24);
      } else {
        color = const Color(0xFFEF4444);
      }

      final paint = Paint()
        ..color = color.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, maxHeight - barHeight, barWidth, barHeight),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CloudChartPainter oldDelegate) => data != oldDelegate.data;
}
