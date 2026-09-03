import 'package:equatable/equatable.dart';

class PrivacySettings extends Equatable {
  final bool isPrivate;
  final String allowComments;
  final String allowMentions;
  final bool showActivityStatus;
  final bool searchDiscoverable;

  const PrivacySettings({
    this.isPrivate = false,
    this.allowComments = 'everyone',
    this.allowMentions = 'everyone',
    this.showActivityStatus = true,
    this.searchDiscoverable = true,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      isPrivate: json['is_private'] as bool? ?? false,
      allowComments: json['allow_comments'] as String? ?? 'everyone',
      allowMentions: json['allow_mentions'] as String? ?? 'everyone',
      showActivityStatus: json['show_activity_status'] as bool? ?? true,
      searchDiscoverable: json['search_discoverable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'is_private': isPrivate,
        'allow_comments': allowComments,
        'allow_mentions': allowMentions,
        'show_activity_status': showActivityStatus,
        'search_discoverable': searchDiscoverable,
      };

  @override
  List<Object?> get props => [
        isPrivate,
        allowComments,
        allowMentions,
        showActivityStatus,
        searchDiscoverable,
      ];
}

class NotificationPreferences extends Equatable {
  final bool likesEnabled;
  final bool commentsEnabled;
  final bool followsEnabled;
  final bool mentionsEnabled;
  final bool communityEnabled;
  final bool emailEnabled;
  final bool pushEnabled;
  final bool quietHoursEnabled;
  final String? quietHoursStart;
  final String? quietHoursEnd;

  const NotificationPreferences({
    this.likesEnabled = true,
    this.commentsEnabled = true,
    this.followsEnabled = true,
    this.mentionsEnabled = true,
    this.communityEnabled = true,
    this.emailEnabled = false,
    this.pushEnabled = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart,
    this.quietHoursEnd,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      likesEnabled: json['likes_enabled'] as bool? ?? true,
      commentsEnabled: json['comments_enabled'] as bool? ?? true,
      followsEnabled: json['follows_enabled'] as bool? ?? true,
      mentionsEnabled: json['mentions_enabled'] as bool? ?? true,
      communityEnabled: json['community_enabled'] as bool? ?? true,
      emailEnabled: json['email_enabled'] as bool? ?? false,
      pushEnabled: json['push_enabled'] as bool? ?? true,
      quietHoursEnabled: json['quiet_hours_enabled'] as bool? ?? false,
      quietHoursStart: json['quiet_hours_start'] as String?,
      quietHoursEnd: json['quiet_hours_end'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'likes_enabled': likesEnabled,
        'comments_enabled': commentsEnabled,
        'follows_enabled': followsEnabled,
        'mentions_enabled': mentionsEnabled,
        'community_enabled': communityEnabled,
        'email_enabled': emailEnabled,
        'push_enabled': pushEnabled,
        'quiet_hours_enabled': quietHoursEnabled,
        'quiet_hours_start': quietHoursStart,
        'quiet_hours_end': quietHoursEnd,
      };

  @override
  List<Object?> get props => [
        likesEnabled,
        commentsEnabled,
        followsEnabled,
        mentionsEnabled,
        communityEnabled,
        emailEnabled,
        pushEnabled,
        quietHoursEnabled,
        quietHoursStart,
        quietHoursEnd,
      ];
}

class UserSession extends Equatable {
  final String id;
  final String? deviceName;
  final String? ipAddress;
  final DateTime lastActiveAt;
  final DateTime createdAt;
  final bool isCurrent;

  const UserSession({
    required this.id,
    this.deviceName,
    this.ipAddress,
    required this.lastActiveAt,
    required this.createdAt,
    this.isCurrent = false,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id'] as String,
      deviceName: json['device_name'] as String?,
      ipAddress: json['ip_address'] as String?,
      lastActiveAt: DateTime.parse(json['last_active_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      isCurrent: json['is_current'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        deviceName,
        ipAddress,
        lastActiveAt,
        createdAt,
        isCurrent,
      ];
}
