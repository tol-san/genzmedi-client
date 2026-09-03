import 'package:equatable/equatable.dart';
import 'package:client/features/notifications/data/models/notification_models.dart';

class NotificationCenterState extends Equatable {
  final List<AppNotificationModel> notifications;
  final int total;
  final int unreadCount;
  final bool unreadOnly;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isActionLoading;
  final String? errorMessage;

  const NotificationCenterState({
    this.notifications = const [],
    this.total = 0,
    this.unreadCount = 0,
    this.unreadOnly = false,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.isActionLoading = false,
    this.errorMessage,
  });

  bool get hasMore => notifications.length < total;

  NotificationCenterState copyWith({
    List<AppNotificationModel>? notifications,
    int? total,
    int? unreadCount,
    bool? unreadOnly,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isActionLoading,
    String? errorMessage,
    bool clearError = false,
  }) => NotificationCenterState(
    notifications: notifications ?? this.notifications,
    total: total ?? this.total,
    unreadCount: unreadCount ?? this.unreadCount,
    unreadOnly: unreadOnly ?? this.unreadOnly,
    isLoading: isLoading ?? this.isLoading,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    isActionLoading: isActionLoading ?? this.isActionLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );

  @override
  List<Object?> get props => [
    notifications,
    total,
    unreadCount,
    unreadOnly,
    isLoading,
    isRefreshing,
    isLoadingMore,
    isActionLoading,
    errorMessage,
  ];
}
