import 'package:equatable/equatable.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/profiles/data/models/relationship_model.dart';

class PublicProfileState extends Equatable {
  final UserModel? user;
  final RelationshipModel relationship;
  final List<PostModel> posts;
  final bool isLoading;
  final bool isActionLoading;
  final bool isRefreshing;
  final String? errorMessage;

  const PublicProfileState({
    this.user,
    this.relationship = const RelationshipModel(),
    this.posts = const [],
    this.isLoading = false,
    this.isActionLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
  });

  PublicProfileState copyWith({
    UserModel? user,
    RelationshipModel? relationship,
    List<PostModel>? posts,
    bool? isLoading,
    bool? isActionLoading,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PublicProfileState(
      user: user ?? this.user,
      relationship: relationship ?? this.relationship,
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        user,
        relationship,
        posts,
        isLoading,
        isActionLoading,
        isRefreshing,
        errorMessage,
      ];
}
