import 'notification_model.dart';
import 'cosmic_event_types.dart';

/// List of Saudi cities the app supports for notification targeting.
/// An empty string means "all cities" — admin sends to everyone and the
/// user wants to receive everything regardless of location.
class SupportedCities {
  static const List<String> ids = [
    '', // all
    'riyadh',
    'jeddah',
    'makkah',
    'madinah',
    'dammam',
    'abha',
    'tabuk',
    'taif',
    'khobar',
    'najran',
    'hail',
    'jazan',
  ];
}

/// Per-user preferences that control which notifications they see. Stored
/// inline on the user doc as `notificationPrefs` so a single user-doc read
/// gives us everything we need on app startup.
class NotificationPreferences {
  const NotificationPreferences({
    this.enabled = true,
    this.mutedInteraction = const <String>{},
    this.mutedCosmic = const <String>{},
    this.city = '',
  });

  /// Master switch — when false the user sees zero notifications.
  final bool enabled;

  /// Interaction types the user silenced (values are [NotificationType.name]
  /// minus 'cosmic'). Stored as a name set so it round-trips cleanly.
  final Set<String> mutedInteraction;

  /// Cosmic sub-types the user silenced (values are [CosmicEventType.name]).
  final Set<String> mutedCosmic;

  /// City the user cares about — drives the eventCity filter on cosmic
  /// broadcasts. Empty string = receive everything regardless of region.
  final String city;

  bool showsInteraction(NotificationType type) {
    if (type == NotificationType.cosmic) return true;
    return !mutedInteraction.contains(type.name);
  }

  bool showsCosmic(String? cosmicTypeName) {
    if (cosmicTypeName == null) return true;
    return !mutedCosmic.contains(cosmicTypeName);
  }

  bool matchesCity(String? eventCity) {
    if (eventCity == null || eventCity.isEmpty) return true; // broadcast to all
    if (city.isEmpty) return true; // user opted into everything
    return city == eventCity;
  }

  NotificationPreferences copyWith({
    bool? enabled,
    Set<String>? mutedInteraction,
    Set<String>? mutedCosmic,
    String? city,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      mutedInteraction: mutedInteraction ?? this.mutedInteraction,
      mutedCosmic: mutedCosmic ?? this.mutedCosmic,
      city: city ?? this.city,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'mutedInteraction': mutedInteraction.toList(),
      'mutedCosmic': mutedCosmic.toList(),
      'city': city,
    };
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const NotificationPreferences();
    return NotificationPreferences(
      enabled: map['enabled'] ?? true,
      mutedInteraction:
          Set<String>.from((map['mutedInteraction'] as List?) ?? const []),
      mutedCosmic: Set<String>.from((map['mutedCosmic'] as List?) ?? const []),
      city: map['city'] ?? '',
    );
  }
}
