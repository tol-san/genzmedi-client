import 'dart:async';

import 'package:client/features/communities/data/models/community_models.dart';
import 'package:client/features/search/data/models/discovery_models.dart';
import 'package:client/features/search/data/repositories/discovery_repository.dart';
import 'package:client/features/search/presentation/screens/discover_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

class MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

const _gaming = DiscoverInterestModel(
  id: 'i-gaming',
  name: 'Gaming',
  slug: 'gaming',
);
const _sports = DiscoverInterestModel(
  id: 'i-sports',
  name: 'Sports',
  slug: 'sports',
);

DiscoverCommunityModel _community(
  String id,
  String name,
  String interestId,
  String interestName, {
  bool joined = false,
}) {
  return DiscoverCommunityModel(
    community: CommunityModel(
      id: id,
      ownerId: 'owner',
      interestId: interestId,
      name: name,
      slug: name.toLowerCase().replaceAll(' ', '-'),
      memberCount: 142000,
    ),
    interestName: interestName,
    isMatchedInterest: true,
    isJoined: joined,
  );
}

final _recommended = [
  _community('c-1', 'Creator Culture', 'i-gaming', 'Gaming'),
  _community('c-2', 'Football Fans', 'i-sports', 'Sports'),
  _community('c-3', 'Gaming Arena', 'i-gaming', 'Gaming'),
  _community('c-4', 'Anime World', 'i-gaming', 'Gaming'),
  _community('c-5', 'K-pop Central', 'i-sports', 'Sports'),
];

DiscoveryPage<T> _page<T>(List<T> items) =>
    DiscoveryPage<T>(items: items, total: items.length, limit: 20, offset: 0);

void _stubInitial(
  MockDiscoveryRepository repo, {
  List<DiscoverCommunityModel>? recommended,
  List<DiscoverCommunityModel> joined = const [],
  List<DiscoverInterestModel> interests = const [_gaming, _sports],
}) {
  when(() => repo.getRecommendedCommunities(limit: 20))
      .thenAnswer((_) async => _page(recommended ?? _recommended));
  when(() => repo.getJoinedCommunities(limit: 20))
      .thenAnswer((_) async => _page(joined));
  when(() => repo.getInterests()).thenAnswer((_) async => interests);
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

  group('DiscoverScreen community discovery', () {
    testWidgets('shows loading skeleton while community data is loading', (
      tester,
    ) async {
      final recommended = Completer<DiscoveryPage<DiscoverCommunityModel>>();
      final joined = Completer<DiscoveryPage<DiscoverCommunityModel>>();
      final interests = Completer<List<DiscoverInterestModel>>();
      when(() => mockRepo.getRecommendedCommunities(limit: 20))
          .thenAnswer((_) => recommended.future);
      when(() => mockRepo.getJoinedCommunities(limit: 20))
          .thenAnswer((_) => joined.future);
      when(() => mockRepo.getInterests()).thenAnswer((_) => interests.future);

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Featured for you'), findsNothing);
    });

    testWidgets('matches the community hierarchy from the reference', (
      tester,
    ) async {
      _stubInitial(mockRepo);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(TextField, 'Search communities'),
        findsOneWidget,
      );
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Sports'), findsWidgets);
      expect(find.text('Gaming'), findsWidgets);
      expect(find.text('Featured for you'), findsOneWidget);
      expect(find.text('More communities'), findsOneWidget);
      expect(find.text('Creator Culture'), findsOneWidget);
      expect(find.text('Anime World'), findsOneWidget);
      expect(find.text('People with your interests'), findsNothing);
      expect(find.text('Posts for you'), findsNothing);
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('interest chips filter featured and grid communities', (
      tester,
    ) async {
      _stubInitial(mockRepo);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sports').first);
      await tester.pumpAndSettle();

      expect(find.text('Football Fans'), findsOneWidget);
      expect(find.text('K-pop Central'), findsOneWidget);
      expect(find.text('Creator Culture'), findsNothing);
    });

    testWidgets('join button uses the real community membership flow', (
      tester,
    ) async {
      _stubInitial(mockRepo);
      when(() => mockRepo.joinCommunity('c-1')).thenAnswer((_) async => false);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Join').first);
      await tester.pumpAndSettle();

      verify(() => mockRepo.joinCommunity('c-1')).called(1);
      expect(find.text('Joined'), findsOneWidget);
    });

    testWidgets('shows joined communities when recommendations are empty', (
      tester,
    ) async {
      final joined = _community(
        'joined-1',
        'My Gaming Community',
        'i-gaming',
        'Gaming',
        joined: true,
      );
      _stubInitial(mockRepo, recommended: const [], joined: [joined]);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('My Gaming Community'), findsOneWidget);
      expect(find.text('Joined'), findsOneWidget);
    });

    testWidgets('shows retry state when community loading fails', (
      tester,
    ) async {
      when(() => mockRepo.getRecommendedCommunities(limit: 20))
          .thenThrow(Exception('network error'));
      when(() => mockRepo.getJoinedCommunities(limit: 20))
          .thenAnswer((_) async => _page([]));
      when(() => mockRepo.getInterests()).thenAnswer((_) async => const []);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Communities are taking a break'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('matches the community discovery visual baseline', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393, 650);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      _stubInitial(mockRepo);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(DiscoverScreen),
        matchesGoldenFile('goldens/discover_communities.png'),
      );
    });
  });
}
