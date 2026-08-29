import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/features/communities/data/models/community_models.dart';
import 'package:client/features/communities/data/repositories/community_repository.dart';
import 'package:client/features/communities/presentation/notifiers/create_community_notifier.dart';

class MockCommunityRepository extends Mock implements CommunityRepository {}

class FakeCommunityCreateRequestModel extends Fake
    implements CommunityCreateRequestModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeCommunityCreateRequestModel());
  });

  late MockCommunityRepository mockRepository;

  const testCreated = CommunityModel(
    id: 'comm-created-1',
    ownerId: 'owner-me',
    name: 'Mobile Dev Hub',
    slug: 'mobile-dev-hub',
    description: 'Flutter & Kotlin devs',
    isPrivate: false,
  );

  setUp(() {
    mockRepository = MockCommunityRepository();
  });

  group('CreateCommunityNotifier Unit Tests', () {
    test('updates inputs and auto-generates slug from name', () {
      final notifier = CreateCommunityNotifier(repository: mockRepository);

      notifier.setName('Mobile Dev Hub');
      expect(notifier.state.name, 'Mobile Dev Hub');
      expect(notifier.state.slug, 'mobile-dev-hub');

      notifier.setDescription('Flutter & Kotlin devs');
      expect(notifier.state.description, 'Flutter & Kotlin devs');

      notifier.setIsPrivate(true);
      expect(notifier.state.isPrivate, isTrue);
    });

    test('validates short names and fails submission', () async {
      final notifier = CreateCommunityNotifier(repository: mockRepository);
      notifier.setName('A');

      final success = await notifier.submitCommunity();
      expect(success, isFalse);
      expect(notifier.state.errorMessage, isNotNull);
    });

    test('submits valid community creation successfully', () async {
      when(() => mockRepository.createCommunity(any()))
          .thenAnswer((_) async => testCreated);

      final notifier = CreateCommunityNotifier(repository: mockRepository);
      notifier.setName('Mobile Dev Hub');
      notifier.setDescription('Flutter & Kotlin devs');

      final success = await notifier.submitCommunity();
      expect(success, isTrue);
      expect(notifier.state.isSuccess, isTrue);
      expect(notifier.state.createdCommunity?.id, 'comm-created-1');
      verify(() => mockRepository.createCommunity(any())).called(1);
    });
  });
}
