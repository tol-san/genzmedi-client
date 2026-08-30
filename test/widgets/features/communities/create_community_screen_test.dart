import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/features/communities/data/repositories/community_repository.dart';
import 'package:client/features/communities/presentation/screens/create_community_screen.dart';

class MockCommunityRepository extends Mock implements CommunityRepository {}

void main() {
  late MockCommunityRepository mockRepository;

  setUp(() {
    mockRepository = MockCommunityRepository();
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        communityRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: const MaterialApp(
        home: CreateCommunityScreen(),
      ),
    );
  }

  group('CreateCommunityScreen Widget Tests', () {
    testWidgets(
        'renders name, description, cover banner, avatar icon, privacy toggle, and submit button',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Create Community'), findsWidgets);
      expect(find.text('Community Name'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Public Community'), findsOneWidget);
      expect(find.text('Add Cover Banner (Optional)'), findsOneWidget);
      expect(find.text('Tap banner to add cover · Tap circle to add logo'),
          findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
    });

    testWidgets('toggles privacy switch to private community', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      await tester.ensureVisible(switchFinder);
      await tester.pumpAndSettle();

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(find.text('Private Community'), findsOneWidget);
    });
  });
}
