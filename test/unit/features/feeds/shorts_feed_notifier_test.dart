import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/features/feeds/data/repositories/feed_repository.dart';
import 'package:client/features/feeds/presentation/notifiers/shorts_feed_notifier.dart';
import 'package:client/features/posts/data/models/post_models.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

void main() {
  late MockFeedRepository mockRepository;

  const mockShort1 = PostModel(
    id: 'short-1',
    author: PostAuthorModel(id: 'u-1', username: 'dancer_jane', displayName: 'Jane Dance'),
    postType: 'video',
    title: 'Dance Challenge #1',
    content: 'Check out this new move!',
    media: [
      MediaItemModel(id: 'm-1', mediaType: 'video', url: 'https://example.com/video1.mp4')
    ],
    likeCount: 500,
    saveCount: 40,
    commentCount: 65,
    isLiked: false,
    isSaved: false,
  );

  setUp(() {
    mockRepository = MockFeedRepository();
  });

  group('ShortsFeedNotifier Unit Tests', () {
    test('loads initial shorts items successfully', () async {
      when(() => mockRepository.getShortsFeed(limit: 20, offset: 0))
          .thenAnswer((_) async => [mockShort1]);

      final notifier = ShortsFeedNotifier(repository: mockRepository);
      await pumpEventQueue();

      expect(notifier.state.shorts.length, 1);
      expect(notifier.state.shorts.first.id, 'short-1');
      expect(notifier.state.activeIndex, 0);
      expect(notifier.state.isLoading, isFalse);
    });

    test('setActiveIndex updates current short index', () async {
      when(() => mockRepository.getShortsFeed(limit: 20, offset: 0))
          .thenAnswer((_) async => [mockShort1]);

      final notifier = ShortsFeedNotifier(repository: mockRepository);
      await pumpEventQueue();

      notifier.setActiveIndex(1);
      expect(notifier.state.activeIndex, 1);
    });

    test('toggleLike updates short like status optimistically', () async {
      when(() => mockRepository.getShortsFeed(limit: 20, offset: 0))
          .thenAnswer((_) async => [mockShort1]);
      when(() => mockRepository.likePost('short-1')).thenAnswer((_) async => true);

      final notifier = ShortsFeedNotifier(repository: mockRepository);
      await pumpEventQueue();

      await notifier.toggleLike('short-1');

      expect(notifier.state.shorts.first.isLiked, isTrue);
      expect(notifier.state.shorts.first.likeCount, 501);
      verify(() => mockRepository.likePost('short-1')).called(1);
    });
  });
}
