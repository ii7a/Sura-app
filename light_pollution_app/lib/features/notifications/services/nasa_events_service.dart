import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/cosmic_event.dart';
import '../models/cosmic_event_types.dart';

/// Fetches cosmic events from three sources and merges them into one list:
///
///   1. NASA NeoWs  – near-Earth asteroid approaches for the next 7 days
///   2. NASA APOD   – today's astronomy picture (surfaced as a "notable" event)
///   3. Static JSON – eclipses, meteor showers, conjunctions we preload in the
///                    app (NASA doesn't publish these as an API)
///
/// The admin page calls [fetchAll] and shows the merged result; the admin
/// can then choose which events to broadcast to users.
class NasaEventsService {
  NasaEventsService({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;

  /// Generated at https://api.nasa.gov — the rate limit on this key is
  /// 1000 requests/hour which is plenty for admin-driven fetches.
  static const _apiKey = 'CzoXaW4jqpE0q3thuObotzOtMjn45GFxpLBSwF8P';

  Future<List<CosmicEvent>> fetchAll() async {
    final results = await Future.wait([
      _fetchStatic(),
      _fetchNeoWs().catchError((_) => <CosmicEvent>[]),
      _fetchApod().catchError((_) => <CosmicEvent>[]),
    ]);
    final merged = <CosmicEvent>[
      ...results[0],
      ...results[1],
      ...results[2],
    ];
    // Only show upcoming events — past events pollute the admin view.
    final now = DateTime.now().subtract(const Duration(hours: 6));
    merged.removeWhere((e) => e.date.isBefore(now));
    merged.sort((a, b) => a.date.compareTo(b.date));
    return merged;
  }

  /// Loads our curated JSON of known cosmic events (eclipses, meteor showers,
  /// supermoons). Bundled with the app so it works offline and doesn't need
  /// a remote fetch for well-known annual phenomena.
  Future<List<CosmicEvent>> _fetchStatic() async {
    try {
      final raw = await rootBundle.loadString('assets/data/cosmic_events_2026.json');
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((m) => CosmicEvent.fromStatic(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <CosmicEvent>[];
    }
  }

  /// NASA Near Earth Object Web Service. Returns asteroids & comets passing
  /// close to Earth in the next 7 days. We filter to "potentially hazardous"
  /// or very-close approaches so the admin sees only notable ones — the raw
  /// feed has dozens of barely-noticeable objects per day.
  Future<List<CosmicEvent>> _fetchNeoWs() async {
    final start = DateTime.now().toUtc();
    final end = start.add(const Duration(days: 7));
    final startStr = _ymd(start);
    final endStr = _ymd(end);

    final uri = Uri.parse(
      'https://api.nasa.gov/neo/rest/v1/feed'
      '?start_date=$startStr&end_date=$endStr&api_key=$_apiKey',
    );

    final resp = await _http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) return <CosmicEvent>[];

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final byDate = (body['near_earth_objects'] as Map<String, dynamic>?) ?? {};

    final events = <CosmicEvent>[];
    byDate.forEach((date, neos) {
      for (final neo in (neos as List<dynamic>)) {
        final map = neo as Map<String, dynamic>;
        final hazardous = map['is_potentially_hazardous_asteroid'] == true;
        final name = map['name'] as String? ?? 'Asteroid';
        final approach = (map['close_approach_data'] as List?)?.firstOrNull;
        if (approach == null) continue;
        final ca = approach as Map<String, dynamic>;
        final missKm = double.tryParse(
              (ca['miss_distance'] as Map?)?['kilometers']?.toString() ?? '',
            ) ??
            double.infinity;
        final velocityKmh = double.tryParse(
              (ca['relative_velocity'] as Map?)?['kilometers_per_hour']
                      ?.toString() ??
                  '',
            ) ??
            0.0;

        // Keep only hazardous or genuinely close approaches (<1 lunar distance
        // ≈ 384,400 km). This avoids spamming the admin with dozens of
        // routine far-field asteroids.
        if (!hazardous && missKm > 384400) continue;

        final dateStr = ca['close_approach_date_full'] as String?;
        final dt = _parseApproachDate(dateStr, date);
        events.add(CosmicEvent(
          sourceId: 'neows-${map['id']}',
          titleAr: 'كويكب قريب: $name',
          titleEn: 'Near-Earth asteroid: $name',
          descriptionAr: hazardous
              ? 'كويكب محتمل الخطورة يمر قريباً من الأرض. مسافة العبور: ${_fmtKmAr(missKm)}، بسرعة ${velocityKmh.toStringAsFixed(0)} كم/س.'
              : 'كويكب قريب يمر من الأرض. مسافة العبور: ${_fmtKmAr(missKm)}.',
          descriptionEn: hazardous
              ? 'Potentially hazardous asteroid passing near Earth. Miss distance: ${_fmtKmEn(missKm)}, speed ${velocityKmh.toStringAsFixed(0)} km/h.'
              : 'A near-Earth asteroid passing by. Miss distance: ${_fmtKmEn(missKm)}.',
          date: dt,
          type: CosmicEventType.other,
          source: 'nasa-neows',
        ));
      }
    });
    return events;
  }

  /// NASA Astronomy Picture of the Day. Doesn't have a date per se (it IS
  /// today), but makes a nice "event" the admin can push to users.
  Future<List<CosmicEvent>> _fetchApod() async {
    final uri = Uri.parse('https://api.nasa.gov/planetary/apod?api_key=$_apiKey');
    final resp = await _http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) return <CosmicEvent>[];

    final m = jsonDecode(resp.body) as Map<String, dynamic>;
    final title = m['title'] as String? ?? 'Astronomy Picture of the Day';
    final explanation = m['explanation'] as String? ?? '';
    final dateStr = m['date'] as String?;
    final dt = dateStr != null ? DateTime.tryParse(dateStr) : null;
    final imageUrl = (m['media_type'] == 'image') ? m['url'] as String? : null;

    final shortExplanation = explanation.length > 300
        ? '${explanation.substring(0, 300)}…'
        : explanation;
    return [
      CosmicEvent(
        sourceId: 'apod-${dateStr ?? DateTime.now().toIso8601String()}',
        titleAr: 'صورة اليوم الفلكية: $title',
        titleEn: 'Astronomy Picture of the Day: $title',
        // APOD's explanation is only ever in English — we surface the same
        // text in both locales. A future improvement could run it through
        // a translation service.
        descriptionAr: shortExplanation,
        descriptionEn: shortExplanation,
        date: dt ?? DateTime.now(),
        type: CosmicEventType.other,
        imageUrl: imageUrl,
        source: 'nasa-apod',
      ),
    ];
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtKmAr(double km) {
    if (km >= 1000000) return '${(km / 1000000).toStringAsFixed(2)} مليون كم';
    if (km >= 1000) return '${(km / 1000).toStringAsFixed(0)} ألف كم';
    return '${km.toStringAsFixed(0)} كم';
  }

  String _fmtKmEn(double km) {
    if (km >= 1000000) return '${(km / 1000000).toStringAsFixed(2)}M km';
    if (km >= 1000) return '${(km / 1000).toStringAsFixed(0)}K km';
    return '${km.toStringAsFixed(0)} km';
  }

  /// NeoWs gives us "2026-Nov-12 14:30" in `close_approach_date_full`, or
  /// just "2026-11-12" as the outer key. Try to pick the richest we have.
  DateTime _parseApproachDate(String? full, String dayKey) {
    if (full != null) {
      // Convert "2026-Nov-12 14:30" → "2026-11-12T14:30" for DateTime.parse.
      const months = {
        'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
        'May': '05', 'Jun': '06', 'Jul': '07', 'Aug': '08',
        'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12',
      };
      var s = full;
      months.forEach((k, v) => s = s.replaceAll(k, v));
      s = s.replaceAll(' ', 'T');
      final parsed = DateTime.tryParse(s);
      if (parsed != null) return parsed;
    }
    return DateTime.tryParse(dayKey) ?? DateTime.now();
  }
}
