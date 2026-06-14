import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';

enum TripFilter { all, upcoming, popular }

class StargazingTrip {
  const StargazingTrip({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.durationHours,
    required this.guideName,
    required this.guideRating,
    required this.bortleClass,
    required this.price,
    this.currency = 'SAR',
    required this.maxGroupSize,
    required this.spotsLeft,
    required this.description,
    required this.included,
    required this.gradientColors,
    this.isBooked = false,
    this.guideId = '',
    this.guideAvatarUrl,
    this.bookedBy = const [],
    this.coverImageUrl,
  });

  final String id;
  final String title;
  final String location;
  final DateTime date;
  final int durationHours;
  final String guideName;
  final double guideRating;
  final int bortleClass;
  final double price;
  final String currency;
  final int maxGroupSize;
  final int spotsLeft;
  final String description;
  final List<String> included;
  final List<Color> gradientColors;
  final bool isBooked;
  final String guideId;
  final String? guideAvatarUrl;
  final List<String> bookedBy;
  final String? coverImageUrl;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'location': location,
      'date': Timestamp.fromDate(date),
      'durationHours': durationHours,
      'guideName': guideName,
      'guideId': guideId,
      'guideAvatarUrl': guideAvatarUrl,
      'guideRating': guideRating,
      'bortleClass': bortleClass,
      'price': price,
      'currency': currency,
      'maxGroupSize': maxGroupSize,
      'spotsLeft': spotsLeft,
      'description': description,
      'included': included,
      'gradientColors': gradientColors.map((c) => c.toARGB32()).toList(),
      'bookedBy': bookedBy,
      'coverImageUrl': coverImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory StargazingTrip.fromMap(String id, Map<String, dynamic> map, {String? currentUserId}) {
    final date = map['date'];
    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else {
      dateTime = DateTime.now();
    }

    final gradientInts = List<int>.from(map['gradientColors'] ?? [0xFF000814, 0xFF001d3d, 0xFF1a0a00]);
    final bookedBy = List<String>.from(map['bookedBy'] ?? []);

    return StargazingTrip(
      id: id,
      title: map['title'] ?? '',
      location: map['location'] ?? '',
      date: dateTime,
      durationHours: map['durationHours'] ?? 4,
      guideName: map['guideName'] ?? '',
      guideId: map['guideId'] ?? '',
      guideAvatarUrl: map['guideAvatarUrl'] as String?,
      guideRating: (map['guideRating'] ?? 5.0).toDouble(),
      bortleClass: map['bortleClass'] ?? 3,
      price: (map['price'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'SAR',
      maxGroupSize: map['maxGroupSize'] ?? 10,
      spotsLeft: map['spotsLeft'] ?? 0,
      description: map['description'] ?? '',
      included: List<String>.from(map['included'] ?? []),
      gradientColors: gradientInts.map((i) => Color(i)).toList(),
      isBooked: currentUserId != null && bookedBy.contains(currentUserId),
      bookedBy: bookedBy,
      coverImageUrl: map['coverImageUrl'],
    );
  }

  StargazingTrip copyWith({
    bool? isBooked,
    int? spotsLeft,
    String? coverImageUrl,
  }) {
    return StargazingTrip(
      id: id,
      title: title,
      location: location,
      date: date,
      durationHours: durationHours,
      guideName: guideName,
      guideRating: guideRating,
      bortleClass: bortleClass,
      price: price,
      currency: currency,
      maxGroupSize: maxGroupSize,
      spotsLeft: spotsLeft ?? this.spotsLeft,
      description: description,
      included: included,
      gradientColors: gradientColors,
      isBooked: isBooked ?? this.isBooked,
      guideId: guideId,
      guideAvatarUrl: guideAvatarUrl,
      bookedBy: bookedBy,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    );
  }
}
