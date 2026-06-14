class SunData {
  const SunData({
    required this.sunrise,
    required this.sunset,
    required this.solarNoon,
    required this.dayLength,
    this.civilTwilightBegin,
    this.civilTwilightEnd,
    this.nauticalTwilightBegin,
    this.nauticalTwilightEnd,
    this.astronomicalTwilightBegin,
    this.astronomicalTwilightEnd,
  });

  final DateTime sunrise;
  final DateTime sunset;
  final DateTime solarNoon;
  final Duration dayLength;
  final DateTime? civilTwilightBegin;
  final DateTime? civilTwilightEnd;
  final DateTime? nauticalTwilightBegin;
  final DateTime? nauticalTwilightEnd;
  final DateTime? astronomicalTwilightBegin;
  final DateTime? astronomicalTwilightEnd;

  Duration get nightLength => Duration(hours: 24) - dayLength;

  double get dayProgressPercent {
    final now = DateTime.now().toUtc();
    if (now.isBefore(sunrise)) return 0;
    if (now.isAfter(sunset)) return 100;
    final elapsed = now.difference(sunrise).inMinutes;
    final total = sunset.difference(sunrise).inMinutes;
    if (total == 0) return 0;
    return (elapsed / total * 100).clamp(0, 100);
  }
}
