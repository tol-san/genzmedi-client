import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/features/posts/data/models/comment_model.dart';
import 'package:client/features/posts/presentation/widgets/comment_tile_widget.dart';

void main() {
  const testComment = CommentModel(
    id: 'c-10',
    postId: 'post-10',
    author: CommentAuthorModel(
      id: 'author-10',
      username: 'tech_expert',
      displayName: 'Tech Expert',
    ),
    content: 'This is a test comment discussing modern architecture.',
    replyCount: 2,
    replies: [
      CommentModel(
        id: 'r-1',
        postId: 'post-10',
        parentId: 'c-10',
        author: CommentAuthorModel(id: 'author-11', username: 'reply_user'),
        content: 'I agree completely!',
      )
    ],
  );

  group('CommentTileWidget Tests', () {
    testWidgets('renders author name, username, content, and reply count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommentTileWidget(
              comment: testComment,
              onReply: () {},
            ),
          ),
        ),
      );

      expect(find.text('Tech Expert'), findsOneWidget);
      expect(find.text('This is a test comment discussing modern architecture.'), findsOneWidget);
      expect(find.text('View 2 replies'), findsOneWidget);
      expect(find.text('Reply'), findsOneWidget);
    });

    testWidgets('calls onReply and onToggleReplies callbacks', (tester) async {
      bool replyTapped = false;
      bool toggleTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommentTileWidget(
              comment: testComment,
              onReply: () => replyTapped = true,
              onToggleReplies: () => toggleTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Reply'));
      expect(replyTapped, isTrue);

      await tester.tap(find.text('View 2 replies'));
      expect(toggleTapped, isTrue);
    });
  });
}
