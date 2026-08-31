import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/auth/token_model.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/core/storage/preferences_service.dart';
import 'package:client/core/storage/secure_storage_service.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/auth/data/models/auth_models.dart';
import 'package:client/features/auth/data/repositories/auth_repository.dart';
import 'package:client/features/auth/presentation/screens/verify_otp_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockPreferencesService extends Mock implements PreferencesService {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(const VerifyOtpRequest(email: '', otp: ''));
  });

  late MockAuthRepository mockRepository;
  late MockSecureStorageService mockStorage;
  late MockPreferencesService mockPrefs;

  setUp(() {
    mockRepository = MockAuthRepository();
    mockStorage = MockSecureStorageService();
    mockPrefs = MockPreferencesService();

    when(() => mockStorage.getAccessToken()).thenAnswer((_) async => null);
    when(
      () => mockStorage.saveTokens(
        accessToken: any(named: 'accessToken'),
        refreshToken: any(named: 'refreshToken'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockPrefs.hasSession()).thenReturn(false);
    when(() => mockPrefs.setHasSession(any())).thenAnswer((_) async {});
    when(() => mockPrefs.isOnboardingCompleted()).thenReturn(false);
  });

  Widget createWidgetUnderTest({String email = 'test@example.com'}) {
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
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: VerifyOtpScreen(email: email),
      ),
    );
  }

  group('VerifyOtpScreen Widget Tests', () {
    testWidgets('Renders OTP input and Verify Code button', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Confirm Verification Code'), findsOneWidget);
      expect(find.textContaining('test@example.com'), findsOneWidget);
      expect(find.text('Verify Code'), findsOneWidget);
      expect(find.text('Change Email'), findsOneWidget);
    });

    testWidgets('Shows error if submitted with empty OTP', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.tap(find.text('Verify Code'));
      await tester.pump();

      expect(find.text('Please enter the 6-digit code.'), findsOneWidget);
    });

    testWidgets('Shows error if submitted with less than 6 digits', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.text('Verify Code'));
      await tester.pump();

      expect(find.text('Verification code must be 6 digits.'), findsOneWidget);
    });

    testWidgets('Displays Decision View on valid OTP verification', (
      tester,
    ) async {
      when(() => mockRepository.verifyOtp(any())).thenAnswer(
        (_) async => const PasswordResetVerification(
          resetToken: 'mock_reset_token',
          expiresIn: 420,
        ),
      );

      when(() => mockRepository.getMyProfile()).thenAnswer(
        (_) async => const UserModel(
          id: '123',
          email: 'test@example.com',
          username: 'testuser',
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.enterText(find.byType(TextField), '123456');
      await tester.pumpAndSettle();

      // Should display the post-verification decision UI
      expect(find.text('Verification Successful! 🎉'), findsOneWidget);
      expect(find.text('Update Password Now'), findsOneWidget);
      expect(find.text('Back to Sign In'), findsOneWidget);
    });
  });
}
