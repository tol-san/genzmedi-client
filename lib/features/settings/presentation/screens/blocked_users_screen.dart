import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_avatar.dart';
import 'package:client/core/widgets/empty_state_widget.dart';
import 'package:client/features/settings/presentation/notifiers/blocked_users_notifier.dart';

class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 300) {
      ref.read(blockedUsersNotifierProvider.notifier).loadMore();
    }
  }

  void _confirmUnblock(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Unblock @${user.username}?'),
        content: Text(
          'They will be able to view your profile, posts, and message you again.',
          style: AppTypography.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(blockedUsersNotifierProvider.notifier)
                  .unblockUser(user.id);
            },
            child: const Text(
              'Unblock',
              style: TextStyle(
                color: AppColors.primaryCrimson,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(blockedUsersNotifierProvider);
    final notifier = ref.read(blockedUsersNotifierProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Blocked Accounts',
          style: AppTypography.title.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading && state.users.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryCrimson),
            );
          }

          if (state.errorMessage != null && state.users.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.error_outline_rounded,
              title: 'Could not load blocked users',
              subtitle: state.errorMessage,
              actionText: 'Retry',
              onAction: notifier.loadBlockedUsers,
            );
          }

          if (state.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.block_rounded,
              title: 'No blocked users',
              subtitle:
                  'When you block someone, they will appear here and will be unable to interact with you.',
            );
          }

          return RefreshIndicator(
            color: AppColors.primaryCrimson,
            onRefresh: notifier.loadBlockedUsers,
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space16,
                vertical: AppSpacing.space12,
              ),
              itemCount: state.users.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
              ),
              itemBuilder: (context, index) {
                if (index == state.users.length) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.space16),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                final user = state.users[index];
                final isPending = state.pendingUnblockIds.contains(user.id);

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.space12,
                  ),
                  child: Row(
                    children: [
                      AppAvatar(
                        name: user.displayName ?? user.username,
                        imageUrl: user.avatarUrl,
                        size: 44,
                      ),
                      const SizedBox(width: AppSpacing.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName ?? user.username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '@${user.username}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space8),
                      OutlinedButton(
                        onPressed: isPending
                            ? null
                            : () => _confirmUnblock(context, user),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark
                                ? AppColors.navyBorder
                                : AppColors.lightBorder,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSpacing.roundedFull,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space16,
                            vertical: AppSpacing.space8,
                          ),
                        ),
                        child: isPending
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryCrimson,
                                ),
                              )
                            : Text(
                                'Unblock',
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryCrimson,
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
