import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_avatar.dart';
import 'package:client/core/widgets/app_skeleton.dart';
import 'package:client/core/widgets/empty_state_widget.dart';
import 'package:client/core/widgets/error_state_widget.dart';
import 'package:client/features/notifications/data/models/notification_models.dart';
import 'package:client/features/notifications/data/repositories/notification_repository.dart';
import 'package:client/features/notifications/presentation/notifiers/notification_center_notifier.dart';
import 'package:client/features/notifications/presentation/notifiers/notification_center_state.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationCenterProvider);
    final notifier = ref.read(notificationCenterProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ref.listen<String?>(
      notificationCenterProvider.select((value) => value.errorMessage),
      (previous, next) {
        if (next != null && next != previous && state.notifications.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next), backgroundColor: AppColors.error),
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unreadCount > 0)
            TextButton.icon(
              onPressed: state.isActionLoading ? null : notifier.markAllAsRead,
              icon: state.isActionLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Read all'),
            ),
          const SizedBox(width: AppSpacing.space8),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: [
                      const ButtonSegment(
                        value: false,
                        label: Text('All'),
                        icon: Icon(Icons.notifications_outlined),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(
                          state.unreadCount > 0
                              ? 'Unread ${state.unreadCount}'
                              : 'Unread',
                        ),
                        icon: const Icon(Icons.mark_email_unread_outlined),
                      ),
                    ],
                    selected: {state.unreadOnly},
                    onSelectionChanged: (value) =>
                        notifier.setUnreadOnly(value.first),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(context, ref, state, notifier)),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    NotificationCenterState state,
    NotificationCenterNotifier notifier,
  ) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const _NotificationSkeletonList();
    }
    if (state.errorMessage != null && state.notifications.isEmpty) {
      return ErrorStateWidget(
        title: 'Notifications unavailable',
        message: state.errorMessage!,
        onRetry: notifier.loadInitial,
      );
    }
    if (state.notifications.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primaryCrimson,
        onRefresh: notifier.refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.62,
            child: EmptyStateWidget(
              icon: state.unreadOnly
                  ? Icons.mark_email_read_outlined
                  : Icons.notifications_none_rounded,
              title: state.unreadOnly
                  ? 'You are all caught up'
                  : 'No notifications yet',
              subtitle: state.unreadOnly
                  ? 'There are no unread notifications.'
                  : 'Activity from creators and communities will appear here.',
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryCrimson,
      onRefresh: notifier.refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 240) {
            notifier.loadMore();
          }
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space8),
          itemCount: state.notifications.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == state.notifications.length) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.space16),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryCrimson,
                  ),
                ),
              );
            }
            final notification = state.notifications[index];
            return Dismissible(
              key: ValueKey(notification.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) => _confirmDelete(context),
              onDismissed: (_) => notifier.deleteNotification(notification.id),
              background: Container(
                color: AppColors.error,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: AppSpacing.space24),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              child: _NotificationTile(
                notification: notification,
                onTap: () => _openNotification(context, ref, notification),
                onMarkRead: notification.isRead
                    ? null
                    : () => notifier.markAsRead(notification.id),
                onDelete: () async {
                  if (await _confirmDelete(context)) {
                    await notifier.deleteNotification(notification.id);
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete notification?'),
            content: const Text(
              'This notification will be removed from your history.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _openNotification(
    BuildContext context,
    WidgetRef ref,
    AppNotificationModel notification,
  ) async {
    await ref
        .read(notificationCenterProvider.notifier)
        .markAsRead(notification.id);
    if (!context.mounted) return;

    final entityId = notification.entityId;
    switch (notification.entityType) {
      case 'user':
        final username = notification.actor?.username;
        if (username != null && username.isNotEmpty) {
          context.pushNamed(
            RouteNames.publicProfile,
            pathParameters: {'username': username},
          );
        }
      case 'post':
        if (entityId != null) {
          context.pushNamed(
            RouteNames.postDetail,
            pathParameters: {'postId': entityId},
          );
        }
      case 'comment':
        if (entityId == null) return;
        try {
          final postId = await ref
              .read(notificationRepositoryProvider)
              .getCommentPostId(entityId);
          if (postId != null && context.mounted) {
            context.pushNamed(
              RouteNames.postDetail,
              pathParameters: {'postId': postId},
              queryParameters: {'commentId': entityId},
            );
          }
        } catch (_) {
          if (context.mounted) _showUnavailable(context);
        }
      case 'community':
        if (entityId != null) {
          context.pushNamed(
            RouteNames.communityDetail,
            pathParameters: {'communityId': entityId},
          );
        }
      default:
        final username = notification.actor?.username;
        if (username != null && username.isNotEmpty) {
          context.pushNamed(
            RouteNames.publicProfile,
            pathParameters: {'username': username},
          );
        } else {
          _showUnavailable(context);
        }
    }
  }

  void _showUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('The related content is no longer available.'),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback? onMarkRead;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    this.onMarkRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadColor = isDark
        ? AppColors.primaryElectricBlue.withValues(alpha: 0.14)
        : AppColors.primarySoft.withValues(alpha: 0.7);
    return Material(
      color: notification.isRead
          ? (isDark ? AppColors.darkSurface : AppColors.lightSurface)
          : unreadColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AppAvatar(
                    name:
                        notification.actor?.displayName ??
                        notification.actor?.username ??
                        'GenZ',
                    imageUrl: notification.actor?.avatarUrl,
                    size: 46,
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          width: 2,
                        ),
                      ),
                      child: Icon(_icon, size: 13, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTypography.label.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryCrimson,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(height: 1.35),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _relativeTime(notification.createdAt),
                      style: AppTypography.caption.copyWith(
                        color: notification.isRead
                            ? AppColors.textMuted
                            : AppColors.primaryCrimson,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Notification options',
                onSelected: (value) {
                  if (value == 'read') onMarkRead?.call();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  if (onMarkRead != null)
                    const PopupMenuItem(
                      value: 'read',
                      child: Row(
                        children: [
                          Icon(Icons.mark_email_read_outlined),
                          SizedBox(width: 10),
                          Text('Mark as read'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: AppColors.error),
                        SizedBox(width: 10),
                        Text('Delete notification'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _icon => switch (notification.type) {
    AppNotificationType.newFollower => Icons.person_add_alt_1_rounded,
    AppNotificationType.postLike => Icons.favorite_rounded,
    AppNotificationType.postComment => Icons.chat_bubble_rounded,
    AppNotificationType.commentReply => Icons.reply_rounded,
    AppNotificationType.communityJoinApproved => Icons.groups_rounded,
    AppNotificationType.unknown => Icons.notifications_rounded,
  };

  Color get _accentColor => switch (notification.type) {
    AppNotificationType.postLike => AppColors.primaryCrimson,
    AppNotificationType.communityJoinApproved => AppColors.success,
    _ => AppColors.primaryElectricBlue,
  };

  String _relativeTime(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt.toLocal());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('MMM d').format(createdAt.toLocal());
  }
}

class _NotificationSkeletonList extends StatelessWidget {
  const _NotificationSkeletonList();

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(AppSpacing.space16),
    itemCount: 7,
    separatorBuilder: (_, _) => const SizedBox(height: 14),
    itemBuilder: (_, _) => const Row(
      children: [
        AppSkeleton(
          width: 46,
          height: 46,
          borderRadius: AppSpacing.roundedFull,
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeleton(width: 150, height: 14),
              SizedBox(height: 8),
              AppSkeleton(width: double.infinity, height: 12),
              SizedBox(height: 7),
              AppSkeleton(width: 64, height: 10),
            ],
          ),
        ),
      ],
    ),
  );
}
