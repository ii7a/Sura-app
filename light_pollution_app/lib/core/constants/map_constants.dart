import 'package:latlong2/latlong.dart';

class MapConstants {
  static const String osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  // DJLorenz / VIIRS light pollution overlay tiles
  // Tiles use 1024px size with zoomOffset -2
  static String lightPollutionTileUrl(int year) =>
      'https://djlorenz.github.io/astronomy/image_tiles/tiles$year/tile_{z}_{x}_{y}.png';

  static const int tileSize = 1024;
  static const int zoomOffset = -2;

  static const List<int> availableYears = [2016, 2020, 2022, 2023, 2024];
  static const int defaultYear = 2024;

  static const double defaultZoom = 4.0;
  static final LatLng defaultCenter = LatLng(30.0, -10.0);

  static const double defaultOverlayOpacity = 0.6;
}
