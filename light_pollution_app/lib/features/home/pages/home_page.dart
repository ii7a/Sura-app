import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../chat/providers/chat_provider.dart';
import '../../community/widgets/app_drawer.dart';
import '../../notifications/providers/notifications_provider.dart';

/// Global key for the home scaffold so child pages can open the drawer.
final homeScaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>((ref) {
  return GlobalKey<ScaffoldState>();
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldKey = ref.watch(homeScaffoldKeyProvider);

    return Scaffold(
      key: scaffoldKey,
      drawer: const AppDrawer(),
      drawerEdgeDragWidth: 40,
      body: navigationShell,
      bottomNavigationBar: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final unselected = isDark ? AppColors.white.withValues(alpha: 0.6) : AppColors.textSecondary;
          final selected = isDark ? AppColors.white : AppColors.navy;
          // Unread count drives the little red badge on the bell icon.
          final unread = ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0;
          final unreadMessages = ref.watch(unreadConversationsCountProvider).valueOrNull ?? 0;
          return Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.div(context), width: 0.5),
              ),
            ),
            child: NavigationBar(
              // Hiding labels makes room for a 6th tab without the icons
              // cramming together the way they do with labels on.
              labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) {
                navigationShell.goBranch(index, initialLocation: true);
              },
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined, color: unselected),
                  selectedIcon: Icon(Icons.home, color: selected),
                  label: l10n.navHome,
                ),
                NavigationDestination(
                  icon: Icon(Icons.search_outlined, color: unselected),
                  selectedIcon: Icon(Icons.search, color: selected),
                  label: l10n.navSearch,
                ),
                NavigationDestination(
                  icon: Icon(Icons.camera_alt_outlined, color: unselected),
                  selectedIcon: Icon(Icons.camera_alt, color: selected),
                  label: l10n.navCamera,
                ),
                NavigationDestination(
                  icon: Icon(Icons.confirmation_num_outlined, color: unselected),
                  selectedIcon: Icon(Icons.confirmation_num, color: selected),
                  label: l10n.navReserve,
                ),
                // Notifications — shows an unread badge when count > 0.
                NavigationDestination(
                  icon: _BellIcon(color: unselected, unread: unread),
                  selectedIcon: _BellIcon(color: selected, unread: unread, filled: true),
                  label: l10n.notifications,
                ),
                NavigationDestination(
                  icon: _ChatIcon(color: unselected, unread: unreadMessages),
                  selectedIcon: _ChatIcon(color: selected, unread: unreadMessages, filled: true),
                  label: l10n.navChat,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Bell icon with an optional red unread counter bubble. Matches how X
/// renders its notifications tab: icon + small pill showing the count.
class _BellIcon extends StatelessWidget {
  const _BellIcon({
    required this.color,
    required this.unread,
    this.filled = false,
  });

  final Color color;
  final int unread;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      filled ? Icons.notifications : Icons.notifications_none,
      color: color,
    );
    if (unread <= 0) return icon;

    final label = unread > 99 ? '99+' : '$unread';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5),
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

/// Chat icon with an optional red unread counter bubble. Mirrors the bell
/// icon so both counters look identical in the bottom nav.
class _ChatIcon extends StatelessWidget {
  const _ChatIcon({
    required this.color,
    required this.unread,
    this.filled = false,
  });

  final Color color;
  final int unread;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      filled ? Icons.chat_bubble : Icons.chat_bubble_outline,
      color: color,
    );
    if (unread <= 0) return icon;

    final label = unread > 99 ? '99+' : '$unread';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5),
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
