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

  const testPublicCommunity = CommunityModel(
    id: 'comm-detail-1',
    ownerId: 'owner-1',
    name: 'Cyberpunk Art Collective',
    slug: 'cyberpunk-art',
    description: 'A space for neon aesthetics and cyberpunk worldbuilding.',
    isPrivate: false,
    memberCount: 250,
    postCount: 15,
  );

  const testPublicNonMemberDetail = CommunityDetailModel(
    community: testPublicCommunity,
    isMember: false,
    isOwner: false,
  );

  const testPublicOwnerDetail = CommunityDetailModel(
    community: testPublicCommunity,
    isMember: true,
    isOwner: true,
    membershipRole: 'owner',
  );

  const testPrivateCommunity = CommunityModel(
    id: 'comm-private-1',
    ownerId: 'owner-2',
    name: 'Secret Lore Society',
    slug: 'secret-lore',
    description: 'Private community for classified lore.',
    isPrivate: true,
    memberCount: 42,
    postCount: 5,
  );

  const testPrivateNonMemberDetail = CommunityDetailModel(
    community: testPrivateCommunity,
    isMember: false,
    isOwner: false,
  );

  const testPrivateOwnerDetail = CommunityDetailModel(
    community: testPrivateCommunity,
    isMember: true,
    isOwner: true,
    membershipRole: 'owner',
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
        .thenAnswer((_) async => testPublicNonMemberDetail);
    when(() => mockRepository.getCommunityPosts('comm-detail-1'))
        .thenAnswer((_) async => [testPost]);
    when(() => mockRepository.listMembers('comm-detail-1'))
        .thenAnswer((_) async => [testMember]);
    when(() => mockRepository.listJoinRequests('comm-detail-1'))
        .thenAnswer((_) async => []);
  });

  Widget buildTestWidget({String communityId = 'comm-detail-1'}) {
    return ProviderScope(
      overrides: [
        communityRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: MaterialApp(
        home: CommunityDetailScreen(communityId: communityId),
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

    testWidgets(
        'renders Public Community Owner screen WITHOUT Requests tab',
        (tester) async {
      when(() => mockRepository.getCommunity('comm-detail-1'))
          .thenAnswer((_) async => testPublicOwnerDetail);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Owner'), findsOneWidget);
      expect(find.text('Edit Banner'), findsOneWidget);
      expect(find.text('Posts'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Members (1)'), findsOneWidget);
      expect(find.textContaining('Requests'), findsNothing);
    });

    testWidgets(
        'renders Private Community Owner screen WITH Requests tab',
        (tester) async {
      when(() => mockRepository.getCommunity('comm-private-1'))
          .thenAnswer((_) async => testPrivateOwnerDetail);
      when(() => mockRepository.getCommunityPosts('comm-private-1'))
          .thenAnswer((_) async => []);
      when(() => mockRepository.listMembers('comm-private-1'))
          .thenAnswer((_) async => [testMember]);
      when(() => mockRepository.listJoinRequests('comm-private-1'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildTestWidget(communityId: 'comm-private-1'));
      await tester.pumpAndSettle();

      expect(find.text('Owner'), findsOneWidget);
      expect(find.text('Edit Banner'), findsOneWidget);
      expect(find.text('Requests (0)'), findsOneWidget);
    });

    testWidgets('renders Private Community locked screen for non-members',
        (tester) async {
      when(() => mockRepository.getCommunity('comm-private-1'))
          .thenAnswer((_) async => testPrivateNonMemberDetail);
      when(() => mockRepository.getCommunityPosts('comm-private-1'))
          .thenAnswer((_) async => []);
      when(() => mockRepository.listMembers('comm-private-1'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildTestWidget(communityId: 'comm-private-1'));
      await tester.pumpAndSettle();

      expect(find.text('Secret Lore Society'), findsWidgets);
      expect(find.text('Private'), findsOneWidget);
      expect(find.text('Request to Join'), findsWidgets);
      expect(find.text('Private Community'), findsOneWidget);
    });

    testWidgets('renders owner options menu with Edit, Manage reports, and Delete community',
        (tester) async {
      when(() => mockRepository.getCommunity('comm-detail-1'))
          .thenAnswer((_) async => testPublicOwnerDetail);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Community options'));
      await tester.pumpAndSettle();

      expect(find.text('Edit community'), findsOneWidget);
      expect(find.text('Manage reports'), findsOneWidget);
      expect(find.text('Delete community'), findsOneWidget);
    });

    testWidgets('allows owner to delete community via confirmation dialog',
        (tester) async {
      when(() => mockRepository.getCommunity('comm-detail-1'))
          .thenAnswer((_) async => testPublicOwnerDetail);
      when(() => mockRepository.deleteCommunity('comm-detail-1'))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Community options'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete community'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Community?'), findsOneWidget);

      final confirmField = find.byKey(const Key('confirm_delete_field'));
      await tester.enterText(confirmField, 'Cyberpunk Art Collective');
      await tester.pumpAndSettle();

      final confirmBtn = find.widgetWithText(ElevatedButton, 'Delete Community');
      await tester.tap(confirmBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      verify(() => mockRepository.deleteCommunity('comm-detail-1')).called(1);
    });

    testWidgets(
        'renders quick post CTA and Post FAB for community members and owners',
        (tester) async {
      when(() => mockRepository.getCommunity('comm-detail-1'))
          .thenAnswer((_) async => testPublicOwnerDetail);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('Share something with the community...'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(FloatingActionButton, 'Post'),
        findsOneWidget,
      );
    });

    testWidgets('hides quick post CTA and Post FAB for non-members',
        (tester) async {
      when(() => mockRepository.getCommunity('comm-detail-1'))
          .thenAnswer((_) async => testPublicNonMemberDetail);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('Share something with the community...'),
        findsNothing,
      );
      expect(
        find.widgetWithText(FloatingActionButton, 'Post'),
        findsNothing,
      );
    });
  });
}
