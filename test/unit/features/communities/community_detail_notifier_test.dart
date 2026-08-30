import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/features/communities/data/models/community_models.dart';
import 'package:client/features/communities/data/repositories/community_repository.dart';
import 'package:client/features/communities/presentation/notifiers/community_detail_notifier.dart';
import 'package:client/features/posts/data/models/post_models.dart';

class MockCommunityRepository extends Mock implements CommunityRepository {}

void main() {
  late MockCommunityRepository mockRepository;

  const testCommunity = CommunityModel(
    id: 'comm-10',
    ownerId: 'owner-10',
    name: 'Flutter Builders',
    slug: 'flutter-builders',
    isPrivate: false,
    memberCount: 50,
  );

  const testDetail = CommunityDetailModel(
    community: testCommunity,
    isMember: false,
    isOwner: false,
  );

  const testOwnerDetail = CommunityDetailModel(
    community: testCommunity,
    isMember: true,
    isOwner: true,
  );

  const testMember = CommunityMemberModel(
    id: 'm-1',
    userId: 'u-100',
    username: 'dev_alex',
    displayName: 'Alex Developer',
    role: 'member',
  );

  const testJoinRequest = JoinRequestModel(
    id: 'req-1',
    userId: 'u-200',
    username: 'pending_user',
    displayName: 'Pending User',
  );

  const testPost = PostModel(
    id: 'p-comm-1',
    author: PostAuthorModel(id: 'u-100', username: 'dev_alex'),
    content: 'Hello Flutter community!',
  );

  setUp(() {
    mockRepository = MockCommunityRepository();
  });

  group('CommunityDetailNotifier Unit Tests', () {
    test('initializes and loads community details, posts, and members', () async {
      when(() => mockRepository.getCommunity('comm-10'))
          .thenAnswer((_) async => testDetail);
      when(() => mockRepository.getCommunityPosts('comm-10'))
          .thenAnswer((_) async => [testPost]);
      when(() => mockRepository.listMembers('comm-10'))
          .thenAnswer((_) async => [testMember]);

      final notifier = CommunityDetailNotifier(
        communityId: 'comm-10',
        repository: mockRepository,
      );
      await pumpEventQueue();

      expect(notifier.state.detail?.community.id, 'comm-10');
      expect(notifier.state.posts.length, 1);
      expect(notifier.state.members.length, 1);
      expect(notifier.state.isLoading, isFalse);
    });

    test('joinCommunity joins public community and increments member count', () async {
      when(() => mockRepository.getCommunity('comm-10'))
          .thenAnswer((_) async => testDetail);
      when(() => mockRepository.getCommunityPosts('comm-10'))
          .thenAnswer((_) async => []);
      when(() => mockRepository.listMembers('comm-10'))
          .thenAnswer((_) async => [testMember]);
      when(() => mockRepository.joinCommunity('comm-10'))
          .thenAnswer((_) async => {'status': 'joined', 'is_member': true});

      final notifier = CommunityDetailNotifier(
        communityId: 'comm-10',
        repository: mockRepository,
      );
      await pumpEventQueue();

      final success = await notifier.joinCommunity();
      expect(success, isTrue);
      expect(notifier.state.detail?.isMember, isTrue);
      expect(notifier.state.detail?.community.memberCount, 51);
    });

    test('leaveCommunity leaves community and decrements member count', () async {
      when(() => mockRepository.getCommunity('comm-10'))
          .thenAnswer((_) async => testDetail.copyWith(isMember: true));
      when(() => mockRepository.getCommunityPosts('comm-10'))
          .thenAnswer((_) async => []);
      when(() => mockRepository.listMembers('comm-10'))
          .thenAnswer((_) async => []);
      when(() => mockRepository.leaveCommunity('comm-10'))
          .thenAnswer((_) async => {'success': true});

      final notifier = CommunityDetailNotifier(
        communityId: 'comm-10',
        repository: mockRepository,
      );
      await pumpEventQueue();

      final success = await notifier.leaveCommunity();
      expect(success, isTrue);
      expect(notifier.state.detail?.isMember, isFalse);
      expect(notifier.state.detail?.community.memberCount, 49);
    });

    test('approveJoinRequest removes request and increments member count', () async {
      final privateOwnerDetail = testOwnerDetail.copyWith(
        community: testCommunity.copyWith(isPrivate: true),
      );
      when(() => mockRepository.getCommunity('comm-10'))
          .thenAnswer((_) async => privateOwnerDetail);
      when(() => mockRepository.getCommunityPosts('comm-10'))
          .thenAnswer((_) async => []);
      when(() => mockRepository.listMembers('comm-10'))
          .thenAnswer((_) async => [testMember]);
      when(() => mockRepository.listJoinRequests('comm-10'))
          .thenAnswer((_) async => [testJoinRequest]);
      when(() => mockRepository.approveJoinRequest('comm-10', 'req-1'))
          .thenAnswer((_) async {});

      final notifier = CommunityDetailNotifier(
        communityId: 'comm-10',
        repository: mockRepository,
      );
      await pumpEventQueue();

      expect(notifier.state.joinRequests.length, 1);
      final success = await notifier.approveJoinRequest('req-1');
      expect(success, isTrue);
      expect(notifier.state.joinRequests.isEmpty, isTrue);
      expect(notifier.state.detail?.community.memberCount, 51);
    });
  });
}
