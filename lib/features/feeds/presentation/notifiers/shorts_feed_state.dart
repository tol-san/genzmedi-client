import 'package:equatable/equatable.dart';
import 'package:client/features/posts/data/models/post_models.dart';

class ShortsFeedState extends Equatable {
  final List<PostModel> shorts;
  final int activeIndex;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final int offset;
  final String? errorMessage;

  const ShortsFeedState({
    this.shorts = const [],
    this.activeIndex = 0,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.offset = 0,
    this.errorMessage,
  });

  ShortsFeedState copyWith({
    List<PostModel>? shorts,
    int? activeIndex,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    int? offset,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ShortsFeedState(
      shorts: shorts ?? this.shorts,
      activeIndex: activeIndex ?? this.activeIndex,
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
        shorts,
        activeIndex,
        isLoading,
        isRefreshing,
        isLoadingMore,
        hasMore,
        offset,
        errorMessage,
      ];
}
