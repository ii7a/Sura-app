import 'package:flutter/material.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import 'package:light_pollution_app/core/l10n/bortle_l10n.dart';
import '../../../../core/theme/panel_theme.dart';
import '../../../../core/constants/bortle_scale.dart';

class LightPollutionLevelCard extends StatelessWidget {
  const LightPollutionLevelCard({super.key, required this.bortleClass});

  final int bortleClass;

  @override
  Widget build(BuildContext context) {
    final bortle = BortleClass.fromValue(bortleClass);
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
            l10n.lightPollutionBortle,
            style: font(
              color: PanelColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Bortle scale bar
          Row(
            children: List.generate(9, (i) {
              final b = BortleClass.fromValue(i + 1);
              final isSelected = i + 1 == bortleClass;
              return Expanded(
                child: Container(
                  height: isSelected ? 24 : 16,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: b.color,
                    borderRadius: BorderRadius.circular(3),
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: isSelected
                      ? Text(
                          '${i + 1}',
                          style: font(
                            color: i < 4 ? Colors.white : Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.dark, style: font(color: PanelColors.textMuted, fontSize: 9)),
              Text(l10n.bright, style: font(color: PanelColors.textMuted, fontSize: 9)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.classLabel(bortleClass, bortle.localizedName(l10n)),
            style: font(
              color: PanelColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            bortle.localizedDescription(l10n),
            style: font(
              color: PanelColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
