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
import 'package:client/features/auth/presentation/screens/profile_setup_screen.dart';
import 'package:client/features/auth/presentation/screens/register_screen.dart';
import 'package:client/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:client/features/auth/presentation/screens/splash_screen.dart';
import 'package:client/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:client/features/communities/presentation/screens/community_detail_screen.dart';
import 'package:client/features/communities/presentation/screens/community_list_screen.dart';
import 'package:client/features/communities/presentation/screens/create_community_screen.dart';
import 'package:client/features/feeds/presentation/screens/home_feed_screen.dart';
import 'package:client/features/feeds/presentation/screens/shorts_feed_screen.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/posts/presentation/screens/create_hub_screen.dart';
import 'package:client/features/posts/presentation/screens/create_post_screen.dart';
import 'package:client/features/posts/presentation/screens/post_detail_screen.dart';
import 'package:client/features/posts/presentation/screens/post_media_viewer_screen.dart';
import 'package:client/features/posts/presentation/screens/post_reactions_screen.dart';
import 'package:client/features/profiles/presentation/screens/edit_profile_screen.dart';
import 'package:client/features/profiles/presentation/screens/follow_list_screen.dart';
import 'package:client/features/profiles/presentation/screens/my_profile_screen.dart';
import 'package:client/features/profiles/presentation/screens/public_profile_screen.dart';
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

    // 1. While initial session checking, stay on splash screen
    if (authState is AuthInitial) {
      return matched == '/splash' ? null : '/splash';
    }

    // 2. Allow OTP verification, password reset, and profile setup flows without interruption
    if (matched == '/verify-otp' ||
        matched == '/reset-password' ||
        matched == '/profile-setup') {
      return null;
    }

    final isPublicAuthRoute = matched == '/login' ||
        matched == '/register' ||
        matched == '/forgot-password';

    // 3. While AuthLoading (e.g. logging in / registering), stay on current auth screen
    if (authState is AuthLoading) {
      if (isPublicAuthRoute) return null;
      if (matched == '/splash') return null;
      return null;
    }

    // 4. User needs interest onboarding or profile setup
    if (authState is AuthNeedsOnboarding) {
      if (matched == '/profile-setup' || matched == '/onboarding') {
        return null;
      }
      return '/onboarding';
    }

    // 5. Unauthenticated user attempting to access protected routes
    if (authState is AuthUnauthenticated) {
      return isPublicAuthRoute ? null : '/login';
    }

    // 6. Authenticated user attempting to access auth, onboarding, or splash
    if (authState is AuthAuthenticated) {
      if (isPublicAuthRoute || matched == '/onboarding' || matched == '/splash' || matched == '/profile-setup') {
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
  final notifier = ref.read(routerNotifierProvider);

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
        path: '/profile-setup',
        name: RouteNames.profileSetup,
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        name: RouteNames.verifyOtp,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final otp = state.uri.queryParameters['otp'];
          final flow = state.uri.queryParameters['flow'];
          return VerifyOtpScreen(
            email: email,
            initialOtp: otp,
            flow: flow,
          );
        },
      ),
      GoRoute(
        path: '/reset-password',
        name: RouteNames.resetPassword,
        builder: (context, state) {
          final token = state.uri.queryParameters['token'];
          final email = state.uri.queryParameters['email'];
          return ResetPasswordScreen(
            initialToken: token,
            initialEmail: email,
          );
        },
      ),
      GoRoute(
        path: '/onboarding',
        name: RouteNames.onboarding,
        builder: (context, state) => const InterestOnboardingScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        name: RouteNames.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/:username',
        name: RouteNames.publicProfile,
        builder: (context, state) {
          final username = state.pathParameters['username'] ?? '';
          return PublicProfileScreen(username: username);
        },
      ),
      GoRoute(
        path: '/user/:username',
        builder: (context, state) {
          final username = state.pathParameters['username'] ?? '';
          return PublicProfileScreen(username: username);
        },
      ),
      GoRoute(
        path: '/user/:userId/follow-list',
        name: RouteNames.followList,
        builder: (context, state) {
          final userId = state.pathParameters['userId'] ?? '';
          final username = state.uri.queryParameters['username'] ?? '';
          final initialTabIndex = int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
          return FollowListScreen(
            userId: userId,
            username: username,
            initialTabIndex: initialTabIndex,
          );
        },
      ),
      GoRoute(
        path: '/create/composer',
        name: RouteNames.createPost,
        builder: (context, state) {
          final type = state.uri.queryParameters['type'] ?? 'text';
          return CreatePostScreen(initialPostType: type);
        },
      ),
      GoRoute(
        path: '/posts/:postId',
        name: RouteNames.postDetail,
        builder: (context, state) {
          final postId = state.pathParameters['postId'] ?? '';
          return PostDetailScreen(postId: postId);
        },
      ),
      GoRoute(
        path: '/posts/:postId/media',
        name: RouteNames.mediaViewer,
        builder: (context, state) {
          final post = state.extra is PostModel ? state.extra as PostModel : null;
          final initialIndexStr = state.uri.queryParameters['index'];
          final initialIndex = int.tryParse(initialIndexStr ?? '0') ?? 0;
          if (post != null) {
            return PostMediaViewerScreen(post: post, initialIndex: initialIndex);
          }
          final postId = state.pathParameters['postId'] ?? '';
          return PostDetailScreen(postId: postId);
        },
      ),
      GoRoute(
        path: '/posts/:postId/reactions',
        name: RouteNames.postReactions,
        builder: (context, state) {
          final postId = state.pathParameters['postId'] ?? '';
          return PostReactionsScreen(postId: postId);
        },
      ),
      GoRoute(
        path: '/communities',
        name: RouteNames.communityList,
        builder: (context, state) => const CommunityListScreen(),
      ),
      GoRoute(
        path: '/communities/create',
        name: RouteNames.createCommunity,
        builder: (context, state) => const CreateCommunityScreen(),
      ),
      GoRoute(
        path: '/communities/:communityId',
        name: RouteNames.communityDetail,
        builder: (context, state) {
          final communityId = state.pathParameters['communityId'] ?? '';
          return CommunityDetailScreen(communityId: communityId);
        },
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
