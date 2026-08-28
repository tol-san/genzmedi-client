import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize sharedPreferencesProvider in main.dart');
});

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PreferencesService(prefs);
});

/// Non-sensitive local preferences store (e.g., theme, onboarded flags).
class PreferencesService {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  static const String _themeModeKey = 'app_theme_mode';
  static const String _isOnboardedKey = 'has_completed_interest_onboarding';
  static const String _hasSessionKey = 'has_active_session';

  Future<void> setHasSession(bool hasSession) async {
    await _prefs.setBool(_hasSessionKey, hasSession);
  }

  bool hasSession() {
    return _prefs.getBool(_hasSessionKey) ?? false;
  }

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_themeModeKey, mode);
  }

  String? getThemeMode() {
    return _prefs.getString(_themeModeKey);
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(_isOnboardedKey, completed);
  }

  bool isOnboardingCompleted() {
    return _prefs.getBool(_isOnboardedKey) ?? false;
  }
}
