import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/features/posts/presentation/screens/create_hub_screen.dart';

void main() {
  Widget buildTestWidget() {
    return const MaterialApp(home: CreateHubScreen());
  }

  group('CreateHubScreen Widget Tests', () {
    testWidgets('renders streamlined format picker with removed banner, badges, poll, and arrows', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Create'), findsOneWidget);
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

      // Verify removed elements are not present
      expect(find.text('What are you posting?'), findsNothing);
      expect(find.text('Pick a format and make it yours.'), findsNothing);
      expect(find.text('SHORT'), findsNothing);
      expect(find.text('UP TO 10'), findsNothing);
      expect(find.text('Poll'), findsNothing);
      expect(find.text('COMING SOON'), findsNothing);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    });
  });
}
