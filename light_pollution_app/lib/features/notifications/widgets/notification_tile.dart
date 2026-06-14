import 'package:flutter/material.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/smart_image.dart';
import '../models/cosmic_event_types.dart';
import '../models/notification_model.dart';

/// X-style notification row. Shows:
///   • a small icon badge on the top-left indicating the action type
///   • the actor's avatar (tapping it opens their profile)
///   • a sentence describing what happened
///   • the post preview (when applicable)
///   • a relative timestamp on the right
///
/// Callbacks let the page decide where each tap leads, keeping this
/// widget purely presentational.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTapAvatar,
    required this.onTapBody,
  });

  final AppNotification notification;
  final VoidCallback onTapAvatar;
  final VoidCallback onTapBody;

  @override
  Widget build(BuildContext context) {
    // Cosmic events get their own, richer layout — big icon, event title,
    // event date, description. Interaction notifications stay X-style.
    if (notification.type == NotificationType.cosmic) {
      return _CosmicTile(
        notification: notification,
        onTap: onTapBody,
      );
    }
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconInfo = _iconFor(notification.type);

    // Unread rows get a subtle tint so the user can see new items at a glance.
    final bg = notification.read
        ? Colors.transparent
        : (isDark
            ? AppColors.navy.withValues(alpha: 0.25)
            : AppColors.navy.withValues(alpha: 0.06));

    return Material(
      color: bg,
      child: InkWell(
        onTap: onTapBody,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge icon on the left, mirroring X's layout.
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 10),
                child: Icon(
                  iconInfo.$1,
                  color: iconInfo.$2,
                  size: 22,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar is its own tap target so the user can jump to
                    // the actor's profile without triggering the body tap.
                    GestureDetector(
                      onTap: onTapAvatar,
                      child: _AvatarSmall(
                        url: notification.actorAvatarUrl,
                        initials: notification.actorAvatarInitials,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: AppColors.text(context),
                          fontSize: 14.5,
                          height: 1.35,
                        ),
                        children: [
                          TextSpan(
                            text: notification.actorName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(text: _actionText(l10n, notification.type)),
                        ],
                      ),
                    ),
                    if (notification.commentText != null &&
                        notification.commentText!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.commentText!,
                        style: TextStyle(
                          color: AppColors.text(context),
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (notification.postPreview != null &&
                        notification.postPreview!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.postPreview!,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                notification.timeAgo,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns the icon + color pair for a notification type. Tuples keep
  /// the mapping compact and inline with how X renders its badges.
  (IconData, Color) _iconFor(NotificationType t) {
    switch (t) {
      case NotificationType.like:
        return (Icons.favorite, Colors.red);
      case NotificationType.repost:
        return (Icons.repeat, Colors.green);
      case NotificationType.comment:
        return (Icons.chat_bubble, Colors.blue);
      case NotificationType.quote:
        return (Icons.format_quote, Colors.orange);
      case NotificationType.follow:
        return (Icons.person_add, Colors.purple);
      case NotificationType.cosmic:
        return (Icons.auto_awesome, Colors.amber);
    }
  }

  String _actionText(AppLocalizations l10n, NotificationType t) {
    switch (t) {
      case NotificationType.like:
        return l10n.notificationLiked;
      case NotificationType.repost:
        return l10n.notificationReposted;
      case NotificationType.comment:
        return l10n.notificationCommented;
      case NotificationType.quote:
        return l10n.notificationQuoted;
      case NotificationType.follow:
        return l10n.notificationFollowed;
      case NotificationType.cosmic:
        return '';
    }
  }
}

/// Card-style tile for cosmic events. Visually distinct from the X-style
/// interaction rows so users can spot "the sky is doing something tonight"
/// at a glance instead of mentally filtering through likes/reposts.
class _CosmicTile extends StatelessWidget {
  const _CosmicTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cosmic = cosmicTypeFromString(notification.cosmicType);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Pick the copy that matches the viewer's locale. falls back to the
    // other language when only one was provided (legacy notifications).
    final locale = Localizations.localeOf(context).languageCode;
    final title = notification.titleFor(locale) ?? '';
    final description = notification.descriptionFor(locale) ?? '';
    final bg = notification.read
        ? (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.02))
        : cosmic.color.withValues(alpha: isDark ? 0.15 : 0.08);

    return Material(
      color: bg,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cosmic.color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(cosmic.icon, color: cosmic.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (notification.eventDate != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatEventDate(notification.eventDate!),
                        style: TextStyle(
                          color: cosmic.color,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                notification.timeAgo,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatEventDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year;
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$year/$month/$day  $hh:$mm';
  }
}

class _AvatarSmall extends StatelessWidget {
  const _AvatarSmall({required this.url, required this.initials});

  final String? url;
  final String initials;

  @override
  Widget build(BuildContext context) {
    const size = 36.0;
    final u = url;
    if (u != null && u.isNotEmpty) {
      return ClipOval(
        child: SmartImage(
          url: u,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.navy,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
