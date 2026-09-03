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

    testWidgets('shows (edited) tag when comment.isEdited is true', (tester) async {
      final editedComment = testComment.copyWith(isEdited: true);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommentTileWidget(comment: editedComment),
          ),
        ),
      );

      expect(find.text('(edited)'), findsOneWidget);
    });

    testWidgets('author can enter edit mode, see char count, and save changes', (tester) async {
      String? updatedContent;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CommentTileWidget(
                comment: testComment,
                currentUserId: 'author-10',
                onEdit: (text) async {
                  updatedContent = text;
                  return true;
                },
              ),
            ),
          ),
        ),
      );

      // Open menu
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Edit comment'), findsOneWidget);

      // Tap Edit comment
      await tester.tap(find.text('Edit comment'));
      await tester.pumpAndSettle();

      // Verify inline editor appears
      expect(find.byType(TextField), findsOneWidget);
      expect(find.textContaining('/1000'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // Modify text
      await tester.enterText(find.byType(TextField), 'Modified insightful comment.');
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(updatedContent, 'Modified insightful comment.');
      // After save, editor is closed
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('validates empty comment and shows error message', (tester) async {
      bool onEditCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CommentTileWidget(
                comment: testComment,
                currentUserId: 'author-10',
                onEdit: (text) async {
                  onEditCalled = true;
                  return true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit comment'));
      await tester.pumpAndSettle();

      // Clear text
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(onEditCalled, isFalse);
      expect(find.text('Comment cannot be empty.'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('canceling edit mode restores original comment without calling onEdit', (tester) async {
      bool onEditCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CommentTileWidget(
                comment: testComment,
                currentUserId: 'author-10',
                onEdit: (text) async {
                  onEditCalled = true;
                  return true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit comment'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Temporary draft text');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(onEditCalled, isFalse);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('This is a test comment discussing modern architecture.'), findsOneWidget);
    });

    testWidgets('platform administrator can edit comments even if not author', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommentTileWidget(
              comment: testComment,
              currentUserId: 'admin-user-99',
              isSuperuser: true,
              onEdit: (text) async => true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Edit comment'), findsOneWidget);
      expect(find.text('Report comment'), findsNothing);
    });
  });
}
