import 'package:equatable/equatable.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/features/posts/data/models/post_models.dart';

class MyProfileState extends Equatable {
  final UserModel? user;
  final bool isLoadingProfile;
  final bool isRefreshing;
  final List<PostModel> posts;
  final bool isLoadingPosts;
  final List<PostModel> savedPosts;
  final bool isLoadingSaved;
  final bool isLoadingMoreSaved;
  final bool hasMoreSaved;
  final String? savedErrorMessage;
  final String? errorMessage;

  const MyProfileState({
    this.user,
    this.isLoadingProfile = false,
    this.isRefreshing = false,
    this.posts = const [],
    this.isLoadingPosts = false,
    this.savedPosts = const [],
    this.isLoadingSaved = false,
    this.isLoadingMoreSaved = false,
    this.hasMoreSaved = false,
    this.savedErrorMessage,
    this.errorMessage,
  });

  MyProfileState copyWith({
    UserModel? user,
    bool? isLoadingProfile,
    bool? isRefreshing,
    List<PostModel>? posts,
    bool? isLoadingPosts,
    List<PostModel>? savedPosts,
    bool? isLoadingSaved,
    bool? isLoadingMoreSaved,
    bool? hasMoreSaved,
    String? savedErrorMessage,
    bool clearSavedError = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MyProfileState(
      user: user ?? this.user,
      isLoadingProfile: isLoadingProfile ?? this.isLoadingProfile,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      posts: posts ?? this.posts,
      isLoadingPosts: isLoadingPosts ?? this.isLoadingPosts,
      savedPosts: savedPosts ?? this.savedPosts,
      isLoadingSaved: isLoadingSaved ?? this.isLoadingSaved,
      isLoadingMoreSaved: isLoadingMoreSaved ?? this.isLoadingMoreSaved,
      hasMoreSaved: hasMoreSaved ?? this.hasMoreSaved,
      savedErrorMessage:
          clearSavedError
              ? null
              : (savedErrorMessage ?? this.savedErrorMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    user,
    isLoadingProfile,
    isRefreshing,
    posts,
    isLoadingPosts,
    savedPosts,
    isLoadingSaved,
    isLoadingMoreSaved,
    hasMoreSaved,
    savedErrorMessage,
    errorMessage,
  ];
}
