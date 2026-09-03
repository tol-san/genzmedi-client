import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/features/posts/presentation/screens/create_hub_screen.dart';

void main() {
  Widget buildTestWidget() {
    return const MaterialApp(home: CreateHubScreen());
  }

  group('CreateHubScreen Widget Tests', () {
    testWidgets('renders polished format picker and creation choices', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Create'), findsOneWidget);
      expect(find.text('What are you posting?'), findsOneWidget);
      expect(find.text('Pick a format and make it yours.'), findsOneWidget);
      expect(find.text('Choose a format'), findsOneWidget);

      expect(find.text('Text post'), findsOneWidget);
      expect(
        find.text('Start a thought, story, or discussion'),
        findsOneWidget,
      );

      expect(find.text('Multi-image post'), findsOneWidget);
      expect(find.text('Share a carousel of up to 10 photos'), findsOneWidget);

      expect(find.text('Short video'), findsOneWidget);
      expect(
        find.text('Upload a vertical clip with a cover image'),
        findsOneWidget,
      );

      expect(find.text('Poll'), findsOneWidget);
      expect(find.text('COMING SOON'), findsOneWidget);
    });

    testWidgets('tapping Poll shows coming soon snackbar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Poll'));
      await tester.pump();

      expect(find.text('Polls are coming soon to GenZ Media!'), findsOneWidget);
    });
  });
}
