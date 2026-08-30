import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/posts/presentation/screens/post_media_viewer_screen.dart';

void main() {
  const multiImagePost = PostModel(
    id: 'post-viewer-1',
    author: PostAuthorModel(
      id: 'author-viewer-1',
      username: 'aba_careers',
      displayName: 'ABA Careers',
    ),
    content: 'Ready to grow with ABA Bank? We are hiring!',
    media: [
      MediaItemModel(id: 'm-1', mediaType: 'image', url: 'https://example.com/hiring.jpg'),
      MediaItemModel(id: 'm-2', mediaType: 'image', url: 'https://example.com/team.jpg'),
    ],
    likeCount: 161,
    commentCount: 1,
    shareCount: 20,
  );

  group('PostMediaViewerScreen Widget Tests', () {
    testWidgets('renders author title, content, reaction counters, and multi-image page counter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PostMediaViewerScreen(post: multiImagePost),
        ),
      );

      expect(find.text("ABA Careers's post"), findsOneWidget);
      expect(find.text('Ready to grow with ABA Bank? We are hiring!'), findsOneWidget);
      expect(find.text('161'), findsOneWidget);
      expect(find.text('1 comments'), findsOneWidget);
      expect(find.text('20 shares'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('Like'), findsOneWidget);
      expect(find.text('Comment'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
    });

    testWidgets('toggles like state in media viewer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PostMediaViewerScreen(post: multiImagePost),
        ),
      );

      await tester.tap(find.text('Like'));
      await tester.pump();

      expect(find.text('162'), findsOneWidget);
    });
  });
}
