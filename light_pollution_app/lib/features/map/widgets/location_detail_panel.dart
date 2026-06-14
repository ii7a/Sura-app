import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/theme/panel_theme.dart';
import '../providers/explore_provider.dart';
import 'panel_sections/search_location_bar.dart';
import 'panel_sections/location_card.dart';
import 'panel_sections/stargazing_score_card.dart';
import 'panel_sections/light_pollution_level_card.dart';
import 'panel_sections/weather_now_card.dart';
import 'panel_sections/cloud_cover_chart_card.dart';
import 'panel_sections/sun_twilight_card.dart';
import 'panel_sections/moon_phase_card.dart';
import 'panel_sections/visible_planets_card.dart';
import 'panel_sections/map_legend_card.dart';

class LocationDetailPanel extends ConsumerWidget {
  const LocationDetailPanel({super.key, this.onSearchSelected, this.scrollController});

  final void Function(double lat, double lng)? onSearchSelected;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(exploreProvider);
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);

    // Use a single CustomScrollView so the DraggableScrollableSheet's
    // scrollController controls everything — swiping down at the top
    // collapses the sheet instead of fighting with a nested ListView.
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        // Drag handle + header (non-scrollable pinned area)
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
                  l10n.explore,
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
        // Scrollable content
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              SearchLocationBar(
                onLocationSelected: (loc) {
                  ref.read(exploreProvider.notifier).selectLocation(loc.latLng);
                  onSearchSelected?.call(loc.latitude, loc.longitude);
                },
              ),
              const SizedBox(height: PanelStyle.sectionSpacing),

              if (state.status == ExploreStatus.idle)
                _IdlePrompt()
              else ...[
                // Location info
                if (state.selectedLocation != null)
                  LocationCard(location: state.selectedLocation!),
                const SizedBox(height: PanelStyle.sectionSpacing),

                // Loading state
                if (state.status == ExploreStatus.loading)
                  _LoadingSkeleton()
                else ...[
                  // Stargazing Score
                  if (state.stargazingScore != null)
                    StargazingScoreCard(
                      score: state.stargazingScore!,
                      cloudCover: state.weather?.cloudCover,
                      moonIllumination: state.moonData?.illumination,
                      bortleClass: state.bortleClass,
                    ),
                  const SizedBox(height: PanelStyle.sectionSpacing),

                  // Bortle Level
                  if (state.bortleClass != null)
                    LightPollutionLevelCard(bortleClass: state.bortleClass!),
                  const SizedBox(height: PanelStyle.sectionSpacing),

                  // Weather
                  if (state.weather != null) ...[
                    WeatherNowCard(weather: state.weather!),
                    const SizedBox(height: PanelStyle.sectionSpacing),
                    CloudCoverChartCard(weather: state.weather!),
                    const SizedBox(height: PanelStyle.sectionSpacing),
                  ],

                  // Sun & Twilight
                  if (state.sunData != null)
                    SunTwilightCard(sunData: state.sunData!),
                  const SizedBox(height: PanelStyle.sectionSpacing),

                  // Moon Phase
                  if (state.moonData != null)
                    MoonPhaseCard(moonData: state.moonData!),
                  const SizedBox(height: PanelStyle.sectionSpacing),

                  // Visible Planets
                  if (state.planets != null)
                    VisiblePlanetsCard(planets: state.planets!),
                  const SizedBox(height: PanelStyle.sectionSpacing),

                  // Map Legend
                  const MapLegendCard(),
                  const SizedBox(height: PanelStyle.sectionSpacing),

                  // Error message
                  if (state.status == ExploreStatus.error && state.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: PanelColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, color: PanelColors.warning, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.someDataFailed,
                              style: font(
                                color: PanelColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

class _IdlePrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(Icons.touch_app_outlined, color: PanelColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(
            l10n.tapLocation,
            style: font(
              color: PanelColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.orSearchCity,
            style: font(
              color: PanelColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(4, (i) => Padding(
        padding: const EdgeInsets.only(bottom: PanelStyle.sectionSpacing),
        child: Container(
          width: double.infinity,
          height: 80 + (i * 20),
          decoration: BoxDecoration(
            color: PanelColors.cardBg,
            borderRadius: BorderRadius.circular(PanelStyle.cardRadius),
          ),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: PanelColors.accent,
              ),
            ),
          ),
        ),
      )),
    );
  }
}
