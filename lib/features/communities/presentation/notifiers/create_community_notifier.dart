import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/communities/data/models/community_models.dart';
import 'package:client/features/communities/data/repositories/community_repository.dart';
import 'package:client/features/communities/presentation/notifiers/create_community_state.dart';

final createCommunityNotifierProvider = StateNotifierProvider<
    CreateCommunityNotifier, CreateCommunityState>((ref) {
  final repository = ref.watch(communityRepositoryProvider);
  return CreateCommunityNotifier(repository: repository);
});

class CreateCommunityNotifier extends StateNotifier<CreateCommunityState> {
  final CommunityRepository repository;

  CreateCommunityNotifier({required this.repository})
      : super(const CreateCommunityState());

  void setName(String name) {
    // Auto generate slug from name if not manually modified
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
    state = state.copyWith(name: name, slug: slug);
  }

  void setSlug(String slug) {
    state = state.copyWith(slug: slug);
  }

  void setDescription(String description) {
    state = state.copyWith(description: description);
  }

  void setInterestId(String? interestId) {
    if (interestId == null) {
      state = state.copyWith(clearInterest: true);
    } else {
      state = state.copyWith(interestId: interestId);
    }
  }

  void setIsPrivate(bool isPrivate) {
    state = state.copyWith(isPrivate: isPrivate);
  }

  void setAvatar(File avatar) {
    state = state.copyWith(selectedAvatar: avatar);
  }

  void setCover(File cover) {
    state = state.copyWith(selectedCover: cover);
  }

  Future<bool> submitCommunity() async {
    if (state.name.trim().length < 2) {
      state = state.copyWith(
          errorMessage: 'Community name must be at least 2 characters.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final request = CommunityCreateRequestModel(
        name: state.name.trim(),
        slug: state.slug.trim().isNotEmpty ? state.slug.trim() : null,
        description: state.description.trim().isNotEmpty
            ? state.description.trim()
            : null,
        interestId: state.interestId,
        isPrivate: state.isPrivate,
      );

      var community = await repository.createCommunity(request);

      // Upload cover if chosen
      if (state.selectedCover != null) {
        community =
            await repository.uploadCover(community.id, state.selectedCover!);
      }

      state = state.copyWith(
        isSubmitting: false,
        isSuccess: true,
        createdCommunity: community,
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to create community.',
      );
      return false;
    }
  }

  void reset() {
    state = const CreateCommunityState();
  }
}
