import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/app/router/app_router.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/auth/auth_state.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/core/storage/preferences_service.dart';
import 'package:client/core/storage/secure_storage_service.dart';
import 'package:client/features/auth/data/repositories/auth_repository.dart';

class MockBuildContext extends Mock implements BuildContext {}
class MockGoRouterState extends Mock implements GoRouterState {}
class MockAuthRepository extends Mock implements AuthRepository {}
class MockSecureStorageService extends Mock implements SecureStorageService {}
class MockPreferencesService extends Mock implements PreferencesService {}

class TestAuthNotifier extends AuthNotifier {
  TestAuthNotifier({
    required super.repository,
    required super.storage,
    required super.prefs,
    AuthState initialState = const AuthInitial(),
  }) {
    state = initialState;
  }

  @override
  Future<void> checkSession() async {
    // No-op for testing
  }

  void setTestState(AuthState newState) {
    state = newState;
  }
}

void main() {
  late ProviderContainer container;
  late TestAuthNotifier testAuthNotifier;
  late MockBuildContext mockContext;
  late MockGoRouterState mockRouterState;

  setUp(() {
    testAuthNotifier = TestAuthNotifier(
      repository: MockAuthRepository(),
      storage: MockSecureStorageService(),
      prefs: MockPreferencesService(),
      initialState: const AuthInitial(),
    );
    mockContext = MockBuildContext();
    mockRouterState = MockGoRouterState();

    container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith((ref) => testAuthNotifier),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('RouterNotifier redirect tests', () {
    test('Keeps user on /splash when AuthInitial', () {
      testAuthNotifier.setTestState(const AuthInitial());
      final notifier = container.read(routerNotifierProvider);
      when(() => mockRouterState.matchedLocation).thenReturn('/splash');

      final redirect = notifier.redirect(mockContext, mockRouterState);
      expect(redirect, isNull);
    });

    test('Redirects to /splash if navigating elsewhere when AuthInitial', () {
      testAuthNotifier.setTestState(const AuthInitial());
      final notifier = container.read(routerNotifierProvider);
      when(() => mockRouterState.matchedLocation).thenReturn('/feed');

      final redirect = notifier.redirect(mockContext, mockRouterState);
      expect(redirect, '/splash');
    });

    test('Does NOT redirect away from /login during AuthLoading', () {
      testAuthNotifier.setTestState(const AuthLoading());
      final notifier = container.read(routerNotifierProvider);
      when(() => mockRouterState.matchedLocation).thenReturn('/login');

      final redirect = notifier.redirect(mockContext, mockRouterState);
      expect(redirect, isNull);
    });

    test('Does NOT redirect away from /register during AuthLoading', () {
      testAuthNotifier.setTestState(const AuthLoading());
      final notifier = container.read(routerNotifierProvider);
      when(() => mockRouterState.matchedLocation).thenReturn('/register');

      final redirect = notifier.redirect(mockContext, mockRouterState);
      expect(redirect, isNull);
    });

    test('Redirects unauthenticated user from /feed to /login', () {
      testAuthNotifier.setTestState(const AuthUnauthenticated());
      final notifier = container.read(routerNotifierProvider);
      when(() => mockRouterState.matchedLocation).thenReturn('/feed');

      final redirect = notifier.redirect(mockContext, mockRouterState);
      expect(redirect, '/login');
    });

    test('Redirects authenticated user from /login to /feed', () {
      testAuthNotifier.setTestState(
        const AuthAuthenticated(
          UserModel(id: '1', username: 'alex', email: 'alex@example.com'),
        ),
      );
      final notifier = container.read(routerNotifierProvider);
      when(() => mockRouterState.matchedLocation).thenReturn('/login');

      final redirect = notifier.redirect(mockContext, mockRouterState);
      expect(redirect, '/feed');
    });

    test('Does NOT redirect away from /verify-otp when AuthAuthenticated', () {
      testAuthNotifier.setTestState(
        const AuthAuthenticated(
          UserModel(id: '1', username: 'alex', email: 'alex@example.com'),
        ),
      );
      final notifier = container.read(routerNotifierProvider);
      when(() => mockRouterState.matchedLocation).thenReturn('/verify-otp');

      final redirect = notifier.redirect(mockContext, mockRouterState);
      expect(redirect, isNull);
    });

    test('Does NOT redirect away from /verify-otp when AuthNeedsOnboarding', () {
      testAuthNotifier.setTestState(
        const AuthNeedsOnboarding(
          UserModel(id: '1', username: 'alex', email: 'alex@example.com'),
        ),
      );
      final notifier = container.read(routerNotifierProvider);
      when(() => mockRouterState.matchedLocation).thenReturn('/verify-otp');

      final redirect = notifier.redirect(mockContext, mockRouterState);
      expect(redirect, isNull);
    });

    test('Does NOT redirect away from /reset-password when AuthAuthenticated', () {
      testAuthNotifier.setTestState(
        const AuthAuthenticated(
          UserModel(id: '1', username: 'alex', email: 'alex@example.com'),
        ),
      );
      final notifier = container.read(routerNotifierProvider);
      when(() => mockRouterState.matchedLocation).thenReturn('/reset-password');

      final redirect = notifier.redirect(mockContext, mockRouterState);
      expect(redirect, isNull);
    });

    test('Does NOT redirect away from /reset-password when AuthNeedsOnboarding', () {
      testAuthNotifier.setTestState(
        const AuthNeedsOnboarding(
          UserModel(id: '1', username: 'alex', email: 'alex@example.com'),
        ),
      );
      final notifier = container.read(routerNotifierProvider);
      when(() => mockRouterState.matchedLocation).thenReturn('/reset-password');

      final redirect = notifier.redirect(mockContext, mockRouterState);
      expect(redirect, isNull);
    });

    test('Redirects to /onboarding when AuthNeedsOnboarding and on other protected routes', () {
      testAuthNotifier.setTestState(
        const AuthNeedsOnboarding(
          UserModel(id: '1', username: 'alex', email: 'alex@example.com'),
        ),
      );
      final notifier = container.read(routerNotifierProvider);
      when(() => mockRouterState.matchedLocation).thenReturn('/feed');

      final redirect = notifier.redirect(mockContext, mockRouterState);
      expect(redirect, '/onboarding');
    });
  });
}
