import 'package:latlong2/latlong.dart';

enum DarkSkyDesignationType {
  park,
  reserve,
  sanctuary,
  community,
  urbanNightSkyPlace;

  static DarkSkyDesignationType fromJson(String value) {
    switch (value) {
      case 'park':
        return DarkSkyDesignationType.park;
      case 'reserve':
        return DarkSkyDesignationType.reserve;
      case 'sanctuary':
        return DarkSkyDesignationType.sanctuary;
      case 'community':
        return DarkSkyDesignationType.community;
      case 'urban':
        return DarkSkyDesignationType.urbanNightSkyPlace;
      default:
        return DarkSkyDesignationType.park;
    }
  }

  String get jsonValue {
    switch (this) {
      case DarkSkyDesignationType.park:
        return 'park';
      case DarkSkyDesignationType.reserve:
        return 'reserve';
      case DarkSkyDesignationType.sanctuary:
        return 'sanctuary';
      case DarkSkyDesignationType.community:
        return 'community';
      case DarkSkyDesignationType.urbanNightSkyPlace:
        return 'urban';
    }
  }
}

class DarkSkySite {
  final String id;
  final String name;
  final String? nameAr;
  final String country;
  final String? countryAr;
  final String region;
  final String? regionAr;
  final double latitude;
  final double longitude;
  final DarkSkyDesignationType designationType;
  final int? designationYear;
  final int? bortleClass;
  final String? description;
  final String? descriptionAr;
  final List<String> bestFor;

  const DarkSkySite({
    required this.id,
    required this.name,
    this.nameAr,
    required this.country,
    this.countryAr,
    required this.region,
    this.regionAr,
    required this.latitude,
    required this.longitude,
    required this.designationType,
    this.designationYear,
    this.bortleClass,
    this.description,
    this.descriptionAr,
    this.bestFor = const [],
  });

  LatLng get latLng => LatLng(latitude, longitude);

  String displayName(bool isArabic) =>
      (isArabic && nameAr != null) ? nameAr! : name;

  String displayCountry(bool isArabic) =>
      (isArabic && countryAr != null) ? countryAr! : country;

  String displayRegion(bool isArabic) =>
      (isArabic && regionAr != null) ? regionAr! : region;

  String displayDescription(bool isArabic) {
    if (isArabic && descriptionAr != null) return descriptionAr!;
    if (description != null) return description!;
    return 'A certified International Dark Sky ${designationType.jsonValue} in $region, $country.';
  }

  factory DarkSkySite.fromJson(Map<String, dynamic> json) {
    return DarkSkySite(
      id: json['id'] as String,
      name: json['name'] as String,
      nameAr: json['name_ar'] as String?,
      country: json['country'] as String,
      countryAr: json['country_ar'] as String?,
      region: json['region'] as String,
      regionAr: json['region_ar'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      designationType: DarkSkyDesignationType.fromJson(
          json['designation_type'] as String),
      designationYear: json['designation_year'] as int?,
      bortleClass: json['bortle_class'] as int?,
      description: json['description'] as String?,
      descriptionAr: json['description_ar'] as String?,
      bestFor: (json['best_for'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}
