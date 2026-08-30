import 'package:equatable/equatable.dart';

class ReactorUserModel extends Equatable {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String reactionType;
  final int mutualCount;
  final bool isFollowing;

  const ReactorUserModel({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.reactionType = 'like',
    this.mutualCount = 0,
    this.isFollowing = false,
  });

  factory ReactorUserModel.fromJson(Map<String, dynamic> json) {
    return ReactorUserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      reactionType: json['reaction_type'] as String? ?? 'like',
      mutualCount: json['mutual_count'] as int? ?? 0,
      isFollowing: json['is_following'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'reaction_type': reactionType,
      'mutual_count': mutualCount,
      'is_following': isFollowing,
    };
  }

  @override
  List<Object?> get props => [
        id,
        username,
        displayName,
        avatarUrl,
        reactionType,
        mutualCount,
        isFollowing,
      ];
}

class PostReactionsModel extends Equatable {
  final List<ReactorUserModel> items;
  final int total;
  final Map<String, int> counts;

  const PostReactionsModel({
    required this.items,
    required this.total,
    required this.counts,
  });

  factory PostReactionsModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((e) => ReactorUserModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final rawCounts = json['counts'] as Map<String, dynamic>? ?? {};
    final counts = rawCounts.map((k, v) => MapEntry(k, (v as num).toInt()));

    return PostReactionsModel(
      items: items,
      total: json['total'] as int? ?? items.length,
      counts: counts,
    );
  }

  @override
  List<Object?> get props => [items, total, counts];
}
