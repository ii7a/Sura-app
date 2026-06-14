import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/trip_model.dart';
import '../providers/reserve_provider.dart';
import '../widgets/trip_card.dart';
import 'create_trip_page.dart';
import 'manage_my_trips_page.dart';
import 'trip_detail_page.dart';

class ReservePage extends ConsumerWidget {
  const ReservePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);
    final tripsAsync = ref.watch(tripsStreamProvider);
    final currentFilter = ref.watch(tripFilterProvider);

    final trips = tripsAsync.valueOrNull ?? [];
    final filteredTrips = _filterTrips(trips, currentFilter);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final canCreateTrip = currentUser?.isVerified ?? false;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      floatingActionButton: canCreateTrip
          ? FloatingActionButton(
              heroTag: 'create_trip_fab',
              backgroundColor: AppColors.navy,
              onPressed: () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateTripPage(),
                  ),
                );
              },
              child: const Icon(Icons.add, color: AppColors.white),
            )
          : null,
      appBar: AppBar(
        title: Text(
          l10n.navReserve,
          style: font(
            color: AppColors.navy,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (canCreateTrip)
            IconButton(
              tooltip: 'My Created Trips',
              icon: const Icon(Icons.folder_special_outlined, color: AppColors.navy),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => const ManageMyTripsPage(),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: TripFilter.values.map((filter) {
                final isSelected = currentFilter == filter;
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(
                      _filterLabel(l10n, filter),
                      style: font(
                        color: isSelected ? AppColors.white : AppColors.navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selectedColor: AppColors.navy,
                    backgroundColor: AppColors.cardBg,
                    checkmarkColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.navy : AppColors.divider,
                      ),
                    ),
                    onSelected: (_) {
                      ref.read(tripFilterProvider.notifier).state = filter;
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          // Trip list
          Expanded(
            child: filteredTrips.isEmpty
                ? Center(
                    child: Text(
                      l10n.noTripsAvailable,
                      style: font(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: filteredTrips.length,
                    itemBuilder: (context, index) {
                      final trip = filteredTrips[index];
                      return TripCard(
                        trip: trip,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TripDetailPage(tripId: trip.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<StargazingTrip> _filterTrips(List<StargazingTrip> trips, TripFilter filter) {
    switch (filter) {
      case TripFilter.all:
        return trips;
      case TripFilter.upcoming:
        final now = DateTime.now();
        final upcoming = trips.where((t) => t.date.isAfter(now)).toList();
        upcoming.sort((a, b) => a.date.compareTo(b.date));
        return upcoming;
      case TripFilter.popular:
        final popular = trips.toList();
        popular.sort((a, b) {
          final aPopularity = a.maxGroupSize - a.spotsLeft;
          final bPopularity = b.maxGroupSize - b.spotsLeft;
          return bPopularity.compareTo(aPopularity);
        });
        return popular;
    }
  }

  String _filterLabel(AppLocalizations l10n, TripFilter filter) {
    switch (filter) {
      case TripFilter.all:
        return l10n.filterAll;
      case TripFilter.upcoming:
        return l10n.filterUpcoming;
      case TripFilter.popular:
        return l10n.filterPopular;
    }
  }
}
