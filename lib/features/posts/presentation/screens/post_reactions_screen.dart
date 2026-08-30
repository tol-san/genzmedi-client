import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_avatar.dart';
import 'package:client/core/widgets/app_button.dart';
import 'package:client/core/widgets/app_skeleton.dart';
import 'package:client/features/posts/data/models/reaction_models.dart';
import 'package:client/features/posts/data/repositories/post_repository.dart';

/// Screen displaying users who reacted to a post with reaction category filters and search.
class PostReactionsScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostReactionsScreen({
    super.key,
    required this.postId,
  });

  @override
  ConsumerState<PostReactionsScreen> createState() => _PostReactionsScreenState();
}

class _PostReactionsScreenState extends ConsumerState<PostReactionsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  PostReactionsModel? _reactions;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadReactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(postRepositoryProvider);
      final data = await repo.getPostReactions(
        widget.postId,
        query: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      if (mounted) {
        setState(() {
          _reactions = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load likes.';
        });
      }
    }
  }

  Widget _buildReactionIconBadge({double size = 18}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryCrimson,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Icon(Icons.favorite_rounded, size: size * 0.6, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalCount = _reactions?.total ?? 0;

    final filteredUsers = (_reactions?.items ?? []).where((u) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (u.displayName ?? u.username).toLowerCase();
        return name.contains(q) || u.username.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.midnightNavy : AppColors.lightCanvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: AppTypography.body.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search people who liked...',
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim());
                },
              )
            : Text(
                'Likes',
                style: AppTypography.heading.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
                _isSearching = !_isSearching;
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
                  width: 0.8,
                ),
              ),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip(
                  key: 'all',
                  icon: _buildReactionIconBadge(size: 16),
                  label: 'All $totalCount',
                  isSelected: true,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(context, filteredUsers, isDark),
    );
  }

  Widget _buildFilterChip({
    required String key,
    Widget? icon,
    required String label,
    required bool isSelected,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? AppColors.primaryCrimson.withValues(alpha: 0.2)
                    : const Color(0xFFFFEBEF))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                icon,
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primaryCrimson
                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<ReactorUserModel> users, bool isDark) {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.space16),
        itemCount: 8,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.space16),
          child: Row(
            children: [
              AppSkeleton.circle(size: 48),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton(width: 140, height: 16),
                    SizedBox(height: 6),
                    AppSkeleton(width: 80, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: AppTypography.body.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'Retry',
              onPressed: _loadReactions,
              isFullWidth: false,
            ),
          ],
        ),
      );
    }

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 48,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty ? 'No users match your search' : 'No likes yet',
              style: AppTypography.body.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReactions,
      color: AppColors.primaryCrimson,
      child: ListView.separated(
        itemCount: users.length,
        separatorBuilder: (context, index) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final user = users[index];
          final name = user.displayName ?? user.username;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space16,
              vertical: 4,
            ),
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () {
                    context.pushNamed(
                      RouteNames.publicProfile,
                      pathParameters: {'username': user.username},
                    );
                  },
                  child: AppAvatar(
                    name: name,
                    size: 44,
                    imageUrl: user.avatarUrl,
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: _buildReactionIconBadge(size: 18),
                ),
              ],
            ),
            title: GestureDetector(
              onTap: () {
                context.pushNamed(
                  RouteNames.publicProfile,
                  pathParameters: {'username': user.username},
                );
              },
              child: Text(
                name,
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ),
            subtitle: Text(
              user.mutualCount > 0
                  ? '${user.mutualCount} mutual connections'
                  : '@${user.username}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
            trailing: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop('@${user.username} ');
              },
              icon: const Icon(Icons.alternate_email_rounded, size: 14),
              label: const Text('Mention'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                side: BorderSide(
                  color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
