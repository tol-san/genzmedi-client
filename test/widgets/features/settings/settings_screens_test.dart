import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/features/settings/data/models/settings_models.dart';
import 'package:client/features/settings/data/repositories/settings_repository.dart';
import 'package:client/features/settings/presentation/screens/account_management_screen.dart';
import 'package:client/features/settings/presentation/screens/notification_preferences_screen.dart';
import 'package:client/features/settings/presentation/screens/privacy_settings_screen.dart';
import 'package:client/features/settings/presentation/screens/sessions_screen.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockSettingsRepository repository;

  setUp(() {
    repository = MockSettingsRepository();
  });

  group('PrivacySettingsScreen Widget Tests', () {
    testWidgets('renders privacy options and switches', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(() => repository.getPrivacySettings()).thenAnswer(
        (_) async => const PrivacySettings(
          isPrivate: false,
          allowComments: 'everyone',
          allowMentions: 'everyone',
          showActivityStatus: true,
          searchDiscoverable: true,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: PrivacySettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Privacy'), findsOneWidget);
      expect(find.text('Private account'), findsOneWidget);
      expect(find.text('Appear in search'), findsOneWidget);
      expect(find.text('Show activity status'), findsOneWidget);
      expect(find.text('Who can comment'), findsOneWidget);
      expect(find.text('Who can mention you'), findsOneWidget);
    });
  });

  group('NotificationPreferencesScreen Widget Tests', () {
    testWidgets('renders notification preferences categories and controls',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(() => repository.getNotificationPreferences()).thenAnswer(
        (_) async => const NotificationPreferences(
          likesEnabled: true,
          commentsEnabled: true,
          followsEnabled: true,
          mentionsEnabled: true,
          communityEnabled: true,
          pushEnabled: true,
          emailEnabled: false,
          quietHoursEnabled: true,
          quietHoursStart: '23:00',
          quietHoursEnd: '08:00',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: NotificationPreferencesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Notification Preferences'), findsOneWidget);
      expect(find.text('Likes'), findsOneWidget);
      expect(find.text('Comments'), findsOneWidget);
      expect(find.text('Mentions & Replies'), findsOneWidget);
      expect(find.text('New Followers'), findsOneWidget);
      expect(find.text('Community Activity'), findsOneWidget);
      expect(find.text('Push Notifications'), findsOneWidget);
      expect(find.text('Email Notifications'), findsOneWidget);
      expect(find.text('Pause During Quiet Hours'), findsOneWidget);
      expect(find.textContaining('23:00 to 08:00'), findsOneWidget);
    });
  });

  group('SessionsScreen Widget Tests', () {
    testWidgets('renders current device and other sessions with revoke button',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime.now();
      when(() => repository.getSessions()).thenAnswer(
        (_) async => [
          UserSession(
            id: 'sess-1',
            deviceName: 'Pixel 9 Pro (Flutter)',
            ipAddress: '10.0.2.2',
            lastActiveAt: now,
            createdAt: now,
            isCurrent: true,
          ),
          UserSession(
            id: 'sess-2',
            deviceName: 'Chrome on macOS',
            ipAddress: '192.168.1.100',
            lastActiveAt: now.subtract(const Duration(hours: 2)),
            createdAt: now.subtract(const Duration(days: 1)),
            isCurrent: false,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: SessionsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Active Sessions'), findsOneWidget);
      expect(find.text('THIS DEVICE'), findsOneWidget);
      expect(find.text('Active Now'), findsOneWidget);
      expect(find.text('Pixel 9 Pro (Flutter)'), findsOneWidget);
      expect(find.text('Chrome on macOS'), findsOneWidget);
      expect(find.text('Revoke'), findsOneWidget);
      expect(find.text('Sign Out All Other Devices'), findsOneWidget);
    });
  });

  group('AccountManagementScreen Widget Tests', () {
    testWidgets('renders data download, deactivate, and delete tiles',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: AccountManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Account Management'), findsOneWidget);
      expect(find.text('Download Your Data'), findsOneWidget);
      expect(find.text('Deactivate Account'), findsOneWidget);
      expect(find.text('Delete Account'), findsOneWidget);

      // Open Deactivate Dialog
      await tester.tap(find.text('Deactivate Account'));
      await tester.pumpAndSettle();

      expect(find.text('Current Password'), findsOneWidget);
      expect(find.text('Reason (Optional)'), findsOneWidget);
      expect(find.text('Deactivate'), findsOneWidget);

      // Dismiss
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Open Delete Dialog
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Forever'), findsOneWidget);
      expect(find.text('Type "DELETE" below to confirm:'), findsOneWidget);
    });
  });
}
