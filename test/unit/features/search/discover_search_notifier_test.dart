import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/communities/data/models/community_models.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/search/data/models/discovery_models.dart';
import 'package:client/features/search/data/repositories/discovery_repository.dart';
import 'package:client/features/search/presentation/notifiers/discover_search_notifier.dart';
import 'package:client/features/search/presentation/notifiers/discover_search_state.dart';

class MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

// ─── Fixtures ─────────────────────────────────────────────────────────────────

const _user1 = UserModel(id: 'u-1', username: 'neo', email: 'neo@test.com');
const _user2 = UserModel(id: 'u-2', username: 'trinity', email: 't@test.com');
final _discoverUser = DiscoverUserModel(user: _user1, isFollowing: false);
final _discoverUserFollowed = DiscoverUserModel(user: _user1, isFollowing: true);
final _discoverUser2 = DiscoverUserModel(user: _user2);

const _community = CommunityModel(
  id: 'c-1',
  ownerId: 'u-1',
  name: 'The Matrix',
  slug: 'matrix',
);
final _discoverCommunity = DiscoverCommunityModel(
  community: _community,
  isJoined: false,
);

const _post = PostModel(
  id: 'p-1',
  author: PostAuthorModel(id: 'u-1', username: 'neo'),
  title: 'Matrix drops',
  likeCount: 10,
);

const _interest = DiscoverInterestModel(
  id: 'i-1',
  name: 'Simulation Theory',
  slug: 'simulation-theory',
);

UnifiedDiscoverySearch _unified({
  List<DiscoverUserModel>? users,
  List<DiscoverCommunityModel>? communities,
  List<PostModel>? posts,
  List<DiscoverInterestModel>? interests,
  String query = 'q',
}) {
  return UnifiedDiscoverySearch(
    query: query,
    users: users ?? [],
    communities: communities ?? [],
    posts: posts ?? [],
    interests: interests ?? [],
    totalResults: (users?.length ?? 0) +
        (communities?.length ?? 0) +
        (posts?.length ?? 0) +
        (interests?.length ?? 0),
  );
}

DiscoveryPage<T> _page<T>(List<T> items, {bool hasMore = false}) =>
    DiscoveryPage<T>(
      items: items,
      total: hasMore ? 100 : items.length,
      limit: 20,
      offset: 0,
    );

/// Creates a fresh notifier backed by the given mock repo.
DiscoverSearchNotifier _make(MockDiscoveryRepository repo, {String q = ''}) =>
    DiscoverSearchNotifier(repository: repo, initialQuery: q);

/// Stubs searchAll for query [q] to return [result].
void _stubSearchAll(
  MockDiscoveryRepository repo,
  String q,
  UnifiedDiscoverySearch result,
) {
  when(() => repo.searchAll(q)).thenAnswer((_) async => result);
}

/// Stubs searchCategory for query [q] and [cat], no offset.
void _stubCategoryFirst(
  MockDiscoveryRepository repo,
  String q,
  DiscoverSearchCategory cat,
  DiscoveryPage<dynamic> page,
) {
  when(
    () => repo.searchCategory(q, cat, limit: 20),
  ).thenAnswer((_) async => page);
}

/// Stubs searchCategory for query [q] and [cat] with explicit offset.
void _stubCategoryNext(
  MockDiscoveryRepository repo,
  String q,
  DiscoverSearchCategory cat,
  int offset,
  DiscoveryPage<dynamic> page,
) {
  when(
    () => repo.searchCategory(q, cat, limit: 20, offset: offset),
  ).thenAnswer((_) async => page);
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late MockDiscoveryRepository mockRepo;

  setUpAll(() {
    // Required so mocktail can use any() for DiscoverSearchCategory in verifyNever
    registerFallbackValue(DiscoverSearchCategory.all);
  });

  setUp(() => mockRepo = MockDiscoveryRepository());

  group('DiscoverSearchNotifier', () {
    // ── Initial state ───────────────────────────────────────────────────────

    test('starts with empty state when initialQuery is empty', () async {
      final notifier = _make(mockRepo);
      await pumpEventQueue();
      expect(notifier.state.query, isEmpty);
      expect(notifier.state.isEmpty, isTrue);
      expect(notifier.state.isLoading, isFalse);
    });

    test('auto-searches when initialQuery is non-empty', () async {
      _stubSearchAll(
        mockRepo,
        'matrix',
        _unified(users: [_discoverUser], query: 'matrix'),
      );

      final notifier = _make(mockRepo, q: 'matrix');
      await pumpEventQueue();

      expect(notifier.state.users, isNotEmpty);
      expect(notifier.state.isLoading, isFalse);
    });

    // ── updateQuery ─────────────────────────────────────────────────────────

    test('updateQuery triggers unified search and populates state', () async {
      _stubSearchAll(
        mockRepo,
        'neo',
        _unified(
          query: 'neo',
          users: [_discoverUser],
          posts: [_post],
          interests: [_interest],
        ),
      );

      final notifier = _make(mockRepo);
      await notifier.updateQuery('neo');

      expect(notifier.state.query, 'neo');
      expect(notifier.state.users.length, 1);
      expect(notifier.state.posts.length, 1);
      expect(notifier.state.interests.length, 1);
      expect(notifier.state.isLoading, isFalse);
    });

    test('updateQuery with empty string resets state', () async {
      _stubSearchAll(mockRepo, 'neo', _unified(users: [_discoverUser], query: 'neo'));

      final notifier = _make(mockRepo);
      await notifier.updateQuery('neo');
      expect(notifier.state.isEmpty, isFalse);

      await notifier.updateQuery('');

      expect(notifier.state.query, isEmpty);
      expect(notifier.state.isEmpty, isTrue);
    });

    test('updateQuery is a no-op when query matches current', () async {
      _stubSearchAll(mockRepo, 'neo', _unified(users: [_discoverUser], query: 'neo'));

      final notifier = _make(mockRepo);
      await notifier.updateQuery('neo');
      clearInteractions(mockRepo);

      // Same query → should NOT trigger another search
      await notifier.updateQuery('neo');

      verifyNever(() => mockRepo.searchAll(any()));
    });

    // ── setCategory ─────────────────────────────────────────────────────────

    test('setCategory to users fetches paginated user results', () async {
      _stubCategoryFirst(
        mockRepo,
        'neo',
        DiscoverSearchCategory.users,
        _page([_discoverUser]),
      );

      final notifier = _make(mockRepo);
      notifier.state = notifier.state.copyWith(query: 'neo');
      await notifier.setCategory(DiscoverSearchCategory.users);

      expect(notifier.state.category, DiscoverSearchCategory.users);
      expect(notifier.state.users.length, 1);
      expect(notifier.state.isLoading, isFalse);
    });

    test('setCategory to communities fetches paginated community results',
        () async {
      _stubCategoryFirst(
        mockRepo,
        'matrix',
        DiscoverSearchCategory.communities,
        _page([_discoverCommunity]),
      );

      final notifier = _make(mockRepo);
      notifier.state = notifier.state.copyWith(query: 'matrix');
      await notifier.setCategory(DiscoverSearchCategory.communities);

      expect(notifier.state.communities.length, 1);
    });

    test('setCategory same category is no-op', () async {
      final notifier = _make(mockRepo);
      // Default category is 'all'; calling setCategory(all) is a no-op.
      await notifier.setCategory(DiscoverSearchCategory.all);

      verifyZeroInteractions(mockRepo);
    });

    // ── loadMore ────────────────────────────────────────────────────────────

    test('loadMore appends results for users category', () async {
      _stubCategoryFirst(
        mockRepo,
        'neo',
        DiscoverSearchCategory.users,
        _page([_discoverUser], hasMore: true),
      );
      _stubCategoryNext(
        mockRepo,
        'neo',
        DiscoverSearchCategory.users,
        1,
        _page([_discoverUser2]),
      );

      final notifier = _make(mockRepo);
      notifier.state = notifier.state.copyWith(query: 'neo');
      await notifier.setCategory(DiscoverSearchCategory.users);
      expect(notifier.state.hasMore, isTrue);

      await notifier.loadMore();

      expect(notifier.state.users.length, 2);
      expect(notifier.state.users.last.user.id, 'u-2');
    });

    test('loadMore is no-op when category is "all"', () async {
      final notifier = _make(mockRepo);
      notifier.state = notifier.state.copyWith(
        query: 'neo',
        hasMore: true,
      );
      // Category stays 'all' (default) → loadMore returns early
      await notifier.loadMore();

      verifyZeroInteractions(mockRepo);
    });

    test('loadMore sets error on failure', () async {
      _stubCategoryFirst(
        mockRepo,
        'neo',
        DiscoverSearchCategory.posts,
        _page([_post], hasMore: true),
      );
      _stubCategoryNext(
        mockRepo,
        'neo',
        DiscoverSearchCategory.posts,
        1,
        // Will throw instead
        _page([]),
      );
      when(
        () => mockRepo.searchCategory(
          'neo',
          DiscoverSearchCategory.posts,
          limit: 20,
          offset: 1,
        ),
      ).thenThrow(const NetworkException(message: 'timeout'));

      final notifier = _make(mockRepo);
      notifier.state = notifier.state.copyWith(query: 'neo');
      await notifier.setCategory(DiscoverSearchCategory.posts);

      await notifier.loadMore();

      expect(notifier.state.errorMessage, isNotNull);
      expect(notifier.state.isLoadingMore, isFalse);
    });

    // ── search error ────────────────────────────────────────────────────────

    test('search sets errorMessage on API failure', () async {
      when(() => mockRepo.searchAll('bad'))
          .thenThrow(const NetworkException(message: 'Server error'));

      final notifier = _make(mockRepo);
      await notifier.updateQuery('bad');

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, contains('Server error'));
    });

    // ── toggleFollow in search ──────────────────────────────────────────────

    test('toggleFollow in search optimistically updates user', () async {
      _stubSearchAll(mockRepo, 'neo', _unified(users: [_discoverUser], query: 'neo'));
      when(() => mockRepo.followUser('u-1')).thenAnswer((_) async {});

      final notifier = _make(mockRepo);
      await notifier.updateQuery('neo');
      expect(notifier.state.users, isNotEmpty);

      await notifier.toggleFollow('u-1');

      expect(notifier.state.users.first.isFollowing, isTrue);
      expect(notifier.state.pendingUserIds.contains('u-1'), isFalse);
    });

    test('toggleFollow in search reverts on error', () async {
      _stubSearchAll(mockRepo, 'neo', _unified(users: [_discoverUser], query: 'neo'));
      when(() => mockRepo.followUser('u-1'))
          .thenThrow(const NetworkException(message: 'fail'));

      final notifier = _make(mockRepo);
      await notifier.updateQuery('neo');
      expect(notifier.state.users, isNotEmpty);

      await notifier.toggleFollow('u-1');

      expect(notifier.state.users.first.isFollowing, isFalse);
      expect(notifier.state.errorMessage, isNotNull);
    });

    // ── toggleCommunity in search ───────────────────────────────────────────

    test('toggleCommunity in search joins community optimistically', () async {
      _stubSearchAll(
        mockRepo,
        'matrix',
        _unified(communities: [_discoverCommunity], query: 'matrix'),
      );
      when(() => mockRepo.joinCommunity('c-1')).thenAnswer((_) async => false);

      final notifier = _make(mockRepo);
      await notifier.updateQuery('matrix');
      expect(notifier.state.communities, isNotEmpty);

      await notifier.toggleCommunity('c-1');

      expect(notifier.state.communities.first.isJoined, isTrue);
      verify(() => mockRepo.joinCommunity('c-1')).called(1);
    });

    // ── activeCount ─────────────────────────────────────────────────────────

    test('activeCount returns totalResults for all category', () {
      const state = DiscoverSearchState(
        query: 'test',
        category: DiscoverSearchCategory.all,
        totalResults: 15,
      );
      expect(state.activeCount, 15);
    });

    test('activeCount returns users.length for users category', () {
      final state = DiscoverSearchState(
        query: 'test',
        category: DiscoverSearchCategory.users,
        users: [_discoverUser, _discoverUserFollowed],
      );
      expect(state.activeCount, 2);
    });
  });
}
