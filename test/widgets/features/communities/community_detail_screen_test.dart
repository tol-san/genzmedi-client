import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/features/communities/data/models/community_models.dart';
import 'package:client/features/communities/data/repositories/community_repository.dart';
import 'package:client/features/communities/presentation/screens/community_detail_screen.dart';
import 'package:client/features/posts/data/models/post_models.dart';

class MockCommunityRepository extends Mock implements CommunityRepository {}

void main() {
  late MockCommunityRepository mockRepository;

  const testCommunity = CommunityModel(
    id: 'comm-detail-1',
    ownerId: 'owner-1',
    name: 'Cyberpunk Art Collective',
    slug: 'cyberpunk-art',
    description: 'A space for neon aesthetics and cyberpunk worldbuilding.',
    isPrivate: false,
    memberCount: 250,
    postCount: 15,
  );

  const testDetail = CommunityDetailModel(
    community: testCommunity,
    isMember: false,
    isOwner: false,
  );

  const testMember = CommunityMemberModel(
    id: 'm-1',
    userId: 'u-1',
    username: 'neon_rider',
    displayName: 'Neon Rider',
    role: 'admin',
  );

  const testPost = PostModel(
    id: 'p-comm-10',
    author: PostAuthorModel(id: 'u-1', username: 'neon_rider'),
    content: 'Neon City skyline art piece!',
  );

  setUp(() {
    mockRepository = MockCommunityRepository();
    when(() => mockRepository.getCommunity('comm-detail-1'))
        .thenAnswer((_) async => testDetail);
    when(() => mockRepository.getCommunityPosts('comm-detail-1'))
        .thenAnswer((_) async => [testPost]);
    when(() => mockRepository.listMembers('comm-detail-1'))
        .thenAnswer((_) async => [testMember]);
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        communityRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: const MaterialApp(
        home: CommunityDetailScreen(communityId: 'comm-detail-1'),
      ),
    );
  }

  group('CommunityDetailScreen Widget Tests', () {
    testWidgets('renders community name, public badge, tabs, and post',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Cyberpunk Art Collective'), findsWidgets);
      expect(find.text('Public'), findsOneWidget);
      expect(find.text('250 members · 15 posts'), findsOneWidget);
      expect(find.text('Join'), findsOneWidget);
      expect(find.text('Neon City skyline art piece!'), findsOneWidget);
    });

    testWidgets('switches to Members tab and displays members list',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Members (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Neon Rider'), findsOneWidget);
      expect(find.text('@neon_rider · ADMIN'), findsOneWidget);
    });
  });
}
