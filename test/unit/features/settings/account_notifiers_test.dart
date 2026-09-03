import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/settings/data/models/settings_models.dart';
import 'package:client/features/settings/data/repositories/settings_repository.dart';
import 'package:client/features/settings/presentation/notifiers/account_settings_notifiers.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository repository;

  setUp(() {
    repository = MockSettingsRepository();
  });

  group('PrivacySettingsNotifier Tests', () {
    test('load() fetches privacy settings and updates state', () async {
      const mockSettings = PrivacySettings(
        isPrivate: true,
        allowComments: 'following',
        allowMentions: 'everyone',
        showActivityStatus: false,
        searchDiscoverable: false,
      );

      when(() => repository.getPrivacySettings())
          .thenAnswer((_) async => mockSettings);

      final notifier = PrivacySettingsNotifier(repository, loadOnCreate: false);
      expect(notifier.state.isLoading, isFalse);

      await notifier.load();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.settings, mockSettings);
      expect(notifier.state.settings?.isPrivate, isTrue);
    });

    test('update() persists changes and clears isSaving', () async {
      const initial = PrivacySettings(isPrivate: false);
      const updated = PrivacySettings(isPrivate: true);

      when(() => repository.getPrivacySettings())
          .thenAnswer((_) async => initial);
      when(() => repository.updatePrivacySettings({'is_private': true}))
          .thenAnswer((_) async => updated);

      final notifier = PrivacySettingsNotifier(repository, loadOnCreate: true);
      await Future<void>.delayed(Duration.zero);

      final success = await notifier.update({'is_private': true});

      expect(success, isTrue);
      expect(notifier.state.settings?.isPrivate, isTrue);
      expect(notifier.state.isSaving, isFalse);
    });

    test('update() handles failure and sets errorMessage', () async {
      const initial = PrivacySettings(isPrivate: false);

      when(() => repository.getPrivacySettings())
          .thenAnswer((_) async => initial);
      when(() => repository.updatePrivacySettings(any()))
          .thenThrow(const ApiException(message: 'Update error', statusCode: 400));

      final notifier = PrivacySettingsNotifier(repository, loadOnCreate: true);
      await Future<void>.delayed(Duration.zero);

      final success = await notifier.update({'is_private': true});

      expect(success, isFalse);
      expect(notifier.state.isSaving, isFalse);
      expect(notifier.state.errorMessage, 'Update error');
    });
  });

  group('NotificationPreferencesNotifier Tests', () {
    test('load() fetches notification preferences', () async {
      const mockPrefs = NotificationPreferences(
        likesEnabled: true,
        commentsEnabled: false,
        pushEnabled: true,
        emailEnabled: true,
      );

      when(() => repository.getNotificationPreferences())
          .thenAnswer((_) async => mockPrefs);

      final notifier =
          NotificationPreferencesNotifier(repository, loadOnCreate: false);

      await notifier.load();

      expect(notifier.state.preferences, mockPrefs);
      expect(notifier.state.preferences?.commentsEnabled, isFalse);
      expect(notifier.state.preferences?.emailEnabled, isTrue);
    });

    test('update() modifies notification preference values', () async {
      const initial = NotificationPreferences(pushEnabled: true);
      const updated = NotificationPreferences(pushEnabled: false);

      when(() => repository.getNotificationPreferences())
          .thenAnswer((_) async => initial);
      when(() => repository.updateNotificationPreferences({'push_enabled': false}))
          .thenAnswer((_) async => updated);

      final notifier =
          NotificationPreferencesNotifier(repository, loadOnCreate: true);
      await Future<void>.delayed(Duration.zero);

      final success = await notifier.update({'push_enabled': false});

      expect(success, isTrue);
      expect(notifier.state.preferences?.pushEnabled, isFalse);
    });
  });

  group('SessionsNotifier Tests', () {
    final sampleSession = UserSession(
      id: 'session-1',
      deviceName: 'Chrome on Windows',
      ipAddress: '127.0.0.1',
      lastActiveAt: DateTime.now(),
      createdAt: DateTime.now(),
      isCurrent: true,
    );
    final otherSession = UserSession(
      id: 'session-2',
      deviceName: 'Safari on iPhone',
      ipAddress: '192.168.1.5',
      lastActiveAt: DateTime.now(),
      createdAt: DateTime.now(),
      isCurrent: false,
    );

    test('load() loads active sessions', () async {
      when(() => repository.getSessions())
          .thenAnswer((_) async => [sampleSession, otherSession]);

      final notifier = SessionsNotifier(repository, loadOnCreate: false);
      await notifier.load();

      expect(notifier.state.sessions.length, 2);
      expect(notifier.state.sessions.first.isCurrent, isTrue);
    });

    test('revoke() removes specific session from list', () async {
      when(() => repository.getSessions())
          .thenAnswer((_) async => [sampleSession, otherSession]);
      when(() => repository.revokeSession('session-2'))
          .thenAnswer((_) async {});

      final notifier = SessionsNotifier(repository, loadOnCreate: true);
      await Future<void>.delayed(Duration.zero);

      final result = await notifier.revoke('session-2');

      expect(result, isTrue);
      expect(notifier.state.sessions.length, 1);
      expect(notifier.state.sessions.first.id, 'session-1');
    });

    test('revokeOthers() removes all non-current sessions', () async {
      when(() => repository.getSessions())
          .thenAnswer((_) async => [sampleSession, otherSession]);
      when(() => repository.revokeOtherSessions())
          .thenAnswer((_) async {});

      final notifier = SessionsNotifier(repository, loadOnCreate: true);
      await Future<void>.delayed(Duration.zero);

      final result = await notifier.revokeOthers();

      expect(result, isTrue);
      expect(notifier.state.sessions.length, 1);
      expect(notifier.state.sessions.every((s) => s.isCurrent), isTrue);
    });
  });

  group('AccountActionNotifier Tests', () {
    test('deactivate() calls repository and updates state', () async {
      when(() => repository.deactivateAccount(
            password: 'mypassword',
            reason: 'Taking a break',
          )).thenAnswer((_) async {});

      final notifier = AccountActionNotifier(repository);
      final success = await notifier.deactivate('mypassword', reason: 'Taking a break');

      expect(success, isTrue);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, isNull);
    });

    test('deactivate() returns false on empty password', () async {
      final notifier = AccountActionNotifier(repository);
      final success = await notifier.deactivate('');

      expect(success, isFalse);
    });

    test('delete() requires exact DELETE confirmation', () async {
      when(() => repository.deleteAccount(password: 'mypassword'))
          .thenAnswer((_) async {});

      final notifier = AccountActionNotifier(repository);

      final invalidConfirm = await notifier.delete('mypassword', 'delete');
      expect(invalidConfirm, isFalse);

      final success = await notifier.delete('mypassword', 'DELETE');
      expect(success, isTrue);
    });
  });
}
