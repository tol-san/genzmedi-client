import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/features/settings/data/repositories/settings_repository.dart';
import 'package:client/features/settings/presentation/screens/blocked_users_screen.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

Widget _buildTestableWidget({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(
      home: BlockedUsersScreen(),
    ),
  );
}

void main() {
  late MockSettingsRepository mockRepo;

  const blockedUser = UserModel(
    id: 'user-b1',
    username: 'blocked_creator',
    email: 'blocked@example.com',
    displayName: 'Blocked Creator',
  );

  setUp(() {
    mockRepo = MockSettingsRepository();
  });

  group('BlockedUsersScreen Widget Tests', () {
    testWidgets('shows empty state when no users are blocked', (tester) async {
      when(() => mockRepo.getBlockedUsers(limit: any(named: 'limit'), offset: 0))
          .thenAnswer((_) async => const BlockedUsersPage(
                items: [],
                total: 0,
                limit: 20,
                offset: 0,
              ));

      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(mockRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Blocked Accounts'), findsOneWidget);
      expect(find.text('No blocked users'), findsOneWidget);
    });

    testWidgets('renders blocked user tile and unblock confirmation dialog', (tester) async {
      when(() => mockRepo.getBlockedUsers(limit: any(named: 'limit'), offset: 0))
          .thenAnswer((_) async => const BlockedUsersPage(
                items: [blockedUser],
                total: 1,
                limit: 20,
                offset: 0,
              ));
      when(() => mockRepo.unblockUser('user-b1')).thenAnswer((_) async {});

      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(mockRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Blocked Creator'), findsOneWidget);
      expect(find.text('@blocked_creator'), findsOneWidget);
      expect(find.text('Unblock'), findsOneWidget);

      // Tap Unblock
      await tester.tap(find.text('Unblock'));
      await tester.pumpAndSettle();

      // Dialog is displayed
      expect(find.text('Unblock @blocked_creator?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Confirm unblock in dialog
      await tester.tap(find.widgetWithText(TextButton, 'Unblock'));
      await tester.pumpAndSettle();

      verify(() => mockRepo.unblockUser('user-b1')).called(1);
    });
  });
}
