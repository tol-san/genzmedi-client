import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/features/posts/data/repositories/post_repository.dart';
import 'package:client/features/posts/presentation/screens/create_post_screen.dart';

class MockPostRepository extends Mock implements PostRepository {}

void main() {
  late MockPostRepository mockPostRepository;

  setUp(() {
    mockPostRepository = MockPostRepository();
  });

  Widget buildTestWidget({String initialType = 'text'}) {
    return ProviderScope(
      overrides: [
        postRepositoryProvider.overrideWithValue(mockPostRepository),
      ],
      child: MaterialApp(
        home: CreatePostScreen(initialPostType: initialType),
      ),
    );
  }

  group('CreatePostScreen Widget Tests', () {
    testWidgets('renders segmented type switcher, title, and content inputs', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Text'), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('Short Video'), findsOneWidget);
      expect(find.text('Title (Optional)'), findsOneWidget);
      expect(find.text('Post Content'), findsOneWidget);
      expect(find.text('Publish'), findsOneWidget);
    });

    testWidgets('switches to photos tab and displays photo picker placeholder', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Photos'));
      await tester.pumpAndSettle();

      expect(find.text('Select Photos from Gallery'), findsOneWidget);
    });

    testWidgets('switches to short video tab and displays video picker placeholder', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Short Video'));
      await tester.pumpAndSettle();

      expect(find.text('Select Video from Gallery'), findsOneWidget);
    });
  });
}
