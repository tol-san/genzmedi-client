import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/network/api_endpoints.dart';
import 'package:client/features/notifications/data/models/notification_models.dart';
import 'package:client/features/notifications/data/repositories/notification_repository.dart';

class MockDio extends Mock implements Dio {}

Map<String, dynamic> notificationJson({bool isRead = false}) => {
  'id': 'notification-1',
  'recipient_id': 'user-1',
  'actor_id': 'actor-1',
  'actor': {'id': 'actor-1', 'username': 'creator', 'display_name': 'Creator'},
  'notification_type': 'post_like',
  'title': 'New like',
  'message': 'Creator liked your post.',
  'entity_type': 'post',
  'entity_id': 'post-1',
  'is_read': isRead,
  'created_at': '2026-09-03T10:00:00Z',
};

void main() {
  late MockDio dio;
  late NotificationRepository repository;

  setUp(() {
    dio = MockDio();
    repository = NotificationRepository(dio: dio);
  });

  test('parses paginated notifications and unread count', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        ApiEndpoints.notifications,
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ApiEndpoints.notifications),
        data: {
          'items': [notificationJson()],
          'total': 1,
          'unread_count': 1,
          'limit': 20,
          'offset': 0,
        },
      ),
    );

    final page = await repository.getNotifications(unreadOnly: true);

    expect(page.unreadCount, 1);
    expect(page.items.single.type, AppNotificationType.postLike);
    expect(page.items.single.actor?.username, 'creator');
  });

  test('requests one-time WebSocket ticket', () async {
    when(
      () => dio.post<Map<String, dynamic>>(ApiEndpoints.notificationWsTicket),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ApiEndpoints.notificationWsTicket),
        data: {'ticket': 'one-time-ticket', 'expires_in_seconds': 30},
      ),
    );

    expect(await repository.requestWebSocketTicket(), 'one-time-ticket');
  });

  test('resolves a comment notification to its post', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        ApiEndpoints.commentDetail('comment-1'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(
          path: ApiEndpoints.commentDetail('comment-1'),
        ),
        data: {'id': 'comment-1', 'post_id': 'post-1'},
      ),
    );

    expect(await repository.getCommentPostId('comment-1'), 'post-1');
  });
}
