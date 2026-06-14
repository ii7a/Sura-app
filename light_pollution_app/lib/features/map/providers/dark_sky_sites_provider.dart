import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dark_sky_site.dart';
import 'map_provider.dart';

final darkSkySitesProvider = FutureProvider<List<DarkSkySite>>((ref) async {
  final jsonString =
      await rootBundle.loadString('assets/data/dark_sky_sites.json');
  final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
  return jsonList
      .map((e) => DarkSkySite.fromJson(e as Map<String, dynamic>))
      .toList();
});

final visibleDarkSkySitesProvider = Provider<List<DarkSkySite>>((ref) {
  final allSitesAsync = ref.watch(darkSkySitesProvider);
  final zoom = ref.watch(mapProvider).currentZoom;

  return allSitesAsync.when(
    data: (sites) {
      if (zoom < 3) {
        // World view: show one representative per country
        final Map<String, DarkSkySite> countryReps = {};
        for (final site in sites) {
          if (!countryReps.containsKey(site.country)) {
            countryReps[site.country] = site;
          }
        }
        return countryReps.values.toList();
      }
      // Zoom 3+: show all sites
      return sites;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Count of sites per country (for cluster badges at low zoom)
final darkSkySiteCountByCountryProvider =
    Provider<Map<String, int>>((ref) {
  final allSitesAsync = ref.watch(darkSkySitesProvider);
  return allSitesAsync.when(
    data: (sites) {
      final Map<String, int> counts = {};
      for (final site in sites) {
        counts[site.country] = (counts[site.country] ?? 0) + 1;
      }
      return counts;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});
