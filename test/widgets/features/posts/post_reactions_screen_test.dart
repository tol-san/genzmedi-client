import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/features/posts/data/models/reaction_models.dart';
import 'package:client/features/posts/data/repositories/post_repository.dart';
import 'package:client/features/posts/presentation/screens/post_reactions_screen.dart';

class MockPostRepository extends Mock implements PostRepository {}

void main() {
  late MockPostRepository mockPostRepository;

  const testReactions = PostReactionsModel(
    total: 399,
    counts: {'all': 399, 'like': 399},
    items: [
      ReactorUserModel(
        id: 'u-react-1',
        username: 'kim_chanthorn',
        displayName: 'Kim Chanthorn',
        reactionType: 'like',
        mutualCount: 26,
      ),
      ReactorUserModel(
        id: 'u-react-2',
        username: 'rayya_yuma',
        displayName: 'Rayya Yuma',
        reactionType: 'like',
        mutualCount: 23,
      ),
    ],
  );

  setUp(() {
    mockPostRepository = MockPostRepository();
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        postRepositoryProvider.overrideWithValue(mockPostRepository),
      ],
      child: const MaterialApp(
        home: PostReactionsScreen(postId: 'post-123'),
      ),
    );
  }

  group('PostReactionsScreen Widget Tests', () {
    testWidgets('renders likes header, filter chip, heart badges, and user list', (tester) async {
      when(() => mockPostRepository.getPostReactions('post-123', query: any(named: 'query')))
          .thenAnswer((_) async => testReactions);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Likes'), findsOneWidget);
      expect(find.text('All 399'), findsOneWidget);
      expect(find.text('Kim Chanthorn'), findsOneWidget);
      expect(find.text('26 mutual connections'), findsOneWidget);
      expect(find.text('Rayya Yuma'), findsOneWidget);
      expect(find.text('Mention'), findsNWidgets(2));
      expect(find.byIcon(Icons.favorite_rounded), findsWidgets);
    });

    testWidgets('searches and filters user list dynamically', (tester) async {
      when(() => mockPostRepository.getPostReactions('post-123', query: any(named: 'query')))
          .thenAnswer((_) async => testReactions);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();

      // Enter query
      await tester.enterText(find.byType(TextField), 'Rayya');
      await tester.pumpAndSettle();

      expect(find.text('Rayya Yuma'), findsOneWidget);
      expect(find.text('Kim Chanthorn'), findsNothing);
    });
  });
}
