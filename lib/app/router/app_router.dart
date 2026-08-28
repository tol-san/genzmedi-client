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

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authNotifierProvider,
      (_, _) => notifyListeners(),
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authNotifierProvider);
    final matched = state.matchedLocation;

    final isPublicAuthRoute = matched == '/login' ||
        matched == '/register' ||
        matched == '/forgot-password';

    // 1. While initial session checking, stay on splash screen
    if (authState is AuthInitial) {
      return matched == '/splash' ? null : '/splash';
    }

    // 2. While AuthLoading (e.g. logging in / registering), stay on current auth screen
    if (authState is AuthLoading) {
      if (isPublicAuthRoute) return null;
      if (matched == '/splash') return null;
      return null;
    }

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
  }
}

final routerNotifierProvider = ChangeNotifierProvider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: notifier.redirect,
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
