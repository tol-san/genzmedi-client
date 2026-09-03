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
import 'package:client/features/posts/presentation/widgets/post_comments_sheet.dart';

class MockPostRepository extends Mock implements PostRepository {}
class MockCommentRepository extends Mock implements CommentRepository {}

class AuthNotifierMock extends StateNotifier<AuthState> implements AuthNotifier {
  AuthNotifierMock(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockPostRepository mockPostRepository;
  late MockCommentRepository mockCommentRepository;

  const currentUser = UserModel(
    id: 'user-tol-1',
    email: 'mrtol@example.com',
    username: 'mrtol',
    displayName: 'MrTol MrTol',
    avatarUrl: null,
  );

  const testPost = PostModel(
    id: 'p-sheet-1',
    author: PostAuthorModel(id: 'a-1', username: 'vattana_dev', displayName: 'Vattana'),
    content: 'Loving the new UI design!',
    likeCount: 52,
    commentCount: 2,
    isLiked: true,
  );

  const testComment = CommentModel(
    id: 'c-sheet-1',
    postId: 'p-sheet-1',
    author: CommentAuthorModel(id: 'a-2', username: 'vattana', displayName: 'Vattana'),
    content: 'Time flies so fast Cher',
    replyCount: 1,
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
        home: Scaffold(
          body: PostCommentsSheet(
            postId: 'p-sheet-1',
            initialPost: testPost,
          ),
        ),
      ),
    );
  }

  group('PostCommentsSheet Widget Tests', () {
    testWidgets('renders reaction summary row, sort dropdown, comment list, and user composer', (tester) async {
      when(() => mockPostRepository.getPost('p-sheet-1')).thenAnswer((_) async => testPost);
      when(() => mockCommentRepository.getComments('p-sheet-1', limit: any(named: 'limit'), offset: any(named: 'offset')))
          .thenAnswer((_) async => [testComment]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('You and 51 others'), findsOneWidget);
      expect(find.text('Most relevant'), findsOneWidget);
      expect(find.text('Vattana'), findsOneWidget);
      expect(find.text('Time flies so fast Cher'), findsOneWidget);
      expect(find.text('Reply'), findsOneWidget);
      expect(find.text('View 1 reply'), findsOneWidget);
      expect(find.text('Comment as MrTol MrTol'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsWidgets);
    });

    testWidgets('allows author to edit comment inside comments sheet', (tester) async {
      // Author matches currentUser ('user-tol-1')
      const ownComment = CommentModel(
        id: 'c-own-1',
        postId: 'p-sheet-1',
        author: CommentAuthorModel(id: 'user-tol-1', username: 'mrtol', displayName: 'MrTol MrTol'),
        content: 'Original comment text',
      );

      when(() => mockPostRepository.getPost('p-sheet-1')).thenAnswer((_) async => testPost);
      when(() => mockCommentRepository.getComments('p-sheet-1', limit: any(named: 'limit'), offset: any(named: 'offset')))
          .thenAnswer((_) async => [ownComment]);
      when(() => mockCommentRepository.updateComment('c-own-1', content: 'Updated comment text'))
          .thenAnswer((_) async => ownComment.copyWith(
                content: 'Updated comment text',
                isEdited: true,
              ));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Original comment text'), findsOneWidget);

      // Open comment options menu
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Edit comment'), findsOneWidget);
      await tester.tap(find.text('Edit comment'));
      await tester.pumpAndSettle();

      // Modify comment in inline editor
      await tester.enterText(find.byType(TextField).first, 'Updated comment text');
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verify(() => mockCommentRepository.updateComment('c-own-1', content: 'Updated comment text')).called(1);
      expect(find.text('Updated comment text'), findsOneWidget);
      expect(find.text('(edited)'), findsOneWidget);
    });
  });
}
