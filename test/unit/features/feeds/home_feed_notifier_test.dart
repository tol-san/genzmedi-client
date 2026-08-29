import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/feeds/data/repositories/feed_repository.dart';
import 'package:client/features/feeds/presentation/notifiers/home_feed_notifier.dart';
import 'package:client/features/posts/data/models/post_models.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

void main() {
  late MockFeedRepository mockRepository;

  const mockPost1 = PostModel(
    id: 'post-101',
    author: PostAuthorModel(id: 'u-1', username: 'creator_one', displayName: 'Creator One'),
    title: 'First Home Post',
    content: 'Loving the new social network!',
    likeCount: 10,
    saveCount: 2,
    commentCount: 4,
    shareCount: 1,
    isLiked: false,
    isSaved: false,
  );

  const mockPost2 = PostModel(
    id: 'post-102',
    author: PostAuthorModel(id: 'u-2', username: 'creator_two', displayName: 'Creator Two'),
    title: 'Second Home Post',
    content: 'Building in public with Flutter & FastAPI.',
    likeCount: 25,
    saveCount: 5,
    commentCount: 8,
    shareCount: 3,
    isLiked: true,
    isSaved: true,
  );

  setUp(() {
    mockRepository = MockFeedRepository();
  });

  group('HomeFeedNotifier Unit Tests', () {
    test('loads initial home feed items successfully', () async {
      when(() => mockRepository.getHomeFeed(limit: 20, offset: 0))
          .thenAnswer((_) async => [mockPost1, mockPost2]);

      final notifier = HomeFeedNotifier(repository: mockRepository);
      await pumpEventQueue();

      expect(notifier.state.posts.length, 2);
      expect(notifier.state.posts.first.id, 'post-101');
      expect(notifier.state.isLoading, isFalse);
    });

    test('toggleLike performs optimistic update and calls repository', () async {
      when(() => mockRepository.getHomeFeed(limit: 20, offset: 0))
          .thenAnswer((_) async => [mockPost1]);
      when(() => mockRepository.likePost('post-101')).thenAnswer((_) async => true);

      final notifier = HomeFeedNotifier(repository: mockRepository);
      await pumpEventQueue();

      await notifier.toggleLike('post-101');

      expect(notifier.state.posts.first.isLiked, isTrue);
      expect(notifier.state.posts.first.likeCount, 11);
      verify(() => mockRepository.likePost('post-101')).called(1);
    });

    test('toggleSave performs optimistic update and calls repository', () async {
      when(() => mockRepository.getHomeFeed(limit: 20, offset: 0))
          .thenAnswer((_) async => [mockPost1]);
      when(() => mockRepository.savePost('post-101')).thenAnswer((_) async => true);

      final notifier = HomeFeedNotifier(repository: mockRepository);
      await pumpEventQueue();

      await notifier.toggleSave('post-101');

      expect(notifier.state.posts.first.isSaved, isTrue);
      expect(notifier.state.posts.first.saveCount, 3);
      verify(() => mockRepository.savePost('post-101')).called(1);
    });

    test('toggleLike reverts on API error', () async {
      when(() => mockRepository.getHomeFeed(limit: 20, offset: 0))
          .thenAnswer((_) async => [mockPost1]);
      when(() => mockRepository.likePost('post-101'))
          .thenThrow(const NetworkException(message: 'Failed to like'));

      final notifier = HomeFeedNotifier(repository: mockRepository);
      await pumpEventQueue();

      await notifier.toggleLike('post-101');

      expect(notifier.state.posts.first.isLiked, isFalse);
      expect(notifier.state.posts.first.likeCount, 10);
    });
  });
}
