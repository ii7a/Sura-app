import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../community/pages/post_detail_page.dart';
import '../../community/pages/user_profile_page.dart';
import '../models/notification_model.dart';
import '../providers/notifications_provider.dart';
import '../widgets/notification_tile.dart';

/// The notifications tab in the bottom nav. Shows the user's latest 50
/// interaction notifications (likes, reposts, quotes, comments, follows),
/// newest first. Opens the app's bell-icon-equivalent destinations:
///   • avatar tap → actor's profile
///   • row tap   → the related post (or actor profile for follow events)
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  bool _markedRead = false;

  @override
  void initState() {
    super.initState();
    // Clear the unread badge on the bell icon once the user lands on this
    // tab. We defer to after the first frame so the read state change
    // doesn't fight with the initial stream snapshot.
    WidgetsBinding.instance.addPostFrameCallback((_) => _markAllRead());
  }

  Future<void> _markAllRead() async {
    if (_markedRead) return;
    _markedRead = true;
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    try {
      await ref.read(firestoreServiceProvider).markAllNotificationsRead(uid);
    } catch (_) {
      // Best-effort. If Firestore rules reject the update we just leave
      // the badge showing; the user can try again on next open.
    }
  }

  Future<void> _onTapBody(AppNotification n) async {
    // Follow events take the user straight to the actor's profile —
    // there's no "post" to open.
    if (n.type == NotificationType.follow) {
      await _openActorProfile(n);
      return;
    }
    final postId = n.postId;
    if (postId == null || postId.isEmpty) return;
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PostDetailPage(postId: postId),
    ));
  }

  Future<void> _openActorProfile(AppNotification n) async {
    final user = await ref.read(firestoreServiceProvider).getUser(n.actorUid);
    if (user == null || !mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => UserProfilePage(user: user),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);
    final notifsAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.notifications,
          style: font(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: notifsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '$e',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) return _EmptyState(message: l10n.noNotifications);
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: AppColors.div(context)),
            itemBuilder: (_, i) {
              final n = items[i];
              return NotificationTile(
                notification: n,
                onTapAvatar: () => _openActorProfile(n),
                onTapBody: () => _onTapBody(n),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none,
            size: 72,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
