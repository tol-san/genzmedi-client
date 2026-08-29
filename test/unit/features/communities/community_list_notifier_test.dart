import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/features/communities/data/models/community_models.dart';
import 'package:client/features/communities/data/repositories/community_repository.dart';
import 'package:client/features/communities/presentation/notifiers/community_list_notifier.dart';

class MockCommunityRepository extends Mock implements CommunityRepository {}

void main() {
  late MockCommunityRepository mockRepository;

  const testCommunity1 = CommunityModel(
    id: 'comm-1',
    ownerId: 'owner-1',
    name: 'Neo Tokyo',
    slug: 'neo-tokyo',
    description: 'Anime & Cyberpunk art discussions',
    isPrivate: false,
    memberCount: 150,
  );

  const testCommunity2 = CommunityModel(
    id: 'comm-2',
    ownerId: 'owner-2',
    name: 'Secret Lab',
    slug: 'secret-lab',
    description: 'Private developers circle',
    isPrivate: true,
    memberCount: 12,
  );

  setUp(() {
    mockRepository = MockCommunityRepository();
  });

  group('CommunityListNotifier Unit Tests', () {
    test('initializes and loads explore and joined communities', () async {
      when(() => mockRepository.listCommunities())
          .thenAnswer((_) async => [testCommunity1, testCommunity2]);
      when(() => mockRepository.getMyJoinedCommunities())
          .thenAnswer((_) async => [testCommunity1]);

      final notifier = CommunityListNotifier(repository: mockRepository);
      await pumpEventQueue();

      expect(notifier.state.exploreCommunities.length, 2);
      expect(notifier.state.joinedCommunities.length, 1);
      expect(notifier.state.isLoadingExplore, isFalse);
      expect(notifier.state.isLoadingJoined, isFalse);
    });

    test('setSearchQuery updates query and refetches communities', () async {
      when(() => mockRepository.listCommunities())
          .thenAnswer((_) async => [testCommunity1, testCommunity2]);
      when(() => mockRepository.getMyJoinedCommunities())
          .thenAnswer((_) async => []);
      when(() => mockRepository.listCommunities(search: 'Tokyo'))
          .thenAnswer((_) async => [testCommunity1]);

      final notifier = CommunityListNotifier(repository: mockRepository);
      await pumpEventQueue();

      await notifier.setSearchQuery('Tokyo');
      expect(notifier.state.searchQuery, 'Tokyo');
      expect(notifier.state.exploreCommunities.length, 1);
      expect(notifier.state.exploreCommunities.first.name, 'Neo Tokyo');
    });

    test('setPrivacyFilter filters by private or public', () async {
      when(() => mockRepository.listCommunities())
          .thenAnswer((_) async => [testCommunity1, testCommunity2]);
      when(() => mockRepository.getMyJoinedCommunities())
          .thenAnswer((_) async => []);
      when(() => mockRepository.listCommunities(isPrivate: true))
          .thenAnswer((_) async => [testCommunity2]);

      final notifier = CommunityListNotifier(repository: mockRepository);
      await pumpEventQueue();

      await notifier.setPrivacyFilter(true);
      expect(notifier.state.privacyFilter, isTrue);
      expect(notifier.state.exploreCommunities.length, 1);
      expect(notifier.state.exploreCommunities.first.isPrivate, isTrue);
    });
  });
}
