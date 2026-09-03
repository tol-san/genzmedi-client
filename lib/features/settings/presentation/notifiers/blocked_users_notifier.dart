import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/settings/data/repositories/settings_repository.dart';
import 'package:client/features/settings/presentation/notifiers/blocked_users_state.dart';

final blockedUsersNotifierProvider = StateNotifierProvider.autoDispose<
    BlockedUsersNotifier, BlockedUsersState>((ref) {
  return BlockedUsersNotifier(
    repository: ref.watch(settingsRepositoryProvider),
  );
});

class BlockedUsersNotifier extends StateNotifier<BlockedUsersState> {
  final SettingsRepository repository;
  static const int _pageSize = 20;

  BlockedUsersNotifier({required this.repository})
      : super(const BlockedUsersState()) {
    loadBlockedUsers();
  }

  Future<void> loadBlockedUsers() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await repository.getBlockedUsers(limit: _pageSize, offset: 0);
      state = state.copyWith(
        users: page.items,
        total: page.total,
        hasMore: page.hasMore,
        isLoading: false,
      );
    } catch (error) {
      final msg = error is AppException
          ? error.message
          : 'Could not load blocked users.';
      state = state.copyWith(isLoading: false, errorMessage: msg);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await repository.getBlockedUsers(
        limit: _pageSize,
        offset: state.users.length,
      );
      state = state.copyWith(
        users: [...state.users, ...page.items],
        total: page.total,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: 'Failed to load more blocked users.',
      );
    }
  }

  Future<bool> unblockUser(String userId) async {
    if (state.pendingUnblockIds.contains(userId)) return false;

    // Optimistic removal
    final originalUsers = state.users;
    final target = originalUsers.firstWhere(
      (u) => u.id == userId,
      orElse: () => originalUsers.first,
    );

    state = state.copyWith(
      users: state.users.where((u) => u.id != userId).toList(),
      total: (state.total - 1).clamp(0, 999999),
      pendingUnblockIds: {...state.pendingUnblockIds, userId},
    );

    try {
      await repository.unblockUser(userId);
      state = state.copyWith(
        pendingUnblockIds: state.pendingUnblockIds.where((id) => id != userId).toSet(),
      );
      return true;
    } catch (error) {
      // Rollback on failure
      state = state.copyWith(
        users: originalUsers,
        total: originalUsers.length,
        pendingUnblockIds: state.pendingUnblockIds.where((id) => id != userId).toSet(),
        errorMessage: 'Failed to unblock @${target.username}. Please try again.',
      );
      return false;
    }
  }
}
