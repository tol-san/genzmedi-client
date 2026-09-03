import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/settings/data/repositories/settings_repository.dart';
import 'package:client/features/settings/presentation/notifiers/change_password_state.dart';

final changePasswordNotifierProvider = StateNotifierProvider.autoDispose<
    ChangePasswordNotifier, ChangePasswordState>((ref) {
  return ChangePasswordNotifier(
    repository: ref.watch(settingsRepositoryProvider),
  );
});

class ChangePasswordNotifier extends StateNotifier<ChangePasswordState> {
  final SettingsRepository repository;

  ChangePasswordNotifier({required this.repository})
      : super(const ChangePasswordState());

  void toggleObscureCurrent() {
    state = state.copyWith(obscureCurrent: !state.obscureCurrent);
  }

  void toggleObscureNew() {
    state = state.copyWith(obscureNew: !state.obscureNew);
  }

  void toggleObscureConfirm() {
    state = state.copyWith(obscureConfirm: !state.obscureConfirm);
  }

  Future<bool> submit({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final cur = currentPassword.trim();
    final next = newPassword.trim();
    final confirm = confirmPassword.trim();

    if (cur.isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter your current password.');
      return false;
    }
    if (next.isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter a new password.');
      return false;
    }
    if (next.length < 8) {
      state = state.copyWith(
        errorMessage: 'New password must be at least 8 characters long.',
      );
      return false;
    }
    if (cur == next) {
      state = state.copyWith(
        errorMessage: 'New password must be different from your current password.',
      );
      return false;
    }
    if (next != confirm) {
      state = state.copyWith(errorMessage: 'New passwords do not match.');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await repository.changePassword(
        currentPassword: cur,
        newPassword: next,
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (error) {
      final msg = error is AppException
          ? error.message
          : 'Failed to change password. Please verify your current password.';
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }
}
