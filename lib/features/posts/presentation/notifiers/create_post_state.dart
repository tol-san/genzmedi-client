import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:client/features/posts/data/models/post_models.dart';

class CreatePostState extends Equatable {
  final String postType;
  final String title;
  final String content;
  final String visibility;
  final String? communityId;
  final List<File> selectedImages;
  final File? selectedVideo;
  final File? selectedThumbnail;
  final double? videoDuration;
  final bool isUploadingMedia;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  final PostModel? createdPost;

  const CreatePostState({
    this.postType = 'text',
    this.title = '',
    this.content = '',
    this.visibility = 'public',
    this.communityId,
    this.selectedImages = const [],
    this.selectedVideo,
    this.selectedThumbnail,
    this.videoDuration,
    this.isUploadingMedia = false,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.createdPost,
  });

  CreatePostState copyWith({
    String? postType,
    String? title,
    String? content,
    String? visibility,
    String? communityId,
    bool clearCommunity = false,
    List<File>? selectedImages,
    File? selectedVideo,
    bool clearVideo = false,
    File? selectedThumbnail,
    bool clearThumbnail = false,
    double? videoDuration,
    bool? isUploadingMedia,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    bool clearError = false,
    PostModel? createdPost,
  }) {
    return CreatePostState(
      postType: postType ?? this.postType,
      title: title ?? this.title,
      content: content ?? this.content,
      visibility: visibility ?? this.visibility,
      communityId: clearCommunity ? null : (communityId ?? this.communityId),
      selectedImages: selectedImages ?? this.selectedImages,
      selectedVideo: clearVideo ? null : (selectedVideo ?? this.selectedVideo),
      selectedThumbnail:
          clearThumbnail ? null : (selectedThumbnail ?? this.selectedThumbnail),
      videoDuration: videoDuration ?? this.videoDuration,
      isUploadingMedia: isUploadingMedia ?? this.isUploadingMedia,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      createdPost: createdPost ?? this.createdPost,
    );
  }

  @override
  List<Object?> get props => [
        postType,
        title,
        content,
        visibility,
        communityId,
        selectedImages,
        selectedVideo,
        selectedThumbnail,
        videoDuration,
        isUploadingMedia,
        isSubmitting,
        isSuccess,
        errorMessage,
        createdPost,
      ];
}
