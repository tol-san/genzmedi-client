import 'package:equatable/equatable.dart';

class CommunityModel extends Equatable {
  final String id;
  final String ownerId;
  final String? interestId;
  final String name;
  final String slug;
  final String? description;
  final String? coverImageUrl;
  final String? avatarUrl;
  final bool isPrivate;
  final int memberCount;
  final int postCount;
  final DateTime? createdAt;

  const CommunityModel({
    required this.id,
    required this.ownerId,
    this.interestId,
    required this.name,
    required this.slug,
    this.description,
    this.coverImageUrl,
    this.avatarUrl,
    this.isPrivate = false,
    this.memberCount = 0,
    this.postCount = 0,
    this.createdAt,
  });

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    return CommunityModel(
      id: json['id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      interestId: json['interest_id'] as String?,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isPrivate: json['is_private'] as bool? ?? false,
      memberCount: json['member_count'] as int? ?? 0,
      postCount: json['post_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      if (interestId != null) 'interest_id': interestId,
      'name': name,
      'slug': slug,
      if (description != null) 'description': description,
      if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'is_private': isPrivate,
      'member_count': memberCount,
      'post_count': postCount,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  CommunityModel copyWith({
    String? id,
    String? ownerId,
    String? interestId,
    String? name,
    String? slug,
    String? description,
    String? coverImageUrl,
    String? avatarUrl,
    bool? isPrivate,
    int? memberCount,
    int? postCount,
    DateTime? createdAt,
  }) {
    return CommunityModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      interestId: interestId ?? this.interestId,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isPrivate: isPrivate ?? this.isPrivate,
      memberCount: memberCount ?? this.memberCount,
      postCount: postCount ?? this.postCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    ownerId,
    interestId,
    name,
    slug,
    description,
    coverImageUrl,
    avatarUrl,
    isPrivate,
    memberCount,
    postCount,
    createdAt,
  ];
}

class CommunityDetailModel extends Equatable {
  final CommunityModel community;
  final bool isMember;
  final bool isOwner;
  final String? membershipRole;
  final String? joinRequestStatus;

  const CommunityDetailModel({
    required this.community,
    this.isMember = false,
    this.isOwner = false,
    this.membershipRole,
    this.joinRequestStatus,
  });

  factory CommunityDetailModel.fromJson(Map<String, dynamic> json) {
    return CommunityDetailModel(
      community: CommunityModel.fromJson(json),
      isMember: json['is_member'] as bool? ?? false,
      isOwner: json['is_owner'] as bool? ?? false,
      membershipRole: json['membership_role'] as String?,
      joinRequestStatus: json['join_request_status'] as String?,
    );
  }

  CommunityDetailModel copyWith({
    CommunityModel? community,
    bool? isMember,
    bool? isOwner,
    String? membershipRole,
    String? joinRequestStatus,
    bool clearJoinRequest = false,
  }) {
    return CommunityDetailModel(
      community: community ?? this.community,
      isMember: isMember ?? this.isMember,
      isOwner: isOwner ?? this.isOwner,
      membershipRole: membershipRole ?? this.membershipRole,
      joinRequestStatus: clearJoinRequest
          ? null
          : (joinRequestStatus ?? this.joinRequestStatus),
    );
  }

  @override
  List<Object?> get props => [
    community,
    isMember,
    isOwner,
    membershipRole,
    joinRequestStatus,
  ];
}

class CommunityMemberModel extends Equatable {
  final String id;
  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String role;
  final DateTime? joinedAt;

  const CommunityMemberModel({
    required this.id,
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.role = 'member',
    this.joinedAt,
  });

  factory CommunityMemberModel.fromJson(Map<String, dynamic> json) {
    return CommunityMemberModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'member',
      joinedAt: json['joined_at'] != null
          ? DateTime.tryParse(json['joined_at'].toString())
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    username,
    displayName,
    avatarUrl,
    role,
    joinedAt,
  ];
}

class JoinRequestModel extends Equatable {
  final String id;
  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String status;
  final DateTime? createdAt;

  const JoinRequestModel({
    required this.id,
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.status = 'pending',
    this.createdAt,
  });

  factory JoinRequestModel.fromJson(Map<String, dynamic> json) {
    return JoinRequestModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    username,
    displayName,
    avatarUrl,
    status,
    createdAt,
  ];
}

class CommunityCreateRequestModel {
  final String name;
  final String? slug;
  final String? description;
  final String? interestId;
  final String? coverImageUrl;
  final String? avatarUrl;
  final bool isPrivate;

  const CommunityCreateRequestModel({
    required this.name,
    this.slug,
    this.description,
    this.interestId,
    this.coverImageUrl,
    this.avatarUrl,
    this.isPrivate = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (slug != null && slug!.isNotEmpty) 'slug': slug,
      if (description != null && description!.isNotEmpty)
        'description': description,
      if (interestId != null && interestId!.isNotEmpty)
        'interest_id': interestId,
      if (coverImageUrl != null && coverImageUrl!.isNotEmpty)
        'cover_image_url': coverImageUrl,
      if (avatarUrl != null && avatarUrl!.isNotEmpty) 'avatar_url': avatarUrl,
      'is_private': isPrivate,
    };
  }
}
