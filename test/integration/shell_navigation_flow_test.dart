import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
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

  group('Full E2E Shell Navigation Flow Integration Test', () {
    testWidgets('Switches tabs across the 5 Shell destinations smoothly', (tester) async {
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

      // 1. Home Feed
      expect(find.text('Your feed is just getting started'), findsOneWidget);

      // 2. Switch to Shorts
      await tester.tap(find.text('Shorts'));
      await tester.pumpAndSettle();
      expect(find.text('Shorts Video Feed'), findsOneWidget);

      // 3. Switch to Discover
      await tester.tap(find.text('Discover'));
      await tester.pumpAndSettle();
      expect(find.text('Trending Topics'), findsOneWidget);

      // 4. Switch to Profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('@alex'), findsOneWidget);

      // 5. Back to Home
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Your feed is just getting started'), findsOneWidget);
    });
  });
}
