import '../models/planet_data.dart';

class PlanetService {
  /// Returns approximate planet visibility data.
  /// Uses simplified orbital period calculations for current visibility.
  List<PlanetVisibility> getVisiblePlanets([DateTime? date]) {
    final now = date ?? DateTime.now().toUtc();
    final dayOfYear = now.difference(DateTime.utc(now.year, 1, 1)).inDays;
    final yearFraction = dayOfYear / 365.25;

    return [
      _calculatePlanet('Mercury', 87.969, -0.36, 0.387, yearFraction, now),
      _calculatePlanet('Venus', 224.701, -4.14, 0.723, yearFraction, now),
      _calculatePlanet('Mars', 686.971, -1.6, 1.524, yearFraction, now),
      _calculatePlanet('Jupiter', 4332.59, -2.2, 5.203, yearFraction, now),
      _calculatePlanet('Saturn', 10759.22, 0.46, 9.537, yearFraction, now),
    ];
  }

  PlanetVisibility _calculatePlanet(
    String name,
    double orbitalPeriod,
    double maxMagnitude,
    double distanceAU,
    double yearFraction,
    DateTime now,
  ) {
    // Simplified visibility based on elongation from sun
    final synodicPeriod = name == 'Mercury' || name == 'Venus'
        ? orbitalPeriod * 365.25 / (365.25 - orbitalPeriod).abs()
        : orbitalPeriod * 365.25 / (orbitalPeriod - 365.25).abs();

    final daysSinceEpoch = now.difference(DateTime.utc(2000, 1, 1)).inDays;
    final phase = (daysSinceEpoch % synodicPeriod) / synodicPeriod;

    // Approximate elongation (0 = conjunction, 0.5 = opposition/max elongation)
    final elongation = (phase * 360) % 360;
    final isVisible = elongation > 20 && elongation < 340;

    // Magnitude varies with distance and phase
    final magnitudeVariation = (1 - (elongation > 180 ? 360 - elongation : elongation) / 180) * 2;
    final magnitude = maxMagnitude + magnitudeVariation;

    return PlanetVisibility(
      name: name,
      isVisible: isVisible,
      magnitude: magnitude,
    );
  }
}
