import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/profiles/data/repositories/profile_repository.dart';
import 'package:client/features/profiles/presentation/notifiers/follow_list_notifier.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository mockRepository;

  const mockUser1 = UserModel(
    id: 'u-1',
    username: 'alex_creator',
    email: 'alex@example.com',
    displayName: 'Alex Creator',
    followersCount: 10,
    followingCount: 5,
  );

  const mockUser2 = UserModel(
    id: 'u-2',
    username: 'sam_designer',
    email: 'sam@example.com',
    displayName: 'Sam Designer',
    followersCount: 20,
    followingCount: 15,
  );

  setUp(() {
    mockRepository = MockProfileRepository();
  });

  group('FollowListNotifier Unit Tests', () {
    test('initializes and loads followers and following lists', () async {
      when(() => mockRepository.getFollowers('u-target', limit: 20, offset: 0))
          .thenAnswer((_) async => [mockUser1]);
      when(() => mockRepository.getFollowing('u-target', limit: 20, offset: 0))
          .thenAnswer((_) async => [mockUser2]);

      final notifier = FollowListNotifier(
        userId: 'u-target',
        repository: mockRepository,
      );

      await pumpEventQueue();

      expect(notifier.state.followers.length, 1);
      expect(notifier.state.followers.first.username, 'alex_creator');
      expect(notifier.state.following.length, 1);
      expect(notifier.state.following.first.username, 'sam_designer');
      expect(notifier.state.followingStatusMap['u-2'], isTrue);
      expect(notifier.state.isLoadingFollowers, isFalse);
      expect(notifier.state.isLoadingFollowing, isFalse);
    });

    test('search query filters followers and following dynamically', () async {
      when(() => mockRepository.getFollowers('u-target', limit: 20, offset: 0))
          .thenAnswer((_) async => [mockUser1, mockUser2]);
      when(() => mockRepository.getFollowing('u-target', limit: 20, offset: 0))
          .thenAnswer((_) async => [mockUser1, mockUser2]);

      final notifier = FollowListNotifier(
        userId: 'u-target',
        repository: mockRepository,
      );
      await pumpEventQueue();

      notifier.setSearchQuery('alex');

      expect(notifier.state.filteredFollowers.length, 1);
      expect(notifier.state.filteredFollowers.first.username, 'alex_creator');
      expect(notifier.state.filteredFollowing.length, 1);
      expect(notifier.state.filteredFollowing.first.username, 'alex_creator');
    });

    test('toggleFollowUser executes follow with optimistic state', () async {
      when(() => mockRepository.getFollowers('u-target', limit: 20, offset: 0))
          .thenAnswer((_) async => [mockUser1]);
      when(() => mockRepository.getFollowing('u-target', limit: 20, offset: 0))
          .thenAnswer((_) async => []);
      when(() => mockRepository.followUser('u-1')).thenAnswer((_) async => true);

      final notifier = FollowListNotifier(
        userId: 'u-target',
        repository: mockRepository,
      );
      await pumpEventQueue();

      await notifier.toggleFollowUser('u-1', isCurrentlyFollowing: false);

      expect(notifier.state.followingStatusMap['u-1'], isTrue);
      verify(() => mockRepository.followUser('u-1')).called(1);
    });

    test('toggleFollowUser reverts on network failure', () async {
      when(() => mockRepository.getFollowers('u-target', limit: 20, offset: 0))
          .thenAnswer((_) async => [mockUser1]);
      when(() => mockRepository.getFollowing('u-target', limit: 20, offset: 0))
          .thenAnswer((_) async => []);
      when(() => mockRepository.followUser('u-1'))
          .thenThrow(const NetworkException(message: 'Connection timed out'));

      final notifier = FollowListNotifier(
        userId: 'u-target',
        repository: mockRepository,
      );
      await pumpEventQueue();

      await notifier.toggleFollowUser('u-1', isCurrentlyFollowing: false);

      expect(notifier.state.followingStatusMap['u-1'], isFalse);
      expect(notifier.state.errorMessage, 'Connection timed out');
    });
  });
}
