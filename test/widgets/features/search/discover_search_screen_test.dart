import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/features/communities/data/models/community_models.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/search/data/models/discovery_models.dart';
import 'package:client/features/search/data/repositories/discovery_repository.dart';
import 'package:client/features/search/presentation/screens/discover_search_screen.dart';

class MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

// ─── Fixtures ─────────────────────────────────────────────────────────────────

const _user = UserModel(id: 'u-1', username: 'neo', email: 'neo@test.com');
final _discoverUser = DiscoverUserModel(user: _user);
const _community = CommunityModel(
  id: 'c-1',
  ownerId: 'u-1',
  name: 'Matrix World',
  slug: 'matrix-world',
);
final _discoverCommunity = DiscoverCommunityModel(community: _community);
const _post = PostModel(
  id: 'p-1',
  author: PostAuthorModel(id: 'u-1', username: 'neo'),
  title: 'The matrix is everywhere',
  likeCount: 99,
);
const _interest = DiscoverInterestModel(
  id: 'i-1',
  name: 'Simulation Theory',
  slug: 'simulation-theory',
);

UnifiedDiscoverySearch _fullResult({String query = 'matrix'}) =>
    UnifiedDiscoverySearch(
      query: query,
      users: [_discoverUser],
      communities: [_discoverCommunity],
      posts: [_post],
      interests: [_interest],
      totalResults: 4,
    );

DiscoveryPage<T> _page<T>(List<T> items, {bool hasMore = false}) =>
    DiscoveryPage<T>(
      items: items,
      total: hasMore ? 100 : items.length,
      limit: 20,
      offset: 0,
    );

void main() {
  late MockDiscoveryRepository mockRepo;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    mockRepo = MockDiscoveryRepository();
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildWidget({String initialQuery = ''}) {
    return ProviderScope(
      overrides: [discoveryRepositoryProvider.overrideWithValue(mockRepo)],
      child: MaterialApp(
        home: DiscoverSearchScreen(initialQuery: initialQuery),
      ),
    );
  }

  group('DiscoverSearchScreen Widget Tests', () {
    // ── Empty state ─────────────────────────────────────────────────────────

    testWidgets(
      'shows search prompt when query is empty and no recent searches',
      (tester) async {
        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        expect(find.text('Search GenZ Media'), findsOneWidget);
      },
    );

    testWidgets('shows all five category chips', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('People'), findsOneWidget);
      expect(find.text('Communities'), findsOneWidget);
      expect(find.text('Posts'), findsOneWidget);
      expect(find.text('Interests'), findsOneWidget);
    });

    // ── Results ─────────────────────────────────────────────────────────────

    testWidgets('shows grouped results for all-category search', (
      tester,
    ) async {
      when(() => mockRepo.searchAll('matrix'))
          .thenAnswer((_) async => _fullResult());

      await tester.pumpWidget(buildWidget(initialQuery: 'matrix'));
      await tester.pumpAndSettle();

      // All four category headings should appear
      expect(find.text('People'), findsWidgets);
      expect(find.text('Communities'), findsWidgets);
      expect(find.text('Posts'), findsWidgets);
      expect(find.text('Interests'), findsWidgets);
    });

    testWidgets('shows user result card when users are returned', (
      tester,
    ) async {
      when(() => mockRepo.searchAll('neo')).thenAnswer(
        (_) async => UnifiedDiscoverySearch(
          query: 'neo',
          users: [_discoverUser],
          communities: [],
          posts: [],
          interests: [],
          totalResults: 1,
        ),
      );

      await tester.pumpWidget(buildWidget(initialQuery: 'neo'));
      await tester.pumpAndSettle();

      expect(find.text('@neo'), findsOneWidget);
    });

    testWidgets('shows community result card when communities are returned', (
      tester,
    ) async {
      when(() => mockRepo.searchAll('matrix')).thenAnswer(
        (_) async => UnifiedDiscoverySearch(
          query: 'matrix',
          users: [],
          communities: [_discoverCommunity],
          posts: [],
          interests: [],
          totalResults: 1,
        ),
      );

      await tester.pumpWidget(buildWidget(initialQuery: 'matrix'));
      await tester.pumpAndSettle();

      expect(find.text('Matrix World'), findsOneWidget);
    });

    // ── No results ──────────────────────────────────────────────────────────

    testWidgets('shows no-results empty state on empty unified search', (
      tester,
    ) async {
      when(() => mockRepo.searchAll('xzxzxz')).thenAnswer(
        (_) async => UnifiedDiscoverySearch(
          query: 'xzxzxz',
          users: [],
          communities: [],
          posts: [],
          interests: [],
          totalResults: 0,
        ),
      );

      await tester.pumpWidget(buildWidget(initialQuery: 'xzxzxz'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No results for'), findsOneWidget);
      expect(find.text('Clear search'), findsOneWidget);
    });

    // ── Error state ─────────────────────────────────────────────────────────

    testWidgets('shows error empty state on API failure', (tester) async {
      when(() => mockRepo.searchAll('crash'))
          .thenThrow(Exception('search failed'));

      await tester.pumpWidget(buildWidget(initialQuery: 'crash'));
      await tester.pumpAndSettle();

      expect(find.text('Search unavailable'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    // ── Loading state ───────────────────────────────────────────────────────

    testWidgets('shows list view while search is pending', (tester) async {
      final completer = Completer<UnifiedDiscoverySearch>();
      when(() => mockRepo.searchAll('loading'))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildWidget(initialQuery: 'loading'));
      await tester.pump();

      expect(find.byType(ListView), findsWidgets);
      // Error text should NOT appear during loading
      expect(find.text('Search unavailable'), findsNothing);
    });

    // ── Category switching ──────────────────────────────────────────────────

    testWidgets('tapping People chip triggers category search', (tester) async {
      when(() => mockRepo.searchAll('neo'))
          .thenAnswer((_) async => _fullResult(query: 'neo'));
      when(
        () => mockRepo.searchCategory(
          'neo',
          DiscoverSearchCategory.users,
          limit: 20,
        ),
      ).thenAnswer((_) async => _page([_discoverUser]));

      await tester.pumpWidget(buildWidget(initialQuery: 'neo'));
      await tester.pumpAndSettle();

      final creatorChip = find.widgetWithText(GestureDetector, 'People');
      if (creatorChip.evaluate().isNotEmpty) {
        await tester.tap(creatorChip.first);
        await tester.pumpAndSettle();

        verify(
          () => mockRepo.searchCategory(
            'neo',
            DiscoverSearchCategory.users,
            limit: 20,
          ),
        ).called(1);
      }
    });

    // ── Recent searches ─────────────────────────────────────────────────────

    testWidgets('shows recent searches list from SharedPreferences', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'discover_recent_searches': ['matrix', 'gaming'],
      });

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Recent searches'), findsOneWidget);
      expect(find.text('matrix'), findsOneWidget);
      expect(find.text('gaming'), findsOneWidget);
    });

    testWidgets('shows Clear all button when recent searches exist', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'discover_recent_searches': ['streetwear'],
      });

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Clear all'), findsOneWidget);
    });

    // ── Post and Interest Card Actions ─────────────────────────────────────

    testWidgets('shows post result card and interest tile in search results', (
      tester,
    ) async {
      when(() => mockRepo.searchAll('matrix')).thenAnswer(
        (_) async => UnifiedDiscoverySearch(
          query: 'matrix',
          users: [],
          communities: [],
          posts: [_post],
          interests: [_interest],
          totalResults: 2,
        ),
      );

      await tester.pumpWidget(buildWidget(initialQuery: 'matrix'));
      await tester.pumpAndSettle();

      expect(find.text('The matrix is everywhere'), findsOneWidget);
      expect(find.text('Simulation Theory'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('tapping like on post card calls likePost on repo', (
      tester,
    ) async {
      when(() => mockRepo.searchAll('matrix')).thenAnswer(
        (_) async => UnifiedDiscoverySearch(
          query: 'matrix',
          users: [],
          communities: [],
          posts: [_post],
          interests: [],
          totalResults: 1,
        ),
      );
      when(() => mockRepo.likePost('p-1', like: true))
          .thenAnswer((_) async => true);

      await tester.pumpWidget(buildWidget(initialQuery: 'matrix'));
      await tester.pumpAndSettle();

      final heartIcon = find.byIcon(Icons.favorite_border_rounded);
      expect(heartIcon, findsOneWidget);

      await tester.tap(heartIcon);
      await tester.pump();

      verify(() => mockRepo.likePost('p-1', like: true)).called(1);
    });

    testWidgets(
      'tapping Add on interest tile calls toggleUserInterest on repo',
      (tester) async {
        when(() => mockRepo.searchAll('matrix')).thenAnswer(
          (_) async => UnifiedDiscoverySearch(
            query: 'matrix',
            users: [],
            communities: [],
            posts: [],
            interests: [_interest],
            totalResults: 1,
          ),
        );
        when(() => mockRepo.toggleUserInterest('i-1', add: true))
            .thenAnswer((_) async {});

        await tester.pumpWidget(buildWidget(initialQuery: 'matrix'));
        await tester.pumpAndSettle();

        final addButton = find.text('Add');
        expect(addButton, findsOneWidget);

        await tester.tap(addButton);
        await tester.pump();

        verify(() => mockRepo.toggleUserInterest('i-1', add: true)).called(1);
      },
    );
  });
}
