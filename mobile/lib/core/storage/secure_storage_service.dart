import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  static const _accessTokenKey = 'sb_access_token';
  static const _refreshTokenKey = 'sb_refresh_token';
  static const _baseUrlKey = 'sb_api_base_url';
  static const _themeModeKey = 'sb_theme_mode';

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;

  SecureStorageService(this._secureStorage, this._prefs);

  Future<void> saveTokens({required String access, String? refresh}) async {
    await _secureStorage.write(key: _accessTokenKey, value: access);
    if (refresh != null && refresh.isNotEmpty) {
      await _secureStorage.write(key: _refreshTokenKey, value: refresh);
    }
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  // Base URL config: strictly enforces secure cloud URLs and purges stale local IPs
  String? getBaseUrl() {
    final url = _prefs.getString(_baseUrlKey);
    if (url == null ||
        url.trim().isEmpty ||
        !url.startsWith('https://') ||
        url.contains('192.168.') ||
        url.contains('10.0.2.2') ||
        url.contains('127.0.0.1') ||
        url.contains('localhost') ||
        url.contains('10.') ||
        url.contains('172.')) {
      if (url != null) {
        _prefs.remove(_baseUrlKey);
      }
      return null;
    }
    return url;
  }

  Future<void> setBaseUrl(String url) async {
    await _prefs.setString(_baseUrlKey, url);
  }

  // Theme mode
  String? getThemeMode() {
    return _prefs.getString(_themeModeKey);
  }

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_themeModeKey, mode);
  }

  // Generic Cache
  String? getCachedString(String key) => _prefs.getString(key);
  Future<void> setCachedString(String key, String value) => _prefs.setString(key, value);
  Future<void> removeCached(String key) => _prefs.remove(key);
}
