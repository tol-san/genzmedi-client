import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/posts/data/repositories/post_repository.dart';
import 'package:client/features/posts/presentation/screens/edit_post_screen.dart';

class MockPostRepository extends Mock implements PostRepository {}

void main() {
  late MockPostRepository mockPostRepository;

  const samplePost = PostModel(
    id: 'post-99',
    author: PostAuthorModel(
      id: 'author-1',
      username: 'creator_test',
      displayName: 'Creator Test',
    ),
    title: 'Initial Title',
    content: 'Initial content of the post.',
    visibility: 'public',
    likeCount: 5,
    commentCount: 2,
    media: [
      MediaItemModel(
        id: 'm-1',
        mediaType: 'image',
        url: 'https://example.com/photo.jpg',
      ),
    ],
  );

  setUp(() {
    mockPostRepository = MockPostRepository();
  });

  Widget buildTestWidget({PostModel? initialPost}) {
    return ProviderScope(
      overrides: [
        postRepositoryProvider.overrideWithValue(mockPostRepository),
      ],
      child: MaterialApp(
        home: EditPostScreen(
          postId: 'post-99',
          initialPost: initialPost ?? samplePost,
        ),
      ),
    );
  }

  group('EditPostScreen Widget Tests', () {
    testWidgets('renders existing post data and visibility options', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Edit Post'), findsOneWidget);
      expect(find.text('Initial Title'), findsOneWidget);
      expect(find.text('Initial content of the post.'), findsOneWidget);
      expect(find.text('Post Visibility'), findsOneWidget);
      expect(find.text('Public'), findsOneWidget);
      expect(find.text('Followers Only'), findsOneWidget);
      expect(find.text('Private'), findsOneWidget);
      expect(find.text('Attached Media (1)'), findsOneWidget);
    });

    testWidgets('shows validation error when content and title are empty', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Clear title and content
      await tester.enterText(find.byType(TextField).first, '');
      await tester.enterText(find.byType(TextField).at(1), '');

      // Tap Save in AppBar
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();

      expect(
        find.text('Post content or title cannot be empty.'),
        findsOneWidget,
      );
    });

    testWidgets('can change visibility and save updated post', (tester) async {
      when(
        () => mockPostRepository.updatePost(
          'post-99',
          title: any(named: 'title'),
          content: any(named: 'content'),
          visibility: 'followers_only',
        ),
      ).thenAnswer(
        (_) async => samplePost.copyWith(
          title: 'Updated Title',
          content: 'Updated content.',
          visibility: 'followers_only',
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Change title
      await tester.enterText(find.byType(TextField).first, 'Updated Title');
      // Tap Followers Only visibility
      await tester.tap(find.text('Followers Only'));
      await tester.pumpAndSettle();

      // Save via AppBar
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pump();

      verify(
        () => mockPostRepository.updatePost(
          'post-99',
          title: 'Updated Title',
          content: 'Initial content of the post.',
          visibility: 'followers_only',
        ),
      ).called(1);
    });

    testWidgets('displays error message when update fails', (tester) async {
      when(
        () => mockPostRepository.updatePost(
          'post-99',
          title: any(named: 'title'),
          content: any(named: 'content'),
          visibility: any(named: 'visibility'),
        ),
      ).thenThrow(Exception('Server error'));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();

      expect(
        find.text('Failed to update post. Please try again.'),
        findsOneWidget,
      );
    });
  });
}
