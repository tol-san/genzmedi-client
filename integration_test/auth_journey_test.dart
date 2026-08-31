import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/app/app.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/auth/token_model.dart';
import 'package:client/core/storage/preferences_service.dart';
import 'package:client/core/storage/secure_storage_service.dart';
import 'package:client/features/auth/data/models/auth_models.dart';
import 'package:client/features/auth/data/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockPreferencesService extends Mock implements PreferencesService {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(const ForgotPasswordRequest(email: ''));
    registerFallbackValue(const VerifyOtpRequest(email: '', otp: ''));
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

    when(() => mockStorage.getAccessToken()).thenAnswer((_) async => null);
    when(
      () => mockStorage.saveTokens(
        accessToken: any(named: 'accessToken'),
        refreshToken: any(named: 'refreshToken'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockPrefs.hasSession()).thenReturn(false);
    when(() => mockPrefs.setHasSession(any())).thenAnswer((_) async {});
    when(() => mockPrefs.isOnboardingCompleted()).thenReturn(true);

    // Default mock responses for auth journey
    when(() => mockRepository.forgotPassword(any())).thenAnswer((_) async {});
    when(() => mockRepository.verifyOtp(any())).thenAnswer(
      (_) async => const PasswordResetVerification(
        resetToken: 'mock_password_reset_token',
        expiresIn: 420,
      ),
    );
    when(() => mockRepository.resetPassword(any())).thenAnswer((_) async {});
  });

  testWidgets(
    'E2E Auth Journey: Forgot Password -> Confirm OTP -> Reset Password -> Sign In',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
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
          child: const GenZApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Splash redirects unauthenticated user to LoginScreen
      expect(find.text('Sign in to your account'), findsOneWidget);

      // 2. Tap "Forgot password?"
      final forgotPasswordLink = find.text('Forgot password?');
      expect(forgotPasswordLink, findsOneWidget);
      await tester.tap(forgotPasswordLink);
      await tester.pumpAndSettle();

      // 3. User is on ForgotPasswordScreen
      expect(find.text('Reset Password'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'alex@genz.media');
      await tester.tap(find.text('Send Verification Code'));
      await tester.pumpAndSettle();

      // 4. User arrives on VerifyOtpScreen
      expect(find.text('Confirm Verification Code'), findsOneWidget);
      expect(find.textContaining('alex@genz.media'), findsOneWidget);

      // 5. Enter 6-digit OTP code and verify
      await tester.enterText(find.byType(TextField).last, '654321');
      await tester.tap(find.text('Verify Code'));
      await tester.pumpAndSettle();

      // 6. Verification Successful Decision View is shown
      expect(find.text('Verification Successful! 🎉'), findsOneWidget);
      expect(find.text('Update Password Now'), findsOneWidget);
      expect(find.text('Back to Sign In'), findsOneWidget);

      // 7. Tap "Update Password Now"
      await tester.tap(find.text('Update Password Now'));
      await tester.pumpAndSettle();

      // 8. User is on ResetPasswordScreen
      expect(find.text('Set New Password'), findsOneWidget);
      final passwordFields = find.byType(TextField);
      final totalFields = passwordFields.evaluate().length;
      await tester.enterText(
        passwordFields.at(totalFields - 2),
        'BrandNewPassword123!',
      );
      await tester.enterText(
        passwordFields.at(totalFields - 1),
        'BrandNewPassword123!',
      );

      await tester.tap(find.text('Save Password'));
      await tester.pumpAndSettle();

      // 9. A password reset never authenticates the user; return to sign in.
      expect(find.text('Sign in to your account'), findsOneWidget);
    },
  );
}
