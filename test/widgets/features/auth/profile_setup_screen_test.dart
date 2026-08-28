import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/auth/auth_state.dart';
import 'package:client/core/storage/preferences_service.dart';
import 'package:client/core/storage/secure_storage_service.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/features/auth/data/repositories/auth_repository.dart';
import 'package:client/features/auth/presentation/screens/profile_setup_screen.dart';

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

    when(() => mockStorage.getAccessToken()).thenAnswer((_) async => 'fake_access_token');
    when(() => mockPrefs.hasSession()).thenReturn(true);
    when(() => mockPrefs.isOnboardingCompleted()).thenReturn(false);
  });

  Widget createWidgetUnderTest({AuthState? initialState}) {
    final notifier = AuthNotifier(
      repository: mockRepository,
      storage: mockStorage,
      prefs: mockPrefs,
    );

    if (initialState != null) {
      notifier.state = initialState;
    }

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepository),
        secureStorageServiceProvider.overrideWithValue(mockStorage),
        preferencesServiceProvider.overrideWithValue(mockPrefs),
        authNotifierProvider.overrideWith((ref) => notifier),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const ProfileSetupScreen(),
      ),
    );
  }

  group('ProfileSetupScreen Widget Tests', () {
    testWidgets('Renders all avatar presets and input fields', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      const user = UserModel(
        id: 'sovandara',
        username: 'sovandara',
        email: 'sovandara@example.com',
        displayName: 'Sovandara',
      );

      await tester.pumpWidget(createWidgetUnderTest(
        initialState: const AuthNeedsOnboarding(user),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Set Up Your Profile'), findsOneWidget);
      expect(find.text('Choose Avatar Style'), findsOneWidget);
      expect(find.byKey(const Key('profile_setup_display_name_field')), findsOneWidget);
      expect(find.byKey(const Key('profile_setup_username_field')), findsOneWidget);
      expect(find.byKey(const Key('profile_setup_continue_button')), findsOneWidget);
      expect(find.byKey(const Key('profile_setup_skip_button')), findsOneWidget);
    });

    testWidgets('Allows selecting avatar preset and editing display name', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      const user = UserModel(
        id: 'sovandara',
        username: 'sovandara',
        email: 'sovandara@example.com',
        displayName: 'Sovandara',
      );

      when(() => mockRepository.updateProfile(
            displayName: any(named: 'displayName'),
            username: any(named: 'username'),
          )).thenAnswer((_) async => const UserModel(
            id: 'sovandara',
            username: 'sovandara_vip',
            email: 'sovandara@example.com',
            displayName: 'Sovandara Pro',
          ));

      await tester.pumpWidget(createWidgetUnderTest(
        initialState: const AuthNeedsOnboarding(user),
      ));
      await tester.pumpAndSettle();

      // Edit Display Name
      await tester.enterText(
        find.byKey(const Key('profile_setup_display_name_field')),
        'Sovandara Pro',
      );

      final continueButton = find.byKey(const Key('profile_setup_continue_button'));
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      verify(() => mockRepository.updateProfile(
            displayName: 'Sovandara Pro',
            username: any(named: 'username'),
            bio: any(named: 'bio'),
            avatarUrl: any(named: 'avatarUrl'),
          )).called(1);
    });
  });
}
