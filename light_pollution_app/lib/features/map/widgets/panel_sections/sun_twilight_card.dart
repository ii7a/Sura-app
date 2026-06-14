import 'package:flutter/material.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../../core/theme/panel_theme.dart';
import '../../../../core/models/sun_data.dart';

class SunTwilightCard extends StatelessWidget {
  const SunTwilightCard({super.key, required this.sunData});

  final SunData sunData;

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '${h}h ${m}m';
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
            l10n.sunTwilight,
            style: font(
              color: PanelColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Day/night progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: sunData.dayProgressPercent / 100,
              backgroundColor: const Color(0xFF1a1a3e),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.dayDuration(_formatDuration(sunData.dayLength)),
                style: font(color: PanelColors.textSecondary, fontSize: 11),
              ),
              Text(
                l10n.nightDuration(_formatDuration(sunData.nightLength)),
                style: font(color: PanelColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _TimeRow(icon: Icons.wb_sunny, label: l10n.sunrise, time: _formatTime(sunData.sunrise), color: const Color(0xFFFBBF24)),
          _TimeRow(icon: Icons.wb_sunny_outlined, label: l10n.solarNoon, time: _formatTime(sunData.solarNoon), color: const Color(0xFFFF9800)),
          _TimeRow(icon: Icons.nightlight, label: l10n.sunset, time: _formatTime(sunData.sunset), color: const Color(0xFFFF5722)),
          if (sunData.civilTwilightEnd != null)
            _TimeRow(icon: Icons.blur_on, label: l10n.civilTwilightEnd, time: _formatTime(sunData.civilTwilightEnd!), color: const Color(0xFF9C27B0)),
          if (sunData.nauticalTwilightEnd != null)
            _TimeRow(icon: Icons.blur_circular, label: l10n.nauticalTwilightEnd, time: _formatTime(sunData.nauticalTwilightEnd!), color: const Color(0xFF3F51B5)),
          if (sunData.astronomicalTwilightEnd != null)
            _TimeRow(icon: Icons.star, label: l10n.astroTwilightEnd, time: _formatTime(sunData.astronomicalTwilightEnd!), color: const Color(0xFF1A237E)),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.icon, required this.label, required this.time, required this.color});

  final IconData icon;
  final String label;
  final String time;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: font(color: PanelColors.textSecondary, fontSize: 11),
            ),
          ),
          Text(
            time,
            style: font(
              color: PanelColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
