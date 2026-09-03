import 'package:equatable/equatable.dart';
import 'package:client/features/posts/data/models/post_models.dart';

class HomeFeedState extends Equatable {
  final List<PostModel> posts;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final int offset;
  final String? errorMessage;

  const HomeFeedState({
    this.posts = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.offset = 0,
    this.errorMessage,
  });

  HomeFeedState copyWith({
    List<PostModel>? posts,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    int? offset,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HomeFeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    posts,
    isLoading,
    isRefreshing,
    isLoadingMore,
    hasMore,
    offset,
    errorMessage,
  ];
}
