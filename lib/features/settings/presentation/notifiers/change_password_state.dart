import 'package:equatable/equatable.dart';

class ChangePasswordState extends Equatable {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;
  final bool obscureCurrent;
  final bool obscureNew;
  final bool obscureConfirm;

  const ChangePasswordState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
    this.obscureCurrent = true,
    this.obscureNew = true,
    this.obscureConfirm = true,
  });

  ChangePasswordState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    bool clearError = false,
    bool? obscureCurrent,
    bool? obscureNew,
    bool? obscureConfirm,
  }) {
    return ChangePasswordState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      obscureCurrent: obscureCurrent ?? this.obscureCurrent,
      obscureNew: obscureNew ?? this.obscureNew,
      obscureConfirm: obscureConfirm ?? this.obscureConfirm,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isSuccess,
        errorMessage,
        obscureCurrent,
        obscureNew,
        obscureConfirm,
      ];
}
