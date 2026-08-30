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
    counts: {'all': 399, 'like': 312, 'love': 85, 'care': 2},
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
        reactionType: 'love',
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
    testWidgets('renders reaction header, filter pill chips, and reactor user list', (tester) async {
      when(() => mockPostRepository.getPostReactions('post-123', query: any(named: 'query')))
          .thenAnswer((_) async => testReactions);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Reactions'), findsOneWidget);
      expect(find.text('All 399'), findsOneWidget);
      expect(find.text('312'), findsOneWidget);
      expect(find.text('85'), findsOneWidget);
      expect(find.text('Kim Chanthorn'), findsOneWidget);
      expect(find.text('26 mutual connections'), findsOneWidget);
      expect(find.text('Rayya Yuma'), findsOneWidget);
      expect(find.text('Mention'), findsNWidgets(2));
    });

    testWidgets('filters list by reaction type tab', (tester) async {
      when(() => mockPostRepository.getPostReactions('post-123', query: any(named: 'query')))
          .thenAnswer((_) async => testReactions);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap on the Love tab (85)
      await tester.tap(find.text('85'));
      await tester.pumpAndSettle();

      expect(find.text('Rayya Yuma'), findsOneWidget);
      expect(find.text('Kim Chanthorn'), findsNothing);
    });
  });
}
