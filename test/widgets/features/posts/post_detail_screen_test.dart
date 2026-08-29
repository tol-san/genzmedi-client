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

      expect(find.text('Post Details Title'), findsOneWidget);
      expect(find.text('Sarah Developer'), findsOneWidget);
      expect(find.text('Full description of the post content.'), findsOneWidget);
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
  });
}
