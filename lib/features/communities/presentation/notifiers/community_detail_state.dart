import 'package:equatable/equatable.dart';
import 'package:client/features/communities/data/models/community_models.dart';
import 'package:client/features/posts/data/models/post_models.dart';

class CommunityDetailState extends Equatable {
  final CommunityDetailModel? detail;
  final List<PostModel> posts;
  final List<CommunityMemberModel> members;
  final List<JoinRequestModel> joinRequests;
  final bool isLoading;
  final bool isLoadingPosts;
  final bool isLoadingMembers;
  final bool isLoadingRequests;
  final bool isActionLoading;
  final String? errorMessage;

  const CommunityDetailState({
    this.detail,
    this.posts = const [],
    this.members = const [],
    this.joinRequests = const [],
    this.isLoading = false,
    this.isLoadingPosts = false,
    this.isLoadingMembers = false,
    this.isLoadingRequests = false,
    this.isActionLoading = false,
    this.errorMessage,
  });

  CommunityDetailState copyWith({
    CommunityDetailModel? detail,
    List<PostModel>? posts,
    List<CommunityMemberModel>? members,
    List<JoinRequestModel>? joinRequests,
    bool? isLoading,
    bool? isLoadingPosts,
    bool? isLoadingMembers,
    bool? isLoadingRequests,
    bool? isActionLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CommunityDetailState(
      detail: detail ?? this.detail,
      posts: posts ?? this.posts,
      members: members ?? this.members,
      joinRequests: joinRequests ?? this.joinRequests,
      isLoading: isLoading ?? this.isLoading,
      isLoadingPosts: isLoadingPosts ?? this.isLoadingPosts,
      isLoadingMembers: isLoadingMembers ?? this.isLoadingMembers,
      isLoadingRequests: isLoadingRequests ?? this.isLoadingRequests,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        detail,
        posts,
        members,
        joinRequests,
        isLoading,
        isLoadingPosts,
        isLoadingMembers,
        isLoadingRequests,
        isActionLoading,
        errorMessage,
      ];
}
