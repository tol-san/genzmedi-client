import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/posts/presentation/widgets/post_card_widget.dart';

void main() {
  const testPost = PostModel(
    id: 'post-1',
    author: PostAuthorModel(
      id: 'author-1',
      username: 'tech_builder',
      displayName: 'Tech Builder',
    ),
    title: 'Building Modern Apps',
    content: 'Flutter and FastAPI make a powerful combination.',
    likeCount: 42,
    commentCount: 15,
    saveCount: 8,
    shareCount: 5,
    isLiked: false,
    isSaved: false,
  );

  group('PostCardWidget Tests', () {
    testWidgets('renders author info, title, content, and engagement counts', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PostCardWidget(post: testPost),
          ),
        ),
      );

      expect(find.text('Tech Builder'), findsOneWidget);
      expect(find.textContaining('@tech_builder'), findsOneWidget);
      expect(find.text('Building Modern Apps'), findsOneWidget);
      expect(find.text('Flutter and FastAPI make a powerful combination.'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('fires onLike and onSave callbacks on tap', (tester) async {
      bool likePressed = false;
      bool savePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PostCardWidget(
              post: testPost,
              onLike: () => likePressed = true,
              onSave: () => savePressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      expect(likePressed, isTrue);

      await tester.tap(find.byIcon(Icons.bookmark_border_rounded));
      expect(savePressed, isTrue);
    });
  });
}
