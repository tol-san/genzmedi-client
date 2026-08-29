import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/posts/data/models/post_models.dart';
import 'package:client/features/posts/data/repositories/post_repository.dart';
import 'package:client/features/posts/presentation/notifiers/create_post_state.dart';

final createPostNotifierProvider =
    StateNotifierProvider<CreatePostNotifier, CreatePostState>((ref) {
  final repository = ref.watch(postRepositoryProvider);
  return CreatePostNotifier(repository: repository);
});

class CreatePostNotifier extends StateNotifier<CreatePostState> {
  final PostRepository repository;

  CreatePostNotifier({required this.repository})
      : super(const CreatePostState());

  void setPostType(String postType) {
    state = state.copyWith(postType: postType);
  }

  void setTitle(String title) {
    state = state.copyWith(title: title);
  }

  void setContent(String content) {
    state = state.copyWith(content: content);
  }

  void setVisibility(String visibility) {
    state = state.copyWith(visibility: visibility);
  }

  void setCommunityId(String? communityId) {
    if (communityId == null) {
      state = state.copyWith(clearCommunity: true);
    } else {
      state = state.copyWith(communityId: communityId);
    }
  }

  void addImages(List<File> images) {
    final updated = [...state.selectedImages, ...images].take(10).toList();
    state = state.copyWith(selectedImages: updated, postType: 'image');
  }

  void removeImageAt(int index) {
    if (index >= 0 && index < state.selectedImages.length) {
      final updated = List<File>.from(state.selectedImages)..removeAt(index);
      state = state.copyWith(selectedImages: updated);
    }
  }

  void setVideo(File video, {File? thumbnail, double? duration}) {
    state = state.copyWith(
      selectedVideo: video,
      selectedThumbnail: thumbnail,
      videoDuration: duration,
      postType: 'video',
    );
  }

  void setThumbnail(File thumbnail) {
    state = state.copyWith(selectedThumbnail: thumbnail);
  }

  void clearMedia() {
    state = state.copyWith(
      selectedImages: [],
      clearVideo: true,
      clearThumbnail: true,
      videoDuration: null,
      postType: 'text',
    );
  }

  Future<bool> submitPost() async {
    // 1. Validation
    if (state.postType == 'text' && state.content.trim().isEmpty && state.title.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter content or a title for your post.');
      return false;
    }
    if (state.postType == 'image' && state.selectedImages.isEmpty) {
      state = state.copyWith(errorMessage: 'Please select at least one image to upload.');
      return false;
    }
    if (state.postType == 'video' && state.selectedVideo == null) {
      state = state.copyWith(errorMessage: 'Please select a video to upload.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final List<MediaItemModel> mediaItems = [];

      // 2. Upload images if image post
      if (state.postType == 'image' && state.selectedImages.isNotEmpty) {
        state = state.copyWith(isUploadingMedia: true);
        for (int i = 0; i < state.selectedImages.length; i++) {
          final file = state.selectedImages[i];
          final uploaded = await repository.uploadMedia(file, mediaType: 'image');
          mediaItems.add(
            MediaItemModel(
              id: 'temp-$i',
              mediaType: 'image',
              url: uploaded.url,
              width: uploaded.width,
              height: uploaded.height,
              order: i,
            ),
          );
        }
        state = state.copyWith(isUploadingMedia: false);
      }

      // 3. Upload video if video post
      if (state.postType == 'video' && state.selectedVideo != null) {
        state = state.copyWith(isUploadingMedia: true);

        // Upload custom thumbnail if chosen
        String? thumbnailUrl;
        if (state.selectedThumbnail != null) {
          final thumbUpload = await repository.uploadMedia(
            state.selectedThumbnail!,
            mediaType: 'image',
          );
          thumbnailUrl = thumbUpload.url;
        }

        final videoUpload = await repository.uploadMedia(
          state.selectedVideo!,
          mediaType: 'video',
        );

        mediaItems.add(
          MediaItemModel(
            id: 'temp-video',
            mediaType: 'video',
            url: videoUpload.url,
            thumbnailUrl: thumbnailUrl ?? videoUpload.thumbnailUrl,
            duration: state.videoDuration ?? videoUpload.duration,
            width: videoUpload.width,
            height: videoUpload.height,
            order: 0,
          ),
        );
        state = state.copyWith(isUploadingMedia: false);
      }

      // 4. Create Post via POST /posts
      final request = PostCreateRequestModel(
        postType: state.postType,
        title: state.title.trim().isNotEmpty ? state.title.trim() : null,
        content: state.content.trim().isNotEmpty ? state.content.trim() : null,
        visibility: state.visibility,
        communityId: state.communityId,
        media: mediaItems,
      );

      final post = await repository.createPost(request);
      state = state.copyWith(
        isSubmitting: false,
        isSuccess: true,
        createdPost: post,
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        isUploadingMedia: false,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        isUploadingMedia: false,
        errorMessage: 'Failed to publish post. Please retry.',
      );
      return false;
    }
  }

  void reset() {
    state = const CreatePostState();
  }
}
