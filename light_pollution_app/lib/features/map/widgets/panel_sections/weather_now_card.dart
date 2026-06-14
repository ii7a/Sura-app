import 'package:flutter/material.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../../core/theme/panel_theme.dart';
import '../../../../core/models/weather_data.dart';

class WeatherNowCard extends StatelessWidget {
  const WeatherNowCard({super.key, required this.weather});

  final WeatherData weather;

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
            l10n.currentWeather,
            style: font(
              color: PanelColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                weather.weatherIcon,
                style: const TextStyle(fontSize: 36),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weather.temperature.round()}\u00B0C',
                    style: font(
                      color: PanelColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    weather.weatherDescription,
                    style: font(
                      color: PanelColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _WeatherDetail(icon: Icons.cloud_outlined, label: l10n.cloudCover, value: '${weather.cloudCover}%'),
              _WeatherDetail(icon: Icons.water_drop_outlined, label: l10n.humidity, value: '${weather.humidity}%'),
              _WeatherDetail(icon: Icons.air, label: l10n.wind, value: '${weather.windSpeed.round()} km/h'),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeatherDetail extends StatelessWidget {
  const _WeatherDetail({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);

    return Column(
      children: [
        Icon(icon, color: PanelColors.textMuted, size: 16),
        const SizedBox(height: 4),
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
    );
  }
}
