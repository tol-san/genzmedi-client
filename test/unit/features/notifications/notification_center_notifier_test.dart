import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/features/notifications/data/models/notification_models.dart';
import 'package:client/features/notifications/data/repositories/notification_repository.dart';
import 'package:client/features/notifications/presentation/notifiers/notification_center_notifier.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

final unreadNotification = AppNotificationModel(
  id: 'notification-1',
  recipientId: 'user-1',
  type: AppNotificationType.newFollower,
  typeValue: 'new_follower',
  title: 'New follower',
  message: 'Creator followed you.',
  entityType: 'user',
  entityId: 'actor-1',
  createdAt: DateTime.utc(2026, 9, 3),
);

void main() {
  late MockNotificationRepository repository;

  setUp(() {
    repository = MockNotificationRepository();
    when(
      () => repository.getNotifications(
        unreadOnly: any(named: 'unreadOnly'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer(
      (_) async => PaginatedNotifications(
        items: [unreadNotification],
        total: 1,
        unreadCount: 1,
        limit: 20,
        offset: 0,
      ),
    );
  });

  test('loads notifications and updates the unread badge count', () async {
    final notifier = NotificationCenterNotifier(
      repository: repository,
      loadOnCreate: false,
    );

    await notifier.loadInitial();

    expect(notifier.state.notifications, [unreadNotification]);
    expect(notifier.state.unreadCount, 1);
  });

  test('marks one notification as read optimistically', () async {
    when(() => repository.markAsRead('notification-1')).thenAnswer(
      (_) async =>
          unreadNotification.copyWith(isRead: true, readAt: DateTime.now()),
    );
    final notifier = NotificationCenterNotifier(
      repository: repository,
      loadOnCreate: false,
    );
    await notifier.loadInitial();

    expect(await notifier.markAsRead('notification-1'), isTrue);
    expect(notifier.state.notifications.single.isRead, isTrue);
    expect(notifier.state.unreadCount, 0);
  });

  test('mark all clears unread state', () async {
    when(repository.markAllAsRead).thenAnswer((_) async => 1);
    final notifier = NotificationCenterNotifier(
      repository: repository,
      loadOnCreate: false,
    );
    await notifier.loadInitial();

    expect(await notifier.markAllAsRead(), isTrue);
    expect(notifier.state.unreadCount, 0);
    expect(notifier.state.notifications.single.isRead, isTrue);
  });

  test('delete removes the notification and updates counts', () async {
    when(() => repository.deleteNotification('notification-1'))
        .thenAnswer((_) async {});
    final notifier = NotificationCenterNotifier(
      repository: repository,
      loadOnCreate: false,
    );
    await notifier.loadInitial();

    expect(await notifier.deleteNotification('notification-1'), isTrue);
    expect(notifier.state.notifications, isEmpty);
    expect(notifier.state.unreadCount, 0);
  });
}
