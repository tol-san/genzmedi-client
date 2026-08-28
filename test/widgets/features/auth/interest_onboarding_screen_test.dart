import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/storage/preferences_service.dart';
import 'package:client/core/storage/secure_storage_service.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/auth/data/models/auth_models.dart';
import 'package:client/features/auth/data/repositories/auth_repository.dart';
import 'package:client/features/auth/presentation/screens/interest_onboarding_screen.dart';

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

    when(() => mockRepository.getInterests()).thenAnswer(
      (_) async => const [
        InterestModel(id: '1', name: 'Technology', slug: 'technology', icon: '💻'),
        InterestModel(id: '2', name: 'Gaming', slug: 'gaming', icon: '🎮'),
        InterestModel(id: '3', name: 'Music', slug: 'music', icon: '🎵'),
        InterestModel(id: '4', name: 'Anime', slug: 'anime', icon: '🎬'),
      ],
    );
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
        home: const InterestOnboardingScreen(),
      ),
    );
  }

  group('InterestOnboardingScreen Widget Tests', () {
    testWidgets('Renders interest catalog chips', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Choose what you\'re into'), findsOneWidget);
      expect(find.text('Technology'), findsOneWidget);
      expect(find.text('Gaming'), findsOneWidget);
      expect(find.text('Music'), findsOneWidget);
      expect(find.text('Anime'), findsOneWidget);
    });

    testWidgets('Toggles chip selection and updates counter', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Select 3 more'), findsOneWidget);

      // Tap on Technology and Gaming
      await tester.tap(find.text('Technology'));
      await tester.pump();
      expect(find.text('Select 2 more'), findsOneWidget);

      await tester.tap(find.text('Gaming'));
      await tester.pump();
      expect(find.text('Select 1 more'), findsOneWidget);

      // Select 3rd item
      await tester.tap(find.text('Music'));
      await tester.pump();

      expect(find.text('✓ 3 selected'), findsOneWidget);
    });
  });
}
