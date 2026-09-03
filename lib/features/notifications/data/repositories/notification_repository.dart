import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/errors/error_mapper.dart';
import 'package:client/core/network/api_client.dart';
import 'package:client/core/network/api_endpoints.dart';
import 'package:client/features/notifications/data/models/notification_models.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(dio: ref.watch(dioClientProvider));
});

class NotificationRepository {
  final Dio dio;
  NotificationRepository({required this.dio});

  Future<PaginatedNotifications> getNotifications({
    bool unreadOnly = false,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        ApiEndpoints.notifications,
        queryParameters: {
          'unread_only': unreadOnly,
          'limit': limit,
          'offset': offset,
        },
      );
      return PaginatedNotifications.fromJson(response.data!);
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        ApiEndpoints.unreadNotificationCount,
      );
      return (response.data?['unread_count'] as num?)?.toInt() ?? 0;
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<AppNotificationModel> markAsRead(String notificationId) async {
    try {
      final response = await dio.patch<Map<String, dynamic>>(
        ApiEndpoints.markNotificationRead(notificationId),
      );
      return AppNotificationModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<int> markAllAsRead() async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiEndpoints.markAllNotificationsRead,
      );
      return (response.data?['count'] as num?)?.toInt() ?? 0;
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await dio.delete<void>(ApiEndpoints.deleteNotification(notificationId));
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<String> requestWebSocketTicket() async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiEndpoints.notificationWsTicket,
      );
      return response.data?['ticket'] as String? ?? '';
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<String?> getCommentPostId(String commentId) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        ApiEndpoints.commentDetail(commentId),
      );
      return response.data?['post_id']?.toString();
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }
}
