import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/storage/preferences_service.dart';
import 'package:client/core/storage/secure_storage_service.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/auth/data/repositories/auth_repository.dart';
import 'package:client/features/auth/presentation/screens/register_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockSecureStorageService extends Mock implements SecureStorageService {}
class MockPreferencesService extends Mock implements PreferencesService {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
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
        home: const RegisterScreen(),
      ),
    );
  }

  group('RegisterScreen Widget Tests', () {
    testWidgets('Renders email and password fields and submit button', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsNWidgets(2)); // Title and Button
      expect(find.byKey(const Key('register_email_field')), findsOneWidget);
      expect(find.byKey(const Key('register_password_field')), findsOneWidget);
      expect(find.byKey(const Key('register_submit_button')), findsOneWidget);
    });

    testWidgets('Shows error if email is invalid or password is too short', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('register_email_field')),
        'invalid-email',
      );
      await tester.enterText(
        find.byKey(const Key('register_password_field')),
        'short',
      );

      final submitFinder = find.byKey(const Key('register_submit_button'));
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address.'), findsOneWidget);
      expect(find.text('Password must be at least 8 characters long.'), findsOneWidget);
    });
  });
}
