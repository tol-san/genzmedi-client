import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/auth/auth_state.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/features/posts/data/models/comment_model.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/posts/data/repositories/comment_repository.dart';
import 'package:client/features/posts/data/repositories/post_repository.dart';
import 'package:client/features/posts/presentation/screens/post_detail_screen.dart';

class MockPostRepository extends Mock implements PostRepository {}

class MockCommentRepository extends Mock implements CommentRepository {}

class AuthNotifierMock extends StateNotifier<AuthState>
    implements AuthNotifier {
  AuthNotifierMock(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockPostRepository mockPostRepository;
  late MockCommentRepository mockCommentRepository;

  const currentUser = UserModel(
    id: 'author-2',
    username: 'mark_reader',
    email: 'mark@example.com',
  );

  const testPost = PostModel(
    id: 'p-detail-1',
    author: PostAuthorModel(
      id: 'author-1',
      username: 'sarah_dev',
      displayName: 'Sarah Developer',
    ),
    title: 'Post Details Title',
    content: 'Full description of the post content.',
    likeCount: 12,
    saveCount: 3,
    commentCount: 1,
  );

  const testComment = CommentModel(
    id: 'c-1',
    postId: 'p-detail-1',
    author: CommentAuthorModel(
      id: 'author-2',
      username: 'mark_reader',
      displayName: 'Mark Reader',
    ),
    content: 'Insightful post!',
  );

  setUp(() {
    mockPostRepository = MockPostRepository();
    mockCommentRepository = MockCommentRepository();
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        postRepositoryProvider.overrideWithValue(mockPostRepository),
        commentRepositoryProvider.overrideWithValue(mockCommentRepository),
        authNotifierProvider.overrideWith(
          (ref) => AuthNotifierMock(const AuthAuthenticated(currentUser)),
        ),
      ],
      child: const MaterialApp(
        home: PostDetailScreen(postId: 'p-detail-1'),
      ),
    );
  }

  group('PostDetailScreen Widget Tests', () {
    testWidgets('renders author, post content, counters, and comment thread', (tester) async {
      when(() => mockPostRepository.getPost('p-detail-1'))
          .thenAnswer((_) async => testPost);
      when(() => mockCommentRepository.getComments('p-detail-1', limit: 20, offset: 0))
          .thenAnswer((_) async => [testComment]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Sarah Developer'), findsOneWidget);
      expect(find.text('Full description of the post content.'), findsOneWidget);
      expect(find.text('Post Details Title'), findsNothing);
      expect(find.text('Discussion (1)'), findsOneWidget);
      expect(find.text('Mark Reader'), findsOneWidget);
      expect(find.text('Insightful post!'), findsOneWidget);
      expect(find.text('Add a comment...'), findsOneWidget);
    });

    testWidgets('renders empty comments placeholder when no comments exist', (tester) async {
      when(() => mockPostRepository.getPost('p-detail-1'))
          .thenAnswer((_) async => testPost);
      when(() => mockCommentRepository.getComments('p-detail-1', limit: 20, offset: 0))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No comments yet. Be the first to share your thoughts!'), findsOneWidget);
    });

    testWidgets('shows report option in overflow menu for non-author', (tester) async {
      when(() => mockPostRepository.getPost('p-detail-1'))
          .thenAnswer((_) async => testPost);
      when(() => mockCommentRepository.getComments('p-detail-1', limit: 20, offset: 0))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Report post'), findsOneWidget);
      expect(find.text('Share post'), findsOneWidget);
      expect(find.text('Copy link'), findsOneWidget);
      expect(find.text('Edit post'), findsNothing);
      expect(find.text('Delete post'), findsNothing);
    });

    testWidgets('shows edit and delete options in overflow menu for author and deletes post', (tester) async {
      when(() => mockPostRepository.getPost('p-detail-1'))
          .thenAnswer((_) async => testPost);
      when(() => mockCommentRepository.getComments('p-detail-1', limit: 20, offset: 0))
          .thenAnswer((_) async => []);
      when(() => mockPostRepository.deletePost('p-detail-1'))
          .thenAnswer((_) async {});

      // Author user matching testPost.author.id ('author-1')
      const authorUser = UserModel(
        id: 'author-1',
        username: 'sarah_dev',
        email: 'sarah@example.com',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            postRepositoryProvider.overrideWithValue(mockPostRepository),
            commentRepositoryProvider.overrideWithValue(mockCommentRepository),
            authNotifierProvider.overrideWith(
              (ref) => AuthNotifierMock(const AuthAuthenticated(authorUser)),
            ),
          ],
          child: const MaterialApp(
            home: PostDetailScreen(postId: 'p-detail-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Edit post'), findsOneWidget);
      expect(find.text('Delete post'), findsOneWidget);
      expect(find.text('Report post'), findsNothing);

      // Tap Delete post
      await tester.tap(find.text('Delete post'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Post?'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      verify(() => mockPostRepository.deletePost('p-detail-1')).called(1);
    });

    testWidgets('allows author to edit comment on post detail screen', (tester) async {
      when(() => mockPostRepository.getPost('p-detail-1'))
          .thenAnswer((_) async => testPost);
      when(() => mockCommentRepository.getComments('p-detail-1', limit: 20, offset: 0))
          .thenAnswer((_) async => [testComment]);
      when(() => mockCommentRepository.updateComment('c-1', content: 'Updated insightful comment!'))
          .thenAnswer((_) async => testComment.copyWith(
                content: 'Updated insightful comment!',
                isEdited: true,
              ));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Insightful post!'), findsOneWidget);

      // Tap more options on comment tile
      final commentMenuFinder = find.byTooltip('Comment options');
      await tester.ensureVisible(commentMenuFinder);
      await tester.tap(commentMenuFinder);
      await tester.pumpAndSettle();

      expect(find.text('Edit comment'), findsOneWidget);
      await tester.tap(find.text('Edit comment'));
      await tester.pumpAndSettle();

      // Enter updated text in inline editor
      await tester.enterText(find.byType(TextField).first, 'Updated insightful comment!');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verify(() => mockCommentRepository.updateComment('c-1', content: 'Updated insightful comment!')).called(1);
      expect(find.text('Updated insightful comment!'), findsOneWidget);
      expect(find.text('(edited)'), findsOneWidget);
    });
  });
}
