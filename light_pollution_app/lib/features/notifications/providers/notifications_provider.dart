import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/notification_model.dart';
import '../models/notification_preferences.dart';

/// Streams the signed-in user's notification preferences. Drives the
/// settings UI and feeds the filter on the notifications list.
final notificationPreferencesProvider =
    StreamProvider<NotificationPreferences>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) {
    return Stream.value(const NotificationPreferences());
  }
  return firestore.notificationPreferencesStream(uid);
});

/// Streams the signed-in user's notifications (newest first, 50 max).
/// Applies the user's own preferences client-side: silenced types are
/// filtered out, and when prefs.enabled is false we return an empty list.
final notificationsStreamProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) {
    return Stream.value(const <AppNotification>[]);
  }
  final prefs = ref.watch(notificationPreferencesProvider).valueOrNull ??
      const NotificationPreferences();
  return firestore.notificationsStream(uid).map((items) {
    if (!prefs.enabled) return const <AppNotification>[];
    return items.where((n) {
      if (n.type == NotificationType.cosmic) {
        if (!prefs.showsCosmic(n.cosmicType)) return false;
        if (!prefs.matchesCity(n.eventCity)) return false;
        return true;
      }
      return prefs.showsInteraction(n.type);
    }).toList();
  });
});

/// Badge count for the bell icon in the bottom nav. Respects the same
/// preference filters so the badge matches what the page would show.
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(0);
  final notifs = ref.watch(notificationsStreamProvider);
  final count = notifs.valueOrNull?.where((n) => !n.read).length ?? 0;
  return Stream.value(count);
});
