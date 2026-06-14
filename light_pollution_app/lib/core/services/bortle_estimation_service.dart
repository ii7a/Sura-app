import 'dart:math';

class BortleEstimationService {
  /// Estimates Bortle class from coordinates using population density heuristics.
  ///
  /// Uses a database of 200+ cities worldwide with realistic light pollution radii.
  /// Light pollution domes extend far beyond city limits — a major metro can
  /// affect skies 150-300km away.
  int estimateBortle(double lat, double lng) {
    // Find the closest city and the max Bortle from city influence
    double minDistance = double.infinity;
    double maxBortle = 1.0;

    for (final city in _cities) {
      final distance = _haversine(lat, lng, city.lat, city.lng);

      // Track nearest city for baseline calculation
      if (distance < minDistance) minDistance = distance;

      if (distance < city.radius) {
        // Non-linear falloff: pollution strongest near center, fades at edges
        final ratio = distance / city.radius;
        final falloff = ratio * ratio;
        final bortle = city.bortle - (city.bortle - 3) * falloff;
        if (bortle > maxBortle) maxBortle = bortle;
      }
    }

    // If no city covers this point, use distance-based baseline
    if (maxBortle <= 1.0) {
      maxBortle = _baselineBortle(lat, lng, minDistance);
    }

    return maxBortle.round().clamp(1, 9);
  }

  /// Baseline Bortle based on latitude/longitude and distance to nearest city.
  /// Remote areas far from any city get very low Bortle (dark skies).
  double _baselineBortle(double lat, double lng, double nearestCityKm) {
    if (_isLikelyOcean(lat, lng)) return 1.0;

    final absLat = lat.abs();

    // Very far from any city (>500km) → pristine dark sky
    if (nearestCityKm > 500) return 1.0;

    // Far from any city (300-500km) → excellent dark sky
    if (nearestCityKm > 300) return 2.0;

    // Moderate distance (200-300km) → rural
    if (nearestCityKm > 200) return 3.0;

    // Somewhat near cities but outside their radius
    // Use latitude as a secondary factor
    if (absLat > 65) return 2.0;
    if (absLat > 30 && absLat <= 65) return 4.0;
    if (absLat > 15 && absLat <= 30) return 3.5;
    return 3.0;
  }

  bool _isLikelyOcean(double lat, double lng) {
    if (lng > -170 && lng < -100 && lat > -40 && lat < 40) return true;
    if (lng > -180 && lng < -80 && lat < -40) return true;
    if (lng > -50 && lng < -10 && lat > -30 && lat < 30) return true;
    if (lng > 40 && lng < 110 && lat < -35) return true;
    if (lat < -60) return true;
    return false;
  }

  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return r * 2 * asin(sqrt(a));
  }

  // City database: (lat, lng, bortleAtCenter, radiusKm)
  //
  // Radius = how far the light pollution dome extends. Real-world values:
  //   Mega city (10M+):     200-300 km
  //   Large city (3-10M):   120-200 km
  //   Medium city (1-3M):   80-120 km
  //   Small city (300K-1M): 50-80 km
  //   Town (100K-300K):     30-50 km
  static const _cities = <_City>[
    // ── North America ──
    _City(40.71, -74.01, 9, 250),   // New York metro
    _City(34.05, -118.24, 9, 220),  // Los Angeles
    _City(41.88, -87.63, 9, 180),   // Chicago
    _City(29.76, -95.37, 8, 160),   // Houston
    _City(33.45, -112.07, 8, 140),  // Phoenix
    _City(29.42, -98.49, 8, 110),   // San Antonio
    _City(32.72, -117.16, 8, 110),  // San Diego
    _City(32.78, -96.80, 8, 150),   // Dallas-Fort Worth
    _City(37.77, -122.42, 9, 150),  // San Francisco Bay
    _City(47.61, -122.33, 8, 120),  // Seattle
    _City(39.74, -104.99, 8, 120),  // Denver
    _City(42.36, -71.06, 9, 150),   // Boston
    _City(39.95, -75.17, 9, 150),   // Philadelphia
    _City(38.91, -77.04, 9, 160),   // Washington DC
    _City(36.17, -115.14, 8, 100),  // Las Vegas
    _City(35.23, -80.84, 8, 110),   // Charlotte
    _City(25.76, -80.19, 8, 130),   // Miami
    _City(33.75, -84.39, 8, 140),   // Atlanta
    _City(30.27, -97.74, 8, 100),   // Austin
    _City(45.50, -73.57, 8, 120),   // Montreal
    _City(43.65, -79.38, 8, 160),   // Toronto
    _City(49.28, -123.12, 8, 100),  // Vancouver
    _City(51.05, -114.07, 7, 80),   // Calgary
    _City(19.43, -99.13, 9, 200),   // Mexico City
    _City(20.67, -103.35, 8, 100),  // Guadalajara
    _City(25.67, -100.31, 8, 100),  // Monterrey
    _City(44.98, -93.27, 8, 110),   // Minneapolis
    _City(38.63, -90.20, 8, 100),   // St. Louis
    _City(39.10, -84.51, 8, 90),    // Cincinnati
    _City(28.54, -81.38, 8, 110),   // Orlando
    _City(36.16, -86.78, 8, 90),    // Nashville
    _City(27.95, -82.46, 8, 100),   // Tampa
    _City(42.33, -83.05, 8, 120),   // Detroit
    _City(35.15, -90.05, 7, 80),    // Memphis

    // ── Europe ──
    _City(51.51, -0.13, 9, 200),    // London
    _City(48.86, 2.35, 9, 180),     // Paris
    _City(52.52, 13.41, 9, 150),    // Berlin
    _City(40.42, -3.70, 9, 150),    // Madrid
    _City(41.39, 2.17, 8, 110),     // Barcelona
    _City(41.90, 12.50, 8, 120),    // Rome
    _City(45.46, 9.19, 8, 130),     // Milan
    _City(48.21, 16.37, 8, 100),    // Vienna
    _City(50.08, 14.44, 8, 100),    // Prague
    _City(47.50, 19.04, 8, 90),     // Budapest
    _City(52.23, 21.01, 8, 110),    // Warsaw
    _City(50.85, 4.35, 8, 100),     // Brussels
    _City(52.37, 4.90, 8, 120),     // Amsterdam/Randstad
    _City(59.33, 18.07, 8, 90),     // Stockholm
    _City(55.68, 12.57, 8, 80),     // Copenhagen
    _City(60.17, 24.94, 8, 80),     // Helsinki
    _City(59.91, 10.75, 8, 70),     // Oslo
    _City(53.35, -6.26, 8, 80),     // Dublin
    _City(38.72, -9.14, 8, 100),    // Lisbon
    _City(37.98, 23.73, 8, 120),    // Athens
    _City(41.01, 28.98, 9, 170),    // Istanbul
    _City(55.76, 37.62, 9, 200),    // Moscow
    _City(59.93, 30.32, 8, 120),    // St. Petersburg
    _City(50.45, 30.52, 8, 120),    // Kyiv
    _City(44.43, 26.10, 8, 100),    // Bucharest
    _City(53.48, -2.24, 8, 130),    // Manchester
    _City(45.76, 4.84, 8, 90),      // Lyon
    _City(43.30, 5.37, 8, 80),      // Marseille
    _City(51.45, 7.01, 9, 150),     // Ruhr area
    _City(50.94, 6.96, 8, 100),     // Cologne
    _City(48.14, 11.58, 8, 100),    // Munich
    _City(53.55, 10.00, 8, 90),     // Hamburg
    _City(50.11, 8.68, 8, 90),      // Frankfurt
    _City(43.71, 7.26, 8, 60),      // Nice
    _City(42.70, 23.32, 8, 80),     // Sofia
    _City(44.79, 20.46, 8, 80),     // Belgrade
    _City(45.81, 15.98, 7, 60),     // Zagreb

    // ── Middle East ──
    _City(25.20, 55.27, 9, 120),    // Dubai
    _City(24.45, 54.65, 8, 100),    // Abu Dhabi
    _City(25.29, 51.53, 8, 80),     // Doha
    _City(26.23, 50.59, 8, 70),     // Manama (Bahrain)
    _City(29.38, 47.99, 8, 100),    // Kuwait City
    _City(23.59, 58.38, 7, 60),     // Muscat
    _City(24.69, 46.72, 9, 150),    // Riyadh
    _City(21.54, 39.17, 8, 120),    // Jeddah
    _City(21.42, 39.83, 8, 80),     // Mecca
    _City(24.47, 39.61, 7, 60),     // Medina
    _City(26.43, 50.10, 8, 100),    // Dammam/Dhahran/Khobar
    _City(31.95, 35.93, 8, 80),     // Amman
    _City(33.89, 35.50, 8, 80),     // Beirut
    _City(33.51, 36.29, 8, 100),    // Damascus
    _City(36.19, 37.16, 8, 80),     // Aleppo
    _City(34.80, 36.72, 7, 50),     // Homs
    _City(33.31, 44.37, 9, 200),    // Baghdad
    _City(36.34, 43.15, 8, 100),    // Mosul
    _City(32.62, 44.02, 7, 60),     // Karbala
    _City(31.99, 44.33, 7, 60),     // Hillah
    _City(32.49, 45.83, 7, 60),     // Kut (Wasit)
    _City(30.51, 47.81, 8, 100),    // Basra
    _City(31.05, 46.26, 7, 50),     // Nasiriyah
    _City(31.84, 46.79, 7, 40),     // Amarah
    _City(34.35, 43.78, 7, 40),     // Samarra
    _City(34.61, 43.68, 7, 50),     // Tikrit
    _City(35.47, 44.39, 7, 50),     // Kirkuk
    _City(36.19, 44.01, 8, 80),     // Erbil
    _City(35.56, 45.44, 7, 60),     // Sulaymaniyah
    _City(36.41, 44.35, 7, 40),     // Duhok
    _City(32.01, 44.97, 7, 40),     // Diwaniyah
    _City(31.32, 47.16, 7, 40),     // Samawah
    _City(35.69, 51.39, 9, 200),    // Tehran
    _City(32.65, 51.68, 8, 100),    // Isfahan
    _City(38.08, 46.29, 8, 100),    // Tabriz
    _City(29.59, 52.58, 8, 80),     // Shiraz
    _City(31.32, 48.69, 8, 80),     // Ahvaz
    _City(36.30, 59.60, 8, 100),    // Mashhad
    _City(32.38, 48.44, 7, 50),     // Dezful
    _City(34.80, 48.51, 7, 50),     // Hamadan
    _City(34.09, 49.69, 7, 50),     // Arak
    _City(32.08, 34.78, 9, 100),    // Tel Aviv
    _City(31.77, 35.23, 8, 70),     // Jerusalem
    _City(32.79, 35.00, 7, 50),     // Haifa
    _City(15.35, 44.21, 7, 60),     // Sanaa
    _City(12.78, 45.04, 7, 50),     // Aden

    // ── South Asia ──
    _City(19.08, 72.88, 9, 200),    // Mumbai
    _City(28.61, 77.21, 9, 250),    // Delhi NCR
    _City(12.97, 77.59, 8, 140),    // Bangalore
    _City(22.57, 88.36, 9, 150),    // Kolkata
    _City(13.08, 80.27, 8, 120),    // Chennai
    _City(17.38, 78.49, 8, 120),    // Hyderabad
    _City(23.03, 72.59, 8, 120),    // Ahmedabad
    _City(18.52, 73.86, 8, 100),    // Pune
    _City(26.85, 80.95, 8, 100),    // Lucknow
    _City(26.92, 75.79, 8, 80),     // Jaipur
    _City(24.86, 67.01, 9, 150),    // Karachi
    _City(31.55, 74.35, 9, 140),    // Lahore
    _City(33.69, 73.04, 8, 80),     // Islamabad
    _City(25.40, 68.37, 7, 50),     // Hyderabad (Pak)
    _City(30.20, 71.47, 7, 60),     // Multan
    _City(23.81, 90.41, 9, 150),    // Dhaka
    _City(22.34, 91.82, 8, 80),     // Chittagong
    _City(6.93, 79.85, 8, 80),      // Colombo
    _City(27.72, 85.32, 8, 60),     // Kathmandu

    // ── East & Southeast Asia ──
    _City(35.68, 139.69, 9, 250),   // Tokyo
    _City(34.69, 135.50, 9, 180),   // Osaka-Kobe
    _City(35.18, 136.91, 8, 120),   // Nagoya
    _City(39.90, 116.41, 9, 250),   // Beijing
    _City(31.23, 121.47, 9, 250),   // Shanghai
    _City(23.13, 113.26, 9, 200),   // Guangzhou-Shenzhen
    _City(22.54, 114.06, 9, 120),   // Shenzhen
    _City(30.57, 104.07, 9, 150),   // Chengdu
    _City(29.56, 106.55, 8, 130),   // Chongqing
    _City(30.29, 120.15, 8, 120),   // Hangzhou
    _City(34.26, 108.94, 8, 100),   // Xi'an
    _City(22.32, 114.17, 9, 80),    // Hong Kong
    _City(37.57, 126.98, 9, 180),   // Seoul
    _City(35.18, 129.08, 8, 100),   // Busan
    _City(1.35, 103.82, 9, 70),     // Singapore
    _City(13.76, 100.50, 9, 150),   // Bangkok
    _City(21.03, 105.85, 8, 100),   // Hanoi
    _City(10.82, 106.63, 9, 130),   // Ho Chi Minh City
    _City(14.60, 120.98, 9, 130),   // Manila
    _City(-6.21, 106.85, 9, 180),   // Jakarta
    _City(3.14, 101.69, 8, 120),    // Kuala Lumpur
    _City(16.87, 96.20, 8, 80),     // Yangon
    _City(39.92, 32.85, 8, 120),    // Ankara
    _City(38.42, 27.14, 8, 80),     // Izmir
    _City(37.00, 35.32, 8, 80),     // Adana
    _City(40.19, 29.06, 8, 80),     // Bursa

    // ── Africa ──
    _City(30.04, 31.24, 9, 200),    // Cairo
    _City(31.20, 29.92, 8, 120),    // Alexandria
    _City(36.75, 3.04, 8, 100),     // Algiers
    _City(33.59, -7.61, 8, 100),    // Casablanca
    _City(36.81, 10.18, 8, 80),     // Tunis
    _City(32.90, 13.18, 7, 60),     // Tripoli
    _City(6.52, 3.38, 9, 150),      // Lagos
    _City(9.06, 7.49, 8, 100),      // Abuja
    _City(-1.29, 36.82, 8, 100),    // Nairobi
    _City(-6.79, 39.28, 8, 80),     // Dar es Salaam
    _City(9.02, 38.75, 8, 100),     // Addis Ababa
    _City(-4.32, 15.31, 8, 100),    // Kinshasa
    _City(-26.20, 28.05, 8, 140),   // Johannesburg
    _City(-33.93, 18.42, 8, 80),    // Cape Town
    _City(5.56, -0.19, 8, 80),      // Accra
    _City(14.69, -17.44, 8, 70),    // Dakar
    _City(12.64, -8.00, 7, 60),     // Bamako
    _City(0.35, 32.58, 7, 60),      // Kampala
    _City(-15.39, 28.32, 7, 50),    // Lusaka
    _City(-17.83, 31.05, 7, 50),    // Harare
    _City(12.00, 8.52, 8, 80),      // Kano

    // ── South America ──
    _City(-23.55, -46.63, 9, 220),  // São Paulo
    _City(-22.91, -43.17, 8, 150),  // Rio de Janeiro
    _City(-15.79, -47.88, 8, 110),  // Brasília
    _City(-34.60, -58.38, 9, 200),  // Buenos Aires
    _City(-33.45, -70.65, 8, 140),  // Santiago
    _City(-12.05, -77.04, 8, 120),  // Lima
    _City(4.71, -74.07, 8, 100),    // Bogotá
    _City(10.48, -66.90, 8, 100),   // Caracas
    _City(-0.18, -78.47, 8, 80),    // Quito
    _City(-2.17, -79.92, 8, 80),    // Guayaquil
    _City(-16.50, -68.15, 8, 70),   // La Paz
    _City(-25.26, -57.58, 8, 80),   // Asunción
    _City(-3.12, -60.02, 8, 80),    // Manaus
    _City(-19.92, -43.94, 8, 100),  // Belo Horizonte
    _City(-8.05, -34.87, 8, 100),   // Recife
    _City(-12.97, -38.51, 8, 100),  // Salvador

    // ── Oceania ──
    _City(-33.87, 151.21, 8, 150),  // Sydney
    _City(-37.81, 144.96, 8, 140),  // Melbourne
    _City(-27.47, 153.03, 8, 110),  // Brisbane
    _City(-31.95, 115.86, 8, 100),  // Perth
    _City(-36.85, 174.76, 8, 100),  // Auckland
    _City(-41.29, 174.78, 7, 60),   // Wellington
  ];
}

class _City {
  const _City(this.lat, this.lng, this.bortle, this.radius);
  final double lat, lng;
  final int bortle;
  final double radius; // km
}
