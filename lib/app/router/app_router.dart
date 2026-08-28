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
import 'package:client/features/auth/presentation/screens/splash_screen.dart';
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

  ref.listen(authNotifierProvider, (_, _) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    listenable.notifyListeners();
  });

  // Dispose the ChangeNotifier when the provider scope closes.
  ref.onDispose(listenable.dispose);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    refreshListenable: listenable,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authNotifierProvider);
      final matched = state.matchedLocation;

      final isAuthLoading =
          authState is AuthInitial || authState is AuthLoading;

      // 1. While loading session, keep on splash screen
      if (isAuthLoading) {
        return matched == '/splash' ? null : '/splash';
      }

      final isPublicAuthRoute = matched == '/login' ||
          matched == '/register' ||
          matched == '/forgot-password';

      // 2. User needs interest onboarding
      if (authState is AuthNeedsOnboarding) {
        return matched == '/onboarding' ? null : '/onboarding';
      }

      // 3. Unauthenticated user attempting to access protected routes
      if (authState is AuthUnauthenticated) {
        return isPublicAuthRoute ? null : '/login';
      }

      // 4. Authenticated user attempting to access auth, onboarding, or splash
      if (authState is AuthAuthenticated) {
        if (isPublicAuthRoute || matched == '/onboarding' || matched == '/splash') {
          return '/feed';
        }
      }

      return null;
    },
    routes: [
      // Splash Route
      GoRoute(
        path: '/splash',
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),

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
