import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:client/features/communities/data/models/community_models.dart';

class CreateCommunityState extends Equatable {
  final String name;
  final String slug;
  final String description;
  final String? interestId;
  final bool isPrivate;
  final File? selectedAvatar;
  final File? selectedCover;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  final CommunityModel? createdCommunity;

  const CreateCommunityState({
    this.name = '',
    this.slug = '',
    this.description = '',
    this.interestId,
    this.isPrivate = false,
    this.selectedAvatar,
    this.selectedCover,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.createdCommunity,
  });

  CreateCommunityState copyWith({
    String? name,
    String? slug,
    String? description,
    String? interestId,
    bool clearInterest = false,
    bool? isPrivate,
    File? selectedAvatar,
    bool clearAvatar = false,
    File? selectedCover,
    bool clearCover = false,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    bool clearError = false,
    CommunityModel? createdCommunity,
  }) {
    return CreateCommunityState(
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      interestId: clearInterest ? null : (interestId ?? this.interestId),
      isPrivate: isPrivate ?? this.isPrivate,
      selectedAvatar:
          clearAvatar ? null : (selectedAvatar ?? this.selectedAvatar),
      selectedCover: clearCover ? null : (selectedCover ?? this.selectedCover),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      createdCommunity: createdCommunity ?? this.createdCommunity,
    );
  }

  @override
  List<Object?> get props => [
        name,
        slug,
        description,
        interestId,
        isPrivate,
        selectedAvatar,
        selectedCover,
        isSubmitting,
        isSuccess,
        errorMessage,
        createdCommunity,
      ];
}
