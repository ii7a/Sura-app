class WeatherData {
  const WeatherData({
    required this.temperature,
    required this.humidity,
    required this.cloudCover,
    required this.windSpeed,
    required this.weatherCode,
    required this.hourlyCloudCover,
    required this.hourlyTimes,
    this.visibility,
  });

  final double temperature;
  final int humidity;
  final int cloudCover;
  final double windSpeed;
  final int weatherCode;
  final List<int> hourlyCloudCover;
  final List<String> hourlyTimes;
  final double? visibility;

  String get weatherDescription {
    switch (weatherCode) {
      case 0:
        return 'Clear sky';
      case 1:
        return 'Mainly clear';
      case 2:
        return 'Partly cloudy';
      case 3:
        return 'Overcast';
      case 45:
      case 48:
        return 'Foggy';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rain';
      case 71:
      case 73:
      case 75:
        return 'Snow';
      case 80:
      case 81:
      case 82:
        return 'Rain showers';
      case 95:
        return 'Thunderstorm';
      default:
        return 'Unknown';
    }
  }

  String get weatherIcon {
    if (cloudCover < 20) return '☀️';
    if (cloudCover < 50) return '⛅';
    if (cloudCover < 80) return '🌥️';
    if (weatherCode >= 61) return '🌧️';
    if (weatherCode >= 71) return '🌨️';
    if (weatherCode >= 95) return '⛈️';
    return '☁️';
  }
}
