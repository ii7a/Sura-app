import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/constants/map_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/panel_theme.dart';
import '../models/dark_sky_site.dart';
import '../providers/map_provider.dart';
import '../providers/explore_provider.dart';
import '../providers/dark_sky_sites_provider.dart';
import '../widgets/light_pollution_legend.dart';
import '../widgets/map_controls.dart';
import '../widgets/location_detail_panel.dart';
import '../widgets/dark_sky_site_detail_sheet.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final MapController _mapController = MapController();
  bool _showLegend = false;
  LatLng? _markerPosition;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  bool _sheetOpen = false;
  DarkSkySite? _selectedDarkSkySite;

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(_onSheetChanged);
  }

  @override
  void dispose() {
    _sheetController.removeListener(_onSheetChanged);
    _sheetController.dispose();
    super.dispose();
  }

  void _onSheetChanged() {
    if (_sheetController.isAttached && _sheetController.size <= 0.05) {
      setState(() {
        _sheetOpen = false;
        _markerPosition = null;
        _selectedDarkSkySite = null;
      });
    }
  }

  void _onMapTap(LatLng point) {
    setState(() {
      _markerPosition = point;
      _selectedDarkSkySite = null;
    });
    ref.read(exploreProvider.notifier).selectLocation(point);
    _openSheet();
  }

  void _moveToLocation(double lat, double lng) {
    final point = LatLng(lat, lng);
    setState(() => _markerPosition = point);
    _mapController.move(point, 8);
  }

  void _openSheet() {
    if (!_sheetOpen) {
      setState(() => _sheetOpen = true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sheetController.isAttached) {
        _sheetController.animateTo(
          0.45,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onDarkSkyPinTap(DarkSkySite site) {
    setState(() {
      _selectedDarkSkySite = site;
      _markerPosition = site.latLng;
    });
    _mapController.move(site.latLng, _mapController.camera.zoom.clamp(5, 10));
    _openSheet();
  }

  void _onExploreLocation() {
    if (_selectedDarkSkySite == null) return;
    final latLng = _selectedDarkSkySite!.latLng;
    setState(() => _selectedDarkSkySite = null);
    ref.read(exploreProvider.notifier).selectLocation(latLng);
  }

  void _toggleSheet() {
    if (_sheetOpen &&
        _sheetController.isAttached &&
        _sheetController.size > 0.05) {
      _sheetController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _openSheet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);
    final visibleSites = ref.watch(visibleDarkSkySitesProvider);
    final countryCounts = ref.watch(darkSkySiteCountByCountryProvider);
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);
    final currentZoom = mapState.currentZoom;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.icon(context)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.explore,
          style: font(
            color: AppColors.icon(context),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showLegend ? Icons.info : Icons.info_outline,
              color: AppColors.icon(context),
            ),
            onPressed: () => setState(() => _showLegend = !_showLegend),
            tooltip: l10n.toggleLegend,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Full-screen map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: MapConstants.defaultCenter,
              initialZoom: MapConstants.defaultZoom,
              minZoom: 2,
              maxZoom: 10,
              onTap: (tapPosition, point) => _onMapTap(point),
              onPositionChanged: (camera, hasGesture) {
                ref.read(mapProvider.notifier).setZoom(camera.zoom);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: MapConstants.osmTileUrl,
                userAgentPackageName: 'com.sura.light_pollution_app',
              ),
              if (mapState.showOverlay)
                Opacity(
                  opacity: mapState.overlayOpacity,
                  child: TileLayer(
                    urlTemplate: MapConstants.lightPollutionTileUrl(
                        mapState.selectedYear),
                    userAgentPackageName: 'com.sura.light_pollution_app',
                    tileSize: MapConstants.tileSize.toDouble(),
                    zoomOffset: MapConstants.zoomOffset.toDouble(),
                    maxZoom: 8,
                    tileProvider: NetworkTileProvider(silenceExceptions: true),
                    errorTileCallback: (tile, error, stackTrace) {},
                  ),
                ),
              // Dark sky site pins
              MarkerLayer(
                markers: visibleSites
                    .map(
                      (site) => Marker(
                        point: site.latLng,
                        width: 36,
                        height: 36,
                        child: GestureDetector(
                          onTap: () => _onDarkSkyPinTap(site),
                          child: _DarkSkyMarkerIcon(
                            site: site,
                            showCount: currentZoom < 3,
                            count: countryCounts[site.country] ?? 1,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              // User tap marker
              if (_markerPosition != null && _selectedDarkSkySite == null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _markerPosition!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: Color(0xFF6C63FF),
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Map controls (top right)
          Positioned(
            top: 8,
            right: 8,
            child: MapControls(),
          ),

          // Zoom controls (+ / -)
          Positioned(
            bottom: 100,
            left: 12,
            child: Column(
              children: [
                _ZoomButton(
                  icon: Icons.add,
                  onPressed: () {
                    final zoom = _mapController.camera.zoom + 1;
                    _mapController.move(
                      _mapController.camera.center,
                      zoom.clamp(2, 10),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _ZoomButton(
                  icon: Icons.remove,
                  onPressed: () {
                    final zoom = _mapController.camera.zoom - 1;
                    _mapController.move(
                      _mapController.camera.center,
                      zoom.clamp(2, 10),
                    );
                  },
                ),
              ],
            ),
          ),

          // Legend (bottom left)
          if (_showLegend)
            const Positioned(
              bottom: 8,
              left: 8,
              child: LightPollutionLegend(),
            ),

          // Floating button to open/close panel
          Positioned(
            right: 16,
            bottom: _sheetOpen
                ? 16 + (MediaQuery.of(context).size.height * 0.12)
                : 16,
            child: FloatingActionButton.small(
              heroTag: 'explore_panel_btn',
              backgroundColor: PanelColors.background,
              onPressed: _toggleSheet,
              child: Icon(
                _sheetOpen ? Icons.keyboard_arrow_down : Icons.explore,
                color: PanelColors.accent,
              ),
            ),
          ),

          // Draggable bottom sheet
          if (_sheetOpen)
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.12,
              minChildSize: 0.0,
              maxChildSize: 0.92,
              snap: true,
              snapSizes: const [0.0, 0.12, 0.45, 0.92],
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: PanelColors.background,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: _selectedDarkSkySite != null
                      ? DarkSkySiteDetailSheet(
                          site: _selectedDarkSkySite!,
                          scrollController: scrollController,
                          onExploreLocation: _onExploreLocation,
                        )
                      : LocationDetailPanel(
                          onSearchSelected: _moveToLocation,
                          scrollController: scrollController,
                        ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _DarkSkyMarkerIcon extends StatelessWidget {
  const _DarkSkyMarkerIcon({
    required this.site,
    this.showCount = false,
    this.count = 1,
  });

  final DarkSkySite site;
  final bool showCount;
  final int count;

  Color get _color {
    switch (site.designationType) {
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _color.withValues(alpha: 0.9),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: const Center(
            child: Icon(
              Icons.star,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        if (showCount && count > 1)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: PanelColors.accent,
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shape: const CircleBorder(),
      color: AppColors.white,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.navy, size: 24),
        ),
      ),
    );
  }
}
