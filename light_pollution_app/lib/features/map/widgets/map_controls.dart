import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import '../../../core/constants/map_constants.dart';
import '../providers/map_provider.dart';

class MapControls extends ConsumerWidget {
  const MapControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapState = ref.watch(mapProvider);
    final l10n = AppLocalizations.of(context)!;
    const textColor = Colors.white;

    return Card(
      margin: const EdgeInsets.all(8),
      color: const Color(0xDD1A2530),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.lightPollutionOverlay,
                  style: const TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: mapState.showOverlay,
                  onChanged: (_) => ref.read(mapProvider.notifier).toggleOverlay(),
                ),
              ],
            ),
            if (mapState.showOverlay) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.opacity, style: const TextStyle(color: textColor, fontSize: 14)),
                  SizedBox(
                    width: 150,
                    child: Slider(
                      value: mapState.overlayOpacity,
                      min: 0.1,
                      max: 1.0,
                      onChanged: (v) => ref.read(mapProvider.notifier).setOverlayOpacity(v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.yearLabel, style: const TextStyle(color: textColor, fontSize: 14)),
                  DropdownButton<int>(
                    value: mapState.selectedYear,
                    isDense: true,
                    dropdownColor: const Color(0xFF1A2530),
                    style: const TextStyle(color: textColor, fontSize: 14),
                    items: MapConstants.availableYears
                        .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                        .toList(),
                    onChanged: (year) {
                      if (year != null) {
                        ref.read(mapProvider.notifier).setYear(year);
                      }
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
