import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/home/pages/home_page.dart';
import 'features/map/pages/map_page.dart';
import 'features/analysis/pages/analysis_page.dart';
import 'features/community/pages/community_page.dart';
import 'features/search/pages/search_page.dart';
import 'features/chat/pages/chat_list_page.dart';
import 'features/notifications/pages/notifications_page.dart';
import 'features/common/pages/splash_page.dart';
import 'features/community/pages/profile_page.dart';
import 'features/reserve/pages/reserve_page.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/signup_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }
}

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  refreshListenable: _AuthNotifier(),
  redirect: (context, state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
    final isSplash = state.matchedLocation == '/splash';

    // Allow splash to show without redirect
    if (isSplash) return null;

    if (!loggedIn && !isAuthRoute) return '/login';
    if (loggedIn && isAuthRoute) return '/community';
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupPage(),
    ),
    GoRoute(
      path: '/map',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MapPage(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return HomePage(navigationShell: navigationShell);
      },
      branches: [
        // Home (Community feed)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/community',
              builder: (context, state) => const CommunityPage(),
              routes: [
                GoRoute(
                  path: 'profile',
                  builder: (context, state) => const ProfilePage(),
                ),
              ],
            ),
          ],
        ),
        // Search
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchPage(),
            ),
          ],
        ),
        // Camera (Analysis)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/analyze',
              builder: (context, state) => const AnalysisPage(),
            ),
          ],
        ),
        // Reserve (trip booking)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/reserve',
              builder: (context, state) => const ReservePage(),
            ),
          ],
        ),
        // Notifications
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/notifications',
              builder: (context, state) => const NotificationsPage(),
            ),
          ],
        ),
        // Chat (DMs)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/chat',
              builder: (context, state) => const ChatListPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
