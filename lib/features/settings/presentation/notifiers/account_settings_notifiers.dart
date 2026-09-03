import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/settings/data/models/settings_models.dart';
import 'package:client/features/settings/data/repositories/settings_repository.dart';

String _message(Object error, String fallback) =>
    error is AppException ? error.message : fallback;

class PrivacySettingsState extends Equatable {
  final PrivacySettings? settings;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const PrivacySettingsState({
    this.settings,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  PrivacySettingsState copyWith({
    PrivacySettings? settings,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) =>
      PrivacySettingsState(
        settings: settings ?? this.settings,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [settings, isLoading, isSaving, errorMessage];
}

final privacySettingsProvider = StateNotifierProvider.autoDispose<
    PrivacySettingsNotifier, PrivacySettingsState>((ref) {
  return PrivacySettingsNotifier(ref.watch(settingsRepositoryProvider));
});

class PrivacySettingsNotifier extends StateNotifier<PrivacySettingsState> {
  final SettingsRepository repository;

  PrivacySettingsNotifier(this.repository, {bool loadOnCreate = true})
      : super(const PrivacySettingsState()) {
    if (loadOnCreate) load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      state = state.copyWith(
        settings: await repository.getPrivacySettings(),
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _message(error, 'Could not load privacy settings.'),
      );
    }
  }

  Future<bool> update(Map<String, dynamic> changes) async {
    if (state.isSaving || state.settings == null) return false;
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      state = state.copyWith(
        settings: await repository.updatePrivacySettings(changes),
        isSaving: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: _message(error, 'Could not save privacy settings.'),
      );
      return false;
    }
  }
}

class NotificationPreferencesState extends Equatable {
  final NotificationPreferences? preferences;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const NotificationPreferencesState({
    this.preferences,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  NotificationPreferencesState copyWith({
    NotificationPreferences? preferences,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) =>
      NotificationPreferencesState(
        preferences: preferences ?? this.preferences,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [preferences, isLoading, isSaving, errorMessage];
}

final notificationPreferencesProvider = StateNotifierProvider.autoDispose<
    NotificationPreferencesNotifier, NotificationPreferencesState>((ref) {
  return NotificationPreferencesNotifier(ref.watch(settingsRepositoryProvider));
});

class NotificationPreferencesNotifier
    extends StateNotifier<NotificationPreferencesState> {
  final SettingsRepository repository;

  NotificationPreferencesNotifier(this.repository, {bool loadOnCreate = true})
      : super(const NotificationPreferencesState()) {
    if (loadOnCreate) load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      state = state.copyWith(
        preferences: await repository.getNotificationPreferences(),
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _message(error, 'Could not load notification settings.'),
      );
    }
  }

  Future<bool> update(Map<String, dynamic> changes) async {
    if (state.isSaving || state.preferences == null) return false;
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      state = state.copyWith(
        preferences: await repository.updateNotificationPreferences(changes),
        isSaving: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: _message(error, 'Could not save notification settings.'),
      );
      return false;
    }
  }
}

class SessionsState extends Equatable {
  final List<UserSession> sessions;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const SessionsState({
    this.sessions = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  SessionsState copyWith({
    List<UserSession>? sessions,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) =>
      SessionsState(
        sessions: sessions ?? this.sessions,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [sessions, isLoading, isSaving, errorMessage];
}

final sessionsProvider =
    StateNotifierProvider.autoDispose<SessionsNotifier, SessionsState>((ref) {
  return SessionsNotifier(ref.watch(settingsRepositoryProvider));
});

class SessionsNotifier extends StateNotifier<SessionsState> {
  final SettingsRepository repository;

  SessionsNotifier(this.repository, {bool loadOnCreate = true})
      : super(const SessionsState()) {
    if (loadOnCreate) load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      state = state.copyWith(
        sessions: await repository.getSessions(),
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _message(error, 'Could not load signed-in devices.'),
      );
    }
  }

  Future<bool> revoke(String sessionId) async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await repository.revokeSession(sessionId);
      state = state.copyWith(
        sessions: state.sessions.where((item) => item.id != sessionId).toList(),
        isSaving: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: _message(error, 'Could not sign out that device.'),
      );
      return false;
    }
  }

  Future<bool> revokeOthers() async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await repository.revokeOtherSessions();
      state = state.copyWith(
        sessions: state.sessions.where((item) => item.isCurrent).toList(),
        isSaving: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: _message(error, 'Could not sign out other devices.'),
      );
      return false;
    }
  }
}

class AccountActionState extends Equatable {
  final bool isLoading;
  final String? errorMessage;

  const AccountActionState({this.isLoading = false, this.errorMessage});

  AccountActionState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) =>
      AccountActionState(
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [isLoading, errorMessage];
}

final accountActionProvider = StateNotifierProvider.autoDispose<
    AccountActionNotifier, AccountActionState>((ref) {
  return AccountActionNotifier(ref.watch(settingsRepositoryProvider));
});

class AccountActionNotifier extends StateNotifier<AccountActionState> {
  final SettingsRepository repository;

  AccountActionNotifier(this.repository) : super(const AccountActionState());

  Future<bool> deactivate(String password, {String? reason}) async {
    if (password.isEmpty || state.isLoading) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await repository.deactivateAccount(password: password, reason: reason);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _message(error, 'Could not deactivate your account.'),
      );
      return false;
    }
  }

  Future<bool> delete(String password, String confirmation) async {
    if (password.isEmpty || confirmation != 'DELETE' || state.isLoading) {
      return false;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await repository.deleteAccount(password: password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _message(error, 'Could not delete your account.'),
      );
      return false;
    }
  }
}
