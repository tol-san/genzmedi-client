import 'package:equatable/equatable.dart';
import 'package:client/core/auth/user_model.dart';

class BlockedUsersState extends Equatable {
  final List<UserModel> users;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Set<String> pendingUnblockIds;
  final String? errorMessage;

  const BlockedUsersState({
    this.users = const [],
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.pendingUnblockIds = const {},
    this.errorMessage,
  });

  bool get isEmpty => users.isEmpty && !isLoading;

  BlockedUsersState copyWith({
    List<UserModel>? users,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Set<String>? pendingUnblockIds,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BlockedUsersState(
      users: users ?? this.users,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      pendingUnblockIds: pendingUnblockIds ?? this.pendingUnblockIds,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        users,
        total,
        isLoading,
        isLoadingMore,
        hasMore,
        pendingUnblockIds,
        errorMessage,
      ];
}
