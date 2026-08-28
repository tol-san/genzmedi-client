import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/auth/auth_state.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/profiles/data/models/relationship_model.dart';
import 'package:client/features/profiles/data/repositories/profile_repository.dart';
import 'package:client/features/profiles/presentation/screens/public_profile_screen.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository mockProfileRepository;

  const currentUser = UserModel(
    id: 'u-self',
    username: 'self_user',
    email: 'self@example.com',
  );

  const targetUser = UserModel(
    id: 'u-target',
    username: 'public_creator',
    email: 'public@example.com',
    displayName: 'Public Creator',
    bio: 'Creating public art & code',
    followersCount: 500,
    followingCount: 150,
    postCount: 3,
    interests: ['art', 'tech'],
  );

  const targetPost = PostModel(
    id: 'p-public-1',
    author: PostAuthorModel(id: 'u-target', username: 'public_creator'),
    content: 'Awesome public post content.',
  );

  const relationship = RelationshipModel(
    isFollowing: false,
    isFollowedBy: false,
    isBlocking: false,
    isBlockedBy: false,
  );

  setUp(() {
    mockProfileRepository = MockProfileRepository();
    when(() => mockProfileRepository.getPublicProfile('public_creator'))
        .thenAnswer((_) async => targetUser);
    when(() => mockProfileRepository.getRelationship('u-target'))
        .thenAnswer((_) async => relationship);
    when(() => mockProfileRepository.getUserPosts(authorId: 'u-target'))
        .thenAnswer((_) async => [targetPost]);
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(mockProfileRepository),
        authNotifierProvider.overrideWith(
          (ref) => AuthNotifierMock(const AuthAuthenticated(currentUser)),
        ),
      ],
      child: const MaterialApp(
        home: PublicProfileScreen(username: 'public_creator'),
      ),
    );
  }

  group('PublicProfileScreen Widget Tests', () {
    testWidgets('renders public profile header, stats, follow button, and posts', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('@public_creator'), findsOneWidget);
      expect(find.text('Public Creator'), findsOneWidget);
      expect(find.text('Creating public art & code'), findsOneWidget);

      expect(find.text('500'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);

      expect(find.text('Follow'), findsOneWidget);
      expect(find.text('#art'), findsOneWidget);
      expect(find.text('#tech'), findsOneWidget);

      expect(find.text('Awesome public post content.'), findsOneWidget);
    });

    testWidgets('renders Edit Profile button when viewing own profile', (tester) async {
      when(() => mockProfileRepository.getPublicProfile('self_user'))
          .thenAnswer((_) async => currentUser);
      when(() => mockProfileRepository.getRelationship('u-self'))
          .thenAnswer((_) async => const RelationshipModel());
      when(() => mockProfileRepository.getUserPosts(authorId: 'u-self'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileRepositoryProvider.overrideWithValue(mockProfileRepository),
            authNotifierProvider.overrideWith(
              (ref) => AuthNotifierMock(const AuthAuthenticated(currentUser)),
            ),
          ],
          child: const MaterialApp(
            home: PublicProfileScreen(username: 'self_user'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
    });

    testWidgets('opens report user sheet from overflow menu', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final overflowBtn = find.byIcon(Icons.more_vert_rounded);
      expect(overflowBtn, findsOneWidget);

      await tester.tap(overflowBtn);
      await tester.pumpAndSettle();

      final reportOption = find.text('Report User');
      expect(reportOption, findsOneWidget);

      await tester.tap(reportOption);
      await tester.pumpAndSettle();

      expect(find.text('Report @public_creator'), findsOneWidget);
      expect(find.text('Submit Report'), findsOneWidget);
    });
  });
}

class AuthNotifierMock extends StateNotifier<AuthState> implements AuthNotifier {
  AuthNotifierMock(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
