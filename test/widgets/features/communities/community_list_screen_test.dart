import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/features/communities/data/models/community_models.dart';
import 'package:client/features/communities/data/repositories/community_repository.dart';
import 'package:client/features/communities/presentation/screens/community_list_screen.dart';

class MockCommunityRepository extends Mock implements CommunityRepository {}

void main() {
  late MockCommunityRepository mockRepository;

  const testCommunity = CommunityModel(
    id: 'comm-1',
    ownerId: 'owner-1',
    name: 'Indie Game Hub',
    slug: 'indie-game-hub',
    description: 'Showcase devlogs & demos',
    isPrivate: false,
    memberCount: 88,
  );

  setUp(() {
    mockRepository = MockCommunityRepository();
    when(() => mockRepository.listCommunities())
        .thenAnswer((_) async => [testCommunity]);
    when(() => mockRepository.getMyJoinedCommunities())
        .thenAnswer((_) async => []);
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        communityRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: const MaterialApp(
        home: CommunityListScreen(),
      ),
    );
  }

  group('CommunityListScreen Widget Tests', () {
    testWidgets('renders search bar, filter chips, tabs, and community card',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Communities'), findsOneWidget);
      expect(find.text('Explore (1)'), findsOneWidget);
      expect(find.text('Joined (0)'), findsOneWidget);
      expect(find.text('Indie Game Hub'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
    });

    testWidgets('switches to Joined tab and renders empty placeholder',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Joined (0)'));
      await tester.pumpAndSettle();

      expect(find.text('You have not joined any communities yet.'),
          findsOneWidget);
    });
  });
}
