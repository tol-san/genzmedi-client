import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/app/app.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/core/storage/preferences_service.dart';
import 'package:client/core/storage/secure_storage_service.dart';
import 'package:client/features/auth/data/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockSecureStorageService extends Mock implements SecureStorageService {}
class MockPreferencesService extends Mock implements PreferencesService {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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

    when(() => mockStorage.getAccessToken()).thenAnswer((_) async => 'valid_access_token');
    when(() => mockPrefs.hasSession()).thenReturn(true);
    when(() => mockPrefs.isOnboardingCompleted()).thenReturn(true);

    when(() => mockRepository.getMyProfile()).thenAnswer(
      (_) async => const UserModel(
        id: '123',
        username: 'alex',
        email: 'alex@genz.media',
        interests: ['Tech', 'Gaming'],
      ),
    );
  });

  testWidgets('E2E Shell Navigation: Switch between 5 tabs', (tester) async {
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

    // 1. User starts on Home tab
    expect(find.text('Explore & For You'), findsOneWidget);

    // 2. Tap Shorts tab
    await tester.tap(find.text('Shorts'));
    await tester.pumpAndSettle();
    expect(find.text('Shorts'), findsAtLeastNWidgets(1));

    // 3. Tap Discover tab
    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();
    expect(find.text('Discover'), findsAtLeastNWidgets(1));

    // 4. Tap Profile tab
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsAtLeastNWidgets(1));

    // 5. Tap Home tab
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Explore & For You'), findsOneWidget);
  });
}
