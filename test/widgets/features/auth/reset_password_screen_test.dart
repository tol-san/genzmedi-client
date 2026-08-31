import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/core/storage/preferences_service.dart';
import 'package:client/core/storage/secure_storage_service.dart';
import 'package:client/features/auth/data/models/auth_models.dart';
import 'package:client/features/auth/data/repositories/auth_repository.dart';
import 'package:client/features/auth/presentation/screens/reset_password_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockPreferencesService extends Mock implements PreferencesService {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(
      const ResetPasswordRequest(token: '', newPassword: ''),
    );
  });

  late MockAuthRepository mockRepository;
  late MockSecureStorageService mockStorage;
  late MockPreferencesService mockPrefs;

  setUp(() {
    mockRepository = MockAuthRepository();
    mockStorage = MockSecureStorageService();
    mockPrefs = MockPreferencesService();

    when(() => mockStorage.getAccessToken())
        .thenAnswer((_) async => 'mock_token');
    when(() => mockPrefs.hasSession()).thenReturn(true);
    when(() => mockPrefs.isOnboardingCompleted()).thenReturn(true);
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepository),
        secureStorageServiceProvider.overrideWithValue(mockStorage),
        preferencesServiceProvider.overrideWithValue(mockPrefs),
        authNotifierProvider.overrideWith(
          (ref) => AuthNotifier(
            repository: mockRepository,
            storage: mockStorage,
            prefs: mockPrefs,
          ),
        ),
      ],
      child: const MaterialApp(
        home: ResetPasswordScreen(
          initialEmail: 'alex@example.com',
          initialToken: 'valid_reset_token',
        ),
      ),
    );
  }

  group('ResetPasswordScreen Widget Tests', () {
    testWidgets('Renders all fields and skip options', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Set New Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Save Password'), findsOneWidget);
      expect(find.text('Back to Sign In'), findsOneWidget);
    });

    testWidgets('Shows error if password is less than 8 characters', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'short');
      await tester.enterText(textFields.at(1), 'short');
      await tester.tap(find.text('Save Password'));
      await tester.pump();

      expect(
        find.text('Password must be at least 8 characters long.'),
        findsOneWidget,
      );
    });

    testWidgets('Shows error if passwords do not match', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Password123!');
      await tester.enterText(textFields.at(1), 'PasswordMismatch!');
      await tester.tap(find.text('Save Password'));
      await tester.pump();

      expect(find.text('Passwords do not match.'), findsOneWidget);
    });

    testWidgets('Calls resetPassword when valid passwords are submitted', (
      tester,
    ) async {
      when(() => mockRepository.resetPassword(any())).thenAnswer((_) async {});
      when(() => mockRepository.getMyProfile()).thenAnswer(
        (_) async => const UserModel(
          id: '1',
          email: 'alex@example.com',
          username: 'alex',
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'NewStrongPassword123!');
      await tester.enterText(textFields.at(1), 'NewStrongPassword123!');
      await tester.tap(find.text('Save Password'));
      await tester.pump();

      verify(() => mockRepository.resetPassword(any())).called(1);
    });
  });
}
