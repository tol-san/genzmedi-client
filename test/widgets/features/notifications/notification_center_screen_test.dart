import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/features/notifications/data/models/notification_models.dart';
import 'package:client/features/notifications/data/repositories/notification_repository.dart';
import 'package:client/features/notifications/presentation/notifiers/notification_center_notifier.dart';
import 'package:client/features/notifications/presentation/screens/notification_center_screen.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  testWidgets('renders unread notification and read-all action', (
    tester,
  ) async {
    final repository = MockNotificationRepository();
    final notification = AppNotificationModel(
      id: 'notification-1',
      recipientId: 'user-1',
      actor: const NotificationActorModel(
        id: 'actor-1',
        username: 'creator',
        displayName: 'Creator',
      ),
      type: AppNotificationType.postLike,
      typeValue: 'post_like',
      title: 'New like',
      message: 'Creator liked your post.',
      entityType: 'post',
      entityId: 'post-1',
      createdAt: DateTime.now(),
    );
    when(
      () => repository.getNotifications(
        unreadOnly: any(named: 'unreadOnly'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer(
      (_) async => PaginatedNotifications(
        items: [notification],
        total: 1,
        unreadCount: 1,
        limit: 20,
        offset: 0,
      ),
    );
    final notifier = NotificationCenterNotifier(
      repository: repository,
      loadOnCreate: false,
    );
    await notifier.loadInitial();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [notificationCenterProvider.overrideWith((ref) => notifier)],
        child: const MaterialApp(home: NotificationCenterScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Unread 1'), findsOneWidget);
    expect(find.text('Read all'), findsOneWidget);
    expect(find.text('New like'), findsOneWidget);
    expect(find.text('Creator liked your post.'), findsOneWidget);
  });
}
