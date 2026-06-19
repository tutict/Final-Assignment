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

  SharedPreferences? _prefs;
  String? _jwtToken;
  String? _refreshToken;
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;

    _prefs ??= await SharedPreferences.getInstance();
    _jwtToken = await _loadToken(
      secureKey: _jwtKey,
      legacyKeys: _legacyJwtKeys,
    );
    _refreshToken = await _loadToken(
      secureKey: _refreshKey,
      legacyKeys: _legacyRefreshKeys,
    );
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

  Future<String?> _loadToken({
    required String secureKey,
    required List<String> legacyKeys,
  }) async {
    if (kIsWeb) {
      await _removeLegacyKeys(legacyKeys);
      return null;
    }

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

  Future<void> _writeToken({
    required String secureKey,
    required List<String> legacyKeys,
    required String? value,
  }) async {
    _prefs ??= await SharedPreferences.getInstance();
    final normalized = _normalizeToken(value);
    if (kIsWeb) {
      await _removeLegacyKeys(legacyKeys);
      return;
    }

    if (normalized == null) {
      await _secureStorage.delete(key: secureKey);
    } else {
      await _secureStorage.write(key: secureKey, value: normalized);
    }
    await _removeLegacyKeys(legacyKeys);
  }

  Future<void> _removeLegacyKeys(List<String> keys) async {
    _prefs ??= await SharedPreferences.getInstance();
    for (final key in keys) {
      await _prefs!.remove(key);
    }
  }

  String? _normalizeToken(String? token) {
    final trimmed = token?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
