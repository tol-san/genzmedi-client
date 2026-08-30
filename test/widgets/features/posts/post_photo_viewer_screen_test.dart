import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/posts/presentation/screens/post_photo_viewer_screen.dart';

void main() {
  const singleImagePost = PostModel(
    id: 'photo-post-1',
    author: PostAuthorModel(
      id: 'author-photo-1',
      username: 'khaosod_english',
      displayName: 'Khaosod English',
    ),
    content: 'A Thai gas station in Sisaket province hit by a BM-21 rocket',
    media: [
      MediaItemModel(id: 'm-photo-1', mediaType: 'image', url: 'https://example.com/gas_station.jpg'),
    ],
    likeCount: 1600,
    commentCount: 1700,
    shareCount: 97,
  );

  group('PostPhotoViewerScreen Widget Tests', () {
    testWidgets('renders black canvas, close button, author info, caption, and counters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PostPhotoViewerScreen(post: singleImagePost),
        ),
      );

      expect(find.text('Khaosod English'), findsOneWidget);
      expect(find.text('A Thai gas station in Sisaket province hit by a BM-21 rocket'), findsOneWidget);
      expect(find.text('1.6K'), findsOneWidget);
      expect(find.text('1.7K comments'), findsOneWidget);
      expect(find.text('97 shares'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
    });

    testWidgets('toggles like state in photo viewer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PostPhotoViewerScreen(post: singleImagePost),
        ),
      );

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pump();

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });
  });
}
