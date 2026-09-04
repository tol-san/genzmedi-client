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
import 'package:client/features/feeds/data/repositories/feed_repository.dart';
import 'package:client/features/feeds/presentation/screens/shorts_feed_screen.dart';
import 'package:client/features/notifications/data/repositories/notification_repository.dart';
import 'package:client/features/notifications/presentation/notifiers/notification_center_notifier.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/profiles/data/repositories/profile_repository.dart';
import 'package:client/features/search/data/models/discovery_models.dart';
import 'package:client/features/search/data/repositories/discovery_repository.dart';
import 'package:client/features/search/presentation/screens/discover_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockPreferencesService extends Mock implements PreferencesService {}

class MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class MockFeedRepository extends Mock implements FeedRepository {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late MockAuthRepository mockRepository;
  late MockProfileRepository mockProfileRepository;
  late MockSecureStorageService mockStorage;
  late MockPreferencesService mockPrefs;
  late MockDiscoveryRepository mockDiscoveryRepository;
  late MockNotificationRepository mockNotificationRepository;
  late MockFeedRepository mockFeedRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    mockProfileRepository = MockProfileRepository();
    mockStorage = MockSecureStorageService();
    mockPrefs = MockPreferencesService();
    mockDiscoveryRepository = MockDiscoveryRepository();
    mockNotificationRepository = MockNotificationRepository();
    mockFeedRepository = MockFeedRepository();

    when(
      () => mockFeedRepository.getHomeFeed(
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => <PostModel>[]);
    when(
      () => mockFeedRepository.getShortsFeed(
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => <PostModel>[]);

    when(() => mockStorage.getAccessToken())
        .thenAnswer((_) async => 'valid_access_token');
    when(() => mockPrefs.hasSession()).thenReturn(true);
    when(() => mockPrefs.isOnboardingCompleted()).thenReturn(true);

    const user = UserModel(
      id: '123',
      username: 'alex',
      email: 'alex@genz.media',
      interests: ['Tech', 'Gaming'],
    );

    when(() => mockRepository.getMyProfile()).thenAnswer((_) async => user);
    when(() => mockProfileRepository.getMyProfile())
        .thenAnswer((_) async => user);
    when(() => mockProfileRepository.getUserPosts(authorId: '123'))
        .thenAnswer((_) async => <PostModel>[]);
    when(() => mockProfileRepository.getSavedPosts())
        .thenAnswer((_) async => <PostModel>[]);

    when(
      () => mockDiscoveryRepository.getRecommendedCommunities(
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer(
      (_) async => const DiscoveryPage<DiscoverCommunityModel>(
        items: [],
        total: 0,
        limit: 10,
        offset: 0,
      ),
    );
    when(
      () => mockDiscoveryRepository.getJoinedCommunities(
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer(
      (_) async => const DiscoveryPage<DiscoverCommunityModel>(
        items: [],
        total: 0,
        limit: 20,
        offset: 0,
      ),
    );
  });

  group('Full E2E Shell Navigation Flow Integration Test', () {
    testWidgets('Switches tabs across the 5 Shell destinations smoothly', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepository),
            feedRepositoryProvider.overrideWithValue(mockFeedRepository),
            profileRepositoryProvider.overrideWithValue(mockProfileRepository),
            discoveryRepositoryProvider.overrideWithValue(
              mockDiscoveryRepository,
            ),
            notificationCenterProvider.overrideWith(
              (ref) => NotificationCenterNotifier(
                repository: mockNotificationRepository,
                loadOnCreate: false,
              ),
            ),
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
      expect(find.byType(ShortsFeedScreen), findsOneWidget);

      // 3. Switch to Discover
      await tester.tap(find.text('Discover'));
      await tester.pumpAndSettle();
      expect(find.byType(DiscoverScreen), findsOneWidget);

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
