import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/features/feeds/data/repositories/feed_repository.dart';
import 'package:client/features/feeds/presentation/screens/home_feed_screen.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/posts/presentation/widgets/post_card_widget.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

void main() {
  late MockFeedRepository mockRepository;

  const testPost = PostModel(
    id: 'p-1',
    author: PostAuthorModel(
      id: 'a-1',
      username: 'art_creator',
      displayName: 'Art Creator',
    ),
    title: 'Digital Illustration',
    content: 'Check out my new piece!',
    likeCount: 50,
    commentCount: 10,
    saveCount: 5,
    shareCount: 2,
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
        home: HomeFeedScreen(),
      ),
    );
  }

  group('HomeFeedScreen Widget Tests', () {
    testWidgets('renders app bar and list of post cards', (tester) async {
      when(() => mockRepository.getHomeFeed(limit: 20, offset: 0))
          .thenAnswer((_) async => [testPost]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(PostCardWidget), findsOneWidget);
      expect(find.text('Digital Illustration'), findsOneWidget);
      expect(find.text('Art Creator'), findsOneWidget);
    });

    testWidgets('renders empty state when home feed is empty', (tester) async {
      when(() => mockRepository.getHomeFeed(limit: 20, offset: 0))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Your feed is just getting started'), findsOneWidget);
      expect(find.text('Explore Discover'), findsOneWidget);
    });
  });
}
