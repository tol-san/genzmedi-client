import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/features/posts/data/models/comment_model.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/posts/data/repositories/comment_repository.dart';
import 'package:client/features/posts/data/repositories/post_repository.dart';
import 'package:client/features/posts/presentation/notifiers/post_detail_notifier.dart';

class MockPostRepository extends Mock implements PostRepository {}

class MockCommentRepository extends Mock implements CommentRepository {}

void main() {
  late MockPostRepository mockPostRepository;
  late MockCommentRepository mockCommentRepository;

  const testPost = PostModel(
    id: 'post-1',
    author: PostAuthorModel(id: 'u-1', username: 'alex', displayName: 'Alex'),
    title: 'Discussion Post',
    content: 'Let us discuss app architecture.',
    likeCount: 5,
    saveCount: 1,
    commentCount: 2,
  );

  const testComment1 = CommentModel(
    id: 'c-1',
    postId: 'post-1',
    author: CommentAuthorModel(id: 'u-2', username: 'bob', displayName: 'Bob'),
    content: 'Great points made here!',
    replyCount: 1,
  );

  const testReply1 = CommentModel(
    id: 'r-1',
    postId: 'post-1',
    parentId: 'c-1',
    author: CommentAuthorModel(id: 'u-1', username: 'alex', displayName: 'Alex'),
    content: 'Thanks Bob, appreciate it!',
  );

  setUp(() {
    mockPostRepository = MockPostRepository();
    mockCommentRepository = MockCommentRepository();
  });

  group('PostDetailNotifier Unit Tests', () {
    test('initializes and loads post and comments successfully', () async {
      when(() => mockPostRepository.getPost('post-1'))
          .thenAnswer((_) async => testPost);
      when(() => mockCommentRepository.getComments('post-1', limit: 20, offset: 0))
          .thenAnswer((_) async => [testComment1]);

      final notifier = PostDetailNotifier(
        postId: 'post-1',
        postRepository: mockPostRepository,
        commentRepository: mockCommentRepository,
      );
      await pumpEventQueue();

      expect(notifier.state.post?.id, 'post-1');
      expect(notifier.state.comments.length, 1);
      expect(notifier.state.comments.first.id, 'c-1');
      expect(notifier.state.isLoadingPost, isFalse);
      expect(notifier.state.isLoadingComments, isFalse);
    });

    test('toggleReplies fetches and expands nested replies', () async {
      when(() => mockPostRepository.getPost('post-1'))
          .thenAnswer((_) async => testPost);
      when(() => mockCommentRepository.getComments('post-1', limit: 20, offset: 0))
          .thenAnswer((_) async => [testComment1]);
      when(() => mockCommentRepository.getReplies('c-1'))
          .thenAnswer((_) async => [testReply1]);

      final notifier = PostDetailNotifier(
        postId: 'post-1',
        postRepository: mockPostRepository,
        commentRepository: mockCommentRepository,
      );
      await pumpEventQueue();

      await notifier.toggleReplies('c-1');

      expect(notifier.state.comments.first.isRepliesExpanded, isTrue);
      expect(notifier.state.comments.first.replies.length, 1);
      expect(notifier.state.comments.first.replies.first.id, 'r-1');
    });

    test('postComment adds new comment and increments commentCount', () async {
      when(() => mockPostRepository.getPost('post-1'))
          .thenAnswer((_) async => testPost);
      when(() => mockCommentRepository.getComments('post-1', limit: 20, offset: 0))
          .thenAnswer((_) async => [testComment1]);
      when(() => mockCommentRepository.createComment('post-1', content: 'New comment'))
          .thenAnswer((_) async => const CommentModel(
                id: 'c-2',
                postId: 'post-1',
                author: CommentAuthorModel(id: 'u-3', username: 'carol'),
                content: 'New comment',
              ));

      final notifier = PostDetailNotifier(
        postId: 'post-1',
        postRepository: mockPostRepository,
        commentRepository: mockCommentRepository,
      );
      await pumpEventQueue();

      final success = await notifier.postComment('New comment');
      expect(success, isTrue);
      expect(notifier.state.comments.length, 2);
      expect(notifier.state.comments.first.id, 'c-2');
      expect(notifier.state.post?.commentCount, 3);
    });
  });
}
