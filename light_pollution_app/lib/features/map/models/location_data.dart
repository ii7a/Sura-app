import 'package:latlong2/latlong.dart';

class SelectedLocation {
  const SelectedLocation({
    required this.latLng,
    this.name,
    this.region,
    this.country,
  });

  final LatLng latLng;
  final String? name;
  final String? region;
  final String? country;

  double get latitude => latLng.latitude;
  double get longitude => latLng.longitude;

  String get displayName {
    if (name != null) return name!;
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  String get subtitle {
    final parts = <String>[];
    if (region != null) parts.add(region!);
    if (country != null) parts.add(country!);
    if (parts.isNotEmpty) return parts.join(', ');
    return '${latitude.toStringAsFixed(4)}°N, ${longitude.toStringAsFixed(4)}°E';
  }
}
