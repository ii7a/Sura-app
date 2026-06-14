import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sun_data.dart';

class SunService {
  static const _baseUrl = 'https://api.sunrise-sunset.org/json';

  Future<SunData> getSunData(double lat, double lng) async {
    final uri = Uri.parse(
      '$_baseUrl?lat=$lat&lng=$lng&formatted=0',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Sun API error: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    if (data['status'] != 'OK') {
      throw Exception('Sun API returned: ${data['status']}');
    }

    final results = data['results'];

    DateTime? tryParse(String? val) {
      if (val == null || val.isEmpty) return null;
      return DateTime.tryParse(val);
    }

    final sunrise = DateTime.parse(results['sunrise']);
    final sunset = DateTime.parse(results['sunset']);
    final solarNoon = DateTime.parse(results['solar_noon']);
    final dayLengthSecs = results['day_length'] as int;

    return SunData(
      sunrise: sunrise,
      sunset: sunset,
      solarNoon: solarNoon,
      dayLength: Duration(seconds: dayLengthSecs),
      civilTwilightBegin: tryParse(results['civil_twilight_begin']),
      civilTwilightEnd: tryParse(results['civil_twilight_end']),
      nauticalTwilightBegin: tryParse(results['nautical_twilight_begin']),
      nauticalTwilightEnd: tryParse(results['nautical_twilight_end']),
      astronomicalTwilightBegin: tryParse(results['astronomical_twilight_begin']),
      astronomicalTwilightEnd: tryParse(results['astronomical_twilight_end']),
    );
  }
}
