import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/features/posts/presentation/screens/create_hub_screen.dart';

void main() {
  Widget buildTestWidget() {
    return const MaterialApp(
      home: CreateHubScreen(),
    );
  }

  group('CreateHubScreen Widget Tests', () {
    testWidgets('renders compact top title Create, heading, and 4 content options', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Create'), findsOneWidget);
      expect(find.text('What are you posting?'), findsOneWidget);
      expect(find.text('Post directly to your profile or contribute to a community.'), findsOneWidget);

      expect(find.text('🎬 Video'), findsOneWidget);
      expect(find.text('Post a short video'), findsOneWidget);

      expect(find.text('🖼️ Photo'), findsOneWidget);
      expect(find.text('Share one or multiple photos'), findsOneWidget);

      expect(find.text('💬 Post'), findsOneWidget);
      expect(find.text('Share a thought, story, or discussion'), findsOneWidget);

      expect(find.text('📊 Poll'), findsOneWidget);
      expect(find.text('Ask the community'), findsOneWidget);
    });

    testWidgets('tapping Poll shows coming soon snackbar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('📊 Poll'));
      await tester.pump();

      expect(find.text('Polls are coming soon to GenZ Media!'), findsOneWidget);
    });
  });
}
