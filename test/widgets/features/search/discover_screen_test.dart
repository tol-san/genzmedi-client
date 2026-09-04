import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/features/communities/data/models/community_models.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/search/data/models/discovery_models.dart';
import 'package:client/features/search/data/repositories/discovery_repository.dart';
import 'package:client/features/search/presentation/screens/discover_screen.dart';

class MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

// ─── Fixtures ─────────────────────────────────────────────────────────────────

const _user = UserModel(id: 'u-1', username: 'creator_x', email: 'x@test.com');
final _discoverUser = DiscoverUserModel(
  user: _user,
  sharedInterests: ['Gaming'],
);
const _community = CommunityModel(
  id: 'c-1',
  ownerId: 'u-1',
  name: 'Pixel Nation',
  slug: 'pixel-nation',
  memberCount: 240,
);
final _discoverCommunity = DiscoverCommunityModel(
  community: _community,
  isMatchedInterest: true,
  interestName: 'Gaming',
);
const _post = PostModel(
  id: 'p-1',
  author: PostAuthorModel(id: 'u-1', username: 'creator_x'),
  title: 'A great Discover post',
  content: 'Some interesting content here',
  likeCount: 20,
);

DiscoveryPage<T> _page<T>(List<T> items) =>
    DiscoveryPage<T>(items: items, total: items.length, limit: 10, offset: 0);

void _stubInitial(
  MockDiscoveryRepository repo, {
  List<PostModel> posts = const [],
  List<DiscoverUserModel> users = const [],
  List<DiscoverCommunityModel> communities = const [],
}) {
  when(() => repo.getDiscoverPosts(limit: 10))
      .thenAnswer((_) async => _page(posts));
  when(() => repo.getRecommendedUsers()).thenAnswer((_) async => _page(users));
  when(() => repo.getRecommendedCommunities())
      .thenAnswer((_) async => _page(communities));
}

void main() {
  late MockDiscoveryRepository mockRepo;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    mockRepo = MockDiscoveryRepository();
  });

  Widget buildWidget() {
    return ProviderScope(
      overrides: [discoveryRepositoryProvider.overrideWithValue(mockRepo)],
      child: const MaterialApp(home: DiscoverScreen()),
    );
  }

  group('DiscoverScreen Widget Tests', () {
    testWidgets('shows loading skeleton while data is being fetched', (
      tester,
    ) async {
      final postCompleter = Completer<DiscoveryPage<PostModel>>();
      final userCompleter = Completer<DiscoveryPage<DiscoverUserModel>>();
      final commCompleter = Completer<DiscoveryPage<DiscoverCommunityModel>>();

      when(() => mockRepo.getDiscoverPosts(limit: 10))
          .thenAnswer((_) => postCompleter.future);
      when(() => mockRepo.getRecommendedUsers())
          .thenAnswer((_) => userCompleter.future);
      when(() => mockRepo.getRecommendedCommunities())
          .thenAnswer((_) => commCompleter.future);

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('shows Discover title in AppBar', (tester) async {
      _stubInitial(mockRepo);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Discover'), findsOneWidget);
    });

    testWidgets('renders a single simple search entry point', (tester) async {
      _stubInitial(mockRepo);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Search'), findsOneWidget);
      expect(find.text('Gaming'), findsNothing);
      expect(find.text('Find your next\nobsession'), findsNothing);
    });

    testWidgets('shows people after communities with shared-interest context', (
      tester,
    ) async {
      _stubInitial(mockRepo, users: [_discoverUser]);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('People with your interests'), findsOneWidget);
      expect(find.text('Gaming'), findsOneWidget);
    });

    testWidgets(
      'shows recommended communities as the primary discovery object',
      (tester) async {
        _stubInitial(mockRepo, communities: [_discoverCommunity]);

        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        expect(find.text('Communities for you'), findsOneWidget);
        expect(find.text('Pixel Nation'), findsOneWidget);
        expect(find.text('Gaming · 240 members'), findsOneWidget);
        expect(find.text('Join'), findsOneWidget);
      },
    );

    testWidgets(
      'renders trending interest-matched posts after recommendations',
      (tester) async {
        _stubInitial(mockRepo, posts: [_post]);

        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        expect(find.text('Trending for you'), findsOneWidget);
      },
    );

    testWidgets('orders communities before people and trending posts', (
      tester,
    ) async {
      _stubInitial(
        mockRepo,
        communities: [_discoverCommunity],
        users: [_discoverUser],
        posts: [_post],
      );

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      final communitiesY = tester
          .getTopLeft(find.text('Communities for you'))
          .dy;
      final peopleY = tester
          .getTopLeft(find.text('People with your interests'))
          .dy;
      final trendingY = tester.getTopLeft(find.text('Trending for you')).dy;

      expect(communitiesY, lessThan(peopleY));
      expect(peopleY, lessThan(trendingY));
    });

    testWidgets('join button starts the community membership flow', (
      tester,
    ) async {
      _stubInitial(mockRepo, communities: [_discoverCommunity]);
      when(() => mockRepo.joinCommunity('c-1')).thenAnswer((_) async => false);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Join'));
      await tester.pumpAndSettle();

      verify(() => mockRepo.joinCommunity('c-1')).called(1);
      expect(find.text('Joined'), findsOneWidget);
    });

    testWidgets('shows empty state for posts when no data and no error', (
      tester,
    ) async {
      _stubInitial(mockRepo);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Nothing to show yet.'), findsOneWidget);
    });

    testWidgets(
      'shows full error empty state when all data fails and lists are empty',
      (tester) async {
        when(() => mockRepo.getDiscoverPosts(limit: 10))
            .thenThrow(Exception('network error'));
        when(() => mockRepo.getRecommendedUsers())
            .thenAnswer((_) async => _page([]));
        when(() => mockRepo.getRecommendedCommunities())
            .thenAnswer((_) async => _page([]));

        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        expect(find.text('Discover is taking a break'), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
      },
    );

    testWidgets('follow button triggers toggleFollow on tap', (tester) async {
      _stubInitial(mockRepo, users: [_discoverUser]);
      when(() => mockRepo.followUser('u-1')).thenAnswer((_) async {});

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Follow'), findsOneWidget);
      await tester.ensureVisible(find.text('Follow'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Follow'));
      await tester.pumpAndSettle();

      verify(() => mockRepo.followUser('u-1')).called(1);
    });
  });
}
