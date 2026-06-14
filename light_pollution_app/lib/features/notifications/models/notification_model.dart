import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  like,
  repost,
  quote,
  comment,
  follow,
  cosmic, // reserved for phase B2
}

NotificationType _typeFromString(String value) {
  return NotificationType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => NotificationType.like,
  );
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.recipientUid,
    required this.actorUid,
    required this.actorName,
    required this.actorUsername,
    this.actorAvatarUrl,
    required this.actorAvatarInitials,
    required this.type,
    this.postId,
    this.postPreview,
    this.commentText,
    this.createdAt,
    this.read = false,
    // Cosmic-notification fields. Populated only when type == cosmic;
    // left null for interaction notifications.
    this.cosmicType,
    this.eventTitle,
    this.eventDescription,
    this.eventTitleEn,
    this.eventDescriptionEn,
    this.eventDate,
    this.eventImageUrl,
    this.eventCity,
  });

  final String id;
  final String recipientUid;
  final String actorUid;
  final String actorName;
  final String actorUsername;
  final String? actorAvatarUrl;
  final String actorAvatarInitials;
  final NotificationType type;
  final String? postId;
  final String? postPreview;
  final String? commentText;
  final DateTime? createdAt;
  final bool read;
  // ── Cosmic fields (B2) ─────────────────────────────────
  /// Which sub-category of cosmic event (eclipse, meteor shower, …). Stored
  /// as the enum's `name` string so it round-trips cleanly through Firestore.
  final String? cosmicType;
  /// Arabic title (default). When the app runs in Arabic locale this is
  /// what the notification tile shows.
  final String? eventTitle;
  /// Arabic description (default).
  final String? eventDescription;
  /// English title. Used when the app is in the 'en' locale. Falls back to
  /// [eventTitle] when null so old notifications keep working.
  final String? eventTitleEn;
  /// English description. Same fallback behavior as [eventTitleEn].
  final String? eventDescriptionEn;
  final DateTime? eventDate;
  final String? eventImageUrl;
  /// When set, this notification was intended for a specific city. The
  /// admin's broadcast also writes per-recipient docs so this is mostly
  /// informational on the client side.
  final String? eventCity;

  String get timeAgo {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inDays > 365) return '${diff.inDays ~/ 365}y';
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }

  Map<String, dynamic> toMap() {
    return {
      'recipientUid': recipientUid,
      'actorUid': actorUid,
      'actorName': actorName,
      'actorUsername': actorUsername,
      'actorAvatarUrl': actorAvatarUrl,
      'actorAvatarInitials': actorAvatarInitials,
      'type': type.name,
      'postId': postId,
      'postPreview': postPreview,
      'commentText': commentText,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'read': read,
      'cosmicType': cosmicType,
      'eventTitle': eventTitle,
      'eventDescription': eventDescription,
      'eventTitleEn': eventTitleEn,
      'eventDescriptionEn': eventDescriptionEn,
      'eventDate': eventDate,
      'eventImageUrl': eventImageUrl,
      'eventCity': eventCity,
    };
  }

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    final createdAtRaw = map['createdAt'];
    DateTime? dt;
    if (createdAtRaw is Timestamp) dt = createdAtRaw.toDate();

    final eventDateRaw = map['eventDate'];
    DateTime? eventDt;
    if (eventDateRaw is Timestamp) eventDt = eventDateRaw.toDate();

    return AppNotification(
      id: id,
      recipientUid: map['recipientUid'] ?? '',
      actorUid: map['actorUid'] ?? '',
      actorName: map['actorName'] ?? '',
      actorUsername: map['actorUsername'] ?? '',
      actorAvatarUrl: map['actorAvatarUrl'] as String?,
      actorAvatarInitials: map['actorAvatarInitials'] ?? '',
      type: _typeFromString(map['type'] ?? 'like'),
      postId: map['postId'] as String?,
      postPreview: map['postPreview'] as String?,
      commentText: map['commentText'] as String?,
      createdAt: dt,
      read: map['read'] ?? false,
      cosmicType: map['cosmicType'] as String?,
      eventTitle: map['eventTitle'] as String?,
      eventDescription: map['eventDescription'] as String?,
      eventTitleEn: map['eventTitleEn'] as String?,
      eventDescriptionEn: map['eventDescriptionEn'] as String?,
      eventDate: eventDt,
      eventImageUrl: map['eventImageUrl'] as String?,
      eventCity: map['eventCity'] as String?,
    );
  }

  /// Returns the title appropriate for [locale] ('ar' or 'en'), with a
  /// sensible fallback when only one language was provided.
  String? titleFor(String locale) {
    if (locale == 'en') return eventTitleEn ?? eventTitle;
    return eventTitle ?? eventTitleEn;
  }

  /// Same locale picker for the event description.
  String? descriptionFor(String locale) {
    if (locale == 'en') return eventDescriptionEn ?? eventDescription;
    return eventDescription ?? eventDescriptionEn;
  }
}
