import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import 'package:light_pollution_app/core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/smart_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/community_models.dart';
import '../pages/bookmarks_page.dart';
import '../pages/premium_page.dart';
import '../../notifications/pages/admin_events_feed_page.dart';
import '../../notifications/pages/admin_send_notification_page.dart';
import '../../reserve/pages/my_trips_page.dart';
import '../../settings/pages/settings_page.dart';
import 'verified_badge.dart';


class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);
    final locale = ref.watch(localeProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    final user = currentUserAsync.valueOrNull ??
        MockUser(
          id: '',
          name: l10n.loadingText,
          username: '@...',
          avatarInitials: '?',
          bio: '',
        );

    return Drawer(
      backgroundColor: AppColors.dark,
      width: MediaQuery.of(context).size.width * 0.78,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar - tapping opens profile
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/community/profile');
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.navy,
                      ),
                      child: user.avatarUrl != null
                          ? ClipOval(
                              child: SmartImage(
                                url: user.avatarUrl!,
                                width: 48, height: 48,
                                fallback: Center(
                                  child: Text(
                                    user.avatarInitials,
                                    style: font(
                                      color: AppColors.white,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                user.avatarInitials,
                                style: font(
                                  color: AppColors.white,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name + verified + premium
                  Row(
                    children: [
                      Text(
                        user.name,
                        style: font(
                          color: AppColors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: 4),
                        VerifiedBadge(size: 18, isAdmin: user.isAdmin),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Username + lock icon if private
                  Row(
                    children: [
                      Text(
                        user.username,
                        style: font(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      ),
                      if (user.isPrivate) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.lock, size: 14, color: Colors.white.withValues(alpha: 0.5)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(color: Colors.white12, height: 1),

            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerItem(
                    icon: Icons.person_outline,
                    label: l10n.profile,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/community/profile');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.star_border,
                    label: l10n.premium,
                    trailing: user.isVerified
                        ? VerifiedBadge(size: 18, isAdmin: user.isAdmin)
                        : null,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(builder: (_) => const PremiumPage()),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.bookmark_border,
                    label: l10n.bookmarks,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(builder: (_) => const BookmarksPage()),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.flight_takeoff_outlined,
                    label: l10n.myReservations,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(builder: (_) => const MyTripsPage()),
                      );
                    },
                  ),
                  // Admin-only entry points. Only the single Sura admin
                  // account sees these rows; everyone else never renders them.
                  if (ref.watch(isAdminProvider)) ...[
                    _DrawerItem(
                      icon: Icons.campaign_outlined,
                      label: l10n.adminSendNotification,
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (_) => const AdminSendNotificationPage(),
                          ),
                        );
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.event_outlined,
                      label: l10n.adminUpcomingEvents,
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (_) => const AdminEventsFeedPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

            // Bottom section
            const Divider(color: Colors.white12, height: 1),
            _DrawerItem(
              icon: Icons.settings_outlined,
              label: l10n.settingsPrivacy,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),
            _DrawerItem(
              icon: Icons.language,
              label: l10n.language,
              trailing: Text(
                locale.languageCode == 'ar' ? l10n.arabic : l10n.english,
                style: font(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              onTap: () {
                ref.read(localeProvider.notifier).toggleLocale();
                Navigator.of(context).pop();
              },
            ),
            _DrawerItem(
              icon: Icons.help_outline,
              label: l10n.helpCenter,
              onTap: () => Navigator.of(context).pop(),
            ),
            _DrawerItem(
              icon: Icons.logout,
              label: l10n.logout,
              onTap: () async {
                Navigator.of(context).pop();
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);
    return ListTile(
      leading: Icon(icon, color: AppColors.white, size: 24),
      title: Text(
        label,
        style: font(
          color: AppColors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      dense: true,
      visualDensity: const VisualDensity(vertical: 0.5),
    );
  }
}
