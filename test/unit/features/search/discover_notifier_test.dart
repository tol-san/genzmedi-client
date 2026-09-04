import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/communities/data/models/community_models.dart';
import 'package:client/features/search/data/models/discovery_models.dart';
import 'package:client/features/search/data/repositories/discovery_repository.dart';
import 'package:client/features/search/presentation/notifiers/discover_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

const _community = CommunityModel(
  id: 'community-1',
  ownerId: 'owner-1',
  interestId: 'interest-1',
  name: 'Pixel Masters',
  slug: 'pixel-masters',
);
const _recommended = DiscoverCommunityModel(
  community: _community,
  interestName: 'Gaming',
);
const _joined = DiscoverCommunityModel(
  community: CommunityModel(
    id: 'community-2',
    ownerId: 'owner-1',
    interestId: 'interest-1',
    name: 'Joined Community',
    slug: 'joined-community',
  ),
  isJoined: true,
);

DiscoveryPage<T> _page<T>(List<T> items) =>
    DiscoveryPage<T>(items: items, total: items.length, limit: 20, offset: 0);

void _stubSuccess(MockDiscoveryRepository repo) {
  when(() => repo.getRecommendedCommunities(limit: 20))
      .thenAnswer((_) async => _page([_recommended]));
  when(() => repo.getJoinedCommunities(limit: 20))
      .thenAnswer((_) async => _page([_joined]));
}

void main() {
  late MockDiscoveryRepository mockRepo;

  setUp(() => mockRepo = MockDiscoveryRepository());

  group('DiscoverNotifier community discovery', () {
    test('loads and merges recommended and joined communities', () async {
      _stubSuccess(mockRepo);

      final notifier = DiscoverNotifier(repository: mockRepo);
      await pumpEventQueue();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.communities.length, 2);
      expect(notifier.state.communities.first.interestName, 'Gaming');
      expect(notifier.state.communities.last.isJoined, isTrue);
    });

    test('deduplicates a community returned by both endpoints', () async {
      when(() => mockRepo.getRecommendedCommunities(limit: 20))
          .thenAnswer((_) async => _page([_recommended]));
      when(() => mockRepo.getJoinedCommunities(limit: 20)).thenAnswer(
        (_) async => _page([
          const DiscoverCommunityModel(community: _community, isJoined: true),
        ]),
      );

      final notifier = DiscoverNotifier(repository: mockRepo);
      await pumpEventQueue();

      expect(notifier.state.communities, hasLength(1));
      expect(notifier.state.communities.single.isJoined, isTrue);
    });

    test('sets an error when community loading fails', () async {
      when(() => mockRepo.getRecommendedCommunities(limit: 20))
          .thenThrow(const NetworkException(message: 'No network'));
      when(() => mockRepo.getJoinedCommunities(limit: 20))
          .thenAnswer((_) async => _page([]));

      final notifier = DiscoverNotifier(repository: mockRepo);
      await pumpEventQueue();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, 'No network');
    });

    test('joins a recommended community optimistically', () async {
      _stubSuccess(mockRepo);
      when(() => mockRepo.joinCommunity('community-1'))
          .thenAnswer((_) async => false);

      final notifier = DiscoverNotifier(repository: mockRepo);
      await pumpEventQueue();
      await notifier.toggleCommunity('community-1');

      expect(notifier.state.communities.first.isJoined, isTrue);
      verify(() => mockRepo.joinCommunity('community-1')).called(1);
    });

    test('reverts membership when the API fails', () async {
      _stubSuccess(mockRepo);
      when(() => mockRepo.joinCommunity('community-1'))
          .thenThrow(const NetworkException(message: 'Join failed'));

      final notifier = DiscoverNotifier(repository: mockRepo);
      await pumpEventQueue();
      await notifier.toggleCommunity('community-1');

      expect(notifier.state.communities.first.isJoined, isFalse);
      expect(notifier.state.errorMessage, 'Join failed');
    });

    test('refresh replaces community discovery data', () async {
      _stubSuccess(mockRepo);
      final notifier = DiscoverNotifier(repository: mockRepo);
      await pumpEventQueue();

      when(() => mockRepo.getRecommendedCommunities(limit: 20))
          .thenAnswer((_) async => _page([]));
      when(() => mockRepo.getJoinedCommunities(limit: 20))
          .thenAnswer((_) async => _page([_joined]));

      await notifier.refresh();

      expect(notifier.state.communities, hasLength(1));
      expect(
        notifier.state.communities.single.community.name,
        'Joined Community',
      );
      expect(notifier.state.isRefreshing, isFalse);
    });
  });
}
