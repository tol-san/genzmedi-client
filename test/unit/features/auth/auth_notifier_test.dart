import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/auth/auth_state.dart';
import 'package:client/core/auth/token_model.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/core/storage/preferences_service.dart';
import 'package:client/core/storage/secure_storage_service.dart';
import 'package:client/features/auth/data/models/auth_models.dart';
import 'package:client/features/auth/data/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockSecureStorageService extends Mock implements SecureStorageService {}
class MockPreferencesService extends Mock implements PreferencesService {}

void main() {
  late MockAuthRepository mockRepository;
  late MockSecureStorageService mockStorage;
  late MockPreferencesService mockPrefs;

  setUpAll(() {
    registerFallbackValue(const LoginRequest(username: '', password: ''));
    registerFallbackValue(const RegisterRequest(username: '', email: '', password: ''));
    registerFallbackValue(const VerifyOtpRequest(email: '', otp: ''));
  });

  setUp(() {
    mockRepository = MockAuthRepository();
    mockStorage = MockSecureStorageService();
    mockPrefs = MockPreferencesService();

    // Default mock behaviors
    when(() => mockStorage.getAccessToken()).thenAnswer((_) async => null);
    when(() => mockPrefs.hasSession()).thenReturn(true);
    when(() => mockPrefs.setHasSession(any())).thenAnswer((_) async => true);
    when(() => mockPrefs.isOnboardingCompleted()).thenReturn(true);
  });

  group('AuthNotifier Unit Tests', () {
    test('Initializes with checkSession and transitions to AuthUnauthenticated when no token exists', () async {
      final notifier = AuthNotifier(
        repository: mockRepository,
        storage: mockStorage,
        prefs: mockPrefs,
      );

      await Future.delayed(Duration.zero);
      expect(notifier.state, isA<AuthUnauthenticated>());
    });

    test('checkSession transitions to AuthAuthenticated when valid token and profile exist', () async {
      const mockUser = UserModel(
        id: '1',
        username: 'sovandara',
        email: 's@genz.media',
        interests: ['Gaming'],
      );

      when(() => mockStorage.getAccessToken()).thenAnswer((_) async => 'valid_token');
      when(() => mockRepository.getMyProfile()).thenAnswer((_) async => mockUser);

      final notifier = AuthNotifier(
        repository: mockRepository,
        storage: mockStorage,
        prefs: mockPrefs,
      );

      await notifier.checkSession();
      expect(notifier.state, isA<AuthAuthenticated>());
      expect((notifier.state as AuthAuthenticated).user.username, 'sovandara');
    });

    test('login saves tokens and transitions to AuthAuthenticated on success', () async {
      const mockToken = TokenModel(
        accessToken: 'access_123',
        refreshToken: 'refresh_456',
        tokenType: 'Bearer',
      );
      const mockUser = UserModel(
        id: '1',
        username: 'sovandara',
        email: 's@genz.media',
        interests: ['Anime', 'Music'],
      );

      when(() => mockRepository.login(any())).thenAnswer((_) async => mockToken);
      when(() => mockStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});
      when(() => mockRepository.getMyProfile()).thenAnswer((_) async => mockUser);

      final notifier = AuthNotifier(
        repository: mockRepository,
        storage: mockStorage,
        prefs: mockPrefs,
      );

      await notifier.login(username: 'sovandara', password: 'password123');

      expect(notifier.state, isA<AuthAuthenticated>());
      verify(() => mockStorage.saveTokens(accessToken: 'access_123', refreshToken: 'refresh_456')).called(1);
    });

    test('login rethrows on failure without transitioning to AuthAuthenticated', () async {
      when(() => mockRepository.login(any())).thenThrow(const UnauthorizedException('Invalid credentials'));

      final notifier = AuthNotifier(
        repository: mockRepository,
        storage: mockStorage,
        prefs: mockPrefs,
      );

      await expectLater(
        () => notifier.login(username: 'sovandara', password: 'wrongpassword'),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(notifier.state, isNot(isA<AuthAuthenticated>()));
    });

    test('logout calls repository, clears storage, and transitions to AuthUnauthenticated', () async {
      when(() => mockRepository.logout()).thenAnswer((_) async {});
      when(() => mockStorage.clearAll()).thenAnswer((_) async {});

      final notifier = AuthNotifier(
        repository: mockRepository,
        storage: mockStorage,
        prefs: mockPrefs,
      );

      await notifier.logout();
      expect(notifier.state, isA<AuthUnauthenticated>());
      verify(() => mockStorage.clearAll()).called(1);
    });

    test('verifyOtp saves tokens and transitions to AuthAuthenticated when interests exist', () async {
      const mockToken = TokenModel(
        accessToken: 'otp_access_token',
        refreshToken: 'otp_refresh_token',
        tokenType: 'Bearer',
      );
      const mockUser = UserModel(
        id: '1',
        username: 'sovandara',
        email: 's@genz.media',
        interests: ['Gaming'],
      );

      when(() => mockRepository.verifyOtp(any())).thenAnswer((_) async => mockToken);
      when(() => mockStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});
      when(() => mockRepository.getMyProfile()).thenAnswer((_) async => mockUser);

      final notifier = AuthNotifier(
        repository: mockRepository,
        storage: mockStorage,
        prefs: mockPrefs,
      );

      final res = await notifier.verifyOtp(email: 's@genz.media', otp: '123456');

      expect(res.accessToken, 'otp_access_token');
      expect(notifier.state, isA<AuthAuthenticated>());
      verify(() => mockStorage.saveTokens(accessToken: 'otp_access_token', refreshToken: 'otp_refresh_token')).called(1);
    });

    test('verifyOtp transitions to AuthNeedsOnboarding when interests are empty', () async {
      const mockToken = TokenModel(
        accessToken: 'otp_access_token',
        refreshToken: 'otp_refresh_token',
        tokenType: 'Bearer',
      );
      const mockUser = UserModel(
        id: '1',
        username: 'sovandara',
        email: 's@genz.media',
        interests: [],
      );

      when(() => mockPrefs.isOnboardingCompleted()).thenReturn(false);
      when(() => mockRepository.verifyOtp(any())).thenAnswer((_) async => mockToken);
      when(() => mockStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});
      when(() => mockRepository.getMyProfile()).thenAnswer((_) async => mockUser);

      final notifier = AuthNotifier(
        repository: mockRepository,
        storage: mockStorage,
        prefs: mockPrefs,
      );

      await notifier.verifyOtp(email: 's@genz.media', otp: '123456');

      expect(notifier.state, isA<AuthNeedsOnboarding>());
    });
  });
}
