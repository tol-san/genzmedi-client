import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/auth/auth_state.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/profiles/data/repositories/profile_repository.dart';
import 'package:client/features/profiles/presentation/screens/my_profile_screen.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockProfileRepository mockProfileRepository;

  const testUser = UserModel(
    id: 'u-123',
    username: 'alex_creator',
    email: 'alex@example.com',
    displayName: 'Alex Creator',
    followersCount: 10,
    followingCount: 5,
    postCount: 1,
  );

  const testSavedTextPost = PostModel(
    id: 'p-saved-1',
    author: PostAuthorModel(id: 'u-999', username: 'author_jane'),
    postType: 'text',
    title: 'Interesting Article',
    content: 'Saved thought on architecture.',
  );

  const testSavedVideoPost = PostModel(
    id: 'p-saved-2',
    author: PostAuthorModel(id: 'u-888', username: 'dancer_dan'),
    postType: 'video',
    title: 'Dance moves',
    content: 'Awesome dance video recap!',
    media: [],
  );

  setUp(() {
    mockProfileRepository = MockProfileRepository();
    when(
      () => mockProfileRepository.getMyProfile(),
    ).thenAnswer((_) async => testUser);
    when(
      () => mockProfileRepository.getUserPosts(authorId: 'u-123'),
    ).thenAnswer((_) async => []);
  });

  Widget buildTestWidget({GoRouter? router}) {
    final testRouter =
        router ??
        GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const MyProfileScreen(),
            ),
            GoRoute(
              path: '/posts/:postId',
              name: RouteNames.postDetail,
              builder:
                  (context, state) =>
                      const Scaffold(body: Text('Mock Post Detail')),
            ),
            GoRoute(
              path: '/shorts-viewer',
              name: RouteNames.shortsViewer,
              builder:
                  (context, state) =>
                      const Scaffold(body: Text('Mock Shorts Viewer')),
            ),
            GoRoute(
              path: '/posts/:postId/media',
              name: RouteNames.mediaViewer,
              builder:
                  (context, state) =>
                      const Scaffold(body: Text('Mock Media Viewer')),
            ),
          ],
        );

    return ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(mockProfileRepository),
        authNotifierProvider.overrideWith(
          (ref) => MockAuthNotifier(const AuthAuthenticated(testUser)),
        ),
      ],
      child: MaterialApp.router(routerConfig: testRouter),
    );
  }

  group('MyProfileScreen Saved Posts Widget Tests', () {
    testWidgets('renders empty state when no saved posts exist', (
      tester,
    ) async {
      when(
        () => mockProfileRepository.getSavedPosts(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Switch to Saved tab
      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();

      expect(find.text('No saved posts'), findsOneWidget);
      expect(
        find.text('Save posts from your feed to easily find them later.'),
        findsOneWidget,
      );
    });

    testWidgets('renders saved post items in grid', (tester) async {
      when(
        () => mockProfileRepository.getSavedPosts(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => [testSavedTextPost, testSavedVideoPost]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Switch to Saved tab
      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();

      expect(find.text('Saved thought on architecture.'), findsOneWidget);
      expect(find.text('Awesome dance video recap!'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('renders error retry state and refreshes on Retry tap', (
      tester,
    ) async {
      when(
        () => mockProfileRepository.getSavedPosts(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenThrow(
        const ApiException(message: 'Network offline', statusCode: 503),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Switch to Saved tab
      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load saved posts'), findsOneWidget);
      expect(find.text('Network offline'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Subsequent call succeeds
      when(
        () => mockProfileRepository.getSavedPosts(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => [testSavedTextPost]);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Saved thought on architecture.'), findsOneWidget);
      expect(find.text('Failed to load saved posts'), findsNothing);
    });

    testWidgets('tapping saved post card triggers post interaction and refresh', (
      tester,
    ) async {
      when(
        () => mockProfileRepository.getSavedPosts(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => [testSavedTextPost]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();

      expect(find.text('Saved thought on architecture.'), findsOneWidget);

      await tester.tap(find.text('Saved thought on architecture.'));
      await tester.pumpAndSettle();

      expect(find.text('Mock Post Detail'), findsOneWidget);

      final navContext = tester.element(find.text('Mock Post Detail'));
      GoRouter.of(navContext).pop();
      await tester.pumpAndSettle();

      verify(
        () => mockProfileRepository.getSavedPosts(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).called(greaterThanOrEqualTo(2));
    });
  });
}
