import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/trip_model.dart';

final tripFilterProvider = StateProvider<TripFilter>((ref) => TripFilter.all);

final _db = FirebaseFirestore.instance;

/// Stream of all trips from Firestore, ordered by date.
final tripsStreamProvider = StreamProvider<List<StargazingTrip>>((ref) {
  final currentUser = ref.watch(currentUserProvider).valueOrNull;
  final uid = currentUser?.id;

  return _db
      .collection('trips')
      .orderBy('date', descending: false)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      return StargazingTrip.fromMap(doc.id, doc.data(), currentUserId: uid);
    }).toList();
  });
});

/// Adds a new trip to Firestore.
Future<void> addTripToFirestore(StargazingTrip trip) async {
  await _db.collection('trips').add(trip.toMap());
}

/// Deletes a trip from Firestore (admin only).
Future<void> deleteTripFromFirestore(String tripId) async {
  await _db.collection('trips').doc(tripId).delete();
}

/// Updates a trip in Firestore (admin only).
Future<void> updateTripInFirestore(String tripId, Map<String, dynamic> updates) async {
  await _db.collection('trips').doc(tripId).update(updates);
}

/// Books a trip for the current user in Firestore.
///
/// [seats] is how many spots the user wants to reserve at once (1–5 per the
/// app rules). The transaction rejects the booking if the trip doesn't have
/// that many spots left, if the user already booked the trip, or if the
/// seat count is out of range.
///
/// This writes two places atomically:
///  • the trip doc's `bookedBy` array + `spotsLeft` counter (decremented
///    by [seats]), and
///  • a private `trips/{tripId}/bookings/{userId}` doc that the trip's
///    guide can read to see who registered. The bookings doc snapshots the
///    user's name / username / avatar / phone / email / seat count at
///    booking time so the management page doesn't need to refetch each
///    profile.
Future<void> bookTripInFirestore(
  String tripId, {
  required String userId,
  required String userName,
  required String userUsername,
  required int seats,
  String? userAvatarUrl,
  String? userEmail,
  String? userPhone,
}) async {
  if (seats < 1 || seats > 5) {
    throw ArgumentError('seats must be between 1 and 5');
  }
  final tripRef = _db.collection('trips').doc(tripId);
  final bookingRef = tripRef.collection('bookings').doc(userId);
  await _db.runTransaction((txn) async {
    final doc = await txn.get(tripRef);
    if (!doc.exists) throw StateError('trip not found');

    final data = doc.data()!;
    final bookedBy = List<String>.from(data['bookedBy'] ?? []);
    final spotsLeft = data['spotsLeft'] as int? ?? 0;

    if (bookedBy.contains(userId)) {
      throw StateError('already booked');
    }
    if (spotsLeft < seats) {
      throw StateError('not enough spots left');
    }

    bookedBy.add(userId);
    txn.update(tripRef, {
      'bookedBy': bookedBy,
      'spotsLeft': spotsLeft - seats,
    });
    txn.set(bookingRef, {
      'userId': userId,
      'userName': userName,
      'userUsername': userUsername,
      'userAvatarUrl': userAvatarUrl,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'seats': seats,
      'bookedAt': FieldValue.serverTimestamp(),
    });
  });
}


// ── Keep for backward compatibility with existing code ──

class ReserveNotifier extends StateNotifier<List<StargazingTrip>> {
  ReserveNotifier() : super([]);

  void bookTrip(String id) {
    state = [
      for (final trip in state)
        if (trip.id == id && !trip.isBooked)
          trip.copyWith(isBooked: true, spotsLeft: trip.spotsLeft - 1)
        else
          trip,
    ];
  }

  void addTrip(StargazingTrip trip) {
    state = [trip, ...state];
  }
}

final reserveProvider =
    StateNotifierProvider<ReserveNotifier, List<StargazingTrip>>((ref) {
  return ReserveNotifier();
});

