import 'package:flutter/material.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/l10n/bortle_l10n.dart';
import '../../../core/constants/bortle_scale.dart';

class LightPollutionLegend extends StatelessWidget {
  const LightPollutionLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.all(8),
      color: const Color(0xDD1A2530),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.bortleScale,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...BortleClass.values.map((bortle) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: bortle.color,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.white24, width: 0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${bortle.value} - ${bortle.localizedName(l10n)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
