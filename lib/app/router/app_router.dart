import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/app/shell/main_shell.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/auth/auth_state.dart';
import 'package:client/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:client/features/auth/presentation/screens/interest_onboarding_screen.dart';
import 'package:client/features/auth/presentation/screens/login_screen.dart';
import 'package:client/features/auth/presentation/screens/register_screen.dart';
import 'package:client/features/feeds/presentation/screens/home_feed_screen.dart';
import 'package:client/features/feeds/presentation/screens/shorts_feed_screen.dart';
import 'package:client/features/posts/presentation/screens/create_hub_screen.dart';
import 'package:client/features/profiles/presentation/screens/my_profile_screen.dart';
import 'package:client/features/search/presentation/screens/discover_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // A plain ChangeNotifier used as GoRouter's refreshListenable.
  // ref.listen fires notifyListeners on every auth state change, so
  // GoRouter re-evaluates its redirect guard automatically.
  final listenable = ChangeNotifier();

  ref.listen(authNotifierProvider, (_, __) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    listenable.notifyListeners();
  });

  // Dispose the ChangeNotifier when the provider scope closes.
  ref.onDispose(listenable.dispose);

  return GoRouter(
    initialLocation: '/feed',
    debugLogDiagnostics: false,
    // KEY FIX: GoRouter re-calls redirect every time listenable fires,
    // which now happens on every auth state change.
    refreshListenable: listenable,
    redirect: (BuildContext context, GoRouterState state) {
      // Always read the CURRENT auth state (not a stale closure copy).
      final authState = ref.read(authNotifierProvider);

      final isAuthLoading =
          authState is AuthInitial || authState is AuthLoading;
      if (isAuthLoading) return null;

      final matched = state.matchedLocation;
      final isPublicAuthRoute = matched == '/login' ||
          matched == '/register' ||
          matched == '/forgot-password';

      // 1. User needs interest onboarding
      if (authState is AuthNeedsOnboarding) {
        return matched == '/onboarding' ? null : '/onboarding';
      }

      // 2. Unauthenticated user attempting to access protected routes
      if (authState is AuthUnauthenticated) {
        return isPublicAuthRoute ? null : '/login';
      }

      // 3. Authenticated user attempting to access auth or onboarding pages
      if (authState is AuthAuthenticated) {
        if (isPublicAuthRoute || matched == '/onboarding') {
          return '/feed';
        }
      }

      return null;
    },
    routes: [
      // Auth & Onboarding Routes
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
      GoRoute(
        path: '/forgot-password',
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: RouteNames.onboarding,
        builder: (context, state) => const InterestOnboardingScreen(),
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
