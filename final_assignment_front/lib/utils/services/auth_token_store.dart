import 'package:shared_preferences/shared_preferences.dart';

class AuthTokenStore {
  AuthTokenStore._();

  static final AuthTokenStore instance = AuthTokenStore._();

  SharedPreferences? _prefs;
  String? _jwtToken;
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _prefs ??= await SharedPreferences.getInstance();
    _jwtToken = _prefs!.getString('jwt_token') ?? _prefs!.getString('jwtToken');
    _loaded = true;
  }

  Future<String?> getJwtToken() async {
    await _ensureLoaded();
    return _jwtToken;
  }

  String? peekJwtToken() => _jwtToken;

  Future<void> setJwtToken(String? token) async {
    _jwtToken = token;
    _loaded = true;
    _prefs ??= await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await _prefs!.remove('jwtToken');
      await _prefs!.remove('jwt_token');
    } else {
      await _prefs!.setString('jwtToken', token);
      await _prefs!.setString('jwt_token', token);
    }
  }

  Future<void> clearJwtToken() async {
    await setJwtToken(null);
  }
}
