import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/communities/data/models/community_models.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/search/data/models/discovery_models.dart';
import 'package:client/features/search/data/repositories/discovery_repository.dart';
import 'package:client/features/search/presentation/notifiers/discover_notifier.dart';

class MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

// ─── Fixtures ─────────────────────────────────────────────────────────────────

const _userA = UserModel(id: 'u-1', username: 'creator_a', email: 'a@test.com');
const _userB = UserModel(id: 'u-2', username: 'creator_b', email: 'b@test.com');

final _discoverUserA = DiscoverUserModel(
  user: _userA,
  isFollowing: false,
  mutualInterestCount: 2,
  sharedInterests: ['Gaming', 'Music'],
);
final _discoverUserB = DiscoverUserModel(
  user: _userB,
  isFollowing: true,
);

const _community = CommunityModel(
  id: 'c-1',
  ownerId: 'u-1',
  name: 'Pixel Masters',
  slug: 'pixel-masters',
);
final _discoverCommunity = DiscoverCommunityModel(
  community: _community,
  isJoined: false,
);

const _post = PostModel(
  id: 'p-1',
  author: PostAuthorModel(id: 'u-1', username: 'creator_a'),
  title: 'Discover post',
  likeCount: 5,
  saveCount: 2,
  commentCount: 1,
  shareCount: 0,
  isLiked: false,
  isSaved: false,
);

DiscoveryPage<T> _page<T>(List<T> items, {bool hasMore = false}) =>
    DiscoveryPage<T>(
      items: items,
      total: hasMore ? 100 : items.length,
      limit: 10,
      offset: 0,
    );

// Notifier uses repository.getDiscoverPosts/Users/Communities without offset in initial call.
void _stubSuccess(
  MockDiscoveryRepository repo, {
  List<PostModel> posts = const [],
  List<DiscoverUserModel> users = const [],
  List<DiscoverCommunityModel> communities = const [],
  bool morePosts = false,
}) {
  when(
    () => repo.getDiscoverPosts(limit: 10),
  ).thenAnswer((_) async => _page(posts, hasMore: morePosts));
  when(
    () => repo.getRecommendedUsers(),
  ).thenAnswer((_) async => _page(users));
  when(
    () => repo.getRecommendedCommunities(),
  ).thenAnswer((_) async => _page(communities));
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late MockDiscoveryRepository mockRepo;

  setUp(() => mockRepo = MockDiscoveryRepository());

  group('DiscoverNotifier', () {
    // ── loadInitial ─────────────────────────────────────────────────────────

    test('loadInitial loads posts, users, and communities on success',
        () async {
      _stubSuccess(
        mockRepo,
        posts: [_post],
        users: [_discoverUserA],
        communities: [_discoverCommunity],
      );

      final notifier = DiscoverNotifier(repository: mockRepo);
      await pumpEventQueue();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.posts.length, 1);
      expect(notifier.state.users.length, 1);
      expect(notifier.state.communities.length, 1);
      expect(notifier.state.errorMessage, isNull);
    });

    test('loadInitial sets errorMessage when posts request throws', () async {
      when(
        () => mockRepo.getDiscoverPosts(limit: 10),
      ).thenThrow(const NetworkException(message: 'No network'));
      when(
        () => mockRepo.getRecommendedUsers(),
      ).thenAnswer((_) async => _page([]));
      when(
        () => mockRepo.getRecommendedCommunities(),
      ).thenAnswer((_) async => _page([]));

      final notifier = DiscoverNotifier(repository: mockRepo);
      await pumpEventQueue();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, isNotNull);
    });

    // ── loadMorePosts ───────────────────────────────────────────────────────

    test('loadMorePosts appends posts and updates hasMore', () async {
      const post2 = PostModel(
        id: 'p-2',
        author: PostAuthorModel(id: 'u-1', username: 'creator_a'),
        title: 'Second post',
      );
      _stubSuccess(mockRepo, posts: [_post], morePosts: true);

      final notifier = DiscoverNotifier(repository: mockRepo);
      await pumpEventQueue();
      expect(notifier.state.hasMorePosts, isTrue);

      when(
        () => mockRepo.getDiscoverPosts(limit: 10, offset: 1),
      ).thenAnswer((_) async => _page([post2]));

      await notifier.loadMorePosts();

      expect(notifier.state.posts.length, 2);
      expect(notifier.state.posts.last.id, 'p-2');
      expect(notifier.state.hasMorePosts, isFalse);
    });

    test('loadMorePosts is a no-op when hasMorePosts is false', () async {
      _stubSuccess(mockRepo, posts: [_post]);

      final notifier = DiscoverNotifier(repository: mockRepo);
      await pumpEventQueue();
      expect(notifier.state.hasMorePosts, isFalse);

      await notifier.loadMorePosts();

      verifyNever(() => mockRepo.getDiscoverPosts(limit: 10, offset: 1));
    });

    // ── toggleFollow ────────────────────────────────────────────────────────

    test('toggleFollow follows user optimistically', () async {
      _stubSuccess(mockRepo, users: [_discoverUserA]);
      when(() => mockRepo.followUser('u-1')).thenAnswer((_) async {});

      final notifier = DiscoverNotifier(repository: mockRepo);
      await pumpEventQueue();

      await notifier.toggleFollow('u-1');

      expect(notifier.state.users.first.isFollowing, isTrue);
      expect(notifier.state.pendingUserIds.contains('u-1'), isFalse);
      verify(() => mockRepo.followUser('u-1')).called(1);
    });

    test('toggleFollow reverts on API error', () async {
      _stubSuccess(mockRepo, users: [_discoverUserA]);
      when(() => mockRepo.followUser('u-1'))
          .thenThrow(const NetworkException(message: 'fail'));

      final notifier = DiscoverNotifier(repository: mockRepo);
      await pumpEventQueue();

      await notifier.toggleFollow('u-1');

      expect(notifier.state.users.first.isFollowing, isFalse);
      expect(notifier.state.pendingUserIds.contains('u-1'), isFalse);
      expect(notifier.state.errorMessage, isNotNull);
    });

    test('toggleFollow unfollows when already following', () async {
      _stubSuccess(mockRepo, users: [_discoverUserB]);
      when(() => mockRepo.unfollowUser('u-2')).thenAnswer((_) async {});

      final notifier = DiscoverNotifier(repository: mockRepo);
      await pumpEventQueue();
      expect(notifier.state.users.first.isFollowing, isTrue);

      await notifier.toggleFollow('u-2');

      expect(notifier.state.users.first.isFollowing, isFalse);
      verify(() => mockRepo.unfollowUser('u-2')).called(1);
    });

    // ── toggleCommunity ─────────────────────────────────────────────────────

    test('toggleCommunity joins with optimistic update', () async {
      _stubSuccess(mockRepo, communities: [_discoverCommunity]);
      when(() => mockRepo.joinCommunity('c-1')).thenAnswer((_) async => false);

      final notifier = DiscoverNotifier(repository: mockRepo);
      await pumpEventQueue();

      await notifier.toggleCommunity('c-1');

      expect(notifier.state.communities.first.isJoined, isTrue);
      verify(() => mockRepo.joinCommunity('c-1')).called(1);
    });

    test('toggleCommunity reverts on API error', () async {
      _stubSuccess(mockRepo, communities: [_discoverCommunity]);
      when(() => mockRepo.joinCommunity('c-1'))
          .thenThrow(const NetworkException(message: 'fail'));

      final notifier = DiscoverNotifier(repository: mockRepo);
      await pumpEventQueue();

      await notifier.toggleCommunity('c-1');

      expect(notifier.state.communities.first.isJoined, isFalse);
      expect(notifier.state.errorMessage, isNotNull);
    });

    // ── toggleLike ──────────────────────────────────────────────────────────

    test('toggleLike performs optimistic like update', () async {
      _stubSuccess(mockRepo, posts: [_post]);
      when(() => mockRepo.likePost('p-1', like: true))
          .thenAnswer((_) async => true);

      final notifier = DiscoverNotifier(repository: mockRepo);
      await pumpEventQueue();

      await notifier.toggleLike('p-1');

      expect(notifier.state.posts.first.isLiked, isTrue);
      expect(notifier.state.posts.first.likeCount, 6);
    });

    test('toggleLike reverts on error', () async {
      _stubSuccess(mockRepo, posts: [_post]);
      when(() => mockRepo.likePost('p-1', like: true))
          .thenThrow(const NetworkException(message: 'fail'));

      final notifier = DiscoverNotifier(repository: mockRepo);
      await pumpEventQueue();

      await notifier.toggleLike('p-1');

      expect(notifier.state.posts.first.isLiked, isFalse);
      expect(notifier.state.posts.first.likeCount, 5);
    });

    // ── toggleSave ──────────────────────────────────────────────────────────

    test('toggleSave performs optimistic save update', () async {
      _stubSuccess(mockRepo, posts: [_post]);
      when(() => mockRepo.savePost('p-1', save: true))
          .thenAnswer((_) async => true);

      final notifier = DiscoverNotifier(repository: mockRepo);
      await pumpEventQueue();

      await notifier.toggleSave('p-1');

      expect(notifier.state.posts.first.isSaved, isTrue);
      expect(notifier.state.posts.first.saveCount, 3);
    });

    // ── refresh ─────────────────────────────────────────────────────────────

    test('refresh replaces data without full loading state', () async {
      const updatedPost = PostModel(
        id: 'p-refreshed',
        author: PostAuthorModel(id: 'u-1', username: 'creator_a'),
        title: 'Refreshed post',
      );
      _stubSuccess(mockRepo, posts: [_post]);

      final notifier = DiscoverNotifier(repository: mockRepo);
      await pumpEventQueue();

      // Re-stub for refresh call
      when(
        () => mockRepo.getDiscoverPosts(limit: 10),
      ).thenAnswer((_) async => _page([updatedPost]));
      when(
        () => mockRepo.getRecommendedUsers(),
      ).thenAnswer((_) async => _page([]));
      when(
        () => mockRepo.getRecommendedCommunities(),
      ).thenAnswer((_) async => _page([]));

      await notifier.refresh();

      expect(notifier.state.posts.first.id, 'p-refreshed');
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.isRefreshing, isFalse);
    });
  });
}
