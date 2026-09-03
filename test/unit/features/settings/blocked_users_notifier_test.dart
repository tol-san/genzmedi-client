import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/settings/data/repositories/settings_repository.dart';
import 'package:client/features/settings/presentation/notifiers/blocked_users_notifier.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository mockRepo;

  const user1 = UserModel(
    id: 'user-1',
    username: 'spammer_1',
    email: 'spam1@example.com',
    displayName: 'Spammer One',
  );
  const user2 = UserModel(
    id: 'user-2',
    username: 'spammer_2',
    email: 'spam2@example.com',
    displayName: 'Spammer Two',
  );

  setUp(() {
    mockRepo = MockSettingsRepository();
  });

  group('BlockedUsersNotifier Unit Tests', () {
    test('loads blocked users on initialization', () async {
      when(() => mockRepo.getBlockedUsers(limit: any(named: 'limit'), offset: 0))
          .thenAnswer((_) async => const BlockedUsersPage(
                items: [user1, user2],
                total: 2,
                limit: 20,
                offset: 0,
              ));

      final notifier = BlockedUsersNotifier(repository: mockRepo);

      // Await initial load
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.users.length, 2);
      expect(notifier.state.total, 2);
      expect(notifier.state.hasMore, isFalse);
    });

    test('captures error when initial load fails', () async {
      when(() => mockRepo.getBlockedUsers(limit: any(named: 'limit'), offset: 0))
          .thenThrow(const ApiException(message: 'Database error'));

      final notifier = BlockedUsersNotifier(repository: mockRepo);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, 'Database error');
      expect(notifier.state.users, isEmpty);
    });

    test('unblockUser removes user optimistically and completes successfully', () async {
      when(() => mockRepo.getBlockedUsers(limit: any(named: 'limit'), offset: 0))
          .thenAnswer((_) async => const BlockedUsersPage(
                items: [user1, user2],
                total: 2,
                limit: 20,
                offset: 0,
              ));
      when(() => mockRepo.unblockUser('user-1')).thenAnswer((_) async {});

      final notifier = BlockedUsersNotifier(repository: mockRepo);
      await Future<void>.delayed(Duration.zero);

      final result = await notifier.unblockUser('user-1');

      expect(result, isTrue);
      expect(notifier.state.users.length, 1);
      expect(notifier.state.users.first.id, 'user-2');
      expect(notifier.state.total, 1);
      expect(notifier.state.pendingUnblockIds, isEmpty);
      verify(() => mockRepo.unblockUser('user-1')).called(1);
    });

    test('unblockUser rolls back state if repository fails', () async {
      when(() => mockRepo.getBlockedUsers(limit: any(named: 'limit'), offset: 0))
          .thenAnswer((_) async => const BlockedUsersPage(
                items: [user1],
                total: 1,
                limit: 20,
                offset: 0,
              ));
      when(() => mockRepo.unblockUser('user-1'))
          .thenThrow(const NetworkException(message: 'Connection timeout'));

      final notifier = BlockedUsersNotifier(repository: mockRepo);
      await Future<void>.delayed(Duration.zero);

      final result = await notifier.unblockUser('user-1');

      expect(result, isFalse);
      expect(notifier.state.users.length, 1);
      expect(notifier.state.users.first.id, 'user-1');
      expect(notifier.state.errorMessage, contains('Failed to unblock @spammer_1'));
    });
  });
}
