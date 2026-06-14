import 'package:flutter/material.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/theme/panel_theme.dart';
import '../models/dark_sky_site.dart';
import 'panel_sections/light_pollution_level_card.dart';

class DarkSkySiteDetailSheet extends StatelessWidget {
  const DarkSkySiteDetailSheet({
    super.key,
    required this.site,
    required this.scrollController,
    this.onExploreLocation,
  });

  final DarkSkySite site;
  final ScrollController scrollController;
  final VoidCallback? onExploreLocation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        // Drag handle + title
        SliverToBoxAdapter(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.only(top: 10, bottom: 6),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: PanelColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  l10n.darkSkySite,
                  style: font(
                    color: PanelColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Content
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Header card
              _HeaderCard(site: site, isArabic: isArabic),
              const SizedBox(height: PanelStyle.sectionSpacing),

              // Stats row
              _StatsRow(site: site, l10n: l10n),
              const SizedBox(height: PanelStyle.sectionSpacing),

              // Bortle visual (if available)
              if (site.bortleClass != null) ...[
                LightPollutionLevelCard(bortleClass: site.bortleClass!),
                const SizedBox(height: PanelStyle.sectionSpacing),
              ],

              // Description
              _DescriptionCard(site: site, isArabic: isArabic),
              const SizedBox(height: PanelStyle.sectionSpacing),

              // Best For tags
              if (site.bestFor.isNotEmpty) ...[
                _BestForCard(site: site, l10n: l10n),
                const SizedBox(height: PanelStyle.sectionSpacing),
              ],

              // Action buttons
              _ActionButtons(
                l10n: l10n,
                onExploreLocation: onExploreLocation,
              ),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.site, required this.isArabic});

  final DarkSkySite site;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PanelStyle.cardPadding),
      decoration: PanelStyle.cardDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _designationColor(site.designationType).withValues(alpha: 0.15),
            ),
            child: Icon(
              Icons.star,
              color: _designationColor(site.designationType),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  site.displayName(isArabic),
                  style: font(
                    color: PanelColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                _DesignationBadge(
                  type: site.designationType,
                  l10n: l10n,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: PanelColors.textSecondary, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${site.displayRegion(isArabic)}, ${site.displayCountry(isArabic)}',
                        style: font(
                          color: PanelColors.textSecondary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesignationBadge extends StatelessWidget {
  const _DesignationBadge({required this.type, required this.l10n});

  final DarkSkyDesignationType type;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);
    final color = _designationColor(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _designationLabel(type, l10n),
        style: font(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.site, required this.l10n});

  final DarkSkySite site;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PanelStyle.cardPadding),
      decoration: PanelStyle.cardDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MiniStat(
            icon: Icons.calendar_today,
            label: l10n.designatedYear,
            value: site.designationYear?.toString() ?? '—',
          ),
          _MiniStat(
            icon: Icons.my_location,
            label: l10n.coordinates,
            value: '${site.latitude.toStringAsFixed(1)}°, ${site.longitude.toStringAsFixed(1)}°',
          ),
          _MiniStat(
            icon: Icons.lightbulb_outline,
            label: l10n.bortle,
            value: site.bortleClass?.toString() ?? '—',
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.icon, required this.label, required this.value});

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

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.site, required this.isArabic});

  final DarkSkySite site;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PanelStyle.cardPadding),
      decoration: PanelStyle.cardDecoration,
      child: Text(
        site.displayDescription(isArabic),
        style: font(
          color: PanelColors.textSecondary,
          fontSize: 12,
          height: 1.5,
        ),
      ),
    );
  }
}

class _BestForCard extends StatelessWidget {
  const _BestForCard({required this.site, required this.l10n});

  final DarkSkySite site;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PanelStyle.cardPadding),
      decoration: PanelStyle.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.bestFor,
            style: font(
              color: PanelColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: site.bestFor.map((tag) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: PanelColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_tagIcon(tag),
                        color: PanelColors.accent, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      tag,
                      style: font(
                        color: PanelColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _tagIcon(String tag) {
    switch (tag.toLowerCase()) {
      case 'milky way':
        return Icons.auto_awesome;
      case 'astrophotography':
        return Icons.camera_alt_outlined;
      case 'naked eye':
        return Icons.visibility_outlined;
      case 'aurora':
        return Icons.waves;
      case 'education':
        return Icons.school_outlined;
      case 'heritage':
        return Icons.account_balance_outlined;
      case 'urban stargazing':
        return Icons.location_city_outlined;
      default:
        return Icons.star_outline;
    }
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.l10n,
    this.onExploreLocation,
  });

  final AppLocalizations l10n;
  final VoidCallback? onExploreLocation;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onExploreLocation,
        icon: const Icon(Icons.explore_outlined, size: 18),
        label: Text(l10n.exploreLocation),
        style: OutlinedButton.styleFrom(
          foregroundColor: PanelColors.accent,
          side: const BorderSide(color: PanelColors.accent),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: font(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

Color _designationColor(DarkSkyDesignationType type) {
  switch (type) {
    case DarkSkyDesignationType.park:
      return PanelColors.success;
    case DarkSkyDesignationType.reserve:
      return PanelColors.accent;
    case DarkSkyDesignationType.sanctuary:
      return PanelColors.warning;
    case DarkSkyDesignationType.community:
      return const Color(0xFF60A5FA);
    case DarkSkyDesignationType.urbanNightSkyPlace:
      return const Color(0xFFE879F9);
  }
}

String _designationLabel(DarkSkyDesignationType type, AppLocalizations l10n) {
  switch (type) {
    case DarkSkyDesignationType.park:
      return l10n.darkSkyPark;
    case DarkSkyDesignationType.reserve:
      return l10n.darkSkyReserve;
    case DarkSkyDesignationType.sanctuary:
      return l10n.darkSkySanctuary;
    case DarkSkyDesignationType.community:
      return l10n.darkSkyCommunity;
    case DarkSkyDesignationType.urbanNightSkyPlace:
      return l10n.darkSkyUrban;
  }
}
