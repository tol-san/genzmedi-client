import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/auth/auth_state.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/notifications/data/repositories/notification_repository.dart';
import 'package:client/features/notifications/data/services/notification_realtime_service.dart';
import 'package:client/features/notifications/presentation/notifiers/notification_center_state.dart';

final notificationCenterProvider =
    StateNotifierProvider<NotificationCenterNotifier, NotificationCenterState>((
      ref,
    ) {
      final authState = ref.watch(authNotifierProvider);
      if (authState is! AuthAuthenticated) {
        return NotificationCenterNotifier(
          repository: ref.watch(notificationRepositoryProvider),
          loadOnCreate: false,
        );
      }
      return NotificationCenterNotifier(
        repository: ref.watch(notificationRepositoryProvider),
        realtimeService: ref.watch(notificationRealtimeServiceProvider),
      );
    });

class NotificationCenterNotifier
    extends StateNotifier<NotificationCenterState> {
  final NotificationRepository repository;
  final NotificationRealtimeService? realtimeService;
  static const _pageSize = 20;
  Timer? _realtimeRefreshTimer;

  NotificationCenterNotifier({
    required this.repository,
    this.realtimeService,
    bool loadOnCreate = true,
    NotificationCenterState initialState = const NotificationCenterState(),
  }) : super(initialState) {
    if (loadOnCreate) {
      loadInitial();
      realtimeService?.connect(_queueRealtimeRefresh);
    }
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await repository.getNotifications(
        unreadOnly: state.unreadOnly,
        limit: _pageSize,
      );
      state = state.copyWith(
        notifications: page.items,
        total: page.total,
        unreadCount: page.unreadCount,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: _message(error));
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, clearError: true);
    try {
      final page = await repository.getNotifications(
        unreadOnly: state.unreadOnly,
        limit: _pageSize,
      );
      state = state.copyWith(
        notifications: page.items,
        total: page.total,
        unreadCount: page.unreadCount,
        isRefreshing: false,
      );
    } catch (error) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: _message(error),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final page = await repository.getNotifications(
        unreadOnly: state.unreadOnly,
        limit: _pageSize,
        offset: state.notifications.length,
      );
      final knownIds = state.notifications.map((item) => item.id).toSet();
      state = state.copyWith(
        notifications: [
          ...state.notifications,
          ...page.items.where((item) => !knownIds.contains(item.id)),
        ],
        total: page.total,
        unreadCount: page.unreadCount,
        isLoadingMore: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: _message(error),
      );
    }
  }

  Future<void> setUnreadOnly(bool unreadOnly) async {
    if (unreadOnly == state.unreadOnly) return;
    state = state.copyWith(
      unreadOnly: unreadOnly,
      notifications: const [],
      total: 0,
    );
    await loadInitial();
  }

  Future<bool> markAsRead(String notificationId) async {
    final index = state.notifications.indexWhere(
      (item) => item.id == notificationId,
    );
    if (index < 0 || state.notifications[index].isRead) return true;
    final previous = state;
    final updatedItems = [...state.notifications];
    updatedItems[index] = updatedItems[index].copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
    if (state.unreadOnly) updatedItems.removeAt(index);
    state = state.copyWith(
      notifications: updatedItems,
      total: state.unreadOnly
          ? (state.total - 1).clamp(0, state.total)
          : state.total,
      unreadCount: (state.unreadCount - 1).clamp(0, state.unreadCount),
      clearError: true,
    );
    try {
      final notification = await repository.markAsRead(notificationId);
      if (!state.unreadOnly) {
        state = state.copyWith(
          notifications: [
            for (final item in state.notifications)
              if (item.id == notificationId) notification else item,
          ],
        );
      }
      return true;
    } catch (error) {
      state = previous.copyWith(errorMessage: _message(error));
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    if (state.unreadCount == 0 || state.isActionLoading) return true;
    final previous = state;
    state = state.copyWith(
      notifications: state.unreadOnly
          ? const []
          : state.notifications
                .map(
                  (item) => item.copyWith(isRead: true, readAt: DateTime.now()),
                )
                .toList(),
      total: state.unreadOnly ? 0 : state.total,
      unreadCount: 0,
      isActionLoading: true,
      clearError: true,
    );
    try {
      await repository.markAllAsRead();
      state = state.copyWith(isActionLoading: false);
      return true;
    } catch (error) {
      state = previous.copyWith(
        isActionLoading: false,
        errorMessage: _message(error),
      );
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    final previous = state;
    final target = state.notifications
        .where((item) => item.id == notificationId)
        .firstOrNull;
    if (target == null) return false;
    state = state.copyWith(
      notifications: state.notifications
          .where((item) => item.id != notificationId)
          .toList(),
      total: (state.total - 1).clamp(0, state.total),
      unreadCount: target.isRead
          ? state.unreadCount
          : (state.unreadCount - 1).clamp(0, state.unreadCount),
      clearError: true,
    );
    try {
      await repository.deleteNotification(notificationId);
      return true;
    } catch (error) {
      state = previous.copyWith(errorMessage: _message(error));
      return false;
    }
  }

  void _queueRealtimeRefresh() {
    _realtimeRefreshTimer?.cancel();
    _realtimeRefreshTimer = Timer(const Duration(milliseconds: 250), refresh);
  }

  String _message(Object error) => error is AppException
      ? error.message
      : 'Could not update notifications. Please try again.';

  @override
  void dispose() {
    _realtimeRefreshTimer?.cancel();
    super.dispose();
  }
}
