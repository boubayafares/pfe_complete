import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps flutter_secure_storage — backed by Keychain (iOS/macOS), Keystore
/// (Android), DPAPI (Windows), and IndexedDB (Web), so the same code works
/// unmodified across all five targets.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'ft_access_token';
  static const _refreshTokenKey = 'ft_refresh_token';
  static const _userProfileKey = 'ft_user_profile';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(
      key: _accessTokenKey,
      value: accessToken,
    );
    await _storage.write(
      key: _refreshTokenKey,
      value: refreshToken,
    );
  }

  Future<String?> get accessToken =>
      _storage.read(key: _accessTokenKey);

  Future<String?> get refreshToken =>
      _storage.read(key: _refreshTokenKey);

  Future<void> saveUserProfileJson(String json) =>
      _storage.write(
        key: _userProfileKey,
        value: json,
      );

  Future<String?> get userProfileJson =>
      _storage.read(key: _userProfileKey);

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userProfileKey);
  }

  Future<bool> get hasSession async =>
      (await accessToken) != null;
}