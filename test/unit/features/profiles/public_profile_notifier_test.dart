import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/profiles/data/models/relationship_model.dart';
import 'package:client/features/profiles/data/repositories/profile_repository.dart';
import 'package:client/features/profiles/presentation/notifiers/public_profile_notifier.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository mockRepository;

  const mockTargetUser = UserModel(
    id: 'u-target-123',
    username: 'creator_jane',
    email: 'jane@example.com',
    displayName: 'Jane Creator',
    bio: 'Digital artist & animator',
    followersCount: 100,
    followingCount: 20,
    postCount: 2,
  );

  const mockPost = PostModel(
    id: 'post-1',
    author: PostAuthorModel(id: 'u-target-123', username: 'creator_jane'),
    content: 'Latest artwork preview!',
  );

  const mockRelationship = RelationshipModel(
    isFollowing: false,
    isFollowedBy: false,
    isBlocking: false,
    isBlockedBy: false,
  );

  setUp(() {
    mockRepository = MockProfileRepository();
  });

  group('PublicProfileNotifier Unit Tests', () {
    test('initializes and loads user, relationship, and posts', () async {
      when(() => mockRepository.getPublicProfile('creator_jane'))
          .thenAnswer((_) async => mockTargetUser);
      when(() => mockRepository.getRelationship('u-target-123'))
          .thenAnswer((_) async => mockRelationship);
      when(() => mockRepository.getUserPosts(authorId: 'u-target-123'))
          .thenAnswer((_) async => [mockPost]);

      final notifier = PublicProfileNotifier(
        username: 'creator_jane',
        repository: mockRepository,
      );

      await pumpEventQueue();

      expect(notifier.state.user, mockTargetUser);
      expect(notifier.state.relationship.isFollowing, isFalse);
      expect(notifier.state.posts.length, 1);
      expect(notifier.state.isLoading, isFalse);
    });

    test('toggleFollow performs optimistic follow and updates state', () async {
      when(() => mockRepository.getPublicProfile('creator_jane'))
          .thenAnswer((_) async => mockTargetUser);
      when(() => mockRepository.getRelationship('u-target-123'))
          .thenAnswer((_) async => mockRelationship);
      when(() => mockRepository.getUserPosts(authorId: 'u-target-123'))
          .thenAnswer((_) async => [mockPost]);
      when(() => mockRepository.followUser('u-target-123')).thenAnswer((_) async => true);

      final notifier = PublicProfileNotifier(
        username: 'creator_jane',
        repository: mockRepository,
      );
      await pumpEventQueue();

      await notifier.toggleFollow();

      expect(notifier.state.relationship.isFollowing, isTrue);
      expect(notifier.state.user?.followersCount, 101);
      verify(() => mockRepository.followUser('u-target-123')).called(1);
    });

    test('toggleFollow reverts state when API call fails', () async {
      when(() => mockRepository.getPublicProfile('creator_jane'))
          .thenAnswer((_) async => mockTargetUser);
      when(() => mockRepository.getRelationship('u-target-123'))
          .thenAnswer((_) async => mockRelationship);
      when(() => mockRepository.getUserPosts(authorId: 'u-target-123'))
          .thenAnswer((_) async => [mockPost]);
      when(() => mockRepository.followUser('u-target-123'))
          .thenThrow(const NetworkException(message: 'Network error'));

      final notifier = PublicProfileNotifier(
        username: 'creator_jane',
        repository: mockRepository,
      );
      await pumpEventQueue();

      await notifier.toggleFollow();

      expect(notifier.state.relationship.isFollowing, isFalse);
      expect(notifier.state.user?.followersCount, 100);
      expect(notifier.state.errorMessage, 'Network error');
    });

    test('toggleBlock updates blocking status', () async {
      when(() => mockRepository.getPublicProfile('creator_jane'))
          .thenAnswer((_) async => mockTargetUser);
      when(() => mockRepository.getRelationship('u-target-123'))
          .thenAnswer((_) async => mockRelationship);
      when(() => mockRepository.getUserPosts(authorId: 'u-target-123'))
          .thenAnswer((_) async => [mockPost]);
      when(() => mockRepository.blockUser('u-target-123')).thenAnswer((_) async => true);

      final notifier = PublicProfileNotifier(
        username: 'creator_jane',
        repository: mockRepository,
      );
      await pumpEventQueue();

      final success = await notifier.toggleBlock();

      expect(success, isTrue);
      expect(notifier.state.relationship.isBlocking, isTrue);
      verify(() => mockRepository.blockUser('u-target-123')).called(1);
    });
  });
}
