import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// OS-level encrypted storage service for sensitive tokens and user session data.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(
              encryptedSharedPreferences: false,
              resetOnError: true,
            ),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    } catch (_) {}
  }

  Future<String?> getAccessToken() async {
    try {
      return await _storage
          .read(key: _accessTokenKey)
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage
          .read(key: _refreshTokenKey)
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUserId(String userId) async {
    try {
      await _storage.write(key: _userIdKey, value: userId);
    } catch (_) {}
  }

  Future<String?> getUserId() async {
    try {
      return await _storage
          .read(key: _userIdKey)
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}
