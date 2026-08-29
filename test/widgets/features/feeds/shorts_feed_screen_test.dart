import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/features/feeds/data/repositories/feed_repository.dart';
import 'package:client/features/feeds/presentation/screens/shorts_feed_screen.dart';
import 'package:client/features/feeds/presentation/widgets/short_video_item_widget.dart';
import 'package:client/features/posts/data/models/post_models.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

void main() {
  late MockFeedRepository mockRepository;

  const testShort = PostModel(
    id: 's-1',
    author: PostAuthorModel(
      id: 'a-2',
      username: 'dancer_pro',
      displayName: 'Dancer Pro',
    ),
    title: 'Epic Street Dance',
    content: '#dance #street #vibes',
    media: [
      MediaItemModel(id: 'm-1', mediaType: 'video', url: 'https://example.com/dance.mp4')
    ],
    likeCount: 1200,
    commentCount: 88,
    saveCount: 340,
  );

  setUp(() {
    mockRepository = MockFeedRepository();
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        feedRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: const MaterialApp(
        home: ShortsFeedScreen(),
      ),
    );
  }

  group('ShortsFeedScreen Widget Tests', () {
    testWidgets('renders shorts page view and short video item overlay', (tester) async {
      when(() => mockRepository.getShortsFeed(limit: 20, offset: 0))
          .thenAnswer((_) async => [testShort]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ShortVideoItemWidget), findsOneWidget);
      expect(find.text('@dancer_pro'), findsOneWidget);
      expect(find.text('Epic Street Dance'), findsOneWidget);
      expect(find.text('1.2K'), findsOneWidget);
      expect(find.text('88'), findsOneWidget);
      expect(find.text('340'), findsOneWidget);
    });

    testWidgets('renders empty state when shorts feed has no items', (tester) async {
      when(() => mockRepository.getShortsFeed(limit: 20, offset: 0))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No shorts available'), findsOneWidget);
      expect(find.text('Refresh Feed'), findsOneWidget);
    });
  });
}
