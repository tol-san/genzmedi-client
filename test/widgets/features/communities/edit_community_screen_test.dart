import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/features/communities/data/models/community_models.dart';
import 'package:client/features/communities/data/repositories/community_repository.dart';
import 'package:client/features/communities/presentation/screens/edit_community_screen.dart';

class MockCommunityRepository extends Mock implements CommunityRepository {}

void main() {
  late MockCommunityRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(const CommunityUpdateRequestModel());
  });

  const testCommunity = CommunityModel(
    id: 'comm-edit-1',
    ownerId: 'owner-1',
    name: 'Cyberpunk Builders',
    slug: 'cyberpunk-builders',
    description: 'A community dedicated to cyberpunk architecture and lore.',
    isPrivate: false,
    memberCount: 120,
    postCount: 18,
  );

  setUp(() {
    mockRepository = MockCommunityRepository();
    when(() => mockRepository.getCommunity('comm-edit-1'))
        .thenAnswer((_) async => const CommunityDetailModel(
              community: testCommunity,
              isOwner: true,
              isMember: true,
            ));
  });

  Widget buildTestWidget({CommunityModel? initialCommunity}) {
    return ProviderScope(
      overrides: [
        communityRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: MaterialApp(
        routes: {
          '/': (_) => const Scaffold(body: Text('Root')),
          '/edit': (_) => EditCommunityScreen(
                communityId: 'comm-edit-1',
                initialCommunity: initialCommunity ?? testCommunity,
              ),
        },
        initialRoute: '/edit',
      ),
    );
  }

  group('EditCommunityScreen Widget Tests', () {
    testWidgets('renders existing community data in fields and controls',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Edit Community'), findsWidgets);
      expect(find.text('Cyberpunk Builders'), findsOneWidget);
      expect(
        find.text('A community dedicated to cyberpunk architecture and lore.'),
        findsOneWidget,
      );
      expect(find.text('Public Community'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Danger Zone'), findsOneWidget);
      expect(find.text('Delete Community'), findsOneWidget);
    });

    testWidgets('shows validation error when community name is too short',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextField, 'Cyberpunk Builders');
      await tester.enterText(nameField, 'X');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.text('Community name must be at least 2 characters.'),
        findsOneWidget,
      );
      verifyNever(() => mockRepository.updateCommunity(any(), any()));
    });

    testWidgets('updates community settings and calls repository on save',
        (tester) async {
      when(() => mockRepository.updateCommunity(
            'comm-edit-1',
            any(),
          )).thenAnswer(
        (_) async => testCommunity.copyWith(
          name: 'Cyberpunk Builders 2077',
          description: 'Updated description.',
          isPrivate: true,
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Update name
      final nameField = find.widgetWithText(TextField, 'Cyberpunk Builders');
      await tester.enterText(nameField, 'Cyberpunk Builders 2077');
      await tester.pumpAndSettle();

      // Update description
      final descField = find.widgetWithText(
        TextField,
        'A community dedicated to cyberpunk architecture and lore.',
      );
      await tester.enterText(descField, 'Updated description.');
      await tester.pumpAndSettle();

      // Toggle privacy switch
      final switchFinder = find.byType(Switch);
      await tester.ensureVisible(switchFinder);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(find.text('Private Community'), findsOneWidget);

      // Tap Save in AppBar
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.updateCommunity(
            'comm-edit-1',
            any(
              that: isA<CommunityUpdateRequestModel>().having(
                (m) => m.name,
                'name',
                'Cyberpunk Builders 2077',
              ).having(
                (m) => m.description,
                'description',
                'Updated description.',
              ).having(
                (m) => m.isPrivate,
                'isPrivate',
                true,
              ),
            ),
          )).called(1);
    });

    testWidgets('shows typed-name confirmation dialog and deletes community',
        (tester) async {
      when(() => mockRepository.deleteCommunity('comm-edit-1'))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Delete Community button in Danger Zone
      final deleteBtn = find.widgetWithText(OutlinedButton, 'Delete Community');
      await tester.ensureVisible(deleteBtn);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Dialog is open
      expect(find.text('Delete Community?'), findsOneWidget);
      expect(
        find.text('To confirm, type "Cyberpunk Builders" below:'),
        findsOneWidget,
      );

      // The dialog confirm button is disabled initially
      final dialogDeleteBtn = find.widgetWithText(ElevatedButton, 'Delete Community');
      expect(tester.widget<ElevatedButton>(dialogDeleteBtn).enabled, isFalse);

      // Type incorrect name
      final confirmField = find.byKey(const Key('confirm_delete_field'));
      await tester.enterText(confirmField, 'Wrong Name');
      await tester.pumpAndSettle();
      expect(tester.widget<ElevatedButton>(dialogDeleteBtn).enabled, isFalse);

      // Type correct name
      await tester.enterText(confirmField, 'Cyberpunk Builders');
      await tester.pumpAndSettle();
      expect(tester.widget<ElevatedButton>(dialogDeleteBtn).enabled, isTrue);

      // Tap Delete Community in dialog
      await tester.tap(dialogDeleteBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      verify(() => mockRepository.deleteCommunity('comm-edit-1')).called(1);
    });
  });
}
