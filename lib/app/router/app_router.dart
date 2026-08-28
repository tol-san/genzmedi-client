import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/auth/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/feeds/presentation/screens/home_feed_screen.dart';
import '../../features/feeds/presentation/screens/shorts_feed_screen.dart';
import '../../features/posts/presentation/screens/create_hub_screen.dart';
import '../../features/profiles/presentation/screens/my_profile_screen.dart';
import '../../features/search/presentation/screens/discover_screen.dart';
import '../shell/main_shell.dart';
import 'route_names.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/feed',
    debugLogDiagnostics: true,
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthLoading = authState is AuthInitial || authState is AuthLoading;
      if (isAuthLoading) return null;

      final isUnauthenticated = authState is AuthUnauthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // If user is not authenticated and not on an auth screen, redirect to login
      if (isUnauthenticated) {
        return isAuthRoute ? null : '/login';
      }

      // If authenticated user is on an auth screen, redirect to feed
      if (authState is AuthAuthenticated && isAuthRoute) {
        return '/feed';
      }

      return null;
    },
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // 5-Tab Shell Route
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home Feed
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                name: RouteNames.homeFeed,
                builder: (context, state) => const HomeFeedScreen(),
              ),
            ],
          ),
          // Branch 1: Shorts Feed
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shorts',
                name: RouteNames.shortsFeed,
                builder: (context, state) => const ShortsFeedScreen(),
              ),
            ],
          ),
          // Branch 2: Create Hub
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/create',
                name: RouteNames.create,
                builder: (context, state) => const CreateHubScreen(),
              ),
            ],
          ),
          // Branch 3: Discover
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                name: RouteNames.discover,
                builder: (context, state) => const DiscoverScreen(),
              ),
            ],
          ),
          // Branch 4: My Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: RouteNames.myProfile,
                builder: (context, state) => const MyProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
