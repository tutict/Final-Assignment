import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/core/config/app_config.dart';
import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_assignment_front/shared/utils/navigation_helper.dart';

class AuthenticatedUser {
  const AuthenticatedUser({
    required this.username,
    required this.roles,
    this.userId,
  });

  final String username;
  final int? userId;
  final List<String> roles;

  bool hasRole(String role) {
    final normalizedRole = role.toUpperCase();
    return roles.any((value) {
      final normalized = value.toUpperCase();
      return normalized == normalizedRole ||
          normalized == 'ROLE_$normalizedRole';
    });
  }
}

class AuthService extends GetxService {
  AuthService({
    http.Client? client,
    this.refreshSkew = const Duration(minutes: 5),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration refreshSkew;
  bool _isRedirecting = false;
  Completer<bool>? _refreshCompleter;

  Future<bool> ensureValidSession({bool redirectIfInvalid = false}) async {
    final token = await AuthTokenStore.instance.getJwtToken();
    if (token == null || token.isEmpty) {
      if (redirectIfInvalid) {
        await redirectToLogin(clearStoredTokens: false);
      }
      return false;
    }

    try {
      final decodedToken = JwtDecoder.decode(token);
      if (_shouldRefresh(token, decodedToken)) {
        final refreshed = await refreshJwtToken();
        final refreshedToken = await AuthTokenStore.instance.getJwtToken();
        if (!refreshed ||
            refreshedToken == null ||
            JwtDecoder.isExpired(refreshedToken)) {
          await clearTokens();
          if (redirectIfInvalid) {
            await redirectToLogin(clearStoredTokens: false);
          }
          return false;
        }
      }
      return true;
    } catch (error, stackTrace) {
      developer.log(
        'Invalid JWT token',
        error: error,
        stackTrace: stackTrace,
      );
      await clearTokens();
      if (redirectIfInvalid) {
        await redirectToLogin(clearStoredTokens: false);
      }
      return false;
    }
  }

  Future<String?> getValidJwtToken({bool redirectIfInvalid = false}) async {
    final isValid =
        await ensureValidSession(redirectIfInvalid: redirectIfInvalid);
    if (!isValid) return null;
    return AuthTokenStore.instance.getJwtToken();
  }

  Future<AuthenticatedUser?> currentUser({
    bool refreshIfNeeded = true,
    bool redirectIfInvalid = false,
  }) async {
    if (refreshIfNeeded) {
      final isValid =
          await ensureValidSession(redirectIfInvalid: redirectIfInvalid);
      if (!isValid) return null;
    }

    final token = await AuthTokenStore.instance.getJwtToken();
    if (token == null || token.isEmpty) return null;

    try {
      final decodedToken = JwtDecoder.decode(token);
      return AuthenticatedUser(
        username: decodedToken['sub']?.toString() ?? 'Unknown',
        userId: _intValue(decodedToken['userId']),
        roles: _extractRoles(decodedToken),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to decode current user from JWT',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<bool> refreshJwtToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();
    try {
      final result = await _refreshJwtTokenInternal();
      _refreshCompleter!.complete(result);
      return result;
    } catch (error, stackTrace) {
      if (!_refreshCompleter!.isCompleted) {
        _refreshCompleter!.complete(false);
      }
      AppLogger.error(
        'Token refresh failed',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<bool> _refreshJwtTokenInternal() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken =
        prefs.getString('refresh_token') ?? prefs.getString('refreshToken');
    if (refreshToken == null || refreshToken.isEmpty) {
      developer.log('No refresh token found');
      return false;
    }

    try {
      final response = await _client
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/auth/refresh'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 || response.body.isEmpty) {
        developer.log('JWT refresh failed: ${response.statusCode}');
        return false;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['success'] == true && body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : body;
      final newJwt =
          (data['accessToken'] ?? data['jwtToken'])?.toString();
      if (newJwt == null || newJwt.isEmpty) {
        developer.log('JWT refresh response did not contain accessToken');
        return false;
      }

      await AuthTokenStore.instance.setJwtToken(newJwt);
      final newRefreshToken = data['refreshToken']?.toString();
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await prefs.setString('refreshToken', newRefreshToken);
        await prefs.setString('refresh_token', newRefreshToken);
      }
      developer.log('JWT token refreshed successfully');
      return true;
    } catch (error, stackTrace) {
      developer.log(
        'Error refreshing JWT token',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> handleForbidden({String? source}) async {
    developer.log(
      'Forbidden${source == null ? '' : ' from $source'}',
    );
  }

  Future<void> handleUnauthorized({String? source}) async {
    if (_isRedirecting || Get.currentRoute == Routes.login) {
      return;
    }

    developer.log(
      'Handling 401${source == null ? '' : ' from $source'}',
    );
    await redirectToLogin(clearStoredTokens: true);
  }

  Future<void> redirectToLogin({bool clearStoredTokens = true}) async {
    if (_isRedirecting || Get.currentRoute == Routes.login) {
      return;
    }

    _isRedirecting = true;
    if (clearStoredTokens) {
      await clearTokens();
    }

    for (var i = 0; i < 50; i++) {
      if (Get.context != null && Get.currentRoute != Routes.login) {
        NavigationHelper.offAllNamed(Routes.login);
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    _isRedirecting = false;
  }

  Future<void> clearTokens() async {
    await AuthTokenStore.instance.clearJwtToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('refreshToken');
    await prefs.remove('refresh_token');
    await prefs.remove('authUserId');
    await prefs.remove('auth_user_id');
    await prefs.remove('driverId');
    await prefs.remove('driver_id');
    await prefs.remove('userId');
    await prefs.remove('userRole');
    await prefs.remove('userName');
    await prefs.remove('driverName');
    await prefs.remove('userEmail');
  }

  Future<void> clearToken() => clearTokens();

  Future<void> logout() async {
    try {
      final token = await AuthTokenStore.instance.getJwtToken();
      if (token != null && token.isNotEmpty) {
        await _client
            .post(
              Uri.parse('${AppConfig.apiBaseUrl}/api/auth/logout'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 5));
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Logout API failed',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      await clearTokens();
      NavigationHelper.offAllNamed(Routes.login);
    }
  }

  bool _shouldRefresh(String token, Map<String, dynamic> decodedToken) {
    if (JwtDecoder.isExpired(token)) {
      return true;
    }

    final expiresAt = _expirationDate(decodedToken);
    if (expiresAt == null) {
      return false;
    }

    return expiresAt.difference(DateTime.now()) <= refreshSkew;
  }

  DateTime? _expirationDate(Map<String, dynamic> decodedToken) {
    final exp = decodedToken['exp'];
    if (exp is int) {
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    }
    if (exp is num) {
      return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
    }
    if (exp is String) {
      final value = int.tryParse(exp);
      if (value != null) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
    }
    return null;
  }

  int? _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  List<String> _extractRoles(Map<String, dynamic> decodedToken) {
    final roles = decodedToken['roles'] ?? decodedToken['authorities'];
    if (roles is List) {
      return roles.map((role) => role.toString()).toList(growable: false);
    }
    if (roles is String) {
      return roles
          .split(',')
          .map((role) => role.trim())
          .where((role) => role.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }

  @override
  void onClose() {
    _client.close();
    super.onClose();
  }
}
