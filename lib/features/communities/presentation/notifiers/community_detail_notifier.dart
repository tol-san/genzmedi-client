import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/communities/data/repositories/community_repository.dart';
import 'package:client/features/communities/presentation/notifiers/community_detail_state.dart';

final communityDetailNotifierProvider = StateNotifierProvider.autoDispose
    .family<CommunityDetailNotifier, CommunityDetailState, String>(
        (ref, communityId) {
  final repository = ref.watch(communityRepositoryProvider);
  return CommunityDetailNotifier(
    communityId: communityId,
    repository: repository,
  );
});

class CommunityDetailNotifier extends StateNotifier<CommunityDetailState> {
  final String communityId;
  final CommunityRepository repository;

  CommunityDetailNotifier({
    required this.communityId,
    required this.repository,
  }) : super(const CommunityDetailState(isLoading: true)) {
    loadAll();
  }

  Future<void> loadAll() async {
    await loadCommunity();
    await Future.wait([
      loadPosts(),
      loadMembers(),
      if (state.detail?.isOwner ?? false) loadJoinRequests(),
    ]);
  }

  Future<void> loadCommunity() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final detail = await repository.getCommunity(communityId);
      state = state.copyWith(detail: detail, isLoading: false);
      if (detail.isOwner) {
        await loadJoinRequests();
      }
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Failed to load community details.');
    }
  }

  Future<void> loadPosts() async {
    state = state.copyWith(isLoadingPosts: true);
    try {
      final posts = await repository.getCommunityPosts(communityId);
      state = state.copyWith(posts: posts, isLoadingPosts: false);
    } catch (_) {
      state = state.copyWith(isLoadingPosts: false);
    }
  }

  Future<void> loadMembers() async {
    state = state.copyWith(isLoadingMembers: true);
    try {
      final members = await repository.listMembers(communityId);
      state = state.copyWith(members: members, isLoadingMembers: false);
    } catch (_) {
      state = state.copyWith(isLoadingMembers: false);
    }
  }

  Future<void> loadJoinRequests() async {
    state = state.copyWith(isLoadingRequests: true);
    try {
      final requests = await repository.listJoinRequests(communityId);
      state = state.copyWith(joinRequests: requests, isLoadingRequests: false);
    } catch (_) {
      state = state.copyWith(isLoadingRequests: false);
    }
  }

  Future<bool> joinCommunity() async {
    if (state.detail == null) return false;
    state = state.copyWith(isActionLoading: true, clearError: true);
    try {
      final result = await repository.joinCommunity(communityId);
      final isMember = result['is_member'] as bool? ?? false;
      final status = result['status'] as String? ?? 'joined';

      final updatedDetail = state.detail!.copyWith(
        isMember: isMember,
        joinRequestStatus: isMember ? null : status,
        community: state.detail!.community.copyWith(
          memberCount: isMember
              ? state.detail!.community.memberCount + 1
              : state.detail!.community.memberCount,
        ),
      );

      state = state.copyWith(
        detail: updatedDetail,
        isActionLoading: false,
      );
      if (isMember) {
        await loadMembers();
      }
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isActionLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Failed to join community.',
      );
      return false;
    }
  }

  Future<bool> leaveCommunity() async {
    if (state.detail == null) return false;
    state = state.copyWith(isActionLoading: true, clearError: true);
    try {
      await repository.leaveCommunity(communityId);

      final updatedDetail = state.detail!.copyWith(
        isMember: false,
        clearJoinRequest: true,
        community: state.detail!.community.copyWith(
          memberCount: (state.detail!.community.memberCount - 1).clamp(0, 999999),
        ),
      );

      state = state.copyWith(
        detail: updatedDetail,
        isActionLoading: false,
      );
      await loadMembers();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isActionLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Failed to leave community.',
      );
      return false;
    }
  }

  Future<bool> approveJoinRequest(String requestId) async {
    try {
      await repository.approveJoinRequest(communityId, requestId);
      state = state.copyWith(
        joinRequests:
            state.joinRequests.where((r) => r.id != requestId).toList(),
        detail: state.detail?.copyWith(
          community: state.detail!.community.copyWith(
            memberCount: state.detail!.community.memberCount + 1,
          ),
        ),
      );
      await loadMembers();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejectJoinRequest(String requestId) async {
    try {
      await repository.rejectJoinRequest(communityId, requestId);
      state = state.copyWith(
        joinRequests:
            state.joinRequests.where((r) => r.id != requestId).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> kickMember(String userId) async {
    try {
      await repository.kickMember(communityId, userId);
      state = state.copyWith(
        members: state.members.where((m) => m.userId != userId).toList(),
        detail: state.detail?.copyWith(
          community: state.detail!.community.copyWith(
            memberCount: (state.detail!.community.memberCount - 1).clamp(0, 999999),
          ),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
