import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/profiles/data/repositories/profile_repository.dart';
import 'package:client/features/profiles/presentation/notifiers/my_profile_notifier.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository mockRepository;

  const mockUser = UserModel(
    id: 'u-123',
    username: 'alex_cool',
    email: 'alex@example.com',
    displayName: 'Alex Cool',
    bio: 'Flutter builder & GenZ designer',
    followersCount: 150,
    followingCount: 30,
    postCount: 5,
    interests: ['gaming', 'music'],
  );

  const mockPost = PostModel(
    id: 'p-1',
    author: PostAuthorModel(id: 'u-123', username: 'alex_cool'),
    postType: 'text',
    title: 'Hello GenZ!',
    content: 'First post on the platform.',
  );

  const mockSavedPost = PostModel(
    id: 'p-saved-1',
    author: PostAuthorModel(id: 'u-456', username: 'other_user'),
    postType: 'text',
    content: 'Interesting thought.',
  );

  setUp(() {
    mockRepository = MockProfileRepository();
  });

  group('MyProfileNotifier Unit Tests', () {
    test('initializes and loads profile, posts, and saved posts automatically', () async {
      when(() => mockRepository.getMyProfile()).thenAnswer((_) async => mockUser);
      when(() => mockRepository.getUserPosts(authorId: 'u-123')).thenAnswer((_) async => [mockPost]);
      when(() => mockRepository.getSavedPosts()).thenAnswer((_) async => [mockSavedPost]);

      final notifier = MyProfileNotifier(repository: mockRepository);

      // Await async microtasks triggered during constructor
      await pumpEventQueue();

      expect(notifier.state.user, mockUser);
      expect(notifier.state.posts.length, 1);
      expect(notifier.state.posts.first.id, 'p-1');
      expect(notifier.state.savedPosts.length, 1);
      expect(notifier.state.savedPosts.first.id, 'p-saved-1');
      expect(notifier.state.isLoadingProfile, isFalse);
    });

    test('refreshProfile updates user and posts while toggling isRefreshing', () async {
      when(() => mockRepository.getMyProfile()).thenAnswer((_) async => mockUser);
      when(() => mockRepository.getUserPosts(authorId: 'u-123')).thenAnswer((_) async => [mockPost]);
      when(() => mockRepository.getSavedPosts()).thenAnswer((_) async => [mockSavedPost]);

      final notifier = MyProfileNotifier(
        repository: mockRepository,
        initialUser: mockUser,
      );

      await notifier.refreshProfile();

      expect(notifier.state.user, mockUser);
      expect(notifier.state.isRefreshing, isFalse);
      expect(notifier.state.posts.length, 1);
    });

    test('sets errorMessage when getMyProfile fails', () async {
      when(() => mockRepository.getMyProfile()).thenThrow(
        const NetworkException(message: 'Connection timed out'),
      );
      when(() => mockRepository.getUserPosts(authorId: any(named: 'authorId')))
          .thenAnswer((_) async => []);
      when(() => mockRepository.getSavedPosts()).thenAnswer((_) async => []);

      final notifier = MyProfileNotifier(repository: mockRepository);

      await pumpEventQueue();

      expect(notifier.state.errorMessage, 'Connection timed out');
      expect(notifier.state.isLoadingProfile, isFalse);
    });

    test('loadSavedPosts populates savedPosts and sets hasMoreSaved', () async {
      final twentyPosts = List.generate(
        20,
        (i) => PostModel(
          id: 'p-saved-$i',
          author: const PostAuthorModel(id: 'u-1', username: 'author'),
          content: 'Saved post #$i',
        ),
      );

      when(
        () => mockRepository.getSavedPosts(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => twentyPosts);

      final notifier = MyProfileNotifier(
        repository: mockRepository,
        initialUser: mockUser,
      );
      await notifier.loadSavedPosts();

      expect(notifier.state.savedPosts.length, 20);
      expect(notifier.state.hasMoreSaved, isTrue);
      expect(notifier.state.isLoadingSaved, isFalse);
    });

    test('loadMoreSavedPosts appends posts to existing savedPosts', () async {
      final firstBatch = List.generate(
        20,
        (i) => PostModel(
          id: 'p-saved-$i',
          author: const PostAuthorModel(id: 'u-1', username: 'author'),
          content: 'Saved post #$i',
        ),
      );

      final secondBatch = [
        const PostModel(
          id: 'p-saved-21',
          author: PostAuthorModel(id: 'u-1', username: 'author'),
          content: 'Saved post #21',
        ),
      ];

      when(
        () => mockRepository.getSavedPosts(limit: 20, offset: 0),
      ).thenAnswer((_) async => firstBatch);
      when(
        () => mockRepository.getSavedPosts(limit: 20, offset: 20),
      ).thenAnswer((_) async => secondBatch);

      final notifier = MyProfileNotifier(
        repository: mockRepository,
        initialUser: mockUser,
      );
      await notifier.loadSavedPosts();
      expect(notifier.state.savedPosts.length, 20);

      await notifier.loadMoreSavedPosts();
      expect(notifier.state.savedPosts.length, 21);
      expect(notifier.state.hasMoreSaved, isFalse);
      expect(notifier.state.isLoadingMoreSaved, isFalse);
    });

    test('removeSavedPost removes the target post immediately', () async {
      when(
        () => mockRepository.getSavedPosts(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => [mockSavedPost]);

      final notifier = MyProfileNotifier(
        repository: mockRepository,
        initialUser: mockUser,
      );
      await notifier.loadSavedPosts();
      expect(notifier.state.savedPosts.length, 1);

      notifier.removeSavedPost('p-saved-1');
      expect(notifier.state.savedPosts.isEmpty, isTrue);
    });

    test('updateSavedPost evicts post when isSaved becomes false', () async {
      when(
        () => mockRepository.getSavedPosts(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => [mockSavedPost]);

      final notifier = MyProfileNotifier(
        repository: mockRepository,
        initialUser: mockUser,
      );
      await notifier.loadSavedPosts();
      expect(notifier.state.savedPosts.length, 1);

      notifier.updateSavedPost(mockSavedPost.copyWith(isSaved: false));
      expect(notifier.state.savedPosts.isEmpty, isTrue);
    });

    test('sets savedErrorMessage when loadSavedPosts fails', () async {
      when(
        () => mockRepository.getSavedPosts(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenThrow(const ApiException(message: 'Server failed', statusCode: 500));

      final notifier = MyProfileNotifier(
        repository: mockRepository,
        initialUser: mockUser,
      );
      await notifier.loadSavedPosts();

      expect(notifier.state.savedErrorMessage, 'Server failed');
      expect(notifier.state.isLoadingSaved, isFalse);
    });
  });
}
