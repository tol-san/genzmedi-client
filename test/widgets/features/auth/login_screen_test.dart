import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/core/storage/preferences_service.dart';
import 'package:client/core/storage/secure_storage_service.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/auth/data/models/auth_models.dart';
import 'package:client/features/auth/data/repositories/auth_repository.dart';
import 'package:client/features/auth/presentation/screens/login_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockSecureStorageService extends Mock implements SecureStorageService {}
class MockPreferencesService extends Mock implements PreferencesService {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(const LoginRequest(username: '', password: ''));
  });

  late MockAuthRepository mockRepository;
  late MockSecureStorageService mockStorage;
  late MockPreferencesService mockPrefs;

  setUp(() {
    mockRepository = MockAuthRepository();
    mockStorage = MockSecureStorageService();
    mockPrefs = MockPreferencesService();

    when(() => mockStorage.getAccessToken()).thenAnswer((_) async => null);
    when(() => mockPrefs.hasSession()).thenReturn(false);
    when(() => mockPrefs.isOnboardingCompleted()).thenReturn(false);
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
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const LoginScreen(),
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('Renders all login elements correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Sign in to your account'), findsOneWidget);
      expect(find.byKey(const Key('login_username_field')), findsOneWidget);
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('Displays error labels and banner when submitted with empty fields', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter both your username/email and password.'),
        findsOneWidget,
      );
      expect(find.text('Please enter your username or email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Displays error labels on incorrect username or password failure', (tester) async {
      when(() => mockRepository.login(any())).thenThrow(
        const UnauthorizedException('Invalid email/username or password.'),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('login_username_field')),
        'wronguser',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'wrongpass',
      );

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Invalid email/username or password.'), findsOneWidget);
      expect(find.text('Invalid username or email'), findsOneWidget);
      expect(find.text('Invalid password'), findsOneWidget);
    });

    testWidgets('Displays error label when username is too short or invalid email', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Username too short (< 3 chars)
      await tester.enterText(
        find.byKey(const Key('login_username_field')),
        'ab',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'password123',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Username must be at least 3 characters'), findsOneWidget);

      // Invalid email format
      await tester.enterText(
        find.byKey(const Key('login_username_field')),
        'notanemail@',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('Displays error label when password is too short (< 6 chars)', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('login_username_field')),
        'sovandara',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        '123',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('Clears error label when typing in the field', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your username or email'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('login_username_field')),
        'alex',
      );
      await tester.pumpAndSettle();

      expect(find.text('Please enter your username or email'), findsNothing);
    });
  });
}
