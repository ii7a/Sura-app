import 'cosmic_event_types.dart';

/// A dated cosmic event that the admin can broadcast as a notification.
///
/// Every event carries both Arabic and English copy so the notification
/// ends up in the viewer's language even though the admin only clicks
/// "send" once.
///
/// Sources (merged into one view):
///   • NASA NeoWs (close asteroid approaches)
///   • NASA APOD (picture of the day)
///   • Static JSON in assets (known eclipses, meteor showers, etc.)
class CosmicEvent {
  const CosmicEvent({
    required this.sourceId,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.date,
    required this.type,
    this.imageUrl,
    this.source = 'manual',
  });

  final String sourceId;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final String descriptionEn;
  final DateTime date;
  final CosmicEventType type;
  final String? imageUrl;
  /// 'nasa-neows' | 'nasa-apod' | 'static' | 'manual'
  final String source;

  /// Returns the title matching [locale] (fallback to Arabic when unknown).
  String title(String locale) => locale == 'en' ? titleEn : titleAr;
  String description(String locale) =>
      locale == 'en' ? descriptionEn : descriptionAr;

  factory CosmicEvent.fromStatic(Map<String, dynamic> m) {
    return CosmicEvent(
      sourceId: 'static-${m['id']}',
      titleAr: (m['title_ar'] ?? m['title']) as String,
      titleEn: (m['title_en'] ?? m['title']) as String,
      descriptionAr: (m['description_ar'] ?? m['description'] ?? '') as String,
      descriptionEn: (m['description_en'] ?? m['description'] ?? '') as String,
      date: DateTime.parse(m['date'] as String),
      type: cosmicTypeFromString(m['type'] as String?),
      imageUrl: m['imageUrl'] as String?,
      source: 'static',
    );
  }
}
