import 'package:equatable/equatable.dart';

enum AppNotificationType {
  newFollower,
  postLike,
  postComment,
  commentReply,
  communityJoinApproved,
  unknown,
}

extension AppNotificationTypeX on AppNotificationType {
  static AppNotificationType fromApi(String value) => switch (value) {
    'new_follower' => AppNotificationType.newFollower,
    'post_like' => AppNotificationType.postLike,
    'post_comment' => AppNotificationType.postComment,
    'comment_reply' => AppNotificationType.commentReply,
    'community_join_approved' => AppNotificationType.communityJoinApproved,
    _ => AppNotificationType.unknown,
  };
}

class NotificationActorModel extends Equatable {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;

  const NotificationActorModel({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory NotificationActorModel.fromJson(Map<String, dynamic> json) =>
      NotificationActorModel(
        id: json['id']?.toString() ?? '',
        username: json['username'] as String? ?? '',
        displayName: json['display_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
      );

  @override
  List<Object?> get props => [id, username, displayName, avatarUrl];
}

class AppNotificationModel extends Equatable {
  final String id;
  final String recipientId;
  final String? actorId;
  final NotificationActorModel? actor;
  final AppNotificationType type;
  final String typeValue;
  final String title;
  final String message;
  final String? entityType;
  final String? entityId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotificationModel({
    required this.id,
    required this.recipientId,
    this.actorId,
    this.actor,
    required this.type,
    required this.typeValue,
    required this.title,
    required this.message,
    this.entityType,
    this.entityId,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    final typeValue = json['notification_type'] as String? ?? 'unknown';
    final actorJson = json['actor'] as Map<String, dynamic>?;
    return AppNotificationModel(
      id: json['id']?.toString() ?? '',
      recipientId: json['recipient_id']?.toString() ?? '',
      actorId: json['actor_id']?.toString(),
      actor: actorJson == null
          ? null
          : NotificationActorModel.fromJson(actorJson),
      type: AppNotificationTypeX.fromApi(typeValue),
      typeValue: typeValue,
      title: json['title'] as String? ?? 'Notification',
      message: json['message'] as String? ?? '',
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id']?.toString(),
      isRead: json['is_read'] as bool? ?? false,
      readAt: DateTime.tryParse(json['read_at']?.toString() ?? ''),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  AppNotificationModel copyWith({bool? isRead, DateTime? readAt}) =>
      AppNotificationModel(
        id: id,
        recipientId: recipientId,
        actorId: actorId,
        actor: actor,
        type: type,
        typeValue: typeValue,
        title: title,
        message: message,
        entityType: entityType,
        entityId: entityId,
        isRead: isRead ?? this.isRead,
        readAt: readAt ?? this.readAt,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [
    id,
    recipientId,
    actorId,
    actor,
    type,
    typeValue,
    title,
    message,
    entityType,
    entityId,
    isRead,
    readAt,
    createdAt,
  ];
}

class PaginatedNotifications {
  final List<AppNotificationModel> items;
  final int total;
  final int unreadCount;
  final int limit;
  final int offset;

  const PaginatedNotifications({
    required this.items,
    required this.total,
    required this.unreadCount,
    required this.limit,
    required this.offset,
  });

  factory PaginatedNotifications.fromJson(Map<String, dynamic> json) =>
      PaginatedNotifications(
        items: (json['items'] as List<dynamic>? ?? const [])
            .map(
              (item) =>
                  AppNotificationModel.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
        total: (json['total'] as num?)?.toInt() ?? 0,
        unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
        limit: (json['limit'] as num?)?.toInt() ?? 20,
        offset: (json['offset'] as num?)?.toInt() ?? 0,
      );
}
