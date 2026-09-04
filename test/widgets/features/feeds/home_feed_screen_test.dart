import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/core/widgets/app_skeleton.dart';
import 'package:client/features/feeds/data/repositories/feed_repository.dart';
import 'package:client/features/feeds/presentation/screens/home_feed_screen.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/posts/presentation/widgets/post_card_widget.dart';
import 'package:client/features/posts/presentation/widgets/feed_create_prompt.dart';
import 'package:client/features/notifications/data/repositories/notification_repository.dart';
import 'package:client/features/notifications/presentation/notifiers/notification_center_notifier.dart';
import 'package:client/features/notifications/presentation/notifiers/notification_center_state.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  late MockFeedRepository mockRepository;
  late MockNotificationRepository mockNotificationRepository;

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
    mockNotificationRepository = MockNotificationRepository();
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        feedRepositoryProvider.overrideWithValue(mockRepository),
        notificationCenterProvider.overrideWith(
          (ref) => NotificationCenterNotifier(
            repository: mockNotificationRepository,
            loadOnCreate: false,
          ),
        ),
      ],
      child: const MaterialApp(home: HomeFeedScreen()),
    );
  }

  Widget buildTestWidgetWithUnreadCount(int count) {
    return ProviderScope(
      overrides: [
        feedRepositoryProvider.overrideWithValue(mockRepository),
        notificationCenterProvider.overrideWith(
          (ref) => NotificationCenterNotifier(
            repository: mockNotificationRepository,
            loadOnCreate: false,
            initialState: NotificationCenterState(unreadCount: count),
          ),
        ),
      ],
      child: const MaterialApp(home: HomeFeedScreen()),
    );
  }

  group('HomeFeedScreen Widget Tests', () {
    testWidgets('shows unread notification count on the bell', (tester) async {
      when(() => mockRepository.getHomeFeed(limit: 20, offset: 0))
          .thenAnswer((_) async => [testPost]);

      await tester.pumpWidget(buildTestWidgetWithUnreadCount(7));
      await tester.pumpAndSettle();

      expect(find.text('7'), findsOneWidget);
      expect(find.byTooltip('7 unread notifications'), findsOneWidget);
    });

    testWidgets('quick create prompt exposes all three post formats', (
      tester,
    ) async {
      var selectedFormat = '';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeedCreatePrompt(
              onTextTap: () => selectedFormat = 'text',
              onPhotosTap: () => selectedFormat = 'image',
              onVideoTap: () => selectedFormat = 'video',
            ),
          ),
        ),
      );

      expect(find.text('Text'), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('Short'), findsOneWidget);

      await tester.tap(find.text('Photos'));
      expect(selectedFormat, 'image');
    });

    testWidgets('renders app bar and list of post cards', (tester) async {
      when(() => mockRepository.getHomeFeed(limit: 20, offset: 0))
          .thenAnswer((_) async => [testPost]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(PostCardWidget), findsOneWidget);
      expect(find.byType(FeedCreatePrompt), findsOneWidget);
      expect(find.text('Share something with your community'), findsOneWidget);
      expect(find.text('Check out my new piece!'), findsOneWidget);
      expect(find.text('Art Creator'), findsOneWidget);
    });

    testWidgets('renders loading skeleton when initially fetching feed', (
      tester,
    ) async {
      final completer = Completer<List<PostModel>>();
      when(() => mockRepository.getHomeFeed(limit: 20, offset: 0))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(AppSkeleton), findsWidgets);

      completer.complete([testPost]);
      await tester.pumpAndSettle();
    });

    testWidgets('renders empty state when home feed is empty', (tester) async {
      when(() => mockRepository.getHomeFeed(limit: 20, offset: 0))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Your feed is just getting started'), findsOneWidget);
      expect(find.text('Explore Discover'), findsOneWidget);
    });

    testWidgets('renders request error when home feed fails', (tester) async {
      when(() => mockRepository.getHomeFeed(limit: 20, offset: 0))
          .thenThrow(const NetworkException());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Unable to load your feed'), findsOneWidget);
      expect(
        find.text(
          'Unable to connect to server. Please check your internet connection.',
        ),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Your feed is just getting started'), findsNothing);
    });
  });
}
