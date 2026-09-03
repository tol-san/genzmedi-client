import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/core/errors/error_mapper.dart';
import 'package:client/core/network/api_client.dart';
import 'package:client/core/network/api_endpoints.dart';
import 'package:client/features/settings/data/models/settings_models.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(dio: ref.watch(dioClientProvider));
});

class BlockedUsersPage {
  final List<UserModel> items;
  final int total;
  final int limit;
  final int offset;

  const BlockedUsersPage({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  bool get hasMore => offset + items.length < total;
}

class SettingsRepository {
  final Dio dio;

  const SettingsRepository({required this.dio});

  /// Changes the authenticated user's password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await dio.post(
        ApiEndpoints.changePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  /// Retrieves the paginated list of users blocked by the authenticated user.
  Future<BlockedUsersPage> getBlockedUsers({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await dio.get(
        ApiEndpoints.myBlockedUsers,
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final rawItems = data['items'] as List<dynamic>? ?? const [];
      final total = (data['total'] as num?)?.toInt() ?? rawItems.length;

      final users = rawItems
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return BlockedUsersPage(
        items: users,
        total: total,
        limit: limit,
        offset: offset,
      );
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  /// Unblocks a user and restores standard interaction visibility.
  Future<void> unblockUser(String userId) async {
    try {
      await dio.delete(ApiEndpoints.blockUser(userId));
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<PrivacySettings> getPrivacySettings() async {
    try {
      final response = await dio.get(ApiEndpoints.myPrivacy);
      return PrivacySettings.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<PrivacySettings> updatePrivacySettings(
    Map<String, dynamic> changes,
  ) async {
    try {
      final response = await dio.patch(
        ApiEndpoints.myPrivacy,
        data: changes,
      );
      return PrivacySettings.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<NotificationPreferences> getNotificationPreferences() async {
    try {
      final response = await dio.get(ApiEndpoints.notificationPreferences);
      return NotificationPreferences.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<NotificationPreferences> updateNotificationPreferences(
    Map<String, dynamic> changes,
  ) async {
    try {
      final response = await dio.patch(
        ApiEndpoints.notificationPreferences,
        data: changes,
      );
      return NotificationPreferences.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<List<UserSession>> getSessions() async {
    try {
      final response = await dio.get(ApiEndpoints.sessions);
      return (response.data as List<dynamic>)
          .map((item) => UserSession.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<void> revokeSession(String sessionId) async {
    try {
      await dio.delete(ApiEndpoints.session(sessionId));
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<void> revokeOtherSessions() async {
    try {
      await dio.delete(ApiEndpoints.otherSessions);
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<void> deactivateAccount({
    required String password,
    String? reason,
  }) async {
    try {
      await dio.post(
        ApiEndpoints.deactivateAccount,
        data: {
          'password': password,
          if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        },
      );
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<void> deleteAccount({required String password}) async {
    try {
      await dio.delete(
        ApiEndpoints.deleteAccount,
        data: {'password': password, 'confirmation': 'DELETE'},
      );
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }
}
