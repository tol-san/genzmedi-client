import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/settings/data/repositories/settings_repository.dart';
import 'package:client/features/settings/presentation/notifiers/change_password_notifier.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository mockRepo;
  late ChangePasswordNotifier notifier;

  setUp(() {
    mockRepo = MockSettingsRepository();
    notifier = ChangePasswordNotifier(repository: mockRepo);
  });

  group('ChangePasswordNotifier Unit Tests', () {
    test('initial state has default obscure flags and not loading', () {
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.isSuccess, isFalse);
      expect(notifier.state.obscureCurrent, isTrue);
      expect(notifier.state.obscureNew, isTrue);
      expect(notifier.state.obscureConfirm, isTrue);
    });

    test('toggling obscure flags updates state', () {
      notifier.toggleObscureCurrent();
      expect(notifier.state.obscureCurrent, isFalse);

      notifier.toggleObscureNew();
      expect(notifier.state.obscureNew, isFalse);

      notifier.toggleObscureConfirm();
      expect(notifier.state.obscureConfirm, isFalse);
    });

    test('submit rejects empty current password', () async {
      final success = await notifier.submit(
        currentPassword: '',
        newPassword: 'newpassword123',
        confirmPassword: 'newpassword123',
      );
      expect(success, isFalse);
      expect(notifier.state.errorMessage, contains('current password'));
      verifyZeroInteractions(mockRepo);
    });

    test('submit rejects short new password (< 8 chars)', () async {
      final success = await notifier.submit(
        currentPassword: 'currentpassword123',
        newPassword: 'short',
        confirmPassword: 'short',
      );
      expect(success, isFalse);
      expect(notifier.state.errorMessage, contains('at least 8 characters'));
      verifyZeroInteractions(mockRepo);
    });

    test('submit rejects matching current and new password', () async {
      final success = await notifier.submit(
        currentPassword: 'samepassword123',
        newPassword: 'samepassword123',
        confirmPassword: 'samepassword123',
      );
      expect(success, isFalse);
      expect(notifier.state.errorMessage, contains('different from'));
      verifyZeroInteractions(mockRepo);
    });

    test('submit rejects mismatched new and confirm passwords', () async {
      final success = await notifier.submit(
        currentPassword: 'currentpassword123',
        newPassword: 'newpassword123',
        confirmPassword: 'differentpassword123',
      );
      expect(success, isFalse);
      expect(notifier.state.errorMessage, contains('do not match'));
      verifyZeroInteractions(mockRepo);
    });

    test('submit calls repo and sets isSuccess on success', () async {
      when(() => mockRepo.changePassword(
            currentPassword: 'currentpassword123',
            newPassword: 'newpassword123',
          )).thenAnswer((_) async {});

      final success = await notifier.submit(
        currentPassword: 'currentpassword123',
        newPassword: 'newpassword123',
        confirmPassword: 'newpassword123',
      );

      expect(success, isTrue);
      expect(notifier.state.isSuccess, isTrue);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, isNull);
    });

    test('submit captures repository error in errorMessage', () async {
      when(() => mockRepo.changePassword(
            currentPassword: 'wrongpassword123',
            newPassword: 'newpassword123',
          )).thenThrow(const ValidationException(message: 'Incorrect current password'));

      final success = await notifier.submit(
        currentPassword: 'wrongpassword123',
        newPassword: 'newpassword123',
        confirmPassword: 'newpassword123',
      );

      expect(success, isFalse);
      expect(notifier.state.isSuccess, isFalse);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, 'Incorrect current password');
    });
  });
}
