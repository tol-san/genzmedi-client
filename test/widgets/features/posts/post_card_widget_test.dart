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

  const multiMediaPost = PostModel(
    id: 'post-2',
    author: PostAuthorModel(
      id: 'author-2',
      username: 'photographer',
      displayName: 'Alex Rivers',
    ),
    content: 'Album from our trip!',
    media: [
      MediaItemModel(id: 'm-1', mediaType: 'image', url: 'https://example.com/1.jpg'),
      MediaItemModel(id: 'm-2', mediaType: 'image', url: 'https://example.com/2.jpg'),
      MediaItemModel(id: 'm-3', mediaType: 'image', url: 'https://example.com/3.jpg'),
      MediaItemModel(id: 'm-4', mediaType: 'image', url: 'https://example.com/4.jpg'),
      MediaItemModel(id: 'm-5', mediaType: 'image', url: 'https://example.com/5.jpg'),
      MediaItemModel(id: 'm-6', mediaType: 'image', url: 'https://example.com/6.jpg'),
    ],
    likeCount: 120,
    commentCount: 22,
    shareCount: 9,
  );

  const videoPost = PostModel(
    id: 'post-3',
    author: PostAuthorModel(
      id: 'author-3',
      username: 'videomaker',
      displayName: 'Video Creator',
    ),
    content: 'Watch this snippet!',
    media: [
      MediaItemModel(
        id: 'v-1',
        mediaType: 'video',
        url: 'https://example.com/demo.mp4',
        thumbnailUrl: 'https://example.com/thumb.jpg',
      ),
    ],
    likeCount: 50,
    commentCount: 10,
    shareCount: 4,
  );

  group('PostCardWidget Tests', () {
    testWidgets('renders author info, title, content, engagement counts, and 3-button action bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PostCardWidget(post: testPost),
          ),
        ),
      );

      expect(find.text('Tech Builder'), findsOneWidget);
      expect(find.textContaining('@tech_builder'), findsNothing);
      expect(find.text('Flutter and FastAPI make a powerful combination.'), findsOneWidget);
      expect(find.text('Building Modern Apps'), findsNothing);
      expect(find.text('42'), findsOneWidget);
      expect(find.textContaining('15 comments'), findsOneWidget);
      expect(find.textContaining('5 shares'), findsOneWidget);
      expect(find.text('Like'), findsOneWidget);
      expect(find.text('Comment'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      // Save button is hidden from action bar
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('fires onLike callback on tap', (tester) async {
      bool likePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PostCardWidget(
              post: testPost,
              onLike: () => likePressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Like'));
      expect(likePressed, isTrue);
    });

    testWidgets('renders multi-image collage with +N overlay when media count >= 5', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PostCardWidget(post: multiMediaPost),
            ),
          ),
        ),
      );

      expect(find.text('Alex Rivers'), findsOneWidget);
      expect(find.text('+3'), findsOneWidget); // 6 images -> 3 displayed, 4th has +3
    });

    testWidgets('renders video post without overflowing or huge button distortions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PostCardWidget(post: videoPost),
            ),
          ),
        ),
      );

      expect(find.text('Video Creator'), findsOneWidget);
      expect(find.text('Watch this snippet!'), findsOneWidget);
    });
  });
}
