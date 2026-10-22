import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthTokenStore {
  AuthTokenStore._();

  static final AuthTokenStore instance = AuthTokenStore._();

  static const _secureStorage = FlutterSecureStorage();
  static const _jwtKey = 'jwt_token';
  static const _refreshKey = 'refresh_token';
  static const _legacyJwtKeys = ['jwt_token', 'jwtToken'];
  static const _legacyRefreshKeys = ['refresh_token', 'refreshToken'];

  // flutter_secure_storage's web backend refuses to run outside a secure
  // context (HTTPS or loopback only), so a plain-HTTP host cannot use it and
  // the web build keeps the tokens in SharedPreferences (localStorage)
  // instead. Everything running on the origin can read them from there, so the
  // tokens must never end up in a log line.
  static const _webJwtKey = 'auth_web_jwt_token';
  static const _webRefreshKey = 'auth_web_refresh_token';

  SharedPreferences? _prefs;
  String? _jwtToken;
  String? _refreshToken;
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;

    if (kIsWeb) {
      await _loadWebTokens();
    } else {
      await _loadSecureTokens();
    }
    _loaded = true;
  }

  Future<String?> getJwtToken() async {
    await _ensureLoaded();
    return _jwtToken;
  }

  String? peekJwtToken() => _jwtToken;

  Future<void> setJwtToken(String? token) async {
    await _writeToken(
      secureKey: _jwtKey,
      legacyKeys: _legacyJwtKeys,
      webKey: _webJwtKey,
      value: token,
    );
    _jwtToken = _normalizeToken(token);
    _loaded = true;
  }

  Future<void> clearJwtToken() async {
    await setJwtToken(null);
  }

  Future<String?> getRefreshToken() async {
    await _ensureLoaded();
    return _refreshToken;
  }

  Future<void> setRefreshToken(String? token) async {
    await _writeToken(
      secureKey: _refreshKey,
      legacyKeys: _legacyRefreshKeys,
      webKey: _webRefreshKey,
      value: token,
    );
    _refreshToken = _normalizeToken(token);
    _loaded = true;
  }

  Future<void> clearRefreshToken() async {
    await setRefreshToken(null);
  }

  Future<void> clearAll() async {
    await setJwtToken(null);
    await setRefreshToken(null);
  }

  Future<void> _loadSecureTokens() async {
    _prefs ??= await SharedPreferences.getInstance();
    _jwtToken = await _readSecureToken(
      secureKey: _jwtKey,
      legacyKeys: _legacyJwtKeys,
    );
    _refreshToken = await _readSecureToken(
      secureKey: _refreshKey,
      legacyKeys: _legacyRefreshKeys,
    );
  }

  Future<String?> _readSecureToken({
    required String secureKey,
    required List<String> legacyKeys,
  }) async {
    final secureValue =
        _normalizeToken(await _secureStorage.read(key: secureKey));
    if (secureValue != null) {
      await _removeLegacyKeys(legacyKeys);
      return secureValue;
    }

    for (final key in legacyKeys) {
      final legacyValue = _normalizeToken(_prefs!.getString(key));
      if (legacyValue != null) {
        await _secureStorage.write(key: secureKey, value: legacyValue);
        await _removeLegacyKeys(legacyKeys);
        return legacyValue;
      }
    }

    await _removeLegacyKeys(legacyKeys);
    return null;
  }

  Future<void> _loadWebTokens() async {
    final prefs = await _openPreferences();
    _jwtToken = _readWebToken(prefs, _webJwtKey);
    _refreshToken = _readWebToken(prefs, _webRefreshKey);
    await _removeLegacyKeys(_legacyJwtKeys);
    await _removeLegacyKeys(_legacyRefreshKeys);
  }

  String? _readWebToken(SharedPreferences? prefs, String key) {
    if (prefs == null) return null;
    try {
      return _normalizeToken(prefs.getString(key));
    } catch (error) {
      AppLogger.error('Web token read failed: ${error.runtimeType}');
      return null;
    }
  }

  Future<void> _writeToken({
    required String secureKey,
    required List<String> legacyKeys,
    required String webKey,
    required String? value,
  }) async {
    final normalized = _normalizeToken(value);
    if (kIsWeb) {
      await _writeWebToken(
        legacyKeys: legacyKeys,
        webKey: webKey,
        value: normalized,
      );
      return;
    }

    _prefs ??= await SharedPreferences.getInstance();
    if (normalized == null) {
      await _secureStorage.delete(key: secureKey);
    } else {
      await _secureStorage.write(key: secureKey, value: normalized);
    }
    await _removeLegacyKeys(legacyKeys);
  }

  Future<void> _writeWebToken({
    required List<String> legacyKeys,
    required String webKey,
    required String? value,
  }) async {
    final prefs = await _openPreferences();
    if (prefs != null) {
      try {
        if (value == null) {
          await prefs.remove(webKey);
        } else {
          await prefs.setString(webKey, value);
        }
      } catch (error) {
        // Persisting is best effort: an unavailable localStorage must not
        // break the sign-in, the session then simply stays in memory.
        AppLogger.error('Web token write failed: ${error.runtimeType}');
      }
    }
    await _removeLegacyKeys(legacyKeys);
  }

  Future<void> _removeLegacyKeys(List<String> keys) async {
    final prefs = await _openPreferences();
    if (prefs == null) return;
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  /// Opens the preference store. The web build degrades to a memory-only
  /// session when localStorage is unavailable instead of failing outright.
  Future<SharedPreferences?> _openPreferences() async {
    final existing = _prefs;
    if (existing != null) return existing;
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (error) {
      if (!kIsWeb) rethrow;
      AppLogger.error('Web preferences unavailable: ${error.runtimeType}');
    }
    return _prefs;
  }

  String? _normalizeToken(String? token) {
    final trimmed = token?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
