import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String username;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final List<String> interests;
  final int followersCount;
  final int followingCount;
  final int postCount;
  final bool isVerified;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.interests = const [],
    this.followersCount = 0,
    this.followingCount = 0,
    this.postCount = 0,
    this.isVerified = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;

    return UserModel(
      id: json['id']?.toString() ?? profile?['id']?.toString() ?? '',
      username: json['username'] as String? ?? profile?['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['display_name'] as String? ?? profile?['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? profile?['avatar_url'] as String?,
      bio: json['bio'] as String? ?? profile?['bio'] as String?,
      interests: (json['interests'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      followersCount: (json['followers_count'] as num?)?.toInt() ??
          (json['follower_count'] as num?)?.toInt() ??
          (profile?['follower_count'] as num?)?.toInt() ??
          0,
      followingCount: (json['following_count'] as num?)?.toInt() ??
          (profile?['following_count'] as num?)?.toInt() ??
          0,
      postCount: (json['post_count'] as num?)?.toInt() ??
          (json['posts_count'] as num?)?.toInt() ??
          (profile?['post_count'] as num?)?.toInt() ??
          0,
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'interests': interests,
      'followers_count': followersCount,
      'following_count': followingCount,
      'post_count': postCount,
      'is_verified': isVerified,
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? bio,
    List<String>? interests,
    int? followersCount,
    int? followingCount,
    int? postCount,
    bool? isVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postCount: postCount ?? this.postCount,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        displayName,
        avatarUrl,
        bio,
        interests,
        followersCount,
        followingCount,
        postCount,
        isVerified,
      ];
}
