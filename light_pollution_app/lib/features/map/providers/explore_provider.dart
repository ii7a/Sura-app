import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/weather_data.dart';
import '../../../core/models/sun_data.dart';
import '../../../core/models/moon_data.dart';
import '../../../core/models/planet_data.dart';
import '../../../core/services/weather_service.dart';
import '../../../core/services/sun_service.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/services/moon_service.dart';
import '../../../core/services/planet_service.dart';
import '../../../core/services/bortle_estimation_service.dart';
import '../models/location_data.dart';

enum ExploreStatus { idle, loading, loaded, error }

class ExploreState {
  const ExploreState({
    this.status = ExploreStatus.idle,
    this.selectedLocation,
    this.weather,
    this.sunData,
    this.moonData,
    this.planets,
    this.bortleClass,
    this.stargazingScore,
    this.errorMessage,
  });

  final ExploreStatus status;
  final SelectedLocation? selectedLocation;
  final WeatherData? weather;
  final SunData? sunData;
  final MoonData? moonData;
  final List<PlanetVisibility>? planets;
  final int? bortleClass;
  final int? stargazingScore;
  final String? errorMessage;

  ExploreState copyWith({
    ExploreStatus? status,
    SelectedLocation? selectedLocation,
    WeatherData? weather,
    SunData? sunData,
    MoonData? moonData,
    List<PlanetVisibility>? planets,
    int? bortleClass,
    int? stargazingScore,
    String? errorMessage,
  }) {
    return ExploreState(
      status: status ?? this.status,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      weather: weather ?? this.weather,
      sunData: sunData ?? this.sunData,
      moonData: moonData ?? this.moonData,
      planets: planets ?? this.planets,
      bortleClass: bortleClass ?? this.bortleClass,
      stargazingScore: stargazingScore ?? this.stargazingScore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ExploreNotifier extends StateNotifier<ExploreState> {
  ExploreNotifier() : super(const ExploreState());

  final _weatherService = WeatherService();
  final _sunService = SunService();
  final _geocodingService = GeocodingService();
  final _moonService = MoonService();
  final _planetService = PlanetService();
  final _bortleService = BortleEstimationService();

  DateTime? _lastTapTime;

  Future<void> selectLocation(LatLng latLng) async {
    // Debounce rapid taps
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!).inMilliseconds < 500) {
      return;
    }
    _lastTapTime = now;

    state = ExploreState(
      status: ExploreStatus.loading,
      selectedLocation: SelectedLocation(latLng: latLng),
    );

    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        _geocodingService.reverseGeocode(latLng),
        _weatherService.getWeather(latLng.latitude, latLng.longitude),
        _sunService.getSunData(latLng.latitude, latLng.longitude),
        Future.value(_moonService.getMoonPhase()),
        Future.value(_planetService.getVisiblePlanets()),
        Future.value(_bortleService.estimateBortle(latLng.latitude, latLng.longitude)),
      ]);

      final location = results[0] as SelectedLocation;
      final weather = results[1] as WeatherData;
      final sunData = results[2] as SunData;
      final moonData = results[3] as MoonData;
      final planets = results[4] as List<PlanetVisibility>;
      final bortle = results[5] as int;

      // Calculate stargazing score
      final score = _calculateStargazingScore(weather, moonData, bortle);

      state = ExploreState(
        status: ExploreStatus.loaded,
        selectedLocation: location,
        weather: weather,
        sunData: sunData,
        moonData: moonData,
        planets: planets,
        bortleClass: bortle,
        stargazingScore: score,
      );
    } catch (e) {
      // Still show what we can compute locally
      final moonData = _moonService.getMoonPhase();
      final planets = _planetService.getVisiblePlanets();
      final bortle = _bortleService.estimateBortle(latLng.latitude, latLng.longitude);

      state = ExploreState(
        status: ExploreStatus.error,
        selectedLocation: SelectedLocation(latLng: latLng),
        moonData: moonData,
        planets: planets,
        bortleClass: bortle,
        errorMessage: e.toString(),
      );
    }
  }

  Future<List<SelectedLocation>> searchPlaces(String query) async {
    return _geocodingService.searchPlaces(query);
  }

  int _calculateStargazingScore(WeatherData weather, MoonData moon, int bortle) {
    // Cloud cover: 0% = 30pts, 100% = 0pts
    final cloudScore = ((100 - weather.cloudCover) / 100.0 * 30).round();

    // Moon: new moon = 25pts, full moon = 0pts
    final moonScore = ((1 - moon.illumination) * 25).round();

    // Bortle: class 1 = 30pts, class 9 = 0pts
    final bortleScore = ((9 - bortle) / 8.0 * 30).round();

    // Humidity: <50% = 15pts, >90% = 0pts
    final humidityScore = weather.humidity < 50
        ? 15
        : weather.humidity > 90
            ? 0
            : ((90 - weather.humidity) / 40.0 * 15).round();

    return (cloudScore + moonScore + bortleScore + humidityScore).clamp(0, 100);
  }

  void clear() {
    state = const ExploreState();
  }
}

final exploreProvider =
    StateNotifierProvider<ExploreNotifier, ExploreState>((ref) {
  return ExploreNotifier();
});
