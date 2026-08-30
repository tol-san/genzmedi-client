import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/auth/auth_state.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/profiles/data/repositories/profile_repository.dart';
import 'package:client/features/profiles/presentation/screens/my_profile_screen.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}
class MockAuthNotifier extends Mock implements AuthNotifier {}

void main() {
  late MockProfileRepository mockProfileRepository;

  const testUser = UserModel(
    id: 'u-123',
    username: 'alex_creator',
    email: 'alex@example.com',
    displayName: 'Alex Creator',
    bio: 'Digital content & UI builder',
    followersCount: 1500,
    followingCount: 320,
    postCount: 12,
    interests: ['gaming', 'music', 'coding'],
    isVerified: true,
  );

  const testPost = PostModel(
    id: 'p-1',
    author: PostAuthorModel(id: 'u-123', username: 'alex_creator'),
    postType: 'text',
    title: 'Welcome to my feed',
    content: 'Loving the vibe here!',
    likeCount: 24,
    commentCount: 5,
  );

  setUp(() {
    mockProfileRepository = MockProfileRepository();
    when(() => mockProfileRepository.getMyProfile()).thenAnswer((_) async => testUser);
    when(() => mockProfileRepository.getUserPosts(authorId: 'u-123'))
        .thenAnswer((_) async => [testPost]);
    when(() => mockProfileRepository.getSavedPosts()).thenAnswer((_) async => []);
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(mockProfileRepository),
        authNotifierProvider.overrideWith(
          (ref) => AuthNotifierMock(const AuthAuthenticated(testUser)),
        ),
      ],
      child: const MaterialApp(
        home: MyProfileScreen(),
      ),
    );
  }

  group('MyProfileScreen Widget Tests', () {
    testWidgets('renders profile header, username, stats, and interest chips', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify username and display name
      expect(find.text('@alex_creator'), findsOneWidget);
      expect(find.text('Alex Creator'), findsOneWidget);
      expect(find.text('Digital content & UI builder'), findsOneWidget);

      // Verify stats
      expect(find.text('1.5K'), findsOneWidget); // 1500 followers formatted as 1.5K
      expect(find.text('Followers'), findsOneWidget);
      expect(find.text('320'), findsOneWidget);
      expect(find.text('Following'), findsOneWidget);

      // Verify interests chips
      expect(find.text('#gaming'), findsOneWidget);
      expect(find.text('#music'), findsOneWidget);
      expect(find.text('#coding'), findsOneWidget);

      // Verify tabs & stats
      expect(find.text('Posts'), findsNWidgets(2)); // Stat label + Tab label
      expect(find.text('Saved'), findsOneWidget);
    });

    testWidgets('renders personal post card inside Posts tab', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Loving the vibe here!'), findsOneWidget);
    });

    testWidgets('tapping Sign Out icon displays confirmation dialog', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final logoutButton = find.byIcon(Icons.logout_rounded);
      expect(logoutButton, findsOneWidget);

      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      expect(find.text('Sign Out'), findsNWidgets(2)); // AppBar tooltip/action + Dialog title
      expect(find.text('Are you sure you want to sign out of your account?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}

class AuthNotifierMock extends StateNotifier<AuthState> implements AuthNotifier {
  AuthNotifierMock(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
