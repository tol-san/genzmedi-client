import 'package:equatable/equatable.dart';

/// Directional follow and block status between authenticated user and target user
class RelationshipModel extends Equatable {
  final bool isFollowing;
  final bool isFollowedBy;
  final bool isBlocking;
  final bool isBlockedBy;

  const RelationshipModel({
    this.isFollowing = false,
    this.isFollowedBy = false,
    this.isBlocking = false,
    this.isBlockedBy = false,
  });

  factory RelationshipModel.fromJson(Map<String, dynamic> json) {
    return RelationshipModel(
      isFollowing: json['is_following'] as bool? ?? false,
      isFollowedBy: json['is_followed_by'] as bool? ?? false,
      isBlocking: json['is_blocking'] as bool? ?? false,
      isBlockedBy: json['is_blocked_by'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'is_following': isFollowing,
        'is_followed_by': isFollowedBy,
        'is_blocking': isBlocking,
        'is_blocked_by': isBlockedBy,
      };

  RelationshipModel copyWith({
    bool? isFollowing,
    bool? isFollowedBy,
    bool? isBlocking,
    bool? isBlockedBy,
  }) {
    return RelationshipModel(
      isFollowing: isFollowing ?? this.isFollowing,
      isFollowedBy: isFollowedBy ?? this.isFollowedBy,
      isBlocking: isBlocking ?? this.isBlocking,
      isBlockedBy: isBlockedBy ?? this.isBlockedBy,
    );
  }

  @override
  List<Object?> get props => [isFollowing, isFollowedBy, isBlocking, isBlockedBy];
}
